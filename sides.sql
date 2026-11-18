CREATE OR REPLACE FUNCTION public.perform_atomic_checkin(
    p_qr_token TEXT,
    p_admin_user_id UUID,
    p_table_number TEXT,
    p_device_info TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_guest RECORD;
    v_guest_type TEXT;
    v_table_name TEXT;
    v_new_checkin_id UUID;
BEGIN
    -- 1. Cek di tabel students (Lock baris dengan FOR UPDATE)
    SELECT id, registration_id, nama, kelas as detail, attendance_status, seating_zone, seating_row, seat_number 
    INTO v_guest FROM students WHERE qr_token = p_qr_token FOR UPDATE;
    v_guest_type := 'student';
    v_table_name := 'students';

    -- Jika tidak ketemu di students, cek di guardians
    IF v_guest.id IS NULL THEN
        SELECT id, registration_id, nama, hubungan as detail, attendance_status, seating_zone, seating_row, seat_number 
        INTO v_guest FROM guardians WHERE qr_token = p_qr_token FOR UPDATE;
        v_guest_type := 'guardian';
        v_table_name := 'guardians';
    END IF;

    -- Jika tidak ketemu di guardians, cek di teachers
    IF v_guest.id IS NULL THEN
        SELECT id, registration_id, nama, jabatan as detail, attendance_status, seating_zone, seating_row, seat_number 
        INTO v_guest FROM teachers WHERE qr_token = p_qr_token FOR UPDATE;
        v_guest_type := 'teacher';
        v_table_name := 'teachers';
    END IF;

    -- Jika QR Token tidak valid / tidak ditemukan
    IF v_guest.id IS NULL THEN
        RETURN jsonb_build_object(
            'status', 'invalid',
            'message', 'Data undangan tidak ditemukan dalam database.'
        );
    END IF;

    -- 2. Cek apakah sudah pernah check-in
    IF v_guest.attendance_status = 'checked_in' THEN
        -- Ambil info check-in sebelumnya
        RETURN jsonb_build_object(
            'status', 'already_checked_in',
            'registration_id', v_guest.registration_id,
            'nama', v_guest.nama,
            'guest_type', v_guest_type,
            'detail', v_guest.detail,
            'message', 'QR Code sudah pernah digunakan untuk check-in.'
        );
    END IF;

    -- 3. Lakukan Atomic Update
    EXECUTE format('UPDATE %I SET attendance_status = %L, checkin_at = NOW(), checkin_by = %L WHERE id = %L',
        v_table_name, 'checked_in', p_admin_user_id, v_guest.id);

    -- 4. Catat ke tabel checkins
    INSERT INTO checkins (registration_id, guest_type, guest_id, scanned_by, scan_method, status, table_number, device_info)
    VALUES (v_guest.registration_id, v_guest_type, v_guest.id, p_admin_user_id, 'qr', 'success', p_table_number, p_device_info)
    RETURNING id INTO v_new_checkin_id;

    -- 5. Catat Audit Log
    INSERT INTO audit_logs (admin_id, action, target_type, target_id, description)
    VALUES (p_admin_user_id, 'SCAN_CHECKIN', v_guest_type, v_guest.id, 'Check-in berhasil untuk ' || v_guest.registration_id);

    -- Return Sukses
    RETURN jsonb_build_object(
        'status', 'success',
        'registration_id', v_guest.registration_id,
        'nama', v_guest.nama,
        'guest_type', v_guest_type,
        'detail', v_guest.detail,
        'seating', jsonb_build_object(
            'zone', v_guest.seating_zone,
            'row', v_guest.seating_row,
            'seat', v_guest.seat_number
        ),
        'checkin_at', NOW()
    );
END;
$$;
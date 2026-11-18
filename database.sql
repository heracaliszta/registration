-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. STUDENTS TABLE
CREATE TABLE students (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    registration_id TEXT UNIQUE NOT NULL,
    nama TEXT NOT NULL,
    nisn TEXT UNIQUE,
    kelas TEXT NOT NULL CHECK (kelas IN ('XII IPA 1', 'XII IPA 2', 'XII IPA 3', 'XII IPS 1', 'XII IPS 2', 'XII IPS 3')),
    jurusan TEXT NOT NULL CHECK (jurusan IN ('IPA', 'IPS')),
    nomor_peserta TEXT UNIQUE,
    whatsapp TEXT NOT NULL,
    email TEXT,
    attendance_status TEXT DEFAULT 'registered' CHECK (attendance_status IN ('registered', 'checked_in', 'cancelled')),
    checkin_at TIMESTAMPTZ,
    checkin_by UUID,
    seating_zone TEXT,
    seating_row TEXT,
    seat_number TEXT,
    qr_token TEXT UNIQUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. GUARDIANS TABLE (1 Student = 1 Guardian)
CREATE TABLE guardians (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    registration_id TEXT UNIQUE NOT NULL,
    student_id UUID UNIQUE NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    nama TEXT NOT NULL,
    hubungan TEXT NOT NULL,
    whatsapp TEXT NOT NULL,
    email TEXT,
    attendance_status TEXT DEFAULT 'registered' CHECK (attendance_status IN ('registered', 'checked_in', 'cancelled')),
    checkin_at TIMESTAMPTZ,
    checkin_by UUID,
    seating_zone TEXT,
    seating_row TEXT,
    seat_number TEXT,
    qr_token TEXT UNIQUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. TEACHERS TABLE
CREATE TABLE teachers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    registration_id TEXT UNIQUE NOT NULL,
    nama TEXT NOT NULL,
    jabatan TEXT NOT NULL CHECK (jabatan IN ('Guru', 'Wali Kelas', 'Pengurus Sekolah')),
    kelas TEXT, -- Dapat dikaitkan dengan 7 kelas atau umum
    whatsapp TEXT NOT NULL,
    email TEXT,
    attendance_status TEXT DEFAULT 'registered' CHECK (attendance_status IN ('registered', 'checked_in', 'cancelled')),
    checkin_at TIMESTAMPTZ,
    checkin_by UUID,
    seating_zone TEXT,
    seating_row TEXT,
    seat_number TEXT,
    qr_token TEXT UNIQUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. ADMINS PROFILES (Linked to Supabase Auth Users)
CREATE TABLE admins (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
    nama TEXT NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('super_admin', 'panitia_wisudawan', 'panitia_wali', 'panitia_guru', 'monitoring')),
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. CHECKINS TABLE (Immutable Log)
CREATE TABLE checkins (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    registration_id TEXT NOT NULL,
    guest_type TEXT NOT NULL CHECK (guest_type IN ('student', 'guardian', 'teacher')),
    guest_id UUID NOT NULL,
    scanned_by UUID REFERENCES auth.users(id),
    scan_method TEXT DEFAULT 'qr' CHECK (scan_method IN ('qr', 'manual')),
    checkin_at TIMESTAMPTZ DEFAULT NOW(),
    status TEXT DEFAULT 'success' CHECK (status IN ('success', 'already_checked_in', 'invalid')),
    table_number TEXT,
    device_info TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. AUDIT LOGS TABLE
CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    admin_id UUID REFERENCES auth.users(id),
    action TEXT NOT NULL,
    target_type TEXT,
    target_id UUID,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7. EVENT SETTINGS TABLE
CREATE TABLE event_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_name TEXT NOT NULL,
    theme TEXT NOT NULL,
    event_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    venue TEXT NOT NULL,
    registration_status TEXT DEFAULT 'open',
    checkin_status TEXT DEFAULT 'open',
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- PERFORMANCE INDEXES
CREATE INDEX idx_students_reg_id ON students(registration_id);
CREATE INDEX idx_students_qr_token ON students(qr_token);
CREATE INDEX idx_students_kelas ON students(kelas);
CREATE INDEX idx_guardians_reg_id ON guardians(registration_id);
CREATE INDEX idx_guardians_qr_token ON guardians(qr_token);
CREATE INDEX idx_teachers_reg_id ON teachers(registration_id);
CREATE INDEX idx_teachers_qr_token ON teachers(qr_token);
CREATE INDEX idx_checkins_reg_id ON checkins(registration_id);
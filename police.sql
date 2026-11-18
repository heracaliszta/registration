-- Enable RLS
ALTER TABLE students ENABLE ROW LEVEL SECURITY;
ALTER TABLE guardians ENABLE ROW LEVEL SECURITY;
ALTER TABLE teachers ENABLE ROW LEVEL SECURITY;
ALTER TABLE admins ENABLE ROW LEVEL SECURITY;
ALTER TABLE checkins ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_settings ENABLE ROW LEVEL SECURITY;

-- PUBLIC / GUEST POLICIES
CREATE POLICY "Allow public insert for guest registration" ON students
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Allow public select by qr_token or registration_id" ON students
    FOR SELECT USING (true);

CREATE POLICY "Allow public insert for guardian registration" ON guardians
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Allow public select guardians" ON guardians
    FOR SELECT USING (true);

CREATE POLICY "Allow public insert for teacher registration" ON teachers
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Allow public select teachers" ON teachers
    FOR SELECT USING (true);

CREATE POLICY "Allow public view event settings" ON event_settings
    FOR SELECT USING (true);

-- ADMIN POLICIES (Authenticated via Supabase Auth)
CREATE POLICY "Allow authenticated admins full access to students" ON students
    FOR ALL TO authenticated USING (EXISTS (SELECT 1 FROM admins WHERE admins.user_id = auth.uid() AND admins.active = true));

CREATE POLICY "Allow authenticated admins full access to guardians" ON guardians
    FOR ALL TO authenticated USING (EXISTS (SELECT 1 FROM admins WHERE admins.user_id = auth.uid() AND admins.active = true));

CREATE POLICY "Allow authenticated admins full access to teachers" ON teachers
    FOR ALL TO authenticated USING (EXISTS (SELECT 1 FROM admins WHERE admins.user_id = auth.uid() AND admins.active = true));

CREATE POLICY "Allow authenticated admins full access to checkins" ON checkins
    FOR ALL TO authenticated USING (EXISTS (SELECT 1 FROM admins WHERE admins.user_id = auth.uid() AND admins.active = true));

CREATE POLICY "Allow authenticated admins full access to audit_logs" ON audit_logs
    FOR ALL TO authenticated USING (EXISTS (SELECT 1 FROM admins WHERE admins.user_id = auth.uid() AND admins.active = true));

CREATE POLICY "Allow authenticated admins update event settings" ON event_settings
    FOR UPDATE TO authenticated USING (EXISTS (SELECT 1 FROM admins WHERE admins.user_id = auth.uid() AND admins.role = 'super_admin'));
-- Initial schema migration
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE IF NOT EXISTS doctors (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    specialization TEXT NOT NULL,
    phone TEXT,
    cabinet TEXT
);

CREATE TABLE IF NOT EXISTS patients (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    birth_date DATE,
    gender TEXT,
    snils TEXT,
    passport_data TEXT,
    phone TEXT,
    relative_contact TEXT,
    representative_data TEXT,
    photo_path TEXT,
    skk_number TEXT,
    skk_date DATE,
    issued_by_lpu TEXT,
    main_diagnosis_mkb TEXT,
    secondary_diagnoses_mkb TEXT,
    checkin_examination TEXT,
    health_group TEXT,
    diet_table TEXT,
    forbidden_procedures TEXT,
    mobility_regime TEXT,
    arrival_purpose TEXT,
    funding_source TEXT,
    sanatorium_profile TEXT,
    planned_arrival TIMESTAMP,
    planned_departure TIMESTAMP,
    actual_arrival TIMESTAMP,
    actual_departure TIMESTAMP,
    room_number TEXT,
    building TEXT,
    floor TEXT,
    doctor_id INTEGER REFERENCES doctors(id) ON DELETE SET NULL,
    bed_days_count INTEGER DEFAULT 0,
    room_category TEXT,
    diet_type TEXT,
    special_needs TEXT,
    lfk_group TEXT,
    cultural_participation TEXT,
    voucher_type TEXT,
    extra_services TEXT,
    companion_data TEXT,
    status TEXT DEFAULT 'active',
    treatment_efficiency TEXT,
    treatment_duration_category TEXT,
    benefit_category TEXT,
    egisz_id TEXT,
    fss_referral_id TEXT,
    is_egisz_activated BOOLEAN DEFAULT FALSE,
    diagnosis TEXT,
    contraindications TEXT,
    treatment_goals TEXT,
    dynamics TEXT,
    final_recommendations TEXT
);

CREATE TABLE IF NOT EXISTS measurements (
    id SERIAL PRIMARY KEY,
    patient_id INTEGER REFERENCES patients(id) ON DELETE CASCADE,
    pressure_systolic REAL,
    pressure_diastolic REAL,
    pulse INTEGER,
    pain_level INTEGER,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS mood_entries (
    id SERIAL PRIMARY KEY,
    patient_id INTEGER REFERENCES patients(id) ON DELETE CASCADE,
    score INTEGER,
    comment TEXT,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    sentiment TEXT
);

CREATE TABLE IF NOT EXISTS medical_notes (
    id SERIAL PRIMARY KEY,
    patient_id INTEGER REFERENCES patients(id) ON DELETE CASCADE,
    author TEXT,
    content TEXT,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS appointments (
    id SERIAL PRIMARY KEY,
    patient_id INTEGER REFERENCES patients(id) ON DELETE CASCADE,
    type TEXT,
    title TEXT,
    time TIMESTAMP NOT NULL,
    room TEXT,
    doctor TEXT,
    status TEXT DEFAULT 'pending'
);

CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    login TEXT UNIQUE NOT NULL,
    password TEXT NOT NULL,
    role TEXT NOT NULL,
    patient_id INTEGER REFERENCES patients(id) ON DELETE SET NULL,
    doctor_id INTEGER REFERENCES doctors(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS reminders (
    id SERIAL PRIMARY KEY,
    patient_id INTEGER REFERENCES patients(id) ON DELETE CASCADE,
    doctor_id INTEGER REFERENCES doctors(id) ON DELETE CASCADE,
    message TEXT,
    is_read BOOLEAN DEFAULT FALSE,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS emk (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id INTEGER REFERENCES patients(id) ON DELETE CASCADE,
    status TEXT DEFAULT 'active',
    diagnoses TEXT,
    contraindications TEXT,
    treatment_goals TEXT,
    daily_logs TEXT,
    stage_reviews TEXT,
    final_recommendations TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS questionnaire_results (
    id SERIAL PRIMARY KEY,
    patient_id INTEGER REFERENCES patients(id) ON DELETE CASCADE,
    title TEXT,
    total_score INTEGER,
    date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS hospitalizations (
    id SERIAL PRIMARY KEY,
    patient_id INTEGER REFERENCES patients(id) ON DELETE CASCADE,
    admission_date DATE,
    discharge_date DATE,
    reason TEXT,
    department TEXT
);

-- Indexes for optimization
CREATE INDEX IF NOT EXISTS idx_users_login ON users(login);
CREATE INDEX IF NOT EXISTS idx_patients_doctor_id ON patients(doctor_id);
CREATE INDEX IF NOT EXISTS idx_measurements_patient_id ON measurements(patient_id);
CREATE INDEX IF NOT EXISTS idx_measurements_timestamp ON measurements(timestamp);
CREATE INDEX IF NOT EXISTS idx_mood_entries_patient_id ON mood_entries(patient_id);
CREATE INDEX IF NOT EXISTS idx_appointments_patient_id ON appointments(patient_id);
CREATE INDEX IF NOT EXISTS idx_appointments_time ON appointments(time);
CREATE INDEX IF NOT EXISTS idx_reminders_patient_id ON reminders(patient_id);
CREATE INDEX IF NOT EXISTS idx_reminders_is_read ON reminders(is_read);
CREATE INDEX IF NOT EXISTS idx_emk_patient_id ON emk(patient_id);

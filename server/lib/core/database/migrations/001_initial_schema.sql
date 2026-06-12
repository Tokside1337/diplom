-- Professional PostgreSQL Schema for Medical Rehabilitation System (ReStart)
-- Architect: Senior Database Engineer
-- Standards: 3NF, SQL:2016, High-Integrity Constraints

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

--------------------------------------------------------------------------------
-- 1. ENUMS AND CUSTOM TYPES
--------------------------------------------------------------------------------

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_role') THEN
        CREATE TYPE user_role AS ENUM ('admin', 'doctor', 'patient', 'staff');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'gender_type') THEN
        CREATE TYPE gender_type AS ENUM ('male', 'female', 'other');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'admission_status') THEN
        CREATE TYPE admission_status AS ENUM ('planned', 'active', 'discharged', 'cancelled');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'appointment_status') THEN
        CREATE TYPE appointment_status AS ENUM ('pending', 'confirmed', 'completed', 'cancelled', 'no_show');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'sentiment_type') THEN
        CREATE TYPE sentiment_type AS ENUM ('positive', 'neutral', 'negative');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'record_status') THEN
        CREATE TYPE record_status AS ENUM ('active', 'archived', 'completed');
    END IF;
END $$;

--------------------------------------------------------------------------------
-- 2. UTILITY FUNCTIONS
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

--------------------------------------------------------------------------------
-- 3. CORE TABLES
--------------------------------------------------------------------------------

-- Doctors/Medical Staff
CREATE TABLE IF NOT EXISTS doctors (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name TEXT NOT NULL,
    specialization TEXT NOT NULL,
    phone TEXT,
    cabinet TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Patients (Personal & Identity Data)
CREATE TABLE IF NOT EXISTS patients (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name TEXT NOT NULL,
    birth_date DATE, -- Changed from NOT NULL
    gender gender_type, -- Changed from NOT NULL
    snils TEXT UNIQUE,
    passport_data TEXT,
    phone TEXT,
    relative_contact TEXT,
    representative_data TEXT,
    photo_path TEXT,
    benefit_category TEXT,
    egisz_id TEXT UNIQUE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Stay Records (Visit specific data - handles multiple visits)
CREATE TABLE IF NOT EXISTS stay_records (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    patient_id INTEGER NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    doctor_id INTEGER REFERENCES doctors(id) ON DELETE SET NULL,
    status admission_status DEFAULT 'planned',

    -- Arrival/Departure
    planned_arrival TIMESTAMPTZ,
    planned_departure TIMESTAMPTZ,
    actual_arrival TIMESTAMPTZ,
    actual_departure TIMESTAMPTZ,
    bed_days_count INTEGER DEFAULT 0 CHECK (bed_days_count >= 0),

    -- Location
    building TEXT,
    floor TEXT,
    room_number TEXT,
    room_category TEXT,

    -- Rehabilitation Specifics
    arrival_purpose TEXT,
    funding_source TEXT,
    sanatorium_profile TEXT,
    voucher_type TEXT,
    fss_referral_id TEXT,

    skk_number TEXT,
    skk_date DATE,
    issued_by_lpu TEXT,
    cultural_participation TEXT,
    extra_services TEXT,
    companion_data TEXT,

    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Patient Medical Profile (Clinical data per visit or overall)
CREATE TABLE IF NOT EXISTS medical_profiles (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    patient_id INTEGER NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    stay_id INTEGER REFERENCES stay_records(id) ON DELETE CASCADE,

    main_diagnosis_mkb TEXT, -- ICD-10/11
    secondary_diagnoses_mkb TEXT,
    checkin_examination TEXT,
    health_group TEXT,
    diet_table TEXT,
    diet_type TEXT,
    forbidden_procedures TEXT,
    mobility_regime TEXT,
    lfk_group TEXT,
    special_needs TEXT,

    is_egisz_activated BOOLEAN DEFAULT FALSE,
    treatment_efficiency TEXT,
    treatment_duration_category TEXT,
    dynamics TEXT,

    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Electronic Medical Record (Long-term clinical summary)
CREATE TABLE IF NOT EXISTS emk (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id INTEGER NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    status record_status DEFAULT 'active',

    diagnoses TEXT,
    contraindications TEXT,
    treatment_goals TEXT,
    daily_logs TEXT,
    stage_reviews TEXT,
    final_recommendations TEXT,

    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

--------------------------------------------------------------------------------
-- 4. MONITORING & ACTIVITY TABLES
--------------------------------------------------------------------------------

-- Physiological Measurements
CREATE TABLE IF NOT EXISTS measurements (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    patient_id INTEGER NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    stay_id INTEGER REFERENCES stay_records(id) ON DELETE CASCADE,

    pressure_systolic REAL CHECK (pressure_systolic > 0 AND pressure_systolic < 300),
    pressure_diastolic REAL CHECK (pressure_diastolic > 0 AND pressure_diastolic < 200),
    pulse INTEGER CHECK (pulse > 0 AND pulse < 300),
    pain_level INTEGER CHECK (pain_level >= 0 AND pain_level <= 10),

    measured_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Psychological State
CREATE TABLE IF NOT EXISTS mood_entries (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    patient_id INTEGER NOT NULL REFERENCES patients(id) ON DELETE CASCADE,

    score INTEGER NOT NULL CHECK (score >= 1 AND score <= 10),
    comment TEXT,
    sentiment sentiment_type,

    measured_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Professional Medical Notes
CREATE TABLE IF NOT EXISTS medical_notes (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    patient_id INTEGER NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    author_id INTEGER REFERENCES doctors(id) ON DELETE SET NULL,

    content TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Appointments & Procedures
CREATE TABLE IF NOT EXISTS appointments (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    patient_id INTEGER NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    doctor_id INTEGER REFERENCES doctors(id) ON DELETE SET NULL,

    type TEXT NOT NULL, -- e.g., 'physiotherapy', 'consultation'
    title TEXT NOT NULL,
    room TEXT,
    status appointment_status DEFAULT 'pending',

    scheduled_at TIMESTAMPTZ NOT NULL,
    duration_minutes INTEGER DEFAULT 30,

    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

--------------------------------------------------------------------------------
-- 5. SYSTEM TABLES
--------------------------------------------------------------------------------

-- User Accounts
CREATE TABLE IF NOT EXISTS users (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    login TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    role user_role NOT NULL,

    patient_id INTEGER UNIQUE REFERENCES patients(id) ON DELETE CASCADE,
    doctor_id INTEGER UNIQUE REFERENCES doctors(id) ON DELETE CASCADE,

    is_active BOOLEAN DEFAULT TRUE,
    last_login TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Communication & Reminders
CREATE TABLE IF NOT EXISTS reminders (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    patient_id INTEGER REFERENCES patients(id) ON DELETE CASCADE,
    doctor_id INTEGER REFERENCES doctors(id) ON DELETE CASCADE,

    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Diagnostics Results
CREATE TABLE IF NOT EXISTS questionnaire_results (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    patient_id INTEGER NOT NULL REFERENCES patients(id) ON DELETE CASCADE,

    title TEXT NOT NULL,
    total_score INTEGER,
    raw_responses JSONB, -- For detailed analysis

    completed_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Hospitalization History
CREATE TABLE IF NOT EXISTS hospitalizations (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    patient_id INTEGER NOT NULL REFERENCES patients(id) ON DELETE CASCADE,

    admission_date TIMESTAMPTZ NOT NULL,
    discharge_date TIMESTAMPTZ,
    reason TEXT,
    department TEXT,

    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

--------------------------------------------------------------------------------
-- 6. INDEXES FOR PERFORMANCE
--------------------------------------------------------------------------------

-- FK Indexes
CREATE INDEX IF NOT EXISTS idx_stay_records_patient_id ON stay_records(patient_id);
CREATE INDEX IF NOT EXISTS idx_medical_profiles_patient_id ON medical_profiles(patient_id);
CREATE INDEX IF NOT EXISTS idx_measurements_patient_id ON measurements(patient_id);
CREATE INDEX IF NOT EXISTS idx_mood_entries_patient_id ON mood_entries(patient_id);
CREATE INDEX IF NOT EXISTS idx_appointments_patient_id ON appointments(patient_id);
CREATE INDEX IF NOT EXISTS idx_appointments_doctor_id ON appointments(doctor_id);
CREATE INDEX IF NOT EXISTS idx_reminders_patient_id ON reminders(patient_id);
CREATE INDEX IF NOT EXISTS idx_emk_patient_id ON emk(patient_id);

-- Time-based Indexes
CREATE INDEX IF NOT EXISTS idx_measurements_measured_at ON measurements(measured_at);
CREATE INDEX IF NOT EXISTS idx_appointments_scheduled_at ON appointments(scheduled_at);
CREATE INDEX IF NOT EXISTS idx_mood_entries_measured_at ON mood_entries(measured_at);

-- Search Indexes
CREATE INDEX IF NOT EXISTS idx_users_login ON users(login);
CREATE INDEX IF NOT EXISTS idx_patients_snils ON patients(snils);

--------------------------------------------------------------------------------
-- 7. TRIGGERS
--------------------------------------------------------------------------------

DO $$
DECLARE
    t text;
BEGIN
    FOR t IN
        SELECT table_name FROM information_schema.tables
        WHERE table_schema = 'public'
        AND table_name IN (
            SELECT table_name FROM information_schema.columns
            WHERE column_name = 'updated_at'
            AND table_schema = 'public'
        )
    LOOP
        EXECUTE format('DROP TRIGGER IF EXISTS trigger_update_updated_at ON %I', t);
        EXECUTE format('CREATE TRIGGER trigger_update_updated_at BEFORE UPDATE ON %I FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();', t);
    END LOOP;
END $$;

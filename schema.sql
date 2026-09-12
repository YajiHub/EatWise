-- ============================================================================
-- MacroPinoy PostgreSQL Schema (Supabase)
-- ============================================================================
-- Run this in the Supabase SQL Editor to set up your database tables,
-- Row Level Security (RLS) policies, indexes, and helper functions.
-- ============================================================================

-- ENABLE UUID EXTENSION
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";


-- ============================================================================
-- 1. USER PROFILES (extends Supabase auth.users)
-- ============================================================================

CREATE TABLE public.profiles (
    id              UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email           TEXT,
    display_name    TEXT NOT NULL DEFAULT '',
    avatar_url      TEXT,
    -- User's daily macro goals (default maintenance for average Filipino male)
    target_calories     INTEGER NOT NULL DEFAULT 2000,
    target_protein_g    NUMERIC(5,1) NOT NULL DEFAULT 60.0,
    target_carbs_g      NUMERIC(5,1) NOT NULL DEFAULT 250.0,
    target_fats_g       NUMERIC(5,1) NOT NULL DEFAULT 55.0,
    -- Physical stats
    weight_kg           NUMERIC(4,1),
    height_cm           NUMERIC(5,1),
    -- Fasting preferences
    fasting_enabled     BOOLEAN NOT NULL DEFAULT FALSE,
    fasting_schedule    TEXT CHECK (fasting_schedule IN ('16:8', '18:6', 'custom')) DEFAULT '16:8',
    fasting_eating_start TIME DEFAULT '12:00:00',   -- e.g., 12 PM start eating
    fasting_eating_end   TIME DEFAULT '20:00:00',   -- e.g., 8 PM stop eating
    -- Timestamps
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Auto-create profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, email, display_name)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data ->> 'display_name', '')
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- Updated_at auto-trigger
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_profiles_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.set_updated_at();


-- ============================================================================
-- 2. DAILY MACRO LOGS
-- ============================================================================

CREATE TABLE public.daily_logs (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    log_date        DATE NOT NULL,                      -- the date this log belongs to
    meal_type       TEXT CHECK (meal_type IN ('breakfast', 'lunch', 'dinner', 'snack', 'fasting', 'unknown')),
    logged_at       TIMESTAMPTZ NOT NULL DEFAULT now(), -- when the user actually logged this

    -- Totals for this meal entry
    total_calories  NUMERIC(7,1) NOT NULL DEFAULT 0,
    total_protein_g NUMERIC(6,1) NOT NULL DEFAULT 0,
    total_carbs_g   NUMERIC(6,1) NOT NULL DEFAULT 0,
    total_fats_g    NUMERIC(6,1) NOT NULL DEFAULT 0,

    -- Metadata
    source          TEXT CHECK (source IN ('photo', 'chat', 'manual', 'barcode')) NOT NULL DEFAULT 'manual',
    ai_confidence   REAL,                              -- AI confidence score (0.0 - 1.0)
    ai_raw_response JSONB,                             -- full AI response for debugging / auditing

    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_daily_logs_user_date ON public.daily_logs(user_id, log_date);


-- ============================================================================
-- 3. INDIVIDUAL FOOD ITEMS WITHIN A LOG
-- ============================================================================

CREATE TABLE public.food_items (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    daily_log_id        UUID NOT NULL REFERENCES public.daily_logs(id) ON DELETE CASCADE,
    name                TEXT NOT NULL,                     -- e.g., "Chicken Adobo"
    name_tagalog        TEXT NOT NULL DEFAULT '',          -- e.g., "Adobong Manok"
    portion_size_g      NUMERIC(6,1) NOT NULL DEFAULT 0,
    portion_description TEXT NOT NULL DEFAULT '',          -- e.g., "1 palm-sized piece"
    calories            NUMERIC(6,1) NOT NULL DEFAULT 0,
    protein_g           NUMERIC(5,1) NOT NULL DEFAULT 0,
    carbs_g             NUMERIC(5,1) NOT NULL DEFAULT 0,
    fats_g              NUMERIC(5,1) NOT NULL DEFAULT 0,
    confidence          REAL DEFAULT 0,
    reasoning           TEXT DEFAULT ''
);

CREATE INDEX idx_food_items_log ON public.food_items(daily_log_id);


-- ============================================================================
-- 4. STEP COUNTS (Daily)
-- ============================================================================

CREATE TABLE public.daily_steps (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    step_date       DATE NOT NULL,
    total_steps     INTEGER NOT NULL DEFAULT 0,
    distance_km     NUMERIC(6,2) NOT NULL DEFAULT 0,
    calories_burned NUMERIC(6,1) NOT NULL DEFAULT 0,
    active_minutes  INTEGER NOT NULL DEFAULT 0,         -- minutes with detectable walking
    synced_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),

    UNIQUE(user_id, step_date)
);

CREATE INDEX idx_daily_steps_user_date ON public.daily_steps(user_id, step_date);


-- ============================================================================
-- 5. JOGGING / RUNNING SESSIONS (optional)
-- ============================================================================

CREATE TABLE public.jog_sessions (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    started_at      TIMESTAMPTZ NOT NULL,
    ended_at        TIMESTAMPTZ,
    total_steps     INTEGER NOT NULL DEFAULT 0,
    distance_km     NUMERIC(6,2) NOT NULL DEFAULT 0,
    calories_burned NUMERIC(6,1) NOT NULL DEFAULT 0,
    avg_pace        NUMERIC(5,2),                       -- minutes per km
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);


-- ============================================================================
-- 6. FASTING LOGS (for tracking adherence)
-- ============================================================================

CREATE TABLE public.fasting_logs (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    fast_date       DATE NOT NULL,
    schedule_type   TEXT NOT NULL DEFAULT '16:8',        -- '16:8' or '18:6'
    fast_start_time TIMESTAMPTZ,                         -- when fasting started
    fast_end_time   TIMESTAMPTZ,                         -- when fasting ended
    completed       BOOLEAN NOT NULL DEFAULT FALSE,
    duration_hours  NUMERIC(4,1),                       -- actual fasting duration
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),

    UNIQUE(user_id, fast_date)
);


-- ============================================================================
-- 7. ROW LEVEL SECURITY (RLS)
-- ============================================================================

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.food_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_steps ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.jog_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fasting_logs ENABLE ROW LEVEL SECURITY;

-- Profiles: users can only read/write their own
CREATE POLICY "Users can read own profile"
    ON public.profiles FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
    ON public.profiles FOR UPDATE
    USING (auth.uid() = id);

-- Daily Logs
CREATE POLICY "Users can CRUD own daily logs"
    ON public.daily_logs FOR ALL
    USING (auth.uid() = user_id);

-- Food Items (inherit from daily_log via join — for SELECT)
-- For INSERT, we trust the client since it's behind our API/RLS
CREATE POLICY "Users access food items of own logs"
    ON public.food_items FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.daily_logs
            WHERE daily_logs.id = food_items.daily_log_id
            AND daily_logs.user_id = auth.uid()
        )
    );

-- Steps
CREATE POLICY "Users can CRUD own steps"
    ON public.daily_steps FOR ALL
    USING (auth.uid() = user_id);

-- Jog Sessions
CREATE POLICY "Users can CRUD own jog sessions"
    ON public.jog_sessions FOR ALL
    USING (auth.uid() = user_id);

-- Fasting Logs
CREATE POLICY "Users can CRUD own fasting logs"
    ON public.fasting_logs FOR ALL
    USING (auth.uid() = user_id);


-- ============================================================================
-- 8. HELPER FUNCTIONS
-- ============================================================================

-- Get daily macro summary for a user on a specific date
CREATE OR REPLACE FUNCTION public.get_daily_macro_summary(
    p_user_id UUID,
    p_date DATE
)
RETURNS TABLE (
    total_calories  NUMERIC,
    total_protein_g NUMERIC,
    total_carbs_g   NUMERIC,
    total_fats_g    NUMERIC,
    meal_count      BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        COALESCE(SUM(dl.total_calories), 0),
        COALESCE(SUM(dl.total_protein_g), 0),
        COALESCE(SUM(dl.total_carbs_g), 0),
        COALESCE(SUM(dl.total_fats_g), 0),
        COUNT(dl.id)
    FROM public.daily_logs dl
    WHERE dl.user_id = p_user_id
      AND dl.log_date = p_date;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Upsert daily steps (called at end of day or periodically)
CREATE OR REPLACE FUNCTION public.upsert_daily_steps(
    p_user_id       UUID,
    p_step_date     DATE,
    p_total_steps   INTEGER,
    p_distance_km   NUMERIC,
    p_calories      NUMERIC
)
RETURNS UUID AS $$
DECLARE
    v_id UUID;
BEGIN
    INSERT INTO public.daily_steps (user_id, step_date, total_steps, distance_km, calories_burned)
    VALUES (p_user_id, p_step_date, p_total_steps, p_distance_km, p_calories)
    ON CONFLICT (user_id, step_date)
    DO UPDATE SET
        total_steps     = EXCLUDED.total_steps,
        distance_km     = EXCLUDED.distance_km,
        calories_burned = EXCLUDED.calories_burned,
        synced_at       = now()
    RETURNING id INTO v_id;
    RETURN v_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get weekly step summary
CREATE OR REPLACE FUNCTION public.get_weekly_steps(
    p_user_id UUID,
    p_end_date DATE
)
RETURNS TABLE (
    step_date       DATE,
    total_steps     INTEGER,
    distance_km     NUMERIC,
    calories_burned NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        ds.step_date,
        ds.total_steps,
        ds.distance_km,
        ds.calories_burned
    FROM public.daily_steps ds
    WHERE ds.user_id = p_user_id
      AND ds.step_date BETWEEN (p_end_date - INTERVAL '6 days') AND p_end_date
    ORDER BY ds.step_date;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

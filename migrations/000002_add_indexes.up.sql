-- Enable pg_trgm extension for fuzzy text search
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_jokes_category ON jokes(category);
CREATE INDEX IF NOT EXISTS idx_jokes_setup_trgm ON jokes USING gin(setup gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_jokes_punchline_trgm ON jokes USING gin(punchline gin_trgm_ops);

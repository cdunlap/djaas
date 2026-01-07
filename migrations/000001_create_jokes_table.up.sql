CREATE TABLE IF NOT EXISTS jokes (
    id SERIAL PRIMARY KEY,
    setup TEXT NOT NULL,
    punchline TEXT NOT NULL,
    category VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Add trigger for updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_jokes_updated_at
    BEFORE UPDATE ON jokes
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Create tags table
CREATE TABLE IF NOT EXISTS tags (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create joke_tags junction table (many-to-many)
CREATE TABLE IF NOT EXISTS joke_tags (
    joke_id INTEGER NOT NULL REFERENCES jokes(id) ON DELETE CASCADE,
    tag_id INTEGER NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (joke_id, tag_id)
);

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_tags_name ON tags(name);
CREATE INDEX IF NOT EXISTS idx_joke_tags_joke_id ON joke_tags(joke_id);
CREATE INDEX IF NOT EXISTS idx_joke_tags_tag_id ON joke_tags(tag_id);

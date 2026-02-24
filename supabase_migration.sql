-- Supabase migration: Create documents table for sync
-- Run this in the Supabase SQL Editor (Dashboard > SQL Editor > New Query)

CREATE TABLE IF NOT EXISTS documents (
  id         TEXT PRIMARY KEY,            -- e.g. "notes/personal/gmail.md" or "templates/family_login"
  content    TEXT NOT NULL DEFAULT '',     -- raw markdown content
  updated_at TIMESTAMPTZ DEFAULT now(),   -- last-write-wins timestamp
  device_id  TEXT,                        -- identifies which device wrote last
  deleted    BOOLEAN DEFAULT false        -- soft-delete flag
);

-- Index for faster queries
CREATE INDEX IF NOT EXISTS idx_documents_updated_at ON documents (updated_at DESC);

-- Enable Row Level Security (optional but recommended)
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;

-- Allow all operations for authenticated users (anon key)
CREATE POLICY "Allow all for anon" ON documents
  FOR ALL
  USING (true)
  WITH CHECK (true);

-- Enable Realtime on this table
ALTER PUBLICATION supabase_realtime ADD TABLE documents;

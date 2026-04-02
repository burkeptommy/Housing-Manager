-- Add trade column to project_quotes for grouping quotes by contractor specialty
-- e.g., "Electrical", "Plumbing", "General Contractor", "HVAC", "Roofing"
ALTER TABLE project_quotes ADD COLUMN IF NOT EXISTS trade TEXT;

-- Backfill existing quotes from their analysis JSONB where possible
UPDATE project_quotes
SET trade = analysis->'vendor'->>'trade'
WHERE trade IS NULL
  AND analysis->'vendor'->>'trade' IS NOT NULL;

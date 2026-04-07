-- Add parent_system_id to support sub-systems (e.g., Well Pump is a child of Well System)
ALTER TABLE home_systems ADD COLUMN IF NOT EXISTS parent_system_id UUID REFERENCES home_systems(id) ON DELETE CASCADE;

-- Index for efficient parent lookups
CREATE INDEX IF NOT EXISTS idx_home_systems_parent ON home_systems(parent_system_id) WHERE parent_system_id IS NOT NULL;

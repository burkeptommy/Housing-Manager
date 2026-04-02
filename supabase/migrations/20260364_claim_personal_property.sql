-- Add personal property amount to property_projects for insurance claims.
-- This tracks the value of personal property (contents) separate from
-- linked project costs, so the total claim includes both.
ALTER TABLE property_projects ADD COLUMN IF NOT EXISTS personal_property_amount DECIMAL(12,2) DEFAULT 0;

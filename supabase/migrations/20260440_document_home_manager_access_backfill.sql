-- Build 87 (Home Manager expansion):
-- Corrective backfill for `documents.visible_to_home_managers`. The earlier
-- 20260438 migration backfilled with snake_case category strings, but the
-- production category column stores Title Case values from
-- `Haven/Features/Documents/Models/DocumentCategory.swift` (e.g. "Will",
-- "Power of Attorney", "Brokerage Account") plus a few legacy snake_case
-- values from older email-pipeline imports.
--
-- This migration normalizes BOTH forms by lowercasing the column value and
-- comparing against a lowercased list. Mirrors the runtime logic in
-- `DocumentAccessDefaults.privateFromHomeManagers` (Swift) and the
-- `PRIVATE_FROM_HOME_MANAGERS` constant in receive-email,
-- process-inbox-item, and analyze-document Edge Functions.
--
-- Idempotent: re-running this migration is safe — it just re-sets the same
-- column value on the same rows.

update documents
set visible_to_home_managers = false
where lower(coalesce(category, '')) in (
  -- Estate Planning
  'will', 'trust',
  'power of attorney', 'power_of_attorney',
  'healthcare directive', 'healthcare_directive',
  'guardianship designation', 'letter of intent',
  'living_will', 'estate_plan',
  'beneficiary designation', 'beneficiary_designation',
  -- Financial Accounts
  'brokerage account', 'retirement account (ira/401k)',
  'bank account', '529 plan',
  'stock options/rsus', 'crypto wallet', 'alternative investments',
  'financial_account', 'investment_statement', 'bank_statement',
  -- Tax Records (returns and detailed records — bills are visible)
  'federal tax return', 'state tax return',
  'gift tax return (form 709)', 'property tax record',
  'estate & trust return (form 1041)',
  'tax_return', 'tax_document',
  -- Life / Long-Term / Disability Insurance
  'life insurance', 'long-term care insurance', 'disability insurance',
  'life_insurance',
  -- Medical (legacy)
  'medical_record', 'health_insurance',
  -- Legal (legacy)
  'legal_agreement',
  -- Government IDs
  'passport',
  'birth certificate', 'marriage certificate', 'divorce decree',
  'social security card', 'citizenship/immigration', 'death certificate',
  'birth_certificate', 'marriage_certificate', 'divorce_decree',
  'social_security'
);

-- Inverse: any row whose category is NOT in the private list should be
-- visible. This re-asserts the default for rows the earlier migration may
-- have left in an inconsistent state because of category casing drift.
update documents
set visible_to_home_managers = true
where lower(coalesce(category, '')) not in (
  'will', 'trust',
  'power of attorney', 'power_of_attorney',
  'healthcare directive', 'healthcare_directive',
  'guardianship designation', 'letter of intent',
  'living_will', 'estate_plan',
  'beneficiary designation', 'beneficiary_designation',
  'brokerage account', 'retirement account (ira/401k)',
  'bank account', '529 plan',
  'stock options/rsus', 'crypto wallet', 'alternative investments',
  'financial_account', 'investment_statement', 'bank_statement',
  'federal tax return', 'state tax return',
  'gift tax return (form 709)', 'property tax record',
  'estate & trust return (form 1041)',
  'tax_return', 'tax_document',
  'life insurance', 'long-term care insurance', 'disability insurance',
  'life_insurance',
  'medical_record', 'health_insurance',
  'legal_agreement',
  'passport',
  'birth certificate', 'marriage certificate', 'divorce decree',
  'social security card', 'citizenship/immigration', 'death certificate',
  'birth_certificate', 'marriage_certificate', 'divorce_decree',
  'social_security'
);

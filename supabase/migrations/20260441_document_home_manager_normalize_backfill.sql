-- Build 87 (Home Manager expansion) — Fix 1 follow-up:
-- Re-backfill `documents.visible_to_home_managers` using a normalized
-- comparison so multi-word Title Case categories match the private list.
--
-- The earlier 20260440 backfill used lowercased category strings against
-- a set that mixed underscore and space formats. Categories like
-- "Power of Attorney" → lower → "power of attorney" only matched if
-- "power of attorney" was in the set; categories like "Bank Statement"
-- → "bank statement" never matched the snake_case-only "bank_statement"
-- entry. This migration fixes both directions by also normalizing
-- underscores to spaces before comparing.
--
-- Mirrors the runtime logic in `DocumentAccessDefaults.privateFromHomeManagers`
-- (Swift) and the `PRIVATE_FROM_HOME_MANAGERS` constant in receive-email,
-- process-inbox-item, and analyze-document Edge Functions.
--
-- Idempotent: re-running this migration is safe — it just re-sets the
-- column value on the same rows.

update documents
set visible_to_home_managers = false
where lower(replace(coalesce(category, ''), '_', ' ')) in (
  -- Estate Planning
  'will', 'trust',
  'power of attorney', 'healthcare directive',
  'guardianship designation', 'letter of intent',
  'living will', 'estate plan', 'beneficiary designation',
  -- Financial Accounts
  'brokerage account', 'retirement account (ira/401k)',
  'bank account', '529 plan',
  'stock options/rsus', 'crypto wallet', 'alternative investments',
  'financial account', 'investment statement', 'bank statement',
  -- Tax Records (returns and detailed records — bills are visible)
  'federal tax return', 'state tax return',
  'gift tax return (form 709)', 'property tax record',
  'estate & trust return (form 1041)',
  'tax return', 'tax document',
  -- Life / Long-Term / Disability Insurance
  'life insurance', 'long-term care insurance', 'disability insurance',
  -- Medical / Health
  'medical record', 'health insurance',
  -- Legal
  'legal agreement',
  -- Government IDs
  'passport',
  'birth certificate', 'marriage certificate', 'divorce decree',
  'social security card', 'social security',
  'citizenship/immigration', 'death certificate'
);

-- Inverse: re-assert the visible default for any row whose category is NOT
-- in the private list. Catches rows that were incorrectly flipped to
-- visible by the earlier 20260440 backfill because of casing drift.
update documents
set visible_to_home_managers = true
where lower(replace(coalesce(category, ''), '_', ' ')) not in (
  'will', 'trust',
  'power of attorney', 'healthcare directive',
  'guardianship designation', 'letter of intent',
  'living will', 'estate plan', 'beneficiary designation',
  'brokerage account', 'retirement account (ira/401k)',
  'bank account', '529 plan',
  'stock options/rsus', 'crypto wallet', 'alternative investments',
  'financial account', 'investment statement', 'bank statement',
  'federal tax return', 'state tax return',
  'gift tax return (form 709)', 'property tax record',
  'estate & trust return (form 1041)',
  'tax return', 'tax document',
  'life insurance', 'long-term care insurance', 'disability insurance',
  'medical record', 'health insurance',
  'legal agreement',
  'passport',
  'birth certificate', 'marriage certificate', 'divorce decree',
  'social security card', 'social security',
  'citizenship/immigration', 'death certificate'
);

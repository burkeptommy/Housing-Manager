-- Build 87 (Home Manager expansion):
-- Per-document visibility flag for home managers. Estate, legal, financial,
-- and medical documents default to hidden so paid household staff never see
-- something the homeowner didn't explicitly share. Family members (and the
-- homeowner) always see every document regardless of this flag — the RLS
-- policy in `20260439_document_home_manager_rls.sql` only filters when the
-- caller is a linked user with `family_members.member_type` of
-- 'home_manager' or 'staff'.

alter table documents
  add column if not exists visible_to_home_managers boolean not null default true;

create index if not exists idx_documents_visible_to_home_managers
  on documents (household_id, visible_to_home_managers);

comment on column documents.visible_to_home_managers is
  'Whether household home managers can see this document. Set by category at upload time via DocumentAccessDefaults; overridable per document via the Access pill in DocumentDetailView. Family members and the homeowner always see every document regardless of this value.';

-- Backfill existing documents based on category. The category list mirrors
-- DocumentAccessDefaults.privateFromHomeManagers in the iOS app. Keep these
-- two lists in sync when categories change.
update documents
set visible_to_home_managers = false
where lower(coalesce(category, '')) in (
  'will', 'trust', 'power_of_attorney', 'healthcare_directive', 'living_will',
  'estate_plan', 'beneficiary_designation',
  'financial_account', 'investment_statement', 'bank_statement',
  'tax_return', 'tax_document',
  'medical_record', 'health_insurance',
  'life_insurance',
  'legal_agreement',
  'passport', 'social_security', 'birth_certificate',
  'marriage_certificate', 'divorce_decree'
);

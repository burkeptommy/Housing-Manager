-- Phase X feedback: drop estate-related vendor categories.
--
-- Chez v1 removed the estate intelligence module (Phase 48, see
-- `20260901_chez_v1_estate_removal.sql` and the "Estate Intelligence —
-- REMOVED (Chez v1)" tombstone in CLAUDE.md). The dedicated estate
-- intake / scoring / handoff flows are gone. With the catalog cleanup
-- we're also dropping the seeded advisor rows since Chez doesn't
-- surface attorneys / CPAs / financial advisors / life insurance to
-- homeowners anymore.
--
-- Affected categories: estate_attorney, cpa_tax, financial_advisor,
-- life_insurance. Total ~411 rows.
--
-- FK safety verified pre-delete: 0 utility_accounts and 0 contractors
-- reference these rows.
--
-- Idempotent — re-running on a fresh DB without seeds is a no-op.

DELETE FROM utility_providers
WHERE provider_type IN ('estate_attorney', 'cpa_tax', 'financial_advisor', 'life_insurance');

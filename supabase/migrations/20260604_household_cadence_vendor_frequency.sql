-- Phase 54E.2: Expand household_cadences to support vendor-backed
-- cadences (cleaning lady every 2 weeks, lawn service, pool service,
-- pest control) and frequencies beyond "every week" — biweekly,
-- tri-weekly, every-4-weeks (~monthly). The original Phase 54D schema
-- assumed weekly-only rhythms for household chores.

-- 1. Drop the CHECK constraint so new cadence_type values (cleaning,
--    lawn_care, pool_service, pest_control, and any future additions)
--    don't require another migration. The iOS enum is the source of
--    truth — an unknown type gracefully falls back to "other" via
--    HouseholdCadenceType(rawValue:).
alter table public.household_cadences
  drop constraint if exists cadence_type_valid;

-- 2. `weeks_interval`: 1 = every week (existing behavior), 2 = every
--    other week, 3 = every 3 weeks, 4 ≈ monthly. Bounded at 12 weeks
--    so the bad-data surface is capped. Default 1 so existing rows
--    retain their weekly-only semantics.
alter table public.household_cadences
  add column if not exists weeks_interval int not null default 1
    check (weeks_interval between 1 and 12);

-- 3. `anchor_date`: reference date for weeks_interval > 1. Used by the
--    expander + edge function to decide which specific week the cadence
--    fires. Weeks-since-anchor modulo weeks_interval must equal zero.
--    Nullable because weekly cadences don't need it.
alter table public.household_cadences
  add column if not exists anchor_date date;

-- 4. `contractor_id`: optional link to the vendor who performs this
--    cadence (cleaning lady, lawn crew). on delete set null so
--    deleting the contractor keeps the cadence alive as an orphan the
--    user can re-link or relabel.
alter table public.household_cadences
  add column if not exists contractor_id uuid
    references public.contractors(id) on delete set null;

create index if not exists idx_household_cadences_contractor
  on public.household_cadences(contractor_id)
  where contractor_id is not null;

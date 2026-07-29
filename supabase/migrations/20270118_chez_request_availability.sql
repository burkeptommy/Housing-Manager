-- Wave 3 Phase C — operator-captured homeowner availability on a case.
--
-- The service portal captures when the homeowner can host a visit
-- directly on the case: freeform windows ("any weekday after 3pm, not
-- Thursday") plus structured chips. Seeded client-side from
-- snapshot.homeowner_intake.preferred_windows when present; edited by
-- the operator as scheduling reality develops. JSONB passthrough so the
-- portal's shape can evolve without another migration. NULL = never
-- captured (legacy rows and cases where scheduling never came up).
--
-- Written by chez-concierge action `save_case_availability` (admin
-- only, 8KB serialized cap). Read via fetch_case_bundle's `select *`
-- request row — no reader change needed.

ALTER TABLE public.chez_requests
    ADD COLUMN IF NOT EXISTS availability_windows JSONB;

COMMENT ON COLUMN public.chez_requests.availability_windows IS
    'Operator-captured homeowner availability for this case: freeform windows plus structured chips. Seeded from snapshot.homeowner_intake.preferred_windows; edited in the service portal via save_case_availability. NULL = never captured.';

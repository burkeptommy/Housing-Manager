-- Phase 56.2: Persist the ATTOM-supplied low/high value band alongside
-- the canonical single value so the UI can display an honest range
-- ("$908K–$1.0M") instead of either a false-precision point estimate
-- ("$955,623") or a synthetic ±5% band.
--
-- Nullable. Old rows and user-overridden rows keep the band NULL and
-- the UI falls back to the point value. Populated by the Build 84
-- fallback ladder in `AppState.refreshPropertyValuesV1` /
-- `ensurePropertyValuesAreFresh` and `PropertyDetailViewModel.refreshFromPublicRecords`
-- whenever an ATTOM lookup returns a band.

alter table public.properties
    add column if not exists current_estimated_value_low numeric,
    add column if not exists current_estimated_value_high numeric;

comment on column public.properties.current_estimated_value_low is
    'Lower bound of the ATTOM/RentCast AVM range in dollars. NULL when the lookup source did not supply a range or when the user manually overrode the value.';
comment on column public.properties.current_estimated_value_high is
    'Upper bound of the ATTOM/RentCast AVM range in dollars. NULL when the lookup source did not supply a range or when the user manually overrode the value.';

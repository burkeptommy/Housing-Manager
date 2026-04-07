-- Phase 16e: Track where the property's estimated value came from so the
-- Investment Summary can show a transparent caption ("from public records",
-- "estimated from last sale", "based on square footage average") instead of
-- a context-free dollar amount.
--
-- Source values (free-form so future fallback layers don't need a migration):
--   attom     — ATTOM AVM endpoint
--   rentcast  — RentCast AVM fallback
--   computed  — last sale price + appreciation curve
--   estimated — square footage × state median $/sqft
--   manual    — user typed it in themselves
--
-- Confidence is a 0-100 hint shown in transparency captions. ATTOM rows write
-- their actual `estimatedValueConfidence` here; computed/estimated paths write
-- their own conservative values (40 / 25).

ALTER TABLE public.properties
    ADD COLUMN IF NOT EXISTS estimated_value_source TEXT,
    ADD COLUMN IF NOT EXISTS estimated_value_confidence INTEGER;

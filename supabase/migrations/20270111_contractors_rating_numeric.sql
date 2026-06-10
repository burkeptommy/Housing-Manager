-- Phase 100 sweep fix #2 — the second silent killer of "Chez remembers".
--
-- contractors.rating was INTEGER, but vendor proposals carry real-world
-- ratings (4.6, 4.8 — every Google Places rating is fractional).
-- PostgREST passes JSON numbers as text literals, so 4.6 failed the
-- text->integer cast (22P02), the decide_proposal try/catch swallowed
-- it, and the contractor never persisted. Stacked with the
-- source-constraint bug (20270110), the proposal-approval memory write
-- has had two independent ways to fail since Phase 83.3 shipped.
--
-- numeric(2,1) holds 1.0-5.0 with one decimal; the existing
-- rating >= 1 AND rating <= 5 CHECK survives the type change.
-- iOS note: ContractorRow decodes rating as Int? with resilient
-- try? decodeIfPresent — fractional ratings simply decode as nil there
-- until the model moves to Double (logged as an iOS follow-up); whole
-- ratings keep working. Data capture comes first.

ALTER TABLE public.contractors
    ALTER COLUMN rating TYPE numeric(2,1) USING rating::numeric(2,1);

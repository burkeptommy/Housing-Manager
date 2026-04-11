-- Seed life insurance providers into utility_providers table.
-- 30 national US life insurance companies (traditional + digital-first).
-- provider_type = 'life_insurance', regions = ARRAY['US'].

INSERT INTO public.utility_providers (name, slug, provider_type, website, regions, logo_url) VALUES
    ('MetLife', 'metlife', 'life_insurance', 'https://www.metlife.com', ARRAY['US'], NULL),
    ('Northwestern Mutual', 'northwestern-mutual', 'life_insurance', 'https://www.northwesternmutual.com', ARRAY['US'], NULL),
    ('New York Life', 'new-york-life', 'life_insurance', 'https://www.newyorklife.com', ARRAY['US'], NULL),
    ('Prudential', 'prudential', 'life_insurance', 'https://www.prudential.com', ARRAY['US'], NULL),
    ('MassMutual', 'massmutual', 'life_insurance', 'https://www.massmutual.com', ARRAY['US'], NULL),
    ('Lincoln Financial', 'lincoln-financial', 'life_insurance', 'https://www.lincolnfinancial.com', ARRAY['US'], NULL),
    ('Transamerica', 'transamerica', 'life_insurance', 'https://www.transamerica.com', ARRAY['US'], NULL),
    ('Mutual of Omaha', 'mutual-of-omaha', 'life_insurance', 'https://www.mutualofomaha.com', ARRAY['US'], NULL),
    ('Pacific Life', 'pacific-life', 'life_insurance', 'https://www.pacificlife.com', ARRAY['US'], NULL),
    ('Protective Life', 'protective-life', 'life_insurance', 'https://www.protective.com', ARRAY['US'], NULL),
    ('Nationwide', 'nationwide-life', 'life_insurance', 'https://www.nationwide.com', ARRAY['US'], NULL),
    ('State Farm', 'state-farm-life', 'life_insurance', 'https://www.statefarm.com', ARRAY['US'], NULL),
    ('Guardian Life', 'guardian-life', 'life_insurance', 'https://www.guardianlife.com', ARRAY['US'], NULL),
    ('AIG', 'aig', 'life_insurance', 'https://www.aig.com', ARRAY['US'], NULL),
    ('Securian Financial', 'securian-financial', 'life_insurance', 'https://www.securian.com', ARRAY['US'], NULL),
    ('Unum', 'unum', 'life_insurance', 'https://www.unum.com', ARRAY['US'], NULL),
    ('Principal Financial', 'principal-financial', 'life_insurance', 'https://www.principal.com', ARRAY['US'], NULL),
    ('John Hancock', 'john-hancock', 'life_insurance', 'https://www.johnhancock.com', ARRAY['US'], NULL),
    ('Equitable', 'equitable', 'life_insurance', 'https://www.equitable.com', ARRAY['US'], NULL),
    ('Globe Life', 'globe-life', 'life_insurance', 'https://www.globelifeinsurance.com', ARRAY['US'], NULL),
    ('USAA', 'usaa-life', 'life_insurance', 'https://www.usaa.com', ARRAY['US'], NULL),
    ('Allstate', 'allstate-life', 'life_insurance', 'https://www.allstate.com', ARRAY['US'], NULL),
    ('The Hartford', 'the-hartford-life', 'life_insurance', 'https://www.thehartford.com', ARRAY['US'], NULL),
    ('Amica', 'amica-life', 'life_insurance', 'https://www.amica.com', ARRAY['US'], NULL),
    ('Banner Life', 'banner-life', 'life_insurance', 'https://www.lgamerica.com', ARRAY['US'], NULL),
    ('Haven Life', 'haven-life', 'life_insurance', 'https://www.havenlife.com', ARRAY['US'], NULL),
    ('Ladder Life', 'ladder-life', 'life_insurance', 'https://www.ladderlife.com', ARRAY['US'], NULL),
    ('Bestow', 'bestow', 'life_insurance', 'https://www.bestow.com', ARRAY['US'], NULL),
    ('Ethos Life', 'ethos-life', 'life_insurance', 'https://www.ethoslife.com', ARRAY['US'], NULL),
    ('Penn Mutual', 'penn-mutual', 'life_insurance', 'https://www.pennmutual.com', ARRAY['US'], NULL)
ON CONFLICT (slug) DO UPDATE SET
  provider_type = EXCLUDED.provider_type,
  website = EXCLUDED.website,
  regions = EXCLUDED.regions;

# Phase 48: Estate Intelligence + Intake + Attorney Handoff

## Context

Haven has 40+ phases of home management maturity but the Life tab is underdeveloped. Phase 48 makes estate planning a first-class citizen: users who upload estate documents get automatic intelligence (fiduciaries, attorney linking, gap analysis, staleness), users without documents get a low-friction intake, and both paths converge on a PDF export + attorney handoff flow. The goal: estate planning should feel as clean and easy as home management.

Designed as a single phase (48a + 48b combined). Full schema deployed from day one so the Estate Overview card can show the complete vision immediately.

---

## Key Decisions (locked in with Tom)

| # | Decision | Choice |
|---|----------|--------|
| 1 | Data model | Typed columns + JSONB hybrid. One `estate_state` row per household. |
| 2 | Extraction | Extend `analyze-document` with estate branch (second Claude call) |
| 3 | Life tab UX | Estate Overview as hero card above documents list |
| 4 | Attorney linking | New `linked_attorney_contact_id` FK on documents table |
| 5 | PDF generation | Client-side (UIGraphicsPDFRenderer), server stores encrypted PDF |
| 6 | Drip mode | Dedicated dashboard card slot with 3-tier snooze (today / 7 days / indefinitely) |
| 7 | Mail compose | MFMailComposeViewController wrapped in UIViewControllerRepresentable |
| 8 | H/S/L/N ratings | Swipeable card stack (15 concerns, animate away on rate) |
| 9 | Signed URL | 3-use limit + 7-day expiry |
| 10 | Taxonomy | Expand enum to ~12 estate cases + AI sub-classification as metadata |
| 11 | Staleness | 3-tier: info (3yr), amber (5yr / life changes), critical (7yr / major events / 2026 tax) |
| 12 | Auto-fill | Pre-fill from household data with inline edit + "This isn't right?" escape |
| 13 | Fiduciary display | Role-based cards with source badges ("From your Will" / "Your nomination") |
| 14 | Alfred intake | Guided conversation with structured saves. Never initiates unprompted. |
| 15 | Ship strategy | Design together, ship as one phase |
| 16 | Form mode | Mirror House Quiz pattern (save-per-answer, back-nav, progress bar, 6 sections) |
| 17 | Verify page | Static HTML on havenhome.dev + `verify-estate-export` Edge Function |
| 18 | PII blocking | Don't collect SSNs/accounts by design. Redact in AI extraction only. |
| 19 | Send CTA | "Prepare for Attorney" button on Estate Overview card when ready |

---

## Step 1: Schema & Migrations

### 1A. `estate_state` table
**Create:** `supabase/migrations/[timestamp]_estate_state.sql`

```sql
CREATE TABLE IF NOT EXISTS estate_state (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  household_id UUID NOT NULL UNIQUE REFERENCES households(id) ON DELETE CASCADE,

  -- Presence flags (typed columns for fast queries)
  has_will BOOLEAN NOT NULL DEFAULT FALSE,
  has_revocable_trust BOOLEAN NOT NULL DEFAULT FALSE,
  has_irrevocable_trust BOOLEAN NOT NULL DEFAULT FALSE,
  has_poa BOOLEAN NOT NULL DEFAULT FALSE,
  has_health_proxy BOOLEAN NOT NULL DEFAULT FALSE,
  has_living_will BOOLEAN NOT NULL DEFAULT FALSE,
  has_hipaa_auth BOOLEAN NOT NULL DEFAULT FALSE,
  has_prenup BOOLEAN NOT NULL DEFAULT FALSE,
  has_business_agreement BOOLEAN NOT NULL DEFAULT FALSE,
  has_disposition_of_remains BOOLEAN NOT NULL DEFAULT FALSE,

  -- Execution dates per doc type (for staleness computation)
  will_date DATE,
  trust_date DATE,
  poa_date DATE,
  health_proxy_date DATE,

  -- Estate attorney (derived from most recent/frequent across estate docs)
  estate_attorney_contact_id UUID REFERENCES trusted_contacts(id) ON DELETE SET NULL,
  last_estate_review_date DATE,

  -- JSONB fields for nested/variable data
  fiduciaries JSONB NOT NULL DEFAULT '[]'::jsonb,
  -- Array of: {name, role, is_alternate, source, trusted_contact_id?, family_member_id?}
  -- Roles: executor, trustee, guardian, health_proxy, poa_agent, disposition_agent, successor_trustee

  concerns JSONB NOT NULL DEFAULT '[]'::jsonb,
  -- Array of: {concern_id, rating: "high"|"some"|"low"|"na", rated_at}

  wishes JSONB NOT NULL DEFAULT '[]'::jsonb,
  -- Array of: {wish_id, value, noted_at}

  assets_summary JSONB NOT NULL DEFAULT '{}'::jsonb,
  -- {real_estate_count, vehicle_count, business_count, financial_accounts: [{institution, category}],
  --  life_insurance: [{carrier, type, benefit_bucket}], net_worth_bucket}

  intake_state JSONB,
  -- Mirrors house_quiz_state pattern: {started_at, completed_at, current_section,
  --   answers: {section_id: {value, selected_ids?, answered_at}}, skipped: []}

  -- Fiduciary nominations (separate from extracted fiduciaries)
  nominations JSONB NOT NULL DEFAULT '{}'::jsonb,
  -- {executor: {primary: {name, contact_id?}, alternate: {name, contact_id?}},
  --  trustee: {...}, guardian: {...}, health_proxy: {...}, poa_agent: {...}, disposition_agent: {...}}

  -- Computed fields (written on recompute)
  estate_readiness_score INTEGER NOT NULL DEFAULT 0,
  staleness_tier TEXT NOT NULL DEFAULT 'none', -- none|info|amber|critical
  staleness_reasons JSONB NOT NULL DEFAULT '[]'::jsonb,
  household_snapshot JSONB, -- composition at last recompute (member count, property count, vehicle count)

  -- Timestamps
  last_recomputed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_estate_state_household ON estate_state(household_id);

-- Updated_at trigger
CREATE TRIGGER set_estate_state_updated_at
  BEFORE UPDATE ON estate_state
  FOR EACH ROW
  EXECUTE FUNCTION moddatetime(updated_at);

-- RLS
ALTER TABLE estate_state ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own household estate state"
  ON estate_state FOR SELECT
  USING (household_id = public.get_my_household_id());

CREATE POLICY "Users can insert own household estate state"
  ON estate_state FOR INSERT
  WITH CHECK (household_id = public.get_my_household_id());

CREATE POLICY "Users can update own household estate state"
  ON estate_state FOR UPDATE
  USING (household_id = public.get_my_household_id());

CREATE POLICY "Users can delete own household estate state"
  ON estate_state FOR DELETE
  USING (household_id = public.get_my_household_id());

-- Service role bypass for edge functions
CREATE POLICY "Service role full access to estate state"
  ON estate_state FOR ALL
  USING (auth.role() = 'service_role');
```

### 1B. `linked_attorney_contact_id` on documents
**Create:** `supabase/migrations/[timestamp]_document_linked_attorney.sql`

```sql
ALTER TABLE documents
  ADD COLUMN IF NOT EXISTS linked_attorney_contact_id UUID
  REFERENCES trusted_contacts(id) ON DELETE SET NULL;

CREATE INDEX idx_documents_linked_attorney
  ON documents(linked_attorney_contact_id)
  WHERE linked_attorney_contact_id IS NOT NULL;
```

### 1C. `estate_pdf_exports` table
**Create:** `supabase/migrations/[timestamp]_estate_pdf_exports.sql`

```sql
CREATE TABLE IF NOT EXISTS estate_pdf_exports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  household_id UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
  generated_by UUID REFERENCES auth.users(id),
  storage_path TEXT NOT NULL,
  verification_token UUID NOT NULL UNIQUE DEFAULT gen_random_uuid(),
  template_used TEXT NOT NULL, -- 'pre_meeting' | 'annual_review' | 'hybrid'
  max_access_count INTEGER NOT NULL DEFAULT 3,
  access_count INTEGER NOT NULL DEFAULT 0,
  access_log JSONB NOT NULL DEFAULT '[]'::jsonb,
  recipient_email TEXT,
  recipient_name TEXT,
  linked_attorney_contact_id UUID REFERENCES trusted_contacts(id) ON DELETE SET NULL,
  estate_readiness_score INTEGER,
  pdf_content_hash TEXT, -- SHA-256 for verification page
  pdf_sections JSONB,
  expires_at TIMESTAMPTZ NOT NULL,
  revoked_at TIMESTAMPTZ,
  mail_compose_presented_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_estate_pdf_exports_household ON estate_pdf_exports(household_id);
CREATE INDEX idx_estate_pdf_exports_token ON estate_pdf_exports(verification_token);

ALTER TABLE estate_pdf_exports ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own household exports"
  ON estate_pdf_exports FOR SELECT
  USING (household_id = public.get_my_household_id());

CREATE POLICY "Users can insert own household exports"
  ON estate_pdf_exports FOR INSERT
  WITH CHECK (household_id = public.get_my_household_id());

CREATE POLICY "Users can update own household exports"
  ON estate_pdf_exports FOR UPDATE
  USING (household_id = public.get_my_household_id());

CREATE POLICY "Service role full access to estate exports"
  ON estate_pdf_exports FOR ALL
  USING (auth.role() = 'service_role');
```

---

## Step 2: DocumentCategory Enum Expansion

**Modify:** `Haven/Features/Documents/Models/DocumentCategory.swift`

Add ~6 new cases to the "Estate Planning" section:
- `livingWill = "Living Will"`
- `hipaaAuthorization = "HIPAA Authorization"`
- `prenup = "Pre-Nuptial Agreement"`
- `postnup = "Post-Nuptial Agreement"`
- `dispositionOfRemains = "Disposition of Remains"`
- `deedInTrust = "Deed in Trust"`

Update `isSingleton` (all true), `sectionGroup` (all "Estate Planning"), `groupedCategories` order.

**Sync across all 5 locations:**
1. `Haven/Features/Documents/Models/DocumentCategory.swift` -- Swift enum
2. `supabase/functions/analyze-document/index.ts` -- VALID_CATEGORIES array (~line 60)
3. `Haven/Features/Documents/DocumentAccessDefaults.swift` -- privateFromHomeManagers set
4. `supabase/functions/receive-email/index.ts` -- PRIVATE_FROM_HOME_MANAGERS constant
5. `supabase/functions/process-inbox-item/index.ts` -- PRIVATE_FROM_HOME_MANAGERS constant

All new estate categories must be in the PRIVATE_FROM_HOME_MANAGERS set (estate docs are private from home managers by default).

Fine sub-classification (revocable vs irrevocable trust, springing vs general POA) stored in `documents.metadata.extracted_metadata.estate_sub_type` as a string. No extra enum cases needed for sub-types.

---

## Step 3: Estate Extraction in analyze-document

**Modify:** `supabase/functions/analyze-document/index.ts` (currently 602 lines)

After the primary Claude analysis resolves (~line 309), add an estate detection branch.

### Estate categories set
```typescript
const ESTATE_CATEGORIES = new Set([
  "Will", "Trust", "Power of Attorney", "Healthcare Directive",
  "Guardianship Designation", "Letter of Intent", "Living Will",
  "HIPAA Authorization", "Pre-Nuptial Agreement", "Post-Nuptial Agreement",
  "Disposition of Remains", "Deed in Trust", "Beneficiary Designation",
  "Buy-Sell Agreement", "Succession Plan"
]);
```

### When category matches, run second Claude call
```typescript
if (ESTATE_CATEGORIES.has(resolvedCategory)) {
  // Second Claude call with estate-specific extraction prompt
  const estateExtraction = await anthropic.messages.create({
    model: "claude-sonnet-4-6",
    max_tokens: 4096,
    system: "Extract estate planning metadata from this document. CRITICAL: REDACT any SSN (XXX-XX-XXXX patterns), full account numbers, routing numbers, or policy numbers. Replace with '[REDACTED]'. Only return the last 4 digits of account numbers if present. Never include precise dollar amounts -- use buckets if needed.",
    messages: [{ role: "user", content: [
      { type: "text", text: "Extract structured estate metadata..." },
      // Include document text/image from the primary analysis
    ]}]
  });
  // Parse into: {execution_date, governing_state, attorney_name, attorney_firm,
  //   attorney_contact_info, fiduciaries: [{name, role, is_alternate}],
  //   beneficiaries: [{name, relationship}], estate_sub_type, key_provisions}
}
```

### Fire-and-forget DB operations (follow existing vendor auto-creation pattern)
1. **Upsert estate_state**: Set appropriate `has_*` boolean to TRUE, set `*_date` from execution_date, merge fiduciaries into JSONB array (dedup by name+role)
2. **Insert document_parties rows** from fiduciaries array (populates the currently-orphaned table)
3. **Auto-link attorney**: Fuzzy match trusted_contacts by name+firm. Create new contact with `role: 'estate_attorney'` if no match. Show confirmation in iOS.
4. **Set document.linked_attorney_contact_id** to matched/created contact
5. **Store estate_sub_type** in document metadata (`extracted_metadata.estate_sub_type`)

### PII redaction (belt and suspenders)
After Claude returns, run regex to strip any remaining SSN patterns (`/\d{3}-\d{2}-\d{4}/g`) and long digit sequences (`/\b\d{8,}\b/g`) before writing to database.

---

## Step 4: iOS Models & Services

### 4A. EstateState model
**Modify:** `Haven/Core/Networking/DatabaseModels.swift`

Add after the TrustedContact section. Follow the Row/Insert/Update triple pattern:

```swift
// MARK: - Estate State

struct EstateStateRow: Codable, Identifiable {
    let id: UUID
    let householdId: UUID
    // Presence flags
    let hasWill: Bool
    let hasRevocableTrust: Bool
    let hasIrrevocableTrust: Bool
    let hasPoa: Bool
    let hasHealthProxy: Bool
    let hasLivingWill: Bool
    let hasHipaaAuth: Bool
    let hasPrenup: Bool
    let hasBusinessAgreement: Bool
    let hasDispositionOfRemains: Bool
    // Dates
    let willDate: String? // ISO date string
    let trustDate: String?
    let poaDate: String?
    let healthProxyDate: String?
    // Attorney
    let estateAttorneyContactId: UUID?
    let lastEstateReviewDate: String?
    // JSONB fields
    let fiduciaries: [EstateFiduciary]?
    let concerns: [EstateConcernRating]?
    let wishes: [EstateWish]?
    let assetsSummary: EstateAssetsSummary?
    let intakeState: EstateIntakeState?
    let nominations: EstateNominations?
    // Computed
    let estateReadinessScore: Int
    let stalenessTier: String
    let stalenessReasons: [String]?
    let householdSnapshot: EstateHouseholdSnapshot?
    // Timestamps
    let lastRecomputedAt: String?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, householdId = "household_id"
        case hasWill = "has_will", hasRevocableTrust = "has_revocable_trust"
        // ... all snake_case mappings
    }
}
```

Supporting types:
```swift
struct EstateFiduciary: Codable, Identifiable, Hashable {
    var id: UUID { UUID() } // for Identifiable
    let name: String
    let role: String // executor, trustee, guardian, health_proxy, poa_agent, etc.
    let isAlternate: Bool?
    let source: String // from_will, from_trust, user_nomination
    let trustedContactId: UUID?
    let familyMemberId: UUID?
    enum CodingKeys: String, CodingKey {
        case name, role, isAlternate = "is_alternate", source
        case trustedContactId = "trusted_contact_id", familyMemberId = "family_member_id"
    }
}

struct EstateConcernRating: Codable, Identifiable {
    let concernId: String
    let rating: String // high, some, low, na
    let ratedAt: String
    var id: String { concernId }
    enum CodingKeys: String, CodingKey {
        case concernId = "concern_id", rating, ratedAt = "rated_at"
    }
}

struct EstateWish: Codable, Identifiable {
    let wishId: String
    let value: String
    let notedAt: String
    var id: String { wishId }
    enum CodingKeys: String, CodingKey {
        case wishId = "wish_id", value, notedAt = "noted_at"
    }
}

struct EstateAssetsSummary: Codable {
    let realEstateCount: Int?
    let vehicleCount: Int?
    let businessCount: Int?
    let financialAccountsCount: Int?
    let lifeInsuranceCount: Int?
    let netWorthBucket: String? // "<1M", "1-5M", "5-13M", ">13M"
    enum CodingKeys: String, CodingKey {
        case realEstateCount = "real_estate_count", vehicleCount = "vehicle_count"
        case businessCount = "business_count", financialAccountsCount = "financial_accounts_count"
        case lifeInsuranceCount = "life_insurance_count", netWorthBucket = "net_worth_bucket"
    }
}

struct EstateIntakeState: Codable, Equatable {
    var startedAt: String?
    var completedAt: String?
    var currentSection: String?
    var answers: [String: EstateIntakeAnswer]?
    var skipped: [String]?
    enum CodingKeys: String, CodingKey {
        case startedAt = "started_at", completedAt = "completed_at"
        case currentSection = "current_section", answers, skipped
    }
}

struct EstateIntakeAnswer: Codable, Equatable {
    var value: String?
    var selectedIds: [String]?
    var answeredAt: String
    enum CodingKeys: String, CodingKey {
        case value, selectedIds = "selected_ids", answeredAt = "answered_at"
    }
}

struct EstateNominations: Codable {
    var executor: FiduciaryNomination?
    var trustee: FiduciaryNomination?
    var guardian: FiduciaryNomination?
    var healthProxy: FiduciaryNomination?
    var poaAgent: FiduciaryNomination?
    var dispositionAgent: FiduciaryNomination?
    enum CodingKeys: String, CodingKey {
        case executor, trustee, guardian
        case healthProxy = "health_proxy", poaAgent = "poa_agent"
        case dispositionAgent = "disposition_agent"
    }
}

struct FiduciaryNomination: Codable {
    var primary: NominatedPerson?
    var alternate: NominatedPerson?
}

struct NominatedPerson: Codable {
    var name: String
    var trustedContactId: UUID?
    var familyMemberId: UUID?
    enum CodingKeys: String, CodingKey {
        case name, trustedContactId = "trusted_contact_id", familyMemberId = "family_member_id"
    }
}

struct EstateHouseholdSnapshot: Codable {
    let memberCount: Int?
    let propertyCount: Int?
    let vehicleCount: Int?
    let snapshotDate: String?
    enum CodingKeys: String, CodingKey {
        case memberCount = "member_count", propertyCount = "property_count"
        case vehicleCount = "vehicle_count", snapshotDate = "snapshot_date"
    }
}
```

Also update `DocumentRow` to add `linkedAttorneyContactId: UUID?` with CodingKey `linked_attorney_contact_id`. Add to `DocumentUpdate` as optional.

### 4B. EstateStateService
**Create:** `Haven/Features/Estate/EstateStateService.swift`

```swift
@MainActor
final class EstateStateService: ObservableObject {
    static let shared = EstateStateService()

    @Published var estateState: EstateStateRow?

    func fetch(householdId: UUID) async throws -> EstateStateRow? {
        // SELECT * FROM estate_state WHERE household_id = ...
    }

    func upsert(_ update: EstateStateUpdate) async throws {
        // UPSERT on conflict household_id
    }

    func recordConcernRating(concernId: String, rating: String) async throws {
        // Read current concerns JSONB, merge/replace by concernId, write back
    }

    func recordIntakeAnswer(sectionId: String, answer: EstateIntakeAnswer) async throws {
        // Read intake_state, merge answer into answers dict, write back
        // Same save-per-answer pattern as HouseQuizViewModel
    }

    func recomputeReadinessScore() async throws -> Int {
        // Has will: +20, Has trust (HNW): +15, Has POA (per spouse): +15
        // Has health proxy (per spouse): +15, Has living will: +5
        // Linked attorney: +10, No staleness: +10, Fiduciaries named: +10
        // Household-composition-aware (single person not penalized for missing guardian)
    }

    func computeStaleness(estateState: EstateStateRow, memberCount: Int, propertyCount: Int, vehicleCount: Int) -> (tier: String, reasons: [String]) {
        // Info: 3+ year docs, no life changes
        // Amber: 5+ year docs OR life changes post-execution
        // Critical: 7+ year docs OR major events OR 2026 TCJA sunset
    }

    func autoPopulateFromHousehold(householdId: UUID) async throws -> (answeredCount: Int, totalCount: Int) {
        // Pre-fill from family_members, properties, vehicles, documents, document_parties, trusted_contacts
        // Returns count of auto-filled fields vs total intake fields
    }
}
```

### 4C. EstateExportService
**Create:** `Haven/Features/Estate/EstateExportService.swift`

```swift
@MainActor
final class EstateExportService {

    func generatePDF(
        estateState: EstateStateRow,
        documents: [DocumentRow],
        members: [FamilyMemberRow],
        contacts: [TrustedContactRow],
        attorneyName: String?
    ) -> URL? {
        // UIGraphicsPDFRenderer, letter-size (612x792), 50pt margins
        // Fraunces serif for headers, Inter sans for body
        // Cream #F2EEE5 background, Navy #1B2A4A accents
        // NO em dashes anywhere
        // Template selection: A (pre-meeting), B (annual review), C (hybrid)
        // Footer on every page with verification URL + QR code
    }

    func uploadEncrypted(localURL: URL, householdId: UUID) async throws -> String {
        // AES-256-GCM encrypt using DocumentEncryption pattern
        // Upload to estate-exports bucket
        // Return storage path
    }

    func createExportRecord(
        householdId: UUID,
        storagePath: String,
        templateUsed: String,
        recipientEmail: String?,
        recipientName: String?,
        attorneyContactId: UUID?,
        readinessScore: Int,
        pdfHash: String
    ) async throws -> UUID {
        // Insert into estate_pdf_exports
        // expires_at = now() + 7 days
        // Return verification_token
    }
}
```

---

## Step 5: Estate Overview Card (Life Tab)

### 5A. EstateOverviewCard
**Create:** `Haven/Features/Estate/EstateOverviewCard.swift`

Adaptive hero card. One component, three render states based on `EstateStateRow`:

**Empty state** (no estate_state or all flags false):
```
+------------------------------------------+
|  [shield icon]                           |
|  Start organizing your estate documents  |
|  Haven helps you organize and protect    |
|  what matters most.                      |
|                                          |
|  [Upload a Document] [Build Your Plan]   |
+------------------------------------------+
```
No nagging, no zero scores, no "incomplete" language.

**Partial state** (some docs or partial intake):
```
+------------------------------------------+
|  [progress ring 45%]  3 of 7 core docs   |
|                       [amber] 5yr stale  |
|                                          |
|  John Smith - Executor (From your Will)  |
|  Jane Smith - Trustee (Your nomination)  |
|  [+2 more roles]                         |
|                                          |
|  [Continue Setup]                        |
+------------------------------------------+
```

**Full state** (intake complete, good coverage):
```
+------------------------------------------+
|  [large progress ring 85%]               |
|  Estate plan looks strong                |
|  Next review suggested: March 2029      |
|                                          |
|  [fiduciary chips scrollable]            |
|                                          |
|  [Prepare for Attorney]   (when >= 50%) |
+------------------------------------------+
```

**Integration in DocumentVaultView.swift (~line 347):**
Insert before `compactReadinessCard`:
```swift
EstateOverviewCard(
    estateState: viewModel.estateState,
    onGetStarted: { /* navigate to intake */ },
    onContinue: { /* resume intake */ },
    onPrepareForAttorney: { /* open export flow */ }
)
.padding(.horizontal, HavenTheme.pageMargin)
```

Add `@Published var estateState: EstateStateRow?` to `DocumentVaultViewModel`, fetch in `loadData()`.

### 5B. FiduciaryRoleCard
**Create:** `Haven/Features/Estate/FiduciaryRoleCard.swift`

Compact card per fiduciary. Role icon + name + Primary/Alternate badge + source pill. Tap opens linked contact. Unfilled roles show ghost cards with "+" to nominate.

Role icons (SF Symbols):
- executor: `person.crop.circle.badge.checkmark`
- trustee: `building.columns`
- guardian: `figure.and.child.holdinghands`
- health_proxy: `heart.text.square`
- poa_agent: `hand.raised`
- disposition_agent: `leaf`

### 5C. LinkedAttorneyField
**Create:** `Haven/Features/Estate/LinkedAttorneyField.swift`

Reusable field for estate documents in DocumentDetailView. Picker from trusted_contacts where role = estate_attorney. "Add New Attorney" option opens TrustedContactFormView with role pre-set.

**Integrate in:** `Haven/Features/Documents/Views/DocumentDetailView.swift` -- conditional section when `document.category.sectionGroup == "Estate Planning"`.

---

## Step 6: Estate Intake

### 6A. Dashboard Drip Card
**Create:** `Haven/Features/Estate/EstateIntakeDripCard.swift`

Dedicated card slot on dashboard, separate from the 2 SmartRecommendation slots.

3-tier snooze (UserDefaults):
- `estateDripDismissedUntil: Date?` -- for today/7-day
- `estateDripDismissedIndefinitely: Bool` -- permanent dismiss

Card content adapts: "Protect your family in 10 minutes" (empty) / "Your estate plan needs attention" (stale) / "Pick up where you left off" (partial intake).

**Integrate in DashboardView.swift** between recommendations and maintenance hero card:
```swift
if viewModel.shouldShowEstateDripCard {
    EstateIntakeDripCard(
        estateState: viewModel.estateState,
        onStart: { /* open intake */ },
        onDismiss: { tier in viewModel.dismissEstateDrip(tier: tier) }
    )
}
```

**Modify DashboardViewModel.swift:** Add `estateState`, `shouldShowEstateDripCard`, `dismissEstateDrip(tier:)`.

### 6B. Estate Intake Form
**Create:** `Haven/Features/Estate/EstateIntakeFormView.swift`

Mirror House Quiz pattern exactly. 6 sections:

1. **Your Household** -- pre-filled from family_members. Marital status, dependents, state of residence. Inline edit + "This isn't right?" escape.
2. **Your Advisors** -- attorney (pre-filled from estate_attorney_contact_id), CPA, financial advisor, insurance agent. Contact picker.
3. **Your Concerns** -- swipeable card stack (see 6C). 15 concerns rated H/S/L/NA.
4. **Your Fiduciaries** -- executor, trustee, guardian, health proxy, POA agent. Primary + alternate per role. Pre-filled from document_parties.
5. **Your Wishes** -- distribution preference (spouse-then-kids / equal shares / other), minor age gates, charitable bequest intentions, funeral (cremation/burial), organ donation, end-of-life care flags. Multiple-choice pickers, not free text.
6. **Your Assets** -- bucket pickers. Real estate/vehicles pre-filled. Financial accounts: institution + count ("3 accounts at Chase"). Insurance: carrier + type + death benefit bucket (<$250K, $250K-1M, $1M-5M, >$5M). Business: existence + entity type + ownership range. Net worth bucket: <$1M, $1-5M, $5-13M, >$13M.

Save-per-answer to `estate_state.intake_state` JSONB. Progress bar. Back-nav hydration.

Privacy note inline on every section: *"Haven doesn't ask for account numbers or balances. Your attorney will collect those securely in your meeting."*

Auto-fill on first load shows: *"We've already filled in [N] of [M] things based on what Haven knows about you."*

### 6C. Concerns Card Stack
**Create:** `Haven/Features/Estate/EstateConcernsCardStack.swift`

ZStack of cards (top visible, next 2 peek behind). Each card:
- Concern question in `HavenTypography.title3`
- Contextual note from household data (e.g., "You have 2 minor children")
- 4 rating buttons: H (High) / S (Some) / L (Low) / NA

15 concerns:
1. What happens to my home(s) if something happens to me?
2. Will my kids be cared for by who I choose?
3. Who manages my finances if I can't?
4. Is my spouse/partner protected?
5. Will my business continue without me?
6. Am I paying more estate tax than necessary?
7. Are my retirement accounts going to the right people?
8. What if I need long-term care?
9. Are my digital accounts accessible to my family?
10. Is my life insurance adequate?
11. Are my trusts actually funded?
12. Will my pets be cared for?
13. Are my charitable goals documented?
14. Do my healthcare wishes match my documents?
15. Is my estate plan current with tax law changes?

Tap animates card right with spring (HavenTheme.animationCard). Rating saves immediately. "8 of 15" progress. Swipe left to go back.

---

## Step 7: PDF Export & Attorney Handoff

### 7A. Export Preview View
**Create:** `Haven/Features/Estate/EstateExportView.swift`

Flow: Preview -> Attorney selection -> Generate PDF -> Review PDF -> Send

**PDF template selection (automatic):**
- **Template A (Pre-Meeting Brief)**: intake mostly complete, few/no estate docs on file. Sections: cover, family summary, advisors, concerns (H/S/L/N ratings), asset summary, fiduciary nominations, wishes, document inventory.
- **Template B (Annual Review)**: has_will OR has_revocable_trust AND estate_attorney_contact_id set. Sections: cover, current document inventory with execution dates, fiduciaries on file, life events since last review, gaps identified, staleness flags, user questions (free text), footer.
- **Template C (Hybrid)**: partial docs + partial intake. Template A structure + life-events section after cover.

**Footer on every page (verbatim):**
*"This document contains no account numbers, Social Security numbers, or financial identifiers. Sensitive details will be collected directly by [attorney firm or 'your attorney'] under attorney-client privilege. Generated by Haven on [date]. Verify authenticity at havenhome.dev/verify/[token]"*
Plus QR code encoding the verification URL.

### 7B. MailComposeView
**Create:** `Haven/Shared/Components/MailComposeView.swift`

```swift
import MessageUI

struct MailComposeView: UIViewControllerRepresentable {
    let recipients: [String]
    let subject: String
    let body: String
    let attachmentData: Data?
    let attachmentMimeType: String?
    let attachmentFileName: String?
    var onDismiss: ((MFMailComposeResult) -> Void)?

    static var canSend: Bool { MFMailComposeViewController.canSendMail() }

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.mailComposeDelegate = context.coordinator
        vc.setToRecipients(recipients)
        vc.setSubject(subject)
        vc.setMessageBody(body, isHTML: false)
        if let data = attachmentData, let mime = attachmentMimeType, let name = attachmentFileName {
            vc.addAttachmentData(data, mimeType: mime, fileName: name)
        }
        return vc
    }

    func updateUIViewController(_ vc: MFMailComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let parent: MailComposeView
        init(_ parent: MailComposeView) { self.parent = parent }
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            parent.onDismiss?(result)
            controller.dismiss(animated: true)
        }
    }
}
```

Pre-fill for attorney handoff:
- **To:** attorney email from linked contact
- **Subject:** "Estate planning materials from [name] via Haven" (A) / "Annual estate review request from [name] via Haven" (B)
- **Body:** Short professional template. Signed URL inline. Expiry note. What PDF contains. No marketing copy. No Haven promotion.

Guard with `MailComposeView.canSend`. Fallback: alert + copy-link option.

---

## Step 8: Edge Functions

### 8A. verify-estate-export (new)
**Create:** `supabase/functions/verify-estate-export/index.ts`

Public endpoint (no auth required). GET with `token` query param.

```typescript
// 1. Lookup estate_pdf_exports by verification_token
// 2. Check: revoked_at IS NULL, access_count < max_access_count, expires_at > now()
// 3. Valid: increment access_count, append {accessed_at, ip_hash: SHA256(IP)} to access_log
//    Return: {valid: true, first_name, generated_at, pdf_hash_truncated, access_remaining}
// 4. Expired/maxed: return 410 Gone with reason
// 5. Not found: return 404
```

For the actual PDF download, generate a short-lived (5 minute) Supabase Storage signed URL and return it. The verify page never serves the PDF directly.

### 8B. gap-analysis extension
**Modify:** `supabase/functions/gap-analysis/index.ts`

Add to Promise.all fetch (~line 135):
```typescript
supabase.from("estate_state").select("*").eq("household_id", householdId).maybeSingle()
```

Add "ESTATE STATE" section to `buildHouseholdDataString()` with: doc presence flags, fiduciary names, concern count, intake status, staleness tier.

### 8C. chat extension (Alfred)
**Modify:** `supabase/functions/chat/index.ts`

Add `estate_state` to Promise.all fetch (~line 320). Append "ESTATE PLANNING" section to system prompt:
```
ESTATE PLANNING:
  Documents: Will (dated 2021-03-15), Trust (dated 2021-03-15), POA (missing)
  Estate Attorney: Jane Smith at Smith Estate Law
  Fiduciaries: John (executor), Mary (trustee), Bob (guardian)
  Concerns rated: 8 of 15 (top: probate avoidance=High, protecting spouse=High)
  Staleness: amber -- will is 5 years old, new property added since execution
  Intake: 4 of 6 sections complete
```

Add to system prompt preamble: *"When the user asks about estate planning, you have access to their estate state. Reference their fiduciaries, concerns, and document coverage. NEVER initiate estate planning conversations unprompted -- only respond when the user brings it up."*

### 8D. simulate-scenario extension
**Modify:** `supabase/functions/simulate-scenario/index.ts`

Add `estate_state` to Promise.all data fetch. Add estate preset scenarios:
- `estate_review` -- "What if I reviewed my estate plan this year?"
- `incapacity` -- "What if I became incapacitated?"
- `guardian_change` -- "What if my designated guardian can no longer serve?"
- `state_move` -- "What if I move to a different state?"
- `tax_law_2026` -- "How do 2026 tax law changes affect my estate?"

### 8E. proactive-scan extension
**Modify:** `supabase/functions/proactive-scan/index.ts`

Add `estate_state` to data fetch. Add 3-tier staleness computation:
- **Info** (3+ years, no life changes): Any core doc dated 3+ years, no `last_major_life_event` in last year
- **Amber** (5+ years OR life changes): Any core doc dated 5+ years, OR new property/child/vehicle/marriage status since execution
- **Critical** (7+ years OR major events OR 2026 tax): Docs 7+ years old, OR birth/death/divorce since execution, OR 2026 TCJA sunset threshold

Write `staleness_tier` and `staleness_reasons` back to `estate_state`.

---

## Step 9: SmartRecommendations & Readiness Score

**Modify:** `Haven/Features/Dashboard/SmartRecommendations.swift`

Add `estateState: EstateStateRow?` parameter to `RecommendationEngine.evaluate()` (currently line 30).

Add estate staleness recommendation at priority 5 (critical) and 65 (info/amber):
```swift
if let estate = estateState {
    if estate.stalenessTier == "critical" {
        recs.append(Recommendation(
            id: "estate_staleness_critical",
            title: "Your estate plan needs urgent review",
            subtitle: "Key documents are outdated or major life changes detected",
            icon: "exclamationmark.shield.fill",
            iconColor: HavenColors.critical,
            priority: 5,
            action: .navigate(tab: 2)
        ))
    }
}
```

**Readiness score computation** (in EstateStateService):
- Has will: +20
- Has trust (if multiple properties or net_worth_bucket >= "1-5M"): +15
- Has POA (per spouse if married): +15
- Has health proxy (per spouse if married): +15
- Has living will: +5
- Linked attorney on all estate docs: +10
- No staleness warnings: +10
- Fiduciaries named for applicable roles: +10

Household-composition-aware: single person not penalized for missing guardian nomination. Unmarried person needs only one POA/health proxy.

---

## Step 10: Website Changes

### 10A. Verification page
**Create:** `website/verify.html`

Static HTML page matching existing security.html design (same nav, footer, cream/navy/Georgia styling). URL: `havenhome.dev/verify?token=<UUID>`

JavaScript on load:
1. Extract token from URL search params
2. Fetch `verify-estate-export` Edge Function
3. Success: Show "Verified Estate Planning Summary" + generation date + first name + truncated hash + access remaining
4. Expired: "This link has expired. Please ask [first name] to generate a new one."
5. Invalid: "Invalid verification link."

"This verification page does not provide access to the document itself."

Mobile-responsive. Haven branding. No authentication required.

### 10B. Security page update
**Modify:** `website/security.html`

Add "Estate Document Security" section:
- Haven never collects Social Security numbers, account numbers, or precise balances
- Attorney handoff uses expiring links (3-use limit, 7-day expiry) sent from your own email
- AES-256-GCM encryption for exported PDFs
- IP-hashed access logging with full audit trail
- One-tap revocation from the app
- Haven never shares data with third parties

---

## Step 11: CLAUDE.md Updates

Update all three CLAUDE.md files:
1. **Project root** `CLAUDE.md` -- Add Estate State section (table, fields, JSONB structure), document linked_attorney_contact_id, estate_pdf_exports table, new/modified Edge Functions, new iOS feature folder, estate intake pattern, PDF export flow, MailComposeView
2. **`Haven/CLAUDE.md`** -- No changes needed (generic patterns still apply)
3. **`supabase/functions/CLAUDE.md`** -- Add verify-estate-export to inventory, document analyze-document estate branch, note modified functions

---

## Implementation Sequence

| Phase | What | Key Files | Dependencies |
|-------|------|-----------|-------------|
| **1. Foundation** | Migrations + DatabaseModels + EstateStateService + DocCategory expansion | 3 migration files, DatabaseModels.swift, EstateStateService.swift, DocumentCategory.swift, DocumentAccessDefaults.swift | None |
| **2. Extraction** | analyze-document estate branch + PII redaction | analyze-document/index.ts | Phase 1 |
| **3. Overview** | EstateOverviewCard + FiduciaryRoleCard + LinkedAttorneyField + DocumentVaultView integration | EstateOverviewCard.swift, FiduciaryRoleCard.swift, LinkedAttorneyField.swift, DocumentVaultView.swift, DocumentDetailView.swift | Phases 1-2 |
| **4. Intake** | DripCard + IntakeForm + ConcernsCardStack + Dashboard integration | EstateIntakeDripCard.swift, EstateIntakeFormView.swift, EstateConcernsCardStack.swift, DashboardView.swift, DashboardViewModel.swift | Phase 1 |
| **5. Export** | ExportService + ExportView + MailComposeView + PDF generation | EstateExportService.swift, EstateExportView.swift, MailComposeView.swift | Phases 1-3 |
| **6. Edge Functions** | verify-estate-export + gap-analysis + chat + scenario + proactive-scan | 5 Edge Function files | Phase 1 |
| **7. Website** | verify.html + security.html update | 2 website files | Phase 6 |
| **8. Polish** | SmartRecommendations + readiness score + CLAUDE.md | SmartRecommendations.swift, 3x CLAUDE.md | All |

---

## Verification Checklist

- [ ] Upload a will PDF -> AI extracts fiduciaries + attorney -> estate_state updates -> hero card shows them
- [ ] Upload 3+ estate docs from same attorney -> auto-link, no duplicate contacts
- [ ] Complete intake in form mode -> save-per-answer, back-nav hydrates, readiness rises
- [ ] Complete intake in drip mode -> one question per visit, 3-tier snooze persists
- [ ] Dismiss drip card for 7 days -> doesn't reappear for 7 days
- [ ] Dismiss drip card indefinitely -> never reappears
- [ ] Ask Alfred "who is my executor" -> correct answer from estate_state
- [ ] Generate PDF Template A (no docs, intake done) -> correct sections, cream/navy/Georgia, no em dashes
- [ ] Generate PDF Template B (full docs, linked attorney) -> annual review format
- [ ] Generate PDF Template C (partial) -> hybrid format
- [ ] Email to attorney -> MFMailComposeViewController pre-fills correctly
- [ ] Open signed URL -> PDF downloads
- [ ] Open signed URL 4th time -> 410 Gone
- [ ] Wait 8 days (or manually expire) -> 410 Gone
- [ ] havenhome.dev/verify/[token] -> shows first name + date + hash only, no PII
- [ ] Staleness: will_date 8 years ago -> critical tier on hero card + proactive scan
- [ ] Auto-fill: household with properties + vehicles + family -> intake pre-populates
- [ ] Lane A user with full docs -> never nagged for intake
- [ ] Concerns card stack -> all 15 cards, ratings save, back-swipe works
- [ ] No SSN/account numbers in estate_state, PDF, or extraction output
- [ ] New estate categories in DocumentAccessDefaults (private from home managers)
- [ ] Readiness score: single person not penalized for missing guardian
- [ ] Footer on every PDF page with verification URL + QR code
- [ ] Mail not configured -> fallback alert with copy-link option

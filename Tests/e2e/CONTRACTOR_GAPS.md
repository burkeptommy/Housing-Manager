# Chez Contractor web — gaps log

Findings from the overnight E2E run that the matrix flagged as
"feature-absent" or "incomplete." Grouped by category, then severity,
then matrix section. Each row is meant to feed into product input —
the main thread is NOT auto-fixing these.

Schema additions / behavioral gaps that surfaced during fixture
seeding go in the **Schema gaps** section. Web UI gaps go in the
**Web UI gaps** section. Cross-app desync goes in the **Cross-app
gaps** section.

---

## Schema gaps (surfaced during Phase 0 fixture seeding)

### Major

- **`handyman_requests.source` CHECK constraint excludes `chez_admin`.** The constraint is `('homeowner', 'haven', 'vendor', 'field')`. Phase 80+ added Chez admin orchestration but didn't extend this constraint, so Chez-routed requests cannot self-identify their origin at the row level. Workaround: use `source='haven'` and stamp the flavor in the related message's `metadata`. **Recommendation:** add `chez_admin` to the CHECK list and a corresponding column-level enum / constant on the iOS + web sides.
- **`handyman_requests` has no `metadata` JSONB column.** Phase 80 Chez orchestration needs to stamp routing flavor + acknowledgment requirements at the request level, not just on a relayed message. Today the flavor only lives on the related `handyman_request_messages.metadata`. **Recommendation:** add `metadata JSONB DEFAULT '{}'::jsonb` to mirror the homeowner-side `inbox_items` pattern.

---

## Web UI gaps (filed during waves)

### Critical

(populated as waves run)

### Major

(populated as waves run)

### Moderate

(populated as waves run)

### Minor

(populated as waves run)

---

## Cross-app gaps (Section 21 round-trip findings)

(populated by Wave K)

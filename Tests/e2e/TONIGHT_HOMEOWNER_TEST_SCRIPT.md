# Tonight's Homeowner Test Script — Fresh User Walkthrough

**Audience:** Tom + Tom's wife, testing together on TestFlight build.
**Cap:** 40 steps. Expect ~60–75 min total.
**Goal:** Stress-test the fresh-user happy path. Catch every "huh?" moment.

## How to use this

1. **Use two phones.** One person drives the app, the other reads the script + takes notes.
2. **Pick a real-but-throwaway email.** Something like `firstname+test1@gmail.com` works (Gmail ignores everything after `+`). Use a different email per run so each run is "fresh."
3. **Note the time** you start each major section. If something takes >30s longer than feels right, jot it down.
4. **Three columns of notes per step:**
   - ✅ / ❌ — did it match the expected result?
   - 🤔 — was anything confusing, even if it "worked"?
   - 🐛 — any visual bug, typo, weird wording, em-dash, salmon overuse, anything that looked wrong?

Don't try to test every screen exhaustively. **Trust your instincts.** If something feels off, write it down and move on.

---

## Pre-flight (2 min)

- [ ] **0a.** Latest TestFlight build installed. Both phones up to date.
- [ ] **0b.** Decide which throwaway email + simple password to use. Write it here: `____________________________________`

---

## Part 1 — Sign-up and address (steps 1–6, ~8 min)

| # | What to do | What to watch for | Notes |
|---|---|---|---|
| 1 | Open Chez. From the splash, tap **Create Account**. | Lands on sign-up form. Field tints navy, primary CTA salmon. |  |
| 2 | Enter email + password (8+ chars). Tap **Sign Up**. | Goes STRAIGHT to address entry. NO bounce back to "I already have an account." | |
| 3 | On the Address Hook screen, type the first 5–6 chars of your real home address. | Google Places autocomplete fires. Top suggestion is your address. | |
| 4 | Tap your address. | Loads property card. Shows year built, beds/baths, sq ft, **value range** (e.g. "$908K–$1.0M" not "$955,623"), purchase price if on record. | |
| 5 | Tap **Continue**. | Lands on Foundational Questions screen. Title reads "A few quick basics." | |
| 6 | Answer the 5 foundational questions (climate, roof age, primary heat, trash, **pets**). For pets, do NOT tap either chip first. | Continue button stays DISABLED until you pick yes-or-no on pets. Default isn't pre-selected. | |

---

## Part 2 — House Quiz, chapters 1 + 2 (steps 7–14, ~15 min)

| # | What to do | What to watch for | Notes |
|---|---|---|---|
| 7 | After foundationals, the **Property Recap card** appears. | One-screen confirmation of address / value / year built / sq ft / purchase price / detected systems. Every row is tappable. | |
| 8 | Tap the **purchase price** row. Edit it to something obviously round (e.g. $850,000). Save. | Sheet dismisses; the Recap card shows your edit immediately. | |
| 9 | Tap **Looks right** to dismiss the Recap card. Quiz starts at Q1. | Top of screen shows progress: "Question 1 of 37" and a salmon progress bar. | |
| 10 | Answer Q1–Q5 (mostly tap-and-go). Watch the **running value meter** at the top. | Meter climbs with each answer. By Q5 it should show a real dollar number, not $0. | |
| 11 | After Q5 (purchase price reveal), a **milestone card** appears full-screen. | Title personalised to your address. Has a "Continue" CTA, not a confetti animation. | |
| 12 | Continue. A **Chapter intro card** appears before Q6. | Reads "Chapter 2 of 4 — Property Systems" or similar. Says "~5 minutes, 10 questions." Auto-advances in ~3.5s or on tap. | |
| 13 | Answer Q6–Q10. Q10 is the appliances multi-select. | "Select all" pill appears at the top. Tap it — every appliance chip lights up. Tap "Deselect all" to clear. | |
| 14 | Continue through Q11 (lawn). Pick **"Mostly hardscape (patio, gravel, pavers)"** if it applies, otherwise just keep going. | If you picked hardscape, the quiz **skips Q11b** (lawn type) — you should see a toast: "Skipped 1 question — hardscape doesn't need lawn care." | |

---

## Part 3 — House Quiz, vendor + household chapters (steps 15–22, ~15 min)

| # | What to do | What to watch for | Notes |
|---|---|---|---|
| 15 | Continue to Q15b — **household contractors**. Multi-select chips appear (HVAC service, plumber, electrician, etc.). Pick 2 you actually use. | For each chip you tap, an inline picker appears. Search a real vendor name (or "Other"). | |
| 16 | After Q15b, the **Q17 milestone card** appears revealing your forwarding email address (`*@alfred.getchez.com`). | One-tap copy button. Copy it. Open Mail on your phone. Paste it into a draft. Verify it copied correctly. Close Mail without sending. | |
| 17 | Continue. At Q19, if your heat is electric / geothermal / not-sure, the quiz **skips** the heating-fuel provider question. | Should NOT see a provider picker for heating fuel. Toast appears: "Skipped 1 question." | |
| 18 | Continue through Q22 — **generator**. If you have one, walk through fuel + provider sub-steps. | If your generator fuel matches your heating fuel from Q3, a **confirmation card** asks "We already know Petro supplies your propane. Is your generator on the same account?" Tap Yes. | |
| 19 | Continue to Q25 (garage). Pick anything except "None." | The next question (Q25b — EV charger) appears. If you pick "None" instead, Q25b should be **skipped entirely**. | |
| 20 | Continue to Q28 (household composition). Answer the spouse sub-step. | Form asks for spouse first name + last name + email. If you skip the email, that's fine — should still let you continue. | |
| 21 | After spouse, kids sub-step appears. Add at least one kid (or skip). After kids, **home manager** prompt appears: "Anyone else helping run your home?" | Two buttons: "Add home manager" and "Skip." Tap **Skip**. The Q28 summary shows "A couple" or "A couple, 2 kids." | |
| 22 | Continue to Q36 — **maintenance preference tier**. Three chips: "I handle it" / "Mix of both" / "Hire it out." Tap **Mix of both**. | One chip selected, salmon fill. Continue button enables. | |

---

## Part 4 — Cinematic reveal + Day 0 dashboard (steps 23–28, ~8 min)

| # | What to do | What to watch for | Notes |
|---|---|---|---|
| 23 | Finish the quiz. The **cinematic reveal** appears full-screen. | Hero number animates up over ~2.5s. It's a REAL dollar number (your property value × 0.12, e.g. "$92,400" for a $770K home), NOT "$0." Single number, serif font, no confetti, no chime. | |
| 24 | Tap **Take me to my dashboard**. | Smooth transition to Dashboard. Title bar reads "Chez" in serif font. Top-right has Inbox icon + Settings gear. NO "+" button. | |
| 25 | First viewport on Dashboard. | HomeCoverageHero shows "X of Y systems covered" (categories, like "5 of 14"). Next scheduled visit row reads naturally — if it mentions a vendor, the vendor name appears ONCE, not twice. | |
| 26 | Scroll past the hero. **Quick Actions** row of 4 tiles. Then "UP NEXT" section. | UP NEXT has up to 5 tasks. Each has a zzz (snooze) icon on the right side. Tap a task → opens detail. Back out. | |
| 27 | Scroll further. Should see Recent Activity, then footer. | Activity items: verb-first titles ("Invoice processed: …", "System added: …"). 7 items visible max with "View all activity" link. | |
| 28 | Tap the title bar **Chez** logo, then tap **View schedule** link below UP NEXT. | Lands on **Timeline / Calendar view**, NOT the hub. Month headers with task rows underneath. | |

---

## Part 5 — Tasks tab + Property tab spot check (steps 29–35, ~10 min)

| # | What to do | What to watch for | Notes |
|---|---|---|---|
| 29 | Tap **Tasks tab** (3rd from left). | Title-switcher at top: "Maintenance" with chevron — tap chevron to switch between Maintenance / Handyman. Default is Maintenance. | |
| 30 | On Maintenance screen, scroll to **"Needs your decision"** section (salmon-wash rows). | Pending-vendor routines listed. Tap one → opens detail. **CTA button on detail screen reads cleanly** — no navy-on-navy invisible text. | |
| 31 | Switch to **Handyman** via the title chevron. | Different layout: hero card with "Schedule visit" CTA, vendor card, punch list, recommended items. | |
| 32 | Tap **Property tab** (2nd from left). Tap your property. | Lands on Property Detail Overview sub-tab. Hero shows estimated value range, "PRIMARY RESIDENCE" eyebrow (navy not salmon), "X Systems · Y Priorities" (Priorities should be ≤ Systems). | |
| 33 | Switch to **Systems** sub-tab. | Grid of system category tiles. **"Electrical & Safety"** tile shows the FULL label (wraps if needed, no "Electrical & Safe..." cutoff). | |
| 34 | Tap any system tile → list of that category's systems → tap one → SystemDetailView. | Real system name (no "A4 Crawl Space crawl_space" engineering slug — should read "Crawl Space"). | |
| 35 | Back out twice. Switch to **Vendors** sub-tab. | List of contractors with logo + trade + filter chips at top (All / Home services / Utilities & policies / Recurring / Needs review). | |

---

## Part 6 — Chez delegation + inbox (steps 36–38, ~5 min)

| # | What to do | What to watch for | Notes |
|---|---|---|---|
| 36 | From any task or vendor screen, find a **"Have Chez handle this"** button (salmon-bordered card, person-with-question-mark icon). Tap it. | Composer sheet opens. Title says **"Chez"** never "Tom" or any human name. Category + context auto-filled. Submit. | |
| 37 | Tap **Inbox tab** (top-right of nav). | 4 sub-tabs visible at top: Needs Action / Unread / All / **Chez**. Tap Chez. Your just-submitted request appears. Title is clean — NOT "Find a vendor for: A4 Sanitize pet areas synthetic turf" but "Sanitize pet areas synthetic turf." | |
| 38 | From the Inbox empty state (or via "View Your Chez Email" link), forward a real email to your `*@alfred.getchez.com` address. | Within ~30s, an inbox item should appear with the parsed document. | |

---

## Part 7 — Settings + sign-out (steps 39–40, ~3 min)

| # | What to do | What to watch for | Notes |
|---|---|---|---|
| 39 | Tap the **Settings gear** (top-right of Dashboard). Scroll through the list. | **All row icons should be navy, NEVER salmon.** Section headers in tracking-1.5 ALL CAPS. Tap **Profile** → your name/email/phone visible. | |
| 40 | Back out. Scroll to bottom. Tap **Sign Out** → confirm. Then sign back in with the same email. | Lands on Dashboard with all your data intact. No bounce, no re-quiz. | |

---

## End-of-test debrief (5 min, together)

Answer these out loud and write down whoever's reaction is sharper:

1. **What was the most confusing moment?** (Wife's answer matters most — she's seeing it fresh.)
2. **Where did you say "wait, why?"** (Even small ones.)
3. **Did any screen feel "cluttered" or "AI-generated"?** (Em-dashes, salmon overuse, generic icons, weird typography.)
4. **What would you show a friend first?** (i.e. the "wow" moment that landed.)
5. **What would you NOT show a friend?** (i.e. the part that's still rough.)
6. **One sentence: "If we kept building one thing tonight, it should be ___."**

---

## Known limits going in (don't waste notes on these)

- **Dashboard density** — already on the fix list (P0-3). 4 simplification options on file, awaiting Tom's product call.
- **Visit reminders on Handyman tab** — these are scheduled but real notifications won't fire today since the simulator doesn't run the cadence-notifications cron.
- **Vehicle catalog** — adding a real vehicle by VIN works; recall lookups are async and may take 30s to come back.
- **Calendar sync** — backend exists but no iOS surface yet. Don't try to connect Google Calendar from Settings; the entry point isn't shipped.
- **Trusted contact avatar upload** — Trusted contact form has no photo picker today. Schema migration + UI port pending.
- **Estate intelligence** — fully removed for Chez v1. If you see Will / Trust / POA categories anywhere in document picker, that's a backward-decode artifact for existing docs only; it should NOT appear in fresh upload flows.

---

## After the test

Drop the filled-out script in `/Users/tomburke/Projects/Housing-Manager/Tests/e2e/` named `TONIGHT_RESULTS_YYYY-MM-DD.md` or just send me your raw notes. I'll triage into HOMEOWNER_GAPS.md and fix anything mechanical in the morning.

# Haven — Complete Product Review, Competitive Analysis & Go-to-Market Strategy
### March 23, 2026

---

## Part 1: What Haven Is Today

Haven is a native iOS app (SwiftUI, iOS 17+) powered by Supabase and Claude AI. It sits at the intersection of two categories — estate document intelligence and home property management — and combines them into a single product that no competitor currently replicates. After 36+ iterative development phases and 89 Swift files, the app is in TestFlight with a public link.

### Architecture

Four main tabs: **Dashboard** (estate readiness scoring, Getting Started checklist, Requires Attention section, smart recommendations, maintenance hero card), **Life** (document vault organized by section groups with family member scoping, AI-powered document analysis on every upload, gap analysis engine), **Property** (multi-property management with color-coded maintenance schedules, 150+ task template library, vendor/contractor directory with three import methods, warranty tracking), and **Alfred** (conversational AI concierge with full household context injection — family members, properties, documents, flags, maintenance status).

The **Scenario Studio** ("What If?") is accessible from a floating action button on every screen. It runs AI-powered simulations using the family's real uploaded data across 40+ pre-built scenarios and freeform queries — estate distribution flows, tax exposure, guardianship chains, trust vs. probate analysis, refinancing calculations.

Backend: Supabase with 6 Edge Functions (analyze-document, chat, gap-analysis, extract-vendor, simulate-scenario, view-document). Security: AES-256 encryption at rest, biometric auth, Keychain storage, RLS on every table, API keys server-side only, screenshot prevention on sensitive screens. Household sharing supports multi-user with atomic data migration across 15+ tables.

### Honest Strengths

**AI is structural, not cosmetic.** Every document upload triggers Claude analysis that extracts metadata, categorizes, flags issues (expired policies, beneficiary mismatches), links to family members, and generates summaries. The gap analysis engine identifies missing documents and inconsistencies. Alfred has full household context. The Scenario Studio generates personalized simulations. This isn't a chatbot added to a database — it's an intelligence layer woven into the product architecture.

**Two-module combination is unique.** No competitor connects estate documents to property management. When Haven knows your trust exists AND knows your property deed, it can flag whether the deed is titled to the trust. When a warranty expires, it knows which insurance policy might cover the gap. The cross-module intelligence is the moat.

**The Scenario Studio is a category-defining feature.** "What happens to my family if I die tomorrow?" using real data, real dollar amounts, real family names. No competitor offers anything remotely like this.

**Premium design language.** Cream and navy palette, Georgia serif typography, spacious card layouts, haptic feedback, skeleton loading states. Matches the expectations of the target audience.

### Honest Weaknesses

**Onboarding friction remains high** despite reduction from 7 to 5 steps. Users invest effort before seeing value.

**Solo developer with a full-time job.** 89 Swift files, 6 Edge Functions, Supabase schema, Claude integration — maintained by one person. Technical debt is inevitable.

**iOS only.** No Android, no web. Household sharing is weakened if one spouse is on Android.

**AI costs are real.** Every chat, document analysis, and scenario hits the Claude API. At scale, this is expensive without revenue.

**Engagement frequency is unproven.** The #1 killer of home management apps is low return rates. Haven's features are designed to combat this, but it hasn't been tested with real users yet.

---

## Part 2: The Full Competitive Landscape

### Homer — The Closest Home Management Competitor

**What it is:** Award-winning home management app by Home Owner AB (Stockholm). Founded by Wilhelm Lundborg (Spotify/Skype alumni) and Henrik von Stockenström. Apple App of the Day (2023), Apps We Love (2022–2024), Essential Utility Apps (2024). iOS + Android.

**Features:** Home inventory with AI-powered item recognition (snap photo → identify product → fetch manuals), maintenance task lists with recurring reminders, home timeline, expense tracking with receipt scanner, document storage, floor plan scanner, AR augmented reality notes, "Homer Helper" AI chatbot, Centriq CSV importer. Claims 98% premium retention, organic growth in US/UK/EU. ~46K Android downloads total, ~220/month.

**Pricing:** Freemium. Core features free. Premium subscription required for full features (undisclosed pricing).

**Where Homer beats Haven:** Cross-platform (iOS + Android), Apple editorial features, established user base, AR notes and floor plan scanning, Centriq CSV importer, investor-friendly founder pedigree.

**Where Haven beats Homer:** Homer has ZERO estate document intelligence. Homer's AI is limited to item recognition and general chatbot. Homer has no Scenario Studio equivalent. Homer's Android reviews show 3.33/5 with complaints about AI failures, data loss, and unreliability. Homer's core value prop (photo → manual) is commodity functionality (same as Centriq before it died). Haven's premium design targets HNW families vs Homer's general homeowner audience.

**Homer's vulnerability:** B2B pivot dilutes consumer focus. Users openly worried about platform longevity. No estate depth means Haven can position as "Homer + estate intelligence + AI scenarios — for free."

### Trustworthy ($10–20/month, $120–240/year)

"Family Operating System." Digital vault for documents, IDs, financial records, insurance, passwords, property info. AI automation ("Autopilot"), smart reminders, Chrome extension, collaboration with SecureLinks. SOC 2 Type II, AES-256, HIPAA. Founded 2020. Free (12 items), Silver (~$10/mo), Gold (~$20/mo).

**Gap vs Haven:** No home maintenance. No AI document analysis on upload. No scenario simulator. No maintenance templates. No vendor management. Professional reviewers note most families could achieve similar results with simpler tools at lower cost.

### Everplans ($99/year)

Legacy/end-of-life planning vault. Estate documents, funeral preferences, digital accounts. Partners with Quicken WillMaker. Freemium (10-item limit). iOS app with basic functionality.

**Gap vs Haven:** Extremely narrow end-of-life focus. No property management. No AI analysis. No household context. 5GB storage limit insufficient for real estate management.

### Nines Living (Enterprise pricing, sales call required)

Premium estate management for UHNW families with estate managers/staff. Household manual, vendor management, staff task management, asset tracking, maintenance automation. SOC 2 Type II. Backed by Jet.com founders. Family Wealth Report Awards winner.

**Gap vs Haven:** No AI document analysis. No scenario simulator. Designed for families who HAVE estate managers. Inaccessible pricing. Not for the mass-affluent market Haven targets.

### HomeZada ($59–149/year)

Most established all-in-one home management. Maintenance calendars, project management, budgeting, home inventory, financial tracking, "Homeowner AI," design visualization. Free Essentials plan.

**Gap vs Haven:** No estate document analysis. No legal document intelligence. Basic AI. No scenario planning. Broad but shallow.

### Dib (Free beta)

New entrant positioning against Centriq shutdown. Smart photo recognition, AI chat, automatic manual lookups, maintenance tracking. Built Centriq migration tool. Very early stage.

**Gap vs Haven:** Pure home/appliance focus. No estate planning. Still in beta. Unclear business model.

### IronClad Family (Higher price point)

Military-grade security vault with automated delivery mechanisms (time-based triggers for document release after death/incapacity). Concierge setup services. 50GB storage.

**Gap vs Haven:** Pure vault and delivery system. No property management. No AI intelligence. No ongoing engagement.

### GoodTrust ($69–149/year)

Digital asset management (passwords, crypto, online accounts) with will/trust creation. Dead man's switch. No mobile app.

**Gap vs Haven:** Digital-first, no physical property management. No AI. No mobile app.

### Centriq (SHUT DOWN January 2025)

Was category leader in home appliance management for ~10 years. Photo → model number → manual lookup. Shut down after platform was sold. Users lost access to data with minimal export options. Created market vacuum.

---

## Part 3: Why Apps in This Space Fail

### Failure Pattern 1: The Centriq Death Spiral

**Root causes:** Started free, tried subscriptions too late — users resented paying for their own data. Engagement frequency too low to justify ongoing investment. Core technology was commodity with no moat. When business failed, users had no portability.

**Lesson for Haven:** Data portability and trust are existential. Family Reference Binder PDF export isn't just a feature — it's a trust signal. Also: inventory/manual lookup alone cannot sustain a business. The app must create value beyond retrieval.

### Failure Pattern 2: The All-in-One Graveyard

Estate & Manor Magazine documented household management platforms from the 2010s that failed: they complicated instead of simplifying, were desktop-first in a mobile world, required massive data entry before delivering value, and had no intelligence — glorified databases with pretty interfaces.

**Lesson for Haven:** AI analysis on upload returns value at the moment of input, not weeks later. The value exchange is immediate.

### Failure Pattern 3: The Subscription Wall

Free tiers too limited to demonstrate value. Premium tiers require payment before users see ROI. Subscription fatigue in a market where households already pay for 12+ subscriptions.

**Lesson for Haven:** Being free eliminates the highest-friction point in the customer journey.

### Failure Pattern 4: The Engagement Frequency Death Spiral

Home management is episodic. HVAC filter: monthly. Insurance: annually. Estate plan: when someone dies. Low engagement → users forget app → data goes stale → app becomes useless → uninstall. Even Homer's positive reviews reveal users only open it when something breaks.

**Lesson for Haven:** Scenario Studio, Alfred AI, push notifications, and estate readiness scoring must create return reasons. This is Haven's biggest existential risk.

### Failure Pattern 5: Platform Trust Anxiety

Homer's reviewers worry about whether the app will survive the next decade. Centriq's death amplified this fear across the entire category.

**Lesson for Haven:** Trust-building is a first-order marketing priority. Data export, transparent roadmap communication, and the free model all reduce perceived risk.

---

## Part 4: Haven's Five Competitive Moats

### Moat 1: Only Product Combining Estate Intelligence + Home Management
No competitor connects estate documents to property management. The cross-module intelligence (trust ↔ deed ↔ insurance ↔ maintenance) is impossible for single-module competitors to replicate without rebuilding their product.

### Moat 2: AI That Creates Intelligence, Not Just Convenience
Homer recognizes products from photos. HomeZada recommends tasks. Trustworthy auto-categorizes. These save time. Haven's AI generates new knowledge — reads legal documents, finds contradictions across the estate, simulates financial cascades. Fundamentally different capability.

### Moat 3: The Scenario Studio — No Equivalent Anywhere
"What happens if my spouse and I die tomorrow?" with real assets, real family members, real trust provisions. Nobody has this. It's the engagement feature that creates curiosity-driven return visits.

### Moat 4: Free in a Paid Market

| App | Annual Cost |
|-----|------------|
| Nines Living | $1,000+/year (estimated) |
| Trustworthy Gold | $240/year |
| HomeZada Deluxe | $149/year |
| IronClad Family | $149+/year |
| Everplans Premium | $99/year |
| GoodTrust | $69/year |
| HomeZada Premium | $59/year |
| Homer Premium | Subscription (undisclosed) |
| **Haven** | **Free** |

### Moat 5: Premium Design for Premium Audience
Haven specifically targets high-net-worth families with cream/navy palette, Georgia serif typography, and "Alfred the butler" personality. Not cosmetic — it's market positioning.

---

## Part 5: Go-to-Market Strategy — Detailed Playbook

### Phase 1: Foundation (Months 1–3) — Target: 500 Users

#### Channel 1: Estate Attorney Partnerships (Primary — Highest Leverage)

**Execution plan:**
1. Identify 20 target attorneys in CT/tri-state (estate planning, trusts, elder law). Build CRM tracking sheet.
2. Create attorney referral kit:
   - One-page PDF ("Give Your Clients the Gift of Organization") — what Haven does, it's free, App Store link
   - 90-second screen recording demo: document upload → AI analysis → gap identification
   - Templated email attorney can send to clients post-appointment
   - Co-branded QR code cards for handing to clients
3. The pitch: "Your clients leave with good intentions. 6 months later they can't find their trust. Haven solves this free — and when they discover gaps, they come back to you for updates."
4. Onboard 5 attorneys month 1. 15-minute in-person demo. Bring printed QR cards. Biweekly follow-up.
5. Track attorney-sourced users with UTM/referral code.

**Target:** 100 users from attorney referrals in 3 months.

#### Channel 2: Centriq Refugee Campaign

1. Create "Coming from Centriq?" landing page — Haven as massive upgrade, not just replacement
2. Post in Reddit r/homeowners, r/homeimprovement, r/estateplanning, Facebook home management groups
3. Publish SEO article: "Centriq Shut Down — Here's What to Do Now"
4. Differentiation: "Homer is Centriq 2.0. Haven is something Centriq never was."

**Target:** 150 users in 3 months.

#### Channel 3: Personal Network + TestFlight

1. Send TestFlight link to 50 contacts with personalized message
2. Create 5-question feedback form
3. Follow up individually with every tester after 7 days (personal text, not mass email)
4. Ask every satisfied tester to share with one person

**Target:** 50 direct testers, 200 second-degree referrals.

#### Channel 4: Content Seeding (8 pieces in 3 months)

1. "What Happens to Your Family If You Die Tomorrow? A Checklist" — SEO: "estate planning checklist"
2. "Prince, Aretha Franklin, and the Cost of Not Having an Estate Plan" — Shareable celebrity stories
3. "The Home Maintenance Schedule Every Homeowner Needs (Free)" — SEO: "home maintenance schedule"
4. "Centriq Shut Down. Here's How to Protect Your Home Data" — Capture active searchers
5. "I Audited My Estate Documents With AI — Here's What It Found" — Authentic first-person story
6. "Why Every Homeowner Needs a Family Reference Binder" — Leads to Haven's export feature
7. "The 5 Documents Every Family Needs But Most Don't Have" — Gap analysis in article form
8. "Home Management Apps Compared: HomeZada vs Homer vs Trustworthy vs Haven" — Comparison content

**Publish on:** Medium, LinkedIn, personal blog. Repurpose #1, #2, #5 as TikTok/Instagram Reels.

### Phase 2: Growth (Months 4–8) — Target: 5,000 Users

#### Channel 5: Real Estate Agent Partnerships
- Build "New Homeowner Welcome Kit" for agents to send at closing
- Partner with 10 agents. Pitch: "Your competitors give gift cards. You give a free app that tracks their home forever."
- Create "New Homeowner" onboarding flow in Haven — capture property immediately, generate maintenance calendar

#### Channel 6: Financial Advisor Partnerships
- Create advisor-specific one-pager for RIAs and independent wealth advisors ($1M–$10M segment)
- Pitch: "Your clients become more organized, which makes your job easier. Haven is free."

#### Channel 7: Insurance Agent Channel
- Partner with independent agents selling homeowner's, umbrella, and life insurance
- Pitch: "When clients upload policies, Haven monitors expirations. When gaps appear, they call you — not a competitor."
- Referral flywheel: Agent recommends → client uploads → Haven flags expiration → client contacts agent

#### Channel 8: "What If?" Viral Loop
- Shareable summary card after every scenario (readiness score, gap count, CTA)
- TikTok/Instagram: 30-second "What If I Die Tomorrow" Reels
- Target "death cleaning" (döstädning) trend on social media

#### Channel 9: App Store Optimization
- Optimize listing with keywords: home management, estate planning, document organizer, home maintenance, AI assistant
- Create compelling screenshots: Scenario Studio, Alfred chat, estate readiness, document analysis
- Submit for Apple editorial consideration (design + AI innovation angle)
- Collect App Store reviews aggressively after 100+ stable users

### Phase 3: Category Leadership (Months 9–18) — Target: 50,000 Users

#### Channel 10: PR and Media
- Personal finance media (NerdWallet, Forbes Advisor, Investopedia): "Free App Uses AI to Find Estate Plan Gaps"
- Home/lifestyle media (AD, Real Simple, BH&G): "The App That Replaces the Junk Drawer"
- Tech media (TechCrunch, The Verge, 9to5Mac): "One Developer Built an AI Estate App That Outperforms $200/Year Competitors"
- Create "State of Estate Readiness" annual report using anonymized aggregate data

#### Channel 11: Community Building
- "Haven Families" monthly newsletter — tips, maintenance reminders, celebrity estate stories, updates
- Facebook Group or community forum for users
- Quarterly "Estate Planning 101" webinars with guest estate attorneys

---

## Part 6: How to Beat Each Competitor Specifically

### Beating Homer
1. Don't compete on inventory — Homer's photo → product ID is years ahead
2. Compete on intelligence — Homer tells you what you own; Haven tells you what's missing and at risk
3. Exploit reliability issues — Homer's 3.33/5 Android rating; Haven must be bulletproof
4. Exploit estate gap — "Homer tracks your stuff. Haven protects your family."
5. Target worried users — Family Reference Binder export addresses "will this app survive?" anxiety

### Beating Trustworthy
1. Price: Free vs $120–240/year
2. Home management: Trustworthy has zero property management
3. AI depth: Autopilot auto-categorizes; Haven reads documents and runs scenarios

### Beating HomeZada
1. Estate intelligence: HomeZada has no concept of estate documents
2. AI quality: Basic recommendations vs full-context conversational AI
3. Price: Free vs $59–149/year

### Beating Nines
1. Accessibility: Free and self-serve vs sales call and $1,000+/year
2. AI: Nines has none; Haven is AI-powered throughout
3. Target the mass-affluent segment Nines doesn't serve ($500K–$5M net worth)

---

## Part 7: Revenue Model

**Phase 1 (0–10K users):** Absorb API cost ($500–2,000/month). Investment phase.

**Phase 2 (10K–50K users):** Haven Pro at $4.99–9.99/month:
- Unlimited scenario simulations (free: 3/month)
- Priority AI analysis
- Family Reference Binder PDF export with custom branding
- Multi-property advanced dashboards
- Document version history
- Extended Alfred chat history

**Phase 3 (50K+ users):** Partnership revenue:
- Estate attorney referrals for outdated trusts
- Insurance company leads for expiring policies
- Home service provider leads for due maintenance
- High-intent, contextual, helpful — not advertising

**Phase 4 (100K+ users):** Anonymized data intelligence:
- "State of Estate Readiness" reports
- Market insights for insurers, real estate firms, financial institutions

---

## Part 8: 90-Day Execution Plan

### Week 1–2: Pre-Launch Preparation
- [ ] Instrument app with analytics (feature usage, return rates, onboarding completion, upload counts, scenario runs)
- [ ] Create estate attorney referral kit (one-pager, demo video, email template, QR cards)
- [ ] Write "Coming from Centriq?" landing page
- [ ] Create TestFlight invite message for friends/family

### Week 3–4: Soft Launch
- [ ] Send TestFlight to 50 personal contacts
- [ ] Visit 5 estate attorneys with referral kit
- [ ] Post "Centriq Shut Down" article on Medium
- [ ] Publish first 2 content pieces (estate checklist + celebrity estate disasters)

### Week 5–8: Iterate Based on Data
- [ ] Follow up with every tester individually
- [ ] Fix top 3 reported issues
- [ ] Measure: onboarding completion %, document upload %, D7 retention, scenario usage %
- [ ] Double down on working channel
- [ ] Publish content pieces #3–6

### Week 9–12: Scale What Works
- [ ] Expand to 10+ attorney partnerships (if validated)
- [ ] Submit to App Store for editorial consideration
- [ ] Begin real estate agent outreach (if attorney channel validated)
- [ ] Publish Haven vs Homer vs Trustworthy vs HomeZada comparison article
- [ ] Hit 500 users, begin collecting App Store reviews
- [ ] Analyze engagement data: what features drive returns? What's the "aha moment"?

### Key Metrics to Track
- **Onboarding completion rate** — target: 70%+
- **Day 7 retention** — target: 30%+ (industry avg: 15–25%)
- **Documents uploaded per user** — target: 3+ in first month
- **Scenario Studio usage** — target: 50%+ of active users try it
- **Household sharing rate** — target: 25%+ invite a second user
- **NPS score** — target: 50+

---

## Part 9: The Bottom Line

Haven's path to winning requires three things simultaneously:

**Be undeniably better.** Scenario Studio, Alfred AI, and document analysis create capabilities no competitor can match. Protect and deepen this advantage.

**Be free.** In a market where every competitor charges $60–240/year and the #1 barrier is subscription fatigue, free compounds over time.

**Build distribution through trust networks.** Estate attorneys, financial advisors, insurance agents, and real estate agents create distribution that can't be replicated by ads.

**The single sentence:** Haven is the only free app that uses AI to protect both your family's legacy and your home — and the feature that makes people talk about it at dinner parties is the one where they find out what would happen if they died tomorrow.

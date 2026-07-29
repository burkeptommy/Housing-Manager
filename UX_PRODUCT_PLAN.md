# Haven UX and Product Structure Plan

This document turns the recent UX audit into an execution plan for the product itself: how the app should feel, how the main surfaces should work together, and what structural cleanup will make Haven easier to understand for real users.

This is not a security plan. It is focused on experience, information architecture, navigation, and product clarity.

Companion spec: [PROPERTY_EXPERIENCE_REDESIGN_SPEC.md](/Users/tomburke/Documents/Projects/Housing-Manager/PROPERTY_EXPERIENCE_REDESIGN_SPEC.md)

That document is the concrete follow-on from the latest dashboard, property, maintenance, and systems feedback. It translates the audit into exact screen roles, proposed tab structure, status definitions, copy direction, and implementation priorities, with explicit guardrails for preserving Haven's existing systems intelligence.

---

## Why this plan exists

Haven already has strong product taste, a differentiated thesis, and several genuinely premium moments:

- The House Quiz is thoughtful and memorable.
- The Maintenance Hub has a strong organizing idea.
- The app voice feels intentional rather than generic.
- The product combines home operations, estate readiness, documents, and household context in a way that feels original.

The current product risk is not that Haven lacks features. It is that the experience is becoming dense enough that users can start losing the thread:

- Too many surfaces partially own the same concepts.
- The dashboard is carrying too many jobs.
- Cross-tab movement can feel magical rather than grounded.
- Some flows are polished in isolation but heavy in sequence.
- Users may not always understand what changed, why it changed, or where to go next.

The goal of this plan is to preserve Haven's ambition while making the app easier to navigate, easier to trust, and easier to grow.

---

## Product goals

Every major UX decision should move Haven toward these outcomes:

1. A new user can explain what each top-level area is for after one session.
2. A returning user can tell what matters today within a few seconds of opening the app.
3. Users always know where an item "lives" even if they encounter it through a shortcut or nudge card.
4. Haven feels smart and proactive, but never opaque or surprising.
5. High-value moments feel deliberate and premium; routine moments feel quiet and efficient.
6. Multi-property and multi-person households feel first-class, not like edge cases.

---

## UX principles

These should act as product guardrails when making future changes.

### One surface owns each core thing

Every major object in the app should have one canonical home:

- Property
- Vehicle
- Maintenance task
- Routine or service
- Document
- Family member
- Estate state
- AI conversation

Other surfaces can summarize or link to these objects, but should not partially re-own them.

### The dashboard is for priorities, not inventory

The dashboard should answer:

- What needs my attention?
- What changed?
- What should I do next?

It should not become the permanent home for every product announcement, migration card, setup nudge, and discovery path.

### Navigation should feel explicit

If the app moves the user somewhere, the destination should feel earned and explainable.

Users should not have to infer why they landed in a different tab, on a specific property, or in a sheet that appeared unexpectedly.

### Use ceremony sparingly

Big moments should feel big:

- Key onboarding trust moments
- Completion reveals
- Important plan changes
- Major AI outputs

Routine actions should feel faster and quieter.

### Haven should always show its work

Whenever Haven routes a task, changes a recommendation, suggests a vendor, or updates a plan, the user should be able to answer:

- What changed?
- Why did it change?
- Can I review or undo it?

---

## Workstream 1: Clarify top-level information architecture

### Problem

The app's current primary navigation is close, but not fully legible:

- `Dashboard` mixes home, inbox, onboarding, and product messaging.
- `Property` owns homes, systems, maintenance, and also `Your Garage`.
- `Life` currently contains documents and family.
- `Alfred` owns chat and scenario work, but other tabs still trigger AI-related flows.

That creates a cognitive burden for new users. They can use the app, but the mental model is not immediately clean.

### Objective

Make each top-level tab easy to describe in one sentence.

### Plan

Define the job of each top-level area:

- `Dashboard`: priorities, updates, and next actions
- `Property`: homes, vehicles, systems, maintenance, vendors, and projects
- `Life`: household records, family, estate context, and important documents
- `Alfred`: AI help, questions, simulations, and guided reasoning

Decide whether `Life` is the right label.

The current content of `Life` makes internal sense, but the name may not tell a first-time user enough. Before renaming it, test the current label with real users and compare it against alternatives such as:

- `Home Life`
- `Records`
- `Household`
- `Family`
- `Vault`

Do not rename the tab until the team has real user feedback on comprehension.

### Deliverables

- A written ownership map for every major feature and object in the app
- A decision document for the `Life` tab label
- A list of features that are currently duplicated across tabs and where they should ultimately live

### Done looks like

- The team can answer "where does this live?" consistently
- New work gets assigned to one obvious home
- Cross-tab links become summaries, not workarounds for weak ownership

---

## Workstream 2: Tighten the dashboard into a true control center

### Problem

The dashboard is becoming a stack of many different intentions:

- home status
- quick actions
- getting started
- vendor nudges
- migration cards
- release education
- inbox items
- cadence suggestions
- estate prompts
- activity feed

Each card is reasonable in isolation. Together they compete for attention and flatten the hierarchy of the screen.

### Objective

Make the dashboard feel immediate, selective, and trustworthy.

### Plan

Establish a dashboard card model with explicit levels:

- `Critical`: something urgent or blocking
- `Action today`: something the user should reasonably act on now
- `Useful context`: helpful but not urgent
- `Informational`: should usually not live on the dashboard

Create a dashboard card budget.

Above the fold, the dashboard should ideally contain only:

- one primary status or hero area
- one quick actions area
- one immediate action area
- one short update or context area

Move product education, migrations, and low-urgency discovery prompts off the main dashboard unless they are time-sensitive.

Add a rotation rule:

- If a card is informational and persists for more than one or two visits, it should probably move elsewhere.
- If two cards ask the user to "do setup" at the same moment, one should become a follow-up item instead.

### Deliverables

- Dashboard card taxonomy
- Dashboard content budget
- List of cards that stay, move, merge, or retire
- Updated screen spec for the default dashboard state

### Done looks like

- Users can identify the single most important thing on the dashboard quickly
- The dashboard feels calmer without feeling empty
- Product messaging no longer crowds operational value

---

## Workstream 3: Replace magical routing with explicit navigation

### Problem

Some flows currently rely on notifications, delayed posts, or fallback behavior to land the user on the right screen. This is fragile and can feel disorienting, especially when the app has multiple properties, multiple vehicles, or several valid destinations.

### Objective

Make cross-tab and deep-link movement predictable, typed, and entity-aware.

### Plan

Define a navigation model for the app's major destinations.

The model should support explicit targets such as:

- a specific property overview
- a specific property maintenance section
- a specific vehicle
- a specific task detail
- a specific document
- a specific inbox item
- Alfred with a specific context
- a specific quiz for a specific property

Every navigation entry point should pass enough context to land in the right place directly.

Examples:

- Quiz completion should route to the specific property the quiz belonged to, not whichever property is currently first.
- Dashboard shortcuts should target the exact task, vendor category, or inbox item they refer to.
- Cross-tab links should preserve context when the user comes back.

### Deliverables

- Navigation model definition
- Inventory of all current notification-based routing
- Replacement plan for delayed or indirect tab switching
- Multi-property routing rules

### Done looks like

- No more "open Property and hope the right record appears"
- Cross-tab transitions feel intentional
- Navigation bugs become easier to reason about and test

---

## Workstream 4: Simplify the post-quiz arc

### Problem

The House Quiz is one of Haven's strongest experiences, but the end of the flow risks doing too much in sequence:

- recap and trust-building
- chaptering
- milestone overlays
- saved review state
- completion reveal
- vendor coverage follow-up
- delegation suggestions
- maintenance routing

That can turn a powerful completion moment into a chain of adjacent experiences.

### Objective

Let the quiz end with clarity and momentum rather than handoff fatigue.

### Plan

Keep the high-value pieces:

- trust anchor at the beginning
- chapter structure
- running value meter
- personalized copy
- completion reveal

Reduce the number of immediate follow-up asks after completion.

The completion state should answer three things first:

- what Haven learned
- what Haven set up
- what the user should do next

Then choose one immediate follow-up behavior, not several.

If vendor coverage is the most important missing link, show that and defer delegation.
If delegation is more important for a household, show that and make vendor coverage a persistent follow-up.

Add a durable summary surface the user can revisit later:

- what tasks were added
- what tasks were removed
- which vendors were suggested
- what assumptions were made

### Deliverables

- Post-quiz state map
- Decision rule for which follow-up flow appears first
- Persistent "What Haven set up for you" summary view
- Reduced completion sequence spec

### Done looks like

- Completing the quiz feels celebratory and grounding
- Users do not feel bounced between multiple modals
- Users can revisit the results later without rerunning mental context

---

## Workstream 5: Make maintenance the clearest operational system in the app

### Problem

Maintenance is one of Haven's most valuable areas, but it currently appears through multiple surfaces:

- dashboard action cards
- property detail
- maintenance hub
- seasonal views
- task details
- handyman bundles
- vendor coverage prompts

The underlying model is getting richer, but the user-facing hierarchy can still feel layered rather than clean.

### Objective

Make maintenance feel like a coherent operating system, not a set of connected screens.

### Plan

Treat the Maintenance Hub as the main operational home for active home care.

Clarify what each section means:

- `Your Services`: recurring professional help already set up
- `Next Handyman Visit`: the bundled "small things" operational lane
- `Vehicles`: vehicle care as part of the household system
- `This Season`: time-sensitive work that still needs routing
- `Upcoming Scheduled`: already-placed commitments

Then reduce maintenance-like summaries elsewhere.

Dashboard and property overview should summarize maintenance state and link into it, but not compete with it as a second control surface.

Make status transitions more legible:

- what is planned
- what is unassigned
- what is waiting on a pro
- what is on the user's plate
- what is already scheduled

### Deliverables

- Maintenance ownership map
- State language for task lifecycle
- Rules for which maintenance content appears on Dashboard vs Maintenance vs Property Overview
- Copy pass for maintenance states and labels

### Done looks like

- Users can understand the difference between "service," "task," "visit," and "scheduled"
- The maintenance hub feels like the place where work actually lives
- Dashboard stops acting like a second maintenance inbox

---

## Workstream 6: Reconcile Property, Garage, Vehicles, and household asset structure

### Problem

Vehicles are valuable in Haven, but their placement across Property and Maintenance can muddy the overall asset model. Users may not be sure whether vehicles are part of the home system, their personal household system, or a separate operating area.

### Objective

Make Haven's asset model feel intentional rather than inherited from implementation history.

### Plan

Decide and document the product thesis:

- Are vehicles part of the property ecosystem?
- Are they part of the household operating system?
- Are they their own asset category that appears under Property only because it is the closest fit today?

If the answer is "household operating system," keep them in Property for now but make the copy and navigation reflect that clearly.

Potential model:

- Property tab becomes the home for all managed assets
- Homes and vehicles are both managed assets
- Maintenance then acts on those assets

If that is the thesis, the app should say so consistently.

### Deliverables

- Asset model definition
- Copy and naming guidance for vehicles in Property and Maintenance
- Decision on whether "Your Garage" remains a sub-section of Property or evolves later

### Done looks like

- Users do not ask why the car lives under Property
- Vehicles feel intentionally included, not bolted on

---

## Workstream 7: Clarify the role of Alfred in the product

### Problem

Alfred is one of Haven's differentiators, but AI functionality currently spills into other surfaces through prompts, nudges, and scenario entry points. That is useful, but it can blur the boundary between "I am talking to Alfred" and "the app is making product decisions."

### Objective

Make Alfred feel deeply integrated without making the app feel vague about who is acting.

### Plan

Define when the product should:

- open Alfred
- ask for Alfred
- show an Alfred-generated recommendation inside another screen
- quietly use Alfred behind the scenes

Make all Alfred entry points legible:

- from dashboard
- from property
- from documents
- from scenario flows

Where Alfred is invoked from another tab, preserve the initiating context visibly so the user knows why they are in chat.

Examples:

- "Ask Alfred about this document"
- "Ask Alfred about this property"
- "Run a scenario for this home"

### Deliverables

- Alfred interaction model
- Standardized entry point patterns
- Context banner or similar cue for Alfred-originated handoffs

### Done looks like

- Alfred feels powerful and consistent
- Users understand when the assistant is advising versus when the product itself is changing state

---

## Workstream 8: Add a durable change ledger

### Problem

Haven increasingly makes meaningful recommendations and structural updates:

- task routing
- vendor delegation
- cadence suggestions
- maintenance plan adjustments
- document analysis outcomes

The app often presents these changes in the moment, but there is not yet a clear durable place to review them later.

### Objective

Make Haven's intelligence reviewable.

### Plan

Create a user-facing change ledger that records meaningful app actions and recommendations.

This does not need to be a raw system log. It should be an understandable human record:

- what changed
- when it changed
- why it changed
- what object it affected

Examples:

- "Haven moved 4 HVAC tasks into your vendor-managed service because you added Coastal Heating."
- "Haven marked your roof inspection as vendor-only based on your quiz preferences."
- "Gap analysis found 3 missing estate documents."

This ledger should be reachable from:

- dashboard activity
- maintenance flows
- document intelligence surfaces

### Deliverables

- Change ledger model
- Entry types and copy rules
- Screen for reviewing recent product-driven changes

### Done looks like

- Users can answer "What did Haven do for me?"
- Trust improves because intelligence becomes inspectable

---

## Workstream 9: Reduce dead ends, duplicates, and silent failures

### Problem

Some actions are duplicated, some are no longer the best path, and at least one documented action is currently dead. Small issues like this do not just create bugs; they erode the sense that the product is carefully composed.

### Objective

Make every action path feel maintained and intentional.

### Plan

Run a full CTA audit across the app:

- toolbar actions
- dashboard cards
- quick actions
- empty states
- menu items
- overflow menus
- sheet-only actions
- cross-tab shortcuts

For each action, verify:

- it opens the right destination
- it targets the right entity
- it is still the best path
- it is not duplicated in a confusing way
- it has a return path

Fix immediate issues first, including the Life/Documents `Gap Analysis` action.

Then mark every outdated, redundant, or ambiguous action for one of four outcomes:

- keep
- rename
- move
- remove

### Deliverables

- CTA inventory
- Duplicate-path inventory
- Dead-end and silent-failure bug list
- Cleanup pass across the main tabs

### Done looks like

- No dead CTAs
- No hidden "best path" behind old paths
- A cleaner sense of direction across the app

---

## Workstream 10: Strengthen multi-property and multi-household clarity

### Problem

The app's model is increasingly sophisticated, but some behaviors still appear optimized for the common case of one household and one main property. That becomes risky as soon as the user has more than one property or more complex household structure.

### Objective

Make entity context explicit everywhere it matters.

### Plan

Audit the app for any flow that assumes a default property or household context.

Examples to verify:

- Dashboard shortcuts
- Quiz completion routes
- maintenance routing
- vendor coverage
- task detail links
- document-to-property flows
- estate summaries

Where Haven takes action on a specific entity, the UI should say which entity is in scope.

Examples:

- which property this task belongs to
- which vehicle a maintenance program belongs to
- which household member a document is tied to

### Deliverables

- Multi-property audit list
- Context-display rules
- Updated routing behavior for entity-specific flows

### Done looks like

- Multi-property households feel supported, not merely tolerated
- Users can always tell which property or asset they are editing

---

## Workstream 11: Do a naming and language pass across the whole product

### Problem

As Haven has expanded, some labels now reflect implementation history more than user mental models:

- Life
- routines
- services
- handyman visit
- scheduled
- to schedule
- gap analysis
- scenario studio

The terms are not wrong, but the product now needs a more deliberate vocabulary system.

### Objective

Make the product speak one coherent language.

### Plan

Create a vocabulary table for product terms:

- preferred label
- plain-English meaning
- where it appears
- words to avoid

Focus especially on places where users could confuse:

- task vs service vs visit
- property vs household
- family vs life
- recommendation vs automation
- chat vs Alfred vs scenario

### Deliverables

- Product vocabulary guide
- Rename candidates with rationale
- Copy cleanup list for nav, section headers, empty states, and action buttons

### Done looks like

- The product feels more cohesive without losing personality
- Users hear the same concept described the same way across screens

---

## Workstream 12: Build a standing UX review loop

### Problem

Haven is shipping quickly and inventing new patterns as it grows. Without a standing review loop, good decisions can drift over time and polished features can accumulate complexity around them.

### Objective

Make UX quality a maintained system rather than a one-time cleanup.

### Plan

Set a recurring review habit for major feature work:

- before build: define the feature's canonical home and primary job
- before ship: run CTA and navigation review
- after ship: review real-user behavior and confusion points

Use real-user testing as the anchor, not just internal taste.

Track recurring questions:

- Where did users hesitate?
- What did they mislabel?
- What did they expect to find somewhere else?
- Which cards or prompts did they ignore?
- Which flows felt impressive but tiring?

### Deliverables

- UX review checklist for new features
- Post-release observation template
- Monthly product-structure review ritual

### Done looks like

- New features fit the app more naturally
- UX debt gets caught earlier

---

## Decisions the team should make explicitly

These decisions should not stay implicit:

- What is the exact job of the dashboard?
- Is `Life` the long-term name for documents plus family plus estate context?
- Are vehicles a property asset, a household asset, or both?
- Which post-quiz follow-up gets first priority when several are valid?
- What product actions must always leave a durable trail?
- Which surfaces are allowed to trigger Alfred directly?

---

## Suggested success metrics

Use these to judge whether the cleanup is working.

- Users can correctly predict where to go for a task without prompting.
- Fewer wrong-tab journeys during user testing.
- Fewer surprised reactions to navigation jumps.
- Faster completion of core tasks in moderated sessions.
- Better recall of what Haven changed or recommended.
- Higher confidence after quiz completion and maintenance setup.

---

## Final note

The main thing Haven is missing is not ambition, features, or product taste.

What it needs now is stronger product structure around the ambition it already has. The app is beginning to outgrow "smart additions" and needs a clearer system for ownership, navigation, and follow-through. If that structure gets tighter, the existing product strengths will land much more clearly with real users.

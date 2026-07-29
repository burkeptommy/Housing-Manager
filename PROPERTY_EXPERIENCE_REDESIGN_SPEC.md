# Haven Property Experience Redesign Spec

This document turns the latest product feedback into a concrete redesign direction for Haven's core homeowner experience.

It is intentionally opinionated. The goal is to help the app answer the right homeowner questions in the right place, while preserving the differentiated systems intelligence Haven has already built.

## North Star

When a homeowner opens Haven, they should be able to answer these questions in about 10 seconds:

- What needs my attention?
- What is Haven already handling?
- What is scheduled?
- What is missing?
- What is the current state of my home?

The product should feel like a home operating system, not a collection of internal objects.

## Core Recommendation

The product should be organized around three primary property-level surfaces:

- `Dashboard` = command center across the household
- `Property Overview` = source of truth for the property
- `Property Maintenance` = operating plan for maintaining the property

And there should be one additional first-class surface that protects Haven's existing advantage:

- `Property Systems` = the asset registry and equipment intelligence layer

The key product move is not to remove systems from maintenance. It is to stop hiding systems inside maintenance.

## Non-Negotiable: Preserve Systems Intelligence

Haven already has valuable systems infrastructure that should become more visible, not less visible.

Existing capabilities already in the product include:

- Home systems grouped by category and surfaced in property detail
- Appliance and equipment onboarding from the House Quiz
- Manual system creation and specialty-system discovery
- Equipment catalog search
- Photo-based model and serial plate identification
- Supabase-backed equipment catalog matching
- Brand identity and branded system cards
- Reliability scores and score summaries
- Manual lookup and cached manual links
- Per-system service intervals
- Warranty tracking
- Child systems and component hierarchies
- Preferred vendor assignment at the system level

Relevant implementation anchors:

- Property tabs and current systems placement: [PropertyDetailView.swift](/Users/tomburke/Documents/Projects/Housing-Manager/Haven/Features/Property/Views/PropertyDetailView.swift:3)
- System data model: [DatabaseModels.swift](/Users/tomburke/Documents/Projects/Housing-Manager/Haven/Core/Networking/DatabaseModels.swift:745)
- System detail experience: [SystemDetailView.swift](/Users/tomburke/Documents/Projects/Housing-Manager/Haven/Features/Property/Views/SystemDetailView.swift:3)
- Grouped systems browse experience: [SystemGroupListView.swift](/Users/tomburke/Documents/Projects/Housing-Manager/Haven/Features/Property/Views/SystemGroupListView.swift:3)
- Equipment photo identification flow: [EquipmentIdentifySheet.swift](/Users/tomburke/Documents/Projects/Housing-Manager/Haven/Features/Property/Views/EquipmentIdentifySheet.swift:4)
- Add system and catalog-backed setup: [AddSystemView.swift](/Users/tomburke/Documents/Projects/Housing-Manager/Haven/Features/Property/Views/AddSystemView.swift:3)
- Search equipment edge function: [search-equipment/index.ts](/Users/tomburke/Documents/Projects/Housing-Manager/supabase/functions/search-equipment/index.ts:138)
- Photo identify edge function: [identify-equipment/index.ts](/Users/tomburke/Documents/Projects/Housing-Manager/supabase/functions/identify-equipment/index.ts:1)
- Appliance systems seeded during quiz: [HouseQuizAnswerMapper.swift](/Users/tomburke/Documents/Projects/Housing-Manager/Haven/Features/Onboarding/HouseQuiz/HouseQuizAnswerMapper.swift:203)

This is not support infrastructure. It is a product moat.

## Product Model

The user-facing model should be simplified to six concepts:

- Home status
- Systems
- Vendors and utilities
- Tasks and decisions
- Documents
- Schedule

Internally, Haven can still use systems, routines, tasks, templates, service records, and setup states. User-facing language should stay grounded in the homeowner's mental model.

## Status System

Haven needs two different kinds of status that are currently getting blurred together.

### 1. System identity status

This answers: do we know what this thing actually is?

- `Identified`
- `Partly identified`
- `Needs model info`

`Identified` means Haven knows enough about the system to attach model-specific intelligence such as brand, model, manuals, reliability, specs, or warranty context.

### 2. Maintenance coverage status

This answers: can Haven actually manage this system?

- `Covered`
- `Needs vendor`
- `Needs document`
- `Scheduled`
- `Haven handling`
- `Waiting on vendor`
- `You're handling`
- `Done`

`Covered` should be explicitly defined in the product:

- a maintenance owner is known
- the cadence is known
- Haven can track upcoming work
- the system is ready to participate in the maintenance plan

This definition should be accessible from the UI with a small explainer link.

### Why this distinction matters

A refrigerator can be:

- identified, because Haven knows it is a Bosch 800 Series unit
- not yet covered, because no cadence or owner has been set

That is a better product story than forcing one overloaded label to do both jobs.

## Recommended Property Detail Structure

Property detail should move from:

- `Overview`
- `Maintenance`
- `Projects`
- `Contacts`

to:

- `Overview`
- `Maintenance`
- `Systems`
- `Projects`
- `Contacts`

Why this is the right fifth tab:

- `Maintenance` is for what needs to happen
- `Systems` is for what the home actually contains
- `Overview` is for the state of the property as a whole
- `Projects` is for larger scoped work
- `Contacts` is for the people and companies attached to the property

### Important layout note

The current sticky tab selector will likely feel too cramped at five tabs. The implementation should shift to a lighter tab treatment:

- horizontally scrollable pill tabs
- or a slimmer text-first segmented header

The current heavy pinned header should get less vertical weight either way.

## Property Overview

The property overview should become the source of truth for the home, not primarily a finance surface.

### Recommended content order

1. Property identity
2. Ask Alfred about this property
3. Home status
4. Systems snapshot
5. Vendors and utilities
6. Documents
7. Value and protected equity

### Recommended hero content

`236 Sarles Street`

`Single-family residence`

`Est. value: $2.5M`

`Ask Alfred about this property`

Suggested prompts:

- What needs attention this month?
- Which vendors are missing?
- Which systems still need model info?
- What maintenance protects resale value?

### Home status card

This should be the lead operating card.

Example:

`Home status`

- `9 of 19 systems covered`
- `14 of 19 systems identified`
- `4 suggested documents missing`
- `Next visit: Landscaping · Apr 21`

CTAs:

- `Review maintenance`
- `View systems`

### Systems snapshot card

This is the bridge between overview and the full Systems tab.

Example:

`Systems`

- `19 tracked`
- `14 identified`
- `3 need attention`
- `6 manuals linked`

Preview rows:

- `HVAC · Trane · Identified · Covered`
- `Refrigerator · Bosch 800 Series · Identified · Covered`
- `Water heater · Needs model info · Needs vendor`

CTA:

- `Open systems`

### Vendors and utilities

Keep this section, but make it easier to scan.

Recommendations:

- use a 2-column layout or list rows instead of a cramped 3-column grid
- prefer category-first scan patterns when helpful
- show one operational line per item

Examples:

- `Electric · Con Edison · Active`
- `Internet · Optimum · Bill tracking off`
- `Irrigation · Aqua Lawn · Next visit Apr 21`
- `Pest · JP McHale · Covered`

### Documents

This section should show what is missing, not just that something is missing.

Example:

`Property documents`

- `0 uploaded`
- `4 suggested`

Suggested:

- `Deed`
- `Home insurance policy`
- `Survey or site plan`
- `Recent inspection report`

CTA:

- `Upload document`

### Value and protected equity

Keep the investment/value layer, but move it below operations.

Recommendations:

- soften language around unrealized loss
- reserve high precision for true inputs, not estimated value
- connect protected equity directly to maintenance action

Example:

`Value and protected equity`

- `Estimated value: $2.5M`
- `Range: $1.9M to $3.1M`
- `Maintenance helps protect resale value`

CTAs:

- `See value breakdown`
- `Review maintenance plan`

## Property Maintenance

The Maintenance tab should be the actual maintenance hub for this property. It should not feel like an index page before the real maintenance experience.

### Structural rule

Dashboard and property overview should deep-link directly into the property's Maintenance tab, not to a separate intermediate maintenance landing screen.

### Recommended section order

1. Home status
2. Needs your attention
3. Upcoming
4. Handyman list
5. Active programs
6. Coverage by system
7. Recommended

The current Phase 66 direction already contains strong building blocks for this, especially `Home status`, `Needs your decision`, `Upcoming scheduled`, `Active programs`, and the handyman bundle concepts in [MaintenanceHubSections.swift](/Users/tomburke/Documents/Projects/Housing-Manager/Haven/Features/Property/Views/Components/MaintenanceHubSections.swift:21).

### Maintenance hero

Do not lead with total task inventory.

Avoid:

- `65 tasks on your plan`
- `62 vendor / 1 DIY`

Prefer:

`Maintenance status`

- `9 of 19 systems covered`
- `3 visits scheduled`
- `5 need attention`
- `1 task for you`

CTAs:

- `Review open items`
- `View schedule`

### Needs your attention

This section should include only homeowner-owned blockers and decisions.

Examples:

- `Assign vendors to 10 systems`
- `Upload 4 maintenance documents`
- `Confirm cadence for lawn care`
- `Fire extinguisher annual check`

This is where ownership clarity matters most.

Each card should clearly indicate one of:

- `Owner: You`
- `Owner: Haven`
- `Owner: Vendor`
- `Waiting on vendor`
- `Scheduled`

### Upcoming

This should show scheduled visits and near-term work, not generic future inventory.

Examples:

- `Apr 21 · Landscaping · Hickory Homes`
- `Apr 21 · Irrigation · Aqua Lawn`
- `Apr 22 · Trash pickup · Bedford Sanitation`

### Handyman list

Keep the current bundling concept. Improve the copy logic.

Single item:

- `1 handyman task waiting`
- `We will keep small jobs here until you are ready to send them out`

Multiple items:

- `Handyman bundle ready`
- `4 small jobs can likely be handled in one visit`

CTA logic should depend on whether a handyman exists.

### Active programs

Use this label in UI instead of `Routines`.

Examples:

- `Landscaping`
- `Trash and recycling`
- `HVAC`
- `Pest control`
- `Pool`
- `Irrigation`

### Coverage by system

This is how systems should stay visible inside maintenance without maintenance becoming a systems browser.

Examples:

- `Climate · 2 of 4 covered`
- `Outdoor · 4 of 7 covered`
- `Appliances · 6 of 8 covered`
- `Plumbing · 3 of 5 covered`

This section is a coverage map and drilldown entry point, not the full systems registry.

### Recommended

Recommendations should come after open work.

Examples:

- `Garage door tune-up`
- `Water heater service`
- `Generator service`

Use copy like:

- `Recommended services`
- `Suggested for this home`

Avoid more abstract language like `value-preservation services` unless it is supporting copy, not the primary label.

## Property Systems

This should be the full asset registry for the home.

### Systems tab job

The Systems tab should answer:

- What systems do I have?
- Which ones are identified?
- Which ones are covered?
- Which ones need attention?
- Which ones have manuals, warranties, or missing model info?

### Recommended top summary

`Systems`

- `19 tracked`
- `14 identified`
- `9 covered`
- `3 need attention`
- `6 manuals linked`

Subtext:

`Systems power Haven's maintenance plan. Identify them once and Haven can track manuals, reliability, vendors, and service history.`

### Recommended sections

1. Summary metrics
2. Quick actions
3. Grouped systems
4. Suggested setup gaps

### Quick actions

- `Identify equipment`
- `Add system`
- `Browse specialty systems`
- `Upload manual or warranty`

These actions already align with current functionality in [AddSystemView.swift](/Users/tomburke/Documents/Projects/Housing-Manager/Haven/Features/Property/Views/AddSystemView.swift:69) and [EquipmentIdentifySheet.swift](/Users/tomburke/Documents/Projects/Housing-Manager/Haven/Features/Property/Views/EquipmentIdentifySheet.swift:66).

### Grouped systems

Reuse the current grouping model:

- `Climate and energy`
- `Structure and exterior`
- `Plumbing and water`
- `Outdoor and landscaping`
- `Backup and resilience`
- `Utilities and services`
- `Safety`
- `Appliances`
- `Other systems`

The current `SystemGroup` model already supports this grouping and should remain the backbone of the surface.

### System row model

Each row should show three layers of information:

1. What it is
2. Whether it is identified
3. Whether it is covered

Recommended row example:

`Kitchen Refrigerator`

- `Bosch · B36CL80SNS`
- `Appliance · Refrigerator`
- `Identified`
- `Covered`
- `Reliability 86`

Or for an incomplete system:

`Water heater`

- `Model info missing`
- `Needs vendor`
- `No manual linked`

### Appliance-specific opportunity

Appliances deserve to shine because Haven already has a differentiated flow here.

The Systems tab should make appliance intelligence obvious:

- model photo scan
- catalog matching
- manuals
- reliability
- warranty context
- service cadence

This is especially important because appliances are one of the easiest ways for users to feel the product "get smarter" after setup.

### Specialty systems

Pool, spa, generator, EV charger, wine cellar cooling, elevator, water treatment, and similar systems should remain accessible through specialty-system discovery, but the user should encounter them from the Systems tab, not only from Contacts.

## Dashboard

The Dashboard should become the daily command center.

### Required question set

The top of the dashboard should answer:

- Is anything urgent?
- What does Haven need from me?
- What is coming up next?
- What is already covered?

### Recommended order

1. Greeting and seasonal framing
2. Home status hero
3. Needs your attention
4. Upcoming
5. Quick actions
6. Handyman list
7. Recent activity

### Dashboard hero

Example:

`Good morning, Tom`

`Spring prep: 5 things need attention`

`Home status`

- `236 Sarles Street`
- `9 of 19 systems covered`
- `14 systems identified`
- `10 need vendors`
- `Next visit: Landscaping · Apr 21`

CTA:

- `Review maintenance`

Small link:

- `What does covered mean?`

### Needs your attention

This should be the most important list on the dashboard after the hero.

Examples:

- `Assign vendors to 10 systems`
- `Upload 4 suggested documents`
- `Finish estate setup: 1 question left`
- `Identify 3 appliances to unlock manuals and reliability`

This last example matters because it preserves the systems intelligence story at the dashboard level without turning the dashboard into a systems browser.

### Upcoming

Keep it concise and operational.

Examples:

- `Apr 21 · Landscaping`
- `Apr 21 · Irrigation`
- `Apr 22 · Trash pickup`

### Quick actions

Use clearer labels:

- `Ask Alfred`
- `Upload document`
- `Add vendor`
- `Add task`

If scenarios stay on the dashboard, prefer a more understandable label:

- `Plan ahead`
- `What if?`

### Recent activity

Move this lower and make each item more explicit.

Examples:

- `Sustainable Heating & Cooling added as HVAC vendor`
- `Village Exterminating added for pest control`
- `Aqua Lawn linked to irrigation`

Chevrons should appear only when there is a meaningful destination.

## Property List

The Property tab should emphasize operating status over valuation.

Recommended property card shape:

`236 Sarles Street`

`Single-family residence`

- `9 of 19 systems covered`
- `10 systems need vendors`
- `Next visit: Landscaping · Apr 21`

Secondary line:

- `Est. value: $2.5M`

CTA:

- `Open property`

If the next meaningful visit is far away, prefer:

- `No upcoming visits scheduled`

over a confusing far-future event.

## Vehicles and Assets

The current `Your Garage` treatment should be reconsidered.

Recommendation:

- rename it to `Vehicles`
- or expand it into a broader `Assets` section if more asset types are coming

Vehicle cards should be operational:

`2017 Land Rover Range Rover Sport`

- `13 service items`
- `No shop assigned`

CTA:

- `Set up shop`

This aligns with the current vehicle direction already visible in the maintenance hub sections.

## Copy and Language Direction

### Replace internal language

Prefer:

- `Assign vendors to 10 systems`
- `1 handyman task is waiting`
- `Finish setup`
- `1 estate question left`
- `62 handled by vendors · 1 for you`
- `Active programs`

Avoid:

- `10 systems need a vendor`
- `You have 1 things for your handyman`
- `Continue estate setup`
- `65 tasks on your plan`
- `Routines`
- `Scenarios` without supporting context

### Normalize formatting

Fix:

- `1 things`
- `Auto_Insurance`
- `Pool_Service`
- placeholder `Vendor`
- excessive letter spacing in body copy

## Visual and Interaction Polish

### Typography

- reserve tracking for small section labels
- do not use heavy letter spacing in normal body text
- allow important names to wrap to two lines when needed

### Color semantics

Use status color consistently:

- red or coral = urgent, overdue, blocking
- gold = incomplete setup or recommended follow-up
- purple or indigo = standard Haven-managed state
- green = covered, scheduled, complete
- gray = informational or inactive

Missing vendors should not be styled as an emergency unless the missing vendor is actively blocking imminent work.

### Truncation

For vendor and utility names:

- prefer 2-column cards or list rows over dense 3-column tiles
- allow wrapping for primary names
- consider category-first rows when that improves scanability

### Bottom safe area

Ensure final buttons and rows can fully scroll above the tab bar.

## Ownership Rules

Every meaningful item in the maintenance experience should clearly show ownership.

Accepted labels:

- `You`
- `Haven`
- `Vendor`
- `Waiting on vendor`
- `Scheduled`
- `Done`

This should apply to:

- maintenance tasks
- grouped system gaps
- handyman items
- service programs
- seasonal tasks

## Bulk Flows

Grouped problems should become grouped flows.

### Vendors

`Assign vendors to 10 systems`

Inside:

- `Use existing vendors`
- `Add my own contacts`
- `Ask Haven to find options`
- `Skip for now`

### Documents

`Upload 4 suggested documents`

Inside:

- `Home insurance policy`
- `Deed`
- `Survey`
- `Recent inspection`

### Systems

`Identify 3 systems`

Inside:

- `Take a photo`
- `Search catalog`
- `Add manually`

### Handyman

`Bundle 4 small jobs into one visit`

These grouped flows are part of what makes Haven feel like orchestration rather than tracking.

## Implementation Direction

### Recommended rollout order

1. Add `Systems` as the fifth property tab and move full systems browsing there.
2. Redesign Property Overview so home operations come before value.
3. Make the property Maintenance tab the actual maintenance hub and route dashboard/property cards directly into it.
4. Redesign the dashboard around `Home status`, `Needs your attention`, and `Upcoming`.
5. Standardize ownership language, `covered` definition, and copy cleanup.
6. Reduce truncation and improve safe-area spacing.

### Lowest-risk reuse strategy

This redesign should reuse existing work rather than replacing it:

- keep `SystemGroup`, `SystemGroupListView`, and `SystemDetailRowView` as the core of the Systems tab
- reuse equipment search and photo identification as first-class setup actions
- reuse the Phase 66 maintenance sections and recast their wording and hierarchy
- keep system detail as the deep intelligence surface
- keep appliance seeding and specialty-system discovery intact

### Specific code implications for a later implementation pass

- Add `.systems` to `PropertyDetailTab` and update the tab selector in [PropertyDetailView.swift](/Users/tomburke/Documents/Projects/Housing-Manager/Haven/Features/Property/Views/PropertyDetailView.swift:3)
- Move `systemsSection` out of the maintenance tab's primary content and turn it into a dedicated tab backed by the existing grouped browse flow [PropertyDetailView.swift](/Users/tomburke/Documents/Projects/Housing-Manager/Haven/Features/Property/Views/PropertyDetailView.swift:1075)
- Replace the overview tab's top-first `InvestmentSummaryCard` priority with a home-status-first layout [PropertyDetailView.swift](/Users/tomburke/Documents/Projects/Housing-Manager/Haven/Features/Property/Views/PropertyDetailView.swift:510)
- Make the overview maintenance card switch into the property's Maintenance tab instead of pushing an extra maintenance destination [PropertyDetailView.swift](/Users/tomburke/Documents/Projects/Housing-Manager/Haven/Features/Property/Views/PropertyDetailView.swift:783)
- Retain `MaintenanceStatusSection` and related Phase 66 structures as the backbone of the property maintenance hub [MaintenanceHubSections.swift](/Users/tomburke/Documents/Projects/Housing-Manager/Haven/Features/Property/Views/Components/MaintenanceHubSections.swift:21)

## Final Product Thesis

Haven should feel like this:

- your home is okay
- here is what needs your attention
- here is what Haven is already handling
- here is what is scheduled
- here is what is missing
- here is how to protect the home and its value

And, importantly:

- here is what your home actually contains

That last line is why `Systems` should be first-class.

The Maintenance experience should make the home operable.

The Systems experience should make the home legible.

Haven needs both.

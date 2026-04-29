# Haven Real User Test Plan

This document is a full real-user testing guide for Haven. It is designed for moderated sessions with real participants, not internal QA. The goal is to learn how users understand the product, where they get confused, what feels impressive, what feels heavy, and which parts of the app they trust or ignore.

This is not a bug bash. It is a product-comprehension and usability plan.

---

## Goals

This testing plan is meant to answer six product questions:

1. Do users understand what Haven is for after their first few minutes?
2. Do users understand what each top-level area of the app is for?
3. Can users complete the core tasks without hand-holding?
4. Do users understand what Haven changed for them and why?
5. Which parts of the product feel premium and differentiated?
6. Which parts feel confusing, dense, or overly managed?

---

## What to learn from these sessions

Specifically, we want to observe:

- whether users understand the labels `Dashboard`, `Property`, `Life`, and `Alfred`
- whether users know where to go for documents, vendors, maintenance, and family information
- whether the dashboard feels focused or overloaded
- whether the House Quiz feels motivating or too choreographed
- whether maintenance is easy to understand once the plan is generated
- whether users trust Haven's recommendations
- whether AI features feel contextual and useful or vague and bolted on
- whether users can recover when Haven moves them between screens

---

## Who to recruit

Recruit a mix of users who resemble the intended Haven audience or adjacent buyers.

Aim for 8 to 12 participants total, split across these groups:

### Group 1: Primary household operators

People who already manage most of the home's logistics:

- scheduling maintenance
- tracking vendors
- storing household records
- handling recurring property decisions

### Group 2: Shared-decision households

People in a couple or family setting where home decisions are shared. This group helps reveal:

- whether household concepts are clear
- whether family features feel useful or overbuilt
- whether ownership and delegation make sense

### Group 3: High-document households

People who care about records, estate readiness, family administration, or document organization. This group helps test:

- document trust
- Life tab comprehension
- estate-value perception

### Group 4: Asset-heavy households

People with more than one property, a second home, or several vehicles. This group helps expose:

- context confusion
- multi-property assumptions
- wrong-default routing behavior

---

## Recommended session mix

Do not try to run every scenario with every participant. Split testing into three session types.

### Session Type A: First-time product comprehension

Focus:

- first impressions
- onboarding
- House Quiz
- nav comprehension
- dashboard meaning

Target participants:

- new or lightly primed users

Session length:

- 45 to 60 minutes

### Session Type B: Returning-user daily operations

Focus:

- dashboard
- maintenance
- vendors
- document retrieval
- Alfred

Target participants:

- users working from a seeded account with existing data

Session length:

- 45 to 60 minutes

### Session Type C: Complex household and trust

Focus:

- family and household mental model
- estate and records perception
- multi-property behavior
- AI trust

Target participants:

- users with more administrative or household-management complexity

Session length:

- 60 minutes

---

## Test setup

### Device setup

Use a real iPhone whenever possible. Avoid the simulator for moderated real-user sessions unless absolutely necessary.

### Test build

Use a stable seeded build with realistic demo content.

### Seeded account requirements

Prepare at least three test accounts:

#### Account A: New user / near-empty state

- no completed quiz
- no documents
- one property ready for onboarding

#### Account B: Active household

- one primary property
- completed quiz
- documents uploaded
- maintenance plan populated
- some tasks due
- one or two vendors
- activity history

#### Account C: Complex household

- multiple properties or one property plus vehicle-heavy profile
- household members
- estate-related documents
- mixed maintenance states
- at least one vendor coverage gap

### Moderation setup

Record screen and audio if participants consent. Have a note-taker when possible.

---

## Rules for moderators

- Do not explain where features live unless the participant is fully blocked.
- Ask "What are you thinking?" more often than "Did you like that?"
- Let users make wrong turns; those are often the most valuable moments.
- Do not rescue immediately when they hesitate.
- Ask what they expected before you show them the correct path.
- Capture exact language users use. Their labels matter.

---

## What to capture in every session

For every task, note:

- whether the user completed it
- how long it took
- whether they hesitated
- where they looked first
- where they expected to find it
- whether the copy matched their expectation
- whether the outcome felt trustworthy

Also tag moments with these labels:

- `Nav confusion`
- `Label confusion`
- `Too much information`
- `Unexpected navigation`
- `Strong delight`
- `Strong trust`
- `AI uncertainty`
- `Entity context confusion`

---

## Core testing script

Use these questions at the start of every session.

1. "Before tapping anything, what do you think this app does?"
2. "What would you expect to find under each tab?"
3. "If you had to guess, where would you go for your home records? Where would you go for maintenance? Where would you go for household people?"

These questions are extremely important. They reveal whether the product structure is already self-explanatory.

---

## Session Type A: First-time product comprehension test list

### Task A1: First impression of the home screen

Prompt to read:

"Take a look at this screen and tell me what you think this app is for, who it is for, and what you would do first."

What to watch for:

- whether the user understands Haven's thesis
- whether they mention documents, maintenance, family, or AI
- whether the dashboard gives a clean first impression
- whether they seem intrigued or overwhelmed

Follow-up questions:

- "What on this screen feels most important?"
- "What feels optional?"
- "Is anything on this screen confusing right away?"

### Task A2: Predict the navigation

Prompt to read:

"Without tapping yet, tell me what you think lives under Dashboard, Property, Life, and Alfred."

What to watch for:

- whether `Life` is understood
- whether users assume documents belong under Property
- whether Alfred is understood as chat, help, or something else

Follow-up questions:

- "Which tab name is clearest?"
- "Which one feels vaguest?"

### Task A3: Start onboarding

Prompt to read:

"Imagine you just signed up and want to get Haven set up for your home. Show me what you would do."

Success means:

- user can find the right path into setup without coaching

What to watch for:

- whether they start from Dashboard or Property
- whether empty states feel clear and motivating
- whether the first action feels obvious

### Task A4: Early House Quiz trust

Prompt to read:

"Go through the beginning of this setup and say out loud what you think the app is learning about you."

What to watch for:

- whether the recap/trust layer feels reassuring
- whether the quiz feels premium or long
- whether users understand why the questions matter

Follow-up questions:

- "Does this feel worth doing?"
- "Do you feel like the app is asking good questions or too many questions?"

### Task A5: Mid-quiz motivation

Prompt to read:

"Keep going until you have a good sense of the rhythm. Tell me when the flow feels engaging and when it feels like work."

What to watch for:

- reaction to chapter intros
- reaction to the running value meter
- reaction to milestone moments
- whether the sequence feels energetic or over-produced

### Task A6: Quiz completion clarity

Prompt to read:

"Finish the setup and tell me what the app just did for you."

What to watch for:

- whether users can describe the outcome in plain English
- whether they understand the completion screen
- whether follow-up prompts feel helpful or too stacked
- whether they know where to go next

Follow-up questions:

- "If you came back tomorrow, where would you look to see the result of this setup?"
- "Do you feel finished, or does it still feel like setup is continuing?"

---

## Session Type B: Returning-user daily operations test list

### Task B1: Read the dashboard

Prompt to read:

"You are opening Haven for the first time today. Tell me what matters on this screen and what you would do first."

What to watch for:

- whether users know where to focus
- whether too many cards compete
- whether the hero area is informative
- whether dashboard content feels curated or crowded

Follow-up questions:

- "Is there anything here that feels like it should live somewhere else?"
- "What would you ignore?"

### Task B2: Find something due soon

Prompt to read:

"Find something around the house that needs attention soon."

What to watch for:

- whether they use Dashboard, Property, or Maintenance first
- whether task states are understandable
- whether the path to maintenance feels natural

### Task B3: Understand the Maintenance Hub

Prompt to read:

"Walk me through what each section here means in your own words."

What to watch for:

- whether users understand `Your Services`
- whether they understand `Next Handyman Visit`
- whether `This Season` and `Upcoming Scheduled` are clearly distinct
- whether vehicle care feels naturally placed

Follow-up questions:

- "If you wanted to hire help, where would you start?"
- "If you wanted to see everything you are responsible for personally, where would you look?"

### Task B4: Route a maintenance task

Prompt to read:

"Pick one task and show me how you would decide who should handle it."

What to watch for:

- whether users understand vendor-managed versus DIY versus handyman
- whether the routing choices feel intuitive
- whether they understand the effect of their choice

Follow-up questions:

- "What did you think would happen when you chose that?"
- "Would you expect to be able to change this later?"

### Task B5: Find a vendor or add a vendor

Prompt to read:

"Imagine you need someone to take over a category of work. Show me how you would find or add that person."

What to watch for:

- whether users know where vendor management lives
- whether Dashboard, Property, and Maintenance compete for this action
- whether the flow feels direct or detoured

### Task B6: Find a specific document

Prompt to read:

"Find an important document you would want to retrieve quickly for your household."

What to watch for:

- whether users go to `Life`
- whether the tab label slows them down
- whether filtering and search feel clear
- whether document categories are understandable

Follow-up questions:

- "Where did you first expect this to live?"
- "Would you trust yourself to find this again later?"

### Task B7: Understand what Haven changed recently

Prompt to read:

"Show me anything in the app that tells you what Haven changed, recommended, or set up for you recently."

What to watch for:

- whether users can answer this at all
- whether recent activity feels sufficient
- whether users want more explanation

This task is especially important because it tests the current absence of a durable change ledger.

### Task B8: Use Alfred with context

Prompt to read:

"Ask the app for help with a real household decision. Use whatever path feels natural."

What to watch for:

- whether the user knows when to use Alfred
- whether Alfred feels connected to the thing they came from
- whether users expect chat, guidance, or action

Follow-up questions:

- "Did you feel like you were talking to an assistant or using a tool?"
- "What would make this feel more grounded?"

---

## Session Type C: Complex household and trust test list

### Task C1: Understand household structure

Prompt to read:

"Show me where you would go to understand the people in this household and what Haven knows about them."

What to watch for:

- whether family data feels easy to locate
- whether `Life` supports the mental model well
- whether staff and family distinctions feel clear

### Task C2: Find estate-related readiness information

Prompt to read:

"Imagine you were trying to understand whether this household is prepared for an emergency or for estate-related needs. Where would you go?"

What to watch for:

- whether users know where estate readiness lives
- whether the connection between documents, family, and estate work feels coherent

### Task C3: Understand multi-property context

Prompt to read:

"Pretend this household has more than one property. Show me how you would tell which home you are looking at and how you would switch context."

What to watch for:

- whether users notice property context quickly
- whether shortcuts seem risky or vague
- whether they trust the app to be acting on the correct property

### Task C4: Trace a recommendation back to its source

Prompt to read:

"Pick any recommendation or plan change in the app and show me how you would figure out why the app suggested it."

What to watch for:

- whether users can inspect reasoning
- whether they feel comfortable accepting app decisions
- whether they want stronger audit trails

### Task C5: Assess trust in AI

Prompt to read:

"Based on what you have seen so far, which parts of this app would you trust right away and which parts would you double-check?"

What to watch for:

- trust in maintenance recommendations
- trust in document analysis
- trust in Alfred responses
- trust in household or estate guidance

Follow-up questions:

- "What makes something in this app feel trustworthy?"
- "What makes something feel like it should be reviewed before acting on it?"

---

## Cross-cutting stress tests

Run these in later sessions once the basics are clear.

### Stress Test 1: Recover from a wrong turn

Prompt to read:

"Find a vendor for a service category, but take whichever path feels most natural. If you end up in the wrong place, keep going."

What to watch for:

- how easy it is to recover
- whether users know what screen they are on
- whether they understand the relationship between Property, Maintenance, and Dashboard

### Stress Test 2: Interpret a busy dashboard

Prompt to read:

"Imagine you only have two minutes before a meeting. What would you do from this screen?"

What to watch for:

- whether users can prioritize quickly
- whether the dashboard creates noise or clarity

### Stress Test 3: Explain the app back to someone else

Prompt to read:

"If a friend asked what Haven does, how would you explain it now?"

What to watch for:

- the nouns users naturally choose
- whether they mention documents, maintenance, household, estate, or AI
- whether the product story is coherent after actual use

---

## High-value follow-up interview questions

Ask some version of these near the end of each session.

- "What felt most valuable?"
- "What felt most confusing?"
- "What felt like too much?"
- "What felt unusually thoughtful?"
- "Was there any point where the app seemed to take over without enough explanation?"
- "If you wanted to return to the most important thing you saw today, where would you go?"
- "Which tab name would you change, if any?"
- "Did the app feel more like a tool, an assistant, a planner, or a record-keeper?"

---

## Moderator scorecard

Use this simple 1-5 score after each session.

### Product comprehension

- 1: participant never really understood what Haven is
- 3: participant understood pieces, but not the full structure
- 5: participant could clearly explain the product and its main areas

### Navigation clarity

- 1: frequent wrong turns, unclear structure
- 3: some confusion, but recoverable
- 5: participant usually guessed the right place first

### Dashboard clarity

- 1: felt cluttered and hard to prioritize
- 3: mixed
- 5: immediately legible and useful

### Maintenance clarity

- 1: participant did not understand the system
- 3: partially understood
- 5: clearly understood tasks, services, visits, and routing

### AI trust and clarity

- 1: participant did not know when or why to use Alfred
- 3: understood some use cases
- 5: understood the role of Alfred and felt good using it

### Overall product confidence

- 1: would not trust or return to the app
- 3: interested but unsure
- 5: confident and willing to rely on it

---

## Note-taking template

Use this per participant.

### Participant

- Session type:
- Household profile:
- Property count:
- Age range:
- Role in household:

### First impression

- What they thought Haven was:
- What they expected under each tab:
- Immediate confusion points:

### Key moments

- Strongest delight:
- Strongest confusion:
- Biggest hesitation:
- Most trusted feature:
- Least trusted feature:

### Navigation observations

- First wrong turn:
- Labels that did not work:
- Places they expected to find things:

### Product insights

- What they thought the app did best:
- What felt like too much:
- What felt missing:
- Feature they cared about most:

### Verdict

- Would they use it?
- Would they recommend it?
- Main reason:

---

## What to do with the findings

At the end of every 3 to 4 sessions, synthesize findings into four buckets:

- structural confusion
- copy and naming issues
- interaction and navigation issues
- delight and differentiation

Do not just count complaints. Look for repeated patterns:

- multiple users misreading the same tab
- multiple users asking where a thing lives
- multiple users feeling overloaded after the quiz
- multiple users being unable to tell what Haven changed

Those patterns should drive product decisions more than any single opinion.

---

## Recommended order of testing

Run sessions in this order:

1. First-time comprehension sessions
2. Returning-user daily operations sessions
3. Complex-household and trust sessions
4. Follow-up validation sessions after product changes

This order helps the team fix the biggest structural issues before testing more nuanced trust questions.

---

## Final note

The purpose of this plan is not to prove Haven is polished. It is to learn where the product structure is already strong and where users lose the thread.

The biggest win from these sessions will be clarity:

- clearer ownership of features
- clearer navigation
- clearer explanations of what Haven is doing
- clearer understanding of which moments feel truly premium to users

If you run this plan well, it should give you a strong roadmap for tightening the product without flattening what makes Haven special.

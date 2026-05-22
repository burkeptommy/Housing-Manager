// V5 demo fixtures — verbatim port from `data.jsx` in the design handoff.
// Used by every screen when the user's real workspace has no rows yet OR
// when the URL has `?demo=1`. Screenshot diffs against the prototype
// rely on these values being identical.

export const COMPANY_DEMO = {
  name: "Burke Handymen LLC",
  owner: "Tom Burke",
  email: "burkepthomas@gmail.com",
  phone: "508-333-8630",
};

export interface CrewMemberDemo {
  id: string;
  name: string;
  title: string;
  role: "Owner" | "Field tech" | "Desk";
  avatar: string;
  color: string;
  desk?: boolean;
}

export const CREW_DEMO: CrewMemberDemo[] = [
  { id: "TB", name: "Tom Burke",     title: "Owner",            role: "Owner",      avatar: "TB", color: "#6938EF", desk: true },
  { id: "MC", name: "Mara Chen",     title: "Lead technician",  role: "Field tech", avatar: "MC", color: "#6938EF" },
  { id: "DA", name: "Diego Alvarez", title: "Field technician", role: "Field tech", avatar: "DA", color: "#0A0A0A" },
  { id: "LW", name: "Lou Whitman",   title: "Apprentice",       role: "Field tech", avatar: "LW", color: "#6B6B7B" },
  { id: "JP", name: "Jess Park",     title: "Dispatcher",       role: "Desk",       avatar: "JP", color: "#7A55F0", desk: true },
];

export const HOMES_DEMO = [
  { id: "h1", label: "14 Beacon Hill",  owner: "Sarah Whitfield",       city: "Brookline",      systems: 19, openWork: 2, lifetime: 3850, isNew: false },
  { id: "h2", label: "8 Marlborough",   owner: "Aaron Pell",            city: "Boston",         systems: 22, openWork: 0, lifetime: 6210, isNew: false },
  { id: "h3", label: "212 Highland",    owner: "Helen & Theo Rao",      city: "Newton",         systems: 17, openWork: 1, lifetime: 2740, isNew: false },
  { id: "h4", label: "6 Carriage Ln",   owner: "Sasha Linnet",          city: "Wellesley",      systems: 24, openWork: 0, lifetime: 5340, isNew: false },
  { id: "h5", label: "91 Heath St",     owner: "Marcus Doyle",          city: "Chestnut Hill",  systems: 14, openWork: 0, lifetime: 320,  isNew: true },
];

export const VISITS_DEMO = [
  { id: "v1", time: "8:30 AM", duration: 60,  title: "Spring punch-list bundle",   home: "14 Beacon Hill",  tech: "MC", status: "on-the-way" as const, priority: "normal" as const, bundle: true },
  { id: "v2", time: "10:00 AM", duration: 90, title: "Repair leaking sillcock",    home: "212 Highland",    tech: "DA", status: "scheduled" as const, priority: "normal" as const, bundle: false },
  { id: "v3", time: "11:30 AM", duration: 30, title: "Hang gallery wall",          home: "8 Marlborough",   tech: "MC", status: "scheduled" as const, priority: "normal" as const, bundle: false },
  { id: "v4", time: "12:30 PM", duration: 60, title: "Re-caulk powder room",       home: "6 Carriage Ln",   tech: "DA", status: "scheduled" as const, priority: "normal" as const, bundle: false },
  { id: "v5", time: "2:00 PM",  duration: 45, title: "Annual radon test pickup",   home: "91 Heath St",     tech: "LW", status: "scheduled" as const, priority: "high" as const,   bundle: false },
  { id: "v6", time: "3:00 PM",  duration: 30, title: "Replace dryer vent duct",    home: "14 Beacon Hill",  tech: "LW", status: "scheduled" as const, priority: "normal" as const, bundle: false },
  { id: "v7", time: "3:30 PM",  duration: 60, title: "Realign cabinet doors",      home: "212 Highland",    tech: "MC", status: "scheduled" as const, priority: "normal" as const, bundle: false },
];

export const UNASSIGNED_DEMO = [
  { id: "u1", priority: "high" as const,    bundle: false, age: "2h",  title: "Fix toilet running constantly",        home: "Highland",  requestedBy: "Helen Rao",  city: "Newton" },
  { id: "u2", priority: "normal" as const,  bundle: true,  age: "5h",  title: "Spring punch list (5 small jobs)",      home: "Carriage Ln", requestedBy: "Sasha Linnet", city: "Wellesley" },
  { id: "u3", priority: "normal" as const,  bundle: false, age: "1d",  title: "Replace porch light fixture",           home: "Heath St",   requestedBy: "Marcus Doyle", city: "Chestnut Hill" },
  { id: "u4", priority: "normal" as const,  bundle: false, age: "1d",  title: "Caulk master bath shower seam",         home: "Beacon Hill", requestedBy: "Sarah Whitfield", city: "Brookline" },
];

export const REQUESTS_DECISIONS_DEMO = [
  { id: "d1", icon: "lightbulb" as const, title: "Approve quote Q-2026-024 for Sasha Linnet",        sub: "Spring punch-list bundle · $1,842" },
  { id: "d2", icon: "calendar"  as const, title: "Confirm Mara's overtime for Saturday",             sub: "She's offered to wrap the Brookline backlog" },
  { id: "d3", icon: "user"      as const, title: "Mike Doyle wants Friday or Tuesday",               sub: "Replace porch light fixture · 91 Heath St" },
  { id: "d4", icon: "shield"    as const, title: "Renew the workman's-comp policy",                  sub: "Provider sent the renewal yesterday" },
];

export const PIPELINE_DEMO = {
  totalCents: 1421900,
  buckets: [
    { label: "Draft",    count: 1, tone: "neutral"  as const },
    { label: "Sent",     count: 1, tone: "info"     as const },
    { label: "Viewed",   count: 1, tone: "indigo"   as const },
    { label: "Approved", count: 1, tone: "success"  as const },
    { label: "Declined", count: 1, tone: "critical" as const },
  ],
};

export const RECENT_THREADS_DEMO = [
  { id: "t1", from: "Sarah Whitfield", home: "14 Beacon Hill",  preview: "Mara was great — small touch-up on the upstairs trim?", timestamp: "23m", unread: 2 },
  { id: "t2", from: "Aaron Pell",      home: "8 Marlborough",   preview: "Confirmed — see you Tuesday morning.",                 timestamp: "1h",  unread: 0 },
  { id: "t3", from: "Helen Rao",       home: "212 Highland",    preview: "Quick question: would you do gutter cleanouts too?",   timestamp: "3h",  unread: 1 },
];

export const KPIS_DEMO = [
  { label: "Requested",    value: 14,           sub: "Open requests" },
  { label: "Unassigned",   value: 4,            sub: "Awaiting dispatch" },
  { label: "Today",        value: 7,            sub: "Stops on the board" },
  { label: "Crew today",   value: 4,            sub: "Scheduled techs" },
  { label: "Pipeline",     value: "$14.2K",     sub: "Across 5 quotes", accent: true },
  { label: "This week",    value: 31,           sub: "Visits booked" },
];

export const QUOTES_DEMO = [
  { id: "q1", number: "Q-2026-021", customer: "Aaron Pell",        property: "8 Marlborough",  status: "draft"    as const, items: 4, totalCents: 92500,  updated: "Yesterday" },
  { id: "q2", number: "Q-2026-022", customer: "Sarah Whitfield",   property: "14 Beacon Hill", status: "sent"     as const, items: 6, totalCents: 184200, updated: "2 days ago" },
  { id: "q3", number: "Q-2026-023", customer: "Helen Rao",         property: "212 Highland",   status: "viewed"   as const, items: 5, totalCents: 246800, updated: "Today" },
  { id: "q4", number: "Q-2026-024", customer: "Sasha Linnet",      property: "6 Carriage Ln",  status: "approved" as const, items: 7, totalCents: 198400, updated: "Just now" },
  { id: "q5", number: "Q-2026-020", customer: "Marcus Doyle",      property: "91 Heath St",    status: "declined" as const, items: 3, totalCents: 64200,  updated: "3 days ago" },
];

export const SAVED_LINE_ITEMS_DEMO = [
  { id: "s1", name: "Standard caulk replacement",          unit: "lf",   priceCents: 950 },
  { id: "s2", name: "Hang artwork or shelving",            unit: "ea",   priceCents: 4500 },
  { id: "s3", name: "Replace door hinges + adjust",        unit: "ea",   priceCents: 8500 },
  { id: "s4", name: "Hour of general handyman labor",      unit: "hr",   priceCents: 12500 },
  { id: "s5", name: "Annual radon test (pickup + lab)",    unit: "ea",   priceCents: 18000 },
  { id: "s6", name: "Smoke + CO detector swap",            unit: "ea",   priceCents: 7500 },
];

export const QUOTE_BUILDER_DEMO = {
  number: "Q-2026-024",
  customer: "Sasha Linnet",
  property: "6 Carriage Ln · Wellesley",
  status: "draft" as const,
  lines: [
    { id: "l1", name: "General handyman labor",      desc: "Spring punch list bundle",    unit: "hr", qty: 6, priceCents: 12500 },
    { id: "l2", name: "Caulk master bath shower",    desc: "Includes silicone removal",   unit: "lf", qty: 18, priceCents: 950 },
    { id: "l3", name: "Hang gallery wall (3 frames)",desc: "French cleat",                unit: "ea", qty: 1, priceCents: 8500 },
    { id: "l4", name: "Replace porch light fixture", desc: "Customer-supplied fixture",   unit: "ea", qty: 1, priceCents: 14500 },
    { id: "l5", name: "Re-align cabinet doors",      desc: "Kitchen + powder room",       unit: "ea", qty: 6, priceCents: 4500 },
    { id: "l6", name: "Replace dryer vent duct",     desc: "Rigid + clean external",      unit: "ea", qty: 1, priceCents: 18500 },
  ],
  taxBp: 625,
  materialsMarkupBp: 1000,
};

export const MESSAGE_THREAD_DEMO = {
  inbox: [
    { id: "i1", from: "Sarah Whitfield", home: "14 Beacon Hill",  timestamp: "23m", preview: "Mara was great — small touch-up on the upstairs trim?", unread: 2, selected: true },
    { id: "i2", from: "Aaron Pell",      home: "8 Marlborough",   timestamp: "1h",  preview: "Confirmed — see you Tuesday morning.",                 unread: 0 },
    { id: "i3", from: "Helen Rao",       home: "212 Highland",    timestamp: "3h",  preview: "Quick question: would you do gutter cleanouts too?",    unread: 1 },
    { id: "i4", from: "Sasha Linnet",    home: "6 Carriage Ln",   timestamp: "1d",  preview: "Approved — let's get on the books.",                    unread: 0 },
    { id: "i5", from: "Marcus Doyle",    home: "91 Heath St",     timestamp: "2d",  preview: "Maybe Friday after 2?",                                 unread: 0 },
  ],
  thread: [
    { id: "m1", who: "them" as const, body: "Mara was great today, thanks for sending her. Quick question — could she also do a small touch-up on the upstairs trim next time?", timestamp: "10:14 AM" },
    { id: "m2", who: "system" as const, body: "Quote Spring punch-list bundle · $1,842 · approved by Sasha", timestamp: "10:31 AM" },
    { id: "m3", who: "them" as const, body: "And one more thing — the smoke detector by the laundry chirped this morning. Battery probably?", timestamp: "10:33 AM" },
    { id: "m4", who: "us"   as const, body: "Glad to hear Mara crushed it. Yes, easy add — I'll route the trim touch-up + the detector swap into next Tuesday's visit. Want me to add a quote line so it's all on one approval?", timestamp: "10:38 AM" },
  ],
  alfredSuggestion: "Sasha tends to consolidate small jobs — bundle the trim touch-up + the detector swap into one Tuesday visit and keep her at her lifetime $5,340 spend trajectory.",
};

export const ROUTES_DEMO = [
  {
    techId: "MC",
    name: "Mara Chen",
    summary: "4 stops · 5h 0m · 18 mi drive",
    stops: [
      { idx: 1, title: "Spring punch-list bundle",  home: "14 Beacon Hill",  city: "Brookline",     window: "8:30 – 9:30",   drive: "+12 min" },
      { idx: 2, title: "Hang gallery wall",         home: "8 Marlborough",   city: "Boston",        window: "11:30 – 12:00", drive: "+8 min" },
      { idx: 3, title: "Realign cabinet doors",     home: "212 Highland",    city: "Newton",        window: "1:00 – 2:00",   drive: "+15 min" },
      { idx: 4, title: "Smoke detector swap",       home: "14 Beacon Hill",  city: "Brookline",     window: "3:30 – 4:00",   drive: "+10 min" },
    ],
  },
  {
    techId: "DA",
    name: "Diego Alvarez",
    summary: "3 stops · 4h 30m · 14 mi drive",
    stops: [
      { idx: 1, title: "Repair leaking sillcock",   home: "212 Highland",    city: "Newton",        window: "10:00 – 11:30", drive: "+9 min" },
      { idx: 2, title: "Re-caulk powder room",      home: "6 Carriage Ln",   city: "Wellesley",     window: "12:30 – 1:30",  drive: "+18 min" },
      { idx: 3, title: "Pickup parts",              home: "Home Depot",      city: "Newton",        window: "2:00 – 2:30",   drive: "+6 min" },
    ],
  },
  {
    techId: "LW",
    name: "Lou Whitman",
    summary: "2 stops · 1h 15m · 9 mi drive",
    stops: [
      { idx: 1, title: "Annual radon test pickup",  home: "91 Heath St",     city: "Chestnut Hill", window: "2:00 – 2:45",   drive: "+22 min" },
      { idx: 2, title: "Replace dryer vent duct",   home: "14 Beacon Hill",  city: "Brookline",     window: "3:00 – 3:30",   drive: "+11 min" },
    ],
  },
];

export function isDemoMode(): boolean {
  if (typeof window === "undefined") return false;
  return new URLSearchParams(window.location.search).get("demo") === "1";
}

export function formatCurrencyCents(cents: number): string {
  const dollars = cents / 100;
  return `$${dollars.toLocaleString(undefined, { minimumFractionDigits: dollars % 1 === 0 ? 0 : 2 })}`;
}

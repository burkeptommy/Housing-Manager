// Dashboard payload shape returned by the `handyman-provider` Edge Function.
// Mirrors `loadDashboard()` in supabase/functions/handyman-provider/index.ts.
// All field names are camelCase (the function already normalizes from snake).

export type WorkspaceMode = "sole" | "crew";
export type ProviderRole = "owner" | "admin" | "dispatcher" | "technician";
export type RequestStatus =
  | "draft"
  | "submitted"
  | "scheduled"
  | "sent_to_handyman"
  | "alternate_dates_proposed"
  | "awaiting_homeowner"
  | "confirmed"
  | "on_my_way"
  | "checked_in"
  | "quoted"
  | "in_progress"
  | "completed"
  | "follow_up_recommended"
  | "cancelled"
  | "declined";
export type QuoteStatus =
  | "draft"
  | "sent"
  | "viewed"
  | "approved"
  | "declined"
  | "withdrawn"
  | "countered_by_homeowner"
  | "superseded";

export interface CurrentUser {
  id: string;
  memberId: string;
  email: string;
  fullName: string;
  role: ProviderRole;
  roleLabel: string;
}

export interface Permissions {
  canManageCrew: boolean;
  canViewQuotes: boolean;
  canEditQuotes: boolean;
  canViewMessages: boolean;
  canSendMessages: boolean;
  /**
   * Wave P: source of truth is the Edge Function's rolePermissions().
   * `canManageWorkspace` is the canonical name; `canBootstrapWorkspace`
   * is kept as a backward-compat alias because earlier specs and any
   * legacy SPA call sites may still reference it.
   */
  canManageWorkspace: boolean;
  canBootstrapWorkspace?: boolean;
  isFieldTechnician: boolean;
}

export interface Workspace {
  id: string;
  companyName: string;
  primaryEmail: string;
  primaryPhone: string;
  website: string;
  contractorCount: number;
  activeMemberCount: number;
  invitedMemberCount: number;
  providerUrl: string;
  // Branding / directory fields. All optional because pre-Wave-P workspaces
  // landed without them populated. The Settings screen lets the owner fill
  // them in, and the find-network handymen flow surfaces them downstream.
  licenseNumber?: string;
  serviceState?: string;
  serviceCity?: string;
  serviceZipCodes?: string[];
  categories?: string[];
  displayBlurb?: string;
  headshotUrl?: string;
  isListedInDirectory?: boolean;
}

export interface LinkedContractor {
  contractorId: string;
  companyName: string;
  contactName: string;
  email: string;
  phone: string;
  category: string;
}

export interface DashboardStats {
  requestedVisits: number;
  upcomingVisits: number;
  unassignedVisits: number;
  todayStops: number;
  homesServiced: number;
  activeMembers: number;
  draftQuotes: number;
  quotesSent: number;
  completedVisits: number;
  openThreads: number;
  myAssignedVisits: number;
}

export interface VisitProperty {
  id: string;
  name: string;
  address: string;
}

export interface VisitTaskRef {
  id: string;
  title: string;
  scheduledDate: string;
  dueDate: string;
  notes?: string;
  description?: string;
}

export interface FieldWorkspace {
  portalToken: string;
  url: string;
  reportStatus: string;
  completedAt: string | null;
}

export interface VisitAssignment {
  id: string;
  memberId: string;
  memberName: string;
  memberRole: string;
  memberRoleLabel: string;
  routeDate: string;
  windowStartTime: string;
  windowEndTime: string;
  stopOrder: number;
  routeNotes: string;
  /// Wave M1 — visit lifecycle. ISO timestamps for clock-in/clock-out,
  /// pause accumulation in seconds, and GPS coords stamped at clock-in.
  /// Defaults to nulls for legacy rows that pre-date the lifecycle phase.
  clockInAt?: string | null;
  clockOutAt?: string | null;
  pausedSeconds?: number;
  clockInLat?: number | null;
  clockInLng?: number | null;
  clockInAccuracyM?: number | null;
}

export interface VisitMessagePreview {
  senderRole: string;
  body: string;
  createdAt: string;
}

export interface VisitQuotePreview {
  id: string;
  status: QuoteStatus;
  statusLabel: string;
  total: number;
  lineItems: QuoteLineItem[];
  scopeNotes: string | null;
  homeownerMessage: string | null;
  parentQuoteId: string | null;
  signedAt: string | null;
  signedName: string | null;
  /// Wave M4 — kitchen-table signature artifact. signaturePath is the
  /// raw storage path; the dashboard read path + sign_quote response
  /// also fold in a signed URL via the same pattern as punch-item
  /// attachments. signerRole distinguishes a witness signature from
  /// the principal homeowner signature.
  signaturePath: string | null;
  signerRole: string | null;
  homeownerRevisedAt: string | null;
  updatedAt: string;
  publicShareUrl: string;
}

/// Wave M2 — one entry on `handyman_punch_items.attachments` JSONB array.
/// Camel-case shape mirroring the iOS `HavenFieldPunchAttachment` model.
/// `signedUrl` is filled in by the dashboard read path + by the
/// `attach_punch_photo` response so consumers can render thumbnails
/// without a per-asset round-trip.
export interface PunchItemAttachment {
  kind: string;
  path: string;
  contentType?: string | null;
  caption?: string | null;
  uploadedAt?: string | null;
  uploadedBy?: string | null;
  signedUrl?: string | null;
}

/// Wave M2 — one entry on `handyman_punch_items.materials_used` JSONB array.
/// snake_case `unit_cost` mirrors the column convention. Per-item
/// invoice convertor reads `qty * unit_cost` directly into a draft line.
export interface PunchItemMaterial {
  sku?: string | null;
  name: string;
  qty: number;
  unit_cost: number;
}

/// Wave O — structured punch item row from `handyman_punch_items`.
/// The handyman-provider edge function returns these per visit via
/// the assigned_visit_task_id FK. Replaces the legacy free-text
/// parsePunchList(visit.notes) shim. Shape mirrors mapPunchItemForClient
/// in supabase/functions/handyman-provider/index.ts.
export interface PunchItem {
  id: string;
  householdId: string;
  propertyId: string | null;
  assignedVisitTaskId: string | null;
  systemId: string | null;
  systemLabelSnapshot: string | null;
  templateId: string | null;
  title: string;
  description: string | null;
  /// "manual" / "template" / "recommended" / "auto_seed_handyman_tier" /
  /// "promoted_from_task" / "migrated_from_task" — drives the source pill.
  source: string;
  /// "pending" / "assigned" / "in_progress" / "done" / "cancelled".
  status: string;
  priority: string;
  estimatedMinutes: number | null;
  estimatedCostRange: string | null;
  materialRequired: boolean;
  costBasis: string;
  attachments: PunchItemAttachment[];
  /// Wave M2 — capture-depth fields. Field tech writes via attach_punch_*
  /// and set_punch_* actions; the contractor desk's VisitDetail review
  /// section renders the same shape so post-visit invoicing rolls
  /// per-item materials cost + per-item time straight into draft lines.
  materialsUsed: PunchItemMaterial[];
  timeSpentSeconds: number;
  voiceNotePath: string | null;
  voiceNoteSignedUrl?: string | null;
  addedAfterLock: boolean;
  proposedByRole: string | null;
  proposedAt: string | null;
  proposalMessage: string | null;
  proposalStatus: string;
  proposalExpiresAt: string | null;
  acceptedAt: string | null;
  declinedAt: string | null;
  declinedReason: string | null;
  completedAt: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface VisitRow {
  requestId: string;
  householdId: string;
  propertyId: string;
  contractorId: string;
  title: string;
  requestType: string;
  status: RequestStatus;
  statusLabel: string;
  preferredTiming: string;
  proposedVisitAt: string | null;
  proposedByRole: string | null;
  proposedAt: string | null;
  confirmedVisitAt: string | null;
  updatedAt: string;
  routeDate: string;
  property: VisitProperty | null;
  visit: VisitTaskRef | null;
  fieldWorkspace: FieldWorkspace | null;
  assignment: VisitAssignment | null;
  latestMessage: VisitMessagePreview | null;
  quote: VisitQuotePreview | null;
  /// Wave O — structured punch list. Items already filtered to
  /// archived_at IS NULL on the server. Empty array when the visit has
  /// no attached punch items; the SPA falls back to parsePunchList(notes)
  /// for legacy data while migration completes.
  punchItems?: PunchItem[];
  /// Phase 84.5 — discriminator on the underlying provider_visit_assignments
  /// row. "standard_visit" / "home_assessment" / "inspection" / "follow_up".
  /// Defaults to "standard_visit" when the column is missing on older rows.
  visitType?: "standard_visit" | "home_assessment" | "inspection" | "follow_up";
  /// Phase 84.5 — link back to the home_assessments row for this visit
  /// when visitType === "home_assessment". The field app uses this to
  /// load the captured_* JSONB and render the GuidedAssessmentView.
  homeAssessmentId?: string | null;
  /// Section 19a — origin discriminator. "homeowner" when the homeowner
  /// submitted the request from the iOS app, "haven" when the Chez admin
  /// routed it on their behalf. Drives the "Routed by Chez" pill so the
  /// contractor knows the reply path goes through Chez, not the homeowner.
  source?: string | null;
  /// Section 19a — urgency surfaced from the underlying handyman_requests
  /// row so emergency-routing requests render with a critical pill instead
  /// of a routine indigo one.
  urgency?: string | null;
}

export interface HomeSystemPhoto {
  path: string;
  contentType: string;
  uploadedAt: string;
  uploadedBy: string;
  caption: string;
  signedUrl: string | null;
}

export interface HomeSystem {
  id: string;
  name: string;
  category: string;
  manufacturer: string;
  modelNumber: string;
  serialNumber?: string;
  notes?: string;
  installDate?: string;
  photos?: HomeSystemPhoto[];
  // Wave M3 — system inventory authoring fields written by the field iOS
  // app. The contractor SPA renders REMOVED / FOLLOW-UP badges + voice
  // memo playback when these are present so operator + tech share one
  // view of every home record.
  decommissionedAt?: string | null;
  decommissionReason?: string | null;
  markedForFollowupAt?: string | null;
  followupReason?: string | null;
  voiceNotePath?: string | null;
  voiceNoteSignedUrl?: string | null;
}

/// Section 19d.21 — subset of households.chez_profile that the
/// contractor SPA needs. Spending tiers drive a "ping Chez before
/// quoting above $X" banner; vendor prefs / logistics drive
/// pre-visit context cards. Phase 80.1 added the underlying JSONB.
export interface ChezProfileSummary {
  spendingTiers?: {
    auto_approve_under?: number | null;
    ping_under?: number | null;
    explicit_above?: number | null;
  } | null;
  vendorPreferences?: Record<string, unknown> | null;
  logistics?: Record<string, unknown> | null;
}

export interface HomeRow {
  propertyId: string;
  householdId: string;
  name: string;
  address: string;
  systemCount: number;
  openRequests: number;
  lastCompletedVisit: string | null;
  assignedMembers: string[];
  systems?: HomeSystem[];
  /// Subset of households.chez_profile relevant to the contractor.
  /// null when the household hasn't set up Chez profile yet.
  chezProfile?: ChezProfileSummary | null;
}

export interface MessageThread {
  requestId: string;
  propertyId: string;
  title: string;
  requestType: string;
  preferredTiming: string;
  status: RequestStatus;
  statusLabel: string;
  propertyName: string;
  propertyAddress: string;
  latestMessage: string;
  latestMessageAt: string;
  senderRole: string;
  assignedMemberName: string;
  fieldWorkspaceUrl: string;
  recentMessages: ThreadMessage[];
  quote: VisitQuotePreview | null;
}

export interface ThreadMessage {
  id: string;
  body: string;
  senderRole: string;
  createdAt: string;
  metadata?: Record<string, unknown>;
}

export interface TeamMember {
  id: string;
  userId: string;
  fullName: string;
  email: string;
  phone: string;
  title: string;
  role: ProviderRole;
  roleLabel: string;
  status: "invited" | "active" | "disabled";
  inviteUrl: string | null;
  lastSeenAt: string | null;
  todayStops: number;
  openVisits: number;
  completedCount: number;
  mobileFocus: boolean;
  isDefaultAssignee: boolean;
}

export interface QuoteLineItem {
  id?: string;
  name: string;
  description?: string;
  unit?: string;
  quantity?: number;
  unitPrice?: number;
  total?: number;
}

export interface QuoteComment {
  id: string;
  quoteId: string;
  lineItemId: string | null;
  parentCommentId: string | null;
  authorRole: "homeowner" | "provider" | string;
  body: string;
  status: "open" | "answered" | string;
  createdAt: string;
}

export interface Quote {
  id: string;
  workspaceId: string;
  contractorId: string;
  householdId: string;
  propertyId: string;
  visitTaskId: string;
  title: string;
  status: QuoteStatus;
  statusLabel: string;
  propertyName: string;
  recipientKind: "linked_home" | "prospect" | string;
  recipientName: string;
  recipientEmail: string;
  recipientPhone: string;
  recipientAddress: string;
  audienceLabel: string;
  total: number;
  itemCount: number;
  updatedAt: string;
  sentAt: string | null;
  lastSentAt: string | null;
  viewedAt: string | null;
  approvedAt: string | null;
  declinedAt: string | null;
  requestId: string;
  publicShareUrl: string;
  lineItems: QuoteLineItem[];
  homeownerMessage: string;
  scopeNotes: string;
  latestMessage: { senderRole: string; senderName: string; body: string; createdAt: string } | null;
  recentMessages: { id: string; senderRole: string; senderName: string; body: string; createdAt: string; deliveryChannel: string }[];
  /**
   * Wave V.1 — quote bundles (good/better/best).
   *
   * - parentQuoteId: when set, this quote is a CHILD of a bundle. The
   *   parent's row is the wrapper.
   * - bundleMeta: when present (only on the parent row), this is a
   *   BUNDLE PARENT. Carries the tier list and the chosen-child
   *   breadcrumb if a tier has been picked.
   * - bundleTierLabel: the per-child label ("Good" / "Better" / "Best"
   *   or whatever the contractor typed). Only set on children.
   *
   * Implementation note: the schema reuses parent_quote_id from Phase
   * 73b without a new column. The BUNDLE_MARKER sentinel in
   * scope_notes is what distinguishes a bundle parent from a
   * counter-offer chain.
   */
  parentQuoteId: string | null;
  bundleMeta: {
    bundle: true;
    tiers: string[];
    chosenChildId?: string | null;
    chosenTierLabel?: string | null;
  } | null;
  bundleTierLabel: string | null;
  /**
   * Wave Z.3 — Phase 73b negotiation metadata. signedAt / signedName
   * stamped on homeowner approval; homeownerRevisedAt stamped when the
   * homeowner counters with edited line items.
   *
   * Wave M4 — kitchen-table signature artifact. signaturePath is the
   * raw storage path on the private quote-signatures bucket; the
   * dashboard read path doesn't currently sign URLs at the provider
   * /quotes list level (that lives only on the visit-detail payload),
   * so consumers wanting to render the inline PNG should pull from the
   * VisitQuotePreview shape on a visit detail. signerRole
   * distinguishes a witness signature from the principal homeowner.
   */
  signedAt: string | null;
  signedName: string | null;
  signaturePath: string | null;
  signerRole: string | null;
  homeownerRevisedAt: string | null;
}

export interface SavedQuoteItem {
  id: string;
  name: string;
  description: string;
  unit: string;
  defaultQuantity: number;
  defaultUnitPrice: number;
  sortOrder: number;
}

// Wave Q (Section 8) — Provider invoices.
export type InvoiceStatus =
  | "draft"
  | "sent"
  | "viewed"
  | "paid"
  | "partial"
  | "overdue"
  | "void";

export interface Invoice {
  id: string;
  workspaceId: string;
  contractorId: string | null;
  householdId: string | null;
  propertyId: string | null;
  requestId: string | null;
  sourceQuoteId: string | null;
  invoiceNumber: string;
  title: string;
  status: InvoiceStatus;
  statusLabel: string;
  currency: string;
  lineItems: QuoteLineItem[];
  scopeNotes: string | null;
  homeownerMessage: string | null;
  subtotal: number;
  taxTotal: number;
  total: number;
  amountPaid: number;
  propertyName: string;
  dueDate: string | null;
  sentAt: string | null;
  paidAt: string | null;
  createdAt: string;
  updatedAt: string;
}

/**
 * Wave S — workspace summary surfaced in the sidebar switcher dropdown.
 * One row per active membership the signed-in user holds. Keep this
 * narrow (id + display fields + role) so the dashboard payload stays
 * lean — the full Workspace shape is only loaded when that workspace
 * becomes current.
 */
export interface AvailableWorkspace {
  id: string;
  companyName: string;
  primaryEmail: string;
  role: ProviderRole | string;
  isCurrent: boolean;
}

/**
 * Wave Z.2 — Cross-customer aggregate task row. Returned by the
 * `fetch_aggregate_tasks` action. Combines two underlying tables:
 *
 *  - `handyman_punch_items` (source: "punch_item") — work picked up
 *    inline at visits, on the workspace's customers' homes.
 *  - `maintenance_tasks` (source: "maintenance_task") — assigned visit
 *    tasks the contractor is going to do.
 *
 * id is prefixed `pi:` / `mt:` so React keys stay unique across the
 * two source tables; rawId is the underlying row id used for status
 * mutations.
 */
export interface AggregateTask {
  id: string;
  source: "punch_item" | "maintenance_task";
  title: string;
  customerName: string;
  customerPropertyId: string;
  estimatedMinutes: number | null;
  dueDate: string | null;
  status: "pending" | "in_progress" | "done" | "cancelled";
  visitTaskId: string | null;
  sourceKindLabel: string;
  assignedTechName: string | null;
  rawId: string;
}

export interface Dashboard {
  needsWorkspace: boolean;
  currentUser: CurrentUser;
  permissions: Permissions;
  workspace: Workspace;
  linkedContractors: LinkedContractor[];
  stats: DashboardStats;
  visits: VisitRow[];
  homes: HomeRow[];
  messages: MessageThread[];
  recentWork: VisitRow[];
  teamMembers: TeamMember[];
  quotes: Quote[];
  savedQuoteItems: SavedQuoteItem[];
  invoices: Invoice[];
  /**
   * Wave S — every workspace this user can switch into. Length=1 means
   * single-workspace user (hide the dropdown affordance). Always present
   * post-Wave-S, but typed optional so older edge function deploys don't
   * break the SPA decode.
   */
  availableWorkspaces?: AvailableWorkspace[];
}

// ─── Wave M11 — End-of-day summary ───
//
// Mirrors the response shape of the `today_summary` action on
// handyman-provider. Operations Desk Crew screen renders a compact
// "Today's progress" strip from this so the dispatcher can see the
// same totals the field tech sees on iOS.

export interface TodaySummaryStop {
  requestId: string;
  customerName: string;
  address: string;
  title: string;
  clockInAt: string | null;
  clockOutAt: string | null;
  totalMinutes: number;
  invoiceId: string | null;
}

export interface TodaySummaryToday {
  date: string;
  stopsCompleted: number;
  stopsRemaining: number;
  totalClockMinutes: number;
  materialsCostCents: number;
  revenueInvoicedCents: number;
  stops: TodaySummaryStop[];
}

export interface TodaySummaryTomorrow {
  date: string;
  stopsCount: number;
  firstAt: string | null;
  firstCustomer: string | null;
  /** Reserved for a future weather API integration; null today. */
  weather: string | null;
}

export interface TodaySummary {
  today: TodaySummaryToday;
  tomorrow: TodaySummaryTomorrow;
}

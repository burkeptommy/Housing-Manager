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
  canBootstrapWorkspace: boolean;
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
  homeownerRevisedAt: string | null;
  updatedAt: string;
  publicShareUrl: string;
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
  /// Phase 84.5 — discriminator on the underlying provider_visit_assignments
  /// row. "standard_visit" / "home_assessment" / "inspection" / "follow_up".
  /// Defaults to "standard_visit" when the column is missing on older rows.
  visitType?: "standard_visit" | "home_assessment" | "inspection" | "follow_up";
  /// Phase 84.5 — link back to the home_assessments row for this visit
  /// when visitType === "home_assessment". The field app uses this to
  /// load the captured_* JSONB and render the GuidedAssessmentView.
  homeAssessmentId?: string | null;
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
}

// Mirror of the Supabase row shapes the Operations Desk consumes. Phase 71
// + 72 migrations defined every column; the columns we actually surface
// are typed here so TypeScript catches typos and missing fields.

export type WorkspaceMode = "sole" | "crew";

export interface ProviderWorkspace {
  id: string;
  company_name: string;
  primary_email: string | null;
  phone: string | null;
  website: string | null;
  license_number: string | null;
  created_at: string;
}

export interface ProviderWorkspaceMember {
  id: string;
  workspace_id: string;
  user_id: string | null;
  email: string | null;
  full_name: string | null;
  role: "owner" | "admin" | "dispatcher" | "technician";
  phone: string | null;
  title: string | null;
  invite_token: string | null;
  is_active: boolean;
  created_at: string;
}

export type RequestStatus =
  | "new"
  | "in_review"
  | "scheduled"
  | "in_progress"
  | "completed"
  | "cancelled";

export interface HandymanRequest {
  id: string;
  household_id: string;
  contractor_id: string | null;
  request_type: string;
  status: RequestStatus;
  urgency: "routine" | "soon" | "urgent" | "emergency" | null;
  title: string;
  description: string | null;
  household_label: string | null;
  household_city: string | null;
  household_owner_name: string | null;
  created_at: string;
  updated_at: string;
}

export interface ProviderVisitAssignment {
  id: string;
  workspace_id: string;
  request_id: string;
  assigned_member_id: string | null;
  route_date: string;            // YYYY-MM-DD
  window_start_time: string | null;   // HH:MM
  window_end_time: string | null;
  stop_order: number | null;
  duration_minutes: number | null;
  notes: string | null;
  status: "draft" | "notified" | "confirmed" | "in_progress" | "completed" | "cancelled";
  created_at: string;
}

export interface ProviderQuote {
  id: string;
  workspace_id: string;
  request_id: string | null;
  household_id: string | null;
  quote_number: string;
  customer_name: string | null;
  property_label: string | null;
  status: "draft" | "sent" | "viewed" | "approved" | "declined";
  subtotal_cents: number;
  tax_rate_basis_points: number;
  materials_markup_basis_points: number;
  total_cents: number;
  line_items: ProviderQuoteLineItem[];
  notes: string | null;
  created_at: string;
  updated_at: string;
}

export interface ProviderQuoteLineItem {
  id: string;
  name: string;
  description: string | null;
  unit: string;
  quantity: number;
  unit_price_cents: number;
}

export interface ProviderSavedQuoteItem {
  id: string;
  workspace_id: string;
  name: string;
  description: string | null;
  unit: string;
  default_quantity: number;
  default_unit_price_cents: number;
}

export interface HandymanRequestMessage {
  id: string;
  request_id: string;
  sender_role: "homeowner" | "haven" | "vendor" | "system";
  sender_name: string | null;
  body: string;
  body_card: Record<string, unknown> | null;
  created_at: string;
}

// Aggregated views used by the Overview screen
export interface DashboardSummary {
  requested_count: number;
  unassigned_count: number;
  today_count: number;
  crew_today_count: number;
  pipeline_total_cents: number;
  this_week_count: number;
}

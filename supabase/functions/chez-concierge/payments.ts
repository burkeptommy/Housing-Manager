// Wave 5 — Stripe card-on-file. The customer adds a card once; Chez
// charges per job within the household's spending tiers. This module is
// self-contained and INERT until STRIPE_SECRET_KEY is set as an
// edge-function secret: every action returns a clean "payments not
// configured" error rather than throwing, so the iOS/portal payment
// surfaces stay capability-gated (hidden) until go-live.
//
// Stripe is called over its REST API with form-encoded bodies (no SDK),
// matching the house pattern of raw fetch to third parties.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

type ServiceClient = ReturnType<typeof createClient>;

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
      "Access-Control-Allow-Methods": "POST, OPTIONS",
      "Content-Type": "application/json",
    },
  });
}

function stripeKey(): string | null {
  const k = Deno.env.get("STRIPE_SECRET_KEY");
  return k && k.trim() ? k.trim() : null;
}

function publishableKey(): string | null {
  const k = Deno.env.get("STRIPE_PUBLISHABLE_KEY");
  return k && k.trim() ? k.trim() : null;
}

export function paymentsConfigured(): boolean {
  return stripeKey() !== null;
}

// Form-encode a flat/nested params object the way Stripe's API expects
// (foo[bar]=baz). One level of nesting covers everything we send.
function formEncode(params: Record<string, unknown>): string {
  const parts: string[] = [];
  for (const [k, v] of Object.entries(params)) {
    if (v === undefined || v === null) continue;
    if (typeof v === "object") {
      for (const [k2, v2] of Object.entries(v as Record<string, unknown>)) {
        if (v2 === undefined || v2 === null) continue;
        parts.push(`${encodeURIComponent(k)}[${encodeURIComponent(k2)}]=${encodeURIComponent(String(v2))}`);
      }
    } else {
      parts.push(`${encodeURIComponent(k)}=${encodeURIComponent(String(v))}`);
    }
  }
  return parts.join("&");
}

async function stripeCall(
  path: string,
  method: "GET" | "POST",
  params?: Record<string, unknown>
): Promise<{ ok: boolean; status: number; data: Record<string, unknown> }> {
  const key = stripeKey();
  if (!key) return { ok: false, status: 503, data: { error: { message: "payments not configured" } } };
  const url = `https://api.stripe.com/v1/${path}`;
  const init: RequestInit = {
    method,
    headers: {
      "Authorization": `Bearer ${key}`,
      "Content-Type": "application/x-www-form-urlencoded",
    },
  };
  if (method === "POST" && params) init.body = formEncode(params);
  const resp = await fetch(url, init);
  const data = await resp.json().catch(() => ({}));
  return { ok: resp.ok, status: resp.status, data: data as Record<string, unknown> };
}

// ---------------------------------------------------------------------------
// Customer resolution
// ---------------------------------------------------------------------------

async function ensureStripeCustomer(
  service: ServiceClient,
  householdId: string
): Promise<string | null> {
  const { data: hh } = await service
    .from("households")
    .select("id, name, stripe_customer_id")
    .eq("id", householdId)
    .maybeSingle();
  const existing = (hh as { stripe_customer_id?: string } | null)?.stripe_customer_id;
  if (existing) return existing;

  const created = await stripeCall("customers", "POST", {
    name: (hh as { name?: string } | null)?.name ?? "Chez household",
    metadata: { household_id: householdId },
  });
  if (!created.ok) return null;
  const customerId = String((created.data as { id?: string }).id ?? "");
  if (!customerId) return null;
  await service.from("households").update({ stripe_customer_id: customerId }).eq("id", householdId);
  return customerId;
}

// ---------------------------------------------------------------------------
// Homeowner actions
// ---------------------------------------------------------------------------

/// Start adding a card: create/reuse the Customer + a SetupIntent + an
/// ephemeral key so iOS PaymentSheet can render in setup mode.
export async function handleCreateSetupIntent(
  service: ServiceClient,
  householdId: string
) {
  if (!paymentsConfigured()) return json({ error: "payments not configured" }, 503);
  const customerId = await ensureStripeCustomer(service, householdId);
  if (!customerId) return json({ error: "could not create Stripe customer" }, 502);

  const [intent, ephemeral] = await Promise.all([
    stripeCall("setup_intents", "POST", {
      customer: customerId,
      // deno-lint-ignore no-explicit-any
      "payment_method_types[0]": "card" as any,
      usage: "off_session",
    }),
    stripeCall("ephemeral_keys", "POST", { customer: customerId }),
  ]);
  if (!intent.ok) return json({ error: "setup intent failed" }, 502);

  return json({
    setup_intent_client_secret: (intent.data as { client_secret?: string }).client_secret ?? null,
    ephemeral_key_secret: (ephemeral.data as { secret?: string }).secret ?? null,
    customer_id: customerId,
    publishable_key: publishableKey(),
  });
}

/// After PaymentSheet succeeds: retrieve the SetupIntent, read its
/// payment method, and record the card. Marks it default + de-defaults
/// the others.
export async function handleConfirmPaymentMethod(
  service: ServiceClient,
  householdId: string,
  setupIntentId: string
) {
  if (!paymentsConfigured()) return json({ error: "payments not configured" }, 503);
  const si = await stripeCall(`setup_intents/${encodeURIComponent(setupIntentId)}`, "GET");
  if (!si.ok) return json({ error: "setup intent not found" }, 404);
  const pmId = String((si.data as { payment_method?: string }).payment_method ?? "");
  if (!pmId) return json({ error: "no payment method on setup intent" }, 400);

  const pm = await stripeCall(`payment_methods/${encodeURIComponent(pmId)}`, "GET");
  const card = ((pm.data as { card?: Record<string, unknown> }).card ?? {}) as Record<string, unknown>;

  // New card becomes default; existing ones step down.
  await service.from("chez_payment_methods")
    .update({ is_default: false })
    .eq("household_id", householdId)
    .is("detached_at", null);

  await service.from("chez_payment_methods").upsert({
    household_id: householdId,
    stripe_payment_method_id: pmId,
    brand: card.brand ? String(card.brand) : null,
    last4: card.last4 ? String(card.last4) : null,
    exp_month: typeof card.exp_month === "number" ? card.exp_month : null,
    exp_year: typeof card.exp_year === "number" ? card.exp_year : null,
    is_default: true,
    detached_at: null,
  }, { onConflict: "stripe_payment_method_id" });

  return json({
    ok: true,
    card: { brand: card.brand ?? null, last4: card.last4 ?? null },
  });
}

export async function handleDetachPaymentMethod(
  service: ServiceClient,
  householdId: string,
  paymentMethodId: string
) {
  if (!paymentsConfigured()) return json({ error: "payments not configured" }, 503);
  // Only detach a card that belongs to this household.
  const { data: row } = await service
    .from("chez_payment_methods")
    .select("id, stripe_payment_method_id")
    .eq("household_id", householdId)
    .eq("stripe_payment_method_id", paymentMethodId)
    .is("detached_at", null)
    .maybeSingle();
  if (!row) return json({ error: "card not found" }, 404);

  await stripeCall(`payment_methods/${encodeURIComponent(paymentMethodId)}/detach`, "POST");
  await service.from("chez_payment_methods")
    .update({ detached_at: new Date().toISOString(), is_default: false })
    .eq("id", (row as { id: string }).id);
  return json({ ok: true });
}

// ---------------------------------------------------------------------------
// Admin: charge a job (within tier → off-session; above → approval)
// ---------------------------------------------------------------------------

interface SpendingTiers {
  auto_approve_under?: number;   // dollars
  explicit_above?: number;       // dollars
}

/// Returns true when the amount is within the household's auto-approve
/// tier (charge without asking). Defaults to $200 when unset, matching
/// the chez_profile default.
function withinAutoTier(amountCents: number, tiers: SpendingTiers): boolean {
  const autoUnder = typeof tiers.auto_approve_under === "number" ? tiers.auto_approve_under : 200;
  return amountCents <= autoUnder * 100;
}

/// Charge a job. Within tier: off-session PaymentIntent + succeeded
/// charge + thread receipt. Above tier: a requires_approval charge — the
/// caller (chez-concierge) sends the cost proposal that carries the
/// charge id, and decide_proposal confirms it on approval.
export async function chargeJob(
  service: ServiceClient,
  opts: {
    householdId: string;
    requestId: string;
    visitId?: string | null;
    amountCents: number;
    description: string;
    tiers: SpendingTiers;
  }
): Promise<{ ok: boolean; status: string; charge_id?: string; error?: string; needs_approval?: boolean }> {
  if (!paymentsConfigured()) return { ok: false, status: "unconfigured", error: "payments not configured" };
  if (!(opts.amountCents > 0)) return { ok: false, status: "invalid", error: "amount must be positive" };

  const { data: pm } = await service
    .from("chez_payment_methods")
    .select("stripe_payment_method_id")
    .eq("household_id", opts.householdId)
    .is("detached_at", null)
    .eq("is_default", true)
    .maybeSingle();
  const paymentMethodId = (pm as { stripe_payment_method_id?: string } | null)?.stripe_payment_method_id;
  if (!paymentMethodId) return { ok: false, status: "no_card", error: "no card on file" };

  const { data: hh } = await service
    .from("households")
    .select("stripe_customer_id")
    .eq("id", opts.householdId)
    .maybeSingle();
  const customerId = (hh as { stripe_customer_id?: string } | null)?.stripe_customer_id;
  if (!customerId) return { ok: false, status: "no_customer", error: "no Stripe customer" };

  // Above tier: record the charge as requires_approval; do NOT move money.
  if (!withinAutoTier(opts.amountCents, opts.tiers)) {
    const { data: charge } = await service.from("chez_charges").insert({
      household_id: opts.householdId,
      request_id: opts.requestId,
      visit_id: opts.visitId ?? null,
      amount_cents: opts.amountCents,
      status: "requires_approval",
      description: opts.description.slice(0, 300),
      initiated_by: "admin",
    }).select("id").single();
    return { ok: true, status: "requires_approval", charge_id: (charge as unknown as { id?: string } | null)?.id, needs_approval: true };
  }

  // Within tier: charge off-session now.
  const intent = await stripeCall("payment_intents", "POST", {
    amount: opts.amountCents,
    currency: "usd",
    customer: customerId,
    payment_method: paymentMethodId,
    off_session: "true",
    confirm: "true",
    description: opts.description.slice(0, 300),
    metadata: { household_id: opts.householdId, request_id: opts.requestId },
  });

  if (!intent.ok) {
    // SCA / expired card / decline: record failed, signal downgrade to a
    // cost proposal (the caller handles the in-app approval path).
    const reason = ((intent.data as { error?: { message?: string } }).error?.message) ?? "charge failed";
    const { data: charge } = await service.from("chez_charges").insert({
      household_id: opts.householdId,
      request_id: opts.requestId,
      visit_id: opts.visitId ?? null,
      amount_cents: opts.amountCents,
      status: "failed",
      description: opts.description.slice(0, 300),
      initiated_by: "auto_tier",
      failure_reason: reason.slice(0, 300),
    }).select("id").single();
    return { ok: false, status: "failed", charge_id: (charge as unknown as { id?: string } | null)?.id, error: reason, needs_approval: true };
  }

  const piId = String((intent.data as { id?: string }).id ?? "");
  const { data: charge } = await service.from("chez_charges").insert({
    household_id: opts.householdId,
    request_id: opts.requestId,
    visit_id: opts.visitId ?? null,
    stripe_payment_intent_id: piId,
    amount_cents: opts.amountCents,
    status: "succeeded",
    description: opts.description.slice(0, 300),
    initiated_by: "auto_tier",
  }).select("id").single();

  return { ok: true, status: "succeeded", charge_id: (charge as unknown as { id?: string } | null)?.id };
}

/// Confirm a requires_approval charge after the homeowner approves the
/// cost proposal it rides on. Called from decide_proposal.
export async function confirmApprovedCharge(
  service: ServiceClient,
  chargeId: string
): Promise<{ ok: boolean; error?: string }> {
  if (!paymentsConfigured()) return { ok: false, error: "payments not configured" };
  const { data: c } = await service
    .from("chez_charges")
    .select("id, household_id, amount_cents, description, request_id, status")
    .eq("id", chargeId)
    .maybeSingle();
  const charge = c as {
    id: string; household_id: string; amount_cents: number;
    description: string | null; request_id: string | null; status: string;
  } | null;
  if (!charge) return { ok: false, error: "charge not found" };
  if (charge.status !== "requires_approval") return { ok: false, error: "charge not awaiting approval" };

  const { data: pm } = await service
    .from("chez_payment_methods")
    .select("stripe_payment_method_id")
    .eq("household_id", charge.household_id)
    .is("detached_at", null)
    .eq("is_default", true)
    .maybeSingle();
  const paymentMethodId = (pm as { stripe_payment_method_id?: string } | null)?.stripe_payment_method_id;
  const { data: hh } = await service
    .from("households")
    .select("stripe_customer_id")
    .eq("id", charge.household_id)
    .maybeSingle();
  const customerId = (hh as { stripe_customer_id?: string } | null)?.stripe_customer_id;
  if (!paymentMethodId || !customerId) return { ok: false, error: "no card on file" };

  const intent = await stripeCall("payment_intents", "POST", {
    amount: charge.amount_cents,
    currency: "usd",
    customer: customerId,
    payment_method: paymentMethodId,
    off_session: "true",
    confirm: "true",
    description: (charge.description ?? "Chez job").slice(0, 300),
    metadata: { household_id: charge.household_id, request_id: charge.request_id ?? "", charge_id: charge.id },
  });
  if (!intent.ok) {
    const reason = ((intent.data as { error?: { message?: string } }).error?.message) ?? "charge failed";
    await service.from("chez_charges").update({ status: "failed", failure_reason: reason.slice(0, 300) }).eq("id", chargeId);
    return { ok: false, error: reason };
  }
  await service.from("chez_charges").update({
    status: "succeeded",
    stripe_payment_intent_id: String((intent.data as { id?: string }).id ?? ""),
    initiated_by: "homeowner_approval",
  }).eq("id", chargeId);
  return { ok: true };
}

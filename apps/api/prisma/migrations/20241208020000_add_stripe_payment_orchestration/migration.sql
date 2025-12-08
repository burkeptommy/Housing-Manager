-- CreateEnum
CREATE TYPE "PayoutMethod" AS ENUM ('STRIPE_CONNECT', 'CHECK', 'MANUAL');

-- CreateEnum
CREATE TYPE "HouseholdInvoiceStatus" AS ENUM ('PENDING', 'PROCESSING', 'PAID', 'FAILED', 'CANCELLED');

-- AlterTable (Household - add Stripe fields)
ALTER TABLE "households" ADD COLUMN "stripe_customer_id" TEXT;
ALTER TABLE "households" ADD COLUMN "consolidated_billing_day" INTEGER;

-- CreateIndex for unique stripe_customer_id
CREATE UNIQUE INDEX "households_stripe_customer_id_key" ON "households"("stripe_customer_id");

-- AlterTable (BillAccount - rename and add fields)
-- Rename autopay_enabled to vendor_autopay_enabled
ALTER TABLE "bill_accounts" RENAME COLUMN "autopay_enabled" TO "vendor_autopay_enabled";

-- Add new Haven pay-on-behalf fields
ALTER TABLE "bill_accounts" ADD COLUMN "max_auto_pay_amount" DECIMAL(10,2);
ALTER TABLE "bill_accounts" ADD COLUMN "haven_auto_pay_enabled" BOOLEAN NOT NULL DEFAULT true;
ALTER TABLE "bill_accounts" ADD COLUMN "include_in_consolidated_invoice" BOOLEAN NOT NULL DEFAULT true;

-- CreateIndex for payment responsibility filtering
CREATE INDEX "bill_accounts_household_id_payment_responsibility_idx" ON "bill_accounts"("household_id", "payment_responsibility");

-- CreateTable (VendorPayoutAccount)
CREATE TABLE "vendor_payout_accounts" (
    "id" TEXT NOT NULL,
    "vendor_id" TEXT NOT NULL,
    "stripe_account_id" TEXT,
    "payout_method" "PayoutMethod" NOT NULL DEFAULT 'MANUAL',
    "payout_details" JSONB,
    "stripe_onboarding_complete" BOOLEAN NOT NULL DEFAULT false,
    "notes" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "vendor_payout_accounts_pkey" PRIMARY KEY ("id")
);

-- CreateIndex (VendorPayoutAccount)
CREATE UNIQUE INDEX "vendor_payout_accounts_vendor_id_key" ON "vendor_payout_accounts"("vendor_id");
CREATE UNIQUE INDEX "vendor_payout_accounts_stripe_account_id_key" ON "vendor_payout_accounts"("stripe_account_id");

-- AddForeignKey
ALTER TABLE "vendor_payout_accounts" ADD CONSTRAINT "vendor_payout_accounts_vendor_id_fkey" FOREIGN KEY ("vendor_id") REFERENCES "vendors"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- CreateTable (HouseholdInvoice)
CREATE TABLE "household_invoices" (
    "id" TEXT NOT NULL,
    "household_id" TEXT NOT NULL,
    "invoice_number" TEXT NOT NULL,
    "billing_period_start" TIMESTAMP(3) NOT NULL,
    "billing_period_end" TIMESTAMP(3) NOT NULL,
    "subtotal" DECIMAL(10,2) NOT NULL,
    "platform_fee" DECIMAL(10,2) NOT NULL DEFAULT 0,
    "total" DECIMAL(10,2) NOT NULL,
    "status" "HouseholdInvoiceStatus" NOT NULL DEFAULT 'PENDING',
    "stripe_payment_intent_id" TEXT,
    "stripe_payment_status" TEXT,
    "paid_at" TIMESTAMP(3),
    "failed_at" TIMESTAMP(3),
    "failure_reason" TEXT,
    "notes" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "household_invoices_pkey" PRIMARY KEY ("id")
);

-- CreateIndex (HouseholdInvoice)
CREATE UNIQUE INDEX "household_invoices_invoice_number_key" ON "household_invoices"("invoice_number");
CREATE INDEX "household_invoices_household_id_status_idx" ON "household_invoices"("household_id", "status");
CREATE INDEX "household_invoices_billing_period_start_billing_period_end_idx" ON "household_invoices"("billing_period_start", "billing_period_end");

-- AddForeignKey
ALTER TABLE "household_invoices" ADD CONSTRAINT "household_invoices_household_id_fkey" FOREIGN KEY ("household_id") REFERENCES "households"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- CreateTable (HouseholdInvoiceItem)
CREATE TABLE "household_invoice_items" (
    "id" TEXT NOT NULL,
    "household_invoice_id" TEXT NOT NULL,
    "bill_account_id" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "amount" DECIMAL(10,2) NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "household_invoice_items_pkey" PRIMARY KEY ("id")
);

-- CreateIndex (HouseholdInvoiceItem)
CREATE INDEX "household_invoice_items_household_invoice_id_idx" ON "household_invoice_items"("household_invoice_id");
CREATE INDEX "household_invoice_items_bill_account_id_idx" ON "household_invoice_items"("bill_account_id");

-- AddForeignKey
ALTER TABLE "household_invoice_items" ADD CONSTRAINT "household_invoice_items_household_invoice_id_fkey" FOREIGN KEY ("household_invoice_id") REFERENCES "household_invoices"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "household_invoice_items" ADD CONSTRAINT "household_invoice_items_bill_account_id_fkey" FOREIGN KEY ("bill_account_id") REFERENCES "bill_accounts"("id") ON DELETE CASCADE ON UPDATE CASCADE;

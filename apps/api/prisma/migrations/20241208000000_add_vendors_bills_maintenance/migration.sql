-- CreateEnum
CREATE TYPE "VendorCategory" AS ENUM (
  'MORTGAGE', 'HOA', 'PROPERTY_TAX',
  'ELECTRIC', 'GAS', 'WATER_SEWER', 'TRASH', 'INTERNET', 'MOBILE', 'CABLE',
  'HOME_INSURANCE', 'AUTO_INSURANCE', 'HEALTH_INSURANCE', 'LIFE_INSURANCE', 'PET_INSURANCE',
  'CREDIT_CARD', 'STUDENT_LOAN', 'PERSONAL_LOAN', 'VEHICLE_LOAN', 'HELOC',
  'STREAMING', 'GYM', 'SECURITY_MONITORING', 'PEST_CONTROL', 'LAWN_CARE', 'LANDSCAPING', 'HOME_WARRANTY',
  'CLEANING', 'WINDOW_WASHING', 'GUTTER_CLEANING', 'HVAC_SERVICE', 'FILTER_SERVICE', 'CHIMNEY_SWEEP', 'SEPTIC_SERVICE', 'POOL_SERVICE', 'SNOW_REMOVAL', 'HANDYMAN',
  'OTHER'
);

-- CreateEnum
CREATE TYPE "BillingFrequency" AS ENUM ('WEEKLY', 'BIWEEKLY', 'MONTHLY', 'QUARTERLY', 'SEMIANNUALLY', 'ANNUAL', 'PER_VISIT', 'PER_JOB', 'OTHER');

-- CreateEnum
CREATE TYPE "PaymentResponsibility" AS ENUM ('OWNER_PAYS_DIRECT', 'HAVEN_PAYS_ON_BEHALF', 'VENDOR_AUTOPAY');

-- CreateEnum
CREATE TYPE "PaymentMethodType" AS ENUM ('CARD', 'BANK_ACCOUNT');

-- CreateEnum
CREATE TYPE "MaintenanceCategory" AS ENUM ('HVAC', 'PLUMBING', 'ROOF_GUTTER', 'CHIMNEY', 'SEPTIC', 'LANDSCAPING', 'PEST', 'POOL', 'SAFETY', 'CLEANING', 'APPLIANCES', 'EXTERIOR', 'INTERIOR', 'GENERAL');

-- CreateEnum
CREATE TYPE "MaintenanceTaskStatus" AS ENUM ('PENDING', 'SCHEDULED', 'COMPLETED', 'SKIPPED', 'OVERDUE');

-- AlterTable: Update vendors table
ALTER TABLE "vendors" ADD COLUMN IF NOT EXISTS "household_id" TEXT;
ALTER TABLE "vendors" ADD COLUMN IF NOT EXISTS "category" "VendorCategory" NOT NULL DEFAULT 'OTHER';
ALTER TABLE "vendors" ADD COLUMN IF NOT EXISTS "service_description" TEXT;
ALTER TABLE "vendors" ADD COLUMN IF NOT EXISTS "is_local" BOOLEAN NOT NULL DEFAULT true;
ALTER TABLE "vendors" ADD COLUMN IF NOT EXISTS "website_url" TEXT;
ALTER TABLE "vendors" ADD COLUMN IF NOT EXISTS "notes" TEXT;

-- Rename name to display_name if name exists (handle both cases)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'vendors' AND column_name = 'name') THEN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'vendors' AND column_name = 'display_name') THEN
      ALTER TABLE "vendors" RENAME COLUMN "name" TO "display_name";
    END IF;
  END IF;
END $$;

-- Add display_name if it still doesn't exist
ALTER TABLE "vendors" ADD COLUMN IF NOT EXISTS "display_name" TEXT NOT NULL DEFAULT 'Unknown';

-- CreateTable: payment_methods
CREATE TABLE IF NOT EXISTS "payment_methods" (
    "id" TEXT NOT NULL,
    "household_id" TEXT NOT NULL,
    "stripe_customer_id" TEXT NOT NULL,
    "stripe_payment_method_id" TEXT NOT NULL,
    "label" TEXT NOT NULL,
    "type" "PaymentMethodType" NOT NULL DEFAULT 'CARD',
    "last4" TEXT NOT NULL,
    "exp_month" INTEGER,
    "exp_year" INTEGER,
    "bank_name" TEXT,
    "is_default_for_subscription" BOOLEAN NOT NULL DEFAULT false,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "payment_methods_pkey" PRIMARY KEY ("id")
);

-- CreateTable: bill_accounts
CREATE TABLE IF NOT EXISTS "bill_accounts" (
    "id" TEXT NOT NULL,
    "household_id" TEXT NOT NULL,
    "vendor_id" TEXT NOT NULL,
    "payment_method_id" TEXT,
    "nickname" TEXT NOT NULL,
    "category" "VendorCategory" NOT NULL DEFAULT 'OTHER',
    "account_number" TEXT,
    "billing_frequency" "BillingFrequency" NOT NULL DEFAULT 'MONTHLY',
    "payment_responsibility" "PaymentResponsibility" NOT NULL DEFAULT 'OWNER_PAYS_DIRECT',
    "typical_amount" DECIMAL(10,2),
    "next_due_date" TIMESTAMP(3),
    "autopay_enabled" BOOLEAN NOT NULL DEFAULT false,
    "portal_url" TEXT,
    "support_phone" TEXT,
    "notes" TEXT,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,
    "deleted_at" TIMESTAMP(3),

    CONSTRAINT "bill_accounts_pkey" PRIMARY KEY ("id")
);

-- CreateTable: maintenance_templates
CREATE TABLE IF NOT EXISTS "maintenance_templates" (
    "id" TEXT NOT NULL,
    "slug" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "description" TEXT,
    "category" "MaintenanceCategory" NOT NULL DEFAULT 'GENERAL',
    "recommended_frequency_months" INTEGER,
    "recommended_season_start_month" INTEGER,
    "recommended_season_end_month" INTEGER,
    "property_conditions_json" JSONB,
    "default_vendor_category" "VendorCategory",
    "estimated_cost_min" DECIMAL(10,2),
    "estimated_cost_max" DECIMAL(10,2),
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "sort_order" INTEGER NOT NULL DEFAULT 0,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "maintenance_templates_pkey" PRIMARY KEY ("id")
);

-- CreateTable: maintenance_tasks
CREATE TABLE IF NOT EXISTS "maintenance_tasks" (
    "id" TEXT NOT NULL,
    "household_id" TEXT NOT NULL,
    "template_id" TEXT,
    "assigned_vendor_id" TEXT,
    "title" TEXT NOT NULL,
    "description" TEXT,
    "category" "MaintenanceCategory" NOT NULL DEFAULT 'GENERAL',
    "status" "MaintenanceTaskStatus" NOT NULL DEFAULT 'PENDING',
    "due_date" TIMESTAMP(3),
    "scheduled_date" TIMESTAMP(3),
    "completed_at" TIMESTAMP(3),
    "estimated_cost" DECIMAL(10,2),
    "actual_cost" DECIMAL(10,2),
    "created_from_template" BOOLEAN NOT NULL DEFAULT false,
    "notes" TEXT,
    "priority" "TaskPriority" NOT NULL DEFAULT 'MEDIUM',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "maintenance_tasks_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX IF NOT EXISTS "maintenance_templates_slug_key" ON "maintenance_templates"("slug");

-- CreateIndex
CREATE INDEX IF NOT EXISTS "payment_methods_household_id_idx" ON "payment_methods"("household_id");

-- CreateIndex
CREATE INDEX IF NOT EXISTS "bill_accounts_household_id_category_idx" ON "bill_accounts"("household_id", "category");

-- CreateIndex
CREATE INDEX IF NOT EXISTS "bill_accounts_household_id_next_due_date_idx" ON "bill_accounts"("household_id", "next_due_date");

-- CreateIndex
CREATE INDEX IF NOT EXISTS "maintenance_tasks_household_id_status_idx" ON "maintenance_tasks"("household_id", "status");

-- CreateIndex
CREATE INDEX IF NOT EXISTS "maintenance_tasks_household_id_due_date_idx" ON "maintenance_tasks"("household_id", "due_date");

-- CreateIndex
CREATE INDEX IF NOT EXISTS "maintenance_tasks_household_id_category_idx" ON "maintenance_tasks"("household_id", "category");

-- CreateIndex
CREATE INDEX IF NOT EXISTS "vendors_household_id_category_idx" ON "vendors"("household_id", "category");

-- AddForeignKey
ALTER TABLE "vendors" ADD CONSTRAINT "vendors_household_id_fkey" FOREIGN KEY ("household_id") REFERENCES "households"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "payment_methods" ADD CONSTRAINT "payment_methods_household_id_fkey" FOREIGN KEY ("household_id") REFERENCES "households"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "bill_accounts" ADD CONSTRAINT "bill_accounts_household_id_fkey" FOREIGN KEY ("household_id") REFERENCES "households"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "bill_accounts" ADD CONSTRAINT "bill_accounts_vendor_id_fkey" FOREIGN KEY ("vendor_id") REFERENCES "vendors"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "bill_accounts" ADD CONSTRAINT "bill_accounts_payment_method_id_fkey" FOREIGN KEY ("payment_method_id") REFERENCES "payment_methods"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "maintenance_tasks" ADD CONSTRAINT "maintenance_tasks_household_id_fkey" FOREIGN KEY ("household_id") REFERENCES "households"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "maintenance_tasks" ADD CONSTRAINT "maintenance_tasks_template_id_fkey" FOREIGN KEY ("template_id") REFERENCES "maintenance_templates"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "maintenance_tasks" ADD CONSTRAINT "maintenance_tasks_assigned_vendor_id_fkey" FOREIGN KEY ("assigned_vendor_id") REFERENCES "vendors"("id") ON DELETE SET NULL ON UPDATE CASCADE;

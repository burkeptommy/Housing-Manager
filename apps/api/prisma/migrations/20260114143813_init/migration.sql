-- CreateEnum
CREATE TYPE "UserRole" AS ENUM ('ADMIN', 'HOMEOWNER', 'MANAGER', 'VENDOR', 'HANDYMAN');

-- CreateEnum
CREATE TYPE "HouseholdRole" AS ENUM ('OWNER', 'MEMBER', 'GUEST', 'HOME_MANAGER', 'ADMIN');

-- CreateEnum
CREATE TYPE "HouseholdMemberStatus" AS ENUM ('PENDING', 'ACTIVE', 'INACTIVE');

-- CreateEnum
CREATE TYPE "HouseholdSubscriptionPlan" AS ENUM ('FREE', 'ESSENTIALS', 'PREMIUM');

-- CreateEnum
CREATE TYPE "HouseholdSubscriptionStatus" AS ENUM ('INACTIVE', 'ACTIVE', 'PAST_DUE', 'CANCELED');

-- CreateEnum
CREATE TYPE "PropertyType" AS ENUM ('SINGLE_FAMILY', 'CONDO', 'TOWNHOUSE', 'APARTMENT', 'MULTI_FAMILY', 'MOBILE_HOME', 'OTHER');

-- CreateEnum
CREATE TYPE "ServiceRequestStatus" AS ENUM ('DRAFT', 'SUBMITTED', 'ASSIGNED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED');

-- CreateEnum
CREATE TYPE "ServiceRequestPriority" AS ENUM ('LOW', 'MEDIUM', 'HIGH', 'URGENT');

-- CreateEnum
CREATE TYPE "HomeownerInputType" AS ENUM ('NONE', 'CHOICE', 'SCHEDULE', 'APPROVAL', 'INFORMATION');

-- CreateEnum
CREATE TYPE "RequestQuickCategory" AS ENUM ('FIX', 'SCHEDULE', 'BUY', 'RESEARCH', 'OTHER');

-- CreateEnum
CREATE TYPE "TaskStatus" AS ENUM ('PENDING', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED');

-- CreateEnum
CREATE TYPE "TaskPriority" AS ENUM ('LOW', 'MEDIUM', 'HIGH', 'URGENT');

-- CreateEnum
CREATE TYPE "TaskRecurrence" AS ENUM ('NONE', 'DAILY', 'WEEKLY', 'BIWEEKLY', 'MONTHLY', 'QUARTERLY', 'SEMIANNUALLY', 'ANNUALLY');

-- CreateEnum
CREATE TYPE "MaintenanceFrequency" AS ENUM ('WEEKLY', 'BIWEEKLY', 'MONTHLY', 'QUARTERLY', 'SEMI_ANNUAL', 'SEMIANNUALLY', 'ANNUAL', 'ANNUALLY', 'BIENNIAL', 'TRIENNIAL', 'ONE_TIME', 'AS_NEEDED');

-- CreateEnum
CREATE TYPE "SubscriptionTier" AS ENUM ('FREE', 'BASIC', 'PREMIUM', 'ENTERPRISE', 'ESSENTIALS', 'LITE', 'HAVEN', 'HAVEN_PLUS', 'ESTATE');

-- CreateEnum
CREATE TYPE "SubscriptionStatus" AS ENUM ('ACTIVE', 'PAST_DUE', 'CANCELLED', 'EXPIRED');

-- CreateEnum
CREATE TYPE "InvoiceStatus" AS ENUM ('DRAFT', 'SENT', 'PAID', 'OVERDUE', 'CANCELLED', 'REFUNDED');

-- CreateEnum
CREATE TYPE "MessageType" AS ENUM ('TEXT', 'SYSTEM', 'SERVICE_UPDATE');

-- CreateEnum
CREATE TYPE "ChannelType" AS ENUM ('HOUSEHOLD', 'REQUEST');

-- CreateEnum
CREATE TYPE "FileCategory" AS ENUM ('DOCUMENT', 'IMAGE', 'RECEIPT', 'WARRANTY', 'MANUAL', 'CONTRACT', 'OTHER');

-- CreateEnum
CREATE TYPE "VendorCategory" AS ENUM ('MORTGAGE', 'HOA', 'PROPERTY_TAX', 'ELECTRIC', 'GAS', 'WATER_SEWER', 'TRASH', 'INTERNET', 'MOBILE', 'CABLE', 'HOME_INSURANCE', 'AUTO_INSURANCE', 'HEALTH_INSURANCE', 'LIFE_INSURANCE', 'PET_INSURANCE', 'UMBRELLA_INSURANCE', 'CREDIT_CARD', 'STUDENT_LOAN', 'PERSONAL_LOAN', 'VEHICLE_LOAN', 'HELOC', 'TUITION', 'CHILDCARE', 'SPORTS_ACTIVITIES', 'MUSIC_LESSONS', 'TUTORING', 'CAMPS', 'EXTRACURRICULAR', 'PET_FOOD', 'PET_GROOMING', 'VET_CARE', 'PET_DAYCARE', 'STREAMING', 'GYM', 'SECURITY_MONITORING', 'PEST_CONTROL', 'LAWN_CARE', 'LANDSCAPING', 'HOME_WARRANTY', 'CLEANING', 'WINDOW_WASHING', 'GUTTER_CLEANING', 'HVAC_SERVICE', 'FILTER_SERVICE', 'CHIMNEY_SWEEP', 'SEPTIC_SERVICE', 'POOL_SERVICE', 'SNOW_REMOVAL', 'HANDYMAN', 'OTHER');

-- CreateEnum
CREATE TYPE "VendorActivityType" AS ENUM ('SERVICE', 'QUOTE', 'CALL', 'EMAIL', 'PAYMENT', 'NOTE', 'COMPLAINT', 'APPOINTMENT', 'ESTIMATE', 'WARRANTY');

-- CreateEnum
CREATE TYPE "BillingFrequency" AS ENUM ('WEEKLY', 'BIWEEKLY', 'MONTHLY', 'QUARTERLY', 'SEMIANNUALLY', 'SEMI_ANNUAL', 'ANNUAL', 'PER_VISIT', 'PER_JOB', 'IRREGULAR', 'OTHER');

-- CreateEnum
CREATE TYPE "PaymentResponsibility" AS ENUM ('OWNER_PAYS_DIRECT', 'HAVEN_PAYS_ON_BEHALF', 'VENDOR_AUTOPAY');

-- CreateEnum
CREATE TYPE "PaymentMethodType" AS ENUM ('CARD', 'BANK_ACCOUNT');

-- CreateEnum
CREATE TYPE "MaintenanceCategory" AS ENUM ('HVAC', 'PLUMBING', 'ELECTRICAL', 'ROOFING', 'ROOF_GUTTER', 'CHIMNEY', 'SEPTIC', 'LANDSCAPING', 'PEST', 'POOL', 'SAFETY', 'CLEANING', 'APPLIANCES', 'EXTERIOR', 'INTERIOR', 'SEASONAL', 'GENERAL', 'OTHER');

-- CreateEnum
CREATE TYPE "MaintenanceTaskStatus" AS ENUM ('PENDING', 'SCHEDULED', 'COMPLETED', 'SKIPPED', 'OVERDUE', 'IN_PROGRESS', 'DUE_SOON', 'UPCOMING');

-- CreateEnum
CREATE TYPE "SeasonalTiming" AS ENUM ('SPRING', 'SUMMER', 'FALL', 'WINTER', 'ANY');

-- CreateEnum
CREATE TYPE "TaskSource" AS ENUM ('SYSTEM_GENERATED', 'MANAGER_CREATED', 'USER_CREATED', 'VENDOR_RECOMMENDED');

-- CreateEnum
CREATE TYPE "ReminderType" AS ENUM ('BILL_DUE', 'MAINTENANCE_TASK', 'WORK_ORDER');

-- CreateEnum
CREATE TYPE "ReminderStatus" AS ENUM ('PENDING', 'SENT', 'CANCELLED', 'FAILED');

-- CreateEnum
CREATE TYPE "ReminderChannel" AS ENUM ('EMAIL', 'PUSH', 'SMS', 'IN_APP');

-- CreateEnum
CREATE TYPE "PayoutMethod" AS ENUM ('STRIPE_CONNECT', 'CHECK', 'MANUAL');

-- CreateEnum
CREATE TYPE "HouseholdInvoiceStatus" AS ENUM ('PENDING', 'PROCESSING', 'PAID', 'FAILED', 'CANCELLED');

-- CreateEnum
CREATE TYPE "ConversationStatus" AS ENUM ('OPEN', 'PENDING', 'CLOSED');

-- CreateEnum
CREATE TYPE "SenderRole" AS ENUM ('HOMEOWNER', 'HOME_MANAGER', 'SYSTEM');

-- CreateEnum
CREATE TYPE "WorkOrderStatus" AS ENUM ('DRAFT', 'REQUESTED', 'SCHEDULED', 'OPEN', 'ASSIGNED', 'IN_PROGRESS', 'COMPLETED', 'VERIFIED', 'CANCELLED');

-- CreateEnum
CREATE TYPE "WorkOrderBillingType" AS ENUM ('BILLABLE_TO_CLIENT', 'INCLUSIVE');

-- CreateEnum
CREATE TYPE "ServiceCategoryTier" AS ENUM ('MINOR_MAINTENANCE', 'MAJOR_REPAIR', 'SPECIALIZED');

-- CreateEnum
CREATE TYPE "TransactionPayoutMethod" AS ENUM ('CHECKBOOK_IO', 'STRIPE', 'CASH', 'COMPANY_CARD', 'BANK_TRANSFER');

-- CreateEnum
CREATE TYPE "TransactionStatus" AS ENUM ('PENDING', 'PAID_TO_VENDOR', 'BILLED_TO_CLIENT', 'SETTLED', 'CANCELLED');

-- CreateEnum
CREATE TYPE "FileAssetType" AS ENUM ('ISSUE_PHOTO', 'RECEIPT', 'DOCUMENT', 'OTHER');

-- CreateEnum
CREATE TYPE "FileAssetStatus" AS ENUM ('PENDING', 'UPLOADED', 'FAILED');

-- CreateEnum
CREATE TYPE "PostVisibility" AS ENUM ('PRIVATE', 'NEIGHBORS_ONLY', 'FRIENDS_ONLY', 'PUBLIC');

-- CreateEnum
CREATE TYPE "CostDisplay" AS ENUM ('HIDDEN', 'RANGE', 'EXACT');

-- CreateEnum
CREATE TYPE "FriendshipStatus" AS ENUM ('PENDING', 'ACCEPTED', 'DECLINED', 'BLOCKED');

-- CreateEnum
CREATE TYPE "ProjectIdeaStatus" AS ENUM ('DREAMING', 'PLANNING', 'ACTIVE', 'COMPLETED', 'ARCHIVED');

-- CreateEnum
CREATE TYPE "ProjectCategory" AS ENUM ('BATHROOM_REMODEL', 'KITCHEN_REMODEL', 'DECK_PATIO', 'LANDSCAPING', 'ROOF', 'WINDOWS_DOORS', 'FLOORING', 'PAINTING', 'HVAC', 'ELECTRICAL', 'PLUMBING', 'ADDITION', 'BASEMENT', 'GARAGE', 'FENCE', 'POOL', 'SOLAR', 'SMART_HOME', 'EXTERIOR_SIDING', 'OTHER');

-- CreateEnum
CREATE TYPE "RecommendationRequestStatus" AS ENUM ('OPEN', 'REVIEWING', 'SELECTED', 'CLOSED');

-- CreateEnum
CREATE TYPE "FamilyEventCategory" AS ENUM ('SCHOOL', 'MEDICAL', 'SPORTS', 'SOCIAL', 'WORK', 'TRAVEL', 'MAINTENANCE', 'FINANCIAL', 'RELIGIOUS', 'BIRTHDAY', 'HOLIDAY', 'OTHER');

-- CreateEnum
CREATE TYPE "EventCreatorRole" AS ENUM ('HOMEOWNER', 'MANAGER', 'SYSTEM', 'SYNCED');

-- CreateEnum
CREATE TYPE "CalendarSyncSource" AS ENUM ('GOOGLE', 'APPLE', 'OUTLOOK', 'MANUAL');

-- CreateEnum
CREATE TYPE "MemberPermissionType" AS ENUM ('VIEW_CALENDAR', 'EDIT_CALENDAR', 'VIEW_BILLS', 'PAY_BILLS', 'VIEW_MAINTENANCE', 'REQUEST_MAINTENANCE', 'VIEW_ASSETS', 'EDIT_ASSETS', 'VIEW_MEMBERS', 'MANAGE_MEMBERS', 'VIEW_BUDGET', 'FULL_ACCESS');

-- CreateEnum
CREATE TYPE "VehicleType" AS ENUM ('CAR', 'SUV', 'TRUCK', 'VAN', 'MOTORCYCLE', 'BOAT', 'RV', 'ATV', 'ELECTRIC', 'HYBRID', 'OTHER');

-- CreateEnum
CREATE TYPE "FuelType" AS ENUM ('GASOLINE', 'DIESEL', 'ELECTRIC', 'HYBRID', 'PLUG_IN_HYBRID', 'HYDROGEN', 'OTHER');

-- CreateEnum
CREATE TYPE "VehicleServiceType" AS ENUM ('OIL_CHANGE', 'TIRE_ROTATION', 'BRAKE_SERVICE', 'BATTERY_REPLACEMENT', 'TRANSMISSION_SERVICE', 'AIR_FILTER', 'CABIN_FILTER', 'COOLANT_FLUSH', 'SPARK_PLUGS', 'INSPECTION', 'EMISSIONS_TEST', 'ALIGNMENT', 'WIPER_BLADES', 'GENERAL_MAINTENANCE', 'REPAIR', 'RECALL', 'ACCIDENT_REPAIR', 'DETAIL', 'WASH', 'OTHER');

-- CreateEnum
CREATE TYPE "PetType" AS ENUM ('DOG', 'CAT', 'BIRD', 'FISH', 'REPTILE', 'SMALL_MAMMAL', 'HORSE', 'OTHER');

-- CreateEnum
CREATE TYPE "PetSize" AS ENUM ('SMALL', 'MEDIUM', 'LARGE', 'EXTRA_LARGE');

-- CreateEnum
CREATE TYPE "HomeSystemType" AS ENUM ('FURNACE', 'AIR_CONDITIONER', 'HEAT_PUMP', 'BOILER', 'THERMOSTAT', 'WATER_HEATER', 'WATER_SOFTENER', 'WELL_PUMP', 'SUMP_PUMP', 'ELECTRICAL_PANEL', 'GENERATOR', 'SOLAR_PANELS', 'BATTERY_STORAGE', 'REFRIGERATOR', 'DISHWASHER', 'OVEN_RANGE', 'MICROWAVE', 'GARBAGE_DISPOSAL', 'WASHER', 'DRYER', 'IRRIGATION_SYSTEM', 'POOL_EQUIPMENT', 'HOT_TUB', 'LAWN_MOWER', 'SMOKE_DETECTOR', 'CO_DETECTOR', 'SECURITY_SYSTEM', 'FIRE_EXTINGUISHER', 'GARAGE_DOOR_OPENER', 'CEILING_FAN', 'FIREPLACE', 'OTHER');

-- CreateEnum
CREATE TYPE "ApplianceCondition" AS ENUM ('EXCELLENT', 'GOOD', 'FAIR', 'NEEDS_REPAIR', 'REPLACED');

-- CreateEnum
CREATE TYPE "ApprovalType" AS ENUM ('EXPENSE', 'VENDOR_SELECTION', 'SCHEDULE', 'PROJECT', 'OTHER');

-- CreateEnum
CREATE TYPE "ApprovalStatus" AS ENUM ('PENDING', 'APPROVED', 'REJECTED', 'EXPIRED', 'CANCELLED');

-- CreateEnum
CREATE TYPE "ApprovalPriority" AS ENUM ('LOW', 'MEDIUM', 'HIGH', 'URGENT');

-- CreateEnum
CREATE TYPE "ActorType" AS ENUM ('HOMEOWNER', 'HOME_MANAGER', 'HANDYMAN', 'VENDOR', 'SYSTEM');

-- CreateEnum
CREATE TYPE "ActivityAction" AS ENUM ('BILL_PAID', 'BILL_SCHEDULED', 'BILL_ADDED', 'SERVICE_COMPLETED', 'SERVICE_SCHEDULED', 'SERVICE_REQUESTED', 'ASSET_ADDED', 'ASSET_UPDATED', 'ZONE_ADDED', 'VENDOR_ADDED', 'VENDOR_CONTACTED', 'APPROVAL_REQUESTED', 'APPROVAL_GRANTED', 'APPROVAL_DENIED', 'MESSAGE_SENT', 'NOTE_ADDED', 'REMINDER_SENT', 'DOCUMENT_UPLOADED');

-- CreateEnum
CREATE TYPE "ActivityCategory" AS ENUM ('BILLING', 'SERVICE', 'MAINTENANCE', 'COMMUNICATION', 'PROPERTY', 'FAMILY', 'SYSTEM');

-- CreateEnum
CREATE TYPE "ReferralStatus" AS ENUM ('PENDING', 'SIGNED_UP', 'CONVERTED', 'EXPIRED');

-- CreateEnum
CREATE TYPE "InboundChannel" AS ENUM ('EMAIL', 'SMS', 'CHAT');

-- CreateEnum
CREATE TYPE "RequestCategory" AS ENUM ('BILL', 'FIX', 'PROJECT', 'CALENDAR', 'TRIP', 'INQUIRY', 'UNKNOWN');

-- CreateEnum
CREATE TYPE "TriageStatus" AS ENUM ('RECEIVED', 'PROCESSING', 'PENDING_REVIEW', 'AUTO_APPROVED', 'NEEDS_ATTENTION', 'RESOLVED', 'REJECTED', 'ERROR');

-- CreateEnum
CREATE TYPE "TriagePriority" AS ENUM ('LOW', 'MEDIUM', 'HIGH', 'URGENT');

-- CreateEnum
CREATE TYPE "TripStatus" AS ENUM ('INQUIRY', 'PROPOSAL_SENT', 'PENDING_SELECTION', 'BOOKED', 'ACTIVE', 'COMPLETED', 'CANCELLED');

-- CreateEnum
CREATE TYPE "ItineraryItemType" AS ENUM ('FLIGHT', 'STAY', 'CAR_RENTAL', 'ACTIVITY', 'TRANSFER', 'OTHER');

-- CreateEnum
CREATE TYPE "HouseProtocolStatus" AS ENUM ('PENDING', 'IN_PROGRESS', 'COMPLETED', 'VERIFIED');

-- CreateEnum
CREATE TYPE "ProtocolItemStatus" AS ENUM ('PENDING', 'COMPLETED', 'SKIPPED', 'BLOCKED');

-- CreateEnum
CREATE TYPE "SeatingPreference" AS ENUM ('WINDOW', 'AISLE', 'MIDDLE', 'NO_PREFERENCE');

-- CreateEnum
CREATE TYPE "IntakeStatus" AS ENUM ('PENDING', 'SCHEDULED', 'IN_PROGRESS', 'PAUSED', 'COMPLETED', 'ARCHIVED');

-- CreateEnum
CREATE TYPE "FamilyMemberType" AS ENUM ('ADULT', 'CHILD', 'STAFF');

-- CreateEnum
CREATE TYPE "ZoneType" AS ENUM ('KITCHEN', 'LIVING_ROOM', 'DINING_ROOM', 'BEDROOM', 'BATHROOM', 'GARAGE', 'BASEMENT', 'ATTIC', 'LAUNDRY', 'OFFICE', 'MUDROOM', 'PANTRY', 'OUTDOOR_FRONT', 'OUTDOOR_BACK', 'POOL_AREA', 'MECHANICAL', 'OTHER');

-- CreateEnum
CREATE TYPE "AssetCategory" AS ENUM ('APPLIANCE', 'HVAC', 'PLUMBING', 'ELECTRICAL', 'STRUCTURAL', 'FURNITURE', 'ELECTRONICS', 'OUTDOOR', 'VEHICLE', 'SAFETY', 'OTHER');

-- CreateEnum
CREATE TYPE "ServiceLogType" AS ENUM ('MAINTENANCE', 'REPAIR', 'REPLACEMENT', 'INSPECTION', 'INSTALLATION', 'CLEANING', 'OTHER');

-- CreateEnum
CREATE TYPE "DocumentType" AS ENUM ('CONTRACT', 'WARRANTY', 'MANUAL', 'RECEIPT', 'INVOICE', 'INSURANCE', 'TAX', 'PHOTO', 'OTHER');

-- CreateEnum
CREATE TYPE "OnboardingStatus" AS ENUM ('PENDING_CALL', 'SIGNUP_COMPLETE', 'CALL_SCHEDULED', 'CALL_IN_PROGRESS', 'INTAKE_PARTIAL', 'INTAKE_COMPLETE', 'PROFILE_BUILDING', 'PROFILE_DELIVERED', 'ACTIVE');

-- CreateEnum
CREATE TYPE "BillCategory" AS ENUM ('MORTGAGE', 'RENT', 'PROPERTY_TAX', 'HOA', 'HOME_INSURANCE', 'ELECTRIC', 'GAS', 'WATER_SEWER', 'OIL_PROPANE', 'TRASH', 'INTERNET', 'CABLE_TV', 'CELL_PHONE', 'LANDLINE', 'CAR_PAYMENT', 'AUTO_INSURANCE', 'CAR_REGISTRATION', 'PARKING', 'TOLLS', 'SCHOOL_TUITION', 'CHILDCARE', 'NANNY', 'KIDS_ACTIVITY', 'SCHOOL_LUNCH', 'TUTORING', 'STUDENT_LOAN', 'PERSONAL_LOAN', 'HELOC', 'CREDIT_CARD', 'LIFE_INSURANCE', 'HEALTH_INSURANCE', 'UMBRELLA_INSURANCE', 'PET_INSURANCE', 'DISABILITY_INSURANCE', 'LONG_TERM_CARE', 'LAWN_LANDSCAPE', 'POOL_SERVICE', 'PEST_CONTROL', 'SECURITY_MONITORING', 'HOUSE_CLEANING', 'SNOW_REMOVAL', 'GYM_FITNESS', 'CLUB_MEMBERSHIP', 'STREAMING_SERVICE', 'SOFTWARE_SUBSCRIPTION', 'NEWSPAPER_MAGAZINE', 'MEAL_KIT', 'AMAZON_PRIME', 'WAREHOUSE_CLUB', 'STORAGE', 'PET_CARE', 'CHARITY_DONATION', 'CHILD_SUPPORT', 'ALIMONY', 'OTHER_BILL');

-- CreateEnum
CREATE TYPE "PayeeType" AS ENUM ('COMPANY', 'INDIVIDUAL', 'GOVERNMENT', 'SCHOOL', 'ORGANIZATION');

-- CreateEnum
CREATE TYPE "AmountType" AS ENUM ('FIXED', 'VARIABLE', 'ESTIMATED');

-- CreateEnum
CREATE TYPE "PaymentFrequency" AS ENUM ('WEEKLY', 'BIWEEKLY', 'TWICE_MONTHLY', 'MONTHLY', 'QUARTERLY', 'SEMI_ANNUAL', 'ANNUAL', 'ONE_TIME', 'AS_NEEDED');

-- CreateEnum
CREATE TYPE "BillPaymentMethod" AS ENUM ('HAVEN_PAYS', 'OWNER_AUTOPAY', 'OWNER_MANUAL', 'PAYROLL', 'ESCROW');

-- CreateEnum
CREATE TYPE "BillStatus" AS ENUM ('ACTIVE', 'PAUSED', 'CANCELLED', 'PAID_OFF', 'PENDING_SETUP');

-- CreateEnum
CREATE TYPE "ActivityType" AS ENUM ('SPORTS', 'MUSIC', 'ARTS', 'ACADEMIC', 'RELIGIOUS', 'SOCIAL', 'CAMP', 'OTHER_ACTIVITY');

-- CreateEnum
CREATE TYPE "DocumentCategory" AS ENUM ('PROPERTY', 'INSURANCE', 'WARRANTY', 'MANUAL', 'TAX', 'CONTRACT', 'RECEIPT', 'PERMIT', 'OTHER');

-- CreateEnum
CREATE TYPE "PlaidConnectionStatus" AS ENUM ('ACTIVE', 'ERROR', 'DISCONNECTED', 'PENDING_REAUTH');

-- CreateEnum
CREATE TYPE "DetectedBillStatus" AS ENUM ('PENDING', 'CONFIRMED', 'DISMISSED', 'IGNORED');

-- CreateTable
CREATE TABLE "users" (
    "id" TEXT NOT NULL,
    "firebase_uid" TEXT,
    "email" TEXT NOT NULL,
    "password_hash" TEXT,
    "first_name" TEXT,
    "last_name" TEXT,
    "display_name" TEXT,
    "phone" TEXT,
    "avatar_url" TEXT,
    "role" "UserRole" NOT NULL DEFAULT 'HOMEOWNER',
    "email_verified" BOOLEAN NOT NULL DEFAULT false,
    "email_verified_at" TIMESTAMP(3),
    "last_login_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,
    "is_public_profile" BOOLEAN NOT NULL DEFAULT false,
    "influencer_badges" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "bio" TEXT,
    "referral_code" TEXT,

    CONSTRAINT "users_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "refresh_tokens" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "token" TEXT NOT NULL,
    "expires_at" TIMESTAMP(3) NOT NULL,
    "is_revoked" BOOLEAN NOT NULL DEFAULT false,
    "user_agent" TEXT,
    "ip_address" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "refresh_tokens_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "households" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT,
    "owner_id" TEXT NOT NULL,
    "manager_id" TEXT,
    "assigned_handyman_id" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,
    "h3_index" TEXT,
    "stripe_customer_id" TEXT,
    "subscription_plan" "HouseholdSubscriptionPlan" NOT NULL DEFAULT 'FREE',
    "subscription_status" "HouseholdSubscriptionStatus" NOT NULL DEFAULT 'INACTIVE',
    "concierge_enabled" BOOLEAN NOT NULL DEFAULT false,
    "monthly_visit_day" INTEGER,
    "billing_cycle_day" INTEGER NOT NULL DEFAULT 1,
    "billing_settings" JSONB,
    "enrichment_data" JSONB,
    "electricity_provider" TEXT,
    "electricity_confirmed" BOOLEAN NOT NULL DEFAULT false,
    "gas_provider" TEXT,
    "gas_confirmed" BOOLEAN NOT NULL DEFAULT false,
    "water_source" TEXT,
    "water_source_confirmed" BOOLEAN NOT NULL DEFAULT false,
    "water_provider" TEXT,
    "sewer_type" TEXT,
    "sewer_type_confirmed" BOOLEAN NOT NULL DEFAULT false,
    "sewer_provider" TEXT,
    "heating_fuel" TEXT,
    "heating_fuel_provider" TEXT,
    "internet_provider" TEXT,
    "cable_provider" TEXT,
    "mortgage_provider" TEXT,
    "mortgage_monthly_payment" DOUBLE PRECISION,
    "mortgage_detected_at" TIMESTAMP(3),
    "insurance_provider" TEXT,
    "insurance_payment_amount" DOUBLE PRECISION,
    "insurance_payment_freq" TEXT,
    "insurance_detected_at" TIMESTAMP(3),
    "home_health_score" INTEGER DEFAULT 85,
    "property_photo_url" TEXT,
    "attom_data_fetched" BOOLEAN NOT NULL DEFAULT false,
    "plaid_data_analyzed" BOOLEAN NOT NULL DEFAULT false,
    "initial_setup_complete" BOOLEAN NOT NULL DEFAULT false,
    "alfred_questions_asked" JSONB,
    "alfred_data_gaps" JSONB,

    CONSTRAINT "households_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "household_members" (
    "id" TEXT NOT NULL,
    "household_id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "role" "HouseholdRole" NOT NULL DEFAULT 'MEMBER',
    "status" "HouseholdMemberStatus" NOT NULL DEFAULT 'PENDING',
    "invited_by_user_id" TEXT,
    "invited_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "accepted_at" TIMESTAMP(3),
    "joined_at" TIMESTAMP(3),
    "nickname" TEXT,
    "birthday" DATE,
    "shirt_size" TEXT,
    "pant_size" TEXT,
    "shoe_size" TEXT,
    "dietary_restrictions" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "allergies" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "medical_notes" TEXT,
    "favorite_color" TEXT,
    "interests" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "profile_photo_url" TEXT,
    "employer" TEXT,
    "job_title" TEXT,
    "work_address" TEXT,
    "work_phone" TEXT,
    "work_schedule" TEXT,
    "commute_miles" DOUBLE PRECISION,
    "primary_physician" TEXT,
    "physician_phone" TEXT,
    "dentist" TEXT,
    "dentist_phone" TEXT,
    "blood_type" TEXT,
    "insurance_provider" TEXT,
    "insurance_number" TEXT,
    "relationship" TEXT,
    "permissions" "MemberPermissionType"[] DEFAULT ARRAY['VIEW_CALENDAR', 'VIEW_ASSETS', 'VIEW_MEMBERS']::"MemberPermissionType"[],
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "household_members_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "household_invites" (
    "id" TEXT NOT NULL,
    "household_id" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "token" TEXT NOT NULL,
    "role" "HouseholdRole" NOT NULL DEFAULT 'MEMBER',
    "invited_by_id" TEXT NOT NULL,
    "expires_at" TIMESTAMP(3) NOT NULL,
    "accepted_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "household_invites_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "referrals" (
    "id" TEXT NOT NULL,
    "referrer_id" TEXT NOT NULL,
    "referral_code" TEXT NOT NULL,
    "referee_email" TEXT,
    "referee_id" TEXT,
    "status" "ReferralStatus" NOT NULL DEFAULT 'PENDING',
    "reward_earned" BOOLEAN NOT NULL DEFAULT false,
    "reward_amount" DECIMAL(10,2),
    "reward_paid_at" TIMESTAMP(3),
    "signed_up_at" TIMESTAMP(3),
    "converted_at" TIMESTAMP(3),
    "expires_at" TIMESTAMP(3) NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "referrals_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "vehicles" (
    "id" TEXT NOT NULL,
    "household_id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "make" TEXT NOT NULL,
    "model" TEXT NOT NULL,
    "year" INTEGER NOT NULL,
    "vehicle_type" "VehicleType" NOT NULL DEFAULT 'SUV',
    "color" TEXT,
    "vin" TEXT,
    "license_plate" TEXT,
    "primary_driver_id" TEXT,
    "is_owned" BOOLEAN NOT NULL DEFAULT true,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "current_mileage" INTEGER,
    "mileage_updated_at" TIMESTAMP(3),
    "annual_miles" INTEGER,
    "registration_expiry" TIMESTAMP(3),
    "registration_state" TEXT,
    "insurance_provider" TEXT,
    "insurance_policy_num" TEXT,
    "insurance_expiry" TIMESTAMP(3),
    "insurance_monthly" DECIMAL(10,2),
    "has_loan" BOOLEAN NOT NULL DEFAULT false,
    "lender" TEXT,
    "monthly_payment" DECIMAL(10,2),
    "loan_balance" DECIMAL(12,2),
    "loan_maturity_date" TIMESTAMP(3),
    "last_oil_change" TIMESTAMP(3),
    "oil_change_mileage" INTEGER,
    "next_service_due" TIMESTAMP(3),
    "next_service_mileage" INTEGER,
    "preferred_service_shop" TEXT,
    "photo_url" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "vehicles_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "vehicle_services" (
    "id" TEXT NOT NULL,
    "vehicle_id" TEXT NOT NULL,
    "service_type" "VehicleServiceType" NOT NULL,
    "description" TEXT,
    "service_date" TIMESTAMP(3) NOT NULL,
    "mileage_at" INTEGER,
    "cost" DECIMAL(10,2),
    "shop_name" TEXT,
    "shop_address" TEXT,
    "next_service_date" TIMESTAMP(3),
    "next_service_mileage" INTEGER,
    "notes" TEXT,
    "receipt_url" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "vehicle_services_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "home_profiles" (
    "id" TEXT NOT NULL,
    "household_id" TEXT NOT NULL,
    "property_type" "PropertyType" NOT NULL DEFAULT 'SINGLE_FAMILY',
    "address_line_1" TEXT NOT NULL,
    "address_line_2" TEXT,
    "city" TEXT NOT NULL,
    "state" TEXT NOT NULL,
    "postal_code" TEXT NOT NULL,
    "country" TEXT NOT NULL DEFAULT 'US',
    "square_feet" INTEGER,
    "lot_size" DOUBLE PRECISION,
    "year_built" INTEGER,
    "bedrooms" INTEGER,
    "bathrooms" DOUBLE PRECISION,
    "stories" INTEGER,
    "garage_spaces" INTEGER,
    "purchase_date" TIMESTAMP(3),
    "purchase_price" DECIMAL(12,2),
    "current_value" DECIMAL(12,2),
    "notes" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "home_profiles_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "service_categories" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT,
    "icon" TEXT,
    "sort_order" INTEGER NOT NULL DEFAULT 0,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,
    "tier" "ServiceCategoryTier" NOT NULL DEFAULT 'MAJOR_REPAIR',
    "default_billing_type" "WorkOrderBillingType" NOT NULL DEFAULT 'BILLABLE_TO_CLIENT',
    "is_handyman_eligible" BOOLEAN NOT NULL DEFAULT false,
    "estimated_minutes" INTEGER,

    CONSTRAINT "service_categories_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "vendors" (
    "id" TEXT NOT NULL,
    "household_id" TEXT,
    "display_name" TEXT NOT NULL,
    "category" "VendorCategory" NOT NULL DEFAULT 'OTHER',
    "service_description" TEXT,
    "is_local" BOOLEAN NOT NULL DEFAULT true,
    "contact_name" TEXT,
    "email" TEXT,
    "phone" TEXT,
    "website_url" TEXT,
    "address_line_1" TEXT,
    "address_line_2" TEXT,
    "city" TEXT,
    "state" TEXT,
    "postal_code" TEXT,
    "country" TEXT DEFAULT 'US',
    "license_number" TEXT,
    "insurance_info" TEXT,
    "rating" REAL,
    "review_count" INTEGER NOT NULL DEFAULT 0,
    "service_category_id" TEXT,
    "is_verified" BOOLEAN NOT NULL DEFAULT false,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "notes" TEXT,
    "user_id" TEXT,
    "service_areas" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "vendors_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "household_vendors" (
    "id" TEXT NOT NULL,
    "household_id" TEXT NOT NULL,
    "vendor_id" TEXT NOT NULL,
    "notes" TEXT,
    "is_favorite" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,
    "rating" INTEGER,
    "tags" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "source" TEXT,
    "referred_by" TEXT,
    "last_contact_date" TIMESTAMP(3),
    "custom_category" TEXT,

    CONSTRAINT "household_vendors_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "vendor_activities" (
    "id" TEXT NOT NULL,
    "household_vendor_id" TEXT NOT NULL,
    "type" "VendorActivityType" NOT NULL,
    "title" TEXT NOT NULL,
    "description" TEXT,
    "amount" DOUBLE PRECISION,
    "is_paid" BOOLEAN NOT NULL DEFAULT false,
    "date" TIMESTAMP(3) NOT NULL,
    "duration" INTEGER,
    "invoice_url" TEXT,
    "receipt_url" TEXT,
    "document_ids" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "maintenance_task_id" TEXT,
    "service_request_id" TEXT,
    "created_by" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "vendor_activities_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "vendor_messages" (
    "id" TEXT NOT NULL,
    "household_vendor_id" TEXT NOT NULL,
    "direction" TEXT NOT NULL,
    "content" TEXT NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'sent',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "vendor_messages_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "service_requests" (
    "id" TEXT NOT NULL,
    "household_id" TEXT NOT NULL,
    "service_category_id" TEXT,
    "vendor_id" TEXT,
    "created_by_id" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "status" "ServiceRequestStatus" NOT NULL DEFAULT 'DRAFT',
    "priority" "ServiceRequestPriority" NOT NULL DEFAULT 'MEDIUM',
    "quick_category" "RequestQuickCategory",
    "preferred_date" TIMESTAMP(3),
    "scheduled_date" TIMESTAMP(3),
    "completed_date" TIMESTAMP(3),
    "estimated_cost" DECIMAL(10,2),
    "actual_cost" DECIMAL(10,2),
    "notes" TEXT,
    "requires_homeowner_input" BOOLEAN NOT NULL DEFAULT false,
    "input_type" "HomeownerInputType" NOT NULL DEFAULT 'NONE',
    "input_question" TEXT,
    "input_options" JSONB,
    "input_response" TEXT,
    "input_responded_at" TIMESTAMP(3),
    "similar_request_id" TEXT,
    "recurring_issue" BOOLEAN NOT NULL DEFAULT false,
    "previous_fix_date" TIMESTAMP(3),
    "previous_vendor_id" TEXT,
    "voice_transcript" TEXT,
    "photo_urls" JSONB,
    "manager_note" TEXT,
    "last_status_update" TEXT,
    "status_updated_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "service_requests_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "tasks" (
    "id" TEXT NOT NULL,
    "household_id" TEXT NOT NULL,
    "created_by_id" TEXT NOT NULL,
    "assignee_id" TEXT,
    "title" TEXT NOT NULL,
    "description" TEXT,
    "status" "TaskStatus" NOT NULL DEFAULT 'PENDING',
    "priority" "TaskPriority" NOT NULL DEFAULT 'MEDIUM',
    "due_date" TIMESTAMP(3),
    "completed_at" TIMESTAMP(3),
    "recurrence" "TaskRecurrence" NOT NULL DEFAULT 'NONE',
    "next_occurrence" TIMESTAMP(3),
    "room_name" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "tasks_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "maintenance_plans" (
    "id" TEXT NOT NULL,
    "household_id" TEXT NOT NULL,
    "service_category_id" TEXT,
    "name" TEXT NOT NULL,
    "description" TEXT,
    "frequency" "MaintenanceFrequency" NOT NULL,
    "last_completed_at" TIMESTAMP(3),
    "next_due_date" TIMESTAMP(3),
    "estimated_cost" DECIMAL(10,2),
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "notes" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "maintenance_plans_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "messages" (
    "id" TEXT NOT NULL,
    "channel_type" "ChannelType" NOT NULL,
    "household_id" TEXT,
    "service_request_id" TEXT,
    "sender_id" TEXT,
    "vendor_id" TEXT,
    "content" TEXT NOT NULL,
    "message_type" "MessageType" NOT NULL DEFAULT 'TEXT',
    "is_read" BOOLEAN NOT NULL DEFAULT false,
    "read_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "messages_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "subscriptions" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "tier" "SubscriptionTier" NOT NULL DEFAULT 'FREE',
    "status" "SubscriptionStatus" NOT NULL DEFAULT 'ACTIVE',
    "current_period_start" TIMESTAMP(3) NOT NULL,
    "current_period_end" TIMESTAMP(3) NOT NULL,
    "stripe_customer_id" TEXT,
    "stripe_subscription_id" TEXT,
    "cancelled_at" TIMESTAMP(3),
    "cancel_at_period_end" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "subscriptions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "invoices" (
    "id" TEXT NOT NULL,
    "household_id" TEXT NOT NULL,
    "invoice_number" TEXT NOT NULL,
    "status" "InvoiceStatus" NOT NULL DEFAULT 'DRAFT',
    "subtotal" DECIMAL(10,2) NOT NULL,
    "tax" DECIMAL(10,2) NOT NULL DEFAULT 0,
    "total" DECIMAL(10,2) NOT NULL,
    "issued_at" TIMESTAMP(3),
    "due_date" TIMESTAMP(3),
    "paid_at" TIMESTAMP(3),
    "payment_method" TEXT,
    "payment_ref" TEXT,
    "notes" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "invoices_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "files" (
    "id" TEXT NOT NULL,
    "user_id" TEXT,
    "household_id" TEXT,
    "service_request_id" TEXT,
    "task_id" TEXT,
    "invoice_id" TEXT,
    "filename" TEXT NOT NULL,
    "original_name" TEXT NOT NULL,
    "mime_type" TEXT NOT NULL,
    "size" INTEGER NOT NULL,
    "url" TEXT,
    "gcs_uri" TEXT,
    "category" "FileCategory" NOT NULL DEFAULT 'DOCUMENT',
    "description" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "files_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "file_assets" (
    "id" TEXT NOT NULL,
    "household_id" TEXT NOT NULL,
    "uploader_user_id" TEXT NOT NULL,
    "type" "FileAssetType" NOT NULL DEFAULT 'OTHER',
    "status" "FileAssetStatus" NOT NULL DEFAULT 'PENDING',
    "gcs_path" TEXT NOT NULL,
    "url" TEXT,
    "filename" TEXT NOT NULL,
    "content_type" TEXT NOT NULL,
    "size" INTEGER,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "file_assets_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "payment_methods" (
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

-- CreateTable
CREATE TABLE "bill_accounts" (
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
    "last_paid_date" TIMESTAMP(3),
    "last_paid_amount" DECIMAL(10,2),
    "vendor_autopay_enabled" BOOLEAN NOT NULL DEFAULT false,
    "max_auto_pay_amount" DECIMAL(10,2),
    "haven_auto_pay_enabled" BOOLEAN NOT NULL DEFAULT true,
    "include_in_consolidated_invoice" BOOLEAN NOT NULL DEFAULT true,
    "loan_balance" DECIMAL(12,2),
    "interest_rate" DECIMAL(5,3),
    "loan_term_months" INTEGER,
    "loan_origination_date" TIMESTAMP(3),
    "estimated_payoff_date" TIMESTAMP(3),
    "escrow_amount" DECIMAL(10,2),
    "principal_amount" DECIMAL(10,2),
    "interest_amount" DECIMAL(10,2),
    "portal_url" TEXT,
    "support_phone" TEXT,
    "notes" TEXT,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,
    "deleted_at" TIMESTAMP(3),

    CONSTRAINT "bill_accounts_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "maintenance_templates" (
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

-- CreateTable
CREATE TABLE "maintenance_tasks" (
    "id" TEXT NOT NULL,
    "household_id" TEXT NOT NULL,
    "template_id" TEXT,
    "assigned_vendor_id" TEXT,
    "attachment_file_id" TEXT,
    "completed_by_id" TEXT,
    "home_system_id" TEXT,
    "title" TEXT NOT NULL,
    "description" TEXT,
    "category" "MaintenanceCategory" NOT NULL DEFAULT 'GENERAL',
    "status" "MaintenanceTaskStatus" NOT NULL DEFAULT 'PENDING',
    "frequency" "MaintenanceFrequency" DEFAULT 'ANNUAL',
    "seasonalTiming" "SeasonalTiming",
    "source" "TaskSource" NOT NULL DEFAULT 'MANAGER_CREATED',
    "source_system" TEXT,
    "is_recurring" BOOLEAN NOT NULL DEFAULT true,
    "recurring_interval_months" INTEGER,
    "due_date" TIMESTAMP(3),
    "next_due_date" TIMESTAMP(3),
    "scheduled_date" TIMESTAMP(3),
    "completed_at" TIMESTAMP(3),
    "last_completed_date" TIMESTAMP(3),
    "estimated_cost" DECIMAL(10,2),
    "actual_cost" DECIMAL(10,2),
    "created_from_template" BOOLEAN NOT NULL DEFAULT false,
    "notes" TEXT,
    "completion_notes" TEXT,
    "priority" "TaskPriority" NOT NULL DEFAULT 'MEDIUM',
    "checklist_steps" JSONB,
    "interval_explanation" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "maintenance_tasks_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "reminders" (
    "id" TEXT NOT NULL,
    "household_id" TEXT NOT NULL,
    "type" "ReminderType" NOT NULL,
    "bill_account_id" TEXT,
    "maintenance_task_id" TEXT,
    "work_order_id" TEXT,
    "scheduled_at" TIMESTAMP(3) NOT NULL,
    "sent_at" TIMESTAMP(3),
    "status" "ReminderStatus" NOT NULL DEFAULT 'PENDING',
    "channel" "ReminderChannel" NOT NULL DEFAULT 'EMAIL',
    "payload_json" JSONB,
    "error_message" TEXT,
    "retry_count" INTEGER NOT NULL DEFAULT 0,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "reminders_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "in_app_notifications" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "household_id" TEXT,
    "title" TEXT NOT NULL,
    "body" TEXT NOT NULL,
    "link" TEXT,
    "bill_account_id" TEXT,
    "maintenance_task_id" TEXT,
    "work_order_id" TEXT,
    "reminder_id" TEXT,
    "is_read" BOOLEAN NOT NULL DEFAULT false,
    "read_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "in_app_notifications_pkey" PRIMARY KEY ("id")
);

-- CreateTable
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

-- CreateTable
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

-- CreateTable
CREATE TABLE "household_invoice_items" (
    "id" TEXT NOT NULL,
    "household_invoice_id" TEXT NOT NULL,
    "bill_account_id" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "amount" DECIMAL(10,2) NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "household_invoice_items_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "conversations" (
    "id" TEXT NOT NULL,
    "household_id" TEXT NOT NULL,
    "created_by_user_id" TEXT NOT NULL,
    "subject" TEXT,
    "status" "ConversationStatus" NOT NULL DEFAULT 'OPEN',
    "homeowner_unread_count" INTEGER NOT NULL DEFAULT 0,
    "home_manager_unread_count" INTEGER NOT NULL DEFAULT 0,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "conversations_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "support_messages" (
    "id" TEXT NOT NULL,
    "conversation_id" TEXT NOT NULL,
    "sender_user_id" TEXT,
    "sender_role" "SenderRole" NOT NULL,
    "body" TEXT NOT NULL,
    "attachment_url" TEXT,
    "attachment_file_id" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "support_messages_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "home_manager_assignments" (
    "id" TEXT NOT NULL,
    "conversation_id" TEXT NOT NULL,
    "home_manager_user_id" TEXT NOT NULL,
    "assigned_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "assigned_by_user_id" TEXT,

    CONSTRAINT "home_manager_assignments_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "work_orders" (
    "id" TEXT NOT NULL,
    "household_id" TEXT NOT NULL,
    "maintenance_task_id" TEXT,
    "vendor_id" TEXT,
    "handyman_id" TEXT,
    "created_by_user_id" TEXT NOT NULL,
    "service_category_id" TEXT,
    "title" TEXT NOT NULL,
    "description" TEXT,
    "status" "WorkOrderStatus" NOT NULL DEFAULT 'DRAFT',
    "is_concierge_request" BOOLEAN NOT NULL DEFAULT false,
    "billing_type" "WorkOrderBillingType" NOT NULL DEFAULT 'BILLABLE_TO_CLIENT',
    "preferred_date" TIMESTAMP(3),
    "preferred_time_window_start" TEXT,
    "preferred_time_window_end" TEXT,
    "scheduled_start" TIMESTAMP(3),
    "scheduled_end" TIMESTAMP(3),
    "estimated_cost" DECIMAL(10,2),
    "actual_cost" DECIMAL(10,2),
    "internal_cost" DECIMAL(10,2),
    "completed_at" TIMESTAMP(3),
    "verified_at" TIMESTAMP(3),
    "verified_by_user_id" TEXT,
    "check_in_at" TIMESTAMP(3),
    "check_in_latitude" DOUBLE PRECISION,
    "check_in_longitude" DOUBLE PRECISION,
    "check_out_at" TIMESTAMP(3),
    "proof_images" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "service_area" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,
    "inbound_request_id" TEXT,

    CONSTRAINT "work_orders_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "work_order_notes" (
    "id" TEXT NOT NULL,
    "work_order_id" TEXT NOT NULL,
    "author_user_id" TEXT NOT NULL,
    "body" TEXT NOT NULL,
    "attachment_file_id" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "work_order_notes_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "company_wallet" (
    "id" TEXT NOT NULL,
    "balance" DECIMAL(12,2) NOT NULL DEFAULT 0,
    "outstanding_float" DECIMAL(12,2) NOT NULL DEFAULT 0,
    "monthly_collections" DECIMAL(12,2) NOT NULL DEFAULT 0,
    "monthly_disbursements" DECIMAL(12,2) NOT NULL DEFAULT 0,
    "last_reset_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "company_wallet_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "client_bank_accounts" (
    "id" TEXT NOT NULL,
    "household_id" TEXT NOT NULL,
    "stripe_payment_method_id" TEXT NOT NULL,
    "stripe_bank_account_id" TEXT,
    "bank_name" TEXT NOT NULL,
    "account_type" TEXT NOT NULL,
    "last4" TEXT NOT NULL,
    "routing_last4" TEXT,
    "is_verified" BOOLEAN NOT NULL DEFAULT false,
    "verified_at" TIMESTAMP(3),
    "is_default" BOOLEAN NOT NULL DEFAULT false,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "client_bank_accounts_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "transactions" (
    "id" TEXT NOT NULL,
    "household_id" TEXT NOT NULL,
    "vendor_id" TEXT,
    "handyman_id" TEXT,
    "manager_id" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "amount" DECIMAL(10,2) NOT NULL,
    "payout_method" "TransactionPayoutMethod" NOT NULL,
    "status" "TransactionStatus" NOT NULL DEFAULT 'PENDING',
    "is_reimbursable" BOOLEAN NOT NULL DEFAULT true,
    "is_inclusive_expense" BOOLEAN NOT NULL DEFAULT false,
    "handyman_hours" DECIMAL(4,2),
    "handyman_hourly_rate" DECIMAL(8,2),
    "paid_at" TIMESTAMP(3),
    "billed_at" TIMESTAMP(3),
    "settled_at" TIMESTAMP(3),
    "receipt_url" TEXT,
    "receipt_file_id" TEXT,
    "work_order_id" TEXT,
    "maintenance_task_id" TEXT,
    "household_invoice_id" TEXT,
    "due_date" TIMESTAMP(3),
    "notes" TEXT,
    "inbound_request_id" TEXT,
    "trip_id" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "transactions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "friendships" (
    "id" TEXT NOT NULL,
    "requester_id" TEXT NOT NULL,
    "addressee_id" TEXT NOT NULL,
    "status" "FriendshipStatus" NOT NULL DEFAULT 'PENDING',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,
    "accepted_at" TIMESTAMP(3),

    CONSTRAINT "friendships_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "follows" (
    "id" TEXT NOT NULL,
    "follower_id" TEXT NOT NULL,
    "following_id" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "follows_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "project_posts" (
    "id" TEXT NOT NULL,
    "author_id" TEXT NOT NULL,
    "household_id" TEXT NOT NULL,
    "work_order_id" TEXT,
    "vendor_id" TEXT,
    "title" TEXT NOT NULL,
    "description" TEXT,
    "before_images" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "after_images" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "visibility" "PostVisibility" NOT NULL DEFAULT 'PRIVATE',
    "cost_display" "CostDisplay" NOT NULL DEFAULT 'HIDDEN',
    "actual_cost" DECIMAL(10,2),
    "cost_range_min" DECIMAL(10,2),
    "cost_range_max" DECIMAL(10,2),
    "duration_days" INTEGER,
    "completed_at" TIMESTAMP(3),
    "likes_count" INTEGER NOT NULL DEFAULT 0,
    "saves_count" INTEGER NOT NULL DEFAULT 0,
    "comments_count" INTEGER NOT NULL DEFAULT 0,
    "is_verified" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "project_posts_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "project_likes" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "post_id" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "project_likes_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "saved_posts" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "post_id" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "saved_posts_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "post_comments" (
    "id" TEXT NOT NULL,
    "post_id" TEXT NOT NULL,
    "author_id" TEXT NOT NULL,
    "content" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "post_comments_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "vendor_service_areas" (
    "id" TEXT NOT NULL,
    "vendor_id" TEXT NOT NULL,
    "h3_index" TEXT NOT NULL,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "vendor_service_areas_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "project_templates" (
    "id" TEXT NOT NULL,
    "slug" TEXT NOT NULL,
    "category" "ProjectCategory" NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT,
    "base_material_cost" DECIMAL(10,2) NOT NULL,
    "labor_hours_per_sq_ft" DECIMAL(6,3),
    "base_labor_rate" DECIMAL(10,2) NOT NULL DEFAULT 75,
    "complexity_factors" JSONB,
    "min_sq_ft" INTEGER,
    "max_sq_ft" INTEGER,
    "estimated_days_min" INTEGER,
    "estimated_days_max" INTEGER,
    "inspiration_images" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "sort_order" INTEGER NOT NULL DEFAULT 0,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "project_templates_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "regional_cost_indexes" (
    "id" TEXT NOT NULL,
    "h3_index" TEXT NOT NULL,
    "h3_resolution" INTEGER NOT NULL DEFAULT 5,
    "multiplier" DECIMAL(4,2) NOT NULL,
    "labor_multiplier" DECIMAL(4,2) NOT NULL DEFAULT 1.0,
    "region_name" TEXT,
    "state_code" TEXT,
    "effective_from" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "effective_to" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "regional_cost_indexes_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "project_ideas" (
    "id" TEXT NOT NULL,
    "household_id" TEXT NOT NULL,
    "created_by_user_id" TEXT NOT NULL,
    "template_id" TEXT,
    "title" TEXT NOT NULL,
    "category" "ProjectCategory" NOT NULL,
    "description" TEXT,
    "specs" JSONB,
    "style" TEXT,
    "vibe_notes" TEXT,
    "mood_board_images" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "estimated_cost_min" DECIMAL(10,2),
    "estimated_cost_max" DECIMAL(10,2),
    "neighbor_project_count" INTEGER NOT NULL DEFAULT 0,
    "social_proof_note" TEXT,
    "status" "ProjectIdeaStatus" NOT NULL DEFAULT 'DREAMING',
    "target_start_date" TIMESTAMP(3),
    "target_completion_date" TIMESTAMP(3),
    "urgency" TEXT,
    "work_order_id" TEXT,
    "project_post_id" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,
    "inbound_request_id" TEXT,

    CONSTRAINT "project_ideas_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "recommendation_requests" (
    "id" TEXT NOT NULL,
    "project_idea_id" TEXT NOT NULL,
    "household_id" TEXT NOT NULL,
    "created_by_user_id" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "description" TEXT,
    "budget" TEXT,
    "timeline" TEXT,
    "h3_index" TEXT,
    "is_public" BOOLEAN NOT NULL DEFAULT true,
    "status" "RecommendationRequestStatus" NOT NULL DEFAULT 'OPEN',
    "view_count" INTEGER NOT NULL DEFAULT 0,
    "suggestion_count" INTEGER NOT NULL DEFAULT 0,
    "expires_at" TIMESTAMP(3),
    "closed_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "recommendation_requests_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "vendor_suggestions" (
    "id" TEXT NOT NULL,
    "project_idea_id" TEXT,
    "recommendation_request_id" TEXT,
    "vendor_id" TEXT NOT NULL,
    "suggested_by_user_id" TEXT,
    "comment" TEXT,
    "rating" INTEGER,
    "is_system_suggestion" BOOLEAN NOT NULL DEFAULT false,
    "system_note" TEXT,
    "reference_project_post_id" TEXT,
    "is_helpful" BOOLEAN,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "vendor_suggestions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "inbound_requests" (
    "id" TEXT NOT NULL,
    "household_id" TEXT,
    "user_id" TEXT,
    "channel" "InboundChannel" NOT NULL,
    "external_id" TEXT,
    "sender_email" TEXT,
    "sender_phone" TEXT,
    "sender_name" TEXT,
    "subject" TEXT,
    "body" TEXT NOT NULL,
    "raw_payload" JSONB,
    "category" "RequestCategory" NOT NULL DEFAULT 'UNKNOWN',
    "ai_confidence" DOUBLE PRECISION,
    "priority" "TriagePriority" NOT NULL DEFAULT 'MEDIUM',
    "summary" TEXT,
    "ai_reasoning" TEXT,
    "extracted_entities" JSONB,
    "status" "TriageStatus" NOT NULL DEFAULT 'RECEIVED',
    "resolved_action" TEXT,
    "resolved_entity_type" TEXT,
    "resolved_entity_id" TEXT,
    "resolved_at" TIMESTAMP(3),
    "resolved_by_user_id" TEXT,
    "manager_notes" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,
    "concierge_thread_id" TEXT,

    CONSTRAINT "inbound_requests_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "inbound_attachments" (
    "id" TEXT NOT NULL,
    "inbound_request_id" TEXT NOT NULL,
    "filename" TEXT NOT NULL,
    "content_type" TEXT NOT NULL,
    "size_bytes" INTEGER,
    "storage_url" TEXT,
    "extracted_text" TEXT,
    "document_type" TEXT,
    "extracted_entities" JSONB,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "inbound_attachments_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "triage_suggestions" (
    "id" TEXT NOT NULL,
    "inbound_request_id" TEXT NOT NULL,
    "actionType" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "description" TEXT,
    "confidence" DOUBLE PRECISION NOT NULL,
    "action_data" JSONB NOT NULL,
    "is_approved" BOOLEAN NOT NULL DEFAULT false,
    "is_rejected" BOOLEAN NOT NULL DEFAULT false,
    "rejection_reason" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "triage_suggestions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "concierge_threads" (
    "id" TEXT NOT NULL,
    "household_id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "title" TEXT,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "context" JSONB,
    "last_message_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "concierge_threads_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "concierge_messages" (
    "id" TEXT NOT NULL,
    "thread_id" TEXT NOT NULL,
    "role" TEXT NOT NULL,
    "content" TEXT NOT NULL,
    "created_inbound_request_id" TEXT,
    "ai_model" TEXT,
    "token_count" INTEGER,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "concierge_messages_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "family_events" (
    "id" TEXT NOT NULL,
    "household_id" TEXT NOT NULL,
    "created_by_user_id" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "description" TEXT,
    "location" TEXT,
    "category" "FamilyEventCategory" NOT NULL DEFAULT 'OTHER',
    "assigned_to_member_id" TEXT,
    "start_date" TIMESTAMP(3) NOT NULL,
    "end_date" TIMESTAMP(3),
    "is_all_day" BOOLEAN NOT NULL DEFAULT false,
    "is_recurring" BOOLEAN NOT NULL DEFAULT false,
    "recurrence" TEXT,
    "reminder_minutes" INTEGER[] DEFAULT ARRAY[]::INTEGER[],
    "color" TEXT,
    "created_by_role" "EventCreatorRole" NOT NULL DEFAULT 'HOMEOWNER',
    "manager_note" TEXT,
    "requires_action" BOOLEAN NOT NULL DEFAULT false,
    "action_description" TEXT,
    "action_completed_at" TIMESTAMP(3),
    "reminder_text" TEXT,
    "reminder_sent_at" TIMESTAMP(3),
    "has_conflict" BOOLEAN NOT NULL DEFAULT false,
    "conflict_reason" TEXT,
    "conflict_resolved_at" TIMESTAMP(3),
    "sync_source" "CalendarSyncSource" NOT NULL DEFAULT 'MANUAL',
    "external_calendar_id" TEXT,
    "external_event_id" TEXT,
    "last_synced_at" TIMESTAMP(3),
    "inbound_request_id" TEXT,
    "vehicle_id" TEXT,
    "pet_id" TEXT,
    "work_order_id" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "family_events_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "travel_profiles" (
    "id" TEXT NOT NULL,
    "household_member_id" TEXT NOT NULL,
    "passport_number" TEXT,
    "passport_country" TEXT,
    "passport_expiry" TIMESTAMP(3),
    "tsa_precheck" TEXT,
    "global_entry" TEXT,
    "seating_preference" "SeatingPreference" NOT NULL DEFAULT 'NO_PREFERENCE',
    "meal_preference" TEXT,
    "airline_loyalty" JSONB,
    "hotel_loyalty" JSONB,
    "car_rental_loyalty" JSONB,
    "emergency_contact_name" TEXT,
    "emergency_contact_phone" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "travel_profiles_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "trips" (
    "id" TEXT NOT NULL,
    "household_id" TEXT NOT NULL,
    "created_by_user_id" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "destination" TEXT NOT NULL,
    "destination_country" TEXT,
    "departure_city" TEXT,
    "start_date" TIMESTAMP(3) NOT NULL,
    "end_date" TIMESTAMP(3) NOT NULL,
    "is_flexible_dates" BOOLEAN NOT NULL DEFAULT false,
    "budget_min" DECIMAL(10,2),
    "budget_max" DECIMAL(10,2),
    "budget_notes" TEXT,
    "traveler_count" INTEGER NOT NULL DEFAULT 1,
    "travelers" JSONB,
    "status" "TripStatus" NOT NULL DEFAULT 'INQUIRY',
    "notes" TEXT,
    "assigned_manager_id" TEXT,
    "total_estimated_cost" DECIMAL(10,2),
    "total_actual_cost" DECIMAL(10,2),
    "inbound_request_id" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "trips_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "trip_proposals" (
    "id" TEXT NOT NULL,
    "trip_id" TEXT NOT NULL,
    "created_by_manager_id" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "category" "ItineraryItemType" NOT NULL,
    "description" TEXT,
    "options" JSONB NOT NULL,
    "selected_option_index" INTEGER,
    "selected_at" TIMESTAMP(3),
    "sent_at" TIMESTAMP(3),
    "expires_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "trip_proposals_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "itinerary_items" (
    "id" TEXT NOT NULL,
    "trip_id" TEXT NOT NULL,
    "type" "ItineraryItemType" NOT NULL,
    "title" TEXT NOT NULL,
    "description" TEXT,
    "start_date_time" TIMESTAMP(3) NOT NULL,
    "end_date_time" TIMESTAMP(3),
    "timezone" TEXT,
    "start_location" TEXT,
    "end_location" TEXT,
    "confirmation_number" TEXT,
    "booking_reference" TEXT,
    "provider_name" TEXT,
    "cost" DECIMAL(10,2) NOT NULL,
    "currency" TEXT NOT NULL DEFAULT 'USD',
    "paid_by_haven" BOOLEAN NOT NULL DEFAULT true,
    "transaction_id" TEXT,
    "documents" JSONB,
    "sort_order" INTEGER NOT NULL DEFAULT 0,
    "notes" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "itinerary_items_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "house_protocols" (
    "id" TEXT NOT NULL,
    "trip_id" TEXT NOT NULL,
    "household_id" TEXT NOT NULL,
    "assigned_to_user_id" TEXT,
    "scheduled_date" TIMESTAMP(3) NOT NULL,
    "completed_at" TIMESTAMP(3),
    "verified_at" TIMESTAMP(3),
    "verified_by_user_id" TEXT,
    "status" "HouseProtocolStatus" NOT NULL DEFAULT 'PENDING',
    "notes" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "house_protocols_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "house_protocol_items" (
    "id" TEXT NOT NULL,
    "protocol_id" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "description" TEXT,
    "category" TEXT,
    "status" "ProtocolItemStatus" NOT NULL DEFAULT 'PENDING',
    "completed_at" TIMESTAMP(3),
    "completed_by_user_id" TEXT,
    "proof_photo_url" TEXT,
    "proof_file_asset_id" TEXT,
    "proof_notes" TEXT,
    "sort_order" INTEGER NOT NULL DEFAULT 0,
    "is_required" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "house_protocol_items_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "pets" (
    "id" TEXT NOT NULL,
    "household_id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "type" "PetType" NOT NULL DEFAULT 'DOG',
    "breed" TEXT,
    "color" TEXT,
    "size" "PetSize",
    "weight" DECIMAL(6,2),
    "birthday" DATE,
    "adoption_date" DATE,
    "gender" TEXT,
    "microchip_id" TEXT,
    "registration_num" TEXT,
    "license_num" TEXT,
    "license_expires" TIMESTAMP(3),
    "is_spayed_neutered" BOOLEAN NOT NULL DEFAULT false,
    "allergies" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "medications" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "special_needs" TEXT,
    "vet_clinic_name" TEXT,
    "vet_clinic_phone" TEXT,
    "vet_clinic_address" TEXT,
    "vet_clinic_email" TEXT,
    "primary_vet_name" TEXT,
    "insurance_provider" TEXT,
    "insurance_policy_num" TEXT,
    "insurance_expires" TIMESTAMP(3),
    "food_brand" TEXT,
    "food_type" TEXT,
    "feeding_schedule" TEXT,
    "dietary_notes" TEXT,
    "care_instructions" TEXT,
    "emergency_contact" TEXT,
    "behavioral_notes" TEXT,
    "photo_urls" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "notes" TEXT,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "pets_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "pet_vet_records" (
    "id" TEXT NOT NULL,
    "pet_id" TEXT NOT NULL,
    "visit_date" TIMESTAMP(3) NOT NULL,
    "visit_type" TEXT NOT NULL,
    "description" TEXT,
    "diagnosis" TEXT,
    "treatment" TEXT,
    "weight" DECIMAL(6,2),
    "vaccinations_given" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "next_vaccination_date" TIMESTAMP(3),
    "prescriptions" JSONB,
    "cost" DECIMAL(10,2),
    "vet_clinic" TEXT,
    "vet_name" TEXT,
    "document_urls" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "follow_up_date" TIMESTAMP(3),
    "follow_up_notes" TEXT,
    "notes" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "pet_vet_records_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "home_systems" (
    "id" TEXT NOT NULL,
    "household_id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "type" "HomeSystemType" NOT NULL,
    "location" TEXT,
    "brand" TEXT,
    "model" TEXT,
    "model_number" TEXT,
    "serial_number" TEXT,
    "color" TEXT,
    "purchase_date" TIMESTAMP(3),
    "purchase_price" DECIMAL(10,2),
    "purchased_from" TEXT,
    "installed_date" TIMESTAMP(3),
    "installed_by" TEXT,
    "warranty_expires" TIMESTAMP(3),
    "warranty_provider" TEXT,
    "warranty_phone" TEXT,
    "warranty_details" TEXT,
    "extended_warranty" BOOLEAN NOT NULL DEFAULT false,
    "extended_warranty_expires" TIMESTAMP(3),
    "condition" "ApplianceCondition" NOT NULL DEFAULT 'GOOD',
    "last_inspected_date" TIMESTAMP(3),
    "maintenance_interval_months" INTEGER,
    "last_maintenance_date" TIMESTAMP(3),
    "next_maintenance_date" TIMESTAMP(3),
    "maintenance_notes" TEXT,
    "service_provider" TEXT,
    "service_account_number" TEXT,
    "service_phone" TEXT,
    "last_service_date" TIMESTAMP(3),
    "current_rate" DECIMAL(10,4),
    "rate_unit" TEXT,
    "last_bill_amount" DECIMAL(10,2),
    "last_bill_date" TIMESTAMP(3),
    "average_monthly_usage" DECIMAL(10,2),
    "usage_unit" TEXT,
    "tank_capacity" DECIMAL(10,2),
    "last_fill_date" TIMESTAMP(3),
    "last_fill_amount" DECIMAL(10,2),
    "estimated_remaining" DECIMAL(10,2),
    "manual_url" TEXT,
    "receipt_url" TEXT,
    "warranty_doc_url" TEXT,
    "photo_urls" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "energy_rating" TEXT,
    "efficiency_score" DECIMAL(4,2),
    "filter_size" TEXT,
    "filter_type" TEXT,
    "last_filter_change" TIMESTAMP(3),
    "filter_change_interval_months" INTEGER DEFAULT 3,
    "service_vendor_id" TEXT,
    "notes" TEXT,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "home_systems_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "home_system_services" (
    "id" TEXT NOT NULL,
    "home_system_id" TEXT NOT NULL,
    "service_date" TIMESTAMP(3) NOT NULL,
    "service_type" TEXT NOT NULL,
    "description" TEXT,
    "technician_name" TEXT,
    "parts_replaced" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "labor_cost" DECIMAL(10,2),
    "parts_cost" DECIMAL(10,2),
    "total_cost" DECIMAL(10,2),
    "vendor_id" TEXT,
    "vendor_name" TEXT,
    "invoice_url" TEXT,
    "receipt_url" TEXT,
    "report_url" TEXT,
    "next_service_date" TIMESTAMP(3),
    "recommendations" TEXT,
    "notes" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "home_system_services_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "home_checklists" (
    "id" TEXT NOT NULL,
    "household_id" TEXT NOT NULL,
    "items" JSONB NOT NULL,
    "total_items" INTEGER NOT NULL DEFAULT 0,
    "completed_items" INTEGER NOT NULL DEFAULT 0,
    "high_priority_remaining" INTEGER NOT NULL DEFAULT 0,
    "status" TEXT NOT NULL DEFAULT 'pending',
    "started_at" TIMESTAMP(3),
    "completed_at" TIMESTAMP(3),
    "completed_by_user_id" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "home_checklists_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "household_intakes" (
    "id" TEXT NOT NULL,
    "household_id" TEXT NOT NULL,
    "status" "OnboardingStatus" NOT NULL DEFAULT 'PENDING_CALL',
    "progress" INTEGER NOT NULL DEFAULT 0,
    "biggest_challenge" TEXT,
    "selected_tier" TEXT,
    "scheduled_at" TIMESTAMP(3),
    "started_at" TIMESTAMP(3),
    "completed_at" TIMESTAMP(3),
    "manager_id" TEXT,
    "sections_completed" JSONB,
    "progress_family" INTEGER NOT NULL DEFAULT 0,
    "progress_property" INTEGER NOT NULL DEFAULT 0,
    "progress_zones" INTEGER NOT NULL DEFAULT 0,
    "progress_systems" INTEGER NOT NULL DEFAULT 0,
    "progress_vendors" INTEGER NOT NULL DEFAULT 0,
    "progress_bills" INTEGER NOT NULL DEFAULT 0,
    "intake_data" JSONB,
    "call_notes" TEXT,
    "manager_notes" TEXT,
    "calculated_monthly_funding" DECIMAL(10,2),
    "funding_breakdown" JSONB,
    "next_steps" TEXT,
    "follow_up_date" TIMESTAMP(3),
    "follow_up_needed" BOOLEAN NOT NULL DEFAULT false,
    "follow_up_notes" TEXT,
    "profile_delivered_at" TIMESTAMP(3),
    "first_bill_paid_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "household_intakes_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "family_members" (
    "id" TEXT NOT NULL,
    "household_id" TEXT NOT NULL,
    "first_name" TEXT NOT NULL,
    "last_name" TEXT,
    "nickname" TEXT,
    "type" "FamilyMemberType" NOT NULL DEFAULT 'ADULT',
    "email" TEXT,
    "phone" TEXT,
    "birthdate" DATE,
    "relationship" TEXT,
    "school" TEXT,
    "school_grade" TEXT,
    "teacher" TEXT,
    "school_pickup" TEXT,
    "school_dropoff" TEXT,
    "work_schedule" TEXT,
    "responsibilities" TEXT,
    "start_date" DATE,
    "payment_method" TEXT,
    "allergies" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "medications" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "special_needs" TEXT,
    "blood_type" TEXT,
    "medical_notes" TEXT,
    "primary_doctor_name" TEXT,
    "primary_doctor_phone" TEXT,
    "primary_doctor_address" TEXT,
    "dentist_name" TEXT,
    "dentist_phone" TEXT,
    "dentist_address" TEXT,
    "occupation" TEXT,
    "employer" TEXT,
    "work_phone" TEXT,
    "work_address" TEXT,
    "emergency_contact" TEXT,
    "emergency_contact_phone" TEXT,
    "photo_url" TEXT,
    "notes" TEXT,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "family_members_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "memberships" (
    "id" TEXT NOT NULL,
    "household_id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "type" TEXT NOT NULL,
    "member_name" TEXT,
    "member_number" TEXT,
    "monthly_cost" DOUBLE PRECISION,
    "annual_cost" DOUBLE PRECISION,
    "contact_phone" TEXT,
    "contact_email" TEXT,
    "address" TEXT,
    "website" TEXT,
    "renewal_date" DATE,
    "start_date" DATE,
    "notes" TEXT,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "memberships_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "family_activities" (
    "id" TEXT NOT NULL,
    "household_id" TEXT NOT NULL,
    "family_member_id" TEXT,
    "name" TEXT NOT NULL,
    "category" TEXT NOT NULL,
    "description" TEXT,
    "location" TEXT,
    "schedule" TEXT,
    "start_date" DATE,
    "end_date" DATE,
    "is_seasonal" BOOLEAN NOT NULL DEFAULT false,
    "season" TEXT,
    "organization_name" TEXT,
    "contact_name" TEXT,
    "contact_phone" TEXT,
    "contact_email" TEXT,
    "website_url" TEXT,
    "cost_amount" DECIMAL(10,2),
    "cost_frequency" "BillingFrequency",
    "payment_method" TEXT,
    "payment_due_day" INTEGER,
    "equipment_needed" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "transportation" TEXT,
    "notes" TEXT,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "family_activities_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "comprehensive_bills" (
    "id" TEXT NOT NULL,
    "household_id" TEXT NOT NULL,
    "category" "BillCategory" NOT NULL,
    "subcategory" TEXT,
    "name" TEXT NOT NULL,
    "description" TEXT,
    "payee_name" TEXT,
    "payee_type" "PayeeType" NOT NULL DEFAULT 'COMPANY',
    "account_number" TEXT,
    "account_name" TEXT,
    "policy_number" TEXT,
    "member_number" TEXT,
    "student_id" TEXT,
    "portal_url" TEXT,
    "portal_username" TEXT,
    "portal_notes" TEXT,
    "amount" DECIMAL(10,2) NOT NULL,
    "amount_type" "AmountType" NOT NULL DEFAULT 'FIXED',
    "frequency" "PaymentFrequency" NOT NULL,
    "due_day" INTEGER,
    "due_date" TIMESTAMP(3),
    "payment_method" "BillPaymentMethod" NOT NULL DEFAULT 'HAVEN_PAYS',
    "current_autopay" BOOLEAN NOT NULL DEFAULT false,
    "autopay_account" TEXT,
    "is_loan" BOOLEAN NOT NULL DEFAULT false,
    "principal_balance" DECIMAL(12,2),
    "interest_rate" DECIMAL(5,3),
    "loan_term" TEXT,
    "maturity_date" TIMESTAMP(3),
    "escrow_included" BOOLEAN,
    "is_insurance" BOOLEAN NOT NULL DEFAULT false,
    "coverage_amount" DECIMAL(12,2),
    "deductible" DECIMAL(10,2),
    "renewal_date" TIMESTAMP(3),
    "vendor_id" TEXT,
    "vehicle_id" TEXT,
    "family_member_id" TEXT,
    "asset_id" TEXT,
    "status" "BillStatus" NOT NULL DEFAULT 'ACTIVE',
    "haven_managed" BOOLEAN NOT NULL DEFAULT false,
    "haven_start_date" TIMESTAMP(3),
    "verified" BOOLEAN NOT NULL DEFAULT false,
    "verified_at" TIMESTAMP(3),
    "verified_by" TEXT,
    "notes" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "comprehensive_bills_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "bill_payment_records" (
    "id" TEXT NOT NULL,
    "comprehensive_bill_id" TEXT NOT NULL,
    "amount" DECIMAL(10,2) NOT NULL,
    "paid_date" TIMESTAMP(3) NOT NULL,
    "paid_by" TEXT NOT NULL,
    "method" TEXT,
    "confirmation_number" TEXT,
    "notes" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "bill_payment_records_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "kid_activities" (
    "id" TEXT NOT NULL,
    "family_member_id" TEXT NOT NULL,
    "household_id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "type" "ActivityType" NOT NULL,
    "organization" TEXT,
    "location" TEXT,
    "schedule" TEXT,
    "season_start" TIMESTAMP(3),
    "season_end" TIMESTAMP(3),
    "cost" DECIMAL(10,2),
    "cost_frequency" "PaymentFrequency",
    "registration_fee" DECIMAL(10,2),
    "equipment_cost" DECIMAL(10,2),
    "coach_name" TEXT,
    "contact_phone" TEXT,
    "contact_email" TEXT,
    "payment_method" TEXT,
    "account_number" TEXT,
    "portal_url" TEXT,
    "notes" TEXT,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "kid_activities_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "zones" (
    "id" TEXT NOT NULL,
    "household_id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "type" "ZoneType" NOT NULL,
    "floor" TEXT,
    "photos" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "notes" TEXT,
    "procedures" TEXT,
    "sort_order" INTEGER NOT NULL DEFAULT 0,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "zones_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "property_assets" (
    "id" TEXT NOT NULL,
    "household_id" TEXT NOT NULL,
    "zone_id" TEXT,
    "name" TEXT NOT NULL,
    "category" "AssetCategory" NOT NULL,
    "brand" TEXT,
    "model" TEXT,
    "serial_number" TEXT,
    "color" TEXT,
    "purchase_date" TIMESTAMP(3),
    "purchase_price" DECIMAL(10,2),
    "purchase_vendor" TEXT,
    "warranty_expires" TIMESTAMP(3),
    "warranty_notes" TEXT,
    "condition" TEXT,
    "condition_notes" TEXT,
    "service_vendor_id" TEXT,
    "last_service_date" TIMESTAMP(3),
    "next_service_date" TIMESTAMP(3),
    "service_interval" TEXT,
    "photos" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "manual_url" TEXT,
    "notes" TEXT,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "property_assets_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "service_logs" (
    "id" TEXT NOT NULL,
    "household_id" TEXT NOT NULL,
    "asset_id" TEXT,
    "zone_id" TEXT,
    "type" "ServiceLogType" NOT NULL,
    "title" TEXT NOT NULL,
    "description" TEXT,
    "vendor_id" TEXT,
    "performed_by" TEXT,
    "service_date" TIMESTAMP(3) NOT NULL,
    "cost" DECIMAL(10,2),
    "invoice_url" TEXT,
    "photos" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "notes" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "service_logs_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "property_documents" (
    "id" TEXT NOT NULL,
    "household_id" TEXT NOT NULL,
    "type" "DocumentType" NOT NULL,
    "name" TEXT NOT NULL,
    "file_url" TEXT NOT NULL,
    "vendor_id" TEXT,
    "asset_id" TEXT,
    "bill_account_id" TEXT,
    "uploaded_by" TEXT,
    "notes" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "property_documents_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "onboarding_progress" (
    "id" TEXT NOT NULL,
    "household_id" TEXT NOT NULL,
    "signup_date" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "biggest_challenge" TEXT,
    "selected_tier" TEXT,
    "call_scheduled_for" TIMESTAMP(3),
    "call_started_at" TIMESTAMP(3),
    "call_completed_at" TIMESTAMP(3),
    "call_notes" TEXT,
    "family_complete" INTEGER NOT NULL DEFAULT 0,
    "property_complete" INTEGER NOT NULL DEFAULT 0,
    "zones_complete" INTEGER NOT NULL DEFAULT 0,
    "systems_complete" INTEGER NOT NULL DEFAULT 0,
    "assets_complete" INTEGER NOT NULL DEFAULT 0,
    "vendors_complete" INTEGER NOT NULL DEFAULT 0,
    "bills_complete" INTEGER NOT NULL DEFAULT 0,
    "intake_data" JSONB,
    "follow_up_needed" BOOLEAN NOT NULL DEFAULT false,
    "follow_up_notes" TEXT,
    "profile_delivered_at" TIMESTAMP(3),
    "first_bill_paid_at" TIMESTAMP(3),
    "all_bills_consolidated_at" TIMESTAMP(3),
    "thirty_day_review_at" TIMESTAMP(3),
    "ninety_day_review_at" TIMESTAMP(3),
    "one_year_review_at" TIMESTAMP(3),
    "status" "OnboardingStatus" NOT NULL DEFAULT 'PENDING_CALL',
    "home_manager_id" TEXT,
    "handyman_id" TEXT,
    "monthly_estimate" DECIMAL(10,2),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "onboarding_progress_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "activity_logs" (
    "id" TEXT NOT NULL,
    "household_id" TEXT NOT NULL,
    "actor_id" TEXT NOT NULL,
    "actor_type" "ActorType" NOT NULL,
    "actor_name" TEXT NOT NULL,
    "action" "ActivityAction" NOT NULL,
    "category" "ActivityCategory" NOT NULL,
    "title" TEXT NOT NULL,
    "description" TEXT,
    "bill_id" TEXT,
    "vendor_id" TEXT,
    "asset_id" TEXT,
    "zone_id" TEXT,
    "task_id" TEXT,
    "amount" DOUBLE PRECISION,
    "metadata" JSONB,
    "visible_to_homeowner" BOOLEAN NOT NULL DEFAULT true,
    "visible_to_handyman" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "activity_logs_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "approval_requests" (
    "id" TEXT NOT NULL,
    "household_id" TEXT NOT NULL,
    "requester_id" TEXT NOT NULL,
    "decider_id" TEXT,
    "type" "ApprovalType" NOT NULL,
    "priority" "ApprovalPriority" NOT NULL DEFAULT 'MEDIUM',
    "status" "ApprovalStatus" NOT NULL DEFAULT 'PENDING',
    "title" TEXT NOT NULL,
    "description" TEXT,
    "amount" DECIMAL(10,2),
    "vendor_name" TEXT,
    "work_order_id" TEXT,
    "service_request_id" TEXT,
    "project_id" TEXT,
    "expires_at" TIMESTAMP(3),
    "decided_at" TIMESTAMP(3),
    "decision_note" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "approval_requests_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "approval_comments" (
    "id" TEXT NOT NULL,
    "approval_id" TEXT NOT NULL,
    "author_id" TEXT NOT NULL,
    "content" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "approval_comments_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "documents" (
    "id" TEXT NOT NULL,
    "household_id" TEXT NOT NULL,
    "file_name" TEXT NOT NULL,
    "original_name" TEXT NOT NULL,
    "mime_type" TEXT NOT NULL,
    "file_size" INTEGER NOT NULL,
    "storage_url" TEXT NOT NULL,
    "storage_path" TEXT NOT NULL,
    "category" "DocumentCategory" NOT NULL,
    "subcategory" TEXT,
    "title" TEXT,
    "description" TEXT,
    "tags" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "expires_at" TIMESTAMP(3),
    "expiration_alert" BOOLEAN NOT NULL DEFAULT false,
    "vendor_id" TEXT,
    "appliance_id" TEXT,
    "uploaded_by_id" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "documents_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "plaid_connections" (
    "id" TEXT NOT NULL,
    "household_id" TEXT NOT NULL,
    "access_token" TEXT NOT NULL,
    "item_id" TEXT NOT NULL,
    "institution_id" TEXT,
    "institution_name" TEXT,
    "status" "PlaidConnectionStatus" NOT NULL DEFAULT 'ACTIVE',
    "last_synced_at" TIMESTAMP(3),
    "error_code" TEXT,
    "error_message" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "plaid_connections_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "plaid_accounts" (
    "id" TEXT NOT NULL,
    "connection_id" TEXT NOT NULL,
    "plaid_account_id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "official_name" TEXT,
    "type" TEXT NOT NULL,
    "subtype" TEXT,
    "mask" TEXT,
    "current_balance" DOUBLE PRECISION,
    "available_balance" DOUBLE PRECISION,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "plaid_accounts_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "detected_bills" (
    "id" TEXT NOT NULL,
    "household_id" TEXT NOT NULL,
    "account_id" TEXT,
    "merchant_name" TEXT NOT NULL,
    "normalized_name" TEXT NOT NULL,
    "category" "BillCategory" NOT NULL DEFAULT 'OTHER_BILL',
    "average_amount" DOUBLE PRECISION NOT NULL,
    "last_amount" DOUBLE PRECISION NOT NULL,
    "frequency" "BillingFrequency" NOT NULL DEFAULT 'MONTHLY',
    "last_transaction_date" TIMESTAMP(3),
    "next_expected_date" TIMESTAMP(3),
    "day_of_month" INTEGER,
    "status" "DetectedBillStatus" NOT NULL DEFAULT 'PENDING',
    "management_status" TEXT NOT NULL DEFAULT 'SELF_MANAGED',
    "notes" TEXT,
    "linked_bill_id" TEXT,
    "payment_method" TEXT,
    "payment_account_id" TEXT,
    "transaction_ids" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "transaction_count" INTEGER NOT NULL DEFAULT 0,
    "detection_type" TEXT NOT NULL DEFAULT 'RECURRING_CHARGE',
    "check_payee" TEXT,
    "check_number" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "detected_bills_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "household_cards" (
    "id" TEXT NOT NULL,
    "household_id" TEXT NOT NULL,
    "stripe_cardholder_id" TEXT,
    "stripe_card_id" TEXT,
    "last4" TEXT,
    "exp_month" INTEGER,
    "exp_year" INTEGER,
    "brand" TEXT NOT NULL DEFAULT 'visa',
    "status" TEXT NOT NULL DEFAULT 'pending',
    "plaid_account_id" TEXT,
    "funding_status" TEXT NOT NULL DEFAULT 'not_connected',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "household_cards_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "bills" (
    "id" TEXT NOT NULL,
    "household_id" TEXT NOT NULL,
    "vendor_id" TEXT,
    "name" TEXT NOT NULL,
    "description" TEXT,
    "category" TEXT NOT NULL,
    "amount" DOUBLE PRECISION,
    "is_variable_amount" BOOLEAN NOT NULL DEFAULT false,
    "average_amount" DOUBLE PRECISION,
    "last_known_amount" DOUBLE PRECISION,
    "frequency" TEXT NOT NULL,
    "due_day" INTEGER,
    "season_start" INTEGER,
    "season_end" INTEGER,
    "next_due_date" TIMESTAMP(3),
    "payment_method" TEXT NOT NULL,
    "payment_portal_url" TEXT,
    "payment_email" TEXT,
    "mailing_address" TEXT,
    "account_number" TEXT,
    "autopay_enabled" BOOLEAN NOT NULL DEFAULT true,
    "requires_approval" BOOLEAN NOT NULL DEFAULT false,
    "approval_threshold" DOUBLE PRECISION,
    "days_before_due" INTEGER NOT NULL DEFAULT 5,
    "priority" TEXT NOT NULL DEFAULT 'normal',
    "status" TEXT NOT NULL DEFAULT 'active',
    "source_type" TEXT NOT NULL DEFAULT 'manual',
    "detected_bill_id" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "bills_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "bill_payments" (
    "id" TEXT NOT NULL,
    "bill_id" TEXT NOT NULL,
    "household_id" TEXT NOT NULL,
    "amount" DOUBLE PRECISION NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'pending',
    "payment_method" TEXT NOT NULL,
    "stripe_payment_id" TEXT,
    "stripe_auth_id" TEXT,
    "checkbook_check_id" TEXT,
    "check_number" TEXT,
    "check_tracking_number" TEXT,
    "scheduled_date" TIMESTAMP(3) NOT NULL,
    "processed_date" TIMESTAMP(3),
    "confirmed_date" TIMESTAMP(3),
    "failure_reason" TEXT,
    "retry_count" INTEGER NOT NULL DEFAULT 0,
    "max_retries" INTEGER NOT NULL DEFAULT 3,
    "approval_id" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "bill_payments_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "payment_approvals" (
    "id" TEXT NOT NULL,
    "household_id" TEXT NOT NULL,
    "bill_id" TEXT NOT NULL,
    "amount" DOUBLE PRECISION NOT NULL,
    "reason" TEXT NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'pending',
    "requested_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "responded_at" TIMESTAMP(3),
    "expires_at" TIMESTAMP(3) NOT NULL,
    "responded_by" TEXT,
    "response_note" TEXT,
    "payment_id" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "payment_approvals_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "calendar_connections" (
    "id" TEXT NOT NULL,
    "household_id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "provider" TEXT NOT NULL,
    "account_email" TEXT,
    "access_token" TEXT,
    "refresh_token" TEXT,
    "token_expiry" TIMESTAMP(3),
    "device_calendar_ids" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "last_sync_at" TIMESTAMP(3),
    "sync_error" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "calendar_connections_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "calendar_events" (
    "id" TEXT NOT NULL,
    "connection_id" TEXT NOT NULL,
    "household_id" TEXT NOT NULL,
    "external_id" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "description" TEXT,
    "location" TEXT,
    "start_time" TIMESTAMP(3) NOT NULL,
    "end_time" TIMESTAMP(3) NOT NULL,
    "is_all_day" BOOLEAN NOT NULL DEFAULT false,
    "recurring_event_id" TEXT,
    "calendar_name" TEXT,
    "calendar_color" TEXT,
    "family_member_id" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "calendar_events_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "users_firebase_uid_key" ON "users"("firebase_uid");

-- CreateIndex
CREATE UNIQUE INDEX "users_email_key" ON "users"("email");

-- CreateIndex
CREATE UNIQUE INDEX "users_referral_code_key" ON "users"("referral_code");

-- CreateIndex
CREATE UNIQUE INDEX "refresh_tokens_token_key" ON "refresh_tokens"("token");

-- CreateIndex
CREATE INDEX "refresh_tokens_user_id_idx" ON "refresh_tokens"("user_id");

-- CreateIndex
CREATE INDEX "refresh_tokens_token_idx" ON "refresh_tokens"("token");

-- CreateIndex
CREATE UNIQUE INDEX "households_stripe_customer_id_key" ON "households"("stripe_customer_id");

-- CreateIndex
CREATE INDEX "households_manager_id_idx" ON "households"("manager_id");

-- CreateIndex
CREATE INDEX "households_assigned_handyman_id_idx" ON "households"("assigned_handyman_id");

-- CreateIndex
CREATE INDEX "households_h3_index_idx" ON "households"("h3_index");

-- CreateIndex
CREATE INDEX "household_members_user_id_idx" ON "household_members"("user_id");

-- CreateIndex
CREATE UNIQUE INDEX "household_members_household_id_user_id_key" ON "household_members"("household_id", "user_id");

-- CreateIndex
CREATE UNIQUE INDEX "household_invites_token_key" ON "household_invites"("token");

-- CreateIndex
CREATE INDEX "household_invites_email_idx" ON "household_invites"("email");

-- CreateIndex
CREATE INDEX "household_invites_token_idx" ON "household_invites"("token");

-- CreateIndex
CREATE UNIQUE INDEX "referrals_referral_code_key" ON "referrals"("referral_code");

-- CreateIndex
CREATE INDEX "referrals_referrer_id_idx" ON "referrals"("referrer_id");

-- CreateIndex
CREATE INDEX "referrals_referral_code_idx" ON "referrals"("referral_code");

-- CreateIndex
CREATE INDEX "referrals_referee_email_idx" ON "referrals"("referee_email");

-- CreateIndex
CREATE INDEX "vehicles_household_id_idx" ON "vehicles"("household_id");

-- CreateIndex
CREATE INDEX "vehicle_services_vehicle_id_idx" ON "vehicle_services"("vehicle_id");

-- CreateIndex
CREATE INDEX "vehicle_services_service_date_idx" ON "vehicle_services"("service_date");

-- CreateIndex
CREATE UNIQUE INDEX "home_profiles_household_id_key" ON "home_profiles"("household_id");

-- CreateIndex
CREATE UNIQUE INDEX "service_categories_name_key" ON "service_categories"("name");

-- CreateIndex
CREATE UNIQUE INDEX "vendors_user_id_key" ON "vendors"("user_id");

-- CreateIndex
CREATE INDEX "vendors_household_id_category_idx" ON "vendors"("household_id", "category");

-- CreateIndex
CREATE INDEX "vendors_user_id_idx" ON "vendors"("user_id");

-- CreateIndex
CREATE INDEX "household_vendors_household_id_is_favorite_idx" ON "household_vendors"("household_id", "is_favorite");

-- CreateIndex
CREATE INDEX "household_vendors_household_id_last_contact_date_idx" ON "household_vendors"("household_id", "last_contact_date");

-- CreateIndex
CREATE UNIQUE INDEX "household_vendors_household_id_vendor_id_key" ON "household_vendors"("household_id", "vendor_id");

-- CreateIndex
CREATE INDEX "vendor_activities_household_vendor_id_idx" ON "vendor_activities"("household_vendor_id");

-- CreateIndex
CREATE INDEX "vendor_activities_household_vendor_id_date_idx" ON "vendor_activities"("household_vendor_id", "date");

-- CreateIndex
CREATE INDEX "vendor_activities_household_vendor_id_type_idx" ON "vendor_activities"("household_vendor_id", "type");

-- CreateIndex
CREATE INDEX "vendor_messages_household_vendor_id_created_at_idx" ON "vendor_messages"("household_vendor_id", "created_at");

-- CreateIndex
CREATE INDEX "service_requests_household_id_status_idx" ON "service_requests"("household_id", "status");

-- CreateIndex
CREATE INDEX "service_requests_vendor_id_status_idx" ON "service_requests"("vendor_id", "status");

-- CreateIndex
CREATE INDEX "service_requests_household_id_requires_homeowner_input_idx" ON "service_requests"("household_id", "requires_homeowner_input");

-- CreateIndex
CREATE INDEX "tasks_household_id_status_idx" ON "tasks"("household_id", "status");

-- CreateIndex
CREATE INDEX "tasks_assignee_id_status_idx" ON "tasks"("assignee_id", "status");

-- CreateIndex
CREATE INDEX "maintenance_plans_household_id_is_active_idx" ON "maintenance_plans"("household_id", "is_active");

-- CreateIndex
CREATE INDEX "messages_channel_type_household_id_created_at_idx" ON "messages"("channel_type", "household_id", "created_at");

-- CreateIndex
CREATE INDEX "messages_channel_type_service_request_id_created_at_idx" ON "messages"("channel_type", "service_request_id", "created_at");

-- CreateIndex
CREATE INDEX "subscriptions_user_id_status_idx" ON "subscriptions"("user_id", "status");

-- CreateIndex
CREATE UNIQUE INDEX "invoices_invoice_number_key" ON "invoices"("invoice_number");

-- CreateIndex
CREATE INDEX "invoices_household_id_status_idx" ON "invoices"("household_id", "status");

-- CreateIndex
CREATE INDEX "files_household_id_category_idx" ON "files"("household_id", "category");

-- CreateIndex
CREATE INDEX "file_assets_household_id_type_idx" ON "file_assets"("household_id", "type");

-- CreateIndex
CREATE INDEX "file_assets_uploader_user_id_idx" ON "file_assets"("uploader_user_id");

-- CreateIndex
CREATE INDEX "file_assets_status_idx" ON "file_assets"("status");

-- CreateIndex
CREATE INDEX "payment_methods_household_id_idx" ON "payment_methods"("household_id");

-- CreateIndex
CREATE INDEX "bill_accounts_household_id_category_idx" ON "bill_accounts"("household_id", "category");

-- CreateIndex
CREATE INDEX "bill_accounts_household_id_next_due_date_idx" ON "bill_accounts"("household_id", "next_due_date");

-- CreateIndex
CREATE INDEX "bill_accounts_household_id_payment_responsibility_idx" ON "bill_accounts"("household_id", "payment_responsibility");

-- CreateIndex
CREATE UNIQUE INDEX "maintenance_templates_slug_key" ON "maintenance_templates"("slug");

-- CreateIndex
CREATE INDEX "maintenance_tasks_household_id_status_idx" ON "maintenance_tasks"("household_id", "status");

-- CreateIndex
CREATE INDEX "maintenance_tasks_household_id_due_date_idx" ON "maintenance_tasks"("household_id", "due_date");

-- CreateIndex
CREATE INDEX "maintenance_tasks_household_id_next_due_date_idx" ON "maintenance_tasks"("household_id", "next_due_date");

-- CreateIndex
CREATE INDEX "maintenance_tasks_household_id_category_idx" ON "maintenance_tasks"("household_id", "category");

-- CreateIndex
CREATE INDEX "maintenance_tasks_attachment_file_id_idx" ON "maintenance_tasks"("attachment_file_id");

-- CreateIndex
CREATE INDEX "maintenance_tasks_home_system_id_idx" ON "maintenance_tasks"("home_system_id");

-- CreateIndex
CREATE INDEX "reminders_status_scheduled_at_idx" ON "reminders"("status", "scheduled_at");

-- CreateIndex
CREATE INDEX "reminders_household_id_type_idx" ON "reminders"("household_id", "type");

-- CreateIndex
CREATE INDEX "reminders_bill_account_id_idx" ON "reminders"("bill_account_id");

-- CreateIndex
CREATE INDEX "reminders_maintenance_task_id_idx" ON "reminders"("maintenance_task_id");

-- CreateIndex
CREATE INDEX "reminders_work_order_id_idx" ON "reminders"("work_order_id");

-- CreateIndex
CREATE INDEX "in_app_notifications_user_id_is_read_created_at_idx" ON "in_app_notifications"("user_id", "is_read", "created_at");

-- CreateIndex
CREATE INDEX "in_app_notifications_household_id_idx" ON "in_app_notifications"("household_id");

-- CreateIndex
CREATE UNIQUE INDEX "vendor_payout_accounts_vendor_id_key" ON "vendor_payout_accounts"("vendor_id");

-- CreateIndex
CREATE UNIQUE INDEX "vendor_payout_accounts_stripe_account_id_key" ON "vendor_payout_accounts"("stripe_account_id");

-- CreateIndex
CREATE UNIQUE INDEX "household_invoices_invoice_number_key" ON "household_invoices"("invoice_number");

-- CreateIndex
CREATE INDEX "household_invoices_household_id_status_idx" ON "household_invoices"("household_id", "status");

-- CreateIndex
CREATE INDEX "household_invoices_billing_period_start_billing_period_end_idx" ON "household_invoices"("billing_period_start", "billing_period_end");

-- CreateIndex
CREATE INDEX "household_invoice_items_household_invoice_id_idx" ON "household_invoice_items"("household_invoice_id");

-- CreateIndex
CREATE INDEX "household_invoice_items_bill_account_id_idx" ON "household_invoice_items"("bill_account_id");

-- CreateIndex
CREATE INDEX "conversations_household_id_status_idx" ON "conversations"("household_id", "status");

-- CreateIndex
CREATE INDEX "conversations_status_updated_at_idx" ON "conversations"("status", "updated_at");

-- CreateIndex
CREATE INDEX "support_messages_conversation_id_created_at_idx" ON "support_messages"("conversation_id", "created_at");

-- CreateIndex
CREATE INDEX "support_messages_attachment_file_id_idx" ON "support_messages"("attachment_file_id");

-- CreateIndex
CREATE INDEX "home_manager_assignments_home_manager_user_id_idx" ON "home_manager_assignments"("home_manager_user_id");

-- CreateIndex
CREATE UNIQUE INDEX "home_manager_assignments_conversation_id_home_manager_user__key" ON "home_manager_assignments"("conversation_id", "home_manager_user_id");

-- CreateIndex
CREATE UNIQUE INDEX "work_orders_inbound_request_id_key" ON "work_orders"("inbound_request_id");

-- CreateIndex
CREATE INDEX "work_orders_household_id_status_idx" ON "work_orders"("household_id", "status");

-- CreateIndex
CREATE INDEX "work_orders_status_scheduled_start_idx" ON "work_orders"("status", "scheduled_start");

-- CreateIndex
CREATE INDEX "work_orders_vendor_id_status_idx" ON "work_orders"("vendor_id", "status");

-- CreateIndex
CREATE INDEX "work_orders_handyman_id_status_idx" ON "work_orders"("handyman_id", "status");

-- CreateIndex
CREATE INDEX "work_orders_status_service_area_idx" ON "work_orders"("status", "service_area");

-- CreateIndex
CREATE INDEX "work_orders_billing_type_status_idx" ON "work_orders"("billing_type", "status");

-- CreateIndex
CREATE INDEX "work_orders_service_category_id_idx" ON "work_orders"("service_category_id");

-- CreateIndex
CREATE INDEX "work_order_notes_work_order_id_created_at_idx" ON "work_order_notes"("work_order_id", "created_at");

-- CreateIndex
CREATE INDEX "work_order_notes_attachment_file_id_idx" ON "work_order_notes"("attachment_file_id");

-- CreateIndex
CREATE INDEX "client_bank_accounts_household_id_idx" ON "client_bank_accounts"("household_id");

-- CreateIndex
CREATE UNIQUE INDEX "transactions_inbound_request_id_key" ON "transactions"("inbound_request_id");

-- CreateIndex
CREATE INDEX "transactions_household_id_status_idx" ON "transactions"("household_id", "status");

-- CreateIndex
CREATE INDEX "transactions_household_id_created_at_idx" ON "transactions"("household_id", "created_at");

-- CreateIndex
CREATE INDEX "transactions_manager_id_idx" ON "transactions"("manager_id");

-- CreateIndex
CREATE INDEX "transactions_vendor_id_idx" ON "transactions"("vendor_id");

-- CreateIndex
CREATE INDEX "transactions_handyman_id_idx" ON "transactions"("handyman_id");

-- CreateIndex
CREATE INDEX "transactions_status_billed_at_idx" ON "transactions"("status", "billed_at");

-- CreateIndex
CREATE INDEX "transactions_receipt_file_id_idx" ON "transactions"("receipt_file_id");

-- CreateIndex
CREATE INDEX "transactions_work_order_id_idx" ON "transactions"("work_order_id");

-- CreateIndex
CREATE INDEX "transactions_maintenance_task_id_idx" ON "transactions"("maintenance_task_id");

-- CreateIndex
CREATE INDEX "transactions_household_invoice_id_idx" ON "transactions"("household_invoice_id");

-- CreateIndex
CREATE INDEX "transactions_is_inclusive_expense_household_id_idx" ON "transactions"("is_inclusive_expense", "household_id");

-- CreateIndex
CREATE INDEX "transactions_trip_id_idx" ON "transactions"("trip_id");

-- CreateIndex
CREATE INDEX "friendships_addressee_id_status_idx" ON "friendships"("addressee_id", "status");

-- CreateIndex
CREATE INDEX "friendships_requester_id_status_idx" ON "friendships"("requester_id", "status");

-- CreateIndex
CREATE UNIQUE INDEX "friendships_requester_id_addressee_id_key" ON "friendships"("requester_id", "addressee_id");

-- CreateIndex
CREATE INDEX "follows_following_id_idx" ON "follows"("following_id");

-- CreateIndex
CREATE INDEX "follows_follower_id_idx" ON "follows"("follower_id");

-- CreateIndex
CREATE UNIQUE INDEX "follows_follower_id_following_id_key" ON "follows"("follower_id", "following_id");

-- CreateIndex
CREATE INDEX "project_posts_author_id_idx" ON "project_posts"("author_id");

-- CreateIndex
CREATE INDEX "project_posts_household_id_idx" ON "project_posts"("household_id");

-- CreateIndex
CREATE INDEX "project_posts_vendor_id_idx" ON "project_posts"("vendor_id");

-- CreateIndex
CREATE INDEX "project_posts_visibility_created_at_idx" ON "project_posts"("visibility", "created_at");

-- CreateIndex
CREATE INDEX "project_posts_is_verified_idx" ON "project_posts"("is_verified");

-- CreateIndex
CREATE INDEX "project_likes_post_id_idx" ON "project_likes"("post_id");

-- CreateIndex
CREATE UNIQUE INDEX "project_likes_user_id_post_id_key" ON "project_likes"("user_id", "post_id");

-- CreateIndex
CREATE INDEX "saved_posts_post_id_idx" ON "saved_posts"("post_id");

-- CreateIndex
CREATE UNIQUE INDEX "saved_posts_user_id_post_id_key" ON "saved_posts"("user_id", "post_id");

-- CreateIndex
CREATE INDEX "post_comments_post_id_created_at_idx" ON "post_comments"("post_id", "created_at");

-- CreateIndex
CREATE INDEX "post_comments_author_id_idx" ON "post_comments"("author_id");

-- CreateIndex
CREATE INDEX "vendor_service_areas_h3_index_idx" ON "vendor_service_areas"("h3_index");

-- CreateIndex
CREATE INDEX "vendor_service_areas_vendor_id_idx" ON "vendor_service_areas"("vendor_id");

-- CreateIndex
CREATE UNIQUE INDEX "vendor_service_areas_vendor_id_h3_index_key" ON "vendor_service_areas"("vendor_id", "h3_index");

-- CreateIndex
CREATE UNIQUE INDEX "project_templates_slug_key" ON "project_templates"("slug");

-- CreateIndex
CREATE INDEX "project_templates_category_is_active_idx" ON "project_templates"("category", "is_active");

-- CreateIndex
CREATE INDEX "regional_cost_indexes_h3_index_idx" ON "regional_cost_indexes"("h3_index");

-- CreateIndex
CREATE INDEX "regional_cost_indexes_state_code_idx" ON "regional_cost_indexes"("state_code");

-- CreateIndex
CREATE UNIQUE INDEX "regional_cost_indexes_h3_index_effective_from_key" ON "regional_cost_indexes"("h3_index", "effective_from");

-- CreateIndex
CREATE UNIQUE INDEX "project_ideas_work_order_id_key" ON "project_ideas"("work_order_id");

-- CreateIndex
CREATE UNIQUE INDEX "project_ideas_project_post_id_key" ON "project_ideas"("project_post_id");

-- CreateIndex
CREATE UNIQUE INDEX "project_ideas_inbound_request_id_key" ON "project_ideas"("inbound_request_id");

-- CreateIndex
CREATE INDEX "project_ideas_household_id_status_idx" ON "project_ideas"("household_id", "status");

-- CreateIndex
CREATE INDEX "project_ideas_status_created_at_idx" ON "project_ideas"("status", "created_at");

-- CreateIndex
CREATE INDEX "project_ideas_category_status_idx" ON "project_ideas"("category", "status");

-- CreateIndex
CREATE UNIQUE INDEX "recommendation_requests_project_idea_id_key" ON "recommendation_requests"("project_idea_id");

-- CreateIndex
CREATE INDEX "recommendation_requests_h3_index_status_idx" ON "recommendation_requests"("h3_index", "status");

-- CreateIndex
CREATE INDEX "recommendation_requests_status_created_at_idx" ON "recommendation_requests"("status", "created_at");

-- CreateIndex
CREATE INDEX "vendor_suggestions_project_idea_id_idx" ON "vendor_suggestions"("project_idea_id");

-- CreateIndex
CREATE INDEX "vendor_suggestions_recommendation_request_id_idx" ON "vendor_suggestions"("recommendation_request_id");

-- CreateIndex
CREATE INDEX "vendor_suggestions_vendor_id_idx" ON "vendor_suggestions"("vendor_id");

-- CreateIndex
CREATE INDEX "inbound_requests_household_id_status_idx" ON "inbound_requests"("household_id", "status");

-- CreateIndex
CREATE INDEX "inbound_requests_household_id_channel_idx" ON "inbound_requests"("household_id", "channel");

-- CreateIndex
CREATE INDEX "inbound_requests_status_created_at_idx" ON "inbound_requests"("status", "created_at");

-- CreateIndex
CREATE INDEX "inbound_requests_category_status_idx" ON "inbound_requests"("category", "status");

-- CreateIndex
CREATE INDEX "inbound_attachments_inbound_request_id_idx" ON "inbound_attachments"("inbound_request_id");

-- CreateIndex
CREATE INDEX "triage_suggestions_inbound_request_id_idx" ON "triage_suggestions"("inbound_request_id");

-- CreateIndex
CREATE INDEX "concierge_threads_household_id_idx" ON "concierge_threads"("household_id");

-- CreateIndex
CREATE INDEX "concierge_threads_user_id_idx" ON "concierge_threads"("user_id");

-- CreateIndex
CREATE UNIQUE INDEX "concierge_threads_household_id_user_id_key" ON "concierge_threads"("household_id", "user_id");

-- CreateIndex
CREATE INDEX "concierge_messages_thread_id_created_at_idx" ON "concierge_messages"("thread_id", "created_at");

-- CreateIndex
CREATE UNIQUE INDEX "family_events_inbound_request_id_key" ON "family_events"("inbound_request_id");

-- CreateIndex
CREATE INDEX "family_events_household_id_start_date_idx" ON "family_events"("household_id", "start_date");

-- CreateIndex
CREATE INDEX "family_events_category_idx" ON "family_events"("category");

-- CreateIndex
CREATE INDEX "family_events_assigned_to_member_id_idx" ON "family_events"("assigned_to_member_id");

-- CreateIndex
CREATE UNIQUE INDEX "travel_profiles_household_member_id_key" ON "travel_profiles"("household_member_id");

-- CreateIndex
CREATE INDEX "travel_profiles_household_member_id_idx" ON "travel_profiles"("household_member_id");

-- CreateIndex
CREATE UNIQUE INDEX "trips_inbound_request_id_key" ON "trips"("inbound_request_id");

-- CreateIndex
CREATE INDEX "trips_household_id_status_idx" ON "trips"("household_id", "status");

-- CreateIndex
CREATE INDEX "trips_status_start_date_idx" ON "trips"("status", "start_date");

-- CreateIndex
CREATE INDEX "trips_assigned_manager_id_idx" ON "trips"("assigned_manager_id");

-- CreateIndex
CREATE INDEX "trip_proposals_trip_id_idx" ON "trip_proposals"("trip_id");

-- CreateIndex
CREATE INDEX "trip_proposals_created_by_manager_id_idx" ON "trip_proposals"("created_by_manager_id");

-- CreateIndex
CREATE INDEX "itinerary_items_trip_id_start_date_time_idx" ON "itinerary_items"("trip_id", "start_date_time");

-- CreateIndex
CREATE INDEX "itinerary_items_transaction_id_idx" ON "itinerary_items"("transaction_id");

-- CreateIndex
CREATE UNIQUE INDEX "house_protocols_trip_id_key" ON "house_protocols"("trip_id");

-- CreateIndex
CREATE INDEX "house_protocols_household_id_status_idx" ON "house_protocols"("household_id", "status");

-- CreateIndex
CREATE INDEX "house_protocols_assigned_to_user_id_idx" ON "house_protocols"("assigned_to_user_id");

-- CreateIndex
CREATE INDEX "house_protocols_scheduled_date_idx" ON "house_protocols"("scheduled_date");

-- CreateIndex
CREATE INDEX "house_protocol_items_protocol_id_idx" ON "house_protocol_items"("protocol_id");

-- CreateIndex
CREATE INDEX "pets_household_id_idx" ON "pets"("household_id");

-- CreateIndex
CREATE INDEX "pet_vet_records_pet_id_visit_date_idx" ON "pet_vet_records"("pet_id", "visit_date");

-- CreateIndex
CREATE INDEX "home_systems_household_id_type_idx" ON "home_systems"("household_id", "type");

-- CreateIndex
CREATE INDEX "home_systems_next_maintenance_date_idx" ON "home_systems"("next_maintenance_date");

-- CreateIndex
CREATE INDEX "home_system_services_home_system_id_service_date_idx" ON "home_system_services"("home_system_id", "service_date");

-- CreateIndex
CREATE UNIQUE INDEX "home_checklists_household_id_key" ON "home_checklists"("household_id");

-- CreateIndex
CREATE UNIQUE INDEX "household_intakes_household_id_key" ON "household_intakes"("household_id");

-- CreateIndex
CREATE INDEX "family_members_household_id_type_idx" ON "family_members"("household_id", "type");

-- CreateIndex
CREATE INDEX "memberships_household_id_idx" ON "memberships"("household_id");

-- CreateIndex
CREATE INDEX "family_activities_household_id_idx" ON "family_activities"("household_id");

-- CreateIndex
CREATE INDEX "family_activities_family_member_id_idx" ON "family_activities"("family_member_id");

-- CreateIndex
CREATE INDEX "comprehensive_bills_household_id_category_idx" ON "comprehensive_bills"("household_id", "category");

-- CreateIndex
CREATE INDEX "comprehensive_bills_household_id_status_idx" ON "comprehensive_bills"("household_id", "status");

-- CreateIndex
CREATE INDEX "comprehensive_bills_vendor_id_idx" ON "comprehensive_bills"("vendor_id");

-- CreateIndex
CREATE INDEX "bill_payment_records_comprehensive_bill_id_paid_date_idx" ON "bill_payment_records"("comprehensive_bill_id", "paid_date");

-- CreateIndex
CREATE INDEX "kid_activities_household_id_idx" ON "kid_activities"("household_id");

-- CreateIndex
CREATE INDEX "kid_activities_family_member_id_idx" ON "kid_activities"("family_member_id");

-- CreateIndex
CREATE INDEX "zones_household_id_type_idx" ON "zones"("household_id", "type");

-- CreateIndex
CREATE INDEX "property_assets_household_id_category_idx" ON "property_assets"("household_id", "category");

-- CreateIndex
CREATE INDEX "property_assets_zone_id_idx" ON "property_assets"("zone_id");

-- CreateIndex
CREATE INDEX "service_logs_household_id_service_date_idx" ON "service_logs"("household_id", "service_date");

-- CreateIndex
CREATE INDEX "service_logs_asset_id_idx" ON "service_logs"("asset_id");

-- CreateIndex
CREATE INDEX "service_logs_vendor_id_idx" ON "service_logs"("vendor_id");

-- CreateIndex
CREATE INDEX "property_documents_household_id_type_idx" ON "property_documents"("household_id", "type");

-- CreateIndex
CREATE INDEX "property_documents_vendor_id_idx" ON "property_documents"("vendor_id");

-- CreateIndex
CREATE INDEX "property_documents_asset_id_idx" ON "property_documents"("asset_id");

-- CreateIndex
CREATE UNIQUE INDEX "onboarding_progress_household_id_key" ON "onboarding_progress"("household_id");

-- CreateIndex
CREATE INDEX "activity_logs_household_id_created_at_idx" ON "activity_logs"("household_id", "created_at");

-- CreateIndex
CREATE INDEX "activity_logs_household_id_category_idx" ON "activity_logs"("household_id", "category");

-- CreateIndex
CREATE INDEX "activity_logs_household_id_visible_to_homeowner_idx" ON "activity_logs"("household_id", "visible_to_homeowner");

-- CreateIndex
CREATE INDEX "approval_requests_household_id_status_idx" ON "approval_requests"("household_id", "status");

-- CreateIndex
CREATE INDEX "approval_requests_household_id_created_at_idx" ON "approval_requests"("household_id", "created_at");

-- CreateIndex
CREATE INDEX "approval_requests_requester_id_idx" ON "approval_requests"("requester_id");

-- CreateIndex
CREATE INDEX "approval_requests_decider_id_idx" ON "approval_requests"("decider_id");

-- CreateIndex
CREATE INDEX "approval_comments_approval_id_created_at_idx" ON "approval_comments"("approval_id", "created_at");

-- CreateIndex
CREATE INDEX "documents_household_id_idx" ON "documents"("household_id");

-- CreateIndex
CREATE INDEX "documents_category_idx" ON "documents"("category");

-- CreateIndex
CREATE INDEX "documents_expires_at_idx" ON "documents"("expires_at");

-- CreateIndex
CREATE INDEX "plaid_connections_household_id_idx" ON "plaid_connections"("household_id");

-- CreateIndex
CREATE UNIQUE INDEX "plaid_connections_household_id_item_id_key" ON "plaid_connections"("household_id", "item_id");

-- CreateIndex
CREATE UNIQUE INDEX "plaid_accounts_connection_id_plaid_account_id_key" ON "plaid_accounts"("connection_id", "plaid_account_id");

-- CreateIndex
CREATE INDEX "detected_bills_household_id_idx" ON "detected_bills"("household_id");

-- CreateIndex
CREATE INDEX "detected_bills_status_idx" ON "detected_bills"("status");

-- CreateIndex
CREATE INDEX "detected_bills_management_status_idx" ON "detected_bills"("management_status");

-- CreateIndex
CREATE UNIQUE INDEX "household_cards_household_id_key" ON "household_cards"("household_id");

-- CreateIndex
CREATE UNIQUE INDEX "household_cards_stripe_card_id_key" ON "household_cards"("stripe_card_id");

-- CreateIndex
CREATE INDEX "bills_household_id_status_idx" ON "bills"("household_id", "status");

-- CreateIndex
CREATE INDEX "bills_next_due_date_idx" ON "bills"("next_due_date");

-- CreateIndex
CREATE INDEX "bill_payments_household_id_status_idx" ON "bill_payments"("household_id", "status");

-- CreateIndex
CREATE INDEX "bill_payments_scheduled_date_idx" ON "bill_payments"("scheduled_date");

-- CreateIndex
CREATE INDEX "payment_approvals_household_id_status_idx" ON "payment_approvals"("household_id", "status");

-- CreateIndex
CREATE INDEX "payment_approvals_expires_at_idx" ON "payment_approvals"("expires_at");

-- CreateIndex
CREATE INDEX "calendar_connections_household_id_idx" ON "calendar_connections"("household_id");

-- CreateIndex
CREATE INDEX "calendar_connections_user_id_idx" ON "calendar_connections"("user_id");

-- CreateIndex
CREATE UNIQUE INDEX "calendar_connections_household_id_provider_account_email_key" ON "calendar_connections"("household_id", "provider", "account_email");

-- CreateIndex
CREATE INDEX "calendar_events_household_id_start_time_idx" ON "calendar_events"("household_id", "start_time");

-- CreateIndex
CREATE INDEX "calendar_events_family_member_id_idx" ON "calendar_events"("family_member_id");

-- CreateIndex
CREATE UNIQUE INDEX "calendar_events_connection_id_external_id_key" ON "calendar_events"("connection_id", "external_id");

-- AddForeignKey
ALTER TABLE "refresh_tokens" ADD CONSTRAINT "refresh_tokens_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "households" ADD CONSTRAINT "households_owner_id_fkey" FOREIGN KEY ("owner_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "households" ADD CONSTRAINT "households_manager_id_fkey" FOREIGN KEY ("manager_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "households" ADD CONSTRAINT "households_assigned_handyman_id_fkey" FOREIGN KEY ("assigned_handyman_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "household_members" ADD CONSTRAINT "household_members_household_id_fkey" FOREIGN KEY ("household_id") REFERENCES "households"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "household_members" ADD CONSTRAINT "household_members_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "household_members" ADD CONSTRAINT "household_members_invited_by_user_id_fkey" FOREIGN KEY ("invited_by_user_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "household_invites" ADD CONSTRAINT "household_invites_household_id_fkey" FOREIGN KEY ("household_id") REFERENCES "households"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "household_invites" ADD CONSTRAINT "household_invites_invited_by_id_fkey" FOREIGN KEY ("invited_by_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "referrals" ADD CONSTRAINT "referrals_referrer_id_fkey" FOREIGN KEY ("referrer_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "referrals" ADD CONSTRAINT "referrals_referee_id_fkey" FOREIGN KEY ("referee_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "vehicles" ADD CONSTRAINT "vehicles_household_id_fkey" FOREIGN KEY ("household_id") REFERENCES "households"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "vehicles" ADD CONSTRAINT "vehicles_primary_driver_id_fkey" FOREIGN KEY ("primary_driver_id") REFERENCES "household_members"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "vehicle_services" ADD CONSTRAINT "vehicle_services_vehicle_id_fkey" FOREIGN KEY ("vehicle_id") REFERENCES "vehicles"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "home_profiles" ADD CONSTRAINT "home_profiles_household_id_fkey" FOREIGN KEY ("household_id") REFERENCES "households"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "vendors" ADD CONSTRAINT "vendors_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "vendors" ADD CONSTRAINT "vendors_household_id_fkey" FOREIGN KEY ("household_id") REFERENCES "households"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "vendors" ADD CONSTRAINT "vendors_service_category_id_fkey" FOREIGN KEY ("service_category_id") REFERENCES "service_categories"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "household_vendors" ADD CONSTRAINT "household_vendors_household_id_fkey" FOREIGN KEY ("household_id") REFERENCES "households"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "household_vendors" ADD CONSTRAINT "household_vendors_vendor_id_fkey" FOREIGN KEY ("vendor_id") REFERENCES "vendors"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "vendor_activities" ADD CONSTRAINT "vendor_activities_household_vendor_id_fkey" FOREIGN KEY ("household_vendor_id") REFERENCES "household_vendors"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "vendor_messages" ADD CONSTRAINT "vendor_messages_household_vendor_id_fkey" FOREIGN KEY ("household_vendor_id") REFERENCES "household_vendors"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "service_requests" ADD CONSTRAINT "service_requests_household_id_fkey" FOREIGN KEY ("household_id") REFERENCES "households"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "service_requests" ADD CONSTRAINT "service_requests_service_category_id_fkey" FOREIGN KEY ("service_category_id") REFERENCES "service_categories"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "service_requests" ADD CONSTRAINT "service_requests_vendor_id_fkey" FOREIGN KEY ("vendor_id") REFERENCES "vendors"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "service_requests" ADD CONSTRAINT "service_requests_created_by_id_fkey" FOREIGN KEY ("created_by_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tasks" ADD CONSTRAINT "tasks_household_id_fkey" FOREIGN KEY ("household_id") REFERENCES "households"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tasks" ADD CONSTRAINT "tasks_created_by_id_fkey" FOREIGN KEY ("created_by_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tasks" ADD CONSTRAINT "tasks_assignee_id_fkey" FOREIGN KEY ("assignee_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "maintenance_plans" ADD CONSTRAINT "maintenance_plans_household_id_fkey" FOREIGN KEY ("household_id") REFERENCES "households"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "maintenance_plans" ADD CONSTRAINT "maintenance_plans_service_category_id_fkey" FOREIGN KEY ("service_category_id") REFERENCES "service_categories"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "messages" ADD CONSTRAINT "messages_household_id_fkey" FOREIGN KEY ("household_id") REFERENCES "households"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "messages" ADD CONSTRAINT "messages_service_request_id_fkey" FOREIGN KEY ("service_request_id") REFERENCES "service_requests"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "messages" ADD CONSTRAINT "messages_sender_id_fkey" FOREIGN KEY ("sender_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "messages" ADD CONSTRAINT "messages_vendor_id_fkey" FOREIGN KEY ("vendor_id") REFERENCES "vendors"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "subscriptions" ADD CONSTRAINT "subscriptions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "invoices" ADD CONSTRAINT "invoices_household_id_fkey" FOREIGN KEY ("household_id") REFERENCES "households"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "files" ADD CONSTRAINT "files_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "files" ADD CONSTRAINT "files_household_id_fkey" FOREIGN KEY ("household_id") REFERENCES "households"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "files" ADD CONSTRAINT "files_service_request_id_fkey" FOREIGN KEY ("service_request_id") REFERENCES "service_requests"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "files" ADD CONSTRAINT "files_task_id_fkey" FOREIGN KEY ("task_id") REFERENCES "tasks"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "files" ADD CONSTRAINT "files_invoice_id_fkey" FOREIGN KEY ("invoice_id") REFERENCES "invoices"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "file_assets" ADD CONSTRAINT "file_assets_household_id_fkey" FOREIGN KEY ("household_id") REFERENCES "households"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "file_assets" ADD CONSTRAINT "file_assets_uploader_user_id_fkey" FOREIGN KEY ("uploader_user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

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

-- AddForeignKey
ALTER TABLE "maintenance_tasks" ADD CONSTRAINT "maintenance_tasks_attachment_file_id_fkey" FOREIGN KEY ("attachment_file_id") REFERENCES "file_assets"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "maintenance_tasks" ADD CONSTRAINT "maintenance_tasks_completed_by_id_fkey" FOREIGN KEY ("completed_by_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "maintenance_tasks" ADD CONSTRAINT "maintenance_tasks_home_system_id_fkey" FOREIGN KEY ("home_system_id") REFERENCES "home_systems"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "reminders" ADD CONSTRAINT "reminders_household_id_fkey" FOREIGN KEY ("household_id") REFERENCES "households"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "in_app_notifications" ADD CONSTRAINT "in_app_notifications_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "vendor_payout_accounts" ADD CONSTRAINT "vendor_payout_accounts_vendor_id_fkey" FOREIGN KEY ("vendor_id") REFERENCES "vendors"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "household_invoices" ADD CONSTRAINT "household_invoices_household_id_fkey" FOREIGN KEY ("household_id") REFERENCES "households"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "household_invoice_items" ADD CONSTRAINT "household_invoice_items_household_invoice_id_fkey" FOREIGN KEY ("household_invoice_id") REFERENCES "household_invoices"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "household_invoice_items" ADD CONSTRAINT "household_invoice_items_bill_account_id_fkey" FOREIGN KEY ("bill_account_id") REFERENCES "bill_accounts"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "conversations" ADD CONSTRAINT "conversations_household_id_fkey" FOREIGN KEY ("household_id") REFERENCES "households"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "conversations" ADD CONSTRAINT "conversations_created_by_user_id_fkey" FOREIGN KEY ("created_by_user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "support_messages" ADD CONSTRAINT "support_messages_conversation_id_fkey" FOREIGN KEY ("conversation_id") REFERENCES "conversations"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "support_messages" ADD CONSTRAINT "support_messages_sender_user_id_fkey" FOREIGN KEY ("sender_user_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "support_messages" ADD CONSTRAINT "support_messages_attachment_file_id_fkey" FOREIGN KEY ("attachment_file_id") REFERENCES "file_assets"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "home_manager_assignments" ADD CONSTRAINT "home_manager_assignments_conversation_id_fkey" FOREIGN KEY ("conversation_id") REFERENCES "conversations"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "home_manager_assignments" ADD CONSTRAINT "home_manager_assignments_home_manager_user_id_fkey" FOREIGN KEY ("home_manager_user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "home_manager_assignments" ADD CONSTRAINT "home_manager_assignments_assigned_by_user_id_fkey" FOREIGN KEY ("assigned_by_user_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "work_orders" ADD CONSTRAINT "work_orders_household_id_fkey" FOREIGN KEY ("household_id") REFERENCES "households"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "work_orders" ADD CONSTRAINT "work_orders_maintenance_task_id_fkey" FOREIGN KEY ("maintenance_task_id") REFERENCES "maintenance_tasks"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "work_orders" ADD CONSTRAINT "work_orders_vendor_id_fkey" FOREIGN KEY ("vendor_id") REFERENCES "vendors"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "work_orders" ADD CONSTRAINT "work_orders_handyman_id_fkey" FOREIGN KEY ("handyman_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "work_orders" ADD CONSTRAINT "work_orders_service_category_id_fkey" FOREIGN KEY ("service_category_id") REFERENCES "service_categories"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "work_orders" ADD CONSTRAINT "work_orders_created_by_user_id_fkey" FOREIGN KEY ("created_by_user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "work_orders" ADD CONSTRAINT "work_orders_verified_by_user_id_fkey" FOREIGN KEY ("verified_by_user_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "work_order_notes" ADD CONSTRAINT "work_order_notes_work_order_id_fkey" FOREIGN KEY ("work_order_id") REFERENCES "work_orders"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "work_order_notes" ADD CONSTRAINT "work_order_notes_author_user_id_fkey" FOREIGN KEY ("author_user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "work_order_notes" ADD CONSTRAINT "work_order_notes_attachment_file_id_fkey" FOREIGN KEY ("attachment_file_id") REFERENCES "file_assets"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "client_bank_accounts" ADD CONSTRAINT "client_bank_accounts_household_id_fkey" FOREIGN KEY ("household_id") REFERENCES "households"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "transactions" ADD CONSTRAINT "transactions_household_id_fkey" FOREIGN KEY ("household_id") REFERENCES "households"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "transactions" ADD CONSTRAINT "transactions_vendor_id_fkey" FOREIGN KEY ("vendor_id") REFERENCES "vendors"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "transactions" ADD CONSTRAINT "transactions_handyman_id_fkey" FOREIGN KEY ("handyman_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "transactions" ADD CONSTRAINT "transactions_manager_id_fkey" FOREIGN KEY ("manager_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "transactions" ADD CONSTRAINT "transactions_receipt_file_id_fkey" FOREIGN KEY ("receipt_file_id") REFERENCES "file_assets"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "transactions" ADD CONSTRAINT "transactions_work_order_id_fkey" FOREIGN KEY ("work_order_id") REFERENCES "work_orders"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "transactions" ADD CONSTRAINT "transactions_maintenance_task_id_fkey" FOREIGN KEY ("maintenance_task_id") REFERENCES "maintenance_tasks"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "transactions" ADD CONSTRAINT "transactions_household_invoice_id_fkey" FOREIGN KEY ("household_invoice_id") REFERENCES "household_invoices"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "transactions" ADD CONSTRAINT "transactions_trip_id_fkey" FOREIGN KEY ("trip_id") REFERENCES "trips"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "friendships" ADD CONSTRAINT "friendships_requester_id_fkey" FOREIGN KEY ("requester_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "friendships" ADD CONSTRAINT "friendships_addressee_id_fkey" FOREIGN KEY ("addressee_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "follows" ADD CONSTRAINT "follows_follower_id_fkey" FOREIGN KEY ("follower_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "follows" ADD CONSTRAINT "follows_following_id_fkey" FOREIGN KEY ("following_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "project_posts" ADD CONSTRAINT "project_posts_author_id_fkey" FOREIGN KEY ("author_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "project_posts" ADD CONSTRAINT "project_posts_household_id_fkey" FOREIGN KEY ("household_id") REFERENCES "households"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "project_posts" ADD CONSTRAINT "project_posts_work_order_id_fkey" FOREIGN KEY ("work_order_id") REFERENCES "work_orders"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "project_posts" ADD CONSTRAINT "project_posts_vendor_id_fkey" FOREIGN KEY ("vendor_id") REFERENCES "vendors"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "project_likes" ADD CONSTRAINT "project_likes_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "project_likes" ADD CONSTRAINT "project_likes_post_id_fkey" FOREIGN KEY ("post_id") REFERENCES "project_posts"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "saved_posts" ADD CONSTRAINT "saved_posts_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "saved_posts" ADD CONSTRAINT "saved_posts_post_id_fkey" FOREIGN KEY ("post_id") REFERENCES "project_posts"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "post_comments" ADD CONSTRAINT "post_comments_post_id_fkey" FOREIGN KEY ("post_id") REFERENCES "project_posts"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "post_comments" ADD CONSTRAINT "post_comments_author_id_fkey" FOREIGN KEY ("author_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "vendor_service_areas" ADD CONSTRAINT "vendor_service_areas_vendor_id_fkey" FOREIGN KEY ("vendor_id") REFERENCES "vendors"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "project_ideas" ADD CONSTRAINT "project_ideas_household_id_fkey" FOREIGN KEY ("household_id") REFERENCES "households"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "project_ideas" ADD CONSTRAINT "project_ideas_created_by_user_id_fkey" FOREIGN KEY ("created_by_user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "project_ideas" ADD CONSTRAINT "project_ideas_template_id_fkey" FOREIGN KEY ("template_id") REFERENCES "project_templates"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "project_ideas" ADD CONSTRAINT "project_ideas_work_order_id_fkey" FOREIGN KEY ("work_order_id") REFERENCES "work_orders"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "project_ideas" ADD CONSTRAINT "project_ideas_project_post_id_fkey" FOREIGN KEY ("project_post_id") REFERENCES "project_posts"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "recommendation_requests" ADD CONSTRAINT "recommendation_requests_project_idea_id_fkey" FOREIGN KEY ("project_idea_id") REFERENCES "project_ideas"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "recommendation_requests" ADD CONSTRAINT "recommendation_requests_household_id_fkey" FOREIGN KEY ("household_id") REFERENCES "households"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "recommendation_requests" ADD CONSTRAINT "recommendation_requests_created_by_user_id_fkey" FOREIGN KEY ("created_by_user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "vendor_suggestions" ADD CONSTRAINT "vendor_suggestions_project_idea_id_fkey" FOREIGN KEY ("project_idea_id") REFERENCES "project_ideas"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "vendor_suggestions" ADD CONSTRAINT "vendor_suggestions_recommendation_request_id_fkey" FOREIGN KEY ("recommendation_request_id") REFERENCES "recommendation_requests"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "vendor_suggestions" ADD CONSTRAINT "vendor_suggestions_vendor_id_fkey" FOREIGN KEY ("vendor_id") REFERENCES "vendors"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "vendor_suggestions" ADD CONSTRAINT "vendor_suggestions_suggested_by_user_id_fkey" FOREIGN KEY ("suggested_by_user_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "vendor_suggestions" ADD CONSTRAINT "vendor_suggestions_reference_project_post_id_fkey" FOREIGN KEY ("reference_project_post_id") REFERENCES "project_posts"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "inbound_requests" ADD CONSTRAINT "inbound_requests_household_id_fkey" FOREIGN KEY ("household_id") REFERENCES "households"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "inbound_requests" ADD CONSTRAINT "inbound_requests_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "inbound_requests" ADD CONSTRAINT "inbound_requests_resolved_by_user_id_fkey" FOREIGN KEY ("resolved_by_user_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "inbound_requests" ADD CONSTRAINT "inbound_requests_concierge_thread_id_fkey" FOREIGN KEY ("concierge_thread_id") REFERENCES "concierge_threads"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "inbound_attachments" ADD CONSTRAINT "inbound_attachments_inbound_request_id_fkey" FOREIGN KEY ("inbound_request_id") REFERENCES "inbound_requests"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "triage_suggestions" ADD CONSTRAINT "triage_suggestions_inbound_request_id_fkey" FOREIGN KEY ("inbound_request_id") REFERENCES "inbound_requests"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "concierge_threads" ADD CONSTRAINT "concierge_threads_household_id_fkey" FOREIGN KEY ("household_id") REFERENCES "households"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "concierge_threads" ADD CONSTRAINT "concierge_threads_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "concierge_messages" ADD CONSTRAINT "concierge_messages_thread_id_fkey" FOREIGN KEY ("thread_id") REFERENCES "concierge_threads"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "family_events" ADD CONSTRAINT "family_events_household_id_fkey" FOREIGN KEY ("household_id") REFERENCES "households"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "family_events" ADD CONSTRAINT "family_events_created_by_user_id_fkey" FOREIGN KEY ("created_by_user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "family_events" ADD CONSTRAINT "family_events_assigned_to_member_id_fkey" FOREIGN KEY ("assigned_to_member_id") REFERENCES "household_members"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "family_events" ADD CONSTRAINT "family_events_vehicle_id_fkey" FOREIGN KEY ("vehicle_id") REFERENCES "vehicles"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "family_events" ADD CONSTRAINT "family_events_pet_id_fkey" FOREIGN KEY ("pet_id") REFERENCES "pets"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "travel_profiles" ADD CONSTRAINT "travel_profiles_household_member_id_fkey" FOREIGN KEY ("household_member_id") REFERENCES "household_members"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "trips" ADD CONSTRAINT "trips_household_id_fkey" FOREIGN KEY ("household_id") REFERENCES "households"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "trips" ADD CONSTRAINT "trips_created_by_user_id_fkey" FOREIGN KEY ("created_by_user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "trips" ADD CONSTRAINT "trips_assigned_manager_id_fkey" FOREIGN KEY ("assigned_manager_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "trip_proposals" ADD CONSTRAINT "trip_proposals_trip_id_fkey" FOREIGN KEY ("trip_id") REFERENCES "trips"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "trip_proposals" ADD CONSTRAINT "trip_proposals_created_by_manager_id_fkey" FOREIGN KEY ("created_by_manager_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "itinerary_items" ADD CONSTRAINT "itinerary_items_trip_id_fkey" FOREIGN KEY ("trip_id") REFERENCES "trips"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "itinerary_items" ADD CONSTRAINT "itinerary_items_transaction_id_fkey" FOREIGN KEY ("transaction_id") REFERENCES "transactions"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "house_protocols" ADD CONSTRAINT "house_protocols_trip_id_fkey" FOREIGN KEY ("trip_id") REFERENCES "trips"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "house_protocols" ADD CONSTRAINT "house_protocols_household_id_fkey" FOREIGN KEY ("household_id") REFERENCES "households"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "house_protocols" ADD CONSTRAINT "house_protocols_assigned_to_user_id_fkey" FOREIGN KEY ("assigned_to_user_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "house_protocol_items" ADD CONSTRAINT "house_protocol_items_protocol_id_fkey" FOREIGN KEY ("protocol_id") REFERENCES "house_protocols"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "house_protocol_items" ADD CONSTRAINT "house_protocol_items_completed_by_user_id_fkey" FOREIGN KEY ("completed_by_user_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "pets" ADD CONSTRAINT "pets_household_id_fkey" FOREIGN KEY ("household_id") REFERENCES "households"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "pet_vet_records" ADD CONSTRAINT "pet_vet_records_pet_id_fkey" FOREIGN KEY ("pet_id") REFERENCES "pets"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "home_systems" ADD CONSTRAINT "home_systems_household_id_fkey" FOREIGN KEY ("household_id") REFERENCES "households"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "home_systems" ADD CONSTRAINT "home_systems_service_vendor_id_fkey" FOREIGN KEY ("service_vendor_id") REFERENCES "vendors"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "home_system_services" ADD CONSTRAINT "home_system_services_home_system_id_fkey" FOREIGN KEY ("home_system_id") REFERENCES "home_systems"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "home_system_services" ADD CONSTRAINT "home_system_services_vendor_id_fkey" FOREIGN KEY ("vendor_id") REFERENCES "vendors"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "home_checklists" ADD CONSTRAINT "home_checklists_household_id_fkey" FOREIGN KEY ("household_id") REFERENCES "households"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "home_checklists" ADD CONSTRAINT "home_checklists_completed_by_user_id_fkey" FOREIGN KEY ("completed_by_user_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "household_intakes" ADD CONSTRAINT "household_intakes_household_id_fkey" FOREIGN KEY ("household_id") REFERENCES "households"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "household_intakes" ADD CONSTRAINT "household_intakes_manager_id_fkey" FOREIGN KEY ("manager_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "family_members" ADD CONSTRAINT "family_members_household_id_fkey" FOREIGN KEY ("household_id") REFERENCES "households"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "memberships" ADD CONSTRAINT "memberships_household_id_fkey" FOREIGN KEY ("household_id") REFERENCES "households"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "family_activities" ADD CONSTRAINT "family_activities_household_id_fkey" FOREIGN KEY ("household_id") REFERENCES "households"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "family_activities" ADD CONSTRAINT "family_activities_family_member_id_fkey" FOREIGN KEY ("family_member_id") REFERENCES "family_members"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "comprehensive_bills" ADD CONSTRAINT "comprehensive_bills_household_id_fkey" FOREIGN KEY ("household_id") REFERENCES "households"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "comprehensive_bills" ADD CONSTRAINT "comprehensive_bills_vendor_id_fkey" FOREIGN KEY ("vendor_id") REFERENCES "vendors"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "comprehensive_bills" ADD CONSTRAINT "comprehensive_bills_vehicle_id_fkey" FOREIGN KEY ("vehicle_id") REFERENCES "vehicles"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "comprehensive_bills" ADD CONSTRAINT "comprehensive_bills_family_member_id_fkey" FOREIGN KEY ("family_member_id") REFERENCES "family_members"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "comprehensive_bills" ADD CONSTRAINT "comprehensive_bills_asset_id_fkey" FOREIGN KEY ("asset_id") REFERENCES "property_assets"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "bill_payment_records" ADD CONSTRAINT "bill_payment_records_comprehensive_bill_id_fkey" FOREIGN KEY ("comprehensive_bill_id") REFERENCES "comprehensive_bills"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "kid_activities" ADD CONSTRAINT "kid_activities_family_member_id_fkey" FOREIGN KEY ("family_member_id") REFERENCES "family_members"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "kid_activities" ADD CONSTRAINT "kid_activities_household_id_fkey" FOREIGN KEY ("household_id") REFERENCES "households"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "zones" ADD CONSTRAINT "zones_household_id_fkey" FOREIGN KEY ("household_id") REFERENCES "households"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "property_assets" ADD CONSTRAINT "property_assets_household_id_fkey" FOREIGN KEY ("household_id") REFERENCES "households"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "property_assets" ADD CONSTRAINT "property_assets_zone_id_fkey" FOREIGN KEY ("zone_id") REFERENCES "zones"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "property_assets" ADD CONSTRAINT "property_assets_service_vendor_id_fkey" FOREIGN KEY ("service_vendor_id") REFERENCES "vendors"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "service_logs" ADD CONSTRAINT "service_logs_household_id_fkey" FOREIGN KEY ("household_id") REFERENCES "households"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "service_logs" ADD CONSTRAINT "service_logs_asset_id_fkey" FOREIGN KEY ("asset_id") REFERENCES "property_assets"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "service_logs" ADD CONSTRAINT "service_logs_zone_id_fkey" FOREIGN KEY ("zone_id") REFERENCES "zones"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "service_logs" ADD CONSTRAINT "service_logs_vendor_id_fkey" FOREIGN KEY ("vendor_id") REFERENCES "vendors"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "property_documents" ADD CONSTRAINT "property_documents_household_id_fkey" FOREIGN KEY ("household_id") REFERENCES "households"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "property_documents" ADD CONSTRAINT "property_documents_vendor_id_fkey" FOREIGN KEY ("vendor_id") REFERENCES "vendors"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "property_documents" ADD CONSTRAINT "property_documents_asset_id_fkey" FOREIGN KEY ("asset_id") REFERENCES "property_assets"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "property_documents" ADD CONSTRAINT "property_documents_bill_account_id_fkey" FOREIGN KEY ("bill_account_id") REFERENCES "bill_accounts"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "onboarding_progress" ADD CONSTRAINT "onboarding_progress_household_id_fkey" FOREIGN KEY ("household_id") REFERENCES "households"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "onboarding_progress" ADD CONSTRAINT "onboarding_progress_home_manager_id_fkey" FOREIGN KEY ("home_manager_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "onboarding_progress" ADD CONSTRAINT "onboarding_progress_handyman_id_fkey" FOREIGN KEY ("handyman_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "activity_logs" ADD CONSTRAINT "activity_logs_household_id_fkey" FOREIGN KEY ("household_id") REFERENCES "households"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "approval_requests" ADD CONSTRAINT "approval_requests_household_id_fkey" FOREIGN KEY ("household_id") REFERENCES "households"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "approval_requests" ADD CONSTRAINT "approval_requests_requester_id_fkey" FOREIGN KEY ("requester_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "approval_requests" ADD CONSTRAINT "approval_requests_decider_id_fkey" FOREIGN KEY ("decider_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "approval_comments" ADD CONSTRAINT "approval_comments_approval_id_fkey" FOREIGN KEY ("approval_id") REFERENCES "approval_requests"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "approval_comments" ADD CONSTRAINT "approval_comments_author_id_fkey" FOREIGN KEY ("author_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "documents" ADD CONSTRAINT "documents_household_id_fkey" FOREIGN KEY ("household_id") REFERENCES "households"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "documents" ADD CONSTRAINT "documents_vendor_id_fkey" FOREIGN KEY ("vendor_id") REFERENCES "vendors"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "documents" ADD CONSTRAINT "documents_uploaded_by_id_fkey" FOREIGN KEY ("uploaded_by_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "plaid_connections" ADD CONSTRAINT "plaid_connections_household_id_fkey" FOREIGN KEY ("household_id") REFERENCES "households"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "plaid_accounts" ADD CONSTRAINT "plaid_accounts_connection_id_fkey" FOREIGN KEY ("connection_id") REFERENCES "plaid_connections"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "detected_bills" ADD CONSTRAINT "detected_bills_household_id_fkey" FOREIGN KEY ("household_id") REFERENCES "households"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "detected_bills" ADD CONSTRAINT "detected_bills_account_id_fkey" FOREIGN KEY ("account_id") REFERENCES "plaid_accounts"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "household_cards" ADD CONSTRAINT "household_cards_household_id_fkey" FOREIGN KEY ("household_id") REFERENCES "households"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "bills" ADD CONSTRAINT "bills_household_id_fkey" FOREIGN KEY ("household_id") REFERENCES "households"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "bills" ADD CONSTRAINT "bills_vendor_id_fkey" FOREIGN KEY ("vendor_id") REFERENCES "household_vendors"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "bill_payments" ADD CONSTRAINT "bill_payments_bill_id_fkey" FOREIGN KEY ("bill_id") REFERENCES "bills"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "payment_approvals" ADD CONSTRAINT "payment_approvals_household_id_fkey" FOREIGN KEY ("household_id") REFERENCES "households"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "payment_approvals" ADD CONSTRAINT "payment_approvals_bill_id_fkey" FOREIGN KEY ("bill_id") REFERENCES "bills"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "calendar_connections" ADD CONSTRAINT "calendar_connections_household_id_fkey" FOREIGN KEY ("household_id") REFERENCES "households"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "calendar_connections" ADD CONSTRAINT "calendar_connections_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "calendar_events" ADD CONSTRAINT "calendar_events_connection_id_fkey" FOREIGN KEY ("connection_id") REFERENCES "calendar_connections"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "calendar_events" ADD CONSTRAINT "calendar_events_household_id_fkey" FOREIGN KEY ("household_id") REFERENCES "households"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "calendar_events" ADD CONSTRAINT "calendar_events_family_member_id_fkey" FOREIGN KEY ("family_member_id") REFERENCES "family_members"("id") ON DELETE SET NULL ON UPDATE CASCADE;

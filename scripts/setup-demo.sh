#!/bin/bash
# Demo Data Setup Script for Haven Home Manager
# Creates users in Firebase Emulator and seeds database with comprehensive demo data

set -e

echo "🏠 Haven Home Manager - Demo Setup"
echo "=================================="
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

FIREBASE_EMULATOR="http://127.0.0.1:9099"
API_KEY="demo-api-key"

# Function to create Firebase user
create_firebase_user() {
    local email=$1
    local password=$2
    local display_name=$3

    echo -e "${BLUE}Creating Firebase user: $email${NC}"

    response=$(curl -s -X POST "${FIREBASE_EMULATOR}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=${API_KEY}" \
        -H "Content-Type: application/json" \
        -d "{
            \"email\": \"$email\",
            \"password\": \"$password\",
            \"displayName\": \"$display_name\",
            \"returnSecureToken\": true
        }")

    local_id=$(echo $response | grep -o '"localId":"[^"]*"' | cut -d'"' -f4)

    if [ -n "$local_id" ]; then
        echo -e "${GREEN}  ✓ Created: $email (UID: $local_id)${NC}"
        echo $local_id
    else
        echo "  ⚠ User may already exist or error occurred"
        # Try to sign in to get the UID
        response=$(curl -s -X POST "${FIREBASE_EMULATOR}/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${API_KEY}" \
            -H "Content-Type: application/json" \
            -d "{\"email\": \"$email\", \"password\": \"$password\", \"returnSecureToken\": true}")
        local_id=$(echo $response | grep -o '"localId":"[^"]*"' | cut -d'"' -f4)
        echo $local_id
    fi
}

echo "Step 1: Creating Firebase Users"
echo "--------------------------------"
echo ""
echo -e "${BLUE}Creating main demo users (from seed.ts)...${NC}"

# ============================================================================
# MAIN DEMO USERS (matches seed.ts)
# These are the primary demo accounts with full data in the database
# ============================================================================

# Homeowners
BOB_UID=$(create_firebase_user "bob@example.com" "Bob123!" "Bob Smith")
ALICE_UID=$(create_firebase_user "alice@example.com" "Alice123!" "Alice Johnson")

# Manager
STEVE_UID=$(create_firebase_user "steve@haven.app" "Manager123!" "Steve Manager")

# Admin
ADMIN_UID=$(create_firebase_user "admin@haven.app" "Admin123!" "Admin User")

# Handymen
CARLOS_UID=$(create_firebase_user "carlos@haven.app" "Handy123!" "Carlos Reyes")
DAVE_UID=$(create_firebase_user "dave@haven.app" "Handy123!" "Mike Castellano")
MARIA_UID=$(create_firebase_user "maria@haven.app" "Handy123!" "Maria Santos")

# Vendor user
VENDOR_UID=$(create_firebase_user "vendor@aceroofing.example.com" "AceRoof123!" "Mike Johnson")

echo ""
echo -e "${BLUE}Creating additional demo users...${NC}"

# ============================================================================
# ADDITIONAL DEMO USERS (legacy setup-demo.sh users)
# ============================================================================

# Create homeowner users
HOMEOWNER1_UID=$(create_firebase_user "sarah@demo.haven.local" "demo1234" "Sarah Johnson")
HOMEOWNER2_UID=$(create_firebase_user "mike@demo.haven.local" "demo1234" "Mike Chen")
HOMEOWNER3_UID=$(create_firebase_user "emily@demo.haven.local" "demo1234" "Emily Rodriguez")

# Create home manager user
MANAGER_UID=$(create_firebase_user "manager@demo.haven.local" "demo1234" "Alex Thompson")

# Create admin user (alternative)
ADMIN2_UID=$(create_firebase_user "admin@demo.haven.local" "demo1234" "Admin User")

echo ""
echo "Step 2: Seeding Database"
echo "------------------------"

# Export UIDs for the Node.js script
export HOMEOWNER1_UID
export HOMEOWNER2_UID
export HOMEOWNER3_UID
export MANAGER_UID
export ADMIN_UID

# Run the database seed
cd "$(dirname "$0")/.."
node -e "
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function seedDemo() {
    const homeowner1Uid = process.env.HOMEOWNER1_UID;
    const homeowner2Uid = process.env.HOMEOWNER2_UID;
    const homeowner3Uid = process.env.HOMEOWNER3_UID;
    const managerUid = process.env.MANAGER_UID;
    const adminUid = process.env.ADMIN_UID;

    console.log('Creating users in database...');

    // Create Admin
    const admin = await prisma.user.upsert({
        where: { email: 'admin@demo.haven.local' },
        update: { firebaseUid: adminUid },
        create: {
            firebaseUid: adminUid,
            email: 'admin@demo.haven.local',
            firstName: 'Admin',
            lastName: 'User',
            displayName: 'Admin User',
            role: 'ADMIN',
            emailVerified: true,
            emailVerifiedAt: new Date(),
        }
    });
    console.log('  ✓ Admin user created');

    // Create Home Manager
    const manager = await prisma.user.upsert({
        where: { email: 'manager@demo.haven.local' },
        update: { firebaseUid: managerUid },
        create: {
            firebaseUid: managerUid,
            email: 'manager@demo.haven.local',
            firstName: 'Alex',
            lastName: 'Thompson',
            displayName: 'Alex Thompson',
            role: 'MANAGER',
            emailVerified: true,
            emailVerifiedAt: new Date(),
        }
    });
    console.log('  ✓ Home Manager created');

    // Create Homeowner 1 - Sarah Johnson
    const sarah = await prisma.user.upsert({
        where: { email: 'sarah@demo.haven.local' },
        update: { firebaseUid: homeowner1Uid },
        create: {
            firebaseUid: homeowner1Uid,
            email: 'sarah@demo.haven.local',
            firstName: 'Sarah',
            lastName: 'Johnson',
            displayName: 'Sarah Johnson',
            role: 'HOMEOWNER',
            emailVerified: true,
            emailVerifiedAt: new Date(),
        }
    });
    console.log('  ✓ Homeowner 1 (Sarah) created');

    // Create Homeowner 2 - Mike Chen
    const mike = await prisma.user.upsert({
        where: { email: 'mike@demo.haven.local' },
        update: { firebaseUid: homeowner2Uid },
        create: {
            firebaseUid: homeowner2Uid,
            email: 'mike@demo.haven.local',
            firstName: 'Mike',
            lastName: 'Chen',
            displayName: 'Mike Chen',
            role: 'HOMEOWNER',
            emailVerified: true,
            emailVerifiedAt: new Date(),
        }
    });
    console.log('  ✓ Homeowner 2 (Mike) created');

    // Create Homeowner 3 - Emily Rodriguez
    const emily = await prisma.user.upsert({
        where: { email: 'emily@demo.haven.local' },
        update: { firebaseUid: homeowner3Uid },
        create: {
            firebaseUid: homeowner3Uid,
            email: 'emily@demo.haven.local',
            firstName: 'Emily',
            lastName: 'Rodriguez',
            displayName: 'Emily Rodriguez',
            role: 'HOMEOWNER',
            emailVerified: true,
            emailVerifiedAt: new Date(),
        }
    });
    console.log('  ✓ Homeowner 3 (Emily) created');

    console.log('');
    console.log('Creating households...');

    // Household 1 - The Johnson Residence (Sarah)
    const household1 = await prisma.household.upsert({
        where: { id: 'demo-household-johnson' },
        update: {},
        create: {
            id: 'demo-household-johnson',
            name: 'The Johnson Residence',
            description: 'Beautiful colonial home in Westbrook',
            ownerId: sarah.id,
            subscriptionPlan: 'PREMIUM',
            subscriptionStatus: 'ACTIVE',
        }
    });

    await prisma.householdMember.upsert({
        where: { householdId_userId: { householdId: household1.id, userId: sarah.id } },
        update: {},
        create: {
            householdId: household1.id,
            userId: sarah.id,
            role: 'OWNER',
            status: 'ACTIVE',
            joinedAt: new Date(),
        }
    });

    await prisma.homeProfile.upsert({
        where: { householdId: household1.id },
        update: {},
        create: {
            householdId: household1.id,
            propertyType: 'SINGLE_FAMILY',
            addressLine1: '456 Oak Lane',
            city: 'Westbrook',
            state: 'CT',
            postalCode: '06498',
            squareFeet: 2800,
            yearBuilt: 2005,
            bedrooms: 4,
            bathrooms: 2.5,
            stories: 2,
            garageSpaces: 2,
        }
    });
    console.log('  ✓ Household 1: The Johnson Residence');

    // Household 2 - The Chen Family (Mike)
    const household2 = await prisma.household.upsert({
        where: { id: 'demo-household-chen' },
        update: {},
        create: {
            id: 'demo-household-chen',
            name: 'The Chen Family',
            description: 'Modern townhouse in downtown',
            ownerId: mike.id,
            subscriptionPlan: 'ESSENTIALS',
            subscriptionStatus: 'ACTIVE',
        }
    });

    await prisma.householdMember.upsert({
        where: { householdId_userId: { householdId: household2.id, userId: mike.id } },
        update: {},
        create: {
            householdId: household2.id,
            userId: mike.id,
            role: 'OWNER',
            status: 'ACTIVE',
            joinedAt: new Date(),
        }
    });

    await prisma.homeProfile.upsert({
        where: { householdId: household2.id },
        update: {},
        create: {
            householdId: household2.id,
            propertyType: 'TOWNHOUSE',
            addressLine1: '789 Main Street',
            addressLine2: 'Unit 12',
            city: 'Hartford',
            state: 'CT',
            postalCode: '06103',
            squareFeet: 1800,
            yearBuilt: 2018,
            bedrooms: 3,
            bathrooms: 2,
            stories: 3,
            garageSpaces: 1,
        }
    });
    console.log('  ✓ Household 2: The Chen Family');

    // Household 3 - Casa Rodriguez (Emily)
    const household3 = await prisma.household.upsert({
        where: { id: 'demo-household-rodriguez' },
        update: {},
        create: {
            id: 'demo-household-rodriguez',
            name: 'Casa Rodriguez',
            description: 'Cozy ranch-style home',
            ownerId: emily.id,
            subscriptionPlan: 'FREE',
            subscriptionStatus: 'ACTIVE',
        }
    });

    await prisma.householdMember.upsert({
        where: { householdId_userId: { householdId: household3.id, userId: emily.id } },
        update: {},
        create: {
            householdId: household3.id,
            userId: emily.id,
            role: 'OWNER',
            status: 'ACTIVE',
            joinedAt: new Date(),
        }
    });

    await prisma.homeProfile.upsert({
        where: { householdId: household3.id },
        update: {},
        create: {
            householdId: household3.id,
            propertyType: 'SINGLE_FAMILY',
            addressLine1: '123 Maple Drive',
            city: 'New Haven',
            state: 'CT',
            postalCode: '06511',
            squareFeet: 1500,
            yearBuilt: 1975,
            bedrooms: 3,
            bathrooms: 1.5,
            stories: 1,
            garageSpaces: 1,
        }
    });
    console.log('  ✓ Household 3: Casa Rodriguez');

    // Add Home Manager to all households
    console.log('');
    console.log('Assigning Home Manager to households...');

    for (const household of [household1, household2, household3]) {
        await prisma.householdMember.upsert({
            where: { householdId_userId: { householdId: household.id, userId: manager.id } },
            update: {},
            create: {
                householdId: household.id,
                userId: manager.id,
                role: 'HOME_MANAGER',
                status: 'ACTIVE',
                joinedAt: new Date(),
            }
        });
    }
    console.log('  ✓ Home Manager assigned to all 3 households');

    // Create vendors
    console.log('');
    console.log('Creating vendors...');

    const vendors = [
        { displayName: 'Green Thumb Landscaping', category: 'LAWN_CARE', phone: '555-0101' },
        { displayName: 'Sparkle Clean Services', category: 'CLEANING', phone: '555-0102' },
        { displayName: 'ABC Plumbing', category: 'HANDYMAN', phone: '555-0103' },
        { displayName: 'Cool Air HVAC', category: 'HVAC_SERVICE', phone: '555-0104' },
        { displayName: 'Bug-B-Gone Pest Control', category: 'PEST_CONTROL', phone: '555-0105' },
        { displayName: 'Regional Electric Co', category: 'ELECTRIC', phone: '555-0106' },
        { displayName: 'City Water Utility', category: 'WATER_SEWER', phone: '555-0107' },
    ];

    for (const v of vendors) {
        await prisma.vendor.upsert({
            where: { id: 'vendor-' + v.category.toLowerCase() },
            update: {},
            create: {
                id: 'vendor-' + v.category.toLowerCase(),
                displayName: v.displayName,
                category: v.category,
                phone: v.phone,
                isLocal: true,
                isVerified: true,
            }
        });
    }
    console.log('  ✓ Created ' + vendors.length + ' vendors');

    // Create bill accounts for Johnson household
    console.log('');
    console.log('Creating bill accounts for Johnson household...');

    const today = new Date();
    const billAccounts = [
        { nickname: 'Electric Bill', category: 'ELECTRIC', vendorId: 'vendor-electric', typicalAmount: 185.00 },
        { nickname: 'Water & Sewer', category: 'WATER_SEWER', vendorId: 'vendor-water_sewer', typicalAmount: 95.00 },
        { nickname: 'Lawn Care', category: 'LAWN_CARE', vendorId: 'vendor-lawn_care', typicalAmount: 175.00 },
        { nickname: 'House Cleaning', category: 'CLEANING', vendorId: 'vendor-cleaning', typicalAmount: 200.00 },
    ];

    for (const bill of billAccounts) {
        await prisma.billAccount.upsert({
            where: { id: 'bill-johnson-' + bill.category.toLowerCase() },
            update: {},
            create: {
                id: 'bill-johnson-' + bill.category.toLowerCase(),
                householdId: household1.id,
                vendorId: bill.vendorId,
                nickname: bill.nickname,
                category: bill.category,
                billingFrequency: 'MONTHLY',
                paymentResponsibility: 'OWNER_PAYS_DIRECT',
                typicalAmount: bill.typicalAmount,
                nextDueDate: new Date(today.getFullYear(), today.getMonth() + 1, 15),
            }
        });
    }
    console.log('  ✓ Created ' + billAccounts.length + ' bill accounts');

    // Create maintenance tasks
    console.log('');
    console.log('Creating maintenance tasks...');

    const maintenanceTasks = [
        { title: 'HVAC Filter Replacement', category: 'HVAC', status: 'PENDING', dueDate: new Date(today.getTime() + 7 * 24 * 60 * 60 * 1000), priority: 'MEDIUM' },
        { title: 'Gutter Cleaning', category: 'ROOF_GUTTER', status: 'SCHEDULED', dueDate: new Date(today.getTime() + 14 * 24 * 60 * 60 * 1000), priority: 'LOW' },
        { title: 'Pest Control Treatment', category: 'PEST', status: 'PENDING', dueDate: new Date(today.getTime() + 30 * 24 * 60 * 60 * 1000), priority: 'MEDIUM' },
        { title: 'Smoke Detector Battery Check', category: 'SAFETY', status: 'OVERDUE', dueDate: new Date(today.getTime() - 5 * 24 * 60 * 60 * 1000), priority: 'HIGH' },
        { title: 'Window Washing', category: 'CLEANING', status: 'COMPLETED', dueDate: new Date(today.getTime() - 14 * 24 * 60 * 60 * 1000), priority: 'LOW' },
    ];

    for (let i = 0; i < maintenanceTasks.length; i++) {
        const task = maintenanceTasks[i];
        await prisma.maintenanceTask.upsert({
            where: { id: 'task-johnson-' + i },
            update: {},
            create: {
                id: 'task-johnson-' + i,
                householdId: household1.id,
                title: task.title,
                category: task.category,
                status: task.status,
                dueDate: task.dueDate,
                priority: task.priority,
            }
        });
    }
    console.log('  ✓ Created ' + maintenanceTasks.length + ' maintenance tasks');

    // Create work orders
    console.log('');
    console.log('Creating work orders...');

    await prisma.workOrder.upsert({
        where: { id: 'work-order-1' },
        update: {},
        create: {
            id: 'work-order-1',
            householdId: household1.id,
            createdByUserId: sarah.id,
            title: 'Fix leaking kitchen faucet',
            description: 'The kitchen faucet has been dripping for a week. Need a plumber to fix it.',
            status: 'SCHEDULED',
            scheduledStart: new Date(today.getTime() + 3 * 24 * 60 * 60 * 1000),
            estimatedCost: 150.00,
        }
    });

    await prisma.workOrder.upsert({
        where: { id: 'work-order-2' },
        update: {},
        create: {
            id: 'work-order-2',
            householdId: household2.id,
            createdByUserId: mike.id,
            title: 'Annual HVAC Inspection',
            description: 'Schedule annual maintenance for the HVAC system before winter.',
            status: 'REQUESTED',
            preferredDate: new Date(today.getTime() + 14 * 24 * 60 * 60 * 1000),
        }
    });

    await prisma.workOrder.upsert({
        where: { id: 'work-order-3' },
        update: {},
        create: {
            id: 'work-order-3',
            householdId: household3.id,
            createdByUserId: emily.id,
            title: 'Garage door repair',
            description: 'The garage door opener is making a grinding noise.',
            status: 'IN_PROGRESS',
            scheduledStart: new Date(today.getTime() - 1 * 24 * 60 * 60 * 1000),
            estimatedCost: 200.00,
        }
    });
    console.log('  ✓ Created 3 work orders');

    // Create conversations
    console.log('');
    console.log('Creating support conversations...');

    const conv1 = await prisma.conversation.upsert({
        where: { id: 'conv-1' },
        update: {},
        create: {
            id: 'conv-1',
            householdId: household1.id,
            createdByUserId: sarah.id,
            subject: 'Question about lawn care schedule',
            status: 'OPEN',
        }
    });

    await prisma.supportMessage.createMany({
        data: [
            {
                conversationId: conv1.id,
                senderUserId: sarah.id,
                senderRole: 'HOMEOWNER',
                body: 'Hi! I wanted to ask about changing the lawn care schedule. Can we switch to bi-weekly during the fall?',
            },
            {
                conversationId: conv1.id,
                senderUserId: manager.id,
                senderRole: 'HOME_MANAGER',
                body: 'Hi Sarah! Absolutely, we can adjust that for you. I\\'ll contact Green Thumb Landscaping to update the schedule. The change will take effect starting next month.',
            },
            {
                conversationId: conv1.id,
                senderUserId: sarah.id,
                senderRole: 'HOMEOWNER',
                body: 'Perfect, thank you so much!',
            },
        ],
        skipDuplicates: true,
    });

    const conv2 = await prisma.conversation.upsert({
        where: { id: 'conv-2' },
        update: {},
        create: {
            id: 'conv-2',
            householdId: household2.id,
            createdByUserId: mike.id,
            subject: 'HVAC making strange noise',
            status: 'PENDING',
        }
    });

    await prisma.supportMessage.createMany({
        data: [
            {
                conversationId: conv2.id,
                senderUserId: mike.id,
                senderRole: 'HOMEOWNER',
                body: 'My HVAC system started making a clicking noise yesterday. Is this something I should be concerned about?',
            },
            {
                conversationId: conv2.id,
                senderUserId: manager.id,
                senderRole: 'HOME_MANAGER',
                body: 'Hi Mike, clicking noises can sometimes indicate an issue with the fan or compressor. I\\'d recommend we schedule an inspection. I\\'ve created a work order for Cool Air HVAC to come take a look. Are you available this week?',
            },
        ],
        skipDuplicates: true,
    });
    console.log('  ✓ Created 2 conversations with messages');

    // Create notifications
    console.log('');
    console.log('Creating notifications...');

    await prisma.inAppNotification.createMany({
        data: [
            {
                userId: sarah.id,
                householdId: household1.id,
                title: 'Bill Due Soon',
                body: 'Your Electric Bill is due in 5 days.',
                link: '/app/bills',
            },
            {
                userId: sarah.id,
                householdId: household1.id,
                title: 'Maintenance Task Overdue',
                body: 'Smoke Detector Battery Check is overdue. Please schedule it soon.',
                link: '/app/maintenance',
            },
            {
                userId: mike.id,
                householdId: household2.id,
                title: 'Work Order Scheduled',
                body: 'Your HVAC inspection has been scheduled for next week.',
                link: '/app/work-orders',
            },
        ],
        skipDuplicates: true,
    });
    console.log('  ✓ Created notifications');

    console.log('');
    console.log('✅ Demo data setup complete!');
}

seedDemo()
    .then(() => prisma.\$disconnect())
    .catch((e) => {
        console.error(e);
        prisma.\$disconnect();
        process.exit(1);
    });
"

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  DEMO SETUP COMPLETE!"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "  ┌─────────────────────────────────────────────────────────────┐"
echo "  │  PRIMARY DEMO ACCOUNTS (from seed.ts - full data)          │"
echo "  └─────────────────────────────────────────────────────────────┘"
echo ""
echo "  🏠 HOMEOWNER ACCOUNTS:"
echo "  ─────────────────────────────────────────────"
echo "  Bob Smith (Bob's Villa, Greenwich CT)"
echo "     Email:    bob@example.com"
echo "     Password: Bob123!"
echo "     Portal:   /app (homeowner portal)"
echo ""
echo "  Alice Johnson (Scarsdale, NY)"
echo "     Email:    alice@example.com"
echo "     Password: Alice123!"
echo "     Portal:   /app (homeowner portal)"
echo ""
echo "  👔 MANAGER ACCOUNT:"
echo "  ─────────────────────────────────────────────"
echo "  Steve Manager"
echo "     Email:    steve@haven.app"
echo "     Password: Manager123!"
echo "     Portal:   /manager"
echo ""
echo "  🛠️  HANDYMAN ACCOUNTS:"
echo "  ─────────────────────────────────────────────"
echo "  Carlos Reyes (Westchester NY)"
echo "     Email:    carlos@haven.app"
echo "     Password: Handy123!"
echo "     Portal:   /handyman"
echo ""
echo "  Mike Castellano (Fairfield CT)"
echo "     Email:    dave@haven.app"
echo "     Password: Handy123!"
echo "     Portal:   /handyman"
echo ""
echo "  Maria Santos (Floater)"
echo "     Email:    maria@haven.app"
echo "     Password: Handy123!"
echo "     Portal:   /handyman"
echo ""
echo "  🏪 VENDOR ACCOUNT:"
echo "  ─────────────────────────────────────────────"
echo "  Mike Johnson (Ace Roofing)"
echo "     Email:    vendor@aceroofing.example.com"
echo "     Password: AceRoof123!"
echo "     Portal:   /vendor"
echo ""
echo "  🔑 ADMIN ACCOUNT:"
echo "  ─────────────────────────────────────────────"
echo "     Email:    admin@haven.app"
echo "     Password: Admin123!"
echo "     Portal:   /admin"
echo ""
echo "  ┌─────────────────────────────────────────────────────────────┐"
echo "  │  ADDITIONAL DEMO ACCOUNTS (setup-demo.sh only)             │"
echo "  └─────────────────────────────────────────────────────────────┘"
echo ""
echo "  🏠 More Homeowners:"
echo "     sarah@demo.haven.local    / demo1234 (The Johnson Residence)"
echo "     mike@demo.haven.local     / demo1234 (The Chen Family)"
echo "     emily@demo.haven.local    / demo1234 (Casa Rodriguez)"
echo ""
echo "  👔 Alt Manager:  manager@demo.haven.local / demo1234"
echo "  🔑 Alt Admin:    admin@demo.haven.local   / demo1234"
echo ""
echo "  ─────────────────────────────────────────────"
echo "  📱 WEB APP:           http://localhost:3000"
echo "  🔥 Firebase Emulator: http://localhost:4001"
echo "  📡 API:               http://localhost:4000/api"
echo "  ─────────────────────────────────────────────"
echo ""
echo "═══════════════════════════════════════════════════════════════"

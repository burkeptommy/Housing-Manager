/**
 * Seed Alfred Email Demo Data for Burke Household
 *
 * Creates:
 * - Alfred email address (146PutnamParkRd@alfred.havenhome.dev)
 * - Example email cases to showcase the feature
 *
 * Run with: DATABASE_URL="..." npx ts-node prisma/seed-alfred-emails.ts
 */

import { PrismaClient, EmailCaseStatus, EmailCasePriority } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  console.log('📧 Seeding Alfred Email Demo Data for Burke Household...\n');

  // Find Burke household
  const household = await prisma.household.findUnique({
    where: { id: 'burke-household-demo' },
    include: { homeProfile: true },
  });

  if (!household) {
    console.error('❌ Burke household not found. Run seed-burke.ts first.');
    process.exit(1);
  }

  console.log(`Found household: ${household.name}`);
  console.log(`Address: ${household.homeProfile?.addressLine1}`);

  // ============================================================================
  // 1. SET ALFRED EMAIL CODE
  // ============================================================================
  console.log('\n📮 Setting Alfred email code...');

  const alfredEmailCode = '146PutnamParkRd';

  await prisma.household.update({
    where: { id: household.id },
    data: { alfredEmailCode },
  });

  console.log(`✅ Alfred email: ${alfredEmailCode}@alfred.havenhome.dev`);

  // ============================================================================
  // 2. ADD AUTHORIZED EMAILS
  // ============================================================================
  console.log('\n✉️ Adding authorized emails...');

  // Get the household owner (from the household relation)
  const householdWithOwner = await prisma.household.findUnique({
    where: { id: household.id },
    include: { owner: true },
  });

  if (!householdWithOwner?.owner) {
    console.log('⚠️ No owner found for household, skipping authorized emails');
  } else {
    const owner = householdWithOwner.owner;
    // Clear existing authorized emails
    await prisma.authorizedEmail.deleteMany({ where: { householdId: household.id } });

    const authorizedEmails = [
      { email: 'tom@example.com', label: 'Tom (Owner)' },
      { email: 'mindy@example.com', label: 'Mindy (Spouse)' },
      { email: 'noreply@eversource.com', label: 'Eversource' },
      { email: 'statements@capitaloneauto.com', label: 'Capital One' },
    ];

    for (const auth of authorizedEmails) {
      await prisma.authorizedEmail.create({
        data: {
          household: { connect: { id: household.id } },
          email: auth.email,
          label: auth.label,
          addedBy: { connect: { id: owner.id } },
        },
      });
    }
    console.log(`✅ Added ${authorizedEmails.length} authorized emails`);
  }

  // ============================================================================
  // 3. CREATE EXAMPLE EMAIL CASES
  // ============================================================================
  console.log('\n📨 Creating example email cases...');

  // Clear existing email cases (delete by case number pattern to avoid conflicts)
  await prisma.emailCase.deleteMany({
    where: {
      caseNumber: {
        startsWith: 'ALF-2026-0000',
      },
    },
  });

  const now = new Date();
  const twoDaysAgo = new Date(now.getTime() - 2 * 24 * 60 * 60 * 1000);
  const fiveDaysAgo = new Date(now.getTime() - 5 * 24 * 60 * 60 * 1000);
  const oneWeekAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
  const twoWeeksAgo = new Date(now.getTime() - 14 * 24 * 60 * 60 * 1000);

  const emailCases = [
    // Completed case - Bill reminder
    {
      householdId: household.id,
      caseNumber: 'ALF-2026-000001',
      messageId: 'msg_demo_001',
      fromEmail: 'noreply@eversource.com',
      fromName: 'Eversource Energy',
      subject: 'Your January 2026 Energy Bill is Ready',
      bodyText: 'Your bill for $187.42 is due on January 25, 2026. Account #: 12345678.',
      receivedAt: twoWeeksAgo,
      status: EmailCaseStatus.COMPLETED,
      priority: EmailCasePriority.NORMAL,
      summary: 'Electric bill of $187.42 due January 25th',
      detectedIntent: 'BILL_PAYMENT',
      actionsTaken: JSON.parse(JSON.stringify([
        { type: 'bill_tracked', description: 'Added to bill calendar with due date reminder' },
        { type: 'notification_sent', description: 'Reminder set for 3 days before due date' },
      ])),
      resolvedAt: new Date(twoWeeksAgo.getTime() + 60000),
    },
    // Completed case - Appointment confirmation
    {
      householdId: household.id,
      caseNumber: 'ALF-2026-000002',
      messageId: 'msg_demo_002',
      fromEmail: 'appointments@bethelpediatrics.com',
      fromName: 'Bethel Pediatrics',
      subject: 'Appointment Confirmation - Blake Burke',
      bodyText: `Dear Burke Family,

This confirms Blake's well-child visit appointment:
Date: Tuesday, January 28, 2026
Time: 10:30 AM
Doctor: Dr. Sarah Chen

Please arrive 15 minutes early.

Bethel Pediatrics
123 Main Street, Bethel CT`,
      receivedAt: oneWeekAgo,
      status: EmailCaseStatus.COMPLETED,
      priority: EmailCasePriority.NORMAL,
      summary: "Blake's pediatrician appointment on Jan 28 at 10:30 AM",
      detectedIntent: 'CALENDAR_EVENT',
      actionsTaken: JSON.parse(JSON.stringify([
        { type: 'calendar_added', description: 'Added appointment to family calendar' },
        { type: 'reminder_set', description: 'Set reminder for day before and 1 hour before' },
      ])),
      resolvedAt: new Date(oneWeekAgo.getTime() + 60000),
    },
    // In Progress case - Vendor quote
    {
      householdId: household.id,
      caseNumber: 'ALF-2026-000003',
      messageId: 'msg_demo_003',
      fromEmail: 'quotes@ctchimneysweeps.com',
      fromName: 'CT Chimney Sweeps',
      subject: 'Quote for Chimney Cleaning - 146 Putnam Park Rd',
      bodyText: `Hi Tom,

Thank you for your inquiry about chimney cleaning services.

Quote for 146 Putnam Park Rd:
- Chimney #1 (Living Room): $225
- Chimney #2 (Family Room): $225
- Total: $450

Available dates:
- Tuesday, Feb 4th (morning)
- Thursday, Feb 6th (afternoon)
- Monday, Feb 10th (all day)

Please let us know which date works best.

Best,
Mike at CT Chimney Sweeps`,
      receivedAt: fiveDaysAgo,
      status: EmailCaseStatus.IN_PROGRESS,
      priority: EmailCasePriority.NORMAL,
      summary: 'Chimney cleaning quote: $450 for both chimneys',
      detectedIntent: 'VENDOR_QUOTE',
      actionsTaken: JSON.parse(JSON.stringify([
        { type: 'vendor_matched', description: 'Matched to existing maintenance task: Annual Chimney Cleaning' },
      ])),
    },
    // Awaiting Input - School registration
    {
      householdId: household.id,
      caseNumber: 'ALF-2026-000004',
      messageId: 'msg_demo_004',
      fromEmail: 'registration@bethelschools.org',
      fromName: 'Bethel Public Schools',
      subject: 'Pre-K Registration Open - Blake Burke',
      bodyText: `Dear Burke Family,

Pre-K registration for the 2026-2027 school year is now open!

Based on Blake's birthdate (January 2022), she is eligible for our Pre-K program starting September 2026.

Important dates:
- Registration deadline: March 1, 2026
- Open house: February 15, 2026, 10am-12pm
- Required documents: Birth certificate, proof of residency, immunization records

Registration fee: $150 (non-refundable)

Would you like to proceed with registration?

Bethel Public Schools
Registration Office`,
      receivedAt: twoDaysAgo,
      status: EmailCaseStatus.AWAITING_INPUT,
      priority: EmailCasePriority.HIGH,
      summary: "Blake's Pre-K registration - deadline March 1st",
      detectedIntent: 'SCHOOL_REGISTRATION',
      pendingQuestion: "Would you like me to add the Pre-K registration deadline and open house to your calendar? Also, should I create a checklist for gathering the required documents?",
      questionOptions: JSON.parse(JSON.stringify([
        'Yes, add both to calendar and create document checklist',
        'Just add to calendar',
        'No, I will handle this myself',
      ])),
    },
    // Received - New email just came in
    {
      householdId: household.id,
      caseNumber: 'ALF-2026-000005',
      messageId: 'msg_demo_005',
      fromEmail: 'service@bluefoxlandscaping.com',
      fromName: 'Blue Fox Landscaping',
      subject: 'Snow Plowing Schedule Update',
      bodyText: `Hi Burke Family,

Weather alert: 4-6 inches of snow expected overnight Thursday into Friday (Jan 23-24).

Our plowing schedule:
- First pass: 5am Friday
- Second pass (if needed): After snowfall ends

Driveway will be cleared before 8am.

Let us know if you have any special requests.

Blue Fox Landscaping`,
      receivedAt: new Date(now.getTime() - 30 * 60 * 1000), // 30 minutes ago
      status: EmailCaseStatus.PROCESSING,
      priority: EmailCasePriority.NORMAL,
      summary: 'Snow plowing scheduled for Friday morning',
      detectedIntent: 'SERVICE_UPDATE',
    },
  ];

  for (const emailCase of emailCases) {
    const { householdId, ...caseData } = emailCase;
    await prisma.emailCase.create({
      data: {
        ...caseData,
        household: { connect: { id: householdId } },
      },
    });
  }

  console.log(`✅ Created ${emailCases.length} example email cases`);

  // ============================================================================
  // SUMMARY
  // ============================================================================
  console.log('\n');
  console.log('═══════════════════════════════════════════════════════════════════');
  console.log('🎉 ALFRED EMAIL DEMO DATA COMPLETE!');
  console.log('═══════════════════════════════════════════════════════════════════');
  console.log('');
  console.log('📧 Alfred Email Address:');
  console.log(`   ${alfredEmailCode}@alfred.havenhome.dev`);
  console.log('');
  console.log('✉️ Authorized Senders:');
  console.log('   • tom@example.com (Tom - Owner)');
  console.log('   • mindy@example.com (Mindy - Spouse)');
  console.log('   • noreply@eversource.com (Eversource)');
  console.log('   • statements@capitaloneauto.com (Capital One)');
  console.log('');
  console.log('📨 Email Cases:');
  console.log('   • ALF-2026-000001: Eversource bill (COMPLETED)');
  console.log('   • ALF-2026-000002: Pediatrician appointment (COMPLETED)');
  console.log('   • ALF-2026-000003: Chimney cleaning quote (IN_PROGRESS)');
  console.log('   • ALF-2026-000004: Pre-K registration (AWAITING_INPUT)');
  console.log('   • ALF-2026-000005: Snow plowing update (PROCESSING)');
  console.log('');
  console.log('═══════════════════════════════════════════════════════════════════');
}

main()
  .catch((e) => {
    console.error('❌ Seed failed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });

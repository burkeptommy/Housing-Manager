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

  // Clear existing email cases and their activities (delete by case number pattern to avoid conflicts)
  const existingCases = await prisma.emailCase.findMany({
    where: { caseNumber: { startsWith: 'ALF-2026-0000' } },
    select: { id: true },
  });

  if (existingCases.length > 0) {
    // Delete activities first (cascade should handle this, but being explicit)
    await prisma.emailCaseActivity.deleteMany({
      where: { caseId: { in: existingCases.map(c => c.id) } },
    });

    await prisma.emailCase.deleteMany({
      where: { caseNumber: { startsWith: 'ALF-2026-0000' } },
    });
  }

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
    // Awaiting Input case - Vendor quote needs confirmation
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
      status: EmailCaseStatus.AWAITING_INPUT,
      priority: EmailCasePriority.NORMAL,
      summary: 'Chimney cleaning quote: $450 for both chimneys. Three dates available.',
      detectedIntent: 'VENDOR_QUOTE',
      pendingQuestion: "I found a quote for chimney cleaning at $450. Would you like me to schedule this service and add it to your calendar?",
      questionOptions: JSON.parse(JSON.stringify([
        'Yes, schedule for Feb 4th (morning)',
        'Yes, schedule for Feb 6th (afternoon)',
        'Yes, schedule for Feb 10th',
        'No thanks, I\'ll handle this myself',
      ])),
      actionsTaken: JSON.parse(JSON.stringify([
        { type: 'vendor_matched', description: 'Matched to vendor: CT Chimney Sweeps' },
        { type: 'quote_extracted', description: 'Extracted quote: $450 for 2 chimneys' },
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
  // 4. CREATE ACTIVITY TIMELINE FOR EACH CASE
  // ============================================================================
  console.log('\n📝 Creating activity timelines...');

  // Get created cases
  const createdCases = await prisma.emailCase.findMany({
    where: { caseNumber: { startsWith: 'ALF-2026-0000' } },
    orderBy: { caseNumber: 'asc' },
  });

  // Activities for Case 1 (Eversource Bill - Completed)
  const case1 = createdCases.find(c => c.caseNumber === 'ALF-2026-000001');
  if (case1) {
    await prisma.emailCaseActivity.createMany({
      data: [
        {
          caseId: case1.id,
          type: 'CASE_CREATED',
          description: 'Email received from Eversource Energy',
          actor: 'system',
          actorName: 'System',
          createdAt: new Date(case1.receivedAt.getTime()),
        },
        {
          caseId: case1.id,
          type: 'EMAIL_PARSED',
          description: 'Detected bill payment email. Amount: $187.42, Due: January 25, 2026',
          actor: 'alfred',
          actorName: 'Alfred',
          createdAt: new Date(case1.receivedAt.getTime() + 5000),
        },
        {
          caseId: case1.id,
          type: 'BILL_CREATED',
          description: 'Added bill to tracking: Eversource Electric - $187.42 due Jan 25',
          actor: 'alfred',
          actorName: 'Alfred',
          createdAt: new Date(case1.receivedAt.getTime() + 10000),
        },
        {
          caseId: case1.id,
          type: 'REMINDER_CREATED',
          description: 'Set payment reminder for January 22, 2026 (3 days before due)',
          actor: 'alfred',
          actorName: 'Alfred',
          createdAt: new Date(case1.receivedAt.getTime() + 15000),
        },
        {
          caseId: case1.id,
          type: 'STATUS_CHANGED',
          description: 'Case completed - bill tracked and reminder set',
          actor: 'alfred',
          actorName: 'Alfred',
          createdAt: new Date(case1.receivedAt.getTime() + 20000),
        },
      ],
    });
  }

  // Activities for Case 2 (Pediatrician Appointment - Completed)
  const case2 = createdCases.find(c => c.caseNumber === 'ALF-2026-000002');
  if (case2) {
    await prisma.emailCaseActivity.createMany({
      data: [
        {
          caseId: case2.id,
          type: 'CASE_CREATED',
          description: 'Email received from Bethel Pediatrics',
          actor: 'system',
          actorName: 'System',
          createdAt: new Date(case2.receivedAt.getTime()),
        },
        {
          caseId: case2.id,
          type: 'EMAIL_PARSED',
          description: 'Detected appointment confirmation for Blake Burke on Jan 28 at 10:30 AM',
          actor: 'alfred',
          actorName: 'Alfred',
          createdAt: new Date(case2.receivedAt.getTime() + 5000),
        },
        {
          caseId: case2.id,
          type: 'CALENDAR_EVENT_CREATED',
          description: "Added to family calendar: Blake's Well-Child Visit with Dr. Sarah Chen",
          actor: 'alfred',
          actorName: 'Alfred',
          createdAt: new Date(case2.receivedAt.getTime() + 10000),
        },
        {
          caseId: case2.id,
          type: 'REMINDER_CREATED',
          description: 'Set reminders: 1 day before and 1 hour before appointment',
          actor: 'alfred',
          actorName: 'Alfred',
          createdAt: new Date(case2.receivedAt.getTime() + 15000),
        },
        {
          caseId: case2.id,
          type: 'STATUS_CHANGED',
          description: 'Case completed - event added to calendar with reminders',
          actor: 'alfred',
          actorName: 'Alfred',
          createdAt: new Date(case2.receivedAt.getTime() + 20000),
        },
      ],
    });
  }

  // Activities for Case 3 (Chimney Quote - Awaiting Input)
  const case3 = createdCases.find(c => c.caseNumber === 'ALF-2026-000003');
  if (case3) {
    await prisma.emailCaseActivity.createMany({
      data: [
        {
          caseId: case3.id,
          type: 'CASE_CREATED',
          description: 'Email received from CT Chimney Sweeps',
          actor: 'system',
          actorName: 'System',
          createdAt: new Date(case3.receivedAt.getTime()),
        },
        {
          caseId: case3.id,
          type: 'EMAIL_PARSED',
          description: 'Detected vendor quote: $450 for chimney cleaning (2 chimneys). 3 available dates.',
          actor: 'alfred',
          actorName: 'Alfred',
          createdAt: new Date(case3.receivedAt.getTime() + 5000),
        },
        {
          caseId: case3.id,
          type: 'VENDOR_UPDATED',
          description: 'Matched email to vendor: CT Chimney Sweeps',
          actor: 'alfred',
          actorName: 'Alfred',
          createdAt: new Date(case3.receivedAt.getTime() + 10000),
        },
        {
          caseId: case3.id,
          type: 'QUESTION_ASKED',
          description: 'Asking for approval to schedule chimney cleaning appointment',
          actor: 'alfred',
          actorName: 'Alfred',
          createdAt: new Date(case3.receivedAt.getTime() + 15000),
        },
      ],
    });
  }

  // Activities for Case 4 (Pre-K Registration - Awaiting Input)
  const case4 = createdCases.find(c => c.caseNumber === 'ALF-2026-000004');
  if (case4) {
    await prisma.emailCaseActivity.createMany({
      data: [
        {
          caseId: case4.id,
          type: 'CASE_CREATED',
          description: 'Email received from Bethel Public Schools',
          actor: 'system',
          actorName: 'System',
          createdAt: new Date(case4.receivedAt.getTime()),
        },
        {
          caseId: case4.id,
          type: 'EMAIL_PARSED',
          description: 'Detected school registration notice. Deadline: March 1. Open house: Feb 15. Fee: $150',
          actor: 'alfred',
          actorName: 'Alfred',
          createdAt: new Date(case4.receivedAt.getTime() + 5000),
        },
        {
          caseId: case4.id,
          type: 'QUESTION_ASKED',
          description: 'Asking for approval to add dates to calendar and create document checklist',
          actor: 'alfred',
          actorName: 'Alfred',
          createdAt: new Date(case4.receivedAt.getTime() + 10000),
        },
      ],
    });
  }

  // Activities for Case 5 (Snow Plowing - Processing)
  const case5 = createdCases.find(c => c.caseNumber === 'ALF-2026-000005');
  if (case5) {
    await prisma.emailCaseActivity.createMany({
      data: [
        {
          caseId: case5.id,
          type: 'CASE_CREATED',
          description: 'Email received from Blue Fox Landscaping',
          actor: 'system',
          actorName: 'System',
          createdAt: new Date(case5.receivedAt.getTime()),
        },
        {
          caseId: case5.id,
          type: 'EMAIL_PARSED',
          description: 'Detected service update: Snow plowing scheduled for Friday morning',
          actor: 'alfred',
          actorName: 'Alfred',
          createdAt: new Date(case5.receivedAt.getTime() + 5000),
        },
      ],
    });
  }

  console.log('✅ Created activity timelines for all cases');

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

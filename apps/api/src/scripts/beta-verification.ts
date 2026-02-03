import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

interface Check {
  name: string;
  pass: boolean;
  detail?: string;
  error?: string;
}

async function verifyBetaReadiness() {
  console.log('Haven Beta Verification Starting...\n');

  const checks: Check[] = [];

  // 1. Database connection
  try {
    await prisma.$queryRaw`SELECT 1`;
    checks.push({ name: 'Database Connection', pass: true });
  } catch (e: any) {
    checks.push({ name: 'Database Connection', pass: false, error: e.message });
  }

  // 2. Users exist
  const userCount = await prisma.user.count();
  checks.push({
    name: 'Users in Database',
    pass: userCount > 0,
    detail: `${userCount} users`,
    error: userCount === 0 ? 'No users found' : undefined,
  });

  // 3. Households exist
  const householdCount = await prisma.household.count();
  checks.push({
    name: 'Households in Database',
    pass: householdCount > 0,
    detail: `${householdCount} households`,
    error: householdCount === 0 ? 'No households found' : undefined,
  });

  // 4. Home profiles
  const homeProfileCount = await prisma.homeProfile.count();
  checks.push({
    name: 'Home Profiles',
    pass: homeProfileCount > 0,
    detail: `${homeProfileCount} profiles`,
  });

  // 5. Alfred email codes configured
  const alfredConfigured = await prisma.household.count({
    where: { alfredEmailCode: { not: null } },
  });
  checks.push({
    name: 'Alfred Email Configured',
    pass: alfredConfigured > 0,
    detail: `${alfredConfigured}/${householdCount} households have Alfred email`,
  });

  // 6. Authorized emails exist
  const authorizedEmailCount = await prisma.authorizedEmail.count();
  checks.push({
    name: 'Authorized Emails',
    pass: authorizedEmailCount > 0,
    detail: `${authorizedEmailCount} authorized emails`,
  });

  // 7. Email cases (test flow)
  const emailCaseCount = await prisma.emailCase.count();
  checks.push({
    name: 'Email Cases (Alfred)',
    pass: true, // informational
    detail: `${emailCaseCount} cases processed`,
  });

  // 8. Family members
  const familyMemberCount = await prisma.familyMember.count();
  checks.push({
    name: 'Family Members',
    pass: true,
    detail: `${familyMemberCount} family members`,
  });

  // 9. Vendors
  const vendorCount = await prisma.vendor.count();
  const householdVendorCount = await prisma.householdVendor.count();
  checks.push({
    name: 'Vendors',
    pass: true,
    detail: `${vendorCount} vendors, ${householdVendorCount} household links`,
  });

  // 10. Property assets (home systems)
  const assetCount = await prisma.propertyAsset.count();
  checks.push({
    name: 'Property Assets / Systems',
    pass: true,
    detail: `${assetCount} assets tracked`,
  });

  // 11. Bills
  const billCount = await prisma.bill.count();
  checks.push({
    name: 'Bills',
    pass: true,
    detail: `${billCount} bills tracked`,
  });

  // 12. Plaid connections
  let plaidCount = 0;
  try {
    plaidCount = await (prisma as any).plaidItem?.count() ?? 0;
  } catch {
    // plaidItem may not exist in schema
  }
  checks.push({
    name: 'Plaid Bank Connections',
    pass: true,
    detail: `${plaidCount} connections`,
  });

  // 13. Budget categories
  let budgetCategoryCount = 0;
  try {
    budgetCategoryCount = await prisma.budgetCategory.count();
  } catch {
    // may not exist yet
  }
  checks.push({
    name: 'Budget Categories',
    pass: true,
    detail: `${budgetCategoryCount} categories`,
  });

  // 14. System forecasts
  let forecastCount = 0;
  try {
    forecastCount = await prisma.systemForecast.count();
  } catch {
    // may not exist
  }
  checks.push({
    name: 'System Forecasts',
    pass: true,
    detail: `${forecastCount} forecasts`,
  });

  // 15. Calendar connections (Google)
  let calendarConnectionCount = 0;
  try {
    calendarConnectionCount = await prisma.calendarConnection.count();
  } catch {
    // may not exist
  }
  checks.push({
    name: 'Calendar Connections',
    pass: true,
    detail: `${calendarConnectionCount} connected`,
  });

  // 16. Family events
  const eventCount = await prisma.familyEvent.count();
  checks.push({
    name: 'Family Events / Calendar',
    pass: true,
    detail: `${eventCount} events`,
  });

  // 17. Tasks
  const taskCount = await prisma.task.count();
  checks.push({
    name: 'Tasks',
    pass: true,
    detail: `${taskCount} tasks`,
  });

  // 18. Documents
  const documentCount = await prisma.document.count();
  checks.push({
    name: 'Documents',
    pass: true,
    detail: `${documentCount} documents`,
  });

  // 19. Maintenance schedules
  let maintenanceCount = 0;
  try {
    maintenanceCount = await (prisma as any).maintenanceSchedule?.count() ?? 0;
  } catch {
    // may not exist in schema
  }
  checks.push({
    name: 'Maintenance Schedules',
    pass: true,
    detail: `${maintenanceCount} schedules`,
  });

  // 20. Check household members (user-household links)
  const memberCount = await prisma.householdMember.count();
  checks.push({
    name: 'Household Members',
    pass: memberCount > 0,
    detail: `${memberCount} members linked`,
    error: memberCount === 0 ? 'No users linked to households' : undefined,
  });

  // Print results
  console.log('VERIFICATION RESULTS:\n');
  console.log('='.repeat(60));

  let passCount = 0;
  let failCount = 0;

  for (const check of checks) {
    const icon = check.pass ? 'PASS' : 'FAIL';
    const detail = check.detail ? ` (${check.detail})` : '';
    console.log(`  [${icon}] ${check.name}${detail}`);
    if (check.error) console.log(`         -> ${check.error}`);
    if (check.pass) passCount++;
    else failCount++;
  }

  console.log('\n' + '='.repeat(60));
  console.log(`\n  ${passCount}/${checks.length} checks passed, ${failCount} failed\n`);

  if (failCount === 0) {
    console.log('  STATUS: READY FOR BETA\n');
  } else {
    console.log('  STATUS: ISSUES FOUND - Review failures above\n');
  }

  await prisma.$disconnect();
}

verifyBetaReadiness().catch((e) => {
  console.error('Verification script failed:', e);
  prisma.$disconnect();
  process.exit(1);
});

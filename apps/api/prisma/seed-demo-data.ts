import { PrismaClient, DocumentCategory, BillCategory, BillingFrequency, DetectedBillStatus } from '@prisma/client';

const prisma = new PrismaClient();

async function seedDemoData() {
  console.log('🌱 Seeding demo data for Morrison household...\n');

  // Find Morrison household and Bob
  const bob = await prisma.user.findFirst({
    where: { email: 'bob@example.com' },
  });

  if (!bob) {
    console.error('❌ Bob user not found. Run main seed first.');
    return;
  }

  const membership = await prisma.householdMember.findFirst({
    where: { userId: bob.id },
    include: { household: true },
  });

  if (!membership) {
    console.error('❌ Bob has no household. Run main seed first.');
    return;
  }

  const householdId = membership.householdId;
  console.log(`Found household: ${membership.household.name} (${householdId})`);

  // =========================================================================
  // SEED DOCUMENTS
  // =========================================================================
  console.log('\n📄 Seeding documents...');

  const existingDocs = await prisma.document.count({ where: { householdId } });
  if (existingDocs > 0) {
    console.log(`  Already have ${existingDocs} documents, skipping...`);
  } else {
    const documents = [
      {
        householdId,
        uploadedById: bob.id,
        fileName: 'deed-38-bedford-rd.pdf',
        originalName: 'Property Deed - 38 Bedford Road.pdf',
        mimeType: 'application/pdf',
        fileSize: 245000,
        storageUrl: 'demo/deed-38-bedford-rd.pdf',
        storagePath: 'demo/deed-38-bedford-rd.pdf',
        category: DocumentCategory.PROPERTY,
        title: 'Property Deed',
        description: 'Warranty deed for 38 Bedford Road, Greenwich CT',
        tags: ['deed', 'property', 'legal'],
      },
      {
        householdId,
        uploadedById: bob.id,
        fileName: 'home-insurance-chubb.pdf',
        originalName: 'Chubb Home Insurance Policy.pdf',
        mimeType: 'application/pdf',
        fileSize: 890000,
        storageUrl: 'demo/home-insurance-chubb.pdf',
        storagePath: 'demo/home-insurance-chubb.pdf',
        category: DocumentCategory.INSURANCE,
        title: 'Home Insurance Policy',
        description: 'Chubb homeowners insurance - Policy #CHB-2024-Morrison',
        tags: ['insurance', 'home', 'chubb'],
        expiresAt: new Date('2025-06-15'),
      },
      {
        householdId,
        uploadedById: bob.id,
        fileName: 'auto-insurance-tesla.pdf',
        originalName: 'Tesla Model Y Insurance.pdf',
        mimeType: 'application/pdf',
        fileSize: 234000,
        storageUrl: 'demo/auto-insurance-tesla.pdf',
        storagePath: 'demo/auto-insurance-tesla.pdf',
        category: DocumentCategory.INSURANCE,
        title: 'Auto Insurance - Tesla Model Y',
        description: 'State Farm auto policy',
        tags: ['insurance', 'auto', 'tesla'],
        expiresAt: new Date('2025-03-01'),
      },
      {
        householdId,
        uploadedById: bob.id,
        fileName: 'hvac-warranty.pdf',
        originalName: 'Carrier HVAC Warranty.pdf',
        mimeType: 'application/pdf',
        fileSize: 123000,
        storageUrl: 'demo/hvac-warranty.pdf',
        storagePath: 'demo/hvac-warranty.pdf',
        category: DocumentCategory.WARRANTY,
        title: 'HVAC System Warranty',
        description: 'Carrier furnace and AC - 10 year parts warranty',
        tags: ['warranty', 'hvac', 'carrier'],
        expiresAt: new Date('2028-09-15'),
      },
      {
        householdId,
        uploadedById: bob.id,
        fileName: 'roof-warranty.pdf',
        originalName: 'GAF Roof Warranty.pdf',
        mimeType: 'application/pdf',
        fileSize: 189000,
        storageUrl: 'demo/roof-warranty.pdf',
        storagePath: 'demo/roof-warranty.pdf',
        category: DocumentCategory.WARRANTY,
        title: 'Roof Warranty',
        description: 'GAF Timberline HDZ - 25 year warranty',
        tags: ['warranty', 'roof'],
        expiresAt: new Date('2042-05-20'),
      },
      {
        householdId,
        uploadedById: bob.id,
        fileName: 'subzero-warranty.pdf',
        originalName: 'Sub-Zero Refrigerator Warranty.pdf',
        mimeType: 'application/pdf',
        fileSize: 98000,
        storageUrl: 'demo/subzero-warranty.pdf',
        storagePath: 'demo/subzero-warranty.pdf',
        category: DocumentCategory.WARRANTY,
        title: 'Sub-Zero Refrigerator Warranty',
        description: 'Sub-Zero 48" built-in - 5 year warranty',
        tags: ['warranty', 'appliance', 'subzero'],
        expiresAt: new Date('2026-11-10'),
      },
      {
        householdId,
        uploadedById: bob.id,
        fileName: 'pool-manual.pdf',
        originalName: 'Pool System Manual.pdf',
        mimeType: 'application/pdf',
        fileSize: 2340000,
        storageUrl: 'demo/pool-manual.pdf',
        storagePath: 'demo/pool-manual.pdf',
        category: DocumentCategory.MANUAL,
        title: 'Pool System Manual',
        description: 'Hayward pool pump, filter, and salt system',
        tags: ['manual', 'pool'],
      },
      {
        householdId,
        uploadedById: bob.id,
        fileName: 'generator-manual.pdf',
        originalName: 'Generac Generator Manual.pdf',
        mimeType: 'application/pdf',
        fileSize: 3450000,
        storageUrl: 'demo/generator-manual.pdf',
        storagePath: 'demo/generator-manual.pdf',
        category: DocumentCategory.MANUAL,
        title: 'Generac Generator Manual',
        description: '22kW whole house generator',
        tags: ['manual', 'generator'],
      },
      {
        householdId,
        uploadedById: bob.id,
        fileName: 'property-tax-2024.pdf',
        originalName: '2024 Property Tax Bill.pdf',
        mimeType: 'application/pdf',
        fileSize: 156000,
        storageUrl: 'demo/property-tax-2024.pdf',
        storagePath: 'demo/property-tax-2024.pdf',
        category: DocumentCategory.TAX,
        title: '2024 Property Tax Bill',
        description: 'Town of Greenwich property tax',
        tags: ['tax', 'property'],
      },
      {
        householdId,
        uploadedById: bob.id,
        fileName: 'landscaping-contract.pdf',
        originalName: 'Greenwich Landscaping Contract.pdf',
        mimeType: 'application/pdf',
        fileSize: 234000,
        storageUrl: 'demo/landscaping-contract.pdf',
        storagePath: 'demo/landscaping-contract.pdf',
        category: DocumentCategory.CONTRACT,
        title: 'Landscaping Service Contract',
        description: 'Weekly lawn maintenance',
        tags: ['contract', 'landscaping'],
        expiresAt: new Date('2025-12-31'),
      },
      {
        householdId,
        uploadedById: bob.id,
        fileName: 'pool-service-contract.pdf',
        originalName: 'Crystal Clear Pools Contract.pdf',
        mimeType: 'application/pdf',
        fileSize: 178000,
        storageUrl: 'demo/pool-service-contract.pdf',
        storagePath: 'demo/pool-service-contract.pdf',
        category: DocumentCategory.CONTRACT,
        title: 'Pool Service Contract',
        description: 'Weekly maintenance April-October',
        tags: ['contract', 'pool'],
        expiresAt: new Date('2025-10-31'),
      },
      {
        householdId,
        uploadedById: bob.id,
        fileName: 'nanny-agreement.pdf',
        originalName: 'Maria Garcia Employment Agreement.pdf',
        mimeType: 'application/pdf',
        fileSize: 145000,
        storageUrl: 'demo/nanny-agreement.pdf',
        storagePath: 'demo/nanny-agreement.pdf',
        category: DocumentCategory.CONTRACT,
        title: 'Nanny Employment Agreement',
        description: 'Maria Garcia - Greenwich Elite Nannies',
        tags: ['contract', 'childcare', 'employment'],
      },
    ];

    for (const doc of documents) {
      await prisma.document.create({ data: doc });
    }
    console.log(`  ✅ Created ${documents.length} documents`);
  }

  // =========================================================================
  // SEED PLAID CONNECTIONS & BILLS
  // =========================================================================
  console.log('\n🏦 Seeding Plaid connections...');

  const existingConnections = await prisma.plaidConnection.count({ where: { householdId } });
  if (existingConnections > 0) {
    console.log(`  Already have ${existingConnections} connections, skipping...`);
  } else {
    // Create Chase connection
    const chase = await prisma.plaidConnection.create({
      data: {
        householdId,
        accessToken: 'demo-access-token-chase',
        itemId: 'demo-item-chase',
        institutionId: 'ins_3',
        institutionName: 'Chase',
        status: 'ACTIVE',
        lastSyncedAt: new Date(),
      },
    });

    // Create Chase accounts
    const chaseChecking = await prisma.plaidAccount.create({
      data: {
        connectionId: chase.id,
        plaidAccountId: 'demo-chase-checking',
        name: 'Chase Total Checking',
        officialName: 'TOTAL CHECKING',
        type: 'depository',
        subtype: 'checking',
        mask: '4823',
        currentBalance: 45678.92,
        availableBalance: 44500.0,
      },
    });

    await prisma.plaidAccount.create({
      data: {
        connectionId: chase.id,
        plaidAccountId: 'demo-chase-savings',
        name: 'Chase Savings',
        officialName: 'CHASE SAVINGS',
        type: 'depository',
        subtype: 'savings',
        mask: '9156',
        currentBalance: 125000.0,
        availableBalance: 125000.0,
      },
    });

    // Create Bank of America connection
    const boa = await prisma.plaidConnection.create({
      data: {
        householdId,
        accessToken: 'demo-access-token-boa',
        itemId: 'demo-item-boa',
        institutionId: 'ins_1',
        institutionName: 'Bank of America',
        status: 'ACTIVE',
        lastSyncedAt: new Date(),
      },
    });

    const boaCC = await prisma.plaidAccount.create({
      data: {
        connectionId: boa.id,
        plaidAccountId: 'demo-boa-cc',
        name: 'Customized Cash Rewards',
        officialName: 'CUSTOMIZED CASH REWARDS VISA',
        type: 'credit',
        subtype: 'credit card',
        mask: '7721',
        currentBalance: 4523.67,
      },
    });

    console.log('  ✅ Created 2 bank connections with 3 accounts');

    // =========================================================================
    // SEED DETECTED BILLS
    // =========================================================================
    console.log('\n💵 Seeding detected bills...');

    interface BillData {
      accountId: string;
      merchantName: string;
      category: BillCategory;
      amount: number;
      frequency: BillingFrequency;
      day: number | null;
      status: DetectedBillStatus;
      detectionType?: string;
      checkPayee?: string;
    }

    const bills: BillData[] = [
      // Monthly bills from checking
      { accountId: chaseChecking.id, merchantName: 'Chase Mortgage', category: BillCategory.MORTGAGE, amount: 8500, frequency: 'MONTHLY', day: 1, status: 'CONFIRMED' },
      { accountId: chaseChecking.id, merchantName: 'Chubb Insurance', category: BillCategory.HOME_INSURANCE, amount: 450, frequency: 'MONTHLY', day: 15, status: 'CONFIRMED' },
      { accountId: chaseChecking.id, merchantName: 'Eversource Electric', category: BillCategory.ELECTRIC, amount: 380, frequency: 'MONTHLY', day: 18, status: 'CONFIRMED' },
      { accountId: chaseChecking.id, merchantName: 'Eversource Gas', category: BillCategory.GAS, amount: 180, frequency: 'MONTHLY', day: 18, status: 'CONFIRMED' },
      { accountId: chaseChecking.id, merchantName: 'Aquarion Water', category: BillCategory.WATER_SEWER, amount: 85, frequency: 'MONTHLY', day: 10, status: 'CONFIRMED' },
      { accountId: chaseChecking.id, merchantName: 'Optimum', category: BillCategory.INTERNET, amount: 120, frequency: 'MONTHLY', day: 5, status: 'CONFIRMED' },
      { accountId: chaseChecking.id, merchantName: 'Verizon Wireless', category: BillCategory.CELL_PHONE, amount: 280, frequency: 'MONTHLY', day: 22, status: 'CONFIRMED' },
      { accountId: chaseChecking.id, merchantName: 'ADT Security', category: BillCategory.SECURITY_MONITORING, amount: 65, frequency: 'MONTHLY', day: 1, status: 'CONFIRMED' },
      { accountId: chaseChecking.id, merchantName: 'Greenwich Country Day School', category: BillCategory.SCHOOL_TUITION, amount: 4500, frequency: 'MONTHLY', day: 1, status: 'CONFIRMED' },

      // Quarterly
      { accountId: chaseChecking.id, merchantName: 'Town of Greenwich Tax', category: BillCategory.PROPERTY_TAX, amount: 6300, frequency: 'QUARTERLY', day: 1, status: 'CONFIRMED' },

      // Credit card subscriptions
      { accountId: boaCC.id, merchantName: 'Netflix', category: BillCategory.STREAMING_SERVICE, amount: 22.99, frequency: 'MONTHLY', day: 15, status: 'CONFIRMED' },
      { accountId: boaCC.id, merchantName: 'Spotify', category: BillCategory.STREAMING_SERVICE, amount: 16.99, frequency: 'MONTHLY', day: 8, status: 'CONFIRMED' },
      { accountId: boaCC.id, merchantName: 'Disney+', category: BillCategory.STREAMING_SERVICE, amount: 13.99, frequency: 'MONTHLY', day: 20, status: 'CONFIRMED' },

      // Check payments (for checkbook.io demo)
      { accountId: chaseChecking.id, merchantName: 'Greenwich Landscaping LLC', category: BillCategory.LAWN_LANDSCAPE, amount: 800, frequency: 'MONTHLY', day: 1, status: 'CONFIRMED', detectionType: 'RECURRING_CHECK', checkPayee: 'Greenwich Landscaping LLC' },
      { accountId: chaseChecking.id, merchantName: 'Maria Garcia', category: BillCategory.NANNY, amount: 1500, frequency: 'WEEKLY', day: null, status: 'CONFIRMED', detectionType: 'RECURRING_CHECK', checkPayee: 'Maria Garcia' },
      { accountId: chaseChecking.id, merchantName: 'Crystal Clear Pools', category: BillCategory.POOL_SERVICE, amount: 350, frequency: 'MONTHLY', day: 1, status: 'CONFIRMED', detectionType: 'RECURRING_CHECK', checkPayee: 'Crystal Clear Pools' },
      { accountId: chaseChecking.id, merchantName: 'Ana Rodriguez Cleaning', category: BillCategory.HOUSE_CLEANING, amount: 300, frequency: 'BIWEEKLY', day: null, status: 'CONFIRMED', detectionType: 'RECURRING_CHECK', checkPayee: 'Ana Rodriguez' },

      // Pending bill for demo
      { accountId: boaCC.id, merchantName: 'Equinox Greenwich', category: BillCategory.GYM_FITNESS, amount: 295, frequency: 'MONTHLY', day: 1, status: 'PENDING' },
    ];

    for (const bill of bills) {
      const now = new Date();
      const lastTx = new Date(now);
      lastTx.setDate(bill.day || 15);
      if (lastTx > now) lastTx.setMonth(lastTx.getMonth() - 1);

      const nextTx = new Date(lastTx);
      if (bill.frequency === 'MONTHLY') nextTx.setMonth(nextTx.getMonth() + 1);
      else if (bill.frequency === 'WEEKLY') nextTx.setDate(nextTx.getDate() + 7);
      else if (bill.frequency === 'BIWEEKLY') nextTx.setDate(nextTx.getDate() + 14);
      else if (bill.frequency === 'QUARTERLY') nextTx.setMonth(nextTx.getMonth() + 3);

      await prisma.detectedBill.create({
        data: {
          householdId,
          accountId: bill.accountId,
          detectionType: bill.detectionType || 'RECURRING_CHARGE',
          merchantName: bill.merchantName,
          normalizedName: bill.merchantName.toLowerCase().replace(/[^a-z0-9]/g, ''),
          category: bill.category,
          checkPayee: bill.checkPayee || null,
          averageAmount: bill.amount,
          lastAmount: bill.amount,
          frequency: bill.frequency,
          lastTransactionDate: lastTx,
          nextExpectedDate: nextTx,
          dayOfMonth: bill.day,
          status: bill.status,
          transactionCount: bill.frequency === 'WEEKLY' ? 52 : bill.frequency === 'BIWEEKLY' ? 26 : 12,
          transactionIds: [],
        },
      });
    }

    console.log(`  ✅ Created ${bills.length} detected bills`);
  }

  console.log('\n✅ Demo data seeding complete!');
}

seedDemoData()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });

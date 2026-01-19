/**
 * Migration script to generate Alfred email codes for existing households
 * Run with: npx ts-node prisma/migrate-alfred-emails.ts
 */
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

/**
 * Generate a memorable email code from a street address
 */
function generateAlfredEmailCode(addressLine1: string): string {
  if (!addressLine1) return '';

  // Remove special characters except spaces, keep letters and numbers
  const cleaned = addressLine1.replace(/[^a-zA-Z0-9\s]/g, '');

  // Split into words, capitalize each, join without spaces
  const code = cleaned
    .split(/\s+/)
    .filter((word) => word.length > 0)
    .map((word) => word.charAt(0).toUpperCase() + word.slice(1).toLowerCase())
    .join('');

  return code;
}

/**
 * Generate unique code, adding suffix if duplicate exists
 */
async function generateUniqueAlfredEmailCode(
  addressLine1: string,
): Promise<string> {
  const baseCode = generateAlfredEmailCode(addressLine1);

  if (!baseCode) return '';

  // Check if this code already exists
  let code = baseCode;
  let suffix = 1;

  while (true) {
    const existing = await prisma.household.findUnique({
      where: { alfredEmailCode: code },
    });

    if (!existing) break;

    suffix++;
    code = `${baseCode}${suffix}`;
  }

  return code;
}

async function main() {
  console.log('Starting Alfred email code migration...\n');

  // Find all households without Alfred email codes
  const households = await prisma.household.findMany({
    where: { alfredEmailCode: null },
    include: { homeProfile: true },
  });

  console.log(`Found ${households.length} households without Alfred email codes.\n`);

  let updated = 0;
  let skipped = 0;

  for (const household of households) {
    const address = household.homeProfile?.addressLine1;

    if (!address) {
      console.log(`⚠️  Skipping "${household.name}" - no address found`);
      skipped++;
      continue;
    }

    const code = await generateUniqueAlfredEmailCode(address);

    if (!code) {
      console.log(`⚠️  Skipping "${household.name}" - could not generate code from "${address}"`);
      skipped++;
      continue;
    }

    await prisma.household.update({
      where: { id: household.id },
      data: { alfredEmailCode: code },
    });

    console.log(`✅ ${household.name}: ${code}@alfred.havenhome.dev`);
    updated++;
  }

  console.log('\n--- Migration Complete ---');
  console.log(`Updated: ${updated} households`);
  console.log(`Skipped: ${skipped} households`);
  console.log(`Total: ${households.length} households`);
}

main()
  .catch((e) => {
    console.error('Migration failed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });

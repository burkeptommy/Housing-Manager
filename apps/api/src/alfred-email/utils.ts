import { PrismaService } from '../prisma/prisma.service';

/**
 * Generate a memorable email code from a street address
 * Examples:
 *   "38 Bedford Road" -> "38BedfordRoad"
 *   "146 Putnam Park" -> "146PutnamPark"
 *   "1200 Sunset Blvd" -> "1200SunsetBlvd"
 */
export function generateAlfredEmailCode(addressLine1: string): string {
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
 * Generate a human-readable case number
 * Format: ALF-{YYYY}-{NNNNNN}
 * Example: ALF-2026-000042
 */
export async function generateCaseNumber(
  prisma: PrismaService,
): Promise<string> {
  const year = new Date().getFullYear();

  // Get the highest case number for this year
  const lastCase = await prisma.emailCase.findFirst({
    where: {
      caseNumber: {
        startsWith: `ALF-${year}-`,
      },
    },
    orderBy: {
      caseNumber: 'desc',
    },
  });

  let nextNumber = 1;
  if (lastCase) {
    const lastNumber = parseInt(lastCase.caseNumber.split('-')[2], 10);
    nextNumber = lastNumber + 1;
  }

  return `ALF-${year}-${nextNumber.toString().padStart(6, '0')}`;
}

/**
 * Generate unique code, adding suffix if duplicate exists
 * Examples:
 *   "38BedfordRoad" (first)
 *   "38BedfordRoad2" (if duplicate)
 */
export async function generateUniqueAlfredEmailCode(
  prisma: PrismaService,
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

/**
 * Generate codes for existing households (one-time migration utility)
 * Can be run as part of seed or migration script
 */
export async function generateCodesForExistingHouseholds(
  prisma: PrismaService,
): Promise<void> {
  const households = await prisma.household.findMany({
    where: { alfredEmailCode: null },
    include: { homeProfile: true },
  });

  for (const household of households) {
    const address = household.homeProfile?.addressLine1;
    if (address) {
      const code = await generateUniqueAlfredEmailCode(prisma, address);
      await prisma.household.update({
        where: { id: household.id },
        data: { alfredEmailCode: code },
      });
      console.log(`Generated Alfred email code for ${household.name}: ${code}`);
    }
  }
}

/**
 * Setup Sarah Script
 *
 * Creates or updates Sarah Chen (Home Manager) in both Firebase Auth and the database.
 *
 * Usage:
 *   pnpm setup-sarah
 *
 * Environment variables required:
 *   - DATABASE_URL: PostgreSQL connection string
 *   - FIREBASE_SERVICE_ACCOUNT: JSON string of Firebase service account credentials
 *     (or FIREBASE_PROJECT_ID + FIREBASE_CLIENT_EMAIL + FIREBASE_PRIVATE_KEY)
 */

import { PrismaClient, UserRole } from '@prisma/client';
import * as admin from 'firebase-admin';
import * as dotenv from 'dotenv';
import * as path from 'path';

// Load environment variables
dotenv.config({ path: path.join(__dirname, '../.env.local') });
dotenv.config({ path: path.join(__dirname, '../.env') });

const prisma = new PrismaClient();

// Sarah's configuration
const SARAH_CONFIG = {
  email: 'sarah@haven.app',
  password: 'SarahManager2024!',
  displayName: 'Sarah Chen',
  firstName: 'Sarah',
  lastName: 'Chen',
};

/**
 * Initialize Firebase Admin SDK
 */
function initializeFirebase(): void {
  if (admin.apps.length > 0) {
    console.log('✅ Firebase already initialized');
    return;
  }

  // Try FIREBASE_SERVICE_ACCOUNT JSON first
  const serviceAccountJson = process.env.FIREBASE_SERVICE_ACCOUNT;
  if (serviceAccountJson) {
    try {
      const serviceAccount = JSON.parse(serviceAccountJson);
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
      });
      console.log(`✅ Firebase initialized with service account for project: ${serviceAccount.project_id}`);
      return;
    } catch (e) {
      console.warn('⚠️  Failed to parse FIREBASE_SERVICE_ACCOUNT, trying individual vars...');
    }
  }

  // Try individual environment variables
  const projectId = process.env.FIREBASE_PROJECT_ID;
  const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
  const privateKey = process.env.FIREBASE_PRIVATE_KEY;

  if (projectId && clientEmail && privateKey) {
    admin.initializeApp({
      credential: admin.credential.cert({
        projectId,
        clientEmail,
        privateKey: privateKey.replace(/\\n/g, '\n'),
      }),
    });
    console.log(`✅ Firebase initialized for project: ${projectId}`);
    return;
  }

  // Fallback to application default credentials (works on GCP)
  try {
    admin.initializeApp();
    console.log('✅ Firebase initialized with application default credentials');
  } catch (e) {
    console.error('❌ Failed to initialize Firebase. Please set FIREBASE_SERVICE_ACCOUNT or run on GCP.');
    throw e;
  }
}

/**
 * Create or update Firebase Auth user
 */
async function createFirebaseUser(): Promise<string> {
  console.log(`\n📧 Setting up Firebase user: ${SARAH_CONFIG.email}`);

  try {
    // Check if user already exists
    const existingUser = await admin.auth().getUserByEmail(SARAH_CONFIG.email);
    console.log(`   User already exists with UID: ${existingUser.uid}`);

    // Update password and display name
    await admin.auth().updateUser(existingUser.uid, {
      password: SARAH_CONFIG.password,
      displayName: SARAH_CONFIG.displayName,
      emailVerified: true,
    });
    console.log('   ✅ Updated existing Firebase user');

    return existingUser.uid;
  } catch (error: any) {
    if (error.code === 'auth/user-not-found') {
      // Create new user
      const newUser = await admin.auth().createUser({
        email: SARAH_CONFIG.email,
        password: SARAH_CONFIG.password,
        displayName: SARAH_CONFIG.displayName,
        emailVerified: true,
      });
      console.log(`   ✅ Created new Firebase user with UID: ${newUser.uid}`);
      return newUser.uid;
    }
    throw error;
  }
}

/**
 * Upsert database user with Prisma
 */
async function upsertDatabaseUser(firebaseUid: string): Promise<void> {
  console.log(`\n💾 Setting up database user...`);

  const user = await prisma.user.upsert({
    where: { email: SARAH_CONFIG.email },
    update: {
      firebaseUid,
      displayName: SARAH_CONFIG.displayName,
      firstName: SARAH_CONFIG.firstName,
      lastName: SARAH_CONFIG.lastName,
      role: UserRole.MANAGER,
    },
    create: {
      email: SARAH_CONFIG.email,
      firebaseUid,
      displayName: SARAH_CONFIG.displayName,
      firstName: SARAH_CONFIG.firstName,
      lastName: SARAH_CONFIG.lastName,
      role: UserRole.MANAGER,
    },
  });

  console.log(`   ✅ Database user created/updated with ID: ${user.id}`);
  console.log(`   Role: ${user.role}`);
}

/**
 * Main entry point
 */
async function main() {
  console.log('╔════════════════════════════════════════════════════════════╗');
  console.log('║              Haven Home Manager Setup Script               ║');
  console.log('╚════════════════════════════════════════════════════════════╝\n');

  try {
    // Initialize Firebase
    initializeFirebase();

    // Create/update Firebase user
    const firebaseUid = await createFirebaseUser();

    // Upsert database user
    await upsertDatabaseUser(firebaseUid);

    // Print success summary
    console.log('\n╔════════════════════════════════════════════════════════════╗');
    console.log('║                    ✅ SUCCESS!                             ║');
    console.log('╚════════════════════════════════════════════════════════════╝\n');
    console.log('Sarah Chen account created successfully!\n');
    console.log('┌─────────────────────────────────────────────────────────────┐');
    console.log('│  Login Credentials                                          │');
    console.log('├─────────────────────────────────────────────────────────────┤');
    console.log(`│  Email:     ${SARAH_CONFIG.email.padEnd(44)}│`);
    console.log(`│  Password:  ${SARAH_CONFIG.password.padEnd(44)}│`);
    console.log('├─────────────────────────────────────────────────────────────┤');
    console.log('│  Manager Portal: https://havenhome.dev/manager              │');
    console.log('└─────────────────────────────────────────────────────────────┘\n');
  } catch (error) {
    console.error('\n❌ Setup failed:', error);
    process.exit(1);
  } finally {
    await prisma.$disconnect();
  }
}

main();

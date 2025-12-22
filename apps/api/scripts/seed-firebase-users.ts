/**
 * Seed demo users to production Firebase Authentication
 *
 * Run with: npx ts-node scripts/seed-firebase-users.ts
 */

import * as admin from 'firebase-admin';

// Initialize Firebase Admin with service account from environment or GCP
const initializeFirebase = async () => {
  // Try to get service account from environment variable first
  const serviceAccountJson = process.env.FIREBASE_SERVICE_ACCOUNT;

  if (serviceAccountJson) {
    const serviceAccount = JSON.parse(serviceAccountJson);
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
  } else {
    // Use application default credentials (works on GCP)
    admin.initializeApp({
      credential: admin.credential.applicationDefault(),
      projectId: 'home-manager-480616',
    });
  }
};

// Demo users to create
const demoUsers = [
  // Homeowners
  { email: 'bob@example.com', password: 'Bob123!', displayName: 'Bob Morrison' },
  { email: 'alice@example.com', password: 'Alice123!', displayName: 'Alice Morrison' },

  // Manager
  { email: 'steve@haven.app', password: 'Manager123!', displayName: 'Steve Manager' },

  // Handymen
  { email: 'carlos@haven.app', password: 'Handy123!', displayName: 'Carlos Reyes' },
  { email: 'dave@haven.app', password: 'Handy123!', displayName: 'Mike Castellano' },
  { email: 'maria@haven.app', password: 'Handy123!', displayName: 'Maria Santos' },

  // Vendor
  { email: 'vendor@aceroofing.example.com', password: 'AceRoof123!', displayName: 'Mike Johnson' },

  // Admin
  { email: 'admin@haven.app', password: 'Admin123!', displayName: 'Admin User' },
];

const createOrUpdateUser = async (user: { email: string; password: string; displayName: string }) => {
  try {
    // Try to get existing user
    const existingUser = await admin.auth().getUserByEmail(user.email);
    console.log(`User ${user.email} already exists with UID: ${existingUser.uid}`);

    // Update password if needed
    await admin.auth().updateUser(existingUser.uid, {
      password: user.password,
      displayName: user.displayName,
    });
    console.log(`  Updated password and display name for ${user.email}`);
    return existingUser.uid;
  } catch (error: any) {
    if (error.code === 'auth/user-not-found') {
      // Create new user
      const newUser = await admin.auth().createUser({
        email: user.email,
        password: user.password,
        displayName: user.displayName,
        emailVerified: true,
      });
      console.log(`Created new user ${user.email} with UID: ${newUser.uid}`);
      return newUser.uid;
    }
    throw error;
  }
};

const main = async () => {
  console.log('Initializing Firebase Admin SDK...');
  await initializeFirebase();

  console.log('\nSeeding demo users to Firebase Authentication...\n');

  for (const user of demoUsers) {
    try {
      await createOrUpdateUser(user);
    } catch (error) {
      console.error(`Error processing user ${user.email}:`, error);
    }
  }

  console.log('\nDone! Demo users have been seeded to Firebase Authentication.');
  console.log('\nDemo Credentials:');
  console.log('================');
  demoUsers.forEach(u => {
    console.log(`  ${u.email} / ${u.password}`);
  });

  process.exit(0);
};

main().catch(console.error);

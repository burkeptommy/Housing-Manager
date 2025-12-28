/**
 * Haven E2E Test Suite
 *
 * Run: pnpm test:e2e
 * Or:  pnpm test:e2e:local
 * Or:  npx ts-node scripts/test-haven.ts [--local]
 */

import * as fs from 'fs';
import * as path from 'path';

// ==============================================================================
// AUTO-LOAD ENVIRONMENT VARIABLES
// ==============================================================================

function loadEnvFiles() {
  const envPaths = [
    path.join(process.cwd(), '.env'),
    path.join(process.cwd(), '.env.local'),
    path.join(process.cwd(), 'apps/web/.env.local'),
    path.join(process.cwd(), 'apps/web/.env'),
  ];

  for (const envPath of envPaths) {
    if (fs.existsSync(envPath)) {
      const content = fs.readFileSync(envPath, 'utf-8');
      for (const line of content.split('\n')) {
        const match = line.match(/^([^#][^=]*)=(.*)$/);
        if (match) {
          const key = match[1].trim();
          const value = match[2].trim().replace(/^["']|["']$/g, '');
          if (!process.env[key]) {
            process.env[key] = value;
          }
        }
      }
    }
  }
}

loadEnvFiles();

// ==============================================================================
// CONFIGURATION
// ==============================================================================

const isLocal = process.argv.includes('--local');
const API_URL = isLocal ? 'http://localhost:4000/api' : 'https://api.havenhome.dev/api';
const WEB_URL = isLocal ? 'http://localhost:3000' : 'https://havenhome.dev';

// Firebase Web API Key - auto-loaded from env files or set manually
const FIREBASE_API_KEY = process.env.FIREBASE_API_KEY ||
                         process.env.NEXT_PUBLIC_FIREBASE_API_KEY ||
                         'AIzaSyDeJGjktaIHmcybrOV4LZyBHiRS0G_BUaA';

// Test credentials
const CREDENTIALS = {
  admin: { email: 'tom@havenhome.dev', password: 'HavenAdmin2024!' },
  manager: { email: 'sarah@haven.app', password: 'SarahManager2024!' },
  homeowner: { email: 'bob@example.com', password: 'Bob123!' },
};

// Colors for terminal
const colors = {
  reset: '\x1b[0m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  cyan: '\x1b[36m',
};

// ==============================================================================
// TYPES
// ==============================================================================

interface TestResult {
  name: string;
  passed: boolean;
  error?: string;
  skipped?: boolean;
  duration?: number;
}

interface TestSuite {
  name: string;
  tests: TestResult[];
}

// ==============================================================================
// HELPERS
// ==============================================================================

async function getFirebaseToken(email: string, password: string): Promise<string | null> {
  if (!FIREBASE_API_KEY) {
    return null;
  }

  try {
    const response = await fetch(
      `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${FIREBASE_API_KEY}`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password, returnSecureToken: true }),
      }
    );

    const data = await response.json() as any;
    
    if (data.error) {
      console.log(`  ${colors.yellow}Firebase error for ${email}: ${data.error.message}${colors.reset}`);
      return null;
    }
    
    return data.idToken || null;
  } catch (error) {
    console.log(`  ${colors.yellow}Firebase request failed: ${error}${colors.reset}`);
    return null;
  }
}

async function apiRequest(
  method: string,
  endpoint: string,
  token?: string,
  body?: any
): Promise<{ status: number; data: any }> {
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
  };
  
  if (token) {
    headers['Authorization'] = `Bearer ${token}`;
  }

  try {
    const response = await fetch(`${API_URL}${endpoint}`, {
      method,
      headers,
      body: body ? JSON.stringify(body) : undefined,
    });

    let data;
    try {
      data = await response.json();
    } catch {
      data = null;
    }

    return { status: response.status, data };
  } catch (error: any) {
    return { status: 0, data: { error: error.message } };
  }
}

async function checkUrl(url: string): Promise<number> {
  try {
    const response = await fetch(url, { method: 'GET' });
    return response.status;
  } catch {
    return 0;
  }
}

function printHeader(title: string) {
  console.log('');
  console.log(`${colors.blue}${'═'.repeat(60)}${colors.reset}`);
  console.log(`${colors.blue}  ${title}${colors.reset}`);
  console.log(`${colors.blue}${'═'.repeat(60)}${colors.reset}`);
}

function printResult(result: TestResult) {
  const icon = result.skipped ? `${colors.yellow}○` : result.passed ? `${colors.green}✓` : `${colors.red}✗`;
  const status = result.skipped ? 'SKIP' : result.passed ? 'PASS' : 'FAIL';
  const duration = result.duration ? ` (${result.duration}ms)` : '';
  
  console.log(`  ${icon} ${result.name}${duration}${colors.reset}`);
  
  if (result.error && !result.skipped) {
    console.log(`    ${colors.red}Error: ${result.error}${colors.reset}`);
  } else if (result.skipped && result.error) {
    console.log(`    ${colors.yellow}Reason: ${result.error}${colors.reset}`);
  }
}

// ==============================================================================
// TEST FUNCTIONS
// ==============================================================================

async function testWebPages(): Promise<TestSuite> {
  const tests: TestResult[] = [];

  // Homepage
  let start = Date.now();
  let status = await checkUrl(WEB_URL);
  tests.push({
    name: 'Homepage loads',
    passed: status === 200,
    error: status !== 200 ? `HTTP ${status}` : undefined,
    duration: Date.now() - start,
  });

  // Login page
  start = Date.now();
  status = await checkUrl(`${WEB_URL}/login`);
  tests.push({
    name: 'Login page loads',
    passed: status === 200,
    error: status !== 200 ? `HTTP ${status}` : undefined,
    duration: Date.now() - start,
  });

  // Onboarding page
  start = Date.now();
  status = await checkUrl(`${WEB_URL}/onboarding`);
  tests.push({
    name: 'Onboarding page loads',
    passed: status === 200,
    error: status !== 200 ? `HTTP ${status}` : undefined,
    duration: Date.now() - start,
  });

  // App page (should redirect or show login)
  start = Date.now();
  status = await checkUrl(`${WEB_URL}/app`);
  tests.push({
    name: 'App page accessible',
    passed: status === 200 || status === 307 || status === 302,
    error: status === 0 ? 'Connection failed' : undefined,
    duration: Date.now() - start,
  });

  return { name: 'Web Pages', tests };
}

async function testApiHealth(): Promise<TestSuite> {
  const tests: TestResult[] = [];

  // Basic connectivity
  let start = Date.now();
  const { status } = await apiRequest('GET', '/user/me');
  tests.push({
    name: 'API is reachable',
    passed: status === 401 || status === 200, // 401 means API is up but needs auth
    error: status === 0 ? 'Connection failed' : (status !== 401 && status !== 200) ? `HTTP ${status}` : undefined,
    duration: Date.now() - start,
  });

  return { name: 'API Health', tests };
}

async function testAdminFlow(): Promise<TestSuite> {
  const tests: TestResult[] = [];

  if (!FIREBASE_API_KEY) {
    tests.push({
      name: 'Admin flow',
      passed: false,
      skipped: true,
      error: 'FIREBASE_API_KEY not set',
    });
    return { name: 'Admin Portal', tests };
  }

  // Login
  let start = Date.now();
  const token = await getFirebaseToken(CREDENTIALS.admin.email, CREDENTIALS.admin.password);
  tests.push({
    name: 'Admin Firebase login',
    passed: !!token,
    error: !token ? 'Could not get token' : undefined,
    duration: Date.now() - start,
  });

  if (!token) {
    return { name: 'Admin Portal', tests };
  }

  // /user/me
  start = Date.now();
  let response = await apiRequest('GET', '/user/me', token);
  const adminData = response.data?.user || response.data;
  const adminRole = adminData?.role;
  tests.push({
    name: 'GET /user/me returns admin role',
    passed: adminRole === 'ADMIN',
    error: adminRole !== 'ADMIN' ? `Role: ${adminRole || 'none'}, Status: ${response.status}` : undefined,
    duration: Date.now() - start,
  });

  // /admin/dashboard
  start = Date.now();
  response = await apiRequest('GET', '/admin/dashboard', token);
  tests.push({
    name: 'GET /admin/dashboard',
    passed: response.status === 200 && response.data?.overview !== undefined,
    error: response.status !== 200 ? `HTTP ${response.status}` : undefined,
    duration: Date.now() - start,
  });

  // /admin/users
  start = Date.now();
  response = await apiRequest('GET', '/admin/users', token);
  tests.push({
    name: 'GET /admin/users',
    passed: response.status === 200 && response.data?.users !== undefined,
    error: response.status !== 200 ? `HTTP ${response.status}` : undefined,
    duration: Date.now() - start,
  });

  // /admin/households
  start = Date.now();
  response = await apiRequest('GET', '/admin/households', token);
  tests.push({
    name: 'GET /admin/households',
    passed: response.status === 200 && response.data?.households !== undefined,
    error: response.status !== 200 ? `HTTP ${response.status}` : undefined,
    duration: Date.now() - start,
  });

  // /admin/onboarding
  start = Date.now();
  response = await apiRequest('GET', '/admin/onboarding', token);
  tests.push({
    name: 'GET /admin/onboarding',
    passed: response.status === 200,
    error: response.status !== 200 ? `HTTP ${response.status}` : undefined,
    duration: Date.now() - start,
  });

  return { name: 'Admin Portal', tests };
}

async function testManagerFlow(): Promise<TestSuite> {
  const tests: TestResult[] = [];

  if (!FIREBASE_API_KEY) {
    tests.push({
      name: 'Manager flow',
      passed: false,
      skipped: true,
      error: 'FIREBASE_API_KEY not set',
    });
    return { name: 'Manager Portal', tests };
  }

  // Login
  let start = Date.now();
  const token = await getFirebaseToken(CREDENTIALS.manager.email, CREDENTIALS.manager.password);
  tests.push({
    name: 'Manager Firebase login',
    passed: !!token,
    error: !token ? 'Could not get token' : undefined,
    duration: Date.now() - start,
  });

  if (!token) {
    return { name: 'Manager Portal', tests };
  }

  // /user/me
  start = Date.now();
  let response = await apiRequest('GET', '/user/me', token);
  const managerData = response.data?.user || response.data;
  const managerRole = managerData?.role;
  tests.push({
    name: 'GET /user/me returns manager role',
    passed: managerRole === 'MANAGER' || managerRole === 'HOME_MANAGER',
    error: !['MANAGER', 'HOME_MANAGER'].includes(managerRole) ? `Role: ${managerRole || 'none'}, Status: ${response.status}` : undefined,
    duration: Date.now() - start,
  });

  // /manager/dashboard
  start = Date.now();
  response = await apiRequest('GET', '/manager/dashboard', token);
  tests.push({
    name: 'GET /manager/dashboard',
    passed: response.status === 200,
    error: response.status !== 200 ? `HTTP ${response.status}: ${JSON.stringify(response.data).slice(0, 100)}` : undefined,
    duration: Date.now() - start,
  });

  // /manager/households
  start = Date.now();
  response = await apiRequest('GET', '/manager/households', token);
  tests.push({
    name: 'GET /manager/households',
    passed: response.status === 200,
    error: response.status !== 200 ? `HTTP ${response.status}` : undefined,
    duration: Date.now() - start,
  });

  // /manager/onboarding/queue
  start = Date.now();
  response = await apiRequest('GET', '/manager/onboarding/queue', token);
  tests.push({
    name: 'GET /manager/onboarding/queue',
    passed: response.status === 200,
    error: response.status !== 200 ? `HTTP ${response.status}` : undefined,
    duration: Date.now() - start,
  });

  // /manager/activity
  start = Date.now();
  response = await apiRequest('GET', '/manager/activity', token);
  tests.push({
    name: 'GET /manager/activity',
    passed: response.status === 200,
    error: response.status !== 200 ? `HTTP ${response.status}` : undefined,
    duration: Date.now() - start,
  });

  return { name: 'Manager Portal', tests };
}

async function testHomeownerFlow(): Promise<TestSuite> {
  const tests: TestResult[] = [];

  if (!FIREBASE_API_KEY) {
    tests.push({
      name: 'Homeowner flow',
      passed: false,
      skipped: true,
      error: 'FIREBASE_API_KEY not set',
    });
    return { name: 'Homeowner Portal', tests };
  }

  // Login
  let start = Date.now();
  const token = await getFirebaseToken(CREDENTIALS.homeowner.email, CREDENTIALS.homeowner.password);
  tests.push({
    name: 'Homeowner Firebase login',
    passed: !!token,
    error: !token ? 'Could not get token' : undefined,
    duration: Date.now() - start,
  });

  if (!token) {
    return { name: 'Homeowner Portal', tests };
  }

  // /user/me
  start = Date.now();
  let response = await apiRequest('GET', '/user/me', token);
  const userData = response.data?.user || response.data;
  const role = userData?.role;
  tests.push({
    name: 'GET /user/me returns homeowner role',
    passed: role === 'HOMEOWNER',
    error: role !== 'HOMEOWNER' ? `Role: ${role || 'none'}, Status: ${response.status}` : undefined,
    duration: Date.now() - start,
  });

  // Check for household - it can be in response.data.household.id or response.data.householdId
  const householdId = response.data?.household?.id || response.data?.householdId;

  if (!householdId) {
    tests.push({
      name: 'Homeowner has household assigned',
      passed: false,
      error: 'No household ID found - check household_members.status is ACTIVE',
    });
    return { name: 'Homeowner Portal', tests };
  }

  tests.push({
    name: 'Homeowner has household assigned',
    passed: true,
    duration: 0,
  });

  // /dashboard/household/:id
  start = Date.now();
  response = await apiRequest('GET', `/dashboard/household/${householdId}`, token);
  tests.push({
    name: 'GET /dashboard/household/:id',
    passed: response.status === 200,
    error: response.status !== 200 ? `HTTP ${response.status}` : undefined,
    duration: Date.now() - start,
  });

  // /property/household/:id
  start = Date.now();
  response = await apiRequest('GET', `/property/household/${householdId}`, token);
  tests.push({
    name: 'GET /property/household/:id',
    passed: response.status === 200,
    error: response.status !== 200 ? `HTTP ${response.status}` : undefined,
    duration: Date.now() - start,
  });

  // /family/household/:id
  start = Date.now();
  response = await apiRequest('GET', `/family/household/${householdId}`, token);
  tests.push({
    name: 'GET /family/household/:id',
    passed: response.status === 200,
    error: response.status !== 200 ? `HTTP ${response.status}` : undefined,
    duration: Date.now() - start,
  });

  return { name: 'Homeowner Portal', tests };
}

async function testApprovalSystem(): Promise<TestSuite> {
  const tests: TestResult[] = [];

  if (!FIREBASE_API_KEY) {
    tests.push({
      name: 'Approval system',
      passed: false,
      skipped: true,
      error: 'FIREBASE_API_KEY not set',
    });
    return { name: 'Approval System', tests };
  }

  // Get homeowner token
  let start = Date.now();
  const homeownerToken = await getFirebaseToken(CREDENTIALS.homeowner.email, CREDENTIALS.homeowner.password);
  if (!homeownerToken) {
    tests.push({
      name: 'Homeowner login for approvals',
      passed: false,
      error: 'Could not get homeowner token',
    });
    return { name: 'Approval System', tests };
  }

  // Get household ID from /user/me
  let response = await apiRequest('GET', '/user/me', homeownerToken);
  const householdId = response.data?.household?.id || response.data?.householdId;

  if (!householdId) {
    tests.push({
      name: 'Get household for approvals',
      passed: false,
      error: 'No household ID found',
    });
    return { name: 'Approval System', tests };
  }

  // Test homeowner approvals endpoint
  start = Date.now();
  response = await apiRequest('GET', `/approvals/household/${householdId}`, homeownerToken);
  tests.push({
    name: 'GET /approvals/household/:id',
    passed: response.status === 200 && Array.isArray(response.data),
    error: response.status !== 200 ? `HTTP ${response.status}` : undefined,
    duration: Date.now() - start,
  });

  // Test pending count endpoint
  start = Date.now();
  response = await apiRequest('GET', `/approvals/household/${householdId}/pending-count`, homeownerToken);
  tests.push({
    name: 'GET /approvals/household/:id/pending-count',
    passed: response.status === 200 && response.data?.count !== undefined,
    error: response.status !== 200 ? `HTTP ${response.status}` : undefined,
    duration: Date.now() - start,
  });

  // Get manager token
  const managerToken = await getFirebaseToken(CREDENTIALS.manager.email, CREDENTIALS.manager.password);
  if (!managerToken) {
    tests.push({
      name: 'Manager login for approvals',
      passed: false,
      error: 'Could not get manager token',
    });
    return { name: 'Approval System', tests };
  }

  // Test manager approvals endpoint
  start = Date.now();
  response = await apiRequest('GET', '/approvals/manager/my-requests', managerToken);
  tests.push({
    name: 'GET /approvals/manager/my-requests',
    passed: response.status === 200 && Array.isArray(response.data),
    error: response.status !== 200 ? `HTTP ${response.status}` : undefined,
    duration: Date.now() - start,
  });

  return { name: 'Approval System', tests };
}

async function testMaintenanceCalendar(): Promise<TestSuite> {
  const tests: TestResult[] = [];

  if (!FIREBASE_API_KEY) {
    tests.push({
      name: 'Maintenance calendar',
      passed: false,
      skipped: true,
      error: 'FIREBASE_API_KEY not set',
    });
    return { name: 'Maintenance Calendar', tests };
  }

  // Get homeowner token
  let start = Date.now();
  const homeownerToken = await getFirebaseToken(CREDENTIALS.homeowner.email, CREDENTIALS.homeowner.password);
  if (!homeownerToken) {
    tests.push({
      name: 'Homeowner login for maintenance',
      passed: false,
      error: 'Could not get homeowner token',
    });
    return { name: 'Maintenance Calendar', tests };
  }

  // Get household ID from /user/me
  let response = await apiRequest('GET', '/user/me', homeownerToken);
  const householdId = response.data?.household?.id || response.data?.householdId;

  if (!householdId) {
    tests.push({
      name: 'Get household for maintenance',
      passed: false,
      error: 'No household ID found',
    });
    return { name: 'Maintenance Calendar', tests };
  }

  // Test maintenance tasks endpoint
  start = Date.now();
  response = await apiRequest('GET', `/maintenance/household/${householdId}`, homeownerToken);
  tests.push({
    name: 'GET /maintenance/household/:id',
    passed: response.status === 200 && Array.isArray(response.data),
    error: response.status !== 200 ? `HTTP ${response.status}` : undefined,
    duration: Date.now() - start,
  });

  // Test maintenance summary endpoint
  start = Date.now();
  response = await apiRequest('GET', `/maintenance/household/${householdId}/summary`, homeownerToken);
  tests.push({
    name: 'GET /maintenance/household/:id/summary',
    passed: response.status === 200 && response.data?.total !== undefined,
    error: response.status !== 200 ? `HTTP ${response.status}` : undefined,
    duration: Date.now() - start,
  });

  // Test maintenance calendar endpoint
  start = Date.now();
  response = await apiRequest('GET', `/maintenance/household/${householdId}/calendar`, homeownerToken);
  tests.push({
    name: 'GET /maintenance/household/:id/calendar',
    passed: response.status === 200 && typeof response.data === 'object',
    error: response.status !== 200 ? `HTTP ${response.status}` : undefined,
    duration: Date.now() - start,
  });

  return { name: 'Maintenance Calendar', tests };
}

async function testDocumentVault(): Promise<TestSuite> {
  const tests: TestResult[] = [];

  if (!FIREBASE_API_KEY) {
    tests.push({
      name: 'Document vault',
      passed: false,
      skipped: true,
      error: 'FIREBASE_API_KEY not set',
    });
    return { name: 'Document Vault', tests };
  }

  // Get homeowner token
  let start = Date.now();
  const homeownerToken = await getFirebaseToken(CREDENTIALS.homeowner.email, CREDENTIALS.homeowner.password);
  if (!homeownerToken) {
    tests.push({
      name: 'Homeowner login for documents',
      passed: false,
      error: 'Could not get homeowner token',
    });
    return { name: 'Document Vault', tests };
  }

  // Get household ID from /user/me
  let response = await apiRequest('GET', '/user/me', homeownerToken);
  const householdId = response.data?.household?.id || response.data?.householdId;

  if (!householdId) {
    tests.push({
      name: 'Get household for documents',
      passed: false,
      error: 'No household ID found',
    });
    return { name: 'Document Vault', tests };
  }

  // Test documents list endpoint
  start = Date.now();
  response = await apiRequest('GET', `/documents/household/${householdId}`, homeownerToken);
  tests.push({
    name: 'GET /documents/household/:id',
    passed: response.status === 200 && Array.isArray(response.data),
    error: response.status !== 200 ? `HTTP ${response.status}` : undefined,
    duration: Date.now() - start,
  });

  // Test documents summary endpoint
  start = Date.now();
  response = await apiRequest('GET', `/documents/household/${householdId}/summary`, homeownerToken);
  tests.push({
    name: 'GET /documents/household/:id/summary',
    passed: response.status === 200 && response.data?.total !== undefined,
    error: response.status !== 200 ? `HTTP ${response.status}` : undefined,
    duration: Date.now() - start,
  });

  return { name: 'Document Vault', tests };
}

async function testDataIntegrity(): Promise<TestSuite> {
  const tests: TestResult[] = [];

  if (!FIREBASE_API_KEY) {
    tests.push({
      name: 'Data integrity',
      passed: false,
      skipped: true,
      error: 'FIREBASE_API_KEY not set',
    });
    return { name: 'Data Integrity', tests };
  }

  // Get admin token
  const token = await getFirebaseToken(CREDENTIALS.admin.email, CREDENTIALS.admin.password);
  
  if (!token) {
    tests.push({
      name: 'Data integrity checks',
      passed: false,
      skipped: true,
      error: 'Could not get admin token',
    });
    return { name: 'Data Integrity', tests };
  }

  // Check Morrison household exists
  let start = Date.now();
  let response = await apiRequest('GET', '/admin/households?search=Morrison', token);
  const hasMorrison = JSON.stringify(response.data).toLowerCase().includes('morrison');
  tests.push({
    name: 'Morrison demo household exists',
    passed: hasMorrison,
    error: !hasMorrison ? 'Morrison household not found' : undefined,
    duration: Date.now() - start,
  });

  // Check property address
  start = Date.now();
  const hasBedford = JSON.stringify(response.data).toLowerCase().includes('bedford');
  tests.push({
    name: '38 Bedford Road property exists',
    passed: hasBedford,
    error: !hasBedford ? 'Bedford Road address not found' : undefined,
    duration: Date.now() - start,
  });

  // Check Sarah exists
  start = Date.now();
  response = await apiRequest('GET', '/admin/users?search=sarah', token);
  const hasSarah = JSON.stringify(response.data).toLowerCase().includes('sarah');
  tests.push({
    name: 'Sarah Chen exists',
    passed: hasSarah,
    error: !hasSarah ? 'Sarah not found' : undefined,
    duration: Date.now() - start,
  });

  return { name: 'Data Integrity', tests };
}

// ==============================================================================
// MAIN
// ==============================================================================

async function main() {
  console.log('');
  console.log(`${colors.cyan}╔════════════════════════════════════════════════════════════╗${colors.reset}`);
  console.log(`${colors.cyan}║           HAVEN END-TO-END TEST SUITE                      ║${colors.reset}`);
  console.log(`${colors.cyan}╚════════════════════════════════════════════════════════════╝${colors.reset}`);
  console.log('');
  console.log(`Environment: ${isLocal ? 'LOCAL' : 'PRODUCTION'}`);
  console.log(`API URL: ${API_URL}`);
  console.log(`Web URL: ${WEB_URL}`);
  console.log(`Firebase API Key: ${FIREBASE_API_KEY ? '✓ Set' : '✗ Not set'}`);
  
  if (!FIREBASE_API_KEY) {
    console.log('');
    console.log(`${colors.yellow}⚠ Set FIREBASE_API_KEY to run authentication tests:${colors.reset}`);
    console.log(`  export FIREBASE_API_KEY=your-api-key`);
    console.log(`  (Get from Firebase Console → Project Settings → Web API Key)`);
  }

  const suites: TestSuite[] = [];

  // Run all test suites
  printHeader('Web Pages');
  const webSuite = await testWebPages();
  webSuite.tests.forEach(printResult);
  suites.push(webSuite);

  printHeader('API Health');
  const healthSuite = await testApiHealth();
  healthSuite.tests.forEach(printResult);
  suites.push(healthSuite);

  printHeader('Admin Portal');
  const adminSuite = await testAdminFlow();
  adminSuite.tests.forEach(printResult);
  suites.push(adminSuite);

  printHeader('Manager Portal');
  const managerSuite = await testManagerFlow();
  managerSuite.tests.forEach(printResult);
  suites.push(managerSuite);

  printHeader('Homeowner Portal');
  const homeownerSuite = await testHomeownerFlow();
  homeownerSuite.tests.forEach(printResult);
  suites.push(homeownerSuite);

  printHeader('Approval System');
  const approvalSuite = await testApprovalSystem();
  approvalSuite.tests.forEach(printResult);
  suites.push(approvalSuite);

  printHeader('Maintenance Calendar');
  const maintenanceSuite = await testMaintenanceCalendar();
  maintenanceSuite.tests.forEach(printResult);
  suites.push(maintenanceSuite);

  printHeader('Document Vault');
  const documentSuite = await testDocumentVault();
  documentSuite.tests.forEach(printResult);
  suites.push(documentSuite);

  printHeader('Data Integrity');
  const dataSuite = await testDataIntegrity();
  dataSuite.tests.forEach(printResult);
  suites.push(dataSuite);

  // Summary
  printHeader('Test Summary');

  let totalPassed = 0;
  let totalFailed = 0;
  let totalSkipped = 0;

  for (const suite of suites) {
    for (const test of suite.tests) {
      if (test.skipped) totalSkipped++;
      else if (test.passed) totalPassed++;
      else totalFailed++;
    }
  }

  console.log('');
  console.log(`  ${colors.green}Passed:  ${totalPassed}${colors.reset}`);
  console.log(`  ${colors.red}Failed:  ${totalFailed}${colors.reset}`);
  console.log(`  ${colors.yellow}Skipped: ${totalSkipped}${colors.reset}`);
  console.log('');

  const total = totalPassed + totalFailed;
  if (total > 0) {
    const percent = Math.round((totalPassed / total) * 100);
    console.log(`  Pass Rate: ${percent}%`);
  }

  console.log('');

  if (totalFailed > 0) {
    console.log(`${colors.red}Some tests failed. Check the output above for details.${colors.reset}`);
    process.exit(1);
  } else {
    console.log(`${colors.green}All tests passed!${colors.reset}`);
    process.exit(0);
  }
}

main().catch(console.error);

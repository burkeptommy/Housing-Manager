// ============================================================================
// HAVEN DEMO DATA - Central Export
// ============================================================================
// This is the main entry point for all demo data used across the Haven app

// Re-export all types
export * from './types';

// Re-export utility functions
export * from './utils';

// Re-export manager data
export {
  DEMO_MANAGER,
  DEMO_HANDYMEN,
  DEMO_VENDORS,
  DEMO_SCHEDULE,
  DEMO_ACTIVITY,
  DEMO_ACCOUNTS,
  DEMO_PERFORMANCE,
} from './manager-demo-data';

// Re-export household data
export {
  // Households
  DEMO_HOUSEHOLDS,

  // Smith Family (primary demo)
  SMITH_ADULTS,
  SMITH_CHILDREN,
  SMITH_PETS,
  SMITH_STAFF,
  SMITH_VEHICLES,
  SMITH_FAMILY,

  // Requests & Work Orders
  DEMO_REQUESTS,
  DEMO_WORK_ORDERS,

  // Tasks & Bills
  DEMO_TASKS,
  DEMO_BILLS,

  // Messages
  DEMO_MESSAGES,

  // Helper functions
  getHouseholdById,
  getRequestsByHousehold,
  getWorkOrdersByHousehold,
  getTasksByHousehold,
  getBillsByHousehold,
  getMessagesByHousehold,
  getPendingApprovals,
  getOverdueTasks,
  getUnreadMessagesCount,
  getBillsDueThisWeek,
} from './households-demo-data';

// ============================================================================
// QUICK STATS (computed at import time)
// ============================================================================

import { DEMO_HOUSEHOLDS, DEMO_REQUESTS, DEMO_WORK_ORDERS, DEMO_TASKS, DEMO_BILLS, DEMO_MESSAGES } from './households-demo-data';

export const DEMO_STATS = {
  totalHouseholds: DEMO_HOUSEHOLDS.length,
  activeRequests: DEMO_REQUESTS.filter(r => r.status !== 'COMPLETED' && r.status !== 'CANCELLED').length,
  pendingApprovals: DEMO_WORK_ORDERS.filter(wo => wo.status === 'AWAITING_APPROVAL').length,
  scheduledWorkOrders: DEMO_WORK_ORDERS.filter(wo => wo.status === 'SCHEDULED').length,
  overdueTasks: DEMO_TASKS.filter(t => t.status === 'OVERDUE').length,
  unreadMessages: DEMO_MESSAGES.filter(m => m.readAt === null).length,
  billsDueThisWeek: DEMO_BILLS.filter(b => {
    const weekFromNow = new Date(Date.now() + 7 * 86400000);
    return b.nextDue.dueDate <= weekFromNow && b.nextDue.dueDate >= new Date();
  }).length,
  householdsWithUrgentItems: DEMO_HOUSEHOLDS.filter(h => h.urgentItems > 0).length,
};

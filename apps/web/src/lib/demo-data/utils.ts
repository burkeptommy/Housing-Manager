// ============================================================================
// DEMO DATA UTILITY FUNCTIONS
// ============================================================================
// Helper functions for generating relative dates and common operations
// These ensure demo data always appears current

/**
 * Get a date that is N days from now (positive = future, negative = past)
 */
export const daysFromNow = (days: number): Date => {
  return new Date(Date.now() + days * 86400000);
};

/**
 * Get a date that is N days ago
 */
export const daysAgo = (days: number): Date => {
  return new Date(Date.now() - days * 86400000);
};

/**
 * Get a date that is N hours ago
 */
export const hoursAgo = (hours: number): Date => {
  return new Date(Date.now() - hours * 3600000);
};

/**
 * Get a date that is N minutes ago
 */
export const minutesAgo = (minutes: number): Date => {
  return new Date(Date.now() - minutes * 60000);
};

/**
 * Get a date that is N hours from now
 */
export const hoursFromNow = (hours: number): Date => {
  return new Date(Date.now() + hours * 3600000);
};

/**
 * Get a date that is N weeks from now
 */
export const weeksFromNow = (weeks: number): Date => {
  return daysFromNow(weeks * 7);
};

/**
 * Get a date that is N weeks ago
 */
export const weeksAgo = (weeks: number): Date => {
  return daysAgo(weeks * 7);
};

/**
 * Get a date that is N months from now (approximate)
 */
export const monthsFromNow = (months: number): Date => {
  return daysFromNow(months * 30);
};

/**
 * Get a date that is N months ago (approximate)
 */
export const monthsAgo = (months: number): Date => {
  return daysAgo(months * 30);
};

/**
 * Get today's date at a specific time
 */
export const todayAt = (hours: number, minutes: number = 0): Date => {
  const date = new Date();
  date.setHours(hours, minutes, 0, 0);
  return date;
};

/**
 * Get tomorrow's date at a specific time
 */
export const tomorrowAt = (hours: number, minutes: number = 0): Date => {
  const date = daysFromNow(1);
  date.setHours(hours, minutes, 0, 0);
  return date;
};

/**
 * Get the next occurrence of a specific day (0 = Sunday, 1 = Monday, etc.)
 */
export const nextDayOfWeek = (dayOfWeek: number): Date => {
  const today = new Date();
  const currentDay = today.getDay();
  const daysUntil = (dayOfWeek - currentDay + 7) % 7 || 7;
  return daysFromNow(daysUntil);
};

/**
 * Get the next Friday
 */
export const nextFriday = (): Date => nextDayOfWeek(5);

/**
 * Format a relative time string (e.g., "2 hours ago", "35 min ago")
 */
export const formatRelativeTime = (date: Date): string => {
  const now = Date.now();
  const diff = now - date.getTime();

  const minutes = Math.floor(diff / 60000);
  const hours = Math.floor(diff / 3600000);
  const days = Math.floor(diff / 86400000);

  if (minutes < 1) return 'just now';
  if (minutes < 60) return `${minutes}m ago`;
  if (hours < 24) return `${hours}h ago`;
  if (days === 1) return 'yesterday';
  if (days < 7) return `${days} days ago`;
  return date.toLocaleDateString();
};

/**
 * Get an absolute date from a string like "2023-03-15"
 */
export const parseDate = (dateString: string): Date => {
  return new Date(dateString);
};

/**
 * Generate a unique ID with a prefix
 */
export const generateId = (prefix: string): string => {
  return `${prefix}-${Math.random().toString(36).substring(2, 9)}`;
};

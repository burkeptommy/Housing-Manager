import { router } from 'expo-router';

/**
 * Navigate to Alfred (Manager tab), optionally with a pre-filled message
 *
 * @param context - Optional context to pre-fill in the chat input
 *
 * Usage:
 *   askAlfred() - Just opens Alfred tab
 *   askAlfred('Help me add a new zone') - Opens Alfred with pre-filled text
 *   askAlfred('Tell me about my Oil Furnace system') - Context about specific item
 */
export function askAlfred(context?: string) {
  // Always navigate to the main Manager/Alfred tab
  // Use push so back button works
  router.push({
    pathname: '/(tabs)/manager',
    params: context ? { prefill: context } : undefined,
  } as any);
}

/**
 * Navigate to Alfred with a specific maintenance task context
 */
export function askAlfredAboutTask(taskName: string) {
  askAlfred(`Help me with my "${taskName}" maintenance task`);
}

/**
 * Navigate to Alfred with a system/zone context
 */
export function askAlfredAboutSystem(systemName: string, zoneName?: string) {
  const context = zoneName
    ? `Tell me about the ${systemName} in my ${zoneName}`
    : `Tell me about my ${systemName}`;
  askAlfred(context);
}

/**
 * Navigate to Alfred for onboarding/setup help
 */
export function askAlfredForHelp(topic: string) {
  askAlfred(`Help me set up ${topic} for my home`);
}

/**
 * Navigate to Alfred for handyman requests
 */
export function askAlfredForHandyman() {
  askAlfred('I need help with a handyman task');
}

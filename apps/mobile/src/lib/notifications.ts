import * as Notifications from 'expo-notifications';
import * as Device from 'expo-device';
import Constants from 'expo-constants';
import { Platform } from 'react-native';
import { API_BASE_URL } from './api';
import { getIdToken } from './firebase';

// Flag to ensure we only configure once
let isNotificationHandlerConfigured = false;

/**
 * Configure notification handler - call this before using notifications
 * Wrapped in function to avoid module-level crash on import
 */
export function configureNotificationHandler(): void {
  if (isNotificationHandlerConfigured) return;

  try {
    Notifications.setNotificationHandler({
      handleNotification: async () => ({
        shouldShowAlert: true,
        shouldPlaySound: true,
        shouldSetBadge: true,
        shouldShowBanner: true,
        shouldShowList: true,
      }),
    });
    isNotificationHandlerConfigured = true;
  } catch (error) {
    console.warn('Failed to configure notification handler:', error);
  }
}

export interface PushToken {
  token: string;
  platform: 'ios' | 'android';
}

/**
 * Register for push notifications and get token
 */
export async function registerForPushNotifications(): Promise<PushToken | null> {
  // Only works on physical devices
  if (!Device.isDevice) {
    console.log('Push notifications require a physical device');
    return null;
  }

  // Check existing permissions
  const { status: existingStatus } = await Notifications.getPermissionsAsync();
  let finalStatus = existingStatus;

  // Request permissions if not granted
  if (existingStatus !== 'granted') {
    const { status } = await Notifications.requestPermissionsAsync();
    finalStatus = status;
  }

  if (finalStatus !== 'granted') {
    console.log('Push notification permission not granted');
    return null;
  }

  // Get push token
  const projectId = Constants.expoConfig?.extra?.eas?.projectId;
  const token = await Notifications.getExpoPushTokenAsync({
    projectId,
  });

  // Configure for Android
  if (Platform.OS === 'android') {
    Notifications.setNotificationChannelAsync('default', {
      name: 'default',
      importance: Notifications.AndroidImportance.MAX,
      vibrationPattern: [0, 250, 250, 250],
      lightColor: '#6200EA',
    });
  }

  return {
    token: token.data,
    platform: Platform.OS as 'ios' | 'android',
  };
}

/**
 * Save push token to backend
 *
 * TODO: Backend endpoint needed - POST /api/users/push-token
 * Request body: { token: string, platform: 'ios' | 'android', deviceId?: string }
 * This should be implemented in apps/api/src/users/users.controller.ts
 */
export async function savePushToken(userId: string, pushToken: PushToken): Promise<void> {
  try {
    const token = await getIdToken(true);
    if (!token) {
      console.log('No auth token available for saving push token');
      return;
    }

    const response = await fetch(`${API_BASE_URL}/users/push-token`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        token: pushToken.token,
        platform: pushToken.platform,
      }),
    });

    if (!response.ok) {
      // 404 means endpoint not implemented yet - that's expected
      if (response.status === 404) {
        console.log('Push token endpoint not yet implemented on backend');
        return;
      }
      throw new Error(`Failed to save push token: ${response.status}`);
    }

    console.log('Push token saved successfully');
  } catch (error) {
    console.error('Failed to save push token:', error);
  }
}

/**
 * Add notification received listener
 */
export function addNotificationReceivedListener(
  callback: (notification: Notifications.Notification) => void
) {
  return Notifications.addNotificationReceivedListener(callback);
}

/**
 * Add notification response listener (when user taps notification)
 */
export function addNotificationResponseListener(
  callback: (response: Notifications.NotificationResponse) => void
) {
  return Notifications.addNotificationResponseReceivedListener(callback);
}

/**
 * Schedule a local notification
 */
export async function scheduleLocalNotification(
  title: string,
  body: string,
  data?: Record<string, unknown>,
  trigger?: Notifications.NotificationTriggerInput
): Promise<string> {
  return await Notifications.scheduleNotificationAsync({
    content: {
      title,
      body,
      data,
      sound: true,
    },
    trigger: trigger || null,
  });
}

/**
 * Cancel all scheduled notifications
 */
export async function cancelAllNotifications(): Promise<void> {
  await Notifications.cancelAllScheduledNotificationsAsync();
}

/**
 * Get badge count
 */
export async function getBadgeCount(): Promise<number> {
  return await Notifications.getBadgeCountAsync();
}

/**
 * Set badge count
 */
export async function setBadgeCount(count: number): Promise<void> {
  await Notifications.setBadgeCountAsync(count);
}

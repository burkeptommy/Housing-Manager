import React, { createContext, useContext, useEffect, useState, useRef } from 'react';
import { useRouter } from 'expo-router';
import * as Notifications from 'expo-notifications';
import { useAuth } from './auth-context';
import {
  configureNotificationHandler,
  registerForPushNotifications,
  savePushToken,
  addNotificationReceivedListener,
  addNotificationResponseListener,
  PushToken,
} from '../lib/notifications';

interface NotificationsContextType {
  pushToken: PushToken | null;
  isEnabled: boolean;
  requestPermissions: () => Promise<boolean>;
}

const NotificationsContext = createContext<NotificationsContextType | null>(null);

export function NotificationsProvider({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const { user } = useAuth();
  const [pushToken, setPushToken] = useState<PushToken | null>(null);
  const [isEnabled, setIsEnabled] = useState(false);
  const notificationListener = useRef<Notifications.Subscription>();
  const responseListener = useRef<Notifications.Subscription>();

  // Configure notification handler on mount
  useEffect(() => {
    configureNotificationHandler();
  }, []);

  // Register for push notifications when user logs in
  useEffect(() => {
    if (user) {
      registerForPushNotifications().then(async (token) => {
        if (token) {
          setPushToken(token);
          setIsEnabled(true);
          if (user.id) {
            await savePushToken(user.id, token);
          }
        }
      });
    }
  }, [user]);

  // Setup notification listeners
  useEffect(() => {
    // When notification received while app is open
    notificationListener.current = addNotificationReceivedListener((notification) => {
      console.log('Notification received:', notification);
    });

    // When user taps on notification
    responseListener.current = addNotificationResponseListener((response) => {
      const data = response.notification.request.content.data;

      // Navigate based on notification type
      if (data?.type === 'approval') {
        router.push('/(tabs)/approvals');
      } else if (data?.type === 'message') {
        router.push('/(tabs)/sarah');
      } else if (data?.type === 'bill') {
        router.push('/(tabs)/billing');
      }
    });

    return () => {
      if (notificationListener.current) {
        notificationListener.current.remove();
      }
      if (responseListener.current) {
        responseListener.current.remove();
      }
    };
  }, [router]);

  const requestPermissions = async (): Promise<boolean> => {
    const token = await registerForPushNotifications();
    if (token) {
      setPushToken(token);
      setIsEnabled(true);
      if (user?.id) {
        await savePushToken(user.id, token);
      }
      return true;
    }
    return false;
  };

  return (
    <NotificationsContext.Provider
      value={{
        pushToken,
        isEnabled,
        requestPermissions,
      }}
    >
      {children}
    </NotificationsContext.Provider>
  );
}

export function useNotifications() {
  const context = useContext(NotificationsContext);
  if (!context) {
    throw new Error('useNotifications must be used within NotificationsProvider');
  }
  return context;
}

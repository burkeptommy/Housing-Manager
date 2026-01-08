import { Slot } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import { AuthProvider } from '../src/contexts/auth-context';
import { SubscriptionProvider } from '../src/contexts/subscription-context';
import { NotificationsProvider } from '../src/contexts/notifications-context';
import { PurchasesProvider } from '../src/contexts/purchases-context';
import { PlaidProvider } from '../src/contexts/plaid-context';

export default function RootLayout() {
  return (
    <SafeAreaProvider>
      <AuthProvider>
        <SubscriptionProvider>
          <NotificationsProvider>
            <PurchasesProvider>
              <PlaidProvider>
                <StatusBar style="auto" />
                <Slot />
              </PlaidProvider>
            </PurchasesProvider>
          </NotificationsProvider>
        </SubscriptionProvider>
      </AuthProvider>
    </SafeAreaProvider>
  );
}

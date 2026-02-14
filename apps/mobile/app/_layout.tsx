import { useCallback } from 'react';
import { Text, TextInput } from 'react-native';
import { Slot } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import * as SplashScreen from 'expo-splash-screen';
import {
  useFonts,
  Nunito_300Light,
  Nunito_400Regular,
  Nunito_500Medium,
  Nunito_600SemiBold,
  Nunito_700Bold,
  Nunito_800ExtraBold,
} from '@expo-google-fonts/nunito';
import { AuthProvider } from '../src/contexts/auth-context';
import { SubscriptionProvider } from '../src/contexts/subscription-context';
import { NotificationsProvider } from '../src/contexts/notifications-context';
import { PurchasesProvider } from '../src/contexts/purchases-context';
import { PlaidProvider } from '../src/contexts/plaid-context';
import { ErrorBoundary } from '../src/components/ErrorBoundary';

SplashScreen.preventAutoHideAsync();

// Apply Nunito as default font for all Text and TextInput components
const originalTextRender = (Text as any).render;
if (originalTextRender) {
  (Text as any).render = function (props: any, ref: any) {
    const { style, ...rest } = props;
    return originalTextRender.call(this, {
      ...rest,
      style: [{ fontFamily: 'Nunito_400Regular' }, style],
    }, ref);
  };
}

const originalTextInputRender = (TextInput as any).render;
if (originalTextInputRender) {
  (TextInput as any).render = function (props: any, ref: any) {
    const { style, ...rest } = props;
    return originalTextInputRender.call(this, {
      ...rest,
      style: [{ fontFamily: 'Nunito_400Regular' }, style],
    }, ref);
  };
}

export default function RootLayout() {
  const [fontsLoaded] = useFonts({
    Nunito_300Light,
    Nunito_400Regular,
    Nunito_500Medium,
    Nunito_600SemiBold,
    Nunito_700Bold,
    Nunito_800ExtraBold,
  });

  const onLayoutRootView = useCallback(async () => {
    if (fontsLoaded) {
      await SplashScreen.hideAsync();
    }
  }, [fontsLoaded]);

  if (!fontsLoaded) {
    return null;
  }

  return (
    <ErrorBoundary>
      <SafeAreaProvider onLayout={onLayoutRootView}>
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
    </ErrorBoundary>
  );
}

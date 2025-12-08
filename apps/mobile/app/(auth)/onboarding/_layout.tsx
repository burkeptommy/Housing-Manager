import { Stack } from 'expo-router';
import { OnboardingProvider } from '../../../src/contexts/onboarding-context';
import { colors } from '../../../src/lib/theme';

export default function OnboardingLayout() {
  return (
    <OnboardingProvider>
      <Stack
        screenOptions={{
          headerStyle: {
            backgroundColor: colors.slate[50],
          },
          headerTintColor: colors.slate[900],
          headerTitleStyle: {
            fontWeight: '600',
          },
          headerShadowVisible: false,
          contentStyle: {
            backgroundColor: colors.slate[50],
          },
        }}
      >
        <Stack.Screen
          name="index"
          options={{
            title: 'Home Basics',
            headerBackVisible: false,
          }}
        />
        <Stack.Screen
          name="bills"
          options={{
            title: 'Recurring Bills',
          }}
        />
        <Stack.Screen
          name="maintenance"
          options={{
            title: 'Maintenance Plan',
          }}
        />
        <Stack.Screen
          name="payment"
          options={{
            title: 'Choose Plan',
          }}
        />
        <Stack.Screen
          name="review"
          options={{
            title: 'Review',
          }}
        />
      </Stack>
    </OnboardingProvider>
  );
}

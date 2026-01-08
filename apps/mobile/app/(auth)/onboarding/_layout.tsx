import { Stack } from 'expo-router';
import { colors, typography } from '../../../src/lib/theme';

export default function OnboardingLayout() {
  return (
    <Stack
      screenOptions={{
        headerStyle: {
          backgroundColor: colors.background.secondary,
        },
        headerTintColor: colors.haven.navy[900],
        headerTitleStyle: {
          fontWeight: typography.fontWeights.semibold,
        },
        headerShadowVisible: false,
        contentStyle: {
          backgroundColor: colors.background.secondary,
        },
      }}
    >
      {/* New Magic Onboarding Flow */}
      <Stack.Screen
        name="address"
        options={{
          title: 'Your Home',
          headerBackVisible: false,
        }}
      />
      <Stack.Screen
        name="property"
        options={{
          title: 'Property Details',
        }}
      />
      <Stack.Screen
        name="bank"
        options={{
          title: 'Connect Bank',
        }}
      />
      <Stack.Screen
        name="plan"
        options={{
          title: 'Choose Plan',
        }}
      />
      <Stack.Screen
        name="complete"
        options={{
          headerShown: false,
        }}
      />

      {/* Legacy/Alternative Flow (accessible from bank screen) */}
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
  );
}

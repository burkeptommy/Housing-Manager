import { Stack } from 'expo-router';
import { colors } from '../../src/lib/theme';

export default function AuthLayout() {
  return (
    <Stack
      screenOptions={{
        headerStyle: {
          backgroundColor: colors.primary[600],
        },
        headerTintColor: colors.white,
        headerTitleStyle: {
          fontWeight: 'bold',
        },
        contentStyle: {
          backgroundColor: colors.slate[50],
        },
      }}
    >
      <Stack.Screen
        name="login"
        options={{
          title: 'Sign In',
          headerShown: false,
        }}
      />
      <Stack.Screen
        name="register"
        options={{
          title: 'Create Account',
          headerShown: false,
        }}
      />
      <Stack.Screen
        name="onboarding"
        options={{
          title: 'Set Up Your Home',
          headerBackVisible: false,
        }}
      />
    </Stack>
  );
}

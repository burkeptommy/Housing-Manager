import { Stack } from 'expo-router';
import { colors } from '../../src/lib/theme';

export default function OnboardingLayout() {
  return (
    <Stack
      screenOptions={{
        headerShown: false,
        contentStyle: { backgroundColor: colors.haven.purple[50] },
        animation: 'slide_from_right',
      }}
    >
      <Stack.Screen name="address" />
      <Stack.Screen name="confirm-property" />
      <Stack.Screen name="complete" />
    </Stack>
  );
}

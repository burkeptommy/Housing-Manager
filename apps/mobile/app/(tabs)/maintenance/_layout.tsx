import { Stack } from 'expo-router';
import { colors } from '../../../src/lib/theme';

export default function MaintenanceLayout() {
  return (
    <Stack
      screenOptions={{
        headerStyle: {
          backgroundColor: colors.white,
        },
        headerTintColor: colors.haven.navy[900],
        headerTitleStyle: {
          fontWeight: '600',
        },
        headerShadowVisible: false,
      }}
    >
      <Stack.Screen
        name="index"
        options={{
          headerShown: false,
        }}
      />
      <Stack.Screen
        name="[id]"
        options={{
          headerBackTitle: 'Back',
        }}
      />
      <Stack.Screen
        name="checklist"
        options={{
          headerShown: false,
        }}
      />
    </Stack>
  );
}

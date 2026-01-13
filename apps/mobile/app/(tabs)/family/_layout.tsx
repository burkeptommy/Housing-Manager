import { Stack } from 'expo-router';

const NAVY = '#0a1929';

export default function FamilyLayout() {
  return (
    <Stack
      screenOptions={{
        headerShown: true,
        headerStyle: {
          backgroundColor: NAVY,
        },
        headerTintColor: '#ffffff',
        headerTitleStyle: {
          fontWeight: '600',
        },
        headerBackTitle: 'Back',
      }}
    >
      <Stack.Screen name="index" options={{ headerShown: false }} />
      <Stack.Screen
        name="member/[id]"
        options={{
          title: 'Family Member',
          headerBackTitle: 'Family',
        }}
      />
      <Stack.Screen
        name="member/edit/[id]"
        options={{
          title: 'Edit Member',
          headerBackTitle: 'Back',
        }}
      />
      <Stack.Screen
        name="pet/[id]"
        options={{
          title: 'Pet',
          headerBackTitle: 'Family',
        }}
      />
      <Stack.Screen
        name="pet/edit/[id]"
        options={{
          title: 'Edit Pet',
          headerBackTitle: 'Back',
        }}
      />
      <Stack.Screen
        name="vehicle/[id]"
        options={{
          title: 'Vehicle',
          headerBackTitle: 'Family',
        }}
      />
      <Stack.Screen
        name="vehicle/edit/[id]"
        options={{
          title: 'Edit Vehicle',
          headerBackTitle: 'Back',
        }}
      />
      <Stack.Screen
        name="staff/[id]"
        options={{
          title: 'Staff',
          headerBackTitle: 'Family',
        }}
      />
      <Stack.Screen
        name="staff/edit/[id]"
        options={{
          title: 'Edit Staff',
          headerBackTitle: 'Back',
        }}
      />
    </Stack>
  );
}

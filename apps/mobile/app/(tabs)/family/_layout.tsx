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
        headerBackTitle: '',
      }}
    >
      <Stack.Screen name="index" options={{ headerShown: false }} />
      <Stack.Screen
        name="member/[id]"
        options={{
          title: 'Family Member',
        }}
      />
    </Stack>
  );
}

import { Stack } from 'expo-router';

const PURPLE = '#6200EA';

export default function VaultLayout() {
  return (
    <Stack
      screenOptions={{
        headerShown: true,
        headerStyle: {
          backgroundColor: PURPLE,
        },
        headerTintColor: '#ffffff',
        headerTitleStyle: {
          fontFamily: 'Nunito_600SemiBold',
        },
        headerBackTitle: '',
      }}
    >
      <Stack.Screen name="index" options={{ headerShown: false }} />
      <Stack.Screen
        name="upload"
        options={{
          title: 'Upload Document',
          presentation: 'modal',
        }}
      />
      <Stack.Screen
        name="[id]"
        options={{
          title: 'Document',
        }}
      />
    </Stack>
  );
}

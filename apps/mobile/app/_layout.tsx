import { Stack } from 'expo-router';
import { StatusBar } from 'expo-status-bar';

export default function RootLayout() {
  return (
    <>
      <StatusBar style="auto" />
      <Stack
        screenOptions={{
          headerStyle: {
            backgroundColor: '#0284c7',
          },
          headerTintColor: '#fff',
          headerTitleStyle: {
            fontWeight: 'bold',
          },
        }}
      >
        <Stack.Screen name="index" options={{ title: 'Haven Home Manager' }} />
        <Stack.Screen name="homes" options={{ title: 'My Homes' }} />
        <Stack.Screen name="tasks" options={{ title: 'Tasks' }} />
      </Stack>
    </>
  );
}

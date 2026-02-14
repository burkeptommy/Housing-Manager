import { Stack } from 'expo-router';
import { colors } from '../../../src/lib/theme';

export default function ManagerLayout() {
  return (
    <Stack
      initialRouteName="index"
      screenOptions={{
        headerShown: false,
      }}
    >
      {/* Index stays hidden - it has its own header */}
      <Stack.Screen name="index" options={{ headerShown: false }} />

      {/* New Request needs a header */}
      <Stack.Screen
        name="new-request"
        options={{
          headerShown: true,
          title: 'Ask Alfred',
          headerStyle: { backgroundColor: colors.haven.purple[500] },
          headerTintColor: colors.white,
          headerBackTitle: 'Back',
        }}
      />

      {/* Chat needs a header */}
      <Stack.Screen
        name="chat"
        options={{
          headerShown: true,
          title: 'Chat',
          headerStyle: { backgroundColor: colors.haven.purple[500] },
          headerTintColor: colors.white,
          headerBackTitle: 'Back',
        }}
      />

      {/* Vendors folder uses its own layout */}
      <Stack.Screen name="vendors" options={{ headerShown: false }} />
    </Stack>
  );
}

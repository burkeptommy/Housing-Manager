import { Stack } from 'expo-router';
import { colors } from '../../../src/lib/theme';

export default function AlfredLayout() {
  return (
    <Stack
      initialRouteName="cases"
      screenOptions={{
        headerShown: false,
      }}
    >
      <Stack.Screen name="cases" options={{ headerShown: false }} />
    </Stack>
  );
}

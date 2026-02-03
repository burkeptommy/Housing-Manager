import { Stack } from 'expo-router';

export default function MoneyLayout() {
  return (
    <Stack screenOptions={{ headerShown: false }}>
      <Stack.Screen name="index" />
      <Stack.Screen name="budget" />
      <Stack.Screen name="transactions" />
      <Stack.Screen name="forecast" />
    </Stack>
  );
}

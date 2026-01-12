import { Stack } from 'expo-router';

export default function ManagerLayout() {
  return (
    <Stack
      initialRouteName="index"
      screenOptions={{
        headerShown: false,
      }}
    />
  );
}

import { Stack } from 'expo-router';
import { colors } from '../../../../../src/lib/theme';

export default function VendorChatLayout() {
  return (
    <Stack
      screenOptions={{
        headerShown: true,
        headerStyle: { backgroundColor: colors.haven.navy[900] },
        headerTintColor: colors.white,
        headerBackTitle: 'Back',
      }}
    />
  );
}

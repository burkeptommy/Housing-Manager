import { Stack } from 'expo-router';
import { colors } from '../../../../src/lib/theme';

export default function ChecklistLayout() {
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
        headerBackTitle: 'Checklist',
      }}
    />
  );
}

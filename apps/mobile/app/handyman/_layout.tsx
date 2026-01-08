import { Stack } from 'expo-router';
import { colors } from '../../src/lib/theme';

export default function HandymanLayout() {
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
        headerBackTitle: 'Back',
      }}
    >
      <Stack.Screen
        name="book"
        options={{
          title: 'Book Handyman',
          presentation: 'modal',
        }}
      />
      <Stack.Screen
        name="confirmation"
        options={{
          title: 'Booking Confirmed',
          headerShown: false,
        }}
      />
    </Stack>
  );
}

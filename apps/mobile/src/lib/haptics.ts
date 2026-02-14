import { Platform } from 'react-native';

let Haptics: typeof import('expo-haptics') | null = null;
try {
  Haptics = require('expo-haptics');
} catch {}

export function lightImpact() {
  if (Platform.OS !== 'ios' || !Haptics) return;
  Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
}

export function mediumImpact() {
  if (Platform.OS !== 'ios' || !Haptics) return;
  Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
}

export function heavyImpact() {
  if (Platform.OS !== 'ios' || !Haptics) return;
  Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Heavy);
}

export function successNotification() {
  if (Platform.OS !== 'ios' || !Haptics) return;
  Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
}

export function warningNotification() {
  if (Platform.OS !== 'ios' || !Haptics) return;
  Haptics.notificationAsync(Haptics.NotificationFeedbackType.Warning);
}

export function errorNotification() {
  if (Platform.OS !== 'ios' || !Haptics) return;
  Haptics.notificationAsync(Haptics.NotificationFeedbackType.Error);
}

export function selectionChanged() {
  if (Platform.OS !== 'ios' || !Haptics) return;
  Haptics.selectionAsync();
}

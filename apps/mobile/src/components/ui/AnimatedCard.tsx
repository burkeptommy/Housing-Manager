import React from 'react';
import { StyleSheet, ViewStyle, TouchableOpacity, View } from 'react-native';
import { colors, spacing, borderRadius, shadows } from '../../lib/theme';

interface AnimatedCardProps {
  children: React.ReactNode;
  onPress?: () => void;
  style?: ViewStyle;
  delay?: number;
  direction?: 'up' | 'down';
  variant?: 'default' | 'elevated' | 'outlined';
}

/**
 * Card component with press feedback
 * Simplified version without react-native-reanimated to avoid native module conflicts
 */
export function AnimatedCard({
  children,
  onPress,
  style,
  delay = 0,
  direction = 'up',
  variant = 'default',
}: AnimatedCardProps) {
  const cardStyle = [
    styles.base,
    variant === 'elevated' && styles.elevated,
    variant === 'outlined' && styles.outlined,
    style,
  ];

  if (onPress) {
    return (
      <TouchableOpacity
        style={cardStyle}
        onPress={onPress}
        activeOpacity={0.7}
      >
        {children}
      </TouchableOpacity>
    );
  }

  return (
    <View style={cardStyle}>
      {children}
    </View>
  );
}

const styles = StyleSheet.create({
  base: {
    backgroundColor: colors.white,
    borderRadius: borderRadius.xl,
    padding: spacing[4],
    ...shadows.md,
  },
  elevated: {
    ...shadows.lg,
  },
  outlined: {
    borderWidth: 1,
    borderColor: colors.border.default,
    shadowColor: 'transparent',
    shadowOpacity: 0,
    elevation: 0,
  },
});

import React from 'react';
import { View, StyleSheet, ViewStyle, Pressable, StyleProp } from 'react-native';
import { colors, spacing, borderRadius, shadows } from '../../lib/theme';

interface CardProps {
  children: React.ReactNode;
  onPress?: () => void;
  variant?: 'default' | 'elevated' | 'outlined';
  padding?: keyof typeof spacing;
  style?: StyleProp<ViewStyle>;
}

export function Card({
  children,
  onPress,
  variant = 'default',
  padding = 4,
  style,
}: CardProps) {
  const baseStyles = [
    styles.base,
    styles[variant],
    { padding: spacing[padding] },
    style,
  ];

  if (onPress) {
    return (
      <Pressable
        style={({ pressed }) => [
          ...baseStyles,
          pressed && styles.pressed,
        ]}
        onPress={onPress}
      >
        {children}
      </Pressable>
    );
  }

  return <View style={baseStyles}>{children}</View>;
}

const styles = StyleSheet.create({
  base: {
    borderRadius: borderRadius.xl,
    backgroundColor: colors.white,
  },
  default: {
    ...shadows.sm,
  },
  elevated: {
    ...shadows.lg,
  },
  outlined: {
    borderWidth: 1,
    borderColor: colors.border.default,
    ...shadows.none,
  },
  pressed: {
    transform: [{ scale: 0.98 }],
    opacity: 0.95,
  },
});

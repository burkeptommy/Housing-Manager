import React from 'react';
import { View, Text, StyleSheet, ViewStyle } from 'react-native';
import { colors, typography, spacing, borderRadius } from '../../lib/theme';

type BadgeVariant = 'default' | 'success' | 'warning' | 'error' | 'info' | 'champagne';

interface BadgeProps {
  label: string;
  variant?: BadgeVariant;
  size?: 'sm' | 'md';
  style?: ViewStyle;
}

export function Badge({ label, variant = 'default', size = 'md', style }: BadgeProps) {
  return (
    <View style={[styles.base, styles[variant], styles[`size_${size}`], style]}>
      <Text style={[styles.text, styles[`text_${variant}`], styles[`text_${size}`]]}>
        {label}
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  base: {
    borderRadius: borderRadius.full,
    alignSelf: 'flex-start',
  },

  // Variants
  default: {
    backgroundColor: colors.gray[100],
  },
  success: {
    backgroundColor: colors.status.successLight,
  },
  warning: {
    backgroundColor: colors.status.warningLight,
  },
  error: {
    backgroundColor: colors.status.errorLight,
  },
  info: {
    backgroundColor: colors.status.infoLight,
  },
  champagne: {
    backgroundColor: colors.haven.champagne[100],
  },

  // Sizes
  size_sm: {
    paddingVertical: spacing[0.5],
    paddingHorizontal: spacing[2],
  },
  size_md: {
    paddingVertical: spacing[1],
    paddingHorizontal: spacing[2.5],
  },

  // Text base
  text: {
    fontWeight: typography.fontWeights.medium,
  },

  // Text variants
  text_default: {
    color: colors.gray[700],
  },
  text_success: {
    color: colors.status.success,
  },
  text_warning: {
    color: colors.status.warning,
  },
  text_error: {
    color: colors.status.error,
  },
  text_info: {
    color: colors.status.info,
  },
  text_champagne: {
    color: colors.haven.champagne[600],
  },

  // Text sizes
  text_sm: {
    fontSize: typography.fontSizes['2xs'],
  },
  text_md: {
    fontSize: typography.fontSizes.xs,
  },
});

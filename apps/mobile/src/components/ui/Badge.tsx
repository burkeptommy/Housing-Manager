import React from 'react';
import { View, Text, StyleSheet, ViewStyle } from 'react-native';
import { colors, typography, spacing, borderRadius } from '../../lib/theme';

type BadgeVariant = 'default' | 'success' | 'warning' | 'error' | 'info' | 'accent' | 'coral';

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
  accent: {
    backgroundColor: colors.haven.purple[100],
  },
  coral: {
    backgroundColor: colors.haven.coral[100],
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
    fontFamily: 'Nunito_500Medium',
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
  text_accent: {
    color: colors.haven.purple[600],
  },
  text_coral: {
    color: colors.haven.coral[600],
  },

  // Text sizes - minimum 11px for badges (xs is now 13px)
  text_sm: {
    fontSize: 11,  // Minimum for small badges
  },
  text_md: {
    fontSize: typography.fontSizes.xs,  // 13px
  },
});

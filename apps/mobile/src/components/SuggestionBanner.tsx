import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity } from 'react-native';
import { useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { colors, typography, spacing, borderRadius } from '../lib/theme';

interface SuggestionBannerProps {
  icon: keyof typeof Ionicons.glyphMap;
  text: string;
  actionLabel?: string;
  route?: string;
  onPress?: () => void;
  variant?: 'default' | 'warning' | 'info';
  dismissable?: boolean;
  onDismiss?: () => void;
}

export function SuggestionBanner({
  icon,
  text,
  actionLabel = 'Add',
  route,
  onPress,
  variant = 'default',
  dismissable = false,
  onDismiss,
}: SuggestionBannerProps) {
  const router = useRouter();

  const handlePress = () => {
    if (onPress) {
      onPress();
    } else if (route) {
      router.push(route as any);
    }
  };

  const getVariantStyles = () => {
    switch (variant) {
      case 'warning':
        return {
          backgroundColor: colors.status.warningLight,
          borderColor: colors.status.warning,
          iconColor: colors.status.warning,
        };
      case 'info':
        return {
          backgroundColor: colors.haven.purple[50],
          borderColor: colors.haven.purple[200],
          iconColor: colors.haven.purple[500],
        };
      default:
        return {
          backgroundColor: colors.haven.purple[50],
          borderColor: colors.haven.purple[200],
          iconColor: colors.haven.purple[500],
        };
    }
  };

  const variantStyles = getVariantStyles();

  return (
    <TouchableOpacity
      style={[
        styles.container,
        {
          backgroundColor: variantStyles.backgroundColor,
          borderColor: variantStyles.borderColor,
        },
      ]}
      onPress={handlePress}
      activeOpacity={0.7}
    >
      <View style={[styles.iconContainer, { backgroundColor: variantStyles.iconColor + '20' }]}>
        <Ionicons name={icon} size={18} color={variantStyles.iconColor} />
      </View>

      <Text style={styles.text} numberOfLines={2}>
        {text}
      </Text>

      <View style={styles.actionContainer}>
        <Text style={[styles.actionLabel, { color: variantStyles.iconColor }]}>
          {actionLabel} →
        </Text>
      </View>

      {dismissable && onDismiss && (
        <TouchableOpacity style={styles.dismissButton} onPress={onDismiss}>
          <Ionicons name="close" size={18} color={colors.text.tertiary} />
        </TouchableOpacity>
      )}
    </TouchableOpacity>
  );
}

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: spacing[3],
    borderRadius: borderRadius.lg,
    borderWidth: 1,
    gap: spacing[3],
  },
  iconContainer: {
    width: 32,
    height: 32,
    borderRadius: borderRadius.md,
    alignItems: 'center',
    justifyContent: 'center',
  },
  text: {
    flex: 1,
    fontSize: typography.fontSizes.sm,
    color: colors.text.primary,
    lineHeight: 18,
  },
  actionContainer: {
    flexShrink: 0,
  },
  actionLabel: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
  },
  dismissButton: {
    padding: spacing[1],
    marginLeft: spacing[1],
  },
});

export default SuggestionBanner;

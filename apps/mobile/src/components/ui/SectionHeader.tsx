import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity, ViewStyle } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { colors, typography, spacing } from '../../lib/theme';

interface SectionHeaderProps {
  title: string;
  subtitle?: string;
  actionText?: string;
  onActionPress?: () => void;
  actionIcon?: keyof typeof Ionicons.glyphMap;
  style?: ViewStyle;
}

export function SectionHeader({
  title,
  subtitle,
  actionText,
  onActionPress,
  actionIcon,
  style,
}: SectionHeaderProps) {
  return (
    <View style={[styles.container, style]}>
      <View style={styles.left}>
        <Text style={styles.title}>{title}</Text>
        {subtitle && <Text style={styles.subtitle}>{subtitle}</Text>}
      </View>
      {(actionText || actionIcon) && onActionPress && (
        <TouchableOpacity
          style={styles.action}
          onPress={onActionPress}
          hitSlop={{ top: 8, bottom: 8, left: 8, right: 8 }}
        >
          {actionText && <Text style={styles.actionText}>{actionText}</Text>}
          {actionIcon && (
            <Ionicons
              name={actionIcon}
              size={18}
              color={colors.haven.purple[500]}
              style={actionText ? styles.actionIcon : undefined}
            />
          )}
        </TouchableOpacity>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-end',
    paddingHorizontal: spacing[4],
    paddingTop: spacing[4],
    paddingBottom: spacing[3],
  },
  left: {
    flex: 1,
  },
  title: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
    letterSpacing: -0.3,
  },
  subtitle: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    marginTop: 2,
  },
  action: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  actionText: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.haven.purple[500],
  },
  actionIcon: {
    marginLeft: spacing[1],
  },
});

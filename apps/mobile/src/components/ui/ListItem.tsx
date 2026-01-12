import React from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  ViewStyle,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { colors, typography, spacing, borderRadius } from '../../lib/theme';

interface ListItemProps {
  title: string;
  subtitle?: string;
  leftIcon?: keyof typeof Ionicons.glyphMap;
  leftIconColor?: string;
  leftIconBgColor?: string;
  rightElement?: React.ReactNode;
  showChevron?: boolean;
  badge?: string | number;
  badgeVariant?: 'default' | 'success' | 'warning' | 'error';
  onPress?: () => void;
  disabled?: boolean;
  style?: ViewStyle;
  isLast?: boolean;
}

export function ListItem({
  title,
  subtitle,
  leftIcon,
  leftIconColor = colors.haven.champagne[500],
  leftIconBgColor = colors.haven.champagne[50],
  rightElement,
  showChevron = true,
  badge,
  badgeVariant = 'default',
  onPress,
  disabled = false,
  style,
  isLast = false,
}: ListItemProps) {
  const getBadgeStyle = () => {
    switch (badgeVariant) {
      case 'success':
        return { backgroundColor: colors.status.success };
      case 'warning':
        return { backgroundColor: colors.status.warning };
      case 'error':
        return { backgroundColor: colors.status.error };
      default:
        return { backgroundColor: colors.haven.champagne[500] };
    }
  };

  const content = (
    <View style={[styles.container, !isLast && styles.border, style]}>
      {leftIcon && (
        <View style={[styles.iconContainer, { backgroundColor: leftIconBgColor }]}>
          <Ionicons name={leftIcon} size={20} color={leftIconColor} />
        </View>
      )}
      <View style={styles.content}>
        <Text style={[styles.title, disabled && styles.titleDisabled]} numberOfLines={1}>
          {title}
        </Text>
        {subtitle && (
          <Text style={styles.subtitle} numberOfLines={1}>
            {subtitle}
          </Text>
        )}
      </View>
      {badge !== undefined && (
        <View style={[styles.badge, getBadgeStyle()]}>
          <Text style={styles.badgeText}>{badge}</Text>
        </View>
      )}
      {rightElement}
      {showChevron && onPress && (
        <Ionicons
          name="chevron-forward"
          size={20}
          color={colors.text.tertiary}
          style={styles.chevron}
        />
      )}
    </View>
  );

  if (onPress && !disabled) {
    return (
      <TouchableOpacity
        onPress={onPress}
        activeOpacity={0.7}
      >
        {content}
      </TouchableOpacity>
    );
  }

  return content;
}

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: spacing[3],
    paddingHorizontal: spacing[4],
    backgroundColor: colors.white,
    minHeight: 56,
  },
  border: {
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: colors.border.light,
  },
  iconContainer: {
    width: 40,
    height: 40,
    borderRadius: borderRadius.lg,
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: spacing[3],
  },
  content: {
    flex: 1,
    justifyContent: 'center',
  },
  title: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.medium as '500',
    color: colors.text.primary,
  },
  titleDisabled: {
    color: colors.text.tertiary,
  },
  subtitle: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    marginTop: 2,
  },
  badge: {
    paddingHorizontal: spacing[2],
    paddingVertical: 2,
    borderRadius: borderRadius.full,
    marginLeft: spacing[2],
  },
  badgeText: {
    fontSize: typography.fontSizes.xs,
    fontWeight: typography.fontWeights.semibold as '600',
    color: colors.white,
  },
  chevron: {
    marginLeft: spacing[2],
  },
});

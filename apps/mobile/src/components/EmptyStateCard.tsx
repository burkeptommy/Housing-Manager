import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity } from 'react-native';
import { useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { colors, typography, spacing, borderRadius, shadows } from '../lib/theme';

interface EmptyStateAction {
  label: string;
  route: string;
  primary?: boolean;
}

interface EmptyStateCardProps {
  icon: keyof typeof Ionicons.glyphMap;
  title: string;
  description: string;
  alfredPrompt?: string;
  actions?: EmptyStateAction[];
  compact?: boolean;
}

export function EmptyStateCard({
  icon,
  title,
  description,
  alfredPrompt,
  actions = [],
  compact = false,
}: EmptyStateCardProps) {
  const router = useRouter();

  return (
    <View style={[styles.container, compact && styles.containerCompact]}>
      <View style={[styles.iconContainer, compact && styles.iconContainerCompact]}>
        <Ionicons
          name={icon}
          size={compact ? 28 : 40}
          color={colors.haven.purple[500]}
        />
      </View>

      <Text style={[styles.title, compact && styles.titleCompact]}>{title}</Text>
      <Text style={[styles.description, compact && styles.descriptionCompact]}>
        {description}
      </Text>

      {alfredPrompt && (
        <TouchableOpacity
          style={styles.alfredPrompt}
          onPress={() => router.push('/(tabs)/manager')}
        >
          <Ionicons name="sparkles" size={16} color={colors.haven.purple[500]} />
          <Text style={styles.alfredPromptText}>{alfredPrompt}</Text>
        </TouchableOpacity>
      )}

      {actions.length > 0 && (
        <View style={styles.actionsContainer}>
          {actions.map((action, index) => (
            <TouchableOpacity
              key={index}
              style={[
                styles.actionButton,
                action.primary && styles.actionButtonPrimary,
              ]}
              onPress={() => router.push(action.route as any)}
            >
              <Text
                style={[
                  styles.actionButtonText,
                  action.primary && styles.actionButtonTextPrimary,
                ]}
              >
                {action.label}
              </Text>
            </TouchableOpacity>
          ))}
        </View>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    alignItems: 'center',
    padding: spacing[6],
    backgroundColor: colors.white,
    borderRadius: borderRadius.xl,
    ...shadows.sm,
  },
  containerCompact: {
    padding: spacing[4],
  },
  iconContainer: {
    width: 72,
    height: 72,
    borderRadius: 36,
    backgroundColor: colors.haven.purple[50],
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: spacing[4],
  },
  iconContainerCompact: {
    width: 56,
    height: 56,
    borderRadius: 28,
    marginBottom: spacing[3],
  },
  title: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
    textAlign: 'center',
    marginBottom: spacing[2],
  },
  titleCompact: {
    fontSize: typography.fontSizes.base,
    marginBottom: spacing[1],
  },
  description: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    textAlign: 'center',
    lineHeight: 20,
    maxWidth: 280,
  },
  descriptionCompact: {
    fontSize: typography.fontSizes.xs,
    maxWidth: 240,
  },
  alfredPrompt: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[2],
    marginTop: spacing[4],
    paddingHorizontal: spacing[4],
    paddingVertical: spacing[2],
    backgroundColor: colors.haven.purple[50],
    borderRadius: borderRadius.full,
  },
  alfredPromptText: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.purple[600],
    fontWeight: typography.fontWeights.medium,
  },
  actionsContainer: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'center',
    gap: spacing[3],
    marginTop: spacing[4],
  },
  actionButton: {
    paddingHorizontal: spacing[4],
    paddingVertical: spacing[3],
    borderRadius: borderRadius.lg,
    backgroundColor: colors.gray[100],
    minWidth: 120,
    alignItems: 'center',
  },
  actionButtonPrimary: {
    backgroundColor: colors.haven.purple[500],
  },
  actionButtonText: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
  },
  actionButtonTextPrimary: {
    color: colors.white,
  },
});

export default EmptyStateCard;

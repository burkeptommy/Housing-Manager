import React from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
} from 'react-native';
import { useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { colors, typography, spacing, borderRadius, shadows } from '../lib/theme';

// =============================================================================
// TYPES
// =============================================================================

export interface ChecklistItem {
  id: string;
  title: string;
  description: string;
  icon: keyof typeof Ionicons.glyphMap;
  iconColor: string;
  completed: boolean;
  route?: string;
  action?: () => void;
}

export interface OnboardingChecklistData {
  bankConnected: boolean;
  hasHvacSystem: boolean;
  hasDocuments: boolean;
  hasFamilyMembers: boolean;
  hasMaintenanceTask: boolean;
  hasVendor: boolean;
}

interface OnboardingChecklistProps {
  data: OnboardingChecklistData;
  onDismiss?: () => void;
}

// =============================================================================
// COMPONENT
// =============================================================================

export function OnboardingChecklist({ data, onDismiss }: OnboardingChecklistProps) {
  const router = useRouter();

  // Build checklist items based on data
  const items: ChecklistItem[] = [
    {
      id: 'bank',
      title: 'Connect your bank',
      description: 'Link accounts for bill tracking',
      icon: 'card-outline',
      iconColor: colors.emerald[500],
      completed: data.bankConnected,
      route: '/(tabs)/wallet',
    },
    {
      id: 'hvac',
      title: 'Add your HVAC system',
      description: 'Track your heating & cooling',
      icon: 'thermometer-outline',
      iconColor: colors.orange[500],
      completed: data.hasHvacSystem,
      route: '/(tabs)/home',
    },
    {
      id: 'documents',
      title: 'Upload home documents',
      description: 'Store warranties & manuals',
      icon: 'document-text-outline',
      iconColor: colors.blue[500],
      completed: data.hasDocuments,
      route: '/(tabs)/vault',
    },
    {
      id: 'family',
      title: 'Add a family member',
      description: 'Share access with household',
      icon: 'people-outline',
      iconColor: colors.indigo[500],
      completed: data.hasFamilyMembers,
      route: '/(tabs)/family',
    },
    {
      id: 'maintenance',
      title: 'Schedule maintenance',
      description: 'Set up seasonal reminders',
      icon: 'construct-outline',
      iconColor: colors.amber[500],
      completed: data.hasMaintenanceTask,
      route: '/(tabs)/maintenance',
    },
    {
      id: 'vendor',
      title: 'Add a service provider',
      description: 'Save your trusted vendors',
      icon: 'briefcase-outline',
      iconColor: colors.cyan[500],
      completed: data.hasVendor,
      route: '/(tabs)/manager/vendors',
    },
  ];

  // Filter to show max 6 items, prioritizing incomplete ones
  const incompleteItems = items.filter(item => !item.completed);
  const completedItems = items.filter(item => item.completed);
  const displayItems = [...incompleteItems, ...completedItems].slice(0, 6);

  // Calculate progress
  const completedCount = items.filter(item => item.completed).length;
  const totalCount = items.length;
  const progressPercent = (completedCount / totalCount) * 100;

  // Don't show if all items completed
  if (completedCount === totalCount) {
    return null;
  }

  const handleItemPress = (item: ChecklistItem) => {
    if (item.action) {
      item.action();
    } else if (item.route) {
      router.push(item.route as any);
    }
  };

  return (
    <View style={styles.container}>
      {/* Header */}
      <View style={styles.header}>
        <View style={styles.headerLeft}>
          <Text style={styles.title}>Get Started</Text>
          <Text style={styles.subtitle}>
            {completedCount}/{totalCount} completed
          </Text>
        </View>
        {onDismiss && (
          <TouchableOpacity onPress={onDismiss} style={styles.dismissButton}>
            <Ionicons name="close" size={20} color={colors.text.tertiary} />
          </TouchableOpacity>
        )}
      </View>

      {/* Progress Bar */}
      <View style={styles.progressContainer}>
        <View style={styles.progressTrack}>
          <View style={[styles.progressFill, { width: `${progressPercent}%` }]} />
        </View>
      </View>

      {/* Checklist Items */}
      <View style={styles.itemsContainer}>
        {displayItems.map((item, index) => (
          <TouchableOpacity
            key={item.id}
            style={[
              styles.item,
              item.completed && styles.itemCompleted,
              index < displayItems.length - 1 && styles.itemBorder,
            ]}
            onPress={() => handleItemPress(item)}
            disabled={item.completed}
          >
            <View style={[styles.iconContainer, { backgroundColor: item.iconColor + '15' }]}>
              {item.completed ? (
                <Ionicons name="checkmark-circle" size={24} color={colors.status.success} />
              ) : (
                <Ionicons name={item.icon} size={24} color={item.iconColor} />
              )}
            </View>
            <View style={styles.itemContent}>
              <Text style={[styles.itemTitle, item.completed && styles.itemTitleCompleted]}>
                {item.title}
              </Text>
              <Text style={styles.itemDescription}>{item.description}</Text>
            </View>
            {!item.completed && (
              <Ionicons name="chevron-forward" size={20} color={colors.text.tertiary} />
            )}
          </TouchableOpacity>
        ))}
      </View>
    </View>
  );
}

// =============================================================================
// STYLES
// =============================================================================

const styles = StyleSheet.create({
  container: {
    backgroundColor: colors.white,
    borderRadius: borderRadius.xl,
    padding: spacing[4],
    marginHorizontal: spacing[4],
    marginVertical: spacing[3],
    ...shadows.md,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    marginBottom: spacing[3],
  },
  headerLeft: {
    flex: 1,
  },
  title: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.bold,
    color: colors.text.primary,
  },
  subtitle: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    marginTop: spacing[1],
  },
  dismissButton: {
    padding: spacing[2],
    marginRight: -spacing[2],
    marginTop: -spacing[2],
  },
  progressContainer: {
    marginBottom: spacing[4],
  },
  progressTrack: {
    height: 6,
    backgroundColor: colors.background.secondary,
    borderRadius: borderRadius.full,
    overflow: 'hidden',
  },
  progressFill: {
    height: '100%',
    backgroundColor: colors.haven.purple[500],
    borderRadius: borderRadius.full,
  },
  itemsContainer: {
    borderRadius: borderRadius.lg,
    overflow: 'hidden',
  },
  item: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: spacing[3],
    gap: spacing[3],
  },
  itemCompleted: {
    opacity: 0.6,
  },
  itemBorder: {
    borderBottomWidth: 1,
    borderBottomColor: colors.border.light,
  },
  iconContainer: {
    width: 44,
    height: 44,
    borderRadius: borderRadius.lg,
    alignItems: 'center',
    justifyContent: 'center',
  },
  itemContent: {
    flex: 1,
  },
  itemTitle: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.primary,
  },
  itemTitleCompleted: {
    textDecorationLine: 'line-through',
    color: colors.text.tertiary,
  },
  itemDescription: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.secondary,
    marginTop: 2,
  },
});

export default OnboardingChecklist;

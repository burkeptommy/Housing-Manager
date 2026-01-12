import React, { useState, useCallback, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Alert,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useRouter, useLocalSearchParams, Stack } from 'expo-router';
import { askAlfredAboutTask } from '../../../../src/lib/navigation';
import { Ionicons } from '@expo/vector-icons';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { Card, Button, Badge } from '../../../../src/components';
import { colors, typography, spacing, borderRadius } from '../../../../src/lib/theme';
import {
  getChecklistItemById,
  CHECKLIST_CATEGORIES,
  FREQUENCY_LABELS,
  DIFFICULTY_LABELS,
  type ChecklistItem,
} from '../../../../src/lib/checklists';

// =============================================================================
// STORAGE
// =============================================================================

const COMPLETED_ITEMS_KEY = 'haven_checklist_completed';

interface CompletedItem {
  itemId: string;
  completedAt: string;
}

// =============================================================================
// CHECKLIST DETAIL SCREEN
// =============================================================================

export default function ChecklistDetailScreen() {
  const router = useRouter();
  const { id } = useLocalSearchParams<{ id: string }>();
  const [item, setItem] = useState<ChecklistItem | null>(null);
  const [isCompleted, setIsCompleted] = useState(false);
  const [lastCompleted, setLastCompleted] = useState<Date | null>(null);
  const [isLoading, setIsLoading] = useState(false);

  // Load item and completion status
  useEffect(() => {
    if (id) {
      const checklistItem = getChecklistItemById(id);
      setItem(checklistItem || null);
      loadCompletionStatus(id);
    }
  }, [id]);

  const loadCompletionStatus = async (itemId: string) => {
    try {
      const stored = await AsyncStorage.getItem(COMPLETED_ITEMS_KEY);
      if (stored) {
        const completedItems: CompletedItem[] = JSON.parse(stored);
        const completed = completedItems.find(c => c.itemId === itemId);
        if (completed) {
          const completedDate = new Date(completed.completedAt);
          setLastCompleted(completedDate);

          // Check if still valid based on frequency
          const now = new Date();
          const daysSince = Math.floor(
            (now.getTime() - completedDate.getTime()) / (1000 * 60 * 60 * 24)
          );

          const checklistItem = getChecklistItemById(itemId);
          if (checklistItem) {
            let isStillValid = false;
            switch (checklistItem.frequency) {
              case 'monthly':
                isStillValid = daysSince < 30;
                break;
              case 'quarterly':
                isStillValid = daysSince < 90;
                break;
              case 'semi-annual':
                isStillValid = daysSince < 180;
                break;
              case 'annual':
                isStillValid = daysSince < 365;
                break;
              default:
                isStillValid = daysSince < 365;
            }
            setIsCompleted(isStillValid);
          }
        }
      }
    } catch (error) {
      console.error('Failed to load completion status:', error);
    }
  };

  const toggleComplete = useCallback(async () => {
    if (!item) return;

    setIsLoading(true);
    try {
      const stored = await AsyncStorage.getItem(COMPLETED_ITEMS_KEY);
      let completedItems: CompletedItem[] = stored ? JSON.parse(stored) : [];

      if (isCompleted) {
        // Remove from completed
        completedItems = completedItems.filter(c => c.itemId !== item.id);
        setIsCompleted(false);
        setLastCompleted(null);
      } else {
        // Add to completed
        const now = new Date();
        completedItems = [
          ...completedItems.filter(c => c.itemId !== item.id),
          { itemId: item.id, completedAt: now.toISOString() },
        ];
        setIsCompleted(true);
        setLastCompleted(now);
      }

      await AsyncStorage.setItem(COMPLETED_ITEMS_KEY, JSON.stringify(completedItems));
    } catch (error) {
      console.error('Failed to toggle completion:', error);
      Alert.alert('Error', 'Failed to update completion status');
    } finally {
      setIsLoading(false);
    }
  }, [item, isCompleted]);

  const handleBookHandyman = () => {
    router.push('/(tabs)/manager/handyman' as any);
  };

  const handleFindVendor = () => {
    router.push('/(tabs)/manager/vendors' as any);
  };

  const handleAskAlfred = () => {
    askAlfredAboutTask(item?.title || 'this task');
  };

  if (!item) {
    return (
      <SafeAreaView style={styles.container} edges={['bottom']}>
        <Stack.Screen options={{ title: 'Not Found' }} />
        <View style={styles.notFound}>
          <Ionicons name="alert-circle" size={48} color={colors.haven.navy[300]} />
          <Text style={styles.notFoundText}>Checklist item not found</Text>
          <Button
            title="Go Back"
            onPress={() => router.back()}
            style={styles.backButton}
          />
        </View>
      </SafeAreaView>
    );
  }

  const categoryInfo = CHECKLIST_CATEGORIES[item.category];
  const difficultyInfo = DIFFICULTY_LABELS[item.diyDifficulty];

  return (
    <SafeAreaView style={styles.container} edges={['bottom']}>
      <Stack.Screen
        options={{
          title: 'Task Details',
        }}
      />

      <ScrollView
        contentContainerStyle={styles.scrollContent}
        showsVerticalScrollIndicator={false}
      >
        {/* Header Card */}
        <Card style={styles.headerCard}>
          <View style={styles.headerTop}>
            <View
              style={[
                styles.iconContainer,
                { backgroundColor: categoryInfo.color + '20' },
              ]}
            >
              <Ionicons
                name={item.icon as any}
                size={32}
                color={categoryInfo.color}
              />
            </View>
            <TouchableOpacity
              style={[
                styles.completeButton,
                isCompleted && styles.completeButtonDone,
              ]}
              onPress={toggleComplete}
              disabled={isLoading}
            >
              {isCompleted ? (
                <>
                  <Ionicons name="checkmark-circle" size={20} color={colors.white} />
                  <Text style={styles.completeButtonTextDone}>Completed</Text>
                </>
              ) : (
                <>
                  <Ionicons name="checkmark-circle-outline" size={20} color={colors.haven.champagne[500]} />
                  <Text style={styles.completeButtonText}>Mark Complete</Text>
                </>
              )}
            </TouchableOpacity>
          </View>

          <Text style={styles.title}>{item.title}</Text>
          <Text style={styles.description}>{item.description}</Text>

          {/* Badges */}
          <View style={styles.badgeRow}>
            <Badge
              label={categoryInfo.label}
              variant="default"
              size="sm"
              style={{ backgroundColor: categoryInfo.color + '20' }}
            />
            <Badge
              label={FREQUENCY_LABELS[item.frequency]}
              variant="default"
              size="sm"
            />
            {item.canHandymanDo && (
              <Badge
                label="Handyman OK"
                variant="success"
                size="sm"
              />
            )}
          </View>

          {/* Last Completed */}
          {lastCompleted && (
            <View style={styles.lastCompletedContainer}>
              <Ionicons name="time-outline" size={16} color={colors.status.success} />
              <Text style={styles.lastCompletedText}>
                Last completed: {lastCompleted.toLocaleDateString()}
              </Text>
            </View>
          )}
        </Card>

        {/* Cost & Difficulty */}
        <Card style={styles.infoCard}>
          <View style={styles.infoRow}>
            <View style={styles.infoItem}>
              <Text style={styles.infoLabel}>Typical Cost</Text>
              <Text style={styles.infoValue}>
                {item.typicalCost.min === 0 && item.typicalCost.max === 0
                  ? 'Free (DIY)'
                  : item.typicalCost.min === item.typicalCost.max
                  ? `$${item.typicalCost.min}`
                  : `$${item.typicalCost.min} - $${item.typicalCost.max}`}
              </Text>
            </View>
            <View style={styles.infoDivider} />
            <View style={styles.infoItem}>
              <Text style={styles.infoLabel}>DIY Difficulty</Text>
              <View style={styles.difficultyRow}>
                <Text style={styles.infoValue}>{difficultyInfo.label}</Text>
                <View
                  style={[
                    styles.difficultyDot,
                    {
                      backgroundColor:
                        item.diyDifficulty === 'easy'
                          ? colors.status.success
                          : item.diyDifficulty === 'medium'
                          ? colors.haven.champagne[500]
                          : item.diyDifficulty === 'hard'
                          ? colors.status.warning
                          : colors.status.error,
                    },
                  ]}
                />
              </View>
              <Text style={styles.infoSubtext}>{difficultyInfo.description}</Text>
            </View>
          </View>
        </Card>

        {/* Tips */}
        {item.tips && item.tips.length > 0 && (
          <Card style={styles.section}>
            <View style={styles.sectionHeader}>
              <Ionicons name="bulb-outline" size={20} color={colors.haven.champagne[500]} />
              <Text style={styles.sectionTitle}>Pro Tips</Text>
            </View>
            {item.tips.map((tip, index) => (
              <View key={index} style={styles.tipItem}>
                <View style={styles.tipBullet} />
                <Text style={styles.tipText}>{tip}</Text>
              </View>
            ))}
          </Card>
        )}

        {/* Warning Signs */}
        {item.warningSign && (
          <Card style={[styles.section, styles.warningCard]}>
            <View style={styles.sectionHeader}>
              <Ionicons name="warning-outline" size={20} color={colors.status.warning} />
              <Text style={[styles.sectionTitle, styles.warningTitle]}>Warning Signs</Text>
            </View>
            <Text style={styles.warningText}>{item.warningSign}</Text>
          </Card>
        )}

        {/* When to Do It */}
        <Card style={styles.section}>
          <View style={styles.sectionHeader}>
            <Ionicons name="calendar-outline" size={20} color={colors.haven.navy[500]} />
            <Text style={styles.sectionTitle}>When to Do This</Text>
          </View>
          <View style={styles.monthsGrid}>
            {[
              'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
              'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
            ].map((month, index) => {
              const isReminderMonth = item.reminderMonths.includes(index + 1);
              const isCurrentMonth = new Date().getMonth() === index;
              return (
                <View
                  key={month}
                  style={[
                    styles.monthBadge,
                    isReminderMonth && styles.monthBadgeActive,
                    isCurrentMonth && styles.monthBadgeCurrent,
                  ]}
                >
                  <Text
                    style={[
                      styles.monthText,
                      isReminderMonth && styles.monthTextActive,
                    ]}
                  >
                    {month}
                  </Text>
                </View>
              );
            })}
          </View>
        </Card>

        {/* Action Buttons */}
        <View style={styles.actionsSection}>
          <Text style={styles.actionsTitle}>Get Help</Text>

          {item.canHandymanDo && (
            <TouchableOpacity
              style={styles.actionCard}
              onPress={handleBookHandyman}
            >
              <View style={[styles.actionIcon, { backgroundColor: colors.haven.champagne[50] }]}>
                <Ionicons name="hammer" size={24} color={colors.haven.champagne[500]} />
              </View>
              <View style={styles.actionContent}>
                <Text style={styles.actionTitle}>Book Handyman</Text>
                <Text style={styles.actionDescription}>
                  Schedule our trusted handyman to do this for you
                </Text>
              </View>
              <Ionicons name="chevron-forward" size={20} color={colors.text.tertiary} />
            </TouchableOpacity>
          )}

          {item.diyDifficulty === 'professional' && (
            <TouchableOpacity
              style={styles.actionCard}
              onPress={handleFindVendor}
            >
              <View style={[styles.actionIcon, { backgroundColor: colors.haven.navy[50] }]}>
                <Ionicons name="business" size={24} color={colors.haven.navy[500]} />
              </View>
              <View style={styles.actionContent}>
                <Text style={styles.actionTitle}>Find a Vendor</Text>
                <Text style={styles.actionDescription}>
                  Connect with licensed professionals in your area
                </Text>
              </View>
              <Ionicons name="chevron-forward" size={20} color={colors.text.tertiary} />
            </TouchableOpacity>
          )}

          <TouchableOpacity
            style={styles.actionCard}
            onPress={handleAskAlfred}
          >
            <View style={[styles.actionIcon, { backgroundColor: colors.haven.champagne[50] }]}>
              <Ionicons name="sparkles" size={24} color={colors.haven.champagne[500]} />
            </View>
            <View style={styles.actionContent}>
              <Text style={styles.actionTitle}>Ask Alfred</Text>
              <Text style={styles.actionDescription}>
                Get personalized advice or schedule this task
              </Text>
            </View>
            <Ionicons name="chevron-forward" size={20} color={colors.text.tertiary} />
          </TouchableOpacity>
        </View>
      </ScrollView>

      {/* Bottom Action */}
      <View style={styles.footer}>
        <Button
          title={isCompleted ? 'Mark as Not Done' : 'Mark as Complete'}
          variant={isCompleted ? 'secondary' : 'primary'}
          onPress={toggleComplete}
          loading={isLoading}
          fullWidth
        />
      </View>
    </SafeAreaView>
  );
}

// =============================================================================
// STYLES
// =============================================================================

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background.secondary,
  },
  scrollContent: {
    padding: spacing[4],
    paddingBottom: spacing[24],
  },
  notFound: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    padding: spacing[6],
  },
  notFoundText: {
    fontSize: typography.fontSizes.lg,
    color: colors.text.secondary,
    marginTop: spacing[4],
    marginBottom: spacing[6],
  },
  backButton: {
    minWidth: 120,
  },
  headerCard: {
    padding: spacing[5],
    marginBottom: spacing[4],
  },
  headerTop: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    marginBottom: spacing[4],
  },
  iconContainer: {
    width: 64,
    height: 64,
    borderRadius: borderRadius.xl,
    alignItems: 'center',
    justifyContent: 'center',
  },
  completeButton: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: spacing[2],
    paddingHorizontal: spacing[3],
    borderRadius: borderRadius.full,
    borderWidth: 1,
    borderColor: colors.haven.champagne[200],
    backgroundColor: colors.haven.champagne[50],
    gap: spacing[1],
  },
  completeButtonDone: {
    backgroundColor: colors.status.success,
    borderColor: colors.status.success,
  },
  completeButtonText: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.haven.champagne[600],
  },
  completeButtonTextDone: {
    color: colors.white,
  },
  title: {
    fontSize: typography.fontSizes.xl,
    fontWeight: typography.fontWeights.bold,
    color: colors.text.primary,
    marginBottom: spacing[2],
  },
  description: {
    fontSize: typography.fontSizes.base,
    color: colors.text.secondary,
    lineHeight: 24,
    marginBottom: spacing[4],
  },
  badgeRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: spacing[2],
  },
  lastCompletedContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[2],
    marginTop: spacing[4],
    padding: spacing[3],
    backgroundColor: colors.status.successLight,
    borderRadius: borderRadius.lg,
  },
  lastCompletedText: {
    fontSize: typography.fontSizes.sm,
    color: colors.status.success,
    fontWeight: typography.fontWeights.medium,
  },
  infoCard: {
    padding: spacing[4],
    marginBottom: spacing[4],
  },
  infoRow: {
    flexDirection: 'row',
  },
  infoItem: {
    flex: 1,
  },
  infoDivider: {
    width: 1,
    backgroundColor: colors.border.light,
    marginHorizontal: spacing[4],
  },
  infoLabel: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
    textTransform: 'uppercase',
    marginBottom: spacing[1],
  },
  infoValue: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
  },
  infoSubtext: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.secondary,
    marginTop: spacing[0.5],
  },
  difficultyRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[2],
  },
  difficultyDot: {
    width: 8,
    height: 8,
    borderRadius: 4,
  },
  section: {
    padding: spacing[4],
    marginBottom: spacing[4],
  },
  sectionHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[2],
    marginBottom: spacing[3],
  },
  sectionTitle: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
  },
  tipItem: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    marginBottom: spacing[2],
  },
  tipBullet: {
    width: 6,
    height: 6,
    borderRadius: 3,
    backgroundColor: colors.haven.champagne[500],
    marginTop: 8,
    marginRight: spacing[3],
  },
  tipText: {
    flex: 1,
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    lineHeight: 22,
  },
  warningCard: {
    backgroundColor: colors.status.warningLight,
    borderWidth: 1,
    borderColor: colors.status.warning + '30',
  },
  warningTitle: {
    color: colors.status.warning,
  },
  warningText: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.primary,
    lineHeight: 22,
  },
  monthsGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: spacing[2],
  },
  monthBadge: {
    width: '15%',
    paddingVertical: spacing[2],
    borderRadius: borderRadius.md,
    backgroundColor: colors.gray[100],
    alignItems: 'center',
  },
  monthBadgeActive: {
    backgroundColor: colors.haven.champagne[100],
  },
  monthBadgeCurrent: {
    borderWidth: 2,
    borderColor: colors.haven.champagne[500],
  },
  monthText: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
    fontWeight: typography.fontWeights.medium,
  },
  monthTextActive: {
    color: colors.haven.champagne[600],
  },
  actionsSection: {
    marginBottom: spacing[4],
  },
  actionsTitle: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.secondary,
    marginBottom: spacing[3],
    textTransform: 'uppercase',
  },
  actionCard: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.white,
    padding: spacing[4],
    borderRadius: borderRadius.xl,
    marginBottom: spacing[2],
    shadowColor: colors.black,
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.05,
    shadowRadius: 2,
    elevation: 1,
  },
  actionIcon: {
    width: 48,
    height: 48,
    borderRadius: borderRadius.lg,
    alignItems: 'center',
    justifyContent: 'center',
  },
  actionContent: {
    flex: 1,
    marginLeft: spacing[3],
  },
  actionTitle: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
  },
  actionDescription: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    marginTop: spacing[0.5],
  },
  footer: {
    padding: spacing[4],
    backgroundColor: colors.white,
    borderTopWidth: 1,
    borderTopColor: colors.border.light,
  },
});

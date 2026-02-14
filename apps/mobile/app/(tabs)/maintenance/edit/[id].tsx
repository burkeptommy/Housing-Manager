import React, { useState, useEffect, useCallback } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Alert,
  KeyboardAvoidingView,
  Platform,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useRouter, useLocalSearchParams, Stack } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import DateTimePicker from '@react-native-community/datetimepicker';
import { useAuth } from '../../../../src/contexts/auth-context';
import { Card, Button, Input, LoadingSpinner, ImageUpload } from '../../../../src/components';
import { colors, typography, spacing, borderRadius } from '../../../../src/lib/theme';
import { API_BASE_URL } from '../../../../src/lib/api';
import { getIdToken } from '../../../../src/lib/firebase';

interface MaintenanceTask {
  id: string;
  title: string;
  description?: string;
  category: string;
  priority: string;
  status: string;
  dueDate?: string;
  estimatedCost?: number;
  frequency?: string;
  vendor?: {
    id: string;
    companyName: string;
  };
  photos?: string[];
}

const CATEGORIES = [
  { id: 'HVAC', label: 'HVAC', icon: 'thermometer-outline' },
  { id: 'PLUMBING', label: 'Plumbing', icon: 'water-outline' },
  { id: 'ELECTRICAL', label: 'Electrical', icon: 'flash-outline' },
  { id: 'LANDSCAPING', label: 'Landscaping', icon: 'leaf-outline' },
  { id: 'POOL', label: 'Pool & Spa', icon: 'water-outline' },
  { id: 'CLEANING', label: 'Cleaning', icon: 'sparkles-outline' },
  { id: 'SECURITY', label: 'Security', icon: 'shield-checkmark-outline' },
  { id: 'GENERAL', label: 'General', icon: 'construct-outline' },
];

const PRIORITIES = [
  { id: 'LOW', label: 'Low', color: colors.status.info },
  { id: 'NORMAL', label: 'Normal', color: colors.haven.purple[500] },
  { id: 'HIGH', label: 'High', color: colors.status.warning },
  { id: 'URGENT', label: 'Urgent', color: colors.status.error },
];

const FREQUENCIES = [
  { id: 'ONCE', label: 'One-time' },
  { id: 'WEEKLY', label: 'Weekly' },
  { id: 'BIWEEKLY', label: 'Every 2 weeks' },
  { id: 'MONTHLY', label: 'Monthly' },
  { id: 'QUARTERLY', label: 'Quarterly' },
  { id: 'BIANNUALLY', label: 'Every 6 months' },
  { id: 'ANNUALLY', label: 'Yearly' },
];

export default function EditMaintenanceScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const router = useRouter();
  const { householdInfo } = useAuth();
  const [isLoading, setIsLoading] = useState(true);
  const [isSaving, setIsSaving] = useState(false);
  const [showDatePicker, setShowDatePicker] = useState(false);

  const [formData, setFormData] = useState({
    title: '',
    description: '',
    category: 'GENERAL',
    priority: 'NORMAL',
    dueDate: new Date(),
    estimatedCost: '',
    frequency: 'ONCE',
  });

  const fetchTask = useCallback(async () => {
    if (!id || !householdInfo?.id) {
      setIsLoading(false);
      return;
    }

    try {
      const token = await getIdToken(true);
      if (!token) {
        setIsLoading(false);
        return;
      }

      const response = await fetch(`${API_BASE_URL}/maintenance-tasks/${id}`, {
        headers: {
          Authorization: `Bearer ${token}`,
        },
      });

      if (response.ok) {
        const task: MaintenanceTask = await response.json();
        setFormData({
          title: task.title || '',
          description: task.description || '',
          category: task.category || 'GENERAL',
          priority: task.priority || 'NORMAL',
          dueDate: task.dueDate ? new Date(task.dueDate) : new Date(),
          estimatedCost: task.estimatedCost?.toString() || '',
          frequency: task.frequency || 'ONCE',
        });
      }
    } catch (err) {
      console.error('Fetch task error:', err);
    } finally {
      setIsLoading(false);
    }
  }, [id, householdInfo?.id]);

  useEffect(() => {
    fetchTask();
  }, [fetchTask]);

  const handleSave = async () => {
    if (!formData.title.trim()) {
      Alert.alert('Required', 'Task name is required');
      return;
    }

    setIsSaving(true);
    try {
      const token = await getIdToken(true);
      if (!token) {
        Alert.alert('Error', 'Authentication expired');
        return;
      }

      const body = {
        title: formData.title.trim(),
        description: formData.description.trim() || null,
        category: formData.category,
        priority: formData.priority,
        dueDate: formData.dueDate.toISOString(),
        estimatedCost: formData.estimatedCost ? parseFloat(formData.estimatedCost) : null,
        frequency: formData.frequency,
      };

      const response = await fetch(`${API_BASE_URL}/maintenance-tasks/${id}`, {
        method: 'PATCH',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(body),
      });

      if (!response.ok) {
        throw new Error('Failed to update task');
      }

      Alert.alert('Success', 'Task updated successfully', [
        { text: 'OK', onPress: () => router.back() },
      ]);
    } catch (error) {
      console.error('Update task error:', error);
      Alert.alert('Error', 'Failed to update task. Please try again.');
    } finally {
      setIsSaving(false);
    }
  };

  if (isLoading) {
    return <LoadingSpinner fullScreen message="Loading task..." />;
  }

  return (
    <SafeAreaView style={styles.container} edges={['bottom']}>
      <Stack.Screen options={{ title: 'Edit Task' }} />
      <KeyboardAvoidingView
        behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
        style={styles.keyboardView}
      >
        <ScrollView
          contentContainerStyle={styles.scrollContent}
          showsVerticalScrollIndicator={false}
        >
          {/* Basic Info */}
          <Card style={styles.card}>
            <Text style={styles.cardTitle}>Task Details</Text>

            <Input
              label="Task Name"
              value={formData.title}
              onChangeText={(v) => setFormData({ ...formData, title: v })}
              placeholder="e.g., HVAC Filter Replacement"
              leftIcon="create-outline"
            />

            <Input
              label="Description"
              value={formData.description}
              onChangeText={(v) => setFormData({ ...formData, description: v })}
              placeholder="Add details about this task..."
              multiline
              numberOfLines={3}
            />
          </Card>

          {/* Category */}
          <Card style={styles.card}>
            <Text style={styles.cardTitle}>Category</Text>
            <View style={styles.optionsGrid}>
              {CATEGORIES.map((cat) => (
                <TouchableOpacity
                  key={cat.id}
                  style={[
                    styles.optionItem,
                    formData.category === cat.id && styles.optionItemSelected,
                  ]}
                  onPress={() => setFormData({ ...formData, category: cat.id })}
                >
                  <Ionicons
                    name={cat.icon as any}
                    size={20}
                    color={formData.category === cat.id ? colors.haven.purple[500] : colors.text.secondary}
                  />
                  <Text
                    style={[
                      styles.optionLabel,
                      formData.category === cat.id && styles.optionLabelSelected,
                    ]}
                  >
                    {cat.label}
                  </Text>
                </TouchableOpacity>
              ))}
            </View>
          </Card>

          {/* Priority */}
          <Card style={styles.card}>
            <Text style={styles.cardTitle}>Priority</Text>
            <View style={styles.priorityRow}>
              {PRIORITIES.map((pri) => (
                <TouchableOpacity
                  key={pri.id}
                  style={[
                    styles.priorityItem,
                    formData.priority === pri.id && { borderColor: pri.color, backgroundColor: `${pri.color}10` },
                  ]}
                  onPress={() => setFormData({ ...formData, priority: pri.id })}
                >
                  <View style={[styles.priorityDot, { backgroundColor: pri.color }]} />
                  <Text
                    style={[
                      styles.priorityLabel,
                      formData.priority === pri.id && { color: pri.color },
                    ]}
                  >
                    {pri.label}
                  </Text>
                </TouchableOpacity>
              ))}
            </View>
          </Card>

          {/* Schedule */}
          <Card style={styles.card}>
            <Text style={styles.cardTitle}>Schedule</Text>

            <TouchableOpacity
              style={styles.dateButton}
              onPress={() => setShowDatePicker(true)}
            >
              <Ionicons name="calendar-outline" size={20} color={colors.haven.purple[500]} />
              <View style={styles.dateContent}>
                <Text style={styles.dateLabel}>Due Date</Text>
                <Text style={styles.dateValue}>
                  {formData.dueDate.toLocaleDateString('en-US', {
                    weekday: 'short',
                    month: 'short',
                    day: 'numeric',
                    year: 'numeric',
                  })}
                </Text>
              </View>
              <Ionicons name="chevron-forward" size={20} color={colors.text.tertiary} />
            </TouchableOpacity>

            {showDatePicker && (
              <DateTimePicker
                value={formData.dueDate}
                mode="date"
                display="spinner"
                onChange={(_event: any, date?: Date) => {
                  setShowDatePicker(Platform.OS === 'ios');
                  if (date) setFormData({ ...formData, dueDate: date });
                }}
              />
            )}

            <Text style={styles.subLabel}>Frequency</Text>
            <View style={styles.frequencyGrid}>
              {FREQUENCIES.map((freq) => (
                <TouchableOpacity
                  key={freq.id}
                  style={[
                    styles.frequencyItem,
                    formData.frequency === freq.id && styles.frequencyItemSelected,
                  ]}
                  onPress={() => setFormData({ ...formData, frequency: freq.id })}
                >
                  <Text
                    style={[
                      styles.frequencyLabel,
                      formData.frequency === freq.id && styles.frequencyLabelSelected,
                    ]}
                  >
                    {freq.label}
                  </Text>
                </TouchableOpacity>
              ))}
            </View>
          </Card>

          {/* Cost */}
          <Card style={styles.card}>
            <Text style={styles.cardTitle}>Budget</Text>
            <Input
              label="Estimated Cost"
              value={formData.estimatedCost}
              onChangeText={(v) => setFormData({ ...formData, estimatedCost: v.replace(/[^0-9.]/g, '') })}
              keyboardType="decimal-pad"
              leftIcon="cash-outline"
              placeholder="0.00"
            />
          </Card>
        </ScrollView>

        {/* Footer */}
        <View style={styles.footer}>
          <Button
            title="Cancel"
            variant="outline"
            onPress={() => router.back()}
            style={styles.cancelButton}
          />
          <Button
            title="Save Changes"
            onPress={handleSave}
            loading={isSaving}
            disabled={isSaving}
            style={styles.saveButton}
          />
        </View>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background.secondary,
  },
  keyboardView: {
    flex: 1,
  },
  scrollContent: {
    padding: spacing[4],
  },
  card: {
    padding: spacing[4],
    marginBottom: spacing[4],
  },
  cardTitle: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
    marginBottom: spacing[4],
  },
  optionsGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: spacing[2],
  },
  optionItem: {
    width: '48%',
    flexDirection: 'row',
    alignItems: 'center',
    padding: spacing[3],
    borderRadius: borderRadius.lg,
    borderWidth: 1,
    borderColor: colors.border.default,
    backgroundColor: colors.white,
    gap: spacing[2],
  },
  optionItemSelected: {
    borderColor: colors.haven.purple[500],
    backgroundColor: colors.haven.purple[50],
  },
  optionLabel: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
  },
  optionLabelSelected: {
    color: colors.haven.purple[600],
    fontWeight: typography.fontWeights.medium,
  },
  priorityRow: {
    flexDirection: 'row',
    gap: spacing[2],
  },
  priorityItem: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    padding: spacing[3],
    borderRadius: borderRadius.lg,
    borderWidth: 1,
    borderColor: colors.border.default,
    backgroundColor: colors.white,
    gap: spacing[1],
  },
  priorityDot: {
    width: 8,
    height: 8,
    borderRadius: 4,
  },
  priorityLabel: {
    fontSize: typography.fontSizes.xs,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.secondary,
  },
  dateButton: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: spacing[3],
    borderRadius: borderRadius.lg,
    backgroundColor: colors.gray[50],
    borderWidth: 1,
    borderColor: colors.border.default,
    marginBottom: spacing[4],
  },
  dateContent: {
    flex: 1,
    marginLeft: spacing[3],
  },
  dateLabel: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
  },
  dateValue: {
    fontSize: typography.fontSizes.base,
    color: colors.text.primary,
    marginTop: 2,
  },
  subLabel: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.secondary,
    marginBottom: spacing[2],
  },
  frequencyGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: spacing[2],
  },
  frequencyItem: {
    paddingVertical: spacing[2],
    paddingHorizontal: spacing[3],
    borderRadius: borderRadius.full,
    borderWidth: 1,
    borderColor: colors.border.default,
    backgroundColor: colors.white,
  },
  frequencyItemSelected: {
    borderColor: colors.haven.purple[500],
    backgroundColor: colors.haven.purple[50],
  },
  frequencyLabel: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
  },
  frequencyLabelSelected: {
    color: colors.haven.purple[600],
    fontWeight: typography.fontWeights.medium,
  },
  footer: {
    flexDirection: 'row',
    padding: spacing[4],
    backgroundColor: colors.white,
    borderTopWidth: 1,
    borderTopColor: colors.border.light,
    gap: spacing[3],
  },
  cancelButton: {
    flex: 1,
  },
  saveButton: {
    flex: 1,
  },
});

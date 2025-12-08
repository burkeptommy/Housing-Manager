import { useState, useEffect } from 'react';
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  ScrollView,
  Alert,
  ActivityIndicator,
  KeyboardAvoidingView,
  Platform,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useRouter } from 'expo-router';
import { useAuth } from '../../src/contexts/auth-context';
import { getApiClient } from '../../src/lib/api';
import { colors, spacing, typography, borderRadius, shadows } from '../../src/lib/theme';
import type { ServiceCategory, ServiceRequestPriority } from '@haven/core';

const PRIORITIES: { value: ServiceRequestPriority; label: string; color: string }[] = [
  { value: 'LOW', label: 'Low', color: colors.slate[400] },
  { value: 'MEDIUM', label: 'Medium', color: colors.info },
  { value: 'HIGH', label: 'High', color: colors.warning },
  { value: 'URGENT', label: 'Urgent', color: colors.error },
];

export default function NewRequestScreen() {
  const router = useRouter();
  const { currentHousehold } = useAuth();
  const api = getApiClient();

  const [categories, setCategories] = useState<ServiceCategory[]>([]);
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [selectedCategory, setSelectedCategory] = useState<string | null>(null);
  const [priority, setPriority] = useState<ServiceRequestPriority>('MEDIUM');
  const [notes, setNotes] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [isFetchingCategories, setIsFetchingCategories] = useState(true);

  useEffect(() => {
    const fetchCategories = async () => {
      try {
        const data = await api.getServiceCategories();
        setCategories(data.filter((c) => c.isActive));
      } catch (error) {
        console.error('Failed to fetch categories:', error);
      } finally {
        setIsFetchingCategories(false);
      }
    };
    fetchCategories();
  }, [api]);

  const handleSubmit = async () => {
    if (!currentHousehold) {
      Alert.alert('Error', 'No household selected');
      return;
    }

    if (!title.trim()) {
      Alert.alert('Error', 'Please enter a title for your request');
      return;
    }

    if (!description.trim()) {
      Alert.alert('Error', 'Please describe your request');
      return;
    }

    setIsLoading(true);
    try {
      await api.createServiceRequest({
        householdId: currentHousehold.id,
        title: title.trim(),
        description: description.trim(),
        categoryId: selectedCategory || undefined,
        priority,
        notes: notes.trim() || undefined,
      });

      Alert.alert('Success', 'Your request has been submitted', [
        {
          text: 'OK',
          onPress: () => router.replace('/(tabs)'),
        },
      ]);
    } catch (error: any) {
      Alert.alert('Error', error.message || 'Failed to create request');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <SafeAreaView style={styles.container} edges={['bottom']}>
      <KeyboardAvoidingView
        behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
        style={styles.keyboardView}
      >
        <ScrollView
          contentContainerStyle={styles.scrollContent}
          keyboardShouldPersistTaps="handled"
        >
          <View style={styles.form}>
            {/* Title */}
            <View style={styles.inputGroup}>
              <Text style={styles.label}>Title *</Text>
              <TextInput
                style={styles.input}
                placeholder="What do you need help with?"
                placeholderTextColor={colors.slate[400]}
                value={title}
                onChangeText={setTitle}
              />
            </View>

            {/* Description */}
            <View style={styles.inputGroup}>
              <Text style={styles.label}>Description *</Text>
              <TextInput
                style={[styles.input, styles.textArea]}
                placeholder="Describe the issue or request in detail..."
                placeholderTextColor={colors.slate[400]}
                value={description}
                onChangeText={setDescription}
                multiline
                numberOfLines={4}
                textAlignVertical="top"
              />
            </View>

            {/* Category */}
            <View style={styles.inputGroup}>
              <Text style={styles.label}>Category</Text>
              {isFetchingCategories ? (
                <ActivityIndicator size="small" color={colors.primary[600]} />
              ) : (
                <ScrollView
                  horizontal
                  showsHorizontalScrollIndicator={false}
                  contentContainerStyle={styles.categoryList}
                >
                  {categories.map((category) => (
                    <TouchableOpacity
                      key={category.id}
                      style={[
                        styles.categoryChip,
                        selectedCategory === category.id && styles.categoryChipActive,
                      ]}
                      onPress={() =>
                        setSelectedCategory(
                          selectedCategory === category.id ? null : category.id
                        )
                      }
                    >
                      {category.icon && (
                        <Text style={styles.categoryIcon}>{category.icon}</Text>
                      )}
                      <Text
                        style={[
                          styles.categoryText,
                          selectedCategory === category.id && styles.categoryTextActive,
                        ]}
                      >
                        {category.name}
                      </Text>
                    </TouchableOpacity>
                  ))}
                </ScrollView>
              )}
            </View>

            {/* Priority */}
            <View style={styles.inputGroup}>
              <Text style={styles.label}>Priority</Text>
              <View style={styles.priorityRow}>
                {PRIORITIES.map((p) => (
                  <TouchableOpacity
                    key={p.value}
                    style={[
                      styles.priorityButton,
                      priority === p.value && {
                        backgroundColor: p.color + '20',
                        borderColor: p.color,
                      },
                    ]}
                    onPress={() => setPriority(p.value)}
                  >
                    <View
                      style={[
                        styles.priorityDot,
                        { backgroundColor: p.color },
                      ]}
                    />
                    <Text
                      style={[
                        styles.priorityText,
                        priority === p.value && { color: p.color },
                      ]}
                    >
                      {p.label}
                    </Text>
                  </TouchableOpacity>
                ))}
              </View>
            </View>

            {/* Additional Notes */}
            <View style={styles.inputGroup}>
              <Text style={styles.label}>Additional Notes</Text>
              <TextInput
                style={[styles.input, styles.textArea]}
                placeholder="Any other information that might be helpful..."
                placeholderTextColor={colors.slate[400]}
                value={notes}
                onChangeText={setNotes}
                multiline
                numberOfLines={3}
                textAlignVertical="top"
              />
            </View>
          </View>

          {/* Submit Button */}
          <TouchableOpacity
            style={[styles.submitButton, isLoading && styles.submitButtonDisabled]}
            onPress={handleSubmit}
            disabled={isLoading}
          >
            {isLoading ? (
              <ActivityIndicator color={colors.white} />
            ) : (
              <Text style={styles.submitButtonText}>Submit Request</Text>
            )}
          </TouchableOpacity>
        </ScrollView>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.slate[50],
  },
  keyboardView: {
    flex: 1,
  },
  scrollContent: {
    padding: spacing[4],
  },
  form: {
    backgroundColor: colors.white,
    borderRadius: borderRadius.xl,
    padding: spacing[4],
    marginBottom: spacing[4],
    ...shadows.sm,
  },
  inputGroup: {
    marginBottom: spacing[5],
  },
  label: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.slate[700],
    marginBottom: spacing[2],
  },
  input: {
    backgroundColor: colors.slate[50],
    borderWidth: 1,
    borderColor: colors.slate[200],
    borderRadius: borderRadius.lg,
    padding: spacing[4],
    fontSize: typography.fontSizes.base,
    color: colors.slate[900],
  },
  textArea: {
    minHeight: 100,
    paddingTop: spacing[3],
  },
  categoryList: {
    flexDirection: 'row',
    gap: spacing[2],
    paddingVertical: spacing[1],
  },
  categoryChip: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: spacing[4],
    paddingVertical: spacing[2],
    borderRadius: borderRadius.full,
    borderWidth: 1,
    borderColor: colors.slate[200],
    backgroundColor: colors.white,
  },
  categoryChipActive: {
    borderColor: colors.primary[600],
    backgroundColor: colors.primary[50],
  },
  categoryIcon: {
    fontSize: 16,
    marginRight: spacing[1],
  },
  categoryText: {
    fontSize: typography.fontSizes.sm,
    color: colors.slate[600],
  },
  categoryTextActive: {
    color: colors.primary[700],
    fontWeight: typography.fontWeights.medium,
  },
  priorityRow: {
    flexDirection: 'row',
    gap: spacing[2],
  },
  priorityButton: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: spacing[3],
    borderRadius: borderRadius.lg,
    borderWidth: 1,
    borderColor: colors.slate[200],
    backgroundColor: colors.white,
  },
  priorityDot: {
    width: 8,
    height: 8,
    borderRadius: 4,
    marginRight: spacing[2],
  },
  priorityText: {
    fontSize: typography.fontSizes.sm,
    color: colors.slate[600],
    fontWeight: typography.fontWeights.medium,
  },
  submitButton: {
    backgroundColor: colors.primary[600],
    borderRadius: borderRadius.lg,
    padding: spacing[4],
    alignItems: 'center',
  },
  submitButtonDisabled: {
    opacity: 0.7,
  },
  submitButtonText: {
    color: colors.white,
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
  },
});

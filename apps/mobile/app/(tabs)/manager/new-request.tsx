import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TextInput,
  TouchableOpacity,
  Alert,
  KeyboardAvoidingView,
  Platform,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useRouter, Stack } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import * as ImagePicker from 'expo-image-picker';
import { useAuth } from '../../../src/contexts/auth-context';
import { useSubscription } from '../../../src/contexts/subscription-context';
import { Card, Button } from '../../../src/components';
import { colors, typography, spacing, borderRadius } from '../../../src/lib/theme';
import { API_BASE_URL } from '../../../src/lib/api';
import { getIdToken } from '../../../src/lib/firebase';

const REQUEST_CATEGORIES = [
  { id: 'maintenance', label: 'Maintenance', icon: 'construct-outline' },
  { id: 'cleaning', label: 'Cleaning', icon: 'sparkles-outline' },
  { id: 'landscaping', label: 'Landscaping', icon: 'leaf-outline' },
  { id: 'pool', label: 'Pool & Spa', icon: 'water-outline' },
  { id: 'security', label: 'Security', icon: 'shield-checkmark-outline' },
  { id: 'other', label: 'Other', icon: 'ellipsis-horizontal-outline' },
];

const PRIORITY_OPTIONS = [
  { id: 'low', label: 'Low', description: 'When convenient' },
  { id: 'normal', label: 'Normal', description: 'Within a few days' },
  { id: 'high', label: 'High', description: 'As soon as possible' },
  { id: 'urgent', label: 'Urgent', description: 'Emergency - today' },
];

export default function NewRequestScreen() {
  const router = useRouter();
  const { householdInfo } = useAuth();
  const { isEssentials, managerInfo } = useSubscription();
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [category, setCategory] = useState<string | null>(null);
  const [priority, setPriority] = useState('normal');
  const [attachments, setAttachments] = useState<string[]>([]);
  const [isSubmitting, setIsSubmitting] = useState(false);

  const pickImage = async () => {
    const result = await ImagePicker.launchImageLibraryAsync({
      mediaTypes: ['images'],
      allowsMultipleSelection: true,
      quality: 0.8,
    });

    if (!result.canceled && result.assets) {
      const uris = result.assets.map(a => a.uri);
      setAttachments(prev => [...prev, ...uris]);
    }
  };

  const takePhoto = async () => {
    const { status } = await ImagePicker.requestCameraPermissionsAsync();
    if (status !== 'granted') {
      Alert.alert('Permission needed', 'Camera permission is required');
      return;
    }

    const result = await ImagePicker.launchCameraAsync({
      quality: 0.8,
    });

    if (!result.canceled && result.assets[0]) {
      setAttachments(prev => [...prev, result.assets[0].uri]);
    }
  };

  const removeAttachment = (index: number) => {
    setAttachments(prev => prev.filter((_, i) => i !== index));
  };

  const handleSubmit = async () => {
    if (!title.trim()) {
      Alert.alert('Required', 'Please enter a title for your request');
      return;
    }

    if (!category) {
      Alert.alert('Required', 'Please select a category');
      return;
    }

    setIsSubmitting(true);

    try {
      const token = await getIdToken(true);
      if (!token) {
        Alert.alert('Error', 'Authentication expired. Please sign in again.');
        return;
      }

      // Create a conversation for the request
      const response = await fetch(`${API_BASE_URL}/conversations`, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          subject: `[${category.toUpperCase()}] ${title}`,
          message: `**Priority:** ${priority.toUpperCase()}\n\n${description || 'No additional details provided.'}`,
        }),
      });

      if (!response.ok) {
        throw new Error('Failed to submit request');
      }

      const managerName = isEssentials ? 'Alfred' : managerInfo.name.split(' ')[0];

      Alert.alert(
        'Request Submitted',
        `${managerName} will review your request and get back to you shortly.`,
        [
          {
            text: 'OK',
            onPress: () => router.back(),
          },
        ]
      );
    } catch (err) {
      console.error('Submit request error:', err);
      Alert.alert('Error', 'Failed to submit request. Please try again.');
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <SafeAreaView style={styles.container} edges={['bottom']}>
      <Stack.Screen options={{ title: 'New Request' }} />
      <KeyboardAvoidingView
        behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
        style={styles.keyboardView}
      >
        <ScrollView
          contentContainerStyle={styles.scrollContent}
          showsVerticalScrollIndicator={false}
        >
          {/* Title */}
          <Card style={styles.section}>
            <Text style={styles.sectionTitle}>What do you need?</Text>
            <TextInput
              style={styles.titleInput}
              placeholder="e.g., Fix leaky faucet in master bathroom"
              placeholderTextColor={colors.text.tertiary}
              value={title}
              onChangeText={setTitle}
              maxLength={100}
            />
          </Card>

          {/* Category */}
          <Card style={styles.section}>
            <Text style={styles.sectionTitle}>Category</Text>
            <View style={styles.categoryGrid}>
              {REQUEST_CATEGORIES.map(cat => (
                <TouchableOpacity
                  key={cat.id}
                  style={[
                    styles.categoryItem,
                    category === cat.id && styles.categoryItemSelected,
                  ]}
                  onPress={() => setCategory(cat.id)}
                >
                  <Ionicons
                    name={cat.icon as any}
                    size={24}
                    color={
                      category === cat.id
                        ? colors.haven.champagne[500]
                        : colors.text.secondary
                    }
                  />
                  <Text
                    style={[
                      styles.categoryLabel,
                      category === cat.id && styles.categoryLabelSelected,
                    ]}
                  >
                    {cat.label}
                  </Text>
                </TouchableOpacity>
              ))}
            </View>
          </Card>

          {/* Priority */}
          <Card style={styles.section}>
            <Text style={styles.sectionTitle}>Priority</Text>
            <View style={styles.priorityList}>
              {PRIORITY_OPTIONS.map(opt => (
                <TouchableOpacity
                  key={opt.id}
                  style={[
                    styles.priorityItem,
                    priority === opt.id && styles.priorityItemSelected,
                  ]}
                  onPress={() => setPriority(opt.id)}
                >
                  <View style={styles.priorityRadio}>
                    {priority === opt.id && <View style={styles.priorityRadioInner} />}
                  </View>
                  <View style={styles.priorityContent}>
                    <Text
                      style={[
                        styles.priorityLabel,
                        priority === opt.id && styles.priorityLabelSelected,
                      ]}
                    >
                      {opt.label}
                    </Text>
                    <Text style={styles.priorityDescription}>{opt.description}</Text>
                  </View>
                </TouchableOpacity>
              ))}
            </View>
          </Card>

          {/* Description */}
          <Card style={styles.section}>
            <Text style={styles.sectionTitle}>Details (Optional)</Text>
            <TextInput
              style={styles.descriptionInput}
              placeholder="Add any additional details..."
              placeholderTextColor={colors.text.tertiary}
              value={description}
              onChangeText={setDescription}
              multiline
              numberOfLines={4}
              maxLength={500}
              textAlignVertical="top"
            />
          </Card>

          {/* Attachments */}
          <Card style={styles.section}>
            <Text style={styles.sectionTitle}>Photos (Optional)</Text>
            <View style={styles.attachmentButtons}>
              <TouchableOpacity style={styles.attachmentButton} onPress={takePhoto}>
                <Ionicons name="camera" size={24} color={colors.haven.champagne[500]} />
                <Text style={styles.attachmentButtonText}>Take Photo</Text>
              </TouchableOpacity>
              <TouchableOpacity style={styles.attachmentButton} onPress={pickImage}>
                <Ionicons name="images" size={24} color={colors.haven.champagne[500]} />
                <Text style={styles.attachmentButtonText}>Choose from Library</Text>
              </TouchableOpacity>
            </View>
            {attachments.length > 0 && (
              <View style={styles.attachmentPreview}>
                {attachments.map((uri, index) => (
                  <View key={index} style={styles.attachmentItem}>
                    <Ionicons name="image" size={20} color={colors.haven.champagne[500]} />
                    <Text style={styles.attachmentName}>Photo {index + 1}</Text>
                    <TouchableOpacity onPress={() => removeAttachment(index)}>
                      <Ionicons
                        name="close-circle"
                        size={20}
                        color={colors.text.tertiary}
                      />
                    </TouchableOpacity>
                  </View>
                ))}
              </View>
            )}
          </Card>
        </ScrollView>

        {/* Submit Button */}
        <View style={styles.footer}>
          <Button
            title={isSubmitting ? 'Submitting...' : 'Submit Request'}
            onPress={handleSubmit}
            loading={isSubmitting}
            disabled={isSubmitting || !title.trim() || !category}
            fullWidth
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
    paddingBottom: spacing[8],
  },
  section: {
    padding: spacing[4],
    marginBottom: spacing[4],
  },
  sectionTitle: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.secondary,
    marginBottom: spacing[3],
  },
  titleInput: {
    fontSize: typography.fontSizes.base,
    color: colors.text.primary,
    padding: spacing[3],
    backgroundColor: colors.gray[50],
    borderRadius: borderRadius.lg,
    borderWidth: 1,
    borderColor: colors.border.default,
  },
  categoryGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: spacing[2],
  },
  categoryItem: {
    width: '31%',
    alignItems: 'center',
    padding: spacing[3],
    borderRadius: borderRadius.lg,
    borderWidth: 1,
    borderColor: colors.border.default,
    backgroundColor: colors.white,
  },
  categoryItemSelected: {
    borderColor: colors.haven.champagne[500],
    backgroundColor: colors.haven.champagne[50],
  },
  categoryLabel: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.secondary,
    marginTop: spacing[1],
    textAlign: 'center',
  },
  categoryLabelSelected: {
    color: colors.haven.champagne[600],
    fontWeight: typography.fontWeights.medium,
  },
  priorityList: {
    gap: spacing[2],
  },
  priorityItem: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: spacing[3],
    borderRadius: borderRadius.lg,
    borderWidth: 1,
    borderColor: colors.border.default,
    backgroundColor: colors.white,
  },
  priorityItemSelected: {
    borderColor: colors.haven.champagne[500],
    backgroundColor: colors.haven.champagne[50],
  },
  priorityRadio: {
    width: 20,
    height: 20,
    borderRadius: 10,
    borderWidth: 2,
    borderColor: colors.border.default,
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: spacing[3],
  },
  priorityRadioInner: {
    width: 10,
    height: 10,
    borderRadius: 5,
    backgroundColor: colors.haven.champagne[500],
  },
  priorityContent: {
    flex: 1,
  },
  priorityLabel: {
    fontSize: typography.fontSizes.base,
    color: colors.text.primary,
    fontWeight: typography.fontWeights.medium,
  },
  priorityLabelSelected: {
    color: colors.haven.champagne[600],
  },
  priorityDescription: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
    marginTop: 2,
  },
  descriptionInput: {
    fontSize: typography.fontSizes.base,
    color: colors.text.primary,
    padding: spacing[3],
    backgroundColor: colors.gray[50],
    borderRadius: borderRadius.lg,
    borderWidth: 1,
    borderColor: colors.border.default,
    minHeight: 100,
  },
  attachmentButtons: {
    flexDirection: 'row',
    gap: spacing[3],
  },
  attachmentButton: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: spacing[2],
    padding: spacing[3],
    borderRadius: borderRadius.lg,
    borderWidth: 1,
    borderColor: colors.haven.champagne[200],
    borderStyle: 'dashed',
    backgroundColor: colors.haven.champagne[50],
  },
  attachmentButtonText: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.champagne[600],
    fontWeight: typography.fontWeights.medium,
  },
  attachmentPreview: {
    marginTop: spacing[3],
    gap: spacing[2],
  },
  attachmentItem: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[2],
    padding: spacing[2],
    backgroundColor: colors.gray[50],
    borderRadius: borderRadius.md,
  },
  attachmentName: {
    flex: 1,
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
  },
  footer: {
    padding: spacing[4],
    backgroundColor: colors.white,
    borderTopWidth: 1,
    borderTopColor: colors.border.light,
  },
});

import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  Modal,
  TouchableOpacity,
  ScrollView,
  Alert,
  Platform,
  KeyboardAvoidingView,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { colors, typography, spacing, borderRadius } from '../../lib/theme';
import { Input } from './Input';
import { Button } from '../ui/Button';

interface CareData {
  foodBrand?: string | null;
  foodType?: string | null;
  feedingSchedule?: string | null;
  feedingAmount?: string | null;
}

interface Props {
  visible: boolean;
  onClose: () => void;
  onSave: (data: CareData) => Promise<void>;
  initialData?: CareData;
}

export function EditPetCareModal({ visible, onClose, onSave, initialData }: Props) {
  const [foodBrand, setFoodBrand] = useState(initialData?.foodBrand || '');
  const [foodType, setFoodType] = useState(initialData?.foodType || '');
  const [feedingSchedule, setFeedingSchedule] = useState(initialData?.feedingSchedule || '');
  const [feedingAmount, setFeedingAmount] = useState(initialData?.feedingAmount || '');
  const [isSaving, setIsSaving] = useState(false);

  useEffect(() => {
    if (visible) {
      setFoodBrand(initialData?.foodBrand || '');
      setFoodType(initialData?.foodType || '');
      setFeedingSchedule(initialData?.feedingSchedule || '');
      setFeedingAmount(initialData?.feedingAmount || '');
    }
  }, [visible, initialData]);

  const handleSave = async () => {
    setIsSaving(true);
    try {
      await onSave({
        foodBrand: foodBrand.trim() || null,
        foodType: foodType.trim() || null,
        feedingSchedule: feedingSchedule.trim() || null,
        feedingAmount: feedingAmount.trim() || null,
      });
      onClose();
    } catch (err) {
      Alert.alert('Error', 'Failed to save food & feeding details');
    } finally {
      setIsSaving(false);
    }
  };

  return (
    <Modal visible={visible} animationType="slide" presentationStyle="pageSheet">
      <SafeAreaView style={styles.container} edges={['top']}>
        <KeyboardAvoidingView
          behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
          style={styles.keyboardView}
        >
          {/* Header */}
          <View style={styles.header}>
            <TouchableOpacity onPress={onClose} style={styles.closeButton}>
              <Ionicons name="close" size={24} color={colors.text.primary} />
            </TouchableOpacity>
            <Text style={styles.title}>Food & Feeding</Text>
            <View style={styles.placeholder} />
          </View>

          <ScrollView style={styles.content} showsVerticalScrollIndicator={false}>
            <Input
              label="Food Brand"
              value={foodBrand}
              onChangeText={setFoodBrand}
              placeholder="e.g., Blue Buffalo, Purina"
              autoCapitalize="words"
            />

            <Input
              label="Food Type"
              value={foodType}
              onChangeText={setFoodType}
              placeholder="e.g., Dry kibble, Wet food, Raw"
              autoCapitalize="words"
            />

            <Input
              label="Feeding Amount"
              value={feedingAmount}
              onChangeText={setFeedingAmount}
              placeholder="e.g., 1 cup, 2 pouches"
            />

            <Input
              label="Feeding Schedule"
              value={feedingSchedule}
              onChangeText={setFeedingSchedule}
              placeholder="e.g., 8am and 6pm, Twice daily"
              multiline
            />
          </ScrollView>

          {/* Footer */}
          <View style={styles.footer}>
            <Button
              title="Cancel"
              variant="outline"
              onPress={onClose}
              style={styles.cancelButton}
            />
            <Button
              title="Save"
              onPress={handleSave}
              loading={isSaving}
              disabled={isSaving}
              style={styles.saveButton}
            />
          </View>
        </KeyboardAvoidingView>
      </SafeAreaView>
    </Modal>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background.primary,
  },
  keyboardView: {
    flex: 1,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: spacing[4],
    paddingVertical: spacing[3],
    borderBottomWidth: 1,
    borderBottomColor: colors.border.light,
  },
  closeButton: {
    padding: spacing[2],
    marginLeft: -spacing[2],
  },
  title: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
  },
  placeholder: {
    width: 40,
  },
  content: {
    flex: 1,
    padding: spacing[4],
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

export default EditPetCareModal;

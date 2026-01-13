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
import DateTimePicker from '@react-native-community/datetimepicker';
import { colors, typography, spacing, borderRadius } from '../../lib/theme';
import { Input } from './Input';
import { Button } from '../ui/Button';

interface BasicInfoData {
  birthDate?: string | null;
  color?: string | null;
  weight?: number | null;
  allergies?: string | null;
}

interface Props {
  visible: boolean;
  onClose: () => void;
  onSave: (data: BasicInfoData) => Promise<void>;
  initialData?: BasicInfoData;
}

export function EditPetBasicInfoModal({ visible, onClose, onSave, initialData }: Props) {
  const [birthDate, setBirthDate] = useState<Date | null>(
    initialData?.birthDate ? new Date(initialData.birthDate) : null
  );
  const [color, setColor] = useState(initialData?.color || '');
  const [weight, setWeight] = useState(initialData?.weight?.toString() || '');
  const [allergies, setAllergies] = useState(initialData?.allergies || '');
  const [showDatePicker, setShowDatePicker] = useState(false);
  const [isSaving, setIsSaving] = useState(false);

  useEffect(() => {
    if (visible) {
      setBirthDate(initialData?.birthDate ? new Date(initialData.birthDate) : null);
      setColor(initialData?.color || '');
      setWeight(initialData?.weight?.toString() || '');
      setAllergies(initialData?.allergies || '');
    }
  }, [visible, initialData]);

  const handleSave = async () => {
    setIsSaving(true);
    try {
      await onSave({
        birthDate: birthDate?.toISOString() || null,
        color: color.trim() || null,
        weight: weight ? parseFloat(weight) : null,
        allergies: allergies.trim() || null,
      });
      onClose();
    } catch (err) {
      Alert.alert('Error', 'Failed to save basic info');
    } finally {
      setIsSaving(false);
    }
  };

  const formatDate = (date: Date | null) => {
    if (!date) return 'Not set';
    return date.toLocaleDateString('en-US', {
      month: 'long',
      day: 'numeric',
      year: 'numeric',
    });
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
            <Text style={styles.title}>Basic Info</Text>
            <View style={styles.placeholder} />
          </View>

          <ScrollView style={styles.content} showsVerticalScrollIndicator={false}>
            <TouchableOpacity
              style={styles.dateButton}
              onPress={() => setShowDatePicker(true)}
            >
              <View style={styles.dateContent}>
                <Text style={styles.dateLabel}>Birthday</Text>
                <Text style={styles.dateValue}>{formatDate(birthDate)}</Text>
              </View>
              <Ionicons name="calendar-outline" size={20} color={colors.text.tertiary} />
            </TouchableOpacity>

            {showDatePicker && (
              <DateTimePicker
                value={birthDate || new Date()}
                mode="date"
                display="spinner"
                onChange={(_: any, date?: Date) => {
                  setShowDatePicker(Platform.OS === 'ios');
                  if (date) setBirthDate(date);
                }}
              />
            )}

            <Input
              label="Color"
              value={color}
              onChangeText={setColor}
              placeholder="e.g., Golden, Black & White"
              autoCapitalize="words"
            />

            <Input
              label="Weight (lbs)"
              value={weight}
              onChangeText={(v) => setWeight(v.replace(/[^0-9.]/g, ''))}
              placeholder="e.g., 25"
              keyboardType="decimal-pad"
            />

            <Input
              label="Allergies"
              value={allergies}
              onChangeText={setAllergies}
              placeholder="List any known allergies"
              multiline
              numberOfLines={3}
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
  dateButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    padding: spacing[4],
    borderRadius: borderRadius.lg,
    backgroundColor: colors.gray[50],
    borderWidth: 1,
    borderColor: colors.border.default,
    marginBottom: spacing[4],
  },
  dateContent: {
    flex: 1,
  },
  dateLabel: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.tertiary,
  },
  dateValue: {
    fontSize: typography.fontSizes.base,
    color: colors.text.primary,
    marginTop: 2,
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

export default EditPetBasicInfoModal;

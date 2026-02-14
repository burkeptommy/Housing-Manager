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

interface MileageData {
  currentMileage?: number | null;
  lastOilChange?: string | null;
  oilChangeMileage?: number | null;
}

interface Props {
  visible: boolean;
  onClose: () => void;
  onSave: (data: MileageData) => Promise<void>;
  initialData?: MileageData;
  vehicleName?: string;
}

export function UpdateMileageModal({ visible, onClose, onSave, initialData, vehicleName }: Props) {
  const [currentMileage, setCurrentMileage] = useState('');
  const [oilChangeMileage, setOilChangeMileage] = useState('');
  const [lastOilChange, setLastOilChange] = useState<Date | null>(null);
  const [showDatePicker, setShowDatePicker] = useState(false);
  const [isSaving, setIsSaving] = useState(false);

  useEffect(() => {
    if (visible) {
      setCurrentMileage(initialData?.currentMileage ? String(initialData.currentMileage) : '');
      setOilChangeMileage(initialData?.oilChangeMileage ? String(initialData.oilChangeMileage) : '');
      setLastOilChange(initialData?.lastOilChange ? new Date(initialData.lastOilChange) : null);
    }
  }, [visible, initialData]);

  const handleSave = async () => {
    setIsSaving(true);
    try {
      await onSave({
        currentMileage: currentMileage ? parseInt(currentMileage, 10) : null,
        lastOilChange: lastOilChange?.toISOString() || null,
        oilChangeMileage: oilChangeMileage ? parseInt(oilChangeMileage, 10) : null,
      });
      onClose();
    } catch (err) {
      Alert.alert('Error', 'Failed to save mileage details');
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
            <Text style={styles.title}>Update Mileage</Text>
            <View style={styles.placeholder} />
          </View>

          <ScrollView style={styles.content} showsVerticalScrollIndicator={false}>
            {vehicleName && (
              <Text style={styles.vehicleLabel}>{vehicleName}</Text>
            )}

            <Input
              label="Current Mileage"
              value={currentMileage}
              onChangeText={setCurrentMileage}
              placeholder="e.g., 45000"
              keyboardType="number-pad"
            />

            <TouchableOpacity
              style={styles.dateButton}
              onPress={() => setShowDatePicker(true)}
            >
              <View style={styles.dateContent}>
                <Text style={styles.dateLabel}>Last Oil Change Date</Text>
                <Text style={styles.dateValue}>
                  {lastOilChange
                    ? lastOilChange.toLocaleDateString('en-US', {
                        month: 'long',
                        day: 'numeric',
                        year: 'numeric',
                      })
                    : 'Not set'}
                </Text>
              </View>
              <Ionicons name="calendar-outline" size={20} color={colors.text.tertiary} />
            </TouchableOpacity>

            {showDatePicker && (
              <DateTimePicker
                value={lastOilChange || new Date()}
                mode="date"
                display="spinner"
                maximumDate={new Date()}
                onChange={(_: any, date?: Date) => {
                  setShowDatePicker(Platform.OS === 'ios');
                  if (date) setLastOilChange(date);
                }}
              />
            )}

            <Input
              label="Mileage at Last Oil Change"
              value={oilChangeMileage}
              onChangeText={setOilChangeMileage}
              placeholder="e.g., 42000"
              keyboardType="number-pad"
            />
            <Text style={styles.hintText}>
              This helps calculate when your next oil change is due.
            </Text>
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
  vehicleLabel: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    marginBottom: spacing[4],
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
  hintText: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
    marginTop: -spacing[2],
    marginBottom: spacing[4],
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

export default UpdateMileageModal;

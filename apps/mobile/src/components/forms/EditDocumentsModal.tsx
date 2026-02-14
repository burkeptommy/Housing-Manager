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
  Switch,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import DateTimePicker from '@react-native-community/datetimepicker';
import { colors, typography, spacing, borderRadius } from '../../lib/theme';
import { Button } from '../ui/Button';

interface DocumentsData {
  hasW9?: boolean;
  hasI9?: boolean;
  backgroundCheckDate?: string | null;
  cprCertifiedUntil?: string | null;
  firstAidCertifiedUntil?: string | null;
  driversLicenseExpiry?: string | null;
}

interface Props {
  visible: boolean;
  onClose: () => void;
  onSave: (data: DocumentsData) => Promise<void>;
  initialData?: DocumentsData;
}

type DateField = 'backgroundCheckDate' | 'cprCertifiedUntil' | 'firstAidCertifiedUntil' | 'driversLicenseExpiry';

export function EditDocumentsModal({ visible, onClose, onSave, initialData }: Props) {
  const [hasW9, setHasW9] = useState(initialData?.hasW9 ?? false);
  const [hasI9, setHasI9] = useState(initialData?.hasI9 ?? false);
  const [backgroundCheckDate, setBackgroundCheckDate] = useState<Date | null>(
    initialData?.backgroundCheckDate ? new Date(initialData.backgroundCheckDate) : null
  );
  const [cprCertifiedUntil, setCprCertifiedUntil] = useState<Date | null>(
    initialData?.cprCertifiedUntil ? new Date(initialData.cprCertifiedUntil) : null
  );
  const [firstAidCertifiedUntil, setFirstAidCertifiedUntil] = useState<Date | null>(
    initialData?.firstAidCertifiedUntil ? new Date(initialData.firstAidCertifiedUntil) : null
  );
  const [driversLicenseExpiry, setDriversLicenseExpiry] = useState<Date | null>(
    initialData?.driversLicenseExpiry ? new Date(initialData.driversLicenseExpiry) : null
  );
  const [activeDatePicker, setActiveDatePicker] = useState<DateField | null>(null);
  const [isSaving, setIsSaving] = useState(false);

  useEffect(() => {
    if (visible) {
      setHasW9(initialData?.hasW9 ?? false);
      setHasI9(initialData?.hasI9 ?? false);
      setBackgroundCheckDate(initialData?.backgroundCheckDate ? new Date(initialData.backgroundCheckDate) : null);
      setCprCertifiedUntil(initialData?.cprCertifiedUntil ? new Date(initialData.cprCertifiedUntil) : null);
      setFirstAidCertifiedUntil(initialData?.firstAidCertifiedUntil ? new Date(initialData.firstAidCertifiedUntil) : null);
      setDriversLicenseExpiry(initialData?.driversLicenseExpiry ? new Date(initialData.driversLicenseExpiry) : null);
      setActiveDatePicker(null);
    }
  }, [visible, initialData]);

  const handleSave = async () => {
    setIsSaving(true);
    try {
      await onSave({
        hasW9,
        hasI9,
        backgroundCheckDate: backgroundCheckDate?.toISOString() || null,
        cprCertifiedUntil: cprCertifiedUntil?.toISOString() || null,
        firstAidCertifiedUntil: firstAidCertifiedUntil?.toISOString() || null,
        driversLicenseExpiry: driversLicenseExpiry?.toISOString() || null,
      });
      onClose();
    } catch (err) {
      Alert.alert('Error', 'Failed to save document information');
    } finally {
      setIsSaving(false);
    }
  };

  const formatDate = (date: Date | null) => {
    if (!date) return 'Not set';
    return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
  };

  const handleDateChange = (field: DateField, date?: Date) => {
    if (!date) return;
    switch (field) {
      case 'backgroundCheckDate': setBackgroundCheckDate(date); break;
      case 'cprCertifiedUntil': setCprCertifiedUntil(date); break;
      case 'firstAidCertifiedUntil': setFirstAidCertifiedUntil(date); break;
      case 'driversLicenseExpiry': setDriversLicenseExpiry(date); break;
    }
    if (Platform.OS !== 'ios') setActiveDatePicker(null);
  };

  const getDateValue = (field: DateField): Date | null => {
    switch (field) {
      case 'backgroundCheckDate': return backgroundCheckDate;
      case 'cprCertifiedUntil': return cprCertifiedUntil;
      case 'firstAidCertifiedUntil': return firstAidCertifiedUntil;
      case 'driversLicenseExpiry': return driversLicenseExpiry;
    }
  };

  const clearDate = (field: DateField) => {
    switch (field) {
      case 'backgroundCheckDate': setBackgroundCheckDate(null); break;
      case 'cprCertifiedUntil': setCprCertifiedUntil(null); break;
      case 'firstAidCertifiedUntil': setFirstAidCertifiedUntil(null); break;
      case 'driversLicenseExpiry': setDriversLicenseExpiry(null); break;
    }
    setActiveDatePicker(null);
  };

  const renderDateField = (field: DateField, label: string, icon: keyof typeof Ionicons.glyphMap) => {
    const value = getDateValue(field);
    return (
      <View key={field}>
        <TouchableOpacity
          style={styles.dateButton}
          onPress={() => setActiveDatePicker(activeDatePicker === field ? null : field)}
        >
          <Ionicons name={icon} size={20} color={colors.text.secondary} />
          <View style={styles.dateContent}>
            <Text style={styles.dateLabel}>{label}</Text>
            <Text style={[styles.dateValue, !value && styles.dateValueEmpty]}>
              {formatDate(value)}
            </Text>
          </View>
          {value && (
            <TouchableOpacity onPress={() => clearDate(field)} hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}>
              <Ionicons name="close-circle" size={20} color={colors.text.tertiary} />
            </TouchableOpacity>
          )}
          <Ionicons name="calendar-outline" size={18} color={colors.text.tertiary} />
        </TouchableOpacity>
        {activeDatePicker === field && (
          <DateTimePicker
            value={value || new Date()}
            mode="date"
            display="spinner"
            onChange={(_: any, date?: Date) => {
              if (Platform.OS !== 'ios') setActiveDatePicker(null);
              if (date) handleDateChange(field, date);
            }}
          />
        )}
      </View>
    );
  };

  return (
    <Modal visible={visible} animationType="slide" presentationStyle="pageSheet">
      <SafeAreaView style={styles.container} edges={['top']}>
        <KeyboardAvoidingView
          behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
          style={styles.keyboardView}
        >
          <View style={styles.header}>
            <TouchableOpacity onPress={onClose} style={styles.closeButton}>
              <Ionicons name="close" size={24} color={colors.text.primary} />
            </TouchableOpacity>
            <Text style={styles.title}>Documents</Text>
            <View style={styles.placeholder} />
          </View>

          <ScrollView style={styles.content} showsVerticalScrollIndicator={false}>
            <Text style={styles.sectionLabel}>TAX DOCUMENTS</Text>

            <View style={styles.switchRow}>
              <View style={styles.switchInfo}>
                <Text style={styles.switchLabel}>W-9 on file</Text>
                <Text style={styles.switchDescription}>Independent contractor tax form</Text>
              </View>
              <Switch
                value={hasW9}
                onValueChange={setHasW9}
                trackColor={{ false: colors.gray[300], true: colors.haven.purple[300] }}
                thumbColor={hasW9 ? colors.haven.purple[500] : colors.gray[100]}
              />
            </View>

            <View style={styles.switchRow}>
              <View style={styles.switchInfo}>
                <Text style={styles.switchLabel}>I-9 on file</Text>
                <Text style={styles.switchDescription}>Employment eligibility verification</Text>
              </View>
              <Switch
                value={hasI9}
                onValueChange={setHasI9}
                trackColor={{ false: colors.gray[300], true: colors.haven.purple[300] }}
                thumbColor={hasI9 ? colors.haven.purple[500] : colors.gray[100]}
              />
            </View>

            <Text style={[styles.sectionLabel, { marginTop: spacing[5] }]}>CERTIFICATIONS & DATES</Text>

            {renderDateField('backgroundCheckDate', 'Background Check Date', 'shield-checkmark-outline')}
            {renderDateField('cprCertifiedUntil', 'CPR Certification Expires', 'heart-outline')}
            {renderDateField('firstAidCertifiedUntil', 'First Aid Certification Expires', 'medkit-outline')}
            {renderDateField('driversLicenseExpiry', "Driver's License Expires", 'card-outline')}
          </ScrollView>

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
  sectionLabel: {
    fontSize: typography.fontSizes.xs,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.tertiary,
    textTransform: 'uppercase',
    letterSpacing: 0.5,
    marginBottom: spacing[3],
  },
  switchRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingVertical: spacing[3],
    borderBottomWidth: 1,
    borderBottomColor: colors.border.light,
  },
  switchInfo: {
    flex: 1,
    marginRight: spacing[3],
  },
  switchLabel: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.primary,
  },
  switchDescription: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.tertiary,
    marginTop: 2,
  },
  dateButton: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[3],
    paddingVertical: spacing[3],
    borderBottomWidth: 1,
    borderBottomColor: colors.border.light,
  },
  dateContent: {
    flex: 1,
  },
  dateLabel: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.tertiary,
    marginBottom: 2,
  },
  dateValue: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.primary,
  },
  dateValueEmpty: {
    color: colors.text.tertiary,
    fontWeight: typography.fontWeights.regular,
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

export default EditDocumentsModal;

import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  Modal,
  ScrollView,
  TouchableOpacity,
  Switch,
  Alert,
  KeyboardAvoidingView,
  Platform,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { colors, typography, spacing, borderRadius } from '../../lib/theme';
import { Input } from './Input';
import { Button } from '../ui/Button';

interface SchoolData {
  school?: string | null;
  schoolGrade?: string | null;
  teacher?: string | null;
  schoolPhone?: string | null;
  busNumber?: string | null;
  pickupTime?: string | null;
  dropoffTime?: string | null;
}

interface Props {
  visible: boolean;
  onClose: () => void;
  onSave: (data: SchoolData) => Promise<void>;
  initialData?: SchoolData;
}

export function EditSchoolModal({ visible, onClose, onSave, initialData }: Props) {
  const [isSaving, setIsSaving] = useState(false);
  const [hasSchool, setHasSchool] = useState(!!initialData?.school);
  const [school, setSchool] = useState(initialData?.school || '');
  const [schoolGrade, setSchoolGrade] = useState(initialData?.schoolGrade || '');
  const [teacher, setTeacher] = useState(initialData?.teacher || '');
  const [schoolPhone, setSchoolPhone] = useState(initialData?.schoolPhone || '');
  const [busNumber, setBusNumber] = useState(initialData?.busNumber || '');
  const [pickupTime, setPickupTime] = useState(initialData?.pickupTime || '');
  const [dropoffTime, setDropoffTime] = useState(initialData?.dropoffTime || '');

  useEffect(() => {
    if (visible) {
      setHasSchool(!!initialData?.school);
      setSchool(initialData?.school || '');
      setSchoolGrade(initialData?.schoolGrade || '');
      setTeacher(initialData?.teacher || '');
      setSchoolPhone(initialData?.schoolPhone || '');
      setBusNumber(initialData?.busNumber || '');
      setPickupTime(initialData?.pickupTime || '');
      setDropoffTime(initialData?.dropoffTime || '');
    }
  }, [visible, initialData]);

  const handleSave = async () => {
    setIsSaving(true);
    try {
      await onSave({
        school: hasSchool ? school.trim() || null : null,
        schoolGrade: hasSchool ? schoolGrade.trim() || null : null,
        teacher: hasSchool ? teacher.trim() || null : null,
        schoolPhone: hasSchool ? schoolPhone.trim() || null : null,
        busNumber: hasSchool ? busNumber.trim() || null : null,
        pickupTime: hasSchool ? pickupTime.trim() || null : null,
        dropoffTime: hasSchool ? dropoffTime.trim() || null : null,
      });
      onClose();
    } catch (err) {
      Alert.alert('Error', 'Failed to save school information');
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
            <Text style={styles.title}>School / Daycare</Text>
            <View style={styles.placeholder} />
          </View>

          <ScrollView style={styles.content} showsVerticalScrollIndicator={false}>
            {/* Toggle */}
            <View style={styles.toggleRow}>
              <View>
                <Text style={styles.toggleLabel}>Attends School/Daycare</Text>
                <Text style={styles.toggleHint}>Enable to add school information</Text>
              </View>
              <Switch
                value={hasSchool}
                onValueChange={setHasSchool}
                trackColor={{ false: colors.gray[200], true: colors.haven.purple[400] }}
                thumbColor={hasSchool ? colors.haven.purple[500] : colors.gray[400]}
              />
            </View>

            {hasSchool && (
              <>
                <Input
                  label="School/Daycare Name"
                  value={school}
                  onChangeText={setSchool}
                  placeholder="Enter school name"
                />

                <Input
                  label="Grade/Class"
                  value={schoolGrade}
                  onChangeText={setSchoolGrade}
                  placeholder="e.g., 3rd Grade, Pre-K"
                />

                <Input
                  label="Teacher Name"
                  value={teacher}
                  onChangeText={setTeacher}
                  placeholder="Enter teacher name"
                />

                <Input
                  label="School Phone"
                  value={schoolPhone}
                  onChangeText={setSchoolPhone}
                  placeholder="Enter school phone"
                  keyboardType="phone-pad"
                />

                <Input
                  label="Bus Number"
                  value={busNumber}
                  onChangeText={setBusNumber}
                  placeholder="Enter bus number"
                />

                <Input
                  label="Drop-off Time"
                  value={dropoffTime}
                  onChangeText={setDropoffTime}
                  placeholder="e.g., 8:00 AM"
                />

                <Input
                  label="Pickup Time"
                  value={pickupTime}
                  onChangeText={setPickupTime}
                  placeholder="e.g., 3:00 PM"
                />
              </>
            )}
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
  toggleRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    backgroundColor: colors.white,
    padding: spacing[4],
    borderRadius: borderRadius.lg,
    marginBottom: spacing[4],
  },
  toggleLabel: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.primary,
  },
  toggleHint: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
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

export default EditSchoolModal;

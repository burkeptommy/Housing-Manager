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
import { colors, typography, spacing } from '../../lib/theme';
import { Button } from '../ui/Button';

interface ReimbursementsData {
  mileageReimbursement?: boolean;
  gasReimbursement?: boolean;
  mealsReimbursement?: boolean;
  phoneAllowance?: boolean;
}

interface Props {
  visible: boolean;
  onClose: () => void;
  onSave: (data: ReimbursementsData) => Promise<void>;
  initialData?: ReimbursementsData;
}

export function EditReimbursementsModal({ visible, onClose, onSave, initialData }: Props) {
  const [mileage, setMileage] = useState(initialData?.mileageReimbursement ?? false);
  const [gas, setGas] = useState(initialData?.gasReimbursement ?? false);
  const [meals, setMeals] = useState(initialData?.mealsReimbursement ?? false);
  const [phone, setPhone] = useState(initialData?.phoneAllowance ?? false);
  const [isSaving, setIsSaving] = useState(false);

  useEffect(() => {
    if (visible) {
      setMileage(initialData?.mileageReimbursement ?? false);
      setGas(initialData?.gasReimbursement ?? false);
      setMeals(initialData?.mealsReimbursement ?? false);
      setPhone(initialData?.phoneAllowance ?? false);
    }
  }, [visible, initialData]);

  const handleSave = async () => {
    setIsSaving(true);
    try {
      await onSave({
        mileageReimbursement: mileage,
        gasReimbursement: gas,
        mealsReimbursement: meals,
        phoneAllowance: phone,
      });
      onClose();
    } catch (err) {
      Alert.alert('Error', 'Failed to save reimbursement settings');
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
          <View style={styles.header}>
            <TouchableOpacity onPress={onClose} style={styles.closeButton}>
              <Ionicons name="close" size={24} color={colors.text.primary} />
            </TouchableOpacity>
            <Text style={styles.title}>Reimbursements</Text>
            <View style={styles.placeholder} />
          </View>

          <ScrollView style={styles.content} showsVerticalScrollIndicator={false}>
            <Text style={styles.sectionLabel}>REIMBURSEMENT POLICY</Text>

            <View style={styles.switchRow}>
              <View style={styles.switchInfo}>
                <Ionicons name="speedometer-outline" size={20} color={colors.text.secondary} />
                <View style={styles.switchText}>
                  <Text style={styles.switchLabel}>Mileage</Text>
                  <Text style={styles.switchDescription}>Reimburse for work-related driving</Text>
                </View>
              </View>
              <Switch
                value={mileage}
                onValueChange={setMileage}
                trackColor={{ false: colors.gray[300], true: colors.haven.purple[300] }}
                thumbColor={mileage ? colors.haven.purple[500] : colors.gray[100]}
              />
            </View>

            <View style={styles.switchRow}>
              <View style={styles.switchInfo}>
                <Ionicons name="car-outline" size={20} color={colors.text.secondary} />
                <View style={styles.switchText}>
                  <Text style={styles.switchLabel}>Gas</Text>
                  <Text style={styles.switchDescription}>Reimburse fuel expenses</Text>
                </View>
              </View>
              <Switch
                value={gas}
                onValueChange={setGas}
                trackColor={{ false: colors.gray[300], true: colors.haven.purple[300] }}
                thumbColor={gas ? colors.haven.purple[500] : colors.gray[100]}
              />
            </View>

            <View style={styles.switchRow}>
              <View style={styles.switchInfo}>
                <Ionicons name="restaurant-outline" size={20} color={colors.text.secondary} />
                <View style={styles.switchText}>
                  <Text style={styles.switchLabel}>Meals</Text>
                  <Text style={styles.switchDescription}>Reimburse meal expenses during work</Text>
                </View>
              </View>
              <Switch
                value={meals}
                onValueChange={setMeals}
                trackColor={{ false: colors.gray[300], true: colors.haven.purple[300] }}
                thumbColor={meals ? colors.haven.purple[500] : colors.gray[100]}
              />
            </View>

            <View style={styles.switchRow}>
              <View style={styles.switchInfo}>
                <Ionicons name="phone-portrait-outline" size={20} color={colors.text.secondary} />
                <View style={styles.switchText}>
                  <Text style={styles.switchLabel}>Phone Allowance</Text>
                  <Text style={styles.switchDescription}>Monthly phone stipend</Text>
                </View>
              </View>
              <Switch
                value={phone}
                onValueChange={setPhone}
                trackColor={{ false: colors.gray[300], true: colors.haven.purple[300] }}
                thumbColor={phone ? colors.haven.purple[500] : colors.gray[100]}
              />
            </View>
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
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[3],
    marginRight: spacing[3],
  },
  switchText: {
    flex: 1,
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

export default EditReimbursementsModal;

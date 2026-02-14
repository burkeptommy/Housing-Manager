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

const MEMBERSHIP_TYPES = [
  { id: 'gym', label: 'Gym/Fitness' },
  { id: 'country_club', label: 'Country Club' },
  { id: 'social_club', label: 'Social Club' },
  { id: 'professional', label: 'Professional' },
  { id: 'other', label: 'Other' },
];

export interface MembershipData {
  id?: string;
  name: string;
  type: 'gym' | 'country_club' | 'social_club' | 'professional' | 'other';
  memberNumber?: string | null;
  expiresAt?: string | null;
  monthlyFee?: number | null;
  autoRenew?: boolean;
  notes?: string | null;
}

interface Props {
  visible: boolean;
  onClose: () => void;
  onSave: (data: MembershipData) => Promise<void>;
  onDelete?: (id: string) => Promise<void>;
  initialData?: MembershipData | null;
  isNew?: boolean;
}

export function EditMembershipModal({
  visible,
  onClose,
  onSave,
  onDelete,
  initialData,
  isNew = true
}: Props) {
  const [isSaving, setIsSaving] = useState(false);
  const [name, setName] = useState('');
  const [type, setType] = useState<MembershipData['type']>('gym');
  const [memberNumber, setMemberNumber] = useState('');
  const [expiresAt, setExpiresAt] = useState('');
  const [monthlyFee, setMonthlyFee] = useState('');
  const [autoRenew, setAutoRenew] = useState(false);
  const [notes, setNotes] = useState('');

  useEffect(() => {
    if (visible) {
      setName(initialData?.name || '');
      setType(initialData?.type || 'gym');
      setMemberNumber(initialData?.memberNumber || '');
      setExpiresAt(initialData?.expiresAt ? initialData.expiresAt.split('T')[0] : '');
      setMonthlyFee(initialData?.monthlyFee?.toString() || '');
      setAutoRenew(initialData?.autoRenew || false);
      setNotes(initialData?.notes || '');
    }
  }, [visible, initialData]);

  const handleSave = async () => {
    if (!name.trim()) {
      Alert.alert('Required', 'Membership name is required');
      return;
    }

    setIsSaving(true);
    try {
      await onSave({
        id: initialData?.id,
        name: name.trim(),
        type,
        memberNumber: memberNumber.trim() || null,
        expiresAt: expiresAt.trim() || null,
        monthlyFee: monthlyFee ? parseFloat(monthlyFee) : null,
        autoRenew,
        notes: notes.trim() || null,
      });
      onClose();
    } catch (err) {
      Alert.alert('Error', 'Failed to save membership');
    } finally {
      setIsSaving(false);
    }
  };

  const handleDelete = () => {
    if (!initialData?.id || !onDelete) return;

    Alert.alert(
      'Remove Membership',
      `Are you sure you want to remove "${name}"?`,
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Remove',
          style: 'destructive',
          onPress: async () => {
            try {
              await onDelete(initialData.id!);
              onClose();
            } catch (err) {
              Alert.alert('Error', 'Failed to remove membership');
            }
          },
        },
      ]
    );
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
            <Text style={styles.title}>{isNew ? 'Add Membership' : 'Edit Membership'}</Text>
            <View style={styles.placeholder} />
          </View>

          <ScrollView style={styles.content} showsVerticalScrollIndicator={false}>
            <Input
              label="Membership Name *"
              value={name}
              onChangeText={setName}
              placeholder="e.g., LA Fitness, Country Club"
            />

            {/* Type Selection */}
            <Text style={styles.label}>Type</Text>
            <View style={styles.typeGrid}>
              {MEMBERSHIP_TYPES.map((t) => (
                <TouchableOpacity
                  key={t.id}
                  style={[
                    styles.typeItem,
                    type === t.id && styles.typeItemSelected,
                  ]}
                  onPress={() => setType(t.id as MembershipData['type'])}
                >
                  <Text
                    style={[
                      styles.typeLabel,
                      type === t.id && styles.typeLabelSelected,
                    ]}
                  >
                    {t.label}
                  </Text>
                </TouchableOpacity>
              ))}
            </View>

            <Input
              label="Member Number"
              value={memberNumber}
              onChangeText={setMemberNumber}
              placeholder="Membership ID or number"
            />

            <Input
              label="Expiration Date"
              value={expiresAt}
              onChangeText={setExpiresAt}
              placeholder="YYYY-MM-DD"
            />

            <Input
              label="Monthly Fee"
              value={monthlyFee}
              onChangeText={setMonthlyFee}
              placeholder="0.00"
              keyboardType="decimal-pad"
            />

            {/* Auto-Renew Toggle */}
            <View style={styles.toggleRow}>
              <View>
                <Text style={styles.toggleLabel}>Auto-Renew</Text>
                <Text style={styles.toggleHint}>Membership renews automatically</Text>
              </View>
              <Switch
                value={autoRenew}
                onValueChange={setAutoRenew}
                trackColor={{ false: colors.gray[200], true: colors.haven.purple[400] }}
                thumbColor={autoRenew ? colors.haven.purple[500] : colors.gray[400]}
              />
            </View>

            <Input
              label="Notes"
              value={notes}
              onChangeText={setNotes}
              placeholder="Any additional notes..."
              multiline
              numberOfLines={3}
            />

            {/* Delete Button (if editing existing) */}
            {!isNew && onDelete && initialData?.id && (
              <TouchableOpacity style={styles.deleteButton} onPress={handleDelete}>
                <Ionicons name="trash-outline" size={20} color={colors.status.error} />
                <Text style={styles.deleteButtonText}>Remove Membership</Text>
              </TouchableOpacity>
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
  label: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.secondary,
    marginBottom: spacing[2],
    marginTop: spacing[3],
  },
  typeGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: spacing[2],
    marginBottom: spacing[3],
  },
  typeItem: {
    paddingVertical: spacing[2],
    paddingHorizontal: spacing[3],
    borderRadius: borderRadius.full,
    borderWidth: 1,
    borderColor: colors.border.default,
    backgroundColor: colors.white,
  },
  typeItemSelected: {
    borderColor: colors.haven.purple[500],
    backgroundColor: colors.haven.purple[50],
  },
  typeLabel: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
  },
  typeLabelSelected: {
    color: colors.haven.purple[600],
    fontWeight: typography.fontWeights.medium,
  },
  toggleRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    backgroundColor: colors.white,
    padding: spacing[4],
    borderRadius: borderRadius.lg,
    marginVertical: spacing[3],
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
  deleteButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: spacing[2],
    paddingVertical: spacing[4],
    marginTop: spacing[4],
  },
  deleteButtonText: {
    fontSize: typography.fontSizes.base,
    color: colors.status.error,
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

export default EditMembershipModal;

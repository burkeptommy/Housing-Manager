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
import { useAuth } from '../../../../../src/contexts/auth-context';
import { Card, Button, Input, LoadingSpinner } from '../../../../../src/components';
import { colors, typography, spacing, borderRadius } from '../../../../../src/lib/theme';
import { API_BASE_URL } from '../../../../../src/lib/api';
import { getIdToken } from '../../../../../src/lib/firebase';

interface Staff {
  id: string;
  firstName: string;
  lastName: string;
  role?: string;
  phone?: string;
  email?: string;
  address?: string;
  workSchedule?: string;
  startDate?: string;
  notes?: string;
  // Compensation
  payFrequency?: string;
  payAmount?: number;
  payMethod?: string;
  // Emergency contact
  emergencyContactName?: string;
  emergencyContactPhone?: string;
  // Agency
  agencyName?: string;
  agencyContact?: string;
  agencyPhone?: string;
  // Responsibilities
  responsibilities?: string;
}

const ROLES = [
  { id: 'nanny', label: 'Nanny' },
  { id: 'housekeeper', label: 'Housekeeper' },
  { id: 'gardener', label: 'Gardener' },
  { id: 'driver', label: 'Driver' },
  { id: 'chef', label: 'Chef' },
  { id: 'other', label: 'Other' },
];

const PAY_FREQUENCIES = [
  { id: 'weekly', label: 'Weekly' },
  { id: 'biweekly', label: 'Bi-weekly' },
  { id: 'monthly', label: 'Monthly' },
];

export default function EditStaffScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const router = useRouter();
  const { householdInfo } = useAuth();
  const [isLoading, setIsLoading] = useState(true);
  const [isSaving, setIsSaving] = useState(false);
  const [showStartDatePicker, setShowStartDatePicker] = useState(false);

  const [formData, setFormData] = useState({
    firstName: '',
    lastName: '',
    role: 'other',
    phone: '',
    email: '',
    address: '',
    workSchedule: '',
    startDate: null as Date | null,
    notes: '',
    payFrequency: 'biweekly',
    payAmount: '',
    payMethod: 'direct_deposit',
    emergencyContactName: '',
    emergencyContactPhone: '',
    agencyName: '',
    agencyContact: '',
    agencyPhone: '',
    responsibilities: '',
  });

  const fetchStaff = useCallback(async () => {
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

      const response = await fetch(`${API_BASE_URL}/family/household/${householdInfo.id}/member/${id}`, {
        headers: {
          Authorization: `Bearer ${token}`,
        },
      });

      if (response.ok) {
        const staff: Staff = await response.json();
        setFormData({
          firstName: staff.firstName || '',
          lastName: staff.lastName || '',
          role: staff.role || 'other',
          phone: staff.phone || '',
          email: staff.email || '',
          address: staff.address || '',
          workSchedule: staff.workSchedule || '',
          startDate: staff.startDate ? new Date(staff.startDate) : null,
          notes: staff.notes || '',
          payFrequency: staff.payFrequency || 'biweekly',
          payAmount: staff.payAmount?.toString() || '',
          payMethod: staff.payMethod || 'direct_deposit',
          emergencyContactName: (staff as any).emergencyContact || staff.emergencyContactName || '',
          emergencyContactPhone: staff.emergencyContactPhone || '',
          agencyName: staff.agencyName || '',
          agencyContact: staff.agencyContact || '',
          agencyPhone: staff.agencyPhone || '',
          responsibilities: staff.responsibilities || '',
        });
      }
    } catch (err) {
      console.error('Fetch staff error:', err);
    } finally {
      setIsLoading(false);
    }
  }, [id, householdInfo?.id]);

  useEffect(() => {
    fetchStaff();
  }, [fetchStaff]);

  const handleSave = async () => {
    if (!formData.firstName.trim()) {
      Alert.alert('Required', 'First name is required');
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
        firstName: formData.firstName.trim(),
        lastName: formData.lastName.trim() || null,
        role: formData.role,
        phone: formData.phone.trim() || null,
        email: formData.email.trim() || null,
        address: formData.address.trim() || null,
        workSchedule: formData.workSchedule.trim() || null,
        startDate: formData.startDate?.toISOString() || null,
        notes: formData.notes.trim() || null,
        payFrequency: formData.payFrequency,
        payAmount: formData.payAmount ? parseFloat(formData.payAmount) : null,
        payMethod: formData.payMethod,
        emergencyContact: formData.emergencyContactName.trim() || null,
        emergencyContactPhone: formData.emergencyContactPhone.trim() || null,
        agencyName: formData.agencyName.trim() || null,
        agencyContact: formData.agencyContact.trim() || null,
        agencyPhone: formData.agencyPhone.trim() || null,
        responsibilities: formData.responsibilities.trim() || null,
      };

      const response = await fetch(`${API_BASE_URL}/family/household/${householdInfo?.id}/member/${id}`, {
        method: 'PATCH',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(body),
      });

      if (!response.ok) {
        throw new Error('Failed to update staff');
      }

      Alert.alert('Success', 'Staff updated successfully', [
        { text: 'OK', onPress: () => router.back() },
      ]);
    } catch (error) {
      console.error('Update staff error:', error);
      Alert.alert('Error', 'Failed to update staff. Please try again.');
    } finally {
      setIsSaving(false);
    }
  };

  const handleDelete = () => {
    Alert.alert(
      'Remove Staff',
      'Are you sure you want to remove this staff member? This action cannot be undone.',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Remove',
          style: 'destructive',
          onPress: async () => {
            try {
              const token = await getIdToken(true);
              if (!token) return;

              await fetch(`${API_BASE_URL}/family/household/${householdInfo?.id}/member/${id}`, {
                method: 'DELETE',
                headers: { Authorization: `Bearer ${token}` },
              });

              router.back();
            } catch (err) {
              console.error('Delete staff error:', err);
              Alert.alert('Error', 'Failed to remove staff');
            }
          },
        },
      ]
    );
  };

  if (isLoading) {
    return <LoadingSpinner fullScreen message="Loading..." />;
  }

  return (
    <SafeAreaView style={styles.container} edges={['bottom']}>
      <Stack.Screen options={{ title: 'Edit Staff', headerBackTitle: 'Back' }} />
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
            <Text style={styles.cardTitle}>Basic Information</Text>

            <View style={styles.row}>
              <View style={styles.halfInput}>
                <Input
                  label="First Name"
                  value={formData.firstName}
                  onChangeText={(v) => setFormData({ ...formData, firstName: v })}
                  placeholder="First name"
                  autoCapitalize="words"
                />
              </View>
              <View style={styles.halfInput}>
                <Input
                  label="Last Name"
                  value={formData.lastName}
                  onChangeText={(v) => setFormData({ ...formData, lastName: v })}
                  placeholder="Last name"
                  autoCapitalize="words"
                />
              </View>
            </View>

            <View style={styles.typeSelector}>
              <Text style={styles.typeLabel}>Role</Text>
              <ScrollView horizontal showsHorizontalScrollIndicator={false}>
                {ROLES.map((role) => (
                  <TouchableOpacity
                    key={role.id}
                    style={[styles.typeChip, formData.role === role.id && styles.typeChipActive]}
                    onPress={() => setFormData({ ...formData, role: role.id })}
                  >
                    <Text style={[styles.typeChipText, formData.role === role.id && styles.typeChipTextActive]}>
                      {role.label}
                    </Text>
                  </TouchableOpacity>
                ))}
              </ScrollView>
            </View>
          </Card>

          {/* Contact Info */}
          <Card style={styles.card}>
            <Text style={styles.cardTitle}>Contact Information</Text>

            <Input
              label="Phone"
              value={formData.phone}
              onChangeText={(v) => setFormData({ ...formData, phone: v })}
              placeholder="(555) 123-4567"
              keyboardType="phone-pad"
            />

            <Input
              label="Email"
              value={formData.email}
              onChangeText={(v) => setFormData({ ...formData, email: v })}
              placeholder="email@example.com"
              keyboardType="email-address"
              autoCapitalize="none"
            />

            <Input
              label="Address"
              value={formData.address}
              onChangeText={(v) => setFormData({ ...formData, address: v })}
              placeholder="Home address"
              multiline
            />
          </Card>

          {/* Employment */}
          <Card style={styles.card}>
            <Text style={styles.cardTitle}>Employment</Text>

            <Input
              label="Work Schedule"
              value={formData.workSchedule}
              onChangeText={(v) => setFormData({ ...formData, workSchedule: v })}
              placeholder="e.g., Mon-Fri 9am-5pm"
            />

            <TouchableOpacity
              style={styles.dateButton}
              onPress={() => setShowStartDatePicker(true)}
            >
              <View style={styles.dateContent}>
                <Text style={styles.dateLabel}>Start Date</Text>
                <Text style={styles.dateValue}>
                  {formData.startDate
                    ? formData.startDate.toLocaleDateString('en-US', {
                        month: 'short',
                        day: 'numeric',
                        year: 'numeric',
                      })
                    : 'Not set'}
                </Text>
              </View>
              <Ionicons name="calendar-outline" size={20} color={colors.text.tertiary} />
            </TouchableOpacity>

            {showStartDatePicker && (
              <DateTimePicker
                value={formData.startDate || new Date()}
                mode="date"
                display="spinner"
                onChange={(_: any, date?: Date) => {
                  setShowStartDatePicker(Platform.OS === 'ios');
                  if (date) setFormData({ ...formData, startDate: date });
                }}
              />
            )}
          </Card>

          {/* Agency */}
          <Card style={styles.card}>
            <Text style={styles.cardTitle}>Staffing Agency</Text>

            <Input
              label="Agency Name"
              value={formData.agencyName}
              onChangeText={(v) => setFormData({ ...formData, agencyName: v })}
              placeholder="e.g., Care.com, Agency XYZ"
              autoCapitalize="words"
            />

            <Input
              label="Agency Contact"
              value={formData.agencyContact}
              onChangeText={(v) => setFormData({ ...formData, agencyContact: v })}
              placeholder="Contact person at agency"
              autoCapitalize="words"
            />

            <Input
              label="Agency Phone"
              value={formData.agencyPhone}
              onChangeText={(v) => setFormData({ ...formData, agencyPhone: v })}
              placeholder="(555) 123-4567"
              keyboardType="phone-pad"
            />
          </Card>

          {/* Responsibilities */}
          <Card style={styles.card}>
            <Text style={styles.cardTitle}>Responsibilities</Text>
            <Input
              value={formData.responsibilities}
              onChangeText={(v) => setFormData({ ...formData, responsibilities: v })}
              placeholder="Describe key duties and responsibilities..."
              multiline
              numberOfLines={4}
            />
          </Card>

          {/* Compensation */}
          <Card style={styles.card}>
            <Text style={styles.cardTitle}>Compensation</Text>

            <View style={styles.typeSelector}>
              <Text style={styles.typeLabel}>Pay Frequency</Text>
              <ScrollView horizontal showsHorizontalScrollIndicator={false}>
                {PAY_FREQUENCIES.map((freq) => (
                  <TouchableOpacity
                    key={freq.id}
                    style={[styles.typeChip, formData.payFrequency === freq.id && styles.typeChipActive]}
                    onPress={() => setFormData({ ...formData, payFrequency: freq.id })}
                  >
                    <Text style={[styles.typeChipText, formData.payFrequency === freq.id && styles.typeChipTextActive]}>
                      {freq.label}
                    </Text>
                  </TouchableOpacity>
                ))}
              </ScrollView>
            </View>

            <Input
              label="Pay Amount ($)"
              value={formData.payAmount}
              onChangeText={(v) => setFormData({ ...formData, payAmount: v.replace(/[^0-9.]/g, '') })}
              keyboardType="decimal-pad"
              placeholder="e.g., 1500"
            />
          </Card>

          {/* Emergency Contact */}
          <Card style={styles.card}>
            <Text style={styles.cardTitle}>Emergency Contact</Text>

            <Input
              label="Name"
              value={formData.emergencyContactName}
              onChangeText={(v) => setFormData({ ...formData, emergencyContactName: v })}
              placeholder="Emergency contact name"
              autoCapitalize="words"
            />

            <Input
              label="Phone"
              value={formData.emergencyContactPhone}
              onChangeText={(v) => setFormData({ ...formData, emergencyContactPhone: v })}
              placeholder="(555) 123-4567"
              keyboardType="phone-pad"
            />

          </Card>

          {/* Notes */}
          <Card style={styles.card}>
            <Text style={styles.cardTitle}>Notes</Text>
            <Input
              value={formData.notes}
              onChangeText={(v) => setFormData({ ...formData, notes: v })}
              placeholder="Add any notes..."
              multiline
              numberOfLines={3}
            />
          </Card>

          {/* Delete Button */}
          <TouchableOpacity style={styles.deleteButton} onPress={handleDelete}>
            <Ionicons name="trash-outline" size={20} color={colors.status.error} />
            <Text style={styles.deleteButtonText}>Remove Staff</Text>
          </TouchableOpacity>
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
  row: {
    flexDirection: 'row',
    gap: spacing[3],
  },
  halfInput: {
    flex: 1,
  },
  typeSelector: {
    marginBottom: spacing[3],
  },
  typeLabel: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.tertiary,
    marginBottom: spacing[2],
  },
  typeChip: {
    paddingHorizontal: spacing[3],
    paddingVertical: spacing[2],
    borderRadius: borderRadius.full,
    backgroundColor: colors.gray[100],
    marginRight: spacing[2],
  },
  typeChipActive: {
    backgroundColor: colors.haven.purple[500],
  },
  typeChipText: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
  },
  typeChipTextActive: {
    color: colors.white,
    fontWeight: typography.fontWeights.medium,
  },
  dateButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    padding: spacing[3],
    borderRadius: borderRadius.lg,
    backgroundColor: colors.gray[50],
    borderWidth: 1,
    borderColor: colors.border.default,
    marginTop: spacing[2],
  },
  dateContent: {
    flex: 1,
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
  deleteButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    padding: spacing[4],
    gap: spacing[2],
    marginTop: spacing[2],
  },
  deleteButtonText: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.medium,
    color: colors.status.error,
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

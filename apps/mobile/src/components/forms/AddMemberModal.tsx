import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  Modal,
  TouchableOpacity,
  ScrollView,
  TextInput,
  KeyboardAvoidingView,
  Platform,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { colors, typography, spacing, borderRadius } from '../../lib/theme';
import { API_BASE_URL } from '../../lib/api';
import { getIdToken } from '../../lib/firebase';
import { Button } from '../ui/Button';

// =============================================================================
// TYPES
// =============================================================================

type MemberType = 'ADULT' | 'CHILD' | 'STAFF';

interface AddMemberModalProps {
  visible: boolean;
  onClose: () => void;
  householdId: string;
  onSuccess: () => void;
  initialType?: MemberType;
}

// =============================================================================
// COMPONENT
// =============================================================================

export function AddMemberModal({
  visible,
  onClose,
  householdId,
  onSuccess,
  initialType = 'ADULT',
}: AddMemberModalProps) {
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Form state
  const [type, setType] = useState<MemberType>(initialType);
  const [firstName, setFirstName] = useState('');
  const [lastName, setLastName] = useState('');
  const [relationship, setRelationship] = useState('');
  const [email, setEmail] = useState('');
  const [phone, setPhone] = useState('');

  // Child-specific
  const [school, setSchool] = useState('');
  const [schoolGrade, setSchoolGrade] = useState('');

  // Staff-specific
  const [workSchedule, setWorkSchedule] = useState('');

  const resetForm = () => {
    setType(initialType);
    setFirstName('');
    setLastName('');
    setRelationship('');
    setEmail('');
    setPhone('');
    setSchool('');
    setSchoolGrade('');
    setWorkSchedule('');
    setError(null);
  };

  const handleClose = () => {
    resetForm();
    onClose();
  };

  const handleSubmit = async () => {
    if (!firstName.trim()) {
      setError('First name is required');
      return;
    }

    setIsSubmitting(true);
    setError(null);

    try {
      const token = await getIdToken(true);
      if (!token) {
        setError('Authentication expired. Please sign in again.');
        return;
      }

      const response = await fetch(
        `${API_BASE_URL}/family/household/${householdId}/members`,
        {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${token}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            firstName: firstName.trim(),
            lastName: lastName.trim() || undefined,
            type,
            relationship: relationship.trim() || undefined,
            email: email.trim() || undefined,
            phone: phone.trim() || undefined,
            school: type === 'CHILD' ? school.trim() || undefined : undefined,
            schoolGrade: type === 'CHILD' ? schoolGrade.trim() || undefined : undefined,
            workSchedule: type === 'STAFF' ? workSchedule.trim() || undefined : undefined,
          }),
        }
      );

      if (!response.ok) {
        throw new Error('Failed to add family member');
      }

      handleClose();
      onSuccess();
    } catch (err) {
      console.error('Add member error:', err);
      setError('Failed to add family member. Please try again.');
    } finally {
      setIsSubmitting(false);
    }
  };

  const getTypeLabel = (t: MemberType) => {
    switch (t) {
      case 'ADULT': return 'Adult';
      case 'CHILD': return 'Child';
      case 'STAFF': return 'Household Staff';
    }
  };

  return (
    <Modal
      visible={visible}
      animationType="slide"
      presentationStyle="pageSheet"
      onRequestClose={handleClose}
    >
      <SafeAreaView style={styles.container} edges={['top']}>
        <KeyboardAvoidingView
          behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
          style={styles.keyboardView}
        >
          {/* Header */}
          <View style={styles.header}>
            <TouchableOpacity onPress={handleClose} style={styles.closeButton}>
              <Ionicons name="close" size={24} color={colors.text.primary} />
            </TouchableOpacity>
            <Text style={styles.title}>Add Family Member</Text>
            <View style={styles.placeholder} />
          </View>

          <ScrollView
            contentContainerStyle={styles.scrollContent}
            showsVerticalScrollIndicator={false}
            keyboardShouldPersistTaps="handled"
          >
            {/* Type Selection */}
            <View style={styles.section}>
              <Text style={styles.label}>Member Type</Text>
              <View style={styles.typeButtons}>
                {(['ADULT', 'CHILD', 'STAFF'] as MemberType[]).map((t) => (
                  <TouchableOpacity
                    key={t}
                    style={[styles.typeButton, type === t && styles.typeButtonActive]}
                    onPress={() => setType(t)}
                  >
                    <Text style={[styles.typeButtonText, type === t && styles.typeButtonTextActive]}>
                      {getTypeLabel(t)}
                    </Text>
                  </TouchableOpacity>
                ))}
              </View>
            </View>

            {/* Basic Info */}
            <View style={styles.section}>
              <Text style={styles.label}>First Name *</Text>
              <TextInput
                style={styles.input}
                value={firstName}
                onChangeText={setFirstName}
                placeholder="Enter first name"
                placeholderTextColor={colors.text.tertiary}
              />
            </View>

            <View style={styles.section}>
              <Text style={styles.label}>Last Name</Text>
              <TextInput
                style={styles.input}
                value={lastName}
                onChangeText={setLastName}
                placeholder="Enter last name"
                placeholderTextColor={colors.text.tertiary}
              />
            </View>

            <View style={styles.section}>
              <Text style={styles.label}>Relationship</Text>
              <TextInput
                style={styles.input}
                value={relationship}
                onChangeText={setRelationship}
                placeholder={type === 'ADULT' ? 'e.g., Spouse, Partner' : type === 'CHILD' ? 'e.g., Son, Daughter' : 'e.g., Nanny, Housekeeper'}
                placeholderTextColor={colors.text.tertiary}
              />
            </View>

            {/* Contact (Adults and Staff only) */}
            {type !== 'CHILD' && (
              <>
                <View style={styles.section}>
                  <Text style={styles.label}>Email</Text>
                  <TextInput
                    style={styles.input}
                    value={email}
                    onChangeText={setEmail}
                    placeholder="Enter email"
                    placeholderTextColor={colors.text.tertiary}
                    keyboardType="email-address"
                    autoCapitalize="none"
                  />
                </View>

                <View style={styles.section}>
                  <Text style={styles.label}>Phone</Text>
                  <TextInput
                    style={styles.input}
                    value={phone}
                    onChangeText={setPhone}
                    placeholder="Enter phone number"
                    placeholderTextColor={colors.text.tertiary}
                    keyboardType="phone-pad"
                  />
                </View>
              </>
            )}

            {/* Child-specific */}
            {type === 'CHILD' && (
              <>
                <View style={styles.section}>
                  <Text style={styles.label}>School</Text>
                  <TextInput
                    style={styles.input}
                    value={school}
                    onChangeText={setSchool}
                    placeholder="Enter school name"
                    placeholderTextColor={colors.text.tertiary}
                  />
                </View>

                <View style={styles.section}>
                  <Text style={styles.label}>Grade</Text>
                  <TextInput
                    style={styles.input}
                    value={schoolGrade}
                    onChangeText={setSchoolGrade}
                    placeholder="e.g., 3rd Grade, Kindergarten"
                    placeholderTextColor={colors.text.tertiary}
                  />
                </View>
              </>
            )}

            {/* Staff-specific */}
            {type === 'STAFF' && (
              <View style={styles.section}>
                <Text style={styles.label}>Work Schedule</Text>
                <TextInput
                  style={styles.input}
                  value={workSchedule}
                  onChangeText={setWorkSchedule}
                  placeholder="e.g., M-F 8am-6pm"
                  placeholderTextColor={colors.text.tertiary}
                />
              </View>
            )}

            {/* Error */}
            {error && (
              <View style={styles.errorContainer}>
                <Text style={styles.errorText}>{error}</Text>
              </View>
            )}

            {/* Submit Button */}
            <View style={styles.buttonContainer}>
              <Button
                title={isSubmitting ? 'Adding...' : 'Add Member'}
                onPress={handleSubmit}
                disabled={isSubmitting || !firstName.trim()}
                variant="primary"
              />
            </View>
          </ScrollView>
        </KeyboardAvoidingView>
      </SafeAreaView>
    </Modal>
  );
}

// =============================================================================
// STYLES
// =============================================================================

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
  },
  title: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
  },
  placeholder: {
    width: 40,
  },
  scrollContent: {
    padding: spacing[4],
    paddingBottom: spacing[8],
  },
  section: {
    marginBottom: spacing[4],
  },
  label: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.secondary,
    marginBottom: spacing[2],
  },
  input: {
    backgroundColor: colors.background.secondary,
    borderRadius: borderRadius.lg,
    paddingHorizontal: spacing[4],
    paddingVertical: spacing[3],
    fontSize: typography.fontSizes.base,
    color: colors.text.primary,
    borderWidth: 1,
    borderColor: colors.border.light,
  },
  typeButtons: {
    flexDirection: 'row',
    gap: spacing[2],
  },
  typeButton: {
    flex: 1,
    paddingVertical: spacing[3],
    paddingHorizontal: spacing[3],
    borderRadius: borderRadius.lg,
    backgroundColor: colors.background.secondary,
    borderWidth: 1,
    borderColor: colors.border.light,
    alignItems: 'center',
  },
  typeButtonActive: {
    backgroundColor: colors.haven.purple[50],
    borderColor: colors.haven.purple[500],
  },
  typeButtonText: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.secondary,
  },
  typeButtonTextActive: {
    color: colors.haven.purple[700],
  },
  errorContainer: {
    backgroundColor: colors.status.error + '20',
    padding: spacing[3],
    borderRadius: borderRadius.md,
    marginBottom: spacing[4],
  },
  errorText: {
    fontSize: typography.fontSizes.sm,
    color: colors.status.error,
    textAlign: 'center',
  },
  buttonContainer: {
    marginTop: spacing[4],
  },
});

import React, { useState, useEffect } from 'react';
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

type ActivityType = 'SPORTS' | 'MUSIC' | 'ARTS' | 'ACADEMIC' | 'RELIGIOUS' | 'SOCIAL' | 'CAMP' | 'OTHER_ACTIVITY';

interface FamilyMember {
  id: string;
  firstName: string;
  lastName: string;
}

interface AddActivityModalProps {
  visible: boolean;
  onClose: () => void;
  householdId: string;
  onSuccess: () => void;
  familyMembers: FamilyMember[];
}

// =============================================================================
// COMPONENT
// =============================================================================

export function AddActivityModal({
  visible,
  onClose,
  householdId,
  onSuccess,
  familyMembers,
}: AddActivityModalProps) {
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Form state
  const [name, setName] = useState('');
  const [type, setType] = useState<ActivityType>('SPORTS');
  const [familyMemberId, setFamilyMemberId] = useState('');
  const [organization, setOrganization] = useState('');
  const [location, setLocation] = useState('');
  const [schedule, setSchedule] = useState('');
  const [coachName, setCoachName] = useState('');
  const [contactPhone, setContactPhone] = useState('');

  // Set default family member
  useEffect(() => {
    if (familyMembers.length > 0 && !familyMemberId) {
      setFamilyMemberId(familyMembers[0].id);
    }
  }, [familyMembers]);

  const resetForm = () => {
    setName('');
    setType('SPORTS');
    setFamilyMemberId(familyMembers.length > 0 ? familyMembers[0].id : '');
    setOrganization('');
    setLocation('');
    setSchedule('');
    setCoachName('');
    setContactPhone('');
    setError(null);
  };

  const handleClose = () => {
    resetForm();
    onClose();
  };

  const handleSubmit = async () => {
    if (!name.trim()) {
      setError('Activity name is required');
      return;
    }
    if (!familyMemberId) {
      setError('Please select a family member');
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
        `${API_BASE_URL}/family/household/${householdId}/activities`,
        {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${token}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            name: name.trim(),
            type,
            familyMemberId,
            organization: organization.trim() || undefined,
            location: location.trim() || undefined,
            schedule: schedule.trim() || undefined,
            coachName: coachName.trim() || undefined,
            contactPhone: contactPhone.trim() || undefined,
          }),
        }
      );

      if (!response.ok) {
        throw new Error('Failed to add activity');
      }

      handleClose();
      onSuccess();
    } catch (err) {
      console.error('Add activity error:', err);
      setError('Failed to add activity. Please try again.');
    } finally {
      setIsSubmitting(false);
    }
  };

  const activityTypes: { value: ActivityType; label: string; icon: string }[] = [
    { value: 'SPORTS', label: 'Sports', icon: 'football' },
    { value: 'MUSIC', label: 'Music', icon: 'musical-notes' },
    { value: 'ARTS', label: 'Arts', icon: 'color-palette' },
    { value: 'ACADEMIC', label: 'Academic', icon: 'school' },
    { value: 'RELIGIOUS', label: 'Religious', icon: 'heart' },
    { value: 'SOCIAL', label: 'Social', icon: 'people' },
    { value: 'CAMP', label: 'Camp', icon: 'bonfire' },
    { value: 'OTHER_ACTIVITY', label: 'Other', icon: 'ellipsis-horizontal' },
  ];

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
            <Text style={styles.title}>Add Activity</Text>
            <View style={styles.placeholder} />
          </View>

          <ScrollView
            contentContainerStyle={styles.scrollContent}
            showsVerticalScrollIndicator={false}
            keyboardShouldPersistTaps="handled"
          >
            {/* Family Member Selection */}
            {familyMembers.length > 0 && (
              <View style={styles.section}>
                <Text style={styles.label}>Family Member *</Text>
                <View style={styles.memberButtons}>
                  {familyMembers.map((member) => (
                    <TouchableOpacity
                      key={member.id}
                      style={[
                        styles.memberButton,
                        familyMemberId === member.id && styles.memberButtonActive,
                      ]}
                      onPress={() => setFamilyMemberId(member.id)}
                    >
                      <Text
                        style={[
                          styles.memberButtonText,
                          familyMemberId === member.id && styles.memberButtonTextActive,
                        ]}
                      >
                        {member.firstName}
                      </Text>
                    </TouchableOpacity>
                  ))}
                </View>
              </View>
            )}

            {/* Activity Type */}
            <View style={styles.section}>
              <Text style={styles.label}>Activity Type</Text>
              <View style={styles.typeGrid}>
                {activityTypes.map((at) => (
                  <TouchableOpacity
                    key={at.value}
                    style={[styles.typeButton, type === at.value && styles.typeButtonActive]}
                    onPress={() => setType(at.value)}
                  >
                    <Ionicons
                      name={at.icon as any}
                      size={18}
                      color={type === at.value ? colors.haven.purple[600] : colors.text.tertiary}
                    />
                    <Text style={[styles.typeButtonText, type === at.value && styles.typeButtonTextActive]}>
                      {at.label}
                    </Text>
                  </TouchableOpacity>
                ))}
              </View>
            </View>

            {/* Activity Name */}
            <View style={styles.section}>
              <Text style={styles.label}>Activity Name *</Text>
              <TextInput
                style={styles.input}
                value={name}
                onChangeText={setName}
                placeholder="e.g., Soccer, Piano Lessons, Math Tutoring"
                placeholderTextColor={colors.text.tertiary}
              />
            </View>

            {/* Organization */}
            <View style={styles.section}>
              <Text style={styles.label}>Organization</Text>
              <TextInput
                style={styles.input}
                value={organization}
                onChangeText={setOrganization}
                placeholder="e.g., YMCA, Local Music School"
                placeholderTextColor={colors.text.tertiary}
              />
            </View>

            {/* Location */}
            <View style={styles.section}>
              <Text style={styles.label}>Location</Text>
              <TextInput
                style={styles.input}
                value={location}
                onChangeText={setLocation}
                placeholder="e.g., Community Center, 123 Main St"
                placeholderTextColor={colors.text.tertiary}
              />
            </View>

            {/* Schedule */}
            <View style={styles.section}>
              <Text style={styles.label}>Schedule</Text>
              <TextInput
                style={styles.input}
                value={schedule}
                onChangeText={setSchedule}
                placeholder="e.g., Tuesdays 4-5pm"
                placeholderTextColor={colors.text.tertiary}
              />
            </View>

            {/* Coach/Contact */}
            <View style={styles.sectionDivider}>
              <Text style={styles.sectionTitle}>Contact</Text>
            </View>

            <View style={styles.section}>
              <Text style={styles.label}>Coach/Instructor Name</Text>
              <TextInput
                style={styles.input}
                value={coachName}
                onChangeText={setCoachName}
                placeholder="Enter name"
                placeholderTextColor={colors.text.tertiary}
              />
            </View>

            <View style={styles.section}>
              <Text style={styles.label}>Contact Phone</Text>
              <TextInput
                style={styles.input}
                value={contactPhone}
                onChangeText={setContactPhone}
                placeholder="Enter phone number"
                placeholderTextColor={colors.text.tertiary}
                keyboardType="phone-pad"
              />
            </View>

            {/* Error */}
            {error && (
              <View style={styles.errorContainer}>
                <Text style={styles.errorText}>{error}</Text>
              </View>
            )}

            {/* Submit Button */}
            <View style={styles.buttonContainer}>
              <Button
                title={isSubmitting ? 'Adding...' : 'Add Activity'}
                onPress={handleSubmit}
                disabled={isSubmitting || !name.trim() || !familyMemberId}
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
  sectionDivider: {
    marginTop: spacing[4],
    marginBottom: spacing[4],
    paddingBottom: spacing[2],
    borderBottomWidth: 1,
    borderBottomColor: colors.border.light,
  },
  sectionTitle: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
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
  memberButtons: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: spacing[2],
  },
  memberButton: {
    paddingVertical: spacing[2],
    paddingHorizontal: spacing[4],
    borderRadius: borderRadius.full,
    backgroundColor: colors.background.secondary,
    borderWidth: 1,
    borderColor: colors.border.light,
  },
  memberButtonActive: {
    backgroundColor: colors.haven.purple[50],
    borderColor: colors.haven.purple[500],
  },
  memberButtonText: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.secondary,
  },
  memberButtonTextActive: {
    color: colors.haven.purple[700],
  },
  typeGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: spacing[2],
  },
  typeButton: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: spacing[2],
    paddingHorizontal: spacing[3],
    borderRadius: borderRadius.lg,
    backgroundColor: colors.background.secondary,
    borderWidth: 1,
    borderColor: colors.border.light,
    gap: spacing[1],
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
    color: colors.haven.purple[600],
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

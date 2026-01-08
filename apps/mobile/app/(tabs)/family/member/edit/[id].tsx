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
import { Card, Button, Input, LoadingSpinner, ImageUpload } from '../../../../../src/components';
import { colors, typography, spacing, borderRadius } from '../../../../../src/lib/theme';
import { API_BASE_URL } from '../../../../../src/lib/api';
import { getIdToken } from '../../../../../src/lib/firebase';

interface FamilyMember {
  id: string;
  firstName: string;
  lastName: string;
  email?: string;
  phone?: string;
  relationship?: string;
  birthdate?: string;
  avatarUrl?: string;
  notes?: string;
  role?: string;
}

const RELATIONSHIPS = [
  { id: 'SPOUSE', label: 'Spouse/Partner' },
  { id: 'CHILD', label: 'Child' },
  { id: 'PARENT', label: 'Parent' },
  { id: 'SIBLING', label: 'Sibling' },
  { id: 'RELATIVE', label: 'Other Relative' },
  { id: 'ROOMMATE', label: 'Roommate' },
  { id: 'OTHER', label: 'Other' },
];

export default function EditFamilyMemberScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const router = useRouter();
  const { householdInfo } = useAuth();
  const [isLoading, setIsLoading] = useState(true);
  const [isSaving, setIsSaving] = useState(false);
  const [showDatePicker, setShowDatePicker] = useState(false);
  const [avatar, setAvatar] = useState<string | null>(null);

  const [formData, setFormData] = useState({
    firstName: '',
    lastName: '',
    email: '',
    phone: '',
    relationship: 'OTHER',
    birthdate: null as Date | null,
    notes: '',
  });

  const fetchMember = useCallback(async () => {
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

      const response = await fetch(`${API_BASE_URL}/households/${householdInfo.id}/members/${id}`, {
        headers: {
          Authorization: `Bearer ${token}`,
        },
      });

      if (response.ok) {
        const member: FamilyMember = await response.json();
        setFormData({
          firstName: member.firstName || '',
          lastName: member.lastName || '',
          email: member.email || '',
          phone: member.phone || '',
          relationship: member.relationship || 'OTHER',
          birthdate: member.birthdate ? new Date(member.birthdate) : null,
          notes: member.notes || '',
        });
        setAvatar(member.avatarUrl || null);
      }
    } catch (err) {
      console.error('Fetch member error:', err);
    } finally {
      setIsLoading(false);
    }
  }, [id, householdInfo?.id]);

  useEffect(() => {
    fetchMember();
  }, [fetchMember]);

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
        lastName: formData.lastName.trim(),
        email: formData.email.trim() || null,
        phone: formData.phone.trim() || null,
        relationship: formData.relationship,
        birthdate: formData.birthdate?.toISOString() || null,
        notes: formData.notes.trim() || null,
        avatarUrl: avatar,
      };

      const response = await fetch(`${API_BASE_URL}/households/${householdInfo?.id}/members/${id}`, {
        method: 'PATCH',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(body),
      });

      if (!response.ok && response.status !== 404) {
        throw new Error('Failed to update member');
      }

      Alert.alert('Success', 'Family member updated successfully', [
        { text: 'OK', onPress: () => router.back() },
      ]);
    } catch (error) {
      console.error('Update member error:', error);
      Alert.alert('Error', 'Failed to update family member. Please try again.');
    } finally {
      setIsSaving(false);
    }
  };

  const handleDelete = () => {
    Alert.alert(
      'Remove Family Member',
      'Are you sure you want to remove this family member? This action cannot be undone.',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Remove',
          style: 'destructive',
          onPress: async () => {
            try {
              const token = await getIdToken(true);
              if (!token) return;

              await fetch(`${API_BASE_URL}/households/${householdInfo?.id}/members/${id}`, {
                method: 'DELETE',
                headers: { Authorization: `Bearer ${token}` },
              });

              router.back();
            } catch (err) {
              console.error('Delete member error:', err);
              Alert.alert('Error', 'Failed to remove family member');
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
      <Stack.Screen options={{ title: 'Edit Family Member' }} />
      <KeyboardAvoidingView
        behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
        style={styles.keyboardView}
      >
        <ScrollView
          contentContainerStyle={styles.scrollContent}
          showsVerticalScrollIndicator={false}
        >
          {/* Avatar */}
          <View style={styles.avatarSection}>
            <ImageUpload
              currentImage={avatar}
              onImageSelected={setAvatar}
              shape="circle"
              size="large"
              placeholder="Add Photo"
            />
          </View>

          {/* Personal Info */}
          <Card style={styles.card}>
            <Text style={styles.cardTitle}>Personal Information</Text>

            <Input
              label="First Name"
              value={formData.firstName}
              onChangeText={(v) => setFormData({ ...formData, firstName: v })}
              leftIcon="person-outline"
              placeholder="Enter first name"
              autoCapitalize="words"
            />

            <Input
              label="Last Name"
              value={formData.lastName}
              onChangeText={(v) => setFormData({ ...formData, lastName: v })}
              leftIcon="person-outline"
              placeholder="Enter last name"
              autoCapitalize="words"
            />

            <Input
              label="Email"
              value={formData.email}
              onChangeText={(v) => setFormData({ ...formData, email: v })}
              keyboardType="email-address"
              autoCapitalize="none"
              leftIcon="mail-outline"
              placeholder="Enter email (optional)"
            />

            <Input
              label="Phone"
              value={formData.phone}
              onChangeText={(v) => setFormData({ ...formData, phone: v })}
              keyboardType="phone-pad"
              leftIcon="call-outline"
              placeholder="Enter phone (optional)"
            />
          </Card>

          {/* Relationship */}
          <Card style={styles.card}>
            <Text style={styles.cardTitle}>Relationship</Text>
            <View style={styles.relationshipGrid}>
              {RELATIONSHIPS.map((rel) => (
                <TouchableOpacity
                  key={rel.id}
                  style={[
                    styles.relationshipItem,
                    formData.relationship === rel.id && styles.relationshipItemSelected,
                  ]}
                  onPress={() => setFormData({ ...formData, relationship: rel.id })}
                >
                  <Text
                    style={[
                      styles.relationshipLabel,
                      formData.relationship === rel.id && styles.relationshipLabelSelected,
                    ]}
                  >
                    {rel.label}
                  </Text>
                </TouchableOpacity>
              ))}
            </View>
          </Card>

          {/* Birthdate */}
          <Card style={styles.card}>
            <Text style={styles.cardTitle}>Birthday</Text>
            <TouchableOpacity
              style={styles.dateButton}
              onPress={() => setShowDatePicker(true)}
            >
              <Ionicons name="calendar-outline" size={20} color={colors.haven.champagne[500]} />
              <Text style={styles.dateValue}>
                {formData.birthdate
                  ? formData.birthdate.toLocaleDateString('en-US', {
                      month: 'long',
                      day: 'numeric',
                      year: 'numeric',
                    })
                  : 'Select birthday (optional)'}
              </Text>
              <Ionicons name="chevron-forward" size={20} color={colors.text.tertiary} />
            </TouchableOpacity>

            {showDatePicker && (
              <DateTimePicker
                value={formData.birthdate || new Date()}
                mode="date"
                display="spinner"
                maximumDate={new Date()}
                onChange={(_: any, date?: Date) => {
                  setShowDatePicker(Platform.OS === 'ios');
                  if (date) setFormData({ ...formData, birthdate: date });
                }}
              />
            )}
          </Card>

          {/* Notes */}
          <Card style={styles.card}>
            <Text style={styles.cardTitle}>Notes</Text>
            <Input
              value={formData.notes}
              onChangeText={(v) => setFormData({ ...formData, notes: v })}
              placeholder="Add any notes or special information..."
              multiline
              numberOfLines={3}
            />
          </Card>

          {/* Delete Button */}
          <TouchableOpacity style={styles.deleteButton} onPress={handleDelete}>
            <Ionicons name="trash-outline" size={20} color={colors.status.error} />
            <Text style={styles.deleteButtonText}>Remove Family Member</Text>
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
  avatarSection: {
    alignItems: 'center',
    marginBottom: spacing[4],
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
  relationshipGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: spacing[2],
  },
  relationshipItem: {
    paddingVertical: spacing[2],
    paddingHorizontal: spacing[3],
    borderRadius: borderRadius.full,
    borderWidth: 1,
    borderColor: colors.border.default,
    backgroundColor: colors.white,
  },
  relationshipItemSelected: {
    borderColor: colors.haven.champagne[500],
    backgroundColor: colors.haven.champagne[50],
  },
  relationshipLabel: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
  },
  relationshipLabelSelected: {
    color: colors.haven.champagne[600],
    fontWeight: typography.fontWeights.medium,
  },
  dateButton: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: spacing[3],
    borderRadius: borderRadius.lg,
    backgroundColor: colors.gray[50],
    borderWidth: 1,
    borderColor: colors.border.default,
    gap: spacing[3],
  },
  dateValue: {
    flex: 1,
    fontSize: typography.fontSizes.base,
    color: colors.text.primary,
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

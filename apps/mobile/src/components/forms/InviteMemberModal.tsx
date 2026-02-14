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
  ActivityIndicator,
  Alert,
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

type InviteRole = 'MEMBER' | 'ADMIN' | 'CHILD';

interface PendingInvitation {
  id: string;
  email: string;
  role: string;
  expiresAt: string;
  createdAt: string;
  isExpired: boolean;
}

interface InviteMemberModalProps {
  visible: boolean;
  onClose: () => void;
  householdId: string;
  onSuccess: () => void;
}

// =============================================================================
// COMPONENT
// =============================================================================

export function InviteMemberModal({
  visible,
  onClose,
  householdId,
  onSuccess,
}: InviteMemberModalProps) {
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Form state
  const [email, setEmail] = useState('');
  const [role, setRole] = useState<InviteRole>('MEMBER');

  // Pending invitations
  const [pendingInvites, setPendingInvites] = useState<PendingInvitation[]>([]);

  useEffect(() => {
    if (visible) {
      fetchPendingInvites();
    }
  }, [visible, householdId]);

  const fetchPendingInvites = async () => {
    if (!householdId) return;

    setIsLoading(true);
    try {
      const token = await getIdToken(true);
      if (!token) return;

      const response = await fetch(
        `${API_BASE_URL}/invitations/household/${householdId}`,
        {
          headers: {
            Authorization: `Bearer ${token}`,
          },
        }
      );

      if (response.ok) {
        const data = await response.json();
        setPendingInvites(data.filter((inv: PendingInvitation) => !inv.isExpired));
      }
    } catch (err) {
      console.error('Fetch pending invites error:', err);
    } finally {
      setIsLoading(false);
    }
  };

  const resetForm = () => {
    setEmail('');
    setRole('MEMBER');
    setError(null);
  };

  const handleClose = () => {
    resetForm();
    onClose();
  };

  const validateEmail = (email: string): boolean => {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
  };

  const handleSubmit = async () => {
    if (!email.trim()) {
      setError('Email is required');
      return;
    }

    if (!validateEmail(email)) {
      setError('Please enter a valid email address');
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

      const response = await fetch(`${API_BASE_URL}/invitations`, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          householdId,
          email: email.trim().toLowerCase(),
          role,
        }),
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.message || 'Failed to send invitation');
      }

      Alert.alert(
        'Invitation Sent',
        `An invitation has been sent to ${email}. They have 7 days to accept.`,
        [{ text: 'OK' }]
      );

      resetForm();
      fetchPendingInvites();
      onSuccess();
    } catch (err) {
      console.error('Invite member error:', err);
      setError(err instanceof Error ? err.message : 'Failed to send invitation');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleCancelInvite = async (inviteId: string) => {
    Alert.alert(
      'Cancel Invitation',
      'Are you sure you want to cancel this invitation?',
      [
        { text: 'No', style: 'cancel' },
        {
          text: 'Yes, Cancel',
          style: 'destructive',
          onPress: async () => {
            try {
              const token = await getIdToken(true);
              if (!token) return;

              const response = await fetch(
                `${API_BASE_URL}/invitations/${inviteId}`,
                {
                  method: 'DELETE',
                  headers: {
                    Authorization: `Bearer ${token}`,
                  },
                }
              );

              if (response.ok) {
                fetchPendingInvites();
              }
            } catch (err) {
              console.error('Cancel invite error:', err);
            }
          },
        },
      ]
    );
  };

  const handleResendInvite = async (inviteId: string) => {
    try {
      const token = await getIdToken(true);
      if (!token) return;

      const response = await fetch(`${API_BASE_URL}/invitations/resend`, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ invitationId: inviteId }),
      });

      if (response.ok) {
        Alert.alert('Success', 'Invitation has been resent');
        fetchPendingInvites();
      }
    } catch (err) {
      console.error('Resend invite error:', err);
    }
  };

  const getRoleLabel = (r: InviteRole) => {
    switch (r) {
      case 'ADMIN': return 'Admin';
      case 'CHILD': return 'Child';
      default: return 'Member';
    }
  };

  const getRoleDescription = (r: InviteRole) => {
    switch (r) {
      case 'ADMIN': return 'Can manage household and invite others';
      case 'CHILD': return 'Limited access, supervised account';
      default: return 'Full access to household features';
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
            <Text style={styles.title}>Invite to Household</Text>
            <View style={styles.placeholder} />
          </View>

          <ScrollView
            contentContainerStyle={styles.scrollContent}
            showsVerticalScrollIndicator={false}
            keyboardShouldPersistTaps="handled"
          >
            {/* Info Card */}
            <View style={styles.infoCard}>
              <Ionicons name="mail-outline" size={24} color={colors.haven.purple[500]} />
              <Text style={styles.infoText}>
                Send an invitation email to add someone to your household. They'll receive a link to join.
              </Text>
            </View>

            {/* Email Input */}
            <View style={styles.section}>
              <Text style={styles.label}>Email Address *</Text>
              <TextInput
                style={styles.input}
                value={email}
                onChangeText={setEmail}
                placeholder="Enter email address"
                placeholderTextColor={colors.text.tertiary}
                keyboardType="email-address"
                autoCapitalize="none"
                autoCorrect={false}
              />
            </View>

            {/* Role Selection */}
            <View style={styles.section}>
              <Text style={styles.label}>Role</Text>
              <View style={styles.roleButtons}>
                {(['MEMBER', 'ADMIN', 'CHILD'] as InviteRole[]).map((r) => (
                  <TouchableOpacity
                    key={r}
                    style={[styles.roleButton, role === r && styles.roleButtonActive]}
                    onPress={() => setRole(r)}
                  >
                    <Text style={[styles.roleButtonText, role === r && styles.roleButtonTextActive]}>
                      {getRoleLabel(r)}
                    </Text>
                    <Text style={[styles.roleDescription, role === r && styles.roleDescriptionActive]}>
                      {getRoleDescription(r)}
                    </Text>
                  </TouchableOpacity>
                ))}
              </View>
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
                title={isSubmitting ? 'Sending...' : 'Send Invitation'}
                onPress={handleSubmit}
                disabled={isSubmitting || !email.trim()}
                variant="primary"
              />
            </View>

            {/* Pending Invitations */}
            {(isLoading || pendingInvites.length > 0) && (
              <View style={styles.pendingSection}>
                <Text style={styles.pendingSectionTitle}>Pending Invitations</Text>

                {isLoading ? (
                  <ActivityIndicator size="small" color={colors.haven.purple[900]} />
                ) : (
                  pendingInvites.map((invite) => (
                    <View key={invite.id} style={styles.pendingCard}>
                      <View style={styles.pendingInfo}>
                        <Text style={styles.pendingEmail}>{invite.email}</Text>
                        <Text style={styles.pendingRole}>{invite.role}</Text>
                        <Text style={styles.pendingExpiry}>
                          Expires {new Date(invite.expiresAt).toLocaleDateString()}
                        </Text>
                      </View>
                      <View style={styles.pendingActions}>
                        <TouchableOpacity
                          style={styles.pendingAction}
                          onPress={() => handleResendInvite(invite.id)}
                        >
                          <Ionicons name="refresh" size={18} color={colors.haven.purple[500]} />
                        </TouchableOpacity>
                        <TouchableOpacity
                          style={styles.pendingAction}
                          onPress={() => handleCancelInvite(invite.id)}
                        >
                          <Ionicons name="close-circle" size={18} color={colors.status.error} />
                        </TouchableOpacity>
                      </View>
                    </View>
                  ))
                )}
              </View>
            )}
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
  infoCard: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.haven.purple[50],
    padding: spacing[4],
    borderRadius: borderRadius.lg,
    marginBottom: spacing[5],
    gap: spacing[3],
  },
  infoText: {
    flex: 1,
    fontSize: typography.fontSizes.sm,
    color: colors.haven.purple[700],
    lineHeight: 20,
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
  roleButtons: {
    gap: spacing[2],
  },
  roleButton: {
    paddingVertical: spacing[3],
    paddingHorizontal: spacing[4],
    borderRadius: borderRadius.lg,
    backgroundColor: colors.background.secondary,
    borderWidth: 1,
    borderColor: colors.border.light,
  },
  roleButtonActive: {
    backgroundColor: colors.haven.purple[50],
    borderColor: colors.haven.purple[500],
  },
  roleButtonText: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.primary,
    marginBottom: 2,
  },
  roleButtonTextActive: {
    color: colors.haven.purple[700],
  },
  roleDescription: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
  },
  roleDescriptionActive: {
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
  pendingSection: {
    marginTop: spacing[8],
    paddingTop: spacing[6],
    borderTopWidth: 1,
    borderTopColor: colors.border.light,
  },
  pendingSectionTitle: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
    marginBottom: spacing[4],
  },
  pendingCard: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.background.secondary,
    padding: spacing[3],
    borderRadius: borderRadius.lg,
    marginBottom: spacing[2],
  },
  pendingInfo: {
    flex: 1,
  },
  pendingEmail: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.primary,
  },
  pendingRole: {
    fontSize: typography.fontSizes.xs,
    color: colors.haven.purple[600],
    marginTop: 2,
  },
  pendingExpiry: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
    marginTop: 2,
  },
  pendingActions: {
    flexDirection: 'row',
    gap: spacing[2],
  },
  pendingAction: {
    padding: spacing[2],
  },
});

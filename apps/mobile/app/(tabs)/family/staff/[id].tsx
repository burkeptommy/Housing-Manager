import React, { useState, useEffect, useCallback } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Alert,
  RefreshControl,
  Linking,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useLocalSearchParams, useRouter, Stack } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { useAuth } from '../../../../src/contexts/auth-context';
import { Card, Badge, LoadingSpinner } from '../../../../src/components';
import { colors, typography, spacing, borderRadius } from '../../../../src/lib/theme';
import { API_BASE_URL } from '../../../../src/lib/api';
import { getIdToken } from '../../../../src/lib/firebase';

interface StaffDetail {
  id: string;
  firstName: string;
  lastName: string;
  relationship?: string | null;
  phone?: string | null;
  email?: string | null;
  workSchedule?: string | null;
  startDate?: string | null;
  notes?: string | null;
  emergencyContact?: boolean;
}

export default function StaffDetailScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const router = useRouter();
  const { householdInfo } = useAuth();
  const [staff, setStaff] = useState<StaffDetail | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const fetchStaff = useCallback(async () => {
    if (!id || !householdInfo?.id) return;

    try {
      const token = await getIdToken(true);
      if (!token) {
        setError('Authentication expired.');
        setIsLoading(false);
        return;
      }

      const response = await fetch(
        `${API_BASE_URL}/family/household/${householdInfo.id}/staff/${id}`,
        {
          headers: {
            Authorization: `Bearer ${token}`,
            'Content-Type': 'application/json',
          },
        }
      );

      if (!response.ok) {
        throw new Error(`Failed to fetch staff: ${response.status}`);
      }

      const data: StaffDetail = await response.json();
      setStaff(data);
      setError(null);
    } catch (err) {
      console.error('Fetch staff error:', err);
      setError('Failed to load staff details.');
    } finally {
      setIsLoading(false);
      setIsRefreshing(false);
    }
  }, [id, householdInfo?.id]);

  useEffect(() => {
    fetchStaff();
  }, [fetchStaff]);

  const handleCall = () => {
    if (staff?.phone) {
      Linking.openURL(`tel:${staff.phone}`);
    }
  };

  const handleEmail = () => {
    if (staff?.email) {
      Linking.openURL(`mailto:${staff.email}`);
    }
  };

  const handleMessage = () => {
    if (staff?.phone) {
      Linking.openURL(`sms:${staff.phone}`);
    }
  };

  const handleDelete = async () => {
    Alert.alert(
      'Remove Staff Member',
      'Are you sure you want to remove this staff member? This cannot be undone.',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Remove',
          style: 'destructive',
          onPress: async () => {
            try {
              const token = await getIdToken(true);
              if (!token) {
                Alert.alert('Error', 'Authentication expired.');
                return;
              }

              const response = await fetch(
                `${API_BASE_URL}/family/household/${householdInfo?.id}/staff/${id}`,
                {
                  method: 'DELETE',
                  headers: {
                    Authorization: `Bearer ${token}`,
                  },
                }
              );

              if (!response.ok) throw new Error('Failed to delete');

              Alert.alert('Removed', 'Staff member has been removed.');
              router.back();
            } catch (err) {
              Alert.alert('Error', 'Failed to remove staff member.');
            }
          },
        },
      ]
    );
  };

  const formatDate = (dateString?: string | null) => {
    if (!dateString) return null;
    return new Date(dateString).toLocaleDateString('en-US', {
      month: 'long',
      day: 'numeric',
      year: 'numeric',
    });
  };

  if (isLoading) {
    return <LoadingSpinner fullScreen message="Loading staff..." />;
  }

  if (error || !staff) {
    return (
      <SafeAreaView style={styles.container} edges={['bottom']}>
        <Stack.Screen options={{ title: 'Staff Member' }} />
        <View style={styles.errorContainer}>
          <Ionicons name="alert-circle" size={48} color={colors.status.error} />
          <Text style={styles.errorTitle}>Unable to Load Staff</Text>
          <Text style={styles.errorText}>{error || 'Staff member not found'}</Text>
          <TouchableOpacity style={styles.retryButton} onPress={fetchStaff}>
            <Text style={styles.retryText}>Try Again</Text>
          </TouchableOpacity>
        </View>
      </SafeAreaView>
    );
  }

  const fullName = `${staff.firstName} ${staff.lastName}`;
  const initials = `${staff.firstName?.[0] || ''}${staff.lastName?.[0] || ''}`;

  return (
    <SafeAreaView style={styles.container} edges={['bottom']}>
      <Stack.Screen
        options={{
          title: 'Staff Member',
          headerRight: () => (
            <TouchableOpacity onPress={() => Alert.alert('Edit', 'Edit staff coming soon')}>
              <Ionicons name="create-outline" size={24} color={colors.haven.champagne[500]} />
            </TouchableOpacity>
          ),
        }}
      />
      <ScrollView
        contentContainerStyle={styles.scrollContent}
        refreshControl={
          <RefreshControl
            refreshing={isRefreshing}
            onRefresh={() => {
              setIsRefreshing(true);
              fetchStaff();
            }}
          />
        }
      >
        {/* Profile Header */}
        <Card style={styles.profileCard}>
          <View style={styles.avatar}>
            <Text style={styles.avatarText}>{initials}</Text>
          </View>
          <Text style={styles.fullName}>{fullName}</Text>
          <View style={styles.badgeRow}>
            <Badge label={staff.relationship || 'Staff'} variant="default" />
            {staff.emergencyContact && (
              <Badge label="Emergency Contact" variant="warning" />
            )}
          </View>
        </Card>

        {/* Contact Actions */}
        {(staff.phone || staff.email) && (
          <View style={styles.actionButtons}>
            {staff.phone && (
              <TouchableOpacity style={styles.actionButton} onPress={handleCall}>
                <View style={styles.actionIcon}>
                  <Ionicons name="call" size={24} color={colors.haven.champagne[500]} />
                </View>
                <Text style={styles.actionButtonText}>Call</Text>
              </TouchableOpacity>
            )}
            {staff.phone && (
              <TouchableOpacity style={styles.actionButton} onPress={handleMessage}>
                <View style={styles.actionIcon}>
                  <Ionicons name="chatbubble" size={24} color={colors.haven.champagne[500]} />
                </View>
                <Text style={styles.actionButtonText}>Message</Text>
              </TouchableOpacity>
            )}
            {staff.email && (
              <TouchableOpacity style={styles.actionButton} onPress={handleEmail}>
                <View style={styles.actionIcon}>
                  <Ionicons name="mail" size={24} color={colors.haven.champagne[500]} />
                </View>
                <Text style={styles.actionButtonText}>Email</Text>
              </TouchableOpacity>
            )}
          </View>
        )}

        {/* Contact Info */}
        <Card style={styles.section}>
          <Text style={styles.sectionTitle}>Contact Information</Text>

          {staff.phone && (
            <View style={styles.detailRow}>
              <Ionicons name="call-outline" size={18} color={colors.text.tertiary} />
              <View style={styles.detailContent}>
                <Text style={styles.detailLabel}>Phone</Text>
                <Text style={styles.detailValue}>{staff.phone}</Text>
              </View>
            </View>
          )}

          {staff.email && (
            <View style={styles.detailRow}>
              <Ionicons name="mail-outline" size={18} color={colors.text.tertiary} />
              <View style={styles.detailContent}>
                <Text style={styles.detailLabel}>Email</Text>
                <Text style={styles.detailValue}>{staff.email}</Text>
              </View>
            </View>
          )}

          {!staff.phone && !staff.email && (
            <Text style={styles.emptyText}>No contact information</Text>
          )}
        </Card>

        {/* Work Schedule */}
        {staff.workSchedule && (
          <Card style={styles.section}>
            <Text style={styles.sectionTitle}>Work Schedule</Text>
            <View style={styles.scheduleContainer}>
              <Ionicons name="calendar-outline" size={20} color={colors.haven.champagne[500]} />
              <Text style={styles.scheduleText}>{staff.workSchedule}</Text>
            </View>
          </Card>
        )}

        {/* Employment Details */}
        {staff.startDate && (
          <Card style={styles.section}>
            <Text style={styles.sectionTitle}>Employment</Text>
            <View style={styles.detailRow}>
              <Ionicons name="briefcase-outline" size={18} color={colors.text.tertiary} />
              <View style={styles.detailContent}>
                <Text style={styles.detailLabel}>Start Date</Text>
                <Text style={styles.detailValue}>{formatDate(staff.startDate)}</Text>
              </View>
            </View>
          </Card>
        )}

        {/* Notes */}
        {staff.notes && (
          <Card style={styles.section}>
            <Text style={styles.sectionTitle}>Notes</Text>
            <Text style={styles.notes}>{staff.notes}</Text>
          </Card>
        )}

        {/* Delete Button */}
        <TouchableOpacity style={styles.deleteButton} onPress={handleDelete}>
          <Ionicons name="trash-outline" size={20} color={colors.status.error} />
          <Text style={styles.deleteButtonText}>Remove Staff Member</Text>
        </TouchableOpacity>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background.secondary,
  },
  scrollContent: {
    padding: spacing[4],
    paddingBottom: spacing[8],
  },
  errorContainer: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    padding: spacing[6],
  },
  errorTitle: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
    marginTop: spacing[4],
  },
  errorText: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    textAlign: 'center',
    marginTop: spacing[2],
  },
  retryButton: {
    marginTop: spacing[4],
    paddingHorizontal: spacing[6],
    paddingVertical: spacing[3],
    backgroundColor: colors.haven.champagne[500],
    borderRadius: borderRadius.lg,
  },
  retryText: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
    color: colors.white,
  },
  profileCard: {
    alignItems: 'center',
    padding: spacing[6],
    marginBottom: spacing[4],
  },
  avatar: {
    width: 80,
    height: 80,
    borderRadius: 40,
    backgroundColor: colors.haven.champagne[100],
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: spacing[3],
  },
  avatarText: {
    fontSize: typography.fontSizes['2xl'],
    fontWeight: typography.fontWeights.bold,
    color: colors.haven.champagne[600],
  },
  fullName: {
    fontSize: typography.fontSizes.xl,
    fontWeight: typography.fontWeights.bold,
    color: colors.text.primary,
    marginBottom: spacing[2],
  },
  badgeRow: {
    flexDirection: 'row',
    gap: spacing[2],
  },
  actionButtons: {
    flexDirection: 'row',
    justifyContent: 'center',
    gap: spacing[6],
    marginBottom: spacing[4],
  },
  actionButton: {
    alignItems: 'center',
    gap: spacing[1],
  },
  actionIcon: {
    width: 56,
    height: 56,
    borderRadius: 28,
    backgroundColor: colors.haven.champagne[50],
    alignItems: 'center',
    justifyContent: 'center',
  },
  actionButtonText: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    fontWeight: typography.fontWeights.medium,
  },
  section: {
    padding: spacing[4],
    marginBottom: spacing[4],
  },
  sectionTitle: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.secondary,
    textTransform: 'uppercase',
    letterSpacing: 0.5,
    marginBottom: spacing[3],
  },
  detailRow: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    paddingVertical: spacing[3],
    borderBottomWidth: 1,
    borderBottomColor: colors.border.light,
    gap: spacing[3],
  },
  detailContent: {
    flex: 1,
  },
  detailLabel: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
    marginBottom: 2,
  },
  detailValue: {
    fontSize: typography.fontSizes.base,
    color: colors.text.primary,
  },
  emptyText: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.tertiary,
    textAlign: 'center',
    paddingVertical: spacing[4],
  },
  scheduleContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[3],
    backgroundColor: colors.haven.champagne[50],
    padding: spacing[4],
    borderRadius: borderRadius.lg,
  },
  scheduleText: {
    flex: 1,
    fontSize: typography.fontSizes.base,
    color: colors.text.primary,
  },
  notes: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    lineHeight: 22,
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
});

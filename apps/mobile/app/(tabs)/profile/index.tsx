import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Alert,
  Image,
  RefreshControl,
} from 'react-native';
import { useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import * as ImagePicker from 'expo-image-picker';
import { useAuth } from '../../../src/contexts/auth-context';
import { Card, Button, Input, LoadingSpinner, AppHeader } from '../../../src/components';
import { colors, typography, spacing, borderRadius } from '../../../src/lib/theme';
import { API_BASE_URL } from '../../../src/lib/api';
import { getIdToken } from '../../../src/lib/firebase';
import { uploadProfileImage } from '../../../src/lib/image-upload';

export default function ProfileScreen() {
  const router = useRouter();
  const { user, householdInfo, currentHousehold, logout, refreshMe } = useAuth();
  const [isEditing, setIsEditing] = useState(false);
  const [isSaving, setIsSaving] = useState(false);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [avatar, setAvatar] = useState<string | null>(user?.avatarUrl || null);

  const [formData, setFormData] = useState({
    firstName: user?.firstName || '',
    lastName: user?.lastName || '',
    email: user?.email || '',
    phone: user?.phone || '',
  });

  // Update form when user changes
  useEffect(() => {
    if (user) {
      setFormData({
        firstName: user.firstName || '',
        lastName: user.lastName || '',
        email: user.email || '',
        phone: user.phone || '',
      });
      setAvatar(user.avatarUrl || null);
    }
  }, [user]);

  const displayName = `${formData.firstName} ${formData.lastName}`.trim() || 'User';
  const initials = `${formData.firstName?.[0] || ''}${formData.lastName?.[0] || ''}`.toUpperCase() || 'U';

  const handlePickAvatar = async () => {
    const result = await ImagePicker.launchImageLibraryAsync({
      mediaTypes: ['images'],
      allowsEditing: true,
      aspect: [1, 1],
      quality: 0.8,
    });

    if (!result.canceled && result.assets[0]) {
      setAvatar(result.assets[0].uri);
    }
  };

  const handleSave = async () => {
    setIsSaving(true);
    try {
      const token = await getIdToken(true);
      if (!token) {
        Alert.alert('Error', 'Authentication expired. Please sign in again.');
        return;
      }

      // Upload avatar if user picked a new local image
      let avatarUrl = avatar;
      if (avatar && avatar.startsWith('file://') && user?.id) {
        try {
          avatarUrl = await uploadProfileImage('user', user.id, avatar);
          setAvatar(avatarUrl);
        } catch (uploadErr) {
          console.error('Avatar upload error:', uploadErr);
          // Continue saving other fields even if upload fails
        }
      }

      const response = await fetch(`${API_BASE_URL}/users/profile`, {
        method: 'PATCH',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          firstName: formData.firstName,
          lastName: formData.lastName,
          phone: formData.phone,
          avatarUrl: avatarUrl || null,
        }),
      });

      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}));
        throw new Error(errorData.message || 'Failed to update profile');
      }

      await refreshMe();
      setIsEditing(false);
      Alert.alert('Success', 'Profile updated successfully');
    } catch (error) {
      console.error('Update profile error:', error);
      Alert.alert('Error', 'Failed to update profile. Please try again.');
    } finally {
      setIsSaving(false);
    }
  };

  const handleRefresh = async () => {
    setIsRefreshing(true);
    try {
      await refreshMe();
    } finally {
      setIsRefreshing(false);
    }
  };

  const handleSignOut = () => {
    Alert.alert(
      'Sign Out',
      'Are you sure you want to sign out?',
      [
        { text: 'Cancel', style: 'cancel' },
        { text: 'Sign Out', style: 'destructive', onPress: logout },
      ]
    );
  };

  return (
    <View style={styles.fullContainer}>
      <AppHeader title="Profile" showBack onBackPress={() => router.navigate('/more')} />
      <ScrollView
        style={styles.scrollContainer}
        contentContainerStyle={styles.scrollContent}
        refreshControl={
          <RefreshControl refreshing={isRefreshing} onRefresh={handleRefresh} />
        }
      >
        {/* Avatar Section */}
        <View style={styles.avatarSection}>
          <TouchableOpacity onPress={handlePickAvatar} disabled={!isEditing}>
            <View style={styles.avatarContainer}>
              {avatar ? (
                <Image source={{ uri: avatar }} style={styles.avatar} />
              ) : (
                <View style={styles.avatarPlaceholder}>
                  <Text style={styles.avatarInitials}>{initials}</Text>
                </View>
              )}
              {isEditing && (
                <View style={styles.avatarEditBadge}>
                  <Ionicons name="camera" size={14} color={colors.white} />
                </View>
              )}
            </View>
          </TouchableOpacity>
          {!isEditing && (
            <>
              <Text style={styles.userName}>{displayName}</Text>
              <Text style={styles.userEmail}>{formData.email}</Text>
            </>
          )}
        </View>

        {/* Edit Form / Display Info */}
        <Card style={styles.infoCard}>
          {isEditing ? (
            <>
              <Input
                label="First Name"
                value={formData.firstName}
                onChangeText={(v) => setFormData({ ...formData, firstName: v })}
                leftIcon="person-outline"
              />
              <Input
                label="Last Name"
                value={formData.lastName}
                onChangeText={(v) => setFormData({ ...formData, lastName: v })}
                leftIcon="person-outline"
              />
              <Input
                label="Email"
                value={formData.email}
                editable={false}
                leftIcon="mail-outline"
              />
              <Input
                label="Phone"
                value={formData.phone}
                onChangeText={(v) => setFormData({ ...formData, phone: v })}
                keyboardType="phone-pad"
                leftIcon="call-outline"
              />
              <View style={styles.editActions}>
                <Button
                  title="Cancel"
                  variant="outline"
                  onPress={() => {
                    setIsEditing(false);
                    // Reset form to original values
                    if (user) {
                      setFormData({
                        firstName: user.firstName || '',
                        lastName: user.lastName || '',
                        email: user.email || '',
                        phone: user.phone || '',
                      });
                    }
                  }}
                  style={styles.cancelButton}
                />
                <Button
                  title="Save"
                  onPress={handleSave}
                  loading={isSaving}
                  style={styles.saveButton}
                />
              </View>
            </>
          ) : (
            <>
              <InfoRow icon="person-outline" label="First Name" value={formData.firstName || 'Not set'} />
              <InfoRow icon="person-outline" label="Last Name" value={formData.lastName || 'Not set'} />
              <InfoRow icon="mail-outline" label="Email" value={formData.email} />
              <InfoRow icon="call-outline" label="Phone" value={formData.phone || 'Not set'} />
              <Button
                title="Edit Profile"
                variant="outline"
                onPress={() => setIsEditing(true)}
                fullWidth
                style={styles.editButton}
              />
            </>
          )}
        </Card>

        {/* Property Info */}
        {householdInfo && (
          <Card style={styles.propertyCard}>
            <View style={styles.propertyHeader}>
              <View style={styles.propertyIcon}>
                <Ionicons name="home" size={24} color={colors.haven.purple[500]} />
              </View>
              <View style={styles.propertyInfo}>
                <Text style={styles.propertyName}>{householdInfo.name}</Text>
                {householdInfo.propertyAddress && (
                  <Text style={styles.propertyAddress}>{householdInfo.propertyAddress}</Text>
                )}
                <View style={styles.subscriptionBadge}>
                  <Text style={styles.subscriptionText}>
                    {householdInfo.subscriptionPlan} Plan
                  </Text>
                </View>
              </View>
            </View>
          </Card>
        )}

        {/* Account Stats */}
        <Card style={styles.statsCard}>
          <Text style={styles.statsTitle}>Account</Text>
          <View style={styles.statsRow}>
            <View style={styles.statItem}>
              <Text style={styles.statValue}>{user?.role || 'Member'}</Text>
              <Text style={styles.statLabel}>Role</Text>
            </View>
            <View style={styles.statDivider} />
            <View style={styles.statItem}>
              <Text style={styles.statValue}>
                {householdInfo?.subscriptionStatus || 'N/A'}
              </Text>
              <Text style={styles.statLabel}>Status</Text>
            </View>
          </View>
        </Card>

        {/* Sign Out */}
        <TouchableOpacity style={styles.signOutButton} onPress={handleSignOut}>
          <Ionicons name="log-out-outline" size={20} color={colors.status.error} />
          <Text style={styles.signOutText}>Sign Out</Text>
        </TouchableOpacity>
      </ScrollView>
    </View>
  );
}

function InfoRow({ icon, label, value }: { icon: string; label: string; value: string }) {
  return (
    <View style={infoStyles.row}>
      <Ionicons name={icon as any} size={20} color={colors.haven.purple[500]} />
      <View style={infoStyles.content}>
        <Text style={infoStyles.label}>{label}</Text>
        <Text style={infoStyles.value}>{value}</Text>
      </View>
    </View>
  );
}

const infoStyles = StyleSheet.create({
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: spacing[3],
    borderBottomWidth: 1,
    borderBottomColor: colors.border.light,
  },
  content: {
    marginLeft: spacing[3],
    flex: 1,
  },
  label: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
  },
  value: {
    fontSize: typography.fontSizes.base,
    color: colors.text.primary,
    marginTop: 2,
  },
});

const styles = StyleSheet.create({
  fullContainer: {
    flex: 1,
    backgroundColor: colors.haven.purple[900],
  },
  scrollContainer: {
    flex: 1,
    backgroundColor: colors.background.secondary,
  },
  container: {
    flex: 1,
    backgroundColor: colors.background.secondary,
  },
  scrollContent: {
    padding: spacing[4],
  },
  avatarSection: {
    alignItems: 'center',
    marginBottom: spacing[6],
  },
  avatarContainer: {
    position: 'relative',
  },
  avatar: {
    width: 100,
    height: 100,
    borderRadius: 50,
  },
  avatarPlaceholder: {
    width: 100,
    height: 100,
    borderRadius: 50,
    backgroundColor: colors.haven.purple[100],
    alignItems: 'center',
    justifyContent: 'center',
  },
  avatarInitials: {
    fontSize: typography.fontSizes['2xl'],
    fontWeight: typography.fontWeights.bold,
    color: colors.haven.purple[600],
  },
  avatarEditBadge: {
    position: 'absolute',
    bottom: 0,
    right: 0,
    width: 32,
    height: 32,
    borderRadius: 16,
    backgroundColor: colors.haven.purple[500],
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 3,
    borderColor: colors.background.secondary,
  },
  userName: {
    fontSize: typography.fontSizes.xl,
    fontWeight: typography.fontWeights.bold,
    color: colors.text.primary,
    marginTop: spacing[3],
  },
  userEmail: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    marginTop: spacing[1],
  },
  infoCard: {
    padding: spacing[4],
    marginBottom: spacing[4],
  },
  editActions: {
    flexDirection: 'row',
    gap: spacing[3],
    marginTop: spacing[4],
  },
  cancelButton: {
    flex: 1,
  },
  saveButton: {
    flex: 1,
  },
  editButton: {
    marginTop: spacing[4],
  },
  propertyCard: {
    padding: spacing[4],
    marginBottom: spacing[4],
  },
  propertyHeader: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  propertyIcon: {
    width: 48,
    height: 48,
    borderRadius: borderRadius.lg,
    backgroundColor: colors.haven.purple[50],
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: spacing[3],
  },
  propertyInfo: {
    flex: 1,
  },
  propertyName: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
  },
  propertyAddress: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    marginTop: 2,
  },
  subscriptionBadge: {
    marginTop: spacing[2],
    alignSelf: 'flex-start',
    backgroundColor: colors.haven.purple[50],
    paddingHorizontal: spacing[2],
    paddingVertical: 2,
    borderRadius: borderRadius.sm,
  },
  subscriptionText: {
    fontSize: typography.fontSizes.xs,
    color: colors.haven.purple[600],
    fontWeight: typography.fontWeights.medium,
  },
  statsCard: {
    padding: spacing[4],
    marginBottom: spacing[4],
  },
  statsTitle: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.secondary,
    marginBottom: spacing[3],
  },
  statsRow: {
    flexDirection: 'row',
  },
  statItem: {
    flex: 1,
    alignItems: 'center',
  },
  statDivider: {
    width: 1,
    backgroundColor: colors.border.light,
    marginHorizontal: spacing[4],
  },
  statValue: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
    textTransform: 'capitalize',
  },
  statLabel: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
    marginTop: 2,
  },
  signOutButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: spacing[2],
    padding: spacing[4],
    marginTop: spacing[2],
  },
  signOutText: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.medium,
    color: colors.status.error,
  },
});

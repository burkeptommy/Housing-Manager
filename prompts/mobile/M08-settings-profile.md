# Haven Mobile: M08 - Settings & Profile

**Created:** December 29, 2024  
**Priority:** P1 - Required for user management  
**Estimated Time:** 3-4 hours  
**Dependencies:** M01-M07 complete

---

## Overview

This prompt implements user settings and profile management:
1. Profile editing (name, email, phone, avatar)
2. Notification preferences
3. Subscription management
4. Connected banks management
5. Security settings (biometrics, password)
6. Sign out / Delete account

---

## PHASE 1: Create Profile Screen

### Task 1.1: Create Profile Screen

Create `apps/mobile/app/(tabs)/profile.tsx`:

```typescript
import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Alert,
  Image,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import * as ImagePicker from 'expo-image-picker';
import { useAuth } from '../../src/contexts/auth-context';
import { Card, Button, Input, LoadingSpinner } from '../../src/components';
import { colors, typography, spacing, borderRadius } from '../../src/lib/theme';

export default function ProfileScreen() {
  const { user, logout } = useAuth();
  const [isEditing, setIsEditing] = useState(false);
  const [isSaving, setIsSaving] = useState(false);
  const [avatar, setAvatar] = useState<string | null>(null);
  
  const [formData, setFormData] = useState({
    displayName: user?.displayName || 'Bob Morrison',
    email: user?.email || 'bob@example.com',
    phone: '(203) 555-0101',
  });

  const handlePickAvatar = async () => {
    const result = await ImagePicker.launchImageLibraryAsync({
      mediaTypes: ImagePicker.MediaTypeOptions.Images,
      allowsEditing: true,
      aspect: [1, 1],
      quality: 0.8,
    });

    if (!result.canceled) {
      setAvatar(result.assets[0].uri);
    }
  };

  const handleSave = async () => {
    setIsSaving(true);
    try {
      // TODO: API call to update profile
      await new Promise(resolve => setTimeout(resolve, 1000));
      setIsEditing(false);
      Alert.alert('Success', 'Profile updated successfully');
    } catch (error) {
      Alert.alert('Error', 'Failed to update profile');
    } finally {
      setIsSaving(false);
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
    <SafeAreaView style={styles.container} edges={['bottom']}>
      <ScrollView contentContainerStyle={styles.scrollContent}>
        {/* Avatar Section */}
        <View style={styles.avatarSection}>
          <TouchableOpacity onPress={handlePickAvatar} disabled={!isEditing}>
            <View style={styles.avatarContainer}>
              {avatar ? (
                <Image source={{ uri: avatar }} style={styles.avatar} />
              ) : (
                <View style={styles.avatarPlaceholder}>
                  <Text style={styles.avatarInitials}>BM</Text>
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
              <Text style={styles.userName}>{formData.displayName}</Text>
              <Text style={styles.userEmail}>{formData.email}</Text>
            </>
          )}
        </View>

        {/* Edit Form / Display Info */}
        <Card style={styles.infoCard}>
          {isEditing ? (
            <>
              <Input
                label="Full Name"
                value={formData.displayName}
                onChangeText={(v) => setFormData({ ...formData, displayName: v })}
                leftIcon="person-outline"
              />
              <Input
                label="Email"
                value={formData.email}
                onChangeText={(v) => setFormData({ ...formData, email: v })}
                keyboardType="email-address"
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
                  onPress={() => setIsEditing(false)}
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
              <InfoRow icon="person-outline" label="Name" value={formData.displayName} />
              <InfoRow icon="mail-outline" label="Email" value={formData.email} />
              <InfoRow icon="call-outline" label="Phone" value={formData.phone} />
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
        <Card style={styles.propertyCard}>
          <View style={styles.propertyHeader}>
            <Ionicons name="home" size={24} color={colors.haven.champagne[500]} />
            <View style={styles.propertyInfo}>
              <Text style={styles.propertyName}>Inspiration Farm</Text>
              <Text style={styles.propertyAddress}>38 Bedford Road, Greenwich, CT</Text>
            </View>
          </View>
        </Card>

        {/* Sign Out */}
        <TouchableOpacity style={styles.signOutButton} onPress={handleSignOut}>
          <Ionicons name="log-out-outline" size={20} color={colors.status.error} />
          <Text style={styles.signOutText}>Sign Out</Text>
        </TouchableOpacity>
      </ScrollView>
    </SafeAreaView>
  );
}

function InfoRow({ icon, label, value }: { icon: string; label: string; value: string }) {
  return (
    <View style={infoStyles.row}>
      <Ionicons name={icon as any} size={20} color={colors.haven.champagne[500]} />
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
    backgroundColor: colors.haven.navy[100],
    alignItems: 'center',
    justifyContent: 'center',
  },
  avatarInitials: {
    fontSize: typography.fontSizes['2xl'],
    fontWeight: typography.fontWeights.bold,
    color: colors.haven.navy[600],
  },
  avatarEditBadge: {
    position: 'absolute',
    bottom: 0,
    right: 0,
    width: 32,
    height: 32,
    borderRadius: 16,
    backgroundColor: colors.haven.champagne[500],
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
    marginBottom: spacing[6],
  },
  propertyHeader: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  propertyInfo: {
    marginLeft: spacing[3],
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
  signOutButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: spacing[2],
    padding: spacing[4],
  },
  signOutText: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.medium,
    color: colors.status.error,
  },
});
```

---

## PHASE 2: Create Settings Screen

### Task 2.1: Create Settings Screen

Create `apps/mobile/app/(tabs)/settings.tsx`:

```typescript
import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Switch,
  Alert,
  Linking,
} from 'react-native';
import { useRouter } from 'expo-router';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { useAuth } from '../../src/contexts/auth-context';
import { useNotifications } from '../../src/contexts/notifications-context';
import { usePurchases } from '../../src/contexts/purchases-context';
import { enableBiometric, disableBiometric, getBiometricName } from '../../src/lib/biometric-auth';
import { Card, Badge } from '../../src/components';
import { colors, typography, spacing, borderRadius } from '../../src/lib/theme';
import { TIER_INFO } from '../../src/lib/purchases';

export default function SettingsScreen() {
  const router = useRouter();
  const { user, biometricStatus, refreshBiometricStatus, logout } = useAuth();
  const { isEnabled: notificationsEnabled, requestPermissions } = useNotifications();
  const { currentTier } = usePurchases();
  
  const [biometricEnabled, setBiometricEnabled] = useState(biometricStatus?.isEnabled || false);

  const handleBiometricToggle = async (value: boolean) => {
    if (value) {
      const success = await enableBiometric(user?.email || '');
      if (success) {
        setBiometricEnabled(true);
        await refreshBiometricStatus();
      }
    } else {
      await disableBiometric();
      setBiometricEnabled(false);
      await refreshBiometricStatus();
    }
  };

  const handleNotificationToggle = async () => {
    if (!notificationsEnabled) {
      const granted = await requestPermissions();
      if (!granted) {
        Alert.alert(
          'Notifications Disabled',
          'Please enable notifications in Settings to receive updates from Haven.',
          [
            { text: 'Cancel', style: 'cancel' },
            { text: 'Open Settings', onPress: () => Linking.openSettings() },
          ]
        );
      }
    }
  };

  const handleDeleteAccount = () => {
    Alert.alert(
      'Delete Account',
      'This will permanently delete your account and all data. This action cannot be undone.',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Delete',
          style: 'destructive',
          onPress: () => {
            Alert.alert(
              'Confirm Delete',
              'Type DELETE to confirm',
              [
                { text: 'Cancel', style: 'cancel' },
                {
                  text: 'Confirm',
                  style: 'destructive',
                  onPress: async () => {
                    // TODO: API call to delete account
                    await logout();
                  },
                },
              ]
            );
          },
        },
      ]
    );
  };

  const tierInfo = currentTier ? TIER_INFO[currentTier] : null;

  return (
    <SafeAreaView style={styles.container} edges={['bottom']}>
      <ScrollView contentContainerStyle={styles.scrollContent}>
        {/* Subscription */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Subscription</Text>
          <Card style={styles.subscriptionCard}>
            <View style={styles.subscriptionHeader}>
              <View>
                <Text style={styles.subscriptionTier}>
                  {tierInfo?.name || 'Free'} Plan
                </Text>
                <Text style={styles.subscriptionPrice}>
                  {tierInfo ? `$${tierInfo.monthlyPrice}/month` : 'No active subscription'}
                </Text>
              </View>
              <Badge 
                label={currentTier ? 'Active' : 'Inactive'} 
                variant={currentTier ? 'success' : 'outline'} 
              />
            </View>
            <TouchableOpacity 
              style={styles.manageButton}
              onPress={() => router.push('/(tabs)/subscription')}
            >
              <Text style={styles.manageButtonText}>Manage Subscription</Text>
              <Ionicons name="chevron-forward" size={20} color={colors.haven.champagne[500]} />
            </TouchableOpacity>
          </Card>
        </View>

        {/* Notifications */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Notifications</Text>
          <Card style={styles.settingsCard}>
            <SettingRow
              icon="notifications-outline"
              title="Push Notifications"
              subtitle={notificationsEnabled ? 'Enabled' : 'Disabled'}
              trailing={
                <Switch
                  value={notificationsEnabled}
                  onValueChange={handleNotificationToggle}
                  trackColor={{ false: colors.gray[300], true: colors.haven.champagne[500] }}
                />
              }
            />
            <SettingRow
              icon="mail-outline"
              title="Email Notifications"
              subtitle="Weekly summaries"
              onPress={() => {}}
            />
          </Card>
        </View>

        {/* Security */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Security</Text>
          <Card style={styles.settingsCard}>
            {biometricStatus?.isAvailable && (
              <SettingRow
                icon={biometricStatus.biometricType === 'facial' ? 'scan-outline' : 'finger-print-outline'}
                title={getBiometricName(biometricStatus.biometricType)}
                subtitle="Quick login"
                trailing={
                  <Switch
                    value={biometricEnabled}
                    onValueChange={handleBiometricToggle}
                    trackColor={{ false: colors.gray[300], true: colors.haven.champagne[500] }}
                  />
                }
              />
            )}
            <SettingRow
              icon="lock-closed-outline"
              title="Change Password"
              onPress={() => router.push('/(auth)/forgot-password')}
            />
          </Card>
        </View>

        {/* Connected Services */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Connected Services</Text>
          <Card style={styles.settingsCard}>
            <SettingRow
              icon="card-outline"
              title="Connected Banks"
              subtitle="Manage linked accounts"
              onPress={() => router.push('/(tabs)/money/banks')}
            />
          </Card>
        </View>

        {/* About */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>About</Text>
          <Card style={styles.settingsCard}>
            <SettingRow
              icon="document-text-outline"
              title="Terms of Service"
              onPress={() => Linking.openURL('https://havenhome.dev/terms')}
            />
            <SettingRow
              icon="shield-checkmark-outline"
              title="Privacy Policy"
              onPress={() => Linking.openURL('https://havenhome.dev/privacy')}
            />
            <SettingRow
              icon="help-circle-outline"
              title="Help & Support"
              onPress={() => Linking.openURL('https://havenhome.dev/support')}
            />
            <SettingRow
              icon="information-circle-outline"
              title="App Version"
              subtitle="1.0.0 (1)"
              disabled
            />
          </Card>
        </View>

        {/* Danger Zone */}
        <View style={styles.section}>
          <Text style={[styles.sectionTitle, { color: colors.status.error }]}>Danger Zone</Text>
          <Card style={styles.settingsCard}>
            <SettingRow
              icon="trash-outline"
              title="Delete Account"
              subtitle="Permanently delete your account"
              titleStyle={{ color: colors.status.error }}
              onPress={handleDeleteAccount}
            />
          </Card>
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

interface SettingRowProps {
  icon: string;
  title: string;
  subtitle?: string;
  trailing?: React.ReactNode;
  onPress?: () => void;
  disabled?: boolean;
  titleStyle?: object;
}

function SettingRow({ icon, title, subtitle, trailing, onPress, disabled, titleStyle }: SettingRowProps) {
  return (
    <TouchableOpacity
      style={styles.settingRow}
      onPress={onPress}
      disabled={disabled || !onPress}
    >
      <View style={styles.settingIcon}>
        <Ionicons name={icon as any} size={22} color={colors.haven.champagne[500]} />
      </View>
      <View style={styles.settingContent}>
        <Text style={[styles.settingTitle, titleStyle]}>{title}</Text>
        {subtitle && <Text style={styles.settingSubtitle}>{subtitle}</Text>}
      </View>
      {trailing || (onPress && !disabled && (
        <Ionicons name="chevron-forward" size={20} color={colors.text.tertiary} />
      ))}
    </TouchableOpacity>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background.secondary,
  },
  scrollContent: {
    padding: spacing[4],
  },
  section: {
    marginBottom: spacing[6],
  },
  sectionTitle: {
    fontSize: typography.fontSizes.xs,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.tertiary,
    textTransform: 'uppercase',
    letterSpacing: 0.5,
    marginBottom: spacing[2],
    marginLeft: spacing[4],
  },
  subscriptionCard: {
    padding: spacing[4],
  },
  subscriptionHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    marginBottom: spacing[3],
  },
  subscriptionTier: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
  },
  subscriptionPrice: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    marginTop: 2,
  },
  manageButton: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingTop: spacing[3],
    borderTopWidth: 1,
    borderTopColor: colors.border.light,
  },
  manageButtonText: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.haven.champagne[500],
  },
  settingsCard: {
    overflow: 'hidden',
  },
  settingRow: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: spacing[4],
    borderBottomWidth: 1,
    borderBottomColor: colors.border.light,
  },
  settingIcon: {
    width: 36,
    height: 36,
    borderRadius: borderRadius.lg,
    backgroundColor: colors.haven.champagne[50],
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: spacing[3],
  },
  settingContent: {
    flex: 1,
  },
  settingTitle: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.primary,
  },
  settingSubtitle: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    marginTop: 2,
  },
});
```

---

## PHASE 3: Verification

### Task 3.1: Test Checklist

- [ ] Profile screen displays user info
- [ ] Can edit profile and save changes
- [ ] Avatar picker works
- [ ] Settings shows subscription status
- [ ] Biometric toggle works
- [ ] Notification toggle works
- [ ] Links open correctly (Terms, Privacy, Help)
- [ ] Sign out works
- [ ] Delete account confirmation flow works
- [ ] No TypeScript errors (`pnpm typecheck`)

### Task 3.2: Test Commands

```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/mobile
pnpm typecheck
pnpm start --ios
```

---

## Summary

After completing this prompt:
1. ✅ Profile screen with edit capability
2. ✅ Avatar upload
3. ✅ Settings with all preferences
4. ✅ Subscription management link
5. ✅ Biometric toggle
6. ✅ Notification preferences
7. ✅ Security settings
8. ✅ Sign out / Delete account

**Next Prompt:** M09 - Polish & TestFlight

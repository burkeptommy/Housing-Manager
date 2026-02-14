import React, { useState, useEffect } from 'react';
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
import { Ionicons } from '@expo/vector-icons';
import { useAuth } from '../../../src/contexts/auth-context';
import {
  enableBiometric,
  disableBiometric,
  getBiometricName,
} from '../../../src/lib/biometric-auth';
import { Card, Badge, AppHeader } from '../../../src/components';
import { colors, typography, spacing, borderRadius } from '../../../src/lib/theme';
import { API_BASE_URL } from '../../../src/lib/api';
import { getIdToken } from '../../../src/lib/firebase';

// Safe context imports with fallbacks
let useNotifications: () => { isEnabled: boolean; requestPermissions: () => Promise<boolean> };
let usePurchases: () => { currentTier: string | null };
let TIER_INFO: Record<string, { name: string; monthlyPrice: number }>;

try {
  useNotifications = require('../../src/contexts/notifications-context').useNotifications;
} catch {
  useNotifications = () => ({ isEnabled: false, requestPermissions: async () => false });
}

try {
  usePurchases = require('../../src/contexts/purchases-context').usePurchases;
} catch {
  usePurchases = () => ({ currentTier: null });
}

try {
  TIER_INFO = require('../../src/lib/purchases').TIER_INFO;
} catch {
  TIER_INFO = {
    FREE: { name: 'Free', monthlyPrice: 0 },
    BASIC: { name: 'Basic', monthlyPrice: 9.99 },
    PREMIUM: { name: 'Premium', monthlyPrice: 19.99 },
  };
}

export default function SettingsScreen() {
  const router = useRouter();
  const { user, biometricStatus, refreshBiometricStatus, logout, householdInfo } = useAuth();

  // Safe context usage
  const notificationsContext = useNotifications?.() || { isEnabled: false, requestPermissions: async () => false };
  const purchasesContext = usePurchases?.() || { currentTier: null };
  const notificationsEnabled = notificationsContext.isEnabled;
  const requestPermissions = notificationsContext.requestPermissions;
  const currentTier = purchasesContext.currentTier;

  const [biometricEnabled, setBiometricEnabled] = useState(biometricStatus?.isEnabled || false);

  // Sync biometric state with status
  useEffect(() => {
    if (biometricStatus) {
      setBiometricEnabled(biometricStatus.isEnabled);
    }
  }, [biometricStatus]);

  // Check biometric status on mount
  useEffect(() => {
    refreshBiometricStatus();
  }, [refreshBiometricStatus]);

  const handleBiometricToggle = async (value: boolean) => {
    if (value) {
      const success = await enableBiometric(user?.email || '');
      if (success) {
        setBiometricEnabled(true);
        await refreshBiometricStatus();
        Alert.alert('Success', `${getBiometricName(biometricStatus?.biometricType || 'none')} enabled`);
      } else {
        Alert.alert('Error', 'Failed to enable biometric authentication');
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
              'Are you absolutely sure? This cannot be undone.',
              [
                { text: 'Cancel', style: 'cancel' },
                {
                  text: 'Delete Forever',
                  style: 'destructive',
                  onPress: async () => {
                    try {
                      const token = await getIdToken(true);
                      if (token) {
                        // TODO: Backend endpoint needed - DELETE /api/users/account
                        // This should delete the user account and all associated data
                        await fetch(`${API_BASE_URL}/users/account`, {
                          method: 'DELETE',
                          headers: {
                            Authorization: `Bearer ${token}`,
                          },
                        });
                      }
                      await logout();
                    } catch (error) {
                      console.error('Delete account error:', error);
                      await logout();
                    }
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
    <View style={styles.fullContainer}>
      <AppHeader title="Settings" showBack onBackPress={() => router.navigate('/more')} />
      <ScrollView style={styles.scrollContainer} contentContainerStyle={styles.scrollContent}>
        {/* Subscription */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Subscription</Text>
          <Card style={styles.subscriptionCard}>
            <View style={styles.subscriptionHeader}>
              <View>
                <Text style={styles.subscriptionTier}>
                  {tierInfo?.name || householdInfo?.subscriptionPlan || 'Free'} Plan
                </Text>
                <Text style={styles.subscriptionPrice}>
                  {tierInfo ? `$${tierInfo.monthlyPrice}/month` : 'No active subscription'}
                </Text>
              </View>
              <Badge
                label={householdInfo?.subscriptionStatus || (currentTier ? 'Active' : 'Inactive')}
                variant={currentTier || householdInfo?.subscriptionStatus === 'ACTIVE' ? 'success' : 'default'}
              />
            </View>
            <TouchableOpacity
              style={styles.manageButton}
              onPress={() => {
                // TODO: Navigate to subscription management screen
                Alert.alert('Coming Soon', 'Subscription management will be available soon.');
              }}
            >
              <Text style={styles.manageButtonText}>Manage Subscription</Text>
              <Ionicons name="chevron-forward" size={20} color={colors.haven.purple[500]} />
            </TouchableOpacity>
          </Card>
        </View>

        {/* Refer a Friend */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Earn Rewards</Text>
          <Card style={styles.settingsCard}>
            <SettingRow
              icon="gift-outline"
              title="Refer a Friend"
              subtitle="Earn $50 for each referral"
              onPress={() => router.push('/(tabs)/settings/referrals' as any)}
            />
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
                  trackColor={{ false: colors.gray[300], true: colors.haven.purple[500] }}
                />
              }
            />
            <SettingRow
              icon="mail-outline"
              title="Email Notifications"
              subtitle="Weekly summaries"
              onPress={() => {
                Alert.alert('Coming Soon', 'Email notification preferences will be available soon.');
              }}
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
                    trackColor={{ false: colors.gray[300], true: colors.haven.purple[500] }}
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
              icon="mail-outline"
              title="Alfred Email Assistant"
              subtitle="CC Alfred to auto-organize emails"
              onPress={() => router.push('/(tabs)/settings/alfred-email' as any)}
            />
            <SettingRow
              icon="calendar-outline"
              title="Calendar Sync"
              subtitle="Connect Google or Apple calendars"
              onPress={() => router.push('/(tabs)/settings/calendars' as any)}
            />
            <SettingRow
              icon="card-outline"
              title="Connected Banks"
              subtitle="Manage linked accounts"
              onPress={() => {
                // TODO: Navigate to bank management
                Alert.alert('Coming Soon', 'Bank management will be available soon.');
              }}
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
              iconColor={colors.status.error}
              onPress={handleDeleteAccount}
            />
          </Card>
        </View>
      </ScrollView>
    </View>
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
  iconColor?: string;
}

function SettingRow({
  icon,
  title,
  subtitle,
  trailing,
  onPress,
  disabled,
  titleStyle,
  iconColor,
}: SettingRowProps) {
  return (
    <TouchableOpacity
      style={styles.settingRow}
      onPress={onPress}
      disabled={disabled || !onPress}
    >
      <View style={[styles.settingIcon, iconColor && { backgroundColor: `${iconColor}10` }]}>
        <Ionicons
          name={icon as any}
          size={22}
          color={iconColor || colors.haven.purple[500]}
        />
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
  section: {
    marginBottom: spacing[6],
  },
  sectionTitle: {
    fontSize: typography.fontSizes.xs,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.tertiary,
    textTransform: 'uppercase',
    letterSpacing: 1.5,  // Wide for uppercase labels
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
    color: colors.haven.purple[500],
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
    backgroundColor: colors.haven.purple[50],
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

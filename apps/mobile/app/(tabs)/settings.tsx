import { useState } from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  ScrollView,
  Switch,
  Alert,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useAuth } from '../../src/contexts/auth-context';
import { colors, spacing, typography, borderRadius, shadows } from '../../src/lib/theme';

interface NotificationSettings {
  pushEnabled: boolean;
  emailEnabled: boolean;
  requestUpdates: boolean;
  chatMessages: boolean;
  maintenanceReminders: boolean;
  marketingEmails: boolean;
}

export default function SettingsScreen() {
  const { user, currentHousehold, logout } = useAuth();
  const [notifications, setNotifications] = useState<NotificationSettings>({
    pushEnabled: true,
    emailEnabled: true,
    requestUpdates: true,
    chatMessages: true,
    maintenanceReminders: true,
    marketingEmails: false,
  });

  const handleLogout = () => {
    Alert.alert('Sign Out', 'Are you sure you want to sign out?', [
      { text: 'Cancel', style: 'cancel' },
      { text: 'Sign Out', style: 'destructive', onPress: logout },
    ]);
  };

  const toggleNotification = (key: keyof NotificationSettings) => {
    setNotifications((prev) => ({
      ...prev,
      [key]: !prev[key],
    }));
    // TODO: Save to API
  };

  return (
    <SafeAreaView style={styles.container} edges={['bottom']}>
      <ScrollView contentContainerStyle={styles.scrollContent}>
        {/* Profile Section */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Account</Text>
          <View style={styles.card}>
            <View style={styles.profileRow}>
              <View style={styles.avatar}>
                <Text style={styles.avatarText}>
                  {user?.firstName?.[0]}
                  {user?.lastName?.[0]}
                </Text>
              </View>
              <View style={styles.profileInfo}>
                <Text style={styles.profileName}>
                  {user?.firstName} {user?.lastName}
                </Text>
                <Text style={styles.profileEmail}>{user?.email}</Text>
              </View>
            </View>
          </View>
        </View>

        {/* Household Section */}
        {currentHousehold && (
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Current Home</Text>
            <View style={styles.card}>
              <View style={styles.row}>
                <View style={styles.homeIcon}>
                  <Text style={styles.homeIconText}>🏠</Text>
                </View>
                <View style={styles.homeInfo}>
                  <Text style={styles.homeName}>{currentHousehold.name}</Text>
                  {currentHousehold.homeProfile && (
                    <Text style={styles.homeAddress}>
                      {currentHousehold.homeProfile.addressLine1},{' '}
                      {currentHousehold.homeProfile.city}
                    </Text>
                  )}
                </View>
              </View>
            </View>
          </View>
        )}

        {/* Notification Settings */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Notifications</Text>
          <View style={styles.card}>
            <View style={styles.settingRow}>
              <View style={styles.settingInfo}>
                <Text style={styles.settingLabel}>Push Notifications</Text>
                <Text style={styles.settingDescription}>
                  Receive notifications on your device
                </Text>
              </View>
              <Switch
                value={notifications.pushEnabled}
                onValueChange={() => toggleNotification('pushEnabled')}
                trackColor={{ false: colors.slate[200], true: colors.primary[200] }}
                thumbColor={notifications.pushEnabled ? colors.primary[600] : colors.slate[400]}
              />
            </View>

            <View style={styles.divider} />

            <View style={styles.settingRow}>
              <View style={styles.settingInfo}>
                <Text style={styles.settingLabel}>Email Notifications</Text>
                <Text style={styles.settingDescription}>
                  Receive updates via email
                </Text>
              </View>
              <Switch
                value={notifications.emailEnabled}
                onValueChange={() => toggleNotification('emailEnabled')}
                trackColor={{ false: colors.slate[200], true: colors.primary[200] }}
                thumbColor={notifications.emailEnabled ? colors.primary[600] : colors.slate[400]}
              />
            </View>
          </View>
        </View>

        {/* Notification Types */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Notification Preferences</Text>
          <View style={styles.card}>
            <View style={styles.settingRow}>
              <View style={styles.settingInfo}>
                <Text style={styles.settingLabel}>Service Request Updates</Text>
                <Text style={styles.settingDescription}>
                  Status changes, vendor assignments
                </Text>
              </View>
              <Switch
                value={notifications.requestUpdates}
                onValueChange={() => toggleNotification('requestUpdates')}
                trackColor={{ false: colors.slate[200], true: colors.primary[200] }}
                thumbColor={notifications.requestUpdates ? colors.primary[600] : colors.slate[400]}
              />
            </View>

            <View style={styles.divider} />

            <View style={styles.settingRow}>
              <View style={styles.settingInfo}>
                <Text style={styles.settingLabel}>Chat Messages</Text>
                <Text style={styles.settingDescription}>
                  New messages from your household
                </Text>
              </View>
              <Switch
                value={notifications.chatMessages}
                onValueChange={() => toggleNotification('chatMessages')}
                trackColor={{ false: colors.slate[200], true: colors.primary[200] }}
                thumbColor={notifications.chatMessages ? colors.primary[600] : colors.slate[400]}
              />
            </View>

            <View style={styles.divider} />

            <View style={styles.settingRow}>
              <View style={styles.settingInfo}>
                <Text style={styles.settingLabel}>Maintenance Reminders</Text>
                <Text style={styles.settingDescription}>
                  Scheduled maintenance notifications
                </Text>
              </View>
              <Switch
                value={notifications.maintenanceReminders}
                onValueChange={() => toggleNotification('maintenanceReminders')}
                trackColor={{ false: colors.slate[200], true: colors.primary[200] }}
                thumbColor={notifications.maintenanceReminders ? colors.primary[600] : colors.slate[400]}
              />
            </View>

            <View style={styles.divider} />

            <View style={styles.settingRow}>
              <View style={styles.settingInfo}>
                <Text style={styles.settingLabel}>Marketing Emails</Text>
                <Text style={styles.settingDescription}>
                  Tips, news, and special offers
                </Text>
              </View>
              <Switch
                value={notifications.marketingEmails}
                onValueChange={() => toggleNotification('marketingEmails')}
                trackColor={{ false: colors.slate[200], true: colors.primary[200] }}
                thumbColor={notifications.marketingEmails ? colors.primary[600] : colors.slate[400]}
              />
            </View>
          </View>
        </View>

        {/* App Info */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>About</Text>
          <View style={styles.card}>
            <View style={styles.infoRow}>
              <Text style={styles.infoLabel}>Version</Text>
              <Text style={styles.infoValue}>1.0.0</Text>
            </View>
            <View style={styles.divider} />
            <TouchableOpacity style={styles.linkRow}>
              <Text style={styles.linkText}>Privacy Policy</Text>
              <Text style={styles.linkArrow}>›</Text>
            </TouchableOpacity>
            <View style={styles.divider} />
            <TouchableOpacity style={styles.linkRow}>
              <Text style={styles.linkText}>Terms of Service</Text>
              <Text style={styles.linkArrow}>›</Text>
            </TouchableOpacity>
            <View style={styles.divider} />
            <TouchableOpacity style={styles.linkRow}>
              <Text style={styles.linkText}>Help & Support</Text>
              <Text style={styles.linkArrow}>›</Text>
            </TouchableOpacity>
          </View>
        </View>

        {/* Sign Out Button */}
        <TouchableOpacity style={styles.logoutButton} onPress={handleLogout}>
          <Text style={styles.logoutText}>Sign Out</Text>
        </TouchableOpacity>

        <View style={styles.footer}>
          <Text style={styles.footerText}>Haven Home Manager</Text>
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.slate[50],
  },
  scrollContent: {
    padding: spacing[4],
  },
  section: {
    marginBottom: spacing[6],
  },
  sectionTitle: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
    color: colors.slate[500],
    textTransform: 'uppercase',
    letterSpacing: 0.5,
    marginBottom: spacing[2],
    marginLeft: spacing[1],
  },
  card: {
    backgroundColor: colors.white,
    borderRadius: borderRadius.xl,
    overflow: 'hidden',
    ...shadows.sm,
  },
  profileRow: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: spacing[4],
  },
  avatar: {
    width: 56,
    height: 56,
    borderRadius: 28,
    backgroundColor: colors.primary[600],
    alignItems: 'center',
    justifyContent: 'center',
  },
  avatarText: {
    color: colors.white,
    fontSize: typography.fontSizes.xl,
    fontWeight: typography.fontWeights.semibold,
  },
  profileInfo: {
    marginLeft: spacing[4],
    flex: 1,
  },
  profileName: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.semibold,
    color: colors.slate[900],
  },
  profileEmail: {
    fontSize: typography.fontSizes.sm,
    color: colors.slate[500],
    marginTop: spacing[1],
  },
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: spacing[4],
  },
  homeIcon: {
    width: 48,
    height: 48,
    borderRadius: borderRadius.lg,
    backgroundColor: colors.accent[100],
    alignItems: 'center',
    justifyContent: 'center',
  },
  homeIconText: {
    fontSize: 24,
  },
  homeInfo: {
    marginLeft: spacing[3],
    flex: 1,
  },
  homeName: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.slate[900],
  },
  homeAddress: {
    fontSize: typography.fontSizes.sm,
    color: colors.slate[500],
    marginTop: 2,
  },
  settingRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    padding: spacing[4],
  },
  settingInfo: {
    flex: 1,
    marginRight: spacing[4],
  },
  settingLabel: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.medium,
    color: colors.slate[900],
  },
  settingDescription: {
    fontSize: typography.fontSizes.sm,
    color: colors.slate[500],
    marginTop: 2,
  },
  divider: {
    height: 1,
    backgroundColor: colors.slate[100],
    marginHorizontal: spacing[4],
  },
  infoRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: spacing[4],
  },
  infoLabel: {
    fontSize: typography.fontSizes.base,
    color: colors.slate[900],
  },
  infoValue: {
    fontSize: typography.fontSizes.base,
    color: colors.slate[500],
  },
  linkRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: spacing[4],
  },
  linkText: {
    fontSize: typography.fontSizes.base,
    color: colors.slate[900],
  },
  linkArrow: {
    fontSize: typography.fontSizes.xl,
    color: colors.slate[400],
  },
  logoutButton: {
    backgroundColor: colors.white,
    borderRadius: borderRadius.xl,
    padding: spacing[4],
    alignItems: 'center',
    borderWidth: 1,
    borderColor: colors.error,
    marginBottom: spacing[6],
  },
  logoutText: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.error,
  },
  footer: {
    alignItems: 'center',
    paddingVertical: spacing[4],
  },
  footerText: {
    fontSize: typography.fontSizes.sm,
    color: colors.slate[400],
  },
});

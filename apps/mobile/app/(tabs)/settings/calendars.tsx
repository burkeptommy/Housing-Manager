import React, { useState, useEffect, useCallback } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  ScrollView,
  Alert,
  ActivityIndicator,
  Linking,
  Platform,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { useRouter } from 'expo-router';
import { ScreenContainer } from '../../../src/components';
import { useGoogleCalendarAuth } from '../../../src/lib/google-calendar';
import { getDeviceCalendars, requestCalendarPermission } from '../../../src/lib/ios-calendar';
import { colors, spacing, typography, borderRadius } from '../../../src/lib/theme';
import { getIdToken } from '../../../src/lib/firebase';
import { API_BASE_URL } from '../../../src/lib/api';

interface CalendarProvider {
  id: string;
  name: string;
  icon: keyof typeof Ionicons.glyphMap;
  color: string;
  connected: boolean;
  accountEmail?: string;
  lastSyncAt?: string;
}

export default function CalendarSettingsScreen() {
  const router = useRouter();
  const [providers, setProviders] = useState<CalendarProvider[]>([
    { id: 'google', name: 'Google Calendar', icon: 'logo-google', color: '#4285f4', connected: false },
    { id: 'apple', name: 'iOS Calendar', icon: 'logo-apple', color: '#000000', connected: false },
  ]);
  const [isLoading, setIsLoading] = useState(true);
  const [connectingProvider, setConnectingProvider] = useState<string | null>(null);

  const googleAuth = useGoogleCalendarAuth();

  // Fetch existing connections on load
  const fetchConnections = useCallback(async () => {
    try {
      const token = await getIdToken();
      if (!token) return;

      const response = await fetch(`${API_BASE_URL}/calendars/connections`, {
        headers: { Authorization: `Bearer ${token}` },
      });

      if (response.ok) {
        const connections = await response.json();

        setProviders(prev => prev.map(p => {
          const conn = connections.find((c: any) => c.provider === p.id);
          return {
            ...p,
            connected: !!conn,
            accountEmail: conn?.accountEmail,
            lastSyncAt: conn?.lastSyncAt,
          };
        }));
      }
    } catch (err) {
      console.error('Failed to fetch calendar connections:', err);
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchConnections();
  }, [fetchConnections]);

  const connectGoogle = async () => {
    setConnectingProvider('google');
    try {
      const result = await googleAuth.promptAsync();

      if (result.type === 'success') {
        const { access_token, refresh_token } = result.params;

        // Send tokens to backend
        const token = await getIdToken();
        const response = await fetch(`${API_BASE_URL}/calendars/connect/google`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${token}`,
          },
          body: JSON.stringify({ accessToken: access_token, refreshToken: refresh_token }),
        });

        if (response.ok) {
          await fetchConnections();
          Alert.alert('Success', 'Google Calendar connected!');
        } else {
          throw new Error('Failed to connect');
        }
      }
    } catch (err) {
      console.error('Google calendar connect error:', err);
      Alert.alert('Error', 'Failed to connect Google Calendar');
    } finally {
      setConnectingProvider(null);
    }
  };

  const connectApple = async () => {
    if (Platform.OS !== 'ios') {
      Alert.alert('Not Available', 'iOS Calendar sync is only available on iOS devices.');
      return;
    }

    setConnectingProvider('apple');
    try {
      const hasPermission = await requestCalendarPermission();

      if (!hasPermission) {
        Alert.alert(
          'Permission Required',
          'Please enable calendar access in Settings to sync your iOS calendars.',
          [
            { text: 'Cancel', style: 'cancel' },
            { text: 'Open Settings', onPress: () => Linking.openSettings() },
          ]
        );
        setConnectingProvider(null);
        return;
      }

      // Get available calendars
      const calendars = await getDeviceCalendars();

      // Navigate to calendar picker
      router.push({
        pathname: '/(tabs)/settings/select-calendars',
        params: { provider: 'apple', calendars: JSON.stringify(calendars) },
      });
    } catch (err) {
      console.error('Apple calendar connect error:', err);
      Alert.alert('Error', 'Failed to access device calendars');
    } finally {
      setConnectingProvider(null);
    }
  };

  const disconnectProvider = async (providerId: string) => {
    Alert.alert(
      'Disconnect Calendar',
      'Are you sure you want to disconnect this calendar? Events will no longer sync.',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Disconnect',
          style: 'destructive',
          onPress: async () => {
            try {
              const token = await getIdToken();
              await fetch(`${API_BASE_URL}/calendars/disconnect/${providerId}`, {
                method: 'DELETE',
                headers: { Authorization: `Bearer ${token}` },
              });
              await fetchConnections();
            } catch (err) {
              Alert.alert('Error', 'Failed to disconnect calendar');
            }
          },
        },
      ]
    );
  };

  const handleProviderPress = (provider: CalendarProvider) => {
    if (provider.connected) {
      disconnectProvider(provider.id);
    } else {
      switch (provider.id) {
        case 'google':
          connectGoogle();
          break;
        case 'apple':
          connectApple();
          break;
      }
    }
  };

  const formatLastSync = (dateString?: string) => {
    if (!dateString) return null;
    const date = new Date(dateString);
    const now = new Date();
    const diffMinutes = Math.floor((now.getTime() - date.getTime()) / 60000);

    if (diffMinutes < 1) return 'Just now';
    if (diffMinutes < 60) return `${diffMinutes}m ago`;
    if (diffMinutes < 1440) return `${Math.floor(diffMinutes / 60)}h ago`;
    return date.toLocaleDateString();
  };

  if (isLoading) {
    return (
      <ScreenContainer title="Calendar Sync" showBack>
        <View style={styles.loadingContainer}>
          <ActivityIndicator size="large" color={colors.haven.purple[500]} />
        </View>
      </ScreenContainer>
    );
  }

  return (
    <ScreenContainer title="Calendar Sync" showBack>
      <ScrollView style={styles.container}>
        <Text style={styles.description}>
          Connect your calendars to see events on your dashboard and help Alfred
          manage your family's schedule.
        </Text>

        <View style={styles.providersContainer}>
          {providers.map(provider => (
            <TouchableOpacity
              key={provider.id}
              style={styles.providerCard}
              onPress={() => handleProviderPress(provider)}
              disabled={connectingProvider === provider.id}
            >
              <View style={[styles.providerIcon, { backgroundColor: provider.color }]}>
                <Ionicons name={provider.icon} size={24} color="#fff" />
              </View>

              <View style={styles.providerInfo}>
                <Text style={styles.providerName}>{provider.name}</Text>
                {provider.connected && provider.accountEmail && (
                  <Text style={styles.providerEmail}>{provider.accountEmail}</Text>
                )}
                {provider.connected && provider.lastSyncAt && (
                  <Text style={styles.lastSync}>
                    Last synced: {formatLastSync(provider.lastSyncAt)}
                  </Text>
                )}
              </View>

              {connectingProvider === provider.id ? (
                <ActivityIndicator size="small" color={colors.haven.purple[500]} />
              ) : provider.connected ? (
                <View style={styles.connectedBadge}>
                  <Ionicons name="checkmark-circle" size={20} color="#10b981" />
                  <Text style={styles.connectedText}>Connected</Text>
                </View>
              ) : (
                <Text style={styles.connectText}>Connect</Text>
              )}
            </TouchableOpacity>
          ))}
        </View>

        <View style={styles.infoBox}>
          <Ionicons name="information-circle" size={20} color={colors.haven.purple[400]} />
          <Text style={styles.infoText}>
            Haven only reads your calendar events. We never modify or delete your events.
          </Text>
        </View>

        {/* Sync button for connected calendars */}
        {providers.some(p => p.connected) && (
          <TouchableOpacity
            style={styles.syncButton}
            onPress={async () => {
              try {
                const token = await getIdToken();
                await fetch(`${API_BASE_URL}/calendars/sync`, {
                  method: 'POST',
                  headers: { Authorization: `Bearer ${token}` },
                });
                await fetchConnections();
                Alert.alert('Success', 'Calendars synced!');
              } catch (err) {
                Alert.alert('Error', 'Failed to sync calendars');
              }
            }}
          >
            <Ionicons name="refresh" size={20} color={colors.haven.purple[600]} />
            <Text style={styles.syncButtonText}>Sync Now</Text>
          </TouchableOpacity>
        )}
      </ScrollView>
    </ScreenContainer>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: spacing[4],
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  description: {
    fontSize: typography.fontSizes.base,
    color: colors.haven.purple[600],
    marginBottom: spacing[6],
    lineHeight: 24,
  },
  providersContainer: {
    gap: spacing[3],
  },
  providerCard: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.white,
    padding: spacing[4],
    borderRadius: borderRadius.lg,
    borderWidth: 1,
    borderColor: colors.border.default,
  },
  providerIcon: {
    width: 48,
    height: 48,
    borderRadius: 12,
    alignItems: 'center',
    justifyContent: 'center',
  },
  providerInfo: {
    flex: 1,
    marginLeft: spacing[3],
  },
  providerName: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.haven.purple[900],
  },
  providerEmail: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.purple[500],
    marginTop: 2,
  },
  lastSync: {
    fontSize: typography.fontSizes.xs,
    color: colors.haven.purple[400],
    marginTop: 2,
  },
  connectedBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[1],
  },
  connectedText: {
    fontSize: typography.fontSizes.sm,
    color: '#10b981',
    fontWeight: typography.fontWeights.medium,
  },
  connectText: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.purple[600],
    fontWeight: typography.fontWeights.semibold,
  },
  infoBox: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    backgroundColor: colors.haven.purple[50],
    padding: spacing[4],
    borderRadius: borderRadius.lg,
    marginTop: spacing[6],
    gap: spacing[3],
  },
  infoText: {
    flex: 1,
    fontSize: typography.fontSizes.sm,
    color: colors.haven.purple[600],
    lineHeight: 20,
  },
  syncButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: colors.haven.purple[100],
    padding: spacing[4],
    borderRadius: borderRadius.lg,
    marginTop: spacing[4],
    gap: spacing[2],
  },
  syncButtonText: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.medium,
    color: colors.haven.purple[600],
  },
});

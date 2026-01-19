# Haven Mobile - Calendar Sync Integration (Read-Only)

## OVERVIEW

Implement read-only calendar sync for iOS Calendar and Google Calendar. Events from connected calendars will appear in Today's Notes and the family calendar view.

**Note:** We already have Google and Apple OAuth set up for authentication, so we can leverage those existing integrations.

---

## SUPPORTED PROVIDERS

1. **Google Calendar** - Uses existing Google OAuth setup
2. **iOS Calendar** - Device calendar access via expo-calendar

---

## PART 1: DATABASE SCHEMA

### Add Calendar Tables to Prisma

**File:** `apps/api/prisma/schema.prisma`

```prisma
model CalendarConnection {
  id            String   @id @default(cuid())
  householdId   String
  household     Household @relation(fields: [householdId], references: [id])
  userId        String   // User who connected the calendar
  user          User     @relation(fields: [userId], references: [id])
  
  provider      String   // 'google', 'apple'
  accountEmail  String?  // Email associated with calendar account
  accessToken   String?  // Encrypted OAuth access token
  refreshToken  String?  // Encrypted OAuth refresh token
  tokenExpiry   DateTime?
  
  // For Apple/iOS - we store calendar IDs from device
  deviceCalendarIds String[] // Array of selected calendar IDs
  
  isActive      Boolean  @default(true)
  lastSyncAt    DateTime?
  syncError     String?
  
  createdAt     DateTime @default(now())
  updatedAt     DateTime @updatedAt
  
  events        CalendarEvent[]
  
  @@unique([householdId, provider, accountEmail])
}

model CalendarEvent {
  id                  String   @id @default(cuid())
  connectionId        String
  connection          CalendarConnection @relation(fields: [connectionId], references: [id], onDelete: Cascade)
  householdId         String
  household           Household @relation(fields: [householdId], references: [id])
  
  externalId          String   // ID from external calendar
  title               String
  description         String?
  location            String?
  
  startTime           DateTime
  endTime             DateTime
  isAllDay            Boolean  @default(false)
  
  // For recurring events
  recurringEventId    String?
  
  // Calendar metadata
  calendarName        String?
  calendarColor       String?
  
  // Link to family member if applicable
  familyMemberId      String?
  familyMember        HouseholdMember? @relation(fields: [familyMemberId], references: [id])
  
  createdAt           DateTime @default(now())
  updatedAt           DateTime @updatedAt
  
  @@unique([connectionId, externalId])
  @@index([householdId, startTime])
}
```

Run migration:
```bash
cd apps/api
pnpm prisma migrate dev --name add_calendar_sync
```

---

## PART 2: GOOGLE CALENDAR INTEGRATION

### Leverage Existing Google OAuth

We already have Google OAuth configured for sign-in. We need to add calendar scopes.

**Required Additional Scopes:**
- `https://www.googleapis.com/auth/calendar.readonly`
- `https://www.googleapis.com/auth/calendar.events.readonly`

### Mobile Implementation

**File:** `apps/mobile/src/lib/google-calendar.ts`

```typescript
import * as WebBrowser from 'expo-web-browser';
import * as Google from 'expo-auth-session/providers/google';
import { makeRedirectUri } from 'expo-auth-session';

WebBrowser.maybeCompleteAuthSession();

// Use existing Google client IDs from .env
const WEB_CLIENT_ID = process.env.EXPO_PUBLIC_GOOGLE_WEB_CLIENT_ID;
const IOS_CLIENT_ID = process.env.EXPO_PUBLIC_GOOGLE_IOS_CLIENT_ID;

const GOOGLE_CALENDAR_SCOPES = [
  'https://www.googleapis.com/auth/calendar.readonly',
  'https://www.googleapis.com/auth/calendar.events.readonly',
  'profile',
  'email',
];

export function useGoogleCalendarAuth() {
  const redirectUri = makeRedirectUri({ scheme: 'haven' });

  const [request, response, promptAsync] = Google.useAuthRequest({
    webClientId: WEB_CLIENT_ID,
    iosClientId: IOS_CLIENT_ID,
    scopes: GOOGLE_CALENDAR_SCOPES,
    redirectUri,
  });

  return { request, response, promptAsync };
}

export async function fetchGoogleCalendars(accessToken: string) {
  const response = await fetch(
    'https://www.googleapis.com/calendar/v3/users/me/calendarList',
    {
      headers: { Authorization: `Bearer ${accessToken}` },
    }
  );
  
  if (!response.ok) throw new Error('Failed to fetch calendars');
  
  const data = await response.json();
  return data.items.map((cal: any) => ({
    id: cal.id,
    name: cal.summary,
    color: cal.backgroundColor,
    primary: cal.primary || false,
  }));
}

export async function fetchGoogleEvents(
  accessToken: string,
  calendarId: string,
  timeMin: Date,
  timeMax: Date
) {
  const params = new URLSearchParams({
    timeMin: timeMin.toISOString(),
    timeMax: timeMax.toISOString(),
    singleEvents: 'true',
    orderBy: 'startTime',
    maxResults: '100',
  });

  const response = await fetch(
    `https://www.googleapis.com/calendar/v3/calendars/${encodeURIComponent(calendarId)}/events?${params}`,
    {
      headers: { Authorization: `Bearer ${accessToken}` },
    }
  );
  
  if (!response.ok) throw new Error('Failed to fetch events');
  
  const data = await response.json();
  return data.items.map((event: any) => ({
    externalId: event.id,
    title: event.summary || '(No title)',
    description: event.description,
    location: event.location,
    startTime: event.start.dateTime || event.start.date,
    endTime: event.end.dateTime || event.end.date,
    isAllDay: !!event.start.date,
  }));
}
```

---

## PART 3: iOS CALENDAR INTEGRATION

### Using expo-calendar

**File:** `apps/mobile/src/lib/ios-calendar.ts`

```typescript
import * as Calendar from 'expo-calendar';
import { Platform, Linking } from 'react-native';

export async function requestCalendarPermission(): Promise<boolean> {
  if (Platform.OS !== 'ios') return false;
  
  const { status } = await Calendar.requestCalendarPermissionsAsync();
  return status === 'granted';
}

export async function getDeviceCalendars() {
  const hasPermission = await requestCalendarPermission();
  if (!hasPermission) {
    throw new Error('Calendar permission not granted');
  }

  const calendars = await Calendar.getCalendarsAsync(Calendar.EntityTypes.EVENT);
  
  return calendars.map(cal => ({
    id: cal.id,
    name: cal.title,
    color: cal.color,
    source: cal.source.name,
    type: cal.source.type,
    // Filter to show only useful calendars
    isSelectable: cal.allowsModifications || cal.source.type === 'caldav',
  }));
}

export async function getDeviceEvents(
  calendarIds: string[],
  startDate: Date,
  endDate: Date
) {
  const hasPermission = await requestCalendarPermission();
  if (!hasPermission) {
    throw new Error('Calendar permission not granted');
  }

  const events = await Calendar.getEventsAsync(
    calendarIds,
    startDate,
    endDate
  );

  return events.map(event => ({
    externalId: event.id,
    title: event.title || '(No title)',
    description: event.notes,
    location: event.location,
    startTime: event.startDate,
    endTime: event.endDate,
    isAllDay: event.allDay,
    calendarId: event.calendarId,
  }));
}
```

---

## PART 4: CALENDAR SETTINGS SCREEN

**File:** `apps/mobile/app/(tabs)/more/settings/calendars.tsx`

```typescript
import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  ScrollView,
  Alert,
  ActivityIndicator,
  Linking,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { useRouter } from 'expo-router';
import { ScreenContainer } from '../../../../src/components';
import { useGoogleCalendarAuth, fetchGoogleCalendars } from '../../../../src/lib/google-calendar';
import { getDeviceCalendars, requestCalendarPermission } from '../../../../src/lib/ios-calendar';
import { colors, spacing, typography, borderRadius } from '../../../../src/lib/theme';
import { getIdToken } from '../../../../src/lib/firebase';

const API_URL = process.env.EXPO_PUBLIC_API_URL;

interface CalendarProvider {
  id: string;
  name: string;
  icon: string;
  color: string;
  connected: boolean;
  accountEmail?: string;
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
  useEffect(() => {
    fetchConnections();
  }, []);

  const fetchConnections = async () => {
    try {
      const token = await getIdToken();
      const response = await fetch(`${API_URL}/calendars/connections`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      const connections = await response.json();
      
      setProviders(prev => prev.map(p => {
        const conn = connections.find((c: any) => c.provider === p.id);
        return {
          ...p,
          connected: !!conn,
          accountEmail: conn?.accountEmail,
        };
      }));
    } catch (err) {
      console.error('Failed to fetch calendar connections:', err);
    } finally {
      setIsLoading(false);
    }
  };

  const connectGoogle = async () => {
    setConnectingProvider('google');
    try {
      const result = await googleAuth.promptAsync();
      
      if (result.type === 'success') {
        const { access_token, refresh_token } = result.params;
        
        // Send tokens to backend
        const token = await getIdToken();
        await fetch(`${API_URL}/calendars/connect/google`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${token}`,
          },
          body: JSON.stringify({ accessToken: access_token, refreshToken: refresh_token }),
        });
        
        await fetchConnections();
        Alert.alert('Success', 'Google Calendar connected!');
      }
    } catch (err) {
      Alert.alert('Error', 'Failed to connect Google Calendar');
    } finally {
      setConnectingProvider(null);
    }
  };

  const connectApple = async () => {
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
        pathname: '/(tabs)/more/settings/select-calendars',
        params: { provider: 'apple', calendars: JSON.stringify(calendars) },
      });
    } catch (err) {
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
              await fetch(`${API_URL}/calendars/disconnect/${providerId}`, {
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
                <Ionicons name={provider.icon as any} size={24} color="#fff" />
              </View>
              
              <View style={styles.providerInfo}>
                <Text style={styles.providerName}>{provider.name}</Text>
                {provider.connected && provider.accountEmail && (
                  <Text style={styles.providerEmail}>{provider.accountEmail}</Text>
                )}
              </View>
              
              {connectingProvider === provider.id ? (
                <ActivityIndicator size="small" color={colors.haven.champagne[500]} />
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
          <Ionicons name="information-circle" size={20} color={colors.haven.navy[400]} />
          <Text style={styles.infoText}>
            Haven only reads your calendar events. We never modify or delete your events.
          </Text>
        </View>
      </ScrollView>
    </ScreenContainer>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: spacing[4],
  },
  description: {
    fontSize: typography.fontSizes.base,
    color: colors.haven.navy[600],
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
    color: colors.haven.navy[900],
  },
  providerEmail: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.navy[500],
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
    color: colors.haven.champagne[600],
    fontWeight: typography.fontWeights.semibold,
  },
  infoBox: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    backgroundColor: colors.haven.navy[50],
    padding: spacing[4],
    borderRadius: borderRadius.lg,
    marginTop: spacing[6],
    gap: spacing[3],
  },
  infoText: {
    flex: 1,
    fontSize: typography.fontSizes.sm,
    color: colors.haven.navy[600],
    lineHeight: 20,
  },
});
```

---

## PART 5: CALENDAR PICKER SCREEN (for iOS)

**File:** `apps/mobile/app/(tabs)/more/settings/select-calendars.tsx`

```typescript
import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  ScrollView,
  Alert,
} from 'react-native';
import { useRouter, useLocalSearchParams } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { ScreenContainer } from '../../../../src/components';
import { colors, spacing, typography, borderRadius } from '../../../../src/lib/theme';
import { getIdToken } from '../../../../src/lib/firebase';

const API_URL = process.env.EXPO_PUBLIC_API_URL;

interface DeviceCalendar {
  id: string;
  name: string;
  color: string;
  source: string;
  isSelectable: boolean;
}

export default function SelectCalendarsScreen() {
  const router = useRouter();
  const params = useLocalSearchParams();
  const provider = params.provider as string;
  const calendars: DeviceCalendar[] = JSON.parse(params.calendars as string || '[]');
  
  const [selectedIds, setSelectedIds] = useState<string[]>([]);
  const [isSaving, setIsSaving] = useState(false);

  const toggleCalendar = (id: string) => {
    setSelectedIds(prev => 
      prev.includes(id) 
        ? prev.filter(i => i !== id)
        : [...prev, id]
    );
  };

  const handleSave = async () => {
    if (selectedIds.length === 0) {
      Alert.alert('Select Calendars', 'Please select at least one calendar to sync.');
      return;
    }

    setIsSaving(true);
    try {
      const token = await getIdToken();
      await fetch(`${API_URL}/calendars/connect/apple`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({ calendarIds: selectedIds }),
      });
      
      Alert.alert('Success', 'iOS Calendars connected!');
      router.back();
    } catch (err) {
      Alert.alert('Error', 'Failed to save calendar selection');
    } finally {
      setIsSaving(false);
    }
  };

  // Group calendars by source
  const groupedCalendars = calendars.reduce((acc, cal) => {
    if (!acc[cal.source]) acc[cal.source] = [];
    acc[cal.source].push(cal);
    return acc;
  }, {} as Record<string, DeviceCalendar[]>);

  return (
    <ScreenContainer title="Select Calendars" showBack>
      <ScrollView style={styles.container}>
        <Text style={styles.description}>
          Choose which calendars to sync with Haven.
        </Text>

        {Object.entries(groupedCalendars).map(([source, cals]) => (
          <View key={source} style={styles.group}>
            <Text style={styles.groupTitle}>{source}</Text>
            {cals.map(cal => (
              <TouchableOpacity
                key={cal.id}
                style={styles.calendarRow}
                onPress={() => toggleCalendar(cal.id)}
              >
                <View style={[styles.colorDot, { backgroundColor: cal.color || '#627d98' }]} />
                <Text style={styles.calendarName}>{cal.name}</Text>
                <View style={[
                  styles.checkbox,
                  selectedIds.includes(cal.id) && styles.checkboxSelected
                ]}>
                  {selectedIds.includes(cal.id) && (
                    <Ionicons name="checkmark" size={16} color="#fff" />
                  )}
                </View>
              </TouchableOpacity>
            ))}
          </View>
        ))}

        <TouchableOpacity
          style={[styles.saveButton, isSaving && styles.saveButtonDisabled]}
          onPress={handleSave}
          disabled={isSaving}
        >
          <Text style={styles.saveButtonText}>
            {isSaving ? 'Saving...' : `Sync ${selectedIds.length} Calendar${selectedIds.length !== 1 ? 's' : ''}`}
          </Text>
        </TouchableOpacity>
      </ScrollView>
    </ScreenContainer>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: spacing[4],
  },
  description: {
    fontSize: typography.fontSizes.base,
    color: colors.haven.navy[600],
    marginBottom: spacing[6],
  },
  group: {
    marginBottom: spacing[6],
  },
  groupTitle: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
    color: colors.haven.navy[500],
    textTransform: 'uppercase',
    letterSpacing: 0.5,
    marginBottom: spacing[2],
  },
  calendarRow: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.white,
    padding: spacing[4],
    borderRadius: borderRadius.lg,
    marginBottom: spacing[2],
    borderWidth: 1,
    borderColor: colors.border.default,
  },
  colorDot: {
    width: 12,
    height: 12,
    borderRadius: 6,
    marginRight: spacing[3],
  },
  calendarName: {
    flex: 1,
    fontSize: typography.fontSizes.base,
    color: colors.haven.navy[900],
  },
  checkbox: {
    width: 24,
    height: 24,
    borderRadius: 6,
    borderWidth: 2,
    borderColor: colors.haven.navy[300],
    alignItems: 'center',
    justifyContent: 'center',
  },
  checkboxSelected: {
    backgroundColor: colors.haven.champagne[500],
    borderColor: colors.haven.champagne[500],
  },
  saveButton: {
    backgroundColor: colors.haven.navy[900],
    padding: spacing[4],
    borderRadius: borderRadius.lg,
    alignItems: 'center',
    marginTop: spacing[4],
  },
  saveButtonDisabled: {
    opacity: 0.6,
  },
  saveButtonText: {
    color: colors.white,
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
  },
});
```

---

## PART 6: API ENDPOINTS

### Calendar Controller

**File:** `apps/api/src/calendars/calendars.controller.ts`

```typescript
import { Controller, Get, Post, Delete, Body, Param, Query, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { CalendarsService } from './calendars.service';
import { User } from '@prisma/client';

@Controller('calendars')
@UseGuards(JwtAuthGuard)
export class CalendarsController {
  constructor(private readonly calendarsService: CalendarsService) {}

  @Get('connections')
  async getConnections(@CurrentUser() user: User) {
    return this.calendarsService.getConnections(user);
  }

  @Post('connect/google')
  async connectGoogle(
    @CurrentUser() user: User,
    @Body() body: { accessToken: string; refreshToken?: string }
  ) {
    return this.calendarsService.connectGoogle(user, body.accessToken, body.refreshToken);
  }

  @Post('connect/apple')
  async connectApple(
    @CurrentUser() user: User,
    @Body() body: { calendarIds: string[] }
  ) {
    return this.calendarsService.connectApple(user, body.calendarIds);
  }

  @Delete('disconnect/:provider')
  async disconnect(
    @CurrentUser() user: User,
    @Param('provider') provider: string
  ) {
    return this.calendarsService.disconnect(user, provider);
  }

  @Get('events')
  async getEvents(
    @CurrentUser() user: User,
    @Query('start') start: string,
    @Query('end') end: string
  ) {
    return this.calendarsService.getEvents(
      user,
      new Date(start),
      new Date(end)
    );
  }

  @Post('sync')
  async syncCalendars(@CurrentUser() user: User) {
    return this.calendarsService.syncAllCalendars(user);
  }
}
```

### Calendar Service

**File:** `apps/api/src/calendars/calendars.service.ts`

```typescript
import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { Cron, CronExpression } from '@nestjs/schedule';
import { User, CalendarConnection } from '@prisma/client';
import * as crypto from 'crypto';

@Injectable()
export class CalendarsService {
  private readonly logger = new Logger(CalendarsService.name);
  private readonly encryptionKey = process.env.CALENDAR_ENCRYPTION_KEY || 'default-key-change-me-32chars!!';

  constructor(private prisma: PrismaService) {}

  private encrypt(text: string): string {
    const iv = crypto.randomBytes(16);
    const cipher = crypto.createCipheriv('aes-256-cbc', Buffer.from(this.encryptionKey), iv);
    let encrypted = cipher.update(text);
    encrypted = Buffer.concat([encrypted, cipher.final()]);
    return iv.toString('hex') + ':' + encrypted.toString('hex');
  }

  private decrypt(text: string): string {
    const parts = text.split(':');
    const iv = Buffer.from(parts.shift()!, 'hex');
    const encryptedText = Buffer.from(parts.join(':'), 'hex');
    const decipher = crypto.createDecipheriv('aes-256-cbc', Buffer.from(this.encryptionKey), iv);
    let decrypted = decipher.update(encryptedText);
    decrypted = Buffer.concat([decrypted, decipher.final()]);
    return decrypted.toString();
  }

  private async getActiveHousehold(user: User) {
    const membership = await this.prisma.householdMember.findFirst({
      where: { userId: user.id },
      include: { household: true },
    });
    if (!membership) throw new Error('No household found');
    return membership.household;
  }

  async getConnections(user: User) {
    const household = await this.getActiveHousehold(user);
    
    return this.prisma.calendarConnection.findMany({
      where: { householdId: household.id, isActive: true },
      select: {
        id: true,
        provider: true,
        accountEmail: true,
        lastSyncAt: true,
      },
    });
  }

  async connectGoogle(user: User, accessToken: string, refreshToken?: string) {
    const household = await this.getActiveHousehold(user);
    
    // Get user info from Google
    const userInfo = await this.fetchGoogleUserInfo(accessToken);
    
    // Create or update connection
    const connection = await this.prisma.calendarConnection.upsert({
      where: {
        householdId_provider_accountEmail: {
          householdId: household.id,
          provider: 'google',
          accountEmail: userInfo.email,
        },
      },
      update: {
        accessToken: this.encrypt(accessToken),
        refreshToken: refreshToken ? this.encrypt(refreshToken) : undefined,
        isActive: true,
        syncError: null,
      },
      create: {
        householdId: household.id,
        userId: user.id,
        provider: 'google',
        accountEmail: userInfo.email,
        accessToken: this.encrypt(accessToken),
        refreshToken: refreshToken ? this.encrypt(refreshToken) : undefined,
      },
    });

    // Trigger initial sync
    await this.syncGoogleCalendar(connection);

    return { success: true, provider: 'google', email: userInfo.email };
  }

  async connectApple(user: User, calendarIds: string[]) {
    const household = await this.getActiveHousehold(user);
    
    // Create or update connection
    const connection = await this.prisma.calendarConnection.upsert({
      where: {
        householdId_provider_accountEmail: {
          householdId: household.id,
          provider: 'apple',
          accountEmail: user.email, // Use user's email as identifier
        },
      },
      update: {
        deviceCalendarIds: calendarIds,
        isActive: true,
        syncError: null,
      },
      create: {
        householdId: household.id,
        userId: user.id,
        provider: 'apple',
        accountEmail: user.email,
        deviceCalendarIds: calendarIds,
      },
    });

    return { success: true, provider: 'apple', calendarCount: calendarIds.length };
  }

  async disconnect(user: User, provider: string) {
    const household = await this.getActiveHousehold(user);
    
    await this.prisma.calendarConnection.updateMany({
      where: { householdId: household.id, provider },
      data: { isActive: false },
    });

    // Delete synced events for this provider
    await this.prisma.calendarEvent.deleteMany({
      where: {
        householdId: household.id,
        connection: { provider },
      },
    });

    return { success: true };
  }

  private async fetchGoogleUserInfo(accessToken: string) {
    const response = await fetch('https://www.googleapis.com/oauth2/v2/userinfo', {
      headers: { Authorization: `Bearer ${accessToken}` },
    });
    if (!response.ok) throw new Error('Failed to fetch Google user info');
    return response.json();
  }

  private async fetchGoogleCalendars(accessToken: string) {
    const response = await fetch(
      'https://www.googleapis.com/calendar/v3/users/me/calendarList',
      { headers: { Authorization: `Bearer ${accessToken}` } }
    );
    if (!response.ok) throw new Error('Failed to fetch Google calendars');
    const data = await response.json();
    return data.items || [];
  }

  private async fetchGoogleEvents(accessToken: string, calendarId: string, timeMin: Date, timeMax: Date) {
    const params = new URLSearchParams({
      timeMin: timeMin.toISOString(),
      timeMax: timeMax.toISOString(),
      singleEvents: 'true',
      orderBy: 'startTime',
      maxResults: '100',
    });

    const response = await fetch(
      `https://www.googleapis.com/calendar/v3/calendars/${encodeURIComponent(calendarId)}/events?${params}`,
      { headers: { Authorization: `Bearer ${accessToken}` } }
    );
    if (!response.ok) throw new Error('Failed to fetch Google events');
    const data = await response.json();
    return data.items || [];
  }

  async syncGoogleCalendar(connection: CalendarConnection) {
    try {
      const accessToken = this.decrypt(connection.accessToken!);
      
      // Fetch events for next 30 days
      const now = new Date();
      const endDate = new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000);
      
      const calendars = await this.fetchGoogleCalendars(accessToken);
      
      for (const calendar of calendars) {
        const events = await this.fetchGoogleEvents(accessToken, calendar.id, now, endDate);
        
        for (const event of events) {
          await this.prisma.calendarEvent.upsert({
            where: {
              connectionId_externalId: {
                connectionId: connection.id,
                externalId: event.id,
              },
            },
            update: {
              title: event.summary || '(No title)',
              description: event.description,
              location: event.location,
              startTime: new Date(event.start.dateTime || event.start.date),
              endTime: new Date(event.end.dateTime || event.end.date),
              isAllDay: !!event.start.date,
              calendarName: calendar.summary,
              calendarColor: calendar.backgroundColor,
            },
            create: {
              connectionId: connection.id,
              householdId: connection.householdId,
              externalId: event.id,
              title: event.summary || '(No title)',
              description: event.description,
              location: event.location,
              startTime: new Date(event.start.dateTime || event.start.date),
              endTime: new Date(event.end.dateTime || event.end.date),
              isAllDay: !!event.start.date,
              calendarName: calendar.summary,
              calendarColor: calendar.backgroundColor,
            },
          });
        }
      }

      await this.prisma.calendarConnection.update({
        where: { id: connection.id },
        data: { lastSyncAt: new Date(), syncError: null },
      });

      this.logger.log(`Synced Google calendar for connection ${connection.id}`);
    } catch (error) {
      this.logger.error(`Google calendar sync failed: ${error.message}`);
      await this.prisma.calendarConnection.update({
        where: { id: connection.id },
        data: { syncError: error.message },
      });
    }
  }

  // Scheduled sync - every 15 minutes
  @Cron(CronExpression.EVERY_15_MINUTES)
  async scheduledSync() {
    const connections = await this.prisma.calendarConnection.findMany({
      where: { isActive: true, provider: 'google' },
    });

    for (const connection of connections) {
      await this.syncGoogleCalendar(connection);
    }
  }

  async getEvents(user: User, startDate: Date, endDate: Date) {
    const household = await this.getActiveHousehold(user);
    
    return this.prisma.calendarEvent.findMany({
      where: {
        householdId: household.id,
        startTime: { gte: startDate },
        endTime: { lte: endDate },
      },
      orderBy: { startTime: 'asc' },
    });
  }

  async syncAllCalendars(user: User) {
    const household = await this.getActiveHousehold(user);
    
    const connections = await this.prisma.calendarConnection.findMany({
      where: { householdId: household.id, isActive: true },
    });

    for (const connection of connections) {
      if (connection.provider === 'google') {
        await this.syncGoogleCalendar(connection);
      }
      // Apple calendars are synced on-device, not server-side
    }

    return { success: true, synced: connections.length };
  }
}
```

### Calendar Module

**File:** `apps/api/src/calendars/calendars.module.ts`

```typescript
import { Module } from '@nestjs/common';
import { CalendarsController } from './calendars.controller';
import { CalendarsService } from './calendars.service';
import { PrismaModule } from '../prisma/prisma.module';

@Module({
  imports: [PrismaModule],
  controllers: [CalendarsController],
  providers: [CalendarsService],
  exports: [CalendarsService],
})
export class CalendarsModule {}
```

Don't forget to add to app.module.ts:
```typescript
import { CalendarsModule } from './calendars/calendars.module';

@Module({
  imports: [
    // ... other modules
    CalendarsModule,
  ],
})
export class AppModule {}
```

---

## PART 7: UPDATE app.json FOR CALENDAR PERMISSIONS

**File:** `apps/mobile/app.json`

Add calendar permission and plugin:

```json
{
  "expo": {
    "ios": {
      "infoPlist": {
        "NSCalendarsUsageDescription": "Haven needs calendar access to show your events and help manage your schedule."
      }
    },
    "plugins": [
      // ... existing plugins
      [
        "expo-calendar",
        {
          "calendarPermission": "Haven needs calendar access to show your events and help manage your schedule."
        }
      ]
    ]
  }
}
```

---

## PART 8: INSTALL EXPO-CALENDAR

```bash
cd apps/mobile
npx expo install expo-calendar
```

---

## ENVIRONMENT VARIABLES

Add to `apps/api/.env`:

```bash
# Encryption key for storing OAuth tokens (must be exactly 32 characters)
CALENDAR_ENCRYPTION_KEY=your_32_character_encryption_key
```

---

## VERIFICATION CHECKLIST

### Google Calendar
- [ ] OAuth flow completes using existing Google setup
- [ ] Events sync from Google
- [ ] Events appear in Today's Notes
- [ ] Can disconnect calendar

### iOS Calendar
- [ ] Permission prompt appears
- [ ] Can select which calendars to sync
- [ ] Events appear in Today's Notes
- [ ] Works with iCloud calendars

### General
- [ ] Calendar settings page shows both providers
- [ ] Connected status shows correctly
- [ ] Google events refresh every 15 minutes
- [ ] Read-only (no modifications)

---

## TEST

```bash
# Install expo-calendar
cd apps/mobile
npx expo install expo-calendar

# Run Prisma migration
cd apps/api
pnpm prisma migrate dev --name add_calendar_sync

# Start API
pnpm dev

# Start mobile (in another terminal)
cd apps/mobile  
npx expo start --clear
```

Navigate to: More → Settings → Calendar Sync

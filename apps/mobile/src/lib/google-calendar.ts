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

export interface GoogleCalendar {
  id: string;
  name: string;
  color: string;
  primary: boolean;
}

export interface GoogleEvent {
  externalId: string;
  title: string;
  description?: string;
  location?: string;
  startTime: string;
  endTime: string;
  isAllDay: boolean;
}

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

export async function fetchGoogleCalendars(accessToken: string): Promise<GoogleCalendar[]> {
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
): Promise<GoogleEvent[]> {
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

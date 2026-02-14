import * as Calendar from 'expo-calendar';
import { Platform, Linking } from 'react-native';

export interface DeviceCalendar {
  id: string;
  name: string;
  color: string;
  source: string;
  type: string;
  isSelectable: boolean;
}

export interface DeviceEvent {
  externalId: string;
  title: string;
  description?: string;
  location?: string;
  startTime: string;
  endTime: string;
  isAllDay: boolean;
  calendarId: string;
}

export async function requestCalendarPermission(): Promise<boolean> {
  if (Platform.OS !== 'ios') return false;

  const { status } = await Calendar.requestCalendarPermissionsAsync();
  return status === 'granted';
}

export async function checkCalendarPermission(): Promise<boolean> {
  if (Platform.OS !== 'ios') return false;

  const { status } = await Calendar.getCalendarPermissionsAsync();
  return status === 'granted';
}

export async function openCalendarSettings(): Promise<void> {
  await Linking.openSettings();
}

export async function getDeviceCalendars(): Promise<DeviceCalendar[]> {
  const hasPermission = await requestCalendarPermission();
  if (!hasPermission) {
    throw new Error('Calendar permission not granted');
  }

  const calendars = await Calendar.getCalendarsAsync(Calendar.EntityTypes.EVENT);

  return calendars.map(cal => ({
    id: cal.id,
    name: cal.title,
    color: cal.color || '#6200EA',
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
): Promise<DeviceEvent[]> {
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
    description: event.notes || undefined,
    location: event.location || undefined,
    startTime: typeof event.startDate === 'string' ? event.startDate : event.startDate.toISOString(),
    endTime: typeof event.endDate === 'string' ? event.endDate : event.endDate.toISOString(),
    isAllDay: event.allDay,
    calendarId: event.calendarId,
  }));
}

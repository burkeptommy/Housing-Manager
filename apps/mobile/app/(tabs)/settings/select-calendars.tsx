import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  ScrollView,
  Alert,
  ActivityIndicator,
} from 'react-native';
import { useRouter, useLocalSearchParams } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { ScreenContainer } from '../../../src/components';
import { colors, spacing, typography, borderRadius } from '../../../src/lib/theme';
import { getIdToken } from '../../../src/lib/firebase';
import { API_BASE_URL } from '../../../src/lib/api';

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
      const response = await fetch(`${API_BASE_URL}/calendars/connect/apple`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({ calendarIds: selectedIds }),
      });

      if (response.ok) {
        Alert.alert('Success', 'iOS Calendars connected!');
        router.back();
      } else {
        throw new Error('Failed to save');
      }
    } catch (err) {
      console.error('Save calendars error:', err);
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

  const selectAll = () => {
    setSelectedIds(calendars.filter(c => c.isSelectable).map(c => c.id));
  };

  const deselectAll = () => {
    setSelectedIds([]);
  };

  return (
    <ScreenContainer title="Select Calendars" showBack>
      <ScrollView style={styles.container}>
        <Text style={styles.description}>
          Choose which calendars to sync with Haven.
        </Text>

        {/* Select/Deselect All */}
        <View style={styles.selectAllRow}>
          <TouchableOpacity onPress={selectAll}>
            <Text style={styles.selectAllText}>Select All</Text>
          </TouchableOpacity>
          <Text style={styles.selectAllDivider}>•</Text>
          <TouchableOpacity onPress={deselectAll}>
            <Text style={styles.selectAllText}>Deselect All</Text>
          </TouchableOpacity>
        </View>

        {Object.entries(groupedCalendars).map(([source, cals]) => (
          <View key={source} style={styles.group}>
            <Text style={styles.groupTitle}>{source}</Text>
            {cals.map(cal => (
              <TouchableOpacity
                key={cal.id}
                style={[
                  styles.calendarRow,
                  selectedIds.includes(cal.id) && styles.calendarRowSelected,
                ]}
                onPress={() => toggleCalendar(cal.id)}
              >
                <View style={[styles.colorDot, { backgroundColor: cal.color }]} />
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
          {isSaving ? (
            <ActivityIndicator size="small" color={colors.white} />
          ) : (
            <Text style={styles.saveButtonText}>
              Sync {selectedIds.length} Calendar{selectedIds.length !== 1 ? 's' : ''}
            </Text>
          )}
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
    color: colors.haven.purple[600],
    marginBottom: spacing[4],
  },
  selectAllRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: spacing[4],
  },
  selectAllText: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.purple[600],
    fontWeight: typography.fontWeights.medium,
  },
  selectAllDivider: {
    marginHorizontal: spacing[2],
    color: colors.haven.purple[300],
  },
  group: {
    marginBottom: spacing[6],
  },
  groupTitle: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
    color: colors.haven.purple[500],
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
  calendarRowSelected: {
    borderColor: colors.haven.purple[300],
    backgroundColor: colors.haven.purple[50],
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
    color: colors.haven.purple[900],
  },
  checkbox: {
    width: 24,
    height: 24,
    borderRadius: 6,
    borderWidth: 2,
    borderColor: colors.haven.purple[300],
    alignItems: 'center',
    justifyContent: 'center',
  },
  checkboxSelected: {
    backgroundColor: colors.haven.purple[500],
    borderColor: colors.haven.purple[500],
  },
  saveButton: {
    backgroundColor: colors.haven.purple[900],
    padding: spacing[4],
    borderRadius: borderRadius.lg,
    alignItems: 'center',
    marginTop: spacing[4],
    marginBottom: spacing[8],
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

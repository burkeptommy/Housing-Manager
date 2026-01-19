import React, { useState } from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  Modal,
  TextInput,
  ScrollView,
  ActivityIndicator,
  Alert,
  Platform,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import DateTimePicker from '@react-native-community/datetimepicker';
import { colors } from '../theme/colors';
import { useApi } from '../lib/api';

interface WalkthroughScheduleModalProps {
  visible: boolean;
  onClose: () => void;
  householdId: string;
  onScheduled: () => void;
}

type TimeSlot = 'morning' | 'afternoon' | 'evening';

const TIME_SLOTS: { id: TimeSlot; label: string; description: string }[] = [
  { id: 'morning', label: 'Morning', description: '9am - 12pm' },
  { id: 'afternoon', label: 'Afternoon', description: '12pm - 5pm' },
  { id: 'evening', label: 'Evening', description: '5pm - 7pm' },
];

export function WalkthroughScheduleModal({
  visible,
  onClose,
  householdId,
  onScheduled,
}: WalkthroughScheduleModalProps) {
  const api = useApi();
  const [selectedDate, setSelectedDate] = useState<Date>(
    new Date(Date.now() + 3 * 24 * 60 * 60 * 1000), // 3 days from now
  );
  const [selectedTimeSlot, setSelectedTimeSlot] = useState<TimeSlot>('morning');
  const [contactPhone, setContactPhone] = useState('');
  const [notes, setNotes] = useState('');
  const [showDatePicker, setShowDatePicker] = useState(false);
  const [loading, setLoading] = useState(false);

  const formatDate = (date: Date) => {
    return date.toLocaleDateString('en-US', {
      weekday: 'long',
      month: 'long',
      day: 'numeric',
      year: 'numeric',
    });
  };

  const handleSubmit = async () => {
    setLoading(true);
    try {
      const response = await api.post('/walkthrough/request', {
        householdId,
        preferredDate: selectedDate.toISOString(),
        preferredTimeSlot: selectedTimeSlot,
        contactPhone: contactPhone || undefined,
        notes: notes || undefined,
      });

      if (response.data?.success) {
        Alert.alert(
          'Walkthrough Scheduled!',
          response.data.message ||
            "We'll contact you within 24-48 hours to confirm your appointment.",
          [{ text: 'OK', onPress: onScheduled }],
        );
      } else {
        Alert.alert(
          'Unable to Schedule',
          response.data?.message ||
            'Please try again later or contact support.',
        );
      }
    } catch (error: any) {
      Alert.alert(
        'Error',
        error.response?.data?.message ||
          'Unable to schedule walkthrough. Please try again.',
      );
    } finally {
      setLoading(false);
    }
  };

  const minDate = new Date(Date.now() + 24 * 60 * 60 * 1000); // Tomorrow
  const maxDate = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000); // 30 days out

  return (
    <Modal
      visible={visible}
      animationType="slide"
      presentationStyle="pageSheet"
      onRequestClose={onClose}
    >
      <View style={styles.container}>
        {/* Header */}
        <View style={styles.header}>
          <TouchableOpacity onPress={onClose} style={styles.closeButton}>
            <Ionicons name="close" size={24} color={colors.text.primary} />
          </TouchableOpacity>
          <Text style={styles.headerTitle}>Schedule Walkthrough</Text>
          <View style={styles.headerSpacer} />
        </View>

        <ScrollView
          style={styles.content}
          contentContainerStyle={styles.contentContainer}
        >
          {/* Hero Section */}
          <View style={styles.hero}>
            <View style={styles.heroIcon}>
              <Ionicons
                name="home"
                size={40}
                color={colors.haven.champagne[500]}
              />
            </View>
            <Text style={styles.heroTitle}>Free Home Walkthrough</Text>
            <Text style={styles.heroSubtitle}>$299 Value - Yours FREE</Text>
          </View>

          {/* What's Included */}
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>What's Included</Text>
            <View style={styles.includesList}>
              <IncludeItem text="Complete documentation of all home systems" />
              <IncludeItem text="Recording of model numbers & installation dates" />
              <IncludeItem text="Personalized maintenance schedule creation" />
              <IncludeItem text="Identification of immediate maintenance needs" />
              <IncludeItem text="Local vendor recommendations" />
            </View>
          </View>

          {/* Date Selection */}
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Preferred Date</Text>
            <TouchableOpacity
              style={styles.dateSelector}
              onPress={() => setShowDatePicker(true)}
            >
              <Ionicons
                name="calendar-outline"
                size={20}
                color={colors.text.secondary}
              />
              <Text style={styles.dateSelectorText}>
                {formatDate(selectedDate)}
              </Text>
              <Ionicons
                name="chevron-down"
                size={20}
                color={colors.text.tertiary}
              />
            </TouchableOpacity>
          </View>

          {/* Date Picker */}
          {showDatePicker && (
            <View style={styles.datePickerContainer}>
              <DateTimePicker
                value={selectedDate}
                mode="date"
                display={Platform.OS === 'ios' ? 'spinner' : 'default'}
                minimumDate={minDate}
                maximumDate={maxDate}
                onChange={(event, date) => {
                  if (Platform.OS === 'android') {
                    setShowDatePicker(false);
                  }
                  if (date) {
                    setSelectedDate(date);
                  }
                }}
              />
              {Platform.OS === 'ios' && (
                <TouchableOpacity
                  style={styles.datePickerDone}
                  onPress={() => setShowDatePicker(false)}
                >
                  <Text style={styles.datePickerDoneText}>Done</Text>
                </TouchableOpacity>
              )}
            </View>
          )}

          {/* Time Slot Selection */}
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Preferred Time</Text>
            <View style={styles.timeSlots}>
              {TIME_SLOTS.map((slot) => (
                <TouchableOpacity
                  key={slot.id}
                  style={[
                    styles.timeSlot,
                    selectedTimeSlot === slot.id && styles.timeSlotSelected,
                  ]}
                  onPress={() => setSelectedTimeSlot(slot.id)}
                >
                  <Text
                    style={[
                      styles.timeSlotLabel,
                      selectedTimeSlot === slot.id &&
                        styles.timeSlotLabelSelected,
                    ]}
                  >
                    {slot.label}
                  </Text>
                  <Text
                    style={[
                      styles.timeSlotDescription,
                      selectedTimeSlot === slot.id &&
                        styles.timeSlotDescriptionSelected,
                    ]}
                  >
                    {slot.description}
                  </Text>
                </TouchableOpacity>
              ))}
            </View>
          </View>

          {/* Contact Phone */}
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Contact Phone (Optional)</Text>
            <TextInput
              style={styles.input}
              placeholder="(555) 123-4567"
              placeholderTextColor={colors.text.tertiary}
              value={contactPhone}
              onChangeText={setContactPhone}
              keyboardType="phone-pad"
            />
          </View>

          {/* Notes */}
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>
              Special Instructions (Optional)
            </Text>
            <TextInput
              style={[styles.input, styles.notesInput]}
              placeholder="Gate code, parking instructions, specific areas of concern..."
              placeholderTextColor={colors.text.tertiary}
              value={notes}
              onChangeText={setNotes}
              multiline
              numberOfLines={3}
              textAlignVertical="top"
            />
          </View>

          {/* Disclaimer */}
          <Text style={styles.disclaimer}>
            We'll contact you within 24-48 hours to confirm your appointment.
            Walkthroughs typically take 60-90 minutes depending on home size.
          </Text>
        </ScrollView>

        {/* Submit Button */}
        <View style={styles.footer}>
          <TouchableOpacity
            style={[styles.submitButton, loading && styles.submitButtonLoading]}
            onPress={handleSubmit}
            disabled={loading}
          >
            {loading ? (
              <ActivityIndicator color={colors.white} />
            ) : (
              <>
                <Ionicons name="checkmark-circle" size={20} color={colors.white} />
                <Text style={styles.submitButtonText}>
                  Request Walkthrough
                </Text>
              </>
            )}
          </TouchableOpacity>
        </View>
      </View>
    </Modal>
  );
}

function IncludeItem({ text }: { text: string }) {
  return (
    <View style={styles.includeItem}>
      <Ionicons
        name="checkmark-circle"
        size={20}
        color={colors.haven.champagne[500]}
      />
      <Text style={styles.includeText}>{text}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background.primary,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    padding: 16,
    borderBottomWidth: 1,
    borderBottomColor: colors.border.light,
  },
  closeButton: {
    padding: 4,
  },
  headerTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: colors.text.primary,
  },
  headerSpacer: {
    width: 32,
  },
  content: {
    flex: 1,
  },
  contentContainer: {
    padding: 20,
    paddingBottom: 40,
  },
  hero: {
    alignItems: 'center',
    marginBottom: 24,
  },
  heroIcon: {
    width: 80,
    height: 80,
    borderRadius: 40,
    backgroundColor: colors.haven.navy[50],
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 16,
  },
  heroTitle: {
    fontSize: 24,
    fontWeight: '700',
    color: colors.text.primary,
    marginBottom: 4,
  },
  heroSubtitle: {
    fontSize: 16,
    color: colors.haven.champagne[600],
    fontWeight: '600',
  },
  section: {
    marginBottom: 24,
  },
  sectionTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: colors.text.primary,
    marginBottom: 12,
  },
  includesList: {
    gap: 12,
  },
  includeItem: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
  },
  includeText: {
    fontSize: 14,
    color: colors.text.secondary,
    flex: 1,
  },
  dateSelector: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.background.secondary,
    borderRadius: 12,
    padding: 16,
    gap: 12,
  },
  dateSelectorText: {
    flex: 1,
    fontSize: 16,
    color: colors.text.primary,
  },
  datePickerContainer: {
    backgroundColor: colors.background.secondary,
    borderRadius: 12,
    marginTop: -16,
    marginBottom: 24,
    overflow: 'hidden',
  },
  datePickerDone: {
    alignItems: 'flex-end',
    padding: 12,
    borderTopWidth: 1,
    borderTopColor: colors.border.light,
  },
  datePickerDoneText: {
    fontSize: 16,
    fontWeight: '600',
    color: colors.haven.champagne[600],
  },
  timeSlots: {
    flexDirection: 'row',
    gap: 12,
  },
  timeSlot: {
    flex: 1,
    backgroundColor: colors.background.secondary,
    borderRadius: 12,
    padding: 16,
    alignItems: 'center',
    borderWidth: 2,
    borderColor: 'transparent',
  },
  timeSlotSelected: {
    borderColor: colors.haven.champagne[500],
    backgroundColor: colors.haven.champagne[50],
  },
  timeSlotLabel: {
    fontSize: 14,
    fontWeight: '600',
    color: colors.text.primary,
    marginBottom: 4,
  },
  timeSlotLabelSelected: {
    color: colors.haven.champagne[700],
  },
  timeSlotDescription: {
    fontSize: 12,
    color: colors.text.tertiary,
  },
  timeSlotDescriptionSelected: {
    color: colors.haven.champagne[600],
  },
  input: {
    backgroundColor: colors.background.secondary,
    borderRadius: 12,
    padding: 16,
    fontSize: 16,
    color: colors.text.primary,
  },
  notesInput: {
    minHeight: 100,
    paddingTop: 16,
  },
  disclaimer: {
    fontSize: 13,
    color: colors.text.tertiary,
    textAlign: 'center',
    lineHeight: 20,
  },
  footer: {
    padding: 16,
    borderTopWidth: 1,
    borderTopColor: colors.border.light,
    backgroundColor: colors.background.primary,
  },
  submitButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: colors.haven.champagne[500],
    paddingVertical: 16,
    borderRadius: 12,
    gap: 8,
  },
  submitButtonLoading: {
    opacity: 0.7,
  },
  submitButtonText: {
    fontSize: 18,
    fontWeight: '600',
    color: colors.white,
  },
});

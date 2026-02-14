import React, { useState, useMemo } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Alert,
} from 'react-native';
import { useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { useSubscription } from '../../../src/contexts/subscription-context';
import { Card, Button, Badge, ScreenContainer } from '../../../src/components';
import { colors, typography, spacing, borderRadius } from '../../../src/lib/theme';
import {
  HANDYMAN_SERVICES,
  HANDYMAN_BASE_PRICE,
  TIME_SLOTS,
  type HandymanService,
  calculateTotalCost,
  calculateEstimatedTime,
} from '../../../src/lib/handyman';

// =============================================================================
// HANDYMAN BOOKING SCREEN
// =============================================================================

export default function HandymanScreen() {
  const router = useRouter();
  const { handymanInfo, tierDetails } = useSubscription();
  const [selectedServices, setSelectedServices] = useState<string[]>([]);
  const [selectedTimeSlot, setSelectedTimeSlot] = useState<string | null>(null);
  const [notes, setNotes] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);

  const toggleService = (serviceId: string) => {
    setSelectedServices(prev =>
      prev.includes(serviceId)
        ? prev.filter(id => id !== serviceId)
        : [...prev, serviceId]
    );
  };

  const handleBook = async () => {
    if (selectedServices.length === 0) {
      Alert.alert('Select Services', 'Please select at least one service');
      return;
    }

    if (!selectedTimeSlot) {
      Alert.alert('Select Time', 'Please select a preferred time slot');
      return;
    }

    setIsSubmitting(true);

    // Simulate booking API call
    setTimeout(() => {
      setIsSubmitting(false);
      Alert.alert(
        'Handyman Booked!',
        'Alfred will coordinate with our handyman and confirm your appointment.',
        [
          {
            text: 'OK',
            onPress: () => router.back(),
          },
        ]
      );
    }, 1500);
  };

  return (
    <ScreenContainer title="Service Request" scrollable={false}>
      <ScrollView
        contentContainerStyle={styles.scrollContent}
        showsVerticalScrollIndicator={false}
      >
        {/* Pricing Info */}
        <Card style={styles.pricingCard}>
          <View style={styles.pricingHeader}>
            <Ionicons name="construct" size={24} color={colors.haven.purple[500]} />
            <View style={styles.pricingInfo}>
              <Text style={styles.pricingTitle}>On-Demand Handyman</Text>
              <Text style={styles.pricingDescription}>
                {handymanInfo.hasIncluded
                  ? `${handymanInfo.hoursIncluded} hours included with your ${tierDetails.name} plan`
                  : `$${handymanInfo.pricePerHour}/visit (covers most tasks)`}
              </Text>
            </View>
          </View>
          {handymanInfo.hasIncluded && (
            <View style={styles.includedBadge}>
              <Ionicons name="checkmark-circle" size={16} color={colors.status.success} />
              <Text style={styles.includedText}>Included in your plan</Text>
            </View>
          )}
        </Card>

        {/* Services */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>What do you need help with?</Text>
          <Text style={styles.sectionSubtitle}>Select all that apply</Text>

          {HANDYMAN_SERVICES.slice(0, 10).map(service => {
            const isSelected = selectedServices.includes(service.id);
            return (
              <TouchableOpacity
                key={service.id}
                style={[styles.serviceCard, isSelected && styles.serviceCardSelected]}
                onPress={() => toggleService(service.id)}
                activeOpacity={0.7}
              >
                <View
                  style={[
                    styles.serviceIcon,
                    isSelected && styles.serviceIconSelected,
                  ]}
                >
                  <Ionicons
                    name={service.icon}
                    size={24}
                    color={isSelected ? colors.white : colors.haven.purple[500]}
                  />
                </View>
                <View style={styles.serviceInfo}>
                  <Text style={styles.serviceName}>{service.name}</Text>
                  <Text style={styles.serviceDescription}>{service.description}</Text>
                  <View style={styles.serviceMeta}>
                    <Text style={styles.serviceDuration}>
                      <Ionicons name="time-outline" size={12} color={colors.text.tertiary} />{' '}
                      {service.estimatedTime}
                    </Text>
                    {service.additionalCost ? (
                      <Badge label={`+$${service.additionalCost}`} variant="warning" size="sm" />
                    ) : (
                      <Badge label="Included" variant="success" size="sm" />
                    )}
                  </View>
                </View>
                <View
                  style={[styles.checkbox, isSelected && styles.checkboxSelected]}
                >
                  {isSelected && (
                    <Ionicons name="checkmark" size={16} color={colors.white} />
                  )}
                </View>
              </TouchableOpacity>
            );
          })}
        </View>

        {/* Time Preference */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Preferred Time</Text>

          <View style={styles.timeSlots}>
            {TIME_SLOTS.map(slot => {
              const isSelected = selectedTimeSlot === slot.id;
              return (
                <TouchableOpacity
                  key={slot.id}
                  style={[styles.timeSlot, isSelected && styles.timeSlotSelected]}
                  onPress={() => setSelectedTimeSlot(slot.id)}
                >
                  <Text
                    style={[
                      styles.timeSlotLabel,
                      isSelected && styles.timeSlotLabelSelected,
                    ]}
                  >
                    {slot.label}
                  </Text>
                  <Text
                    style={[
                      styles.timeSlotTime,
                      isSelected && styles.timeSlotTimeSelected,
                    ]}
                  >
                    {slot.timeRange}
                  </Text>
                </TouchableOpacity>
              );
            })}
          </View>
        </View>

        {/* How it Works */}
        <Card style={styles.howItWorksCard}>
          <Text style={styles.howItWorksTitle}>How it works</Text>
          <View style={styles.step}>
            <View style={styles.stepNumber}>
              <Text style={styles.stepNumberText}>1</Text>
            </View>
            <Text style={styles.stepText}>Select services and preferred time</Text>
          </View>
          <View style={styles.step}>
            <View style={styles.stepNumber}>
              <Text style={styles.stepNumberText}>2</Text>
            </View>
            <Text style={styles.stepText}>Alfred schedules with our trusted handyman</Text>
          </View>
          <View style={styles.step}>
            <View style={styles.stepNumber}>
              <Text style={styles.stepNumberText}>3</Text>
            </View>
            <Text style={styles.stepText}>Get confirmation and reminders</Text>
          </View>
        </Card>
      </ScrollView>

      {/* Footer */}
      <View style={styles.footer}>
        <View style={styles.footerInfo}>
          <Text style={styles.footerServices}>
            {selectedServices.length} service{selectedServices.length !== 1 ? 's' : ''}{' '}
            selected
          </Text>
          {!handymanInfo.hasIncluded && selectedServices.length > 0 && (
            <Text style={styles.footerPrice}>${calculateTotalCost(selectedServices)}</Text>
          )}
          {handymanInfo.hasIncluded && selectedServices.length > 0 && (
            <Text style={styles.footerIncluded}>Included in plan</Text>
          )}
        </View>
        <Button
          title={isSubmitting ? 'Booking...' : 'Book Handyman'}
          onPress={handleBook}
          loading={isSubmitting}
          disabled={isSubmitting || selectedServices.length === 0 || !selectedTimeSlot}
          style={styles.bookButton}
        />
      </View>
    </ScreenContainer>
  );
}

// =============================================================================
// STYLES
// =============================================================================

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background.secondary,
  },
  scrollContent: {
    padding: spacing[4],
    paddingBottom: spacing[8],
  },
  pricingCard: {
    padding: spacing[4],
    marginBottom: spacing[4],
  },
  pricingHeader: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  pricingInfo: {
    flex: 1,
    marginLeft: spacing[3],
  },
  pricingTitle: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
  },
  pricingDescription: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    marginTop: spacing[1],
  },
  includedBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.status.successLight,
    paddingHorizontal: spacing[3],
    paddingVertical: spacing[2],
    borderRadius: borderRadius.lg,
    marginTop: spacing[3],
    gap: spacing[2],
  },
  includedText: {
    fontSize: typography.fontSizes.sm,
    color: colors.status.success,
    fontWeight: typography.fontWeights.medium,
  },
  section: {
    marginBottom: spacing[5],
  },
  sectionTitle: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
    marginBottom: spacing[1],
  },
  sectionSubtitle: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    marginBottom: spacing[3],
  },
  serviceCard: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.white,
    padding: spacing[4],
    borderRadius: borderRadius.xl,
    marginBottom: spacing[2],
    borderWidth: 2,
    borderColor: colors.border.light,
  },
  serviceCardSelected: {
    borderColor: colors.haven.purple[500],
    backgroundColor: colors.haven.purple[50],
  },
  serviceIcon: {
    width: 48,
    height: 48,
    borderRadius: borderRadius.lg,
    backgroundColor: colors.haven.purple[50],
    alignItems: 'center',
    justifyContent: 'center',
  },
  serviceIconSelected: {
    backgroundColor: colors.haven.purple[500],
  },
  serviceInfo: {
    flex: 1,
    marginLeft: spacing[3],
  },
  serviceName: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.primary,
  },
  serviceDescription: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    marginTop: spacing[0.5],
  },
  serviceMeta: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: spacing[2],
    gap: spacing[3],
  },
  serviceDuration: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
  },
  checkbox: {
    width: 24,
    height: 24,
    borderRadius: 12,
    borderWidth: 2,
    borderColor: colors.border.default,
    alignItems: 'center',
    justifyContent: 'center',
  },
  checkboxSelected: {
    backgroundColor: colors.haven.purple[500],
    borderColor: colors.haven.purple[500],
  },
  timeSlots: {
    flexDirection: 'row',
    gap: spacing[2],
  },
  timeSlot: {
    flex: 1,
    alignItems: 'center',
    padding: spacing[3],
    backgroundColor: colors.white,
    borderRadius: borderRadius.xl,
    borderWidth: 2,
    borderColor: colors.border.light,
  },
  timeSlotSelected: {
    borderColor: colors.haven.purple[500],
    backgroundColor: colors.haven.purple[50],
  },
  timeSlotLabel: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
  },
  timeSlotLabelSelected: {
    color: colors.haven.purple[600],
  },
  timeSlotTime: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
    marginTop: spacing[1],
  },
  timeSlotTimeSelected: {
    color: colors.haven.purple[500],
  },
  howItWorksCard: {
    padding: spacing[4],
  },
  howItWorksTitle: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.secondary,
    marginBottom: spacing[3],
  },
  step: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: spacing[3],
  },
  stepNumber: {
    width: 24,
    height: 24,
    borderRadius: 12,
    backgroundColor: colors.haven.purple[100],
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: spacing[3],
  },
  stepNumberText: {
    fontSize: typography.fontSizes.xs,
    fontWeight: typography.fontWeights.semibold,
    color: colors.haven.purple[600],
  },
  stepText: {
    flex: 1,
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
  },
  footer: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: spacing[4],
    backgroundColor: colors.white,
    borderTopWidth: 1,
    borderTopColor: colors.border.light,
  },
  footerInfo: {
    flex: 1,
  },
  footerServices: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
  },
  footerPrice: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.semibold,
    color: colors.haven.purple[900],
  },
  footerIncluded: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.status.success,
  },
  bookButton: {
    flex: 0,
    paddingHorizontal: spacing[6],
  },
});

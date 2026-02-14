import React, { useState, useMemo } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  TextInput,
  Alert,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useRouter, Stack } from 'expo-router';
import { askAlfredForHandyman } from '../../src/lib/navigation';
import { Ionicons } from '@expo/vector-icons';
import { Card, Button, Badge } from '../../src/components';
import { colors, typography, spacing, borderRadius } from '../../src/lib/theme';
import {
  HANDYMAN_SERVICES,
  HANDYMAN_BASE_PRICE,
  HANDYMAN_CATEGORY_INFO,
  TIME_SLOTS,
  type HandymanService,
  type HandymanCategory,
  calculateTotalCost,
  calculateEstimatedTime,
  getAvailableDates,
  formatBookingDate,
} from '../../src/lib/handyman';

// =============================================================================
// BOOK HANDYMAN SCREEN
// =============================================================================

export default function BookHandymanScreen() {
  const router = useRouter();
  const [selectedServices, setSelectedServices] = useState<Set<string>>(new Set());
  const [selectedDate, setSelectedDate] = useState<Date | null>(null);
  const [selectedTimeSlot, setSelectedTimeSlot] = useState<string | null>(null);
  const [notes, setNotes] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [selectedCategory, setSelectedCategory] = useState<HandymanCategory | 'all'>('all');

  // Available dates
  const availableDates = useMemo(() => getAvailableDates(), []);

  // Filter services by category
  const filteredServices = useMemo(() => {
    if (selectedCategory === 'all') {
      return HANDYMAN_SERVICES;
    }
    return HANDYMAN_SERVICES.filter(s => s.category === selectedCategory);
  }, [selectedCategory]);

  // Group services by category
  const groupedServices = useMemo(() => {
    const groups: Record<HandymanCategory, HandymanService[]> = {
      hvac: [],
      plumbing: [],
      electrical: [],
      carpentry: [],
      exterior: [],
      general: [],
    };

    filteredServices.forEach(service => {
      groups[service.category].push(service);
    });

    return Object.entries(groups).filter(([_, services]) => services.length > 0);
  }, [filteredServices]);

  // Calculate totals
  const totalCost = useMemo(
    () => calculateTotalCost(Array.from(selectedServices)),
    [selectedServices]
  );

  const estimatedTime = useMemo(
    () => calculateEstimatedTime(Array.from(selectedServices)),
    [selectedServices]
  );

  const toggleService = (serviceId: string) => {
    setSelectedServices(prev => {
      const newSet = new Set(prev);
      if (newSet.has(serviceId)) {
        newSet.delete(serviceId);
      } else {
        newSet.add(serviceId);
      }
      return newSet;
    });
  };

  const handleBook = async () => {
    if (selectedServices.size === 0) {
      Alert.alert('Select Services', 'Please select at least one service.');
      return;
    }

    if (!selectedDate) {
      Alert.alert('Select Date', 'Please select a preferred date.');
      return;
    }

    if (!selectedTimeSlot) {
      Alert.alert('Select Time', 'Please select a preferred time slot.');
      return;
    }

    setIsSubmitting(true);

    try {
      // TODO: Implement booking API call
      // For now, simulate API call
      await new Promise(resolve => setTimeout(resolve, 1500));

      Alert.alert(
        'Booking Submitted!',
        'Alfred will coordinate with our handyman and send you confirmation details within 24 hours.',
        [
          {
            text: 'OK',
            onPress: () => router.back(),
          },
        ]
      );
    } catch (error) {
      Alert.alert('Error', 'Failed to submit booking. Please try again.');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleAskAlfred = () => {
    askAlfredForHandyman();
  };

  // =============================================================================
  // RENDER
  // =============================================================================

  const renderServiceItem = (service: HandymanService) => {
    const isSelected = selectedServices.has(service.id);

    return (
      <TouchableOpacity
        key={service.id}
        style={[styles.serviceCard, isSelected && styles.serviceCardSelected]}
        onPress={() => toggleService(service.id)}
        activeOpacity={0.7}
      >
        <View
          style={[styles.serviceIcon, isSelected && styles.serviceIconSelected]}
        >
          <Ionicons
            name={service.icon}
            size={24}
            color={isSelected ? colors.white : colors.haven.purple[500]}
          />
        </View>

        <View style={styles.serviceContent}>
          <Text style={styles.serviceName}>{service.name}</Text>
          <Text style={styles.serviceDescription}>{service.description}</Text>

          <View style={styles.serviceMeta}>
            <View style={styles.serviceTime}>
              <Ionicons
                name="time-outline"
                size={12}
                color={colors.text.tertiary}
              />
              <Text style={styles.serviceTimeText}>{service.estimatedTime}</Text>
            </View>

            {service.additionalCost ? (
              <Badge
                label={`+$${service.additionalCost}`}
                variant="warning"
                size="sm"
              />
            ) : (
              <Badge label="Included" variant="success" size="sm" />
            )}
          </View>
        </View>

        <View style={[styles.checkbox, isSelected && styles.checkboxSelected]}>
          {isSelected && (
            <Ionicons name="checkmark" size={16} color={colors.white} />
          )}
        </View>
      </TouchableOpacity>
    );
  };

  return (
    <SafeAreaView style={styles.container} edges={['bottom']}>
      <Stack.Screen
        options={{
          title: 'Book Handyman',
          headerRight: () => (
            <TouchableOpacity onPress={handleAskAlfred} style={styles.headerButton}>
              <Ionicons
                name="sparkles"
                size={24}
                color={colors.haven.purple[500]}
              />
            </TouchableOpacity>
          ),
        }}
      />

      <ScrollView
        contentContainerStyle={styles.scrollContent}
        showsVerticalScrollIndicator={false}
      >
        {/* Header */}
        <View style={styles.header}>
          <View style={styles.headerIcon}>
            <Ionicons name="hammer" size={32} color={colors.haven.purple[500]} />
          </View>
          <View style={styles.headerContent}>
            <Text style={styles.headerTitle}>On-Demand Handyman</Text>
            <Text style={styles.headerSubtitle}>
              ${HANDYMAN_BASE_PRICE} base visit • Most tasks included
            </Text>
          </View>
        </View>

        {/* Category Filter */}
        <View style={styles.categoryFilter}>
          <ScrollView
            horizontal
            showsHorizontalScrollIndicator={false}
            contentContainerStyle={styles.categoryContent}
          >
            <TouchableOpacity
              style={[
                styles.categoryChip,
                selectedCategory === 'all' && styles.categoryChipSelected,
              ]}
              onPress={() => setSelectedCategory('all')}
            >
              <Ionicons
                name="apps-outline"
                size={16}
                color={selectedCategory === 'all' ? colors.white : colors.text.secondary}
              />
              <Text
                style={[
                  styles.categoryChipText,
                  selectedCategory === 'all' && styles.categoryChipTextSelected,
                ]}
              >
                All
              </Text>
            </TouchableOpacity>

            {(Object.keys(HANDYMAN_CATEGORY_INFO) as HandymanCategory[]).map(cat => {
              const info = HANDYMAN_CATEGORY_INFO[cat];
              return (
                <TouchableOpacity
                  key={cat}
                  style={[
                    styles.categoryChip,
                    selectedCategory === cat && styles.categoryChipSelected,
                  ]}
                  onPress={() => setSelectedCategory(cat)}
                >
                  <Ionicons
                    name={info.icon}
                    size={16}
                    color={
                      selectedCategory === cat ? colors.white : colors.text.secondary
                    }
                  />
                  <Text
                    style={[
                      styles.categoryChipText,
                      selectedCategory === cat && styles.categoryChipTextSelected,
                    ]}
                  >
                    {info.label}
                  </Text>
                </TouchableOpacity>
              );
            })}
          </ScrollView>
        </View>

        {/* Services */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>What do you need done?</Text>
          <Text style={styles.sectionSubtitle}>Select all that apply</Text>

          {selectedCategory === 'all' ? (
            // Show grouped by category
            groupedServices.map(([category, services]) => (
              <View key={category} style={styles.categoryGroup}>
                <Text style={styles.categoryLabel}>
                  {HANDYMAN_CATEGORY_INFO[category as HandymanCategory].label}
                </Text>
                {services.map(renderServiceItem)}
              </View>
            ))
          ) : (
            // Show filtered services
            filteredServices.map(renderServiceItem)
          )}
        </View>

        {/* Other Request */}
        <TouchableOpacity style={styles.otherRequest} onPress={handleAskAlfred}>
          <Ionicons
            name="chatbubble-ellipses-outline"
            size={24}
            color={colors.haven.purple[900]}
          />
          <View style={styles.otherRequestContent}>
            <Text style={styles.otherRequestText}>Something else?</Text>
            <Text style={styles.otherRequestSubtext}>Ask Alfred for custom requests</Text>
          </View>
          <Ionicons name="chevron-forward" size={20} color={colors.text.tertiary} />
        </TouchableOpacity>

        {/* Date Selection */}
        {selectedServices.size > 0 && (
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Preferred Date</Text>

            <ScrollView
              horizontal
              showsHorizontalScrollIndicator={false}
              contentContainerStyle={styles.dateScroll}
            >
              {availableDates.map(date => {
                const isSelected =
                  selectedDate?.toDateString() === date.toDateString();
                const dayName = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'][
                  date.getDay()
                ];

                return (
                  <TouchableOpacity
                    key={date.toISOString()}
                    style={[styles.dateCard, isSelected && styles.dateCardSelected]}
                    onPress={() => setSelectedDate(date)}
                  >
                    <Text
                      style={[
                        styles.dateDayName,
                        isSelected && styles.dateDayNameSelected,
                      ]}
                    >
                      {dayName}
                    </Text>
                    <Text
                      style={[
                        styles.dateDay,
                        isSelected && styles.dateDaySelected,
                      ]}
                    >
                      {date.getDate()}
                    </Text>
                  </TouchableOpacity>
                );
              })}
            </ScrollView>
          </View>
        )}

        {/* Time Selection */}
        {selectedServices.size > 0 && selectedDate && (
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Preferred Time</Text>

            <View style={styles.timeSlots}>
              {TIME_SLOTS.map(slot => {
                const isSelected = selectedTimeSlot === slot.id;

                return (
                  <TouchableOpacity
                    key={slot.id}
                    style={[
                      styles.timeSlot,
                      isSelected && styles.timeSlotSelected,
                    ]}
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
        )}

        {/* Notes */}
        {selectedServices.size > 0 && (
          <Card style={styles.notesCard}>
            <Text style={styles.notesLabel}>Additional Notes (Optional)</Text>
            <TextInput
              style={styles.notesInput}
              placeholder="Any special instructions or access details..."
              placeholderTextColor={colors.text.tertiary}
              value={notes}
              onChangeText={setNotes}
              multiline
              numberOfLines={3}
              maxLength={300}
            />
          </Card>
        )}

        {/* Pricing Summary */}
        {selectedServices.size > 0 && (
          <Card style={styles.pricingCard}>
            <Text style={styles.pricingTitle}>Summary</Text>

            <View style={styles.priceRow}>
              <Text style={styles.priceLabel}>
                Base visit ({selectedServices.size} task
                {selectedServices.size !== 1 ? 's' : ''})
              </Text>
              <Text style={styles.priceValue}>${HANDYMAN_BASE_PRICE}</Text>
            </View>

            {Array.from(selectedServices).map(id => {
              const service = HANDYMAN_SERVICES.find(s => s.id === id);
              if (service?.additionalCost) {
                return (
                  <View key={id} style={styles.priceRow}>
                    <Text style={styles.priceLabel}>{service.name}</Text>
                    <Text style={styles.priceValue}>
                      +${service.additionalCost}
                    </Text>
                  </View>
                );
              }
              return null;
            })}

            <View style={styles.priceDivider} />

            <View style={styles.priceRow}>
              <Text style={styles.totalLabel}>Total</Text>
              <Text style={styles.totalValue}>${totalCost}</Text>
            </View>

            <View style={styles.estimatedTime}>
              <Ionicons name="time-outline" size={16} color={colors.text.secondary} />
              <Text style={styles.estimatedTimeText}>
                Estimated time: {estimatedTime}
              </Text>
            </View>
          </Card>
        )}

        {/* Info Box */}
        <View style={styles.infoBox}>
          <Ionicons
            name="information-circle"
            size={20}
            color={colors.haven.purple[400]}
          />
          <Text style={styles.infoText}>
            Alfred will find an available handyman and confirm the appointment with
            you. Most visits can be scheduled within 48-72 hours.
          </Text>
        </View>
      </ScrollView>

      {/* Footer */}
      <View style={styles.footer}>
        <View style={styles.footerInfo}>
          {selectedServices.size > 0 ? (
            <>
              <Text style={styles.footerTotal}>${totalCost}</Text>
              <Text style={styles.footerTasks}>
                {selectedServices.size} task{selectedServices.size !== 1 ? 's' : ''}
              </Text>
            </>
          ) : (
            <Text style={styles.footerPlaceholder}>Select services</Text>
          )}
        </View>
        <Button
          title={
            isSubmitting
              ? 'Booking...'
              : selectedServices.size === 0
              ? 'Select Services'
              : 'Book Handyman'
          }
          onPress={handleBook}
          loading={isSubmitting}
          disabled={
            isSubmitting ||
            selectedServices.size === 0 ||
            !selectedDate ||
            !selectedTimeSlot
          }
          style={styles.bookButton}
        />
      </View>
    </SafeAreaView>
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
  headerButton: {
    padding: spacing[2],
  },
  scrollContent: {
    padding: spacing[4],
    paddingBottom: spacing[24],
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.white,
    padding: spacing[4],
    borderRadius: borderRadius.xl,
    marginBottom: spacing[4],
  },
  headerIcon: {
    width: 64,
    height: 64,
    borderRadius: borderRadius.xl,
    backgroundColor: colors.haven.purple[50],
    alignItems: 'center',
    justifyContent: 'center',
  },
  headerContent: {
    flex: 1,
    marginLeft: spacing[4],
  },
  headerTitle: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.bold,
    color: colors.text.primary,
  },
  headerSubtitle: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    marginTop: spacing[1],
  },
  categoryFilter: {
    marginBottom: spacing[4],
  },
  categoryContent: {
    gap: spacing[2],
  },
  categoryChip: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: spacing[2],
    paddingHorizontal: spacing[3],
    borderRadius: borderRadius.full,
    backgroundColor: colors.white,
    gap: spacing[1],
  },
  categoryChipSelected: {
    backgroundColor: colors.haven.purple[500],
  },
  categoryChipText: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    fontWeight: typography.fontWeights.medium,
  },
  categoryChipTextSelected: {
    color: colors.white,
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
  categoryGroup: {
    marginBottom: spacing[4],
  },
  categoryLabel: {
    fontSize: typography.fontSizes.xs,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.tertiary,
    textTransform: 'uppercase',
    marginBottom: spacing[2],
    marginLeft: spacing[1],
  },
  serviceCard: {
    flexDirection: 'row',
    alignItems: 'flex-start',
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
  serviceContent: {
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
    lineHeight: 20,
  },
  serviceMeta: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: spacing[2],
    gap: spacing[3],
  },
  serviceTime: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[1],
  },
  serviceTimeText: {
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
    marginTop: spacing[1],
  },
  checkboxSelected: {
    backgroundColor: colors.haven.purple[500],
    borderColor: colors.haven.purple[500],
  },
  otherRequest: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.haven.purple[50],
    padding: spacing[4],
    borderRadius: borderRadius.xl,
    marginBottom: spacing[5],
  },
  otherRequestContent: {
    flex: 1,
    marginLeft: spacing[3],
  },
  otherRequestText: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.medium,
    color: colors.haven.purple[900],
  },
  otherRequestSubtext: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    marginTop: spacing[0.5],
  },
  dateScroll: {
    gap: spacing[2],
    paddingVertical: spacing[1],
  },
  dateCard: {
    alignItems: 'center',
    padding: spacing[3],
    borderRadius: borderRadius.xl,
    backgroundColor: colors.white,
    minWidth: 60,
    borderWidth: 2,
    borderColor: colors.border.light,
  },
  dateCardSelected: {
    borderColor: colors.haven.purple[500],
    backgroundColor: colors.haven.purple[50],
  },
  dateDayName: {
    fontSize: typography.fontSizes.xs,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.secondary,
    marginBottom: spacing[1],
  },
  dateDayNameSelected: {
    color: colors.haven.purple[600],
  },
  dateDay: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.bold,
    color: colors.text.primary,
  },
  dateDaySelected: {
    color: colors.haven.purple[600],
  },
  timeSlots: {
    gap: spacing[2],
  },
  timeSlot: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: spacing[4],
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
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.primary,
  },
  timeSlotLabelSelected: {
    color: colors.haven.purple[600],
  },
  timeSlotTime: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
  },
  timeSlotTimeSelected: {
    color: colors.haven.purple[500],
  },
  notesCard: {
    padding: spacing[4],
    marginBottom: spacing[4],
  },
  notesLabel: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.secondary,
    marginBottom: spacing[2],
  },
  notesInput: {
    fontSize: typography.fontSizes.base,
    color: colors.text.primary,
    backgroundColor: colors.gray[50],
    padding: spacing[3],
    borderRadius: borderRadius.lg,
    borderWidth: 1,
    borderColor: colors.border.default,
    minHeight: 80,
    textAlignVertical: 'top',
  },
  pricingCard: {
    padding: spacing[4],
    marginBottom: spacing[4],
  },
  pricingTitle: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.secondary,
    marginBottom: spacing[3],
    textTransform: 'uppercase',
  },
  priceRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: spacing[2],
  },
  priceLabel: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
  },
  priceValue: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.primary,
    fontWeight: typography.fontWeights.medium,
  },
  priceDivider: {
    height: 1,
    backgroundColor: colors.border.light,
    marginVertical: spacing[3],
  },
  totalLabel: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
  },
  totalValue: {
    fontSize: typography.fontSizes.xl,
    fontWeight: typography.fontWeights.bold,
    color: colors.haven.purple[900],
  },
  estimatedTime: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[2],
    marginTop: spacing[3],
    padding: spacing[2],
    backgroundColor: colors.gray[50],
    borderRadius: borderRadius.md,
  },
  estimatedTimeText: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
  },
  infoBox: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    padding: spacing[4],
    backgroundColor: colors.haven.purple[50],
    borderRadius: borderRadius.xl,
    gap: spacing[3],
  },
  infoText: {
    flex: 1,
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    lineHeight: 20,
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
  footerTotal: {
    fontSize: typography.fontSizes.xl,
    fontWeight: typography.fontWeights.bold,
    color: colors.haven.purple[900],
  },
  footerTasks: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
  },
  footerPlaceholder: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.tertiary,
  },
  bookButton: {
    flex: 0,
    minWidth: 150,
  },
});

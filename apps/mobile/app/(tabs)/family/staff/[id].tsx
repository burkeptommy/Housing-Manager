import React, { useState, useEffect, useCallback } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Alert,
  RefreshControl,
  Linking,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useLocalSearchParams, useRouter, Stack } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { useAuth } from '../../../../src/contexts/auth-context';
import { Card, Badge, LoadingSpinner } from '../../../../src/components';
import { colors, typography, spacing, borderRadius } from '../../../../src/lib/theme';
import { API_BASE_URL } from '../../../../src/lib/api';
import { getIdToken } from '../../../../src/lib/firebase';
import { EditStaffContactModal } from '../../../../src/components/forms/EditStaffContactModal';
import { EditEmergencyContactModal } from '../../../../src/components/forms/EditEmergencyContactModal';
import { EditCompensationModal } from '../../../../src/components/forms/EditCompensationModal';
import { EditBenefitsModal } from '../../../../src/components/forms/EditBenefitsModal';

// =============================================================================
// TYPES
// =============================================================================

type StaffRole = 'nanny' | 'housekeeper' | 'gardener' | 'driver' | 'chef' | 'other';
type PayFrequency = 'weekly' | 'biweekly' | 'monthly';
type PayMethod = 'check' | 'direct_deposit' | 'cash' | 'payroll_service';

interface EmergencyContactInfo {
  name?: string | null;
  phone?: string | null;
  relationship?: string | null;
}

interface Employment {
  startDate?: string | null;
  agency?: string | null;
  agencyContact?: string | null;
  agencyPhone?: string | null;
  schedule?: string | null;
  responsibilities?: string[] | null;
}

interface Benefits {
  healthInsurance?: boolean;
  healthInsuranceCost?: number | null;
  dentalInsurance?: boolean;
  paidTimeOff?: number | null;
  sickDays?: number | null;
  holidayPay?: boolean;
}

interface Reimbursements {
  mileage?: boolean;
  mileageRate?: number | null;
  gas?: boolean;
  gasMonthlyLimit?: number | null;
  meals?: boolean;
  mealsMonthlyLimit?: number | null;
  phone?: boolean;
  phoneMonthly?: number | null;
  other?: string | null;
}

interface Compensation {
  payFrequency?: PayFrequency | null;
  payAmount?: number | null;
  payMethod?: PayMethod | null;
  lastPayDate?: string | null;
  benefits?: Benefits;
  reimbursements?: Reimbursements;
}

interface Documents {
  w9OnFile?: boolean;
  i9OnFile?: boolean;
  backgroundCheckDate?: string | null;
  backgroundCheckProvider?: string | null;
  driversLicense?: string | null;
  driversLicenseExpires?: string | null;
  cprCertified?: boolean;
  cprExpires?: string | null;
  firstAidCertified?: boolean;
}

interface StaffDetail {
  id: string;
  firstName: string;
  lastName: string;
  relationship?: string | null;
  role?: StaffRole | null;
  phone?: string | null;
  email?: string | null;
  address?: string | null;
  workSchedule?: string | null;
  startDate?: string | null;
  notes?: string | null;
  emergencyContact?: boolean;
  // Enhanced fields
  staffEmergencyContact?: EmergencyContactInfo;
  employment?: Employment;
  compensation?: Compensation;
  documents?: Documents;
}

// =============================================================================
// HELPER COMPONENTS
// =============================================================================

interface SectionHeaderProps {
  title: string;
  action?: string;
  onAction?: () => void;
}

function SectionHeader({ title, action, onAction }: SectionHeaderProps) {
  return (
    <View style={helperStyles.sectionHeader}>
      <Text style={helperStyles.sectionHeaderText}>{title}</Text>
      {action && onAction && (
        <TouchableOpacity onPress={onAction}>
          <Text style={helperStyles.sectionAction}>{action}</Text>
        </TouchableOpacity>
      )}
    </View>
  );
}

interface InfoRowProps {
  icon: keyof typeof Ionicons.glyphMap;
  label: string;
  value?: string | null;
  onPress?: () => void;
}

function InfoRow({ icon, label, value, onPress }: InfoRowProps) {
  if (!value) return null;
  const content = (
    <View style={helperStyles.infoRow}>
      <Ionicons name={icon} size={18} color={colors.text.tertiary} />
      <View style={helperStyles.infoContent}>
        <Text style={helperStyles.infoLabel}>{label}</Text>
        <Text style={[
          helperStyles.infoValue,
          onPress && helperStyles.linkText,
        ]}>
          {value}
        </Text>
      </View>
    </View>
  );
  if (onPress) {
    return <TouchableOpacity onPress={onPress}>{content}</TouchableOpacity>;
  }
  return content;
}

interface EmptyPromptProps {
  text: string;
  onPress?: () => void;
}

function EmptyPrompt({ text, onPress }: EmptyPromptProps) {
  return (
    <TouchableOpacity style={helperStyles.emptyPrompt} onPress={onPress} disabled={!onPress}>
      <Ionicons name="add-circle-outline" size={20} color={colors.haven.champagne[500]} />
      <Text style={helperStyles.emptyPromptText}>{text}</Text>
    </TouchableOpacity>
  );
}

interface ChecklistRowProps {
  label: string;
  checked?: boolean;
  subtitle?: string;
}

function ChecklistRow({ label, checked, subtitle }: ChecklistRowProps) {
  return (
    <View style={helperStyles.checklistRow}>
      <View style={[
        helperStyles.checklistIcon,
        checked ? helperStyles.checklistIconChecked : helperStyles.checklistIconUnchecked,
      ]}>
        <Ionicons
          name={checked ? 'checkmark' : 'close'}
          size={14}
          color={checked ? colors.white : colors.text.tertiary}
        />
      </View>
      <View style={helperStyles.checklistContent}>
        <Text style={[
          helperStyles.checklistLabel,
          !checked && helperStyles.checklistLabelUnchecked,
        ]}>
          {label}
        </Text>
        {subtitle && (
          <Text style={helperStyles.checklistSubtitle}>{subtitle}</Text>
        )}
      </View>
    </View>
  );
}

const helperStyles = StyleSheet.create({
  sectionHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: spacing[3],
  },
  sectionHeaderText: {
    fontSize: typography.fontSizes.xs,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.tertiary,
    textTransform: 'uppercase',
    letterSpacing: 0.5,
  },
  sectionAction: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.haven.champagne[500],
  },
  infoRow: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    gap: spacing[3],
    paddingVertical: spacing[2],
  },
  infoContent: {
    flex: 1,
  },
  infoLabel: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
    marginBottom: 2,
  },
  infoValue: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.primary,
  },
  linkText: {
    color: colors.haven.champagne[500],
  },
  emptyPrompt: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[2],
    paddingVertical: spacing[3],
  },
  emptyPromptText: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.champagne[500],
  },
  checklistRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[3],
    paddingVertical: spacing[2],
  },
  checklistIcon: {
    width: 24,
    height: 24,
    borderRadius: 12,
    alignItems: 'center',
    justifyContent: 'center',
  },
  checklistIconChecked: {
    backgroundColor: colors.status.success,
  },
  checklistIconUnchecked: {
    backgroundColor: colors.background.secondary,
    borderWidth: 1,
    borderColor: colors.border.light,
  },
  checklistContent: {
    flex: 1,
  },
  checklistLabel: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.primary,
  },
  checklistLabelUnchecked: {
    color: colors.text.tertiary,
  },
  checklistSubtitle: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
    marginTop: 2,
  },
});

export default function StaffDetailScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const router = useRouter();
  const { householdInfo } = useAuth();
  const [staff, setStaff] = useState<StaffDetail | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Modal states
  const [showContactModal, setShowContactModal] = useState(false);
  const [showEmergencyModal, setShowEmergencyModal] = useState(false);
  const [showCompensationModal, setShowCompensationModal] = useState(false);
  const [showBenefitsModal, setShowBenefitsModal] = useState(false);

  const fetchStaff = useCallback(async () => {
    if (!id || !householdInfo?.id) return;

    try {
      const token = await getIdToken(true);
      if (!token) {
        setError('Authentication expired.');
        setIsLoading(false);
        return;
      }

      const response = await fetch(
        `${API_BASE_URL}/family/household/${householdInfo.id}/staff/${id}`,
        {
          headers: {
            Authorization: `Bearer ${token}`,
            'Content-Type': 'application/json',
          },
        }
      );

      if (!response.ok) {
        throw new Error(`Failed to fetch staff: ${response.status}`);
      }

      const data: StaffDetail = await response.json();
      setStaff(data);
      setError(null);
    } catch (err) {
      console.error('Fetch staff error:', err);
      setError('Failed to load staff details.');
    } finally {
      setIsLoading(false);
      setIsRefreshing(false);
    }
  }, [id, householdInfo?.id]);

  useEffect(() => {
    fetchStaff();
  }, [fetchStaff]);

  const handleCall = () => {
    if (staff?.phone) {
      Linking.openURL(`tel:${staff.phone}`);
    }
  };

  const handleEmail = () => {
    if (staff?.email) {
      Linking.openURL(`mailto:${staff.email}`);
    }
  };

  const handleMessage = () => {
    if (staff?.phone) {
      Linking.openURL(`sms:${staff.phone}`);
    }
  };

  const handleDelete = async () => {
    Alert.alert(
      'Remove Staff Member',
      'Are you sure you want to remove this staff member? This cannot be undone.',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Remove',
          style: 'destructive',
          onPress: async () => {
            try {
              const token = await getIdToken(true);
              if (!token) {
                Alert.alert('Error', 'Authentication expired.');
                return;
              }

              const response = await fetch(
                `${API_BASE_URL}/family/household/${householdInfo?.id}/staff/${id}`,
                {
                  method: 'DELETE',
                  headers: {
                    Authorization: `Bearer ${token}`,
                  },
                }
              );

              if (!response.ok) throw new Error('Failed to delete');

              Alert.alert('Removed', 'Staff member has been removed.');
              router.back();
            } catch (err) {
              Alert.alert('Error', 'Failed to remove staff member.');
            }
          },
        },
      ]
    );
  };

  const formatDate = (dateString?: string | null) => {
    if (!dateString) return null;
    return new Date(dateString).toLocaleDateString('en-US', {
      month: 'long',
      day: 'numeric',
      year: 'numeric',
    });
  };

  // Save contact info
  const handleSaveContact = async (data: {
    phone?: string | null;
    email?: string | null;
    address?: string | null;
  }) => {
    const token = await getIdToken(true);
    if (!token) throw new Error('Authentication expired');

    const response = await fetch(
      `${API_BASE_URL}/family/household/${householdInfo?.id}/staff/${id}`,
      {
        method: 'PATCH',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(data),
      }
    );

    if (!response.ok) throw new Error('Failed to save');
    await fetchStaff();
  };

  // Save emergency contact
  const handleSaveEmergencyContact = async (data: {
    emergencyContact?: string | null;
    emergencyContactPhone?: string | null;
    emergencyContactRelationship?: string | null;
  }) => {
    const token = await getIdToken(true);
    if (!token) throw new Error('Authentication expired');

    const response = await fetch(
      `${API_BASE_URL}/family/household/${householdInfo?.id}/staff/${id}`,
      {
        method: 'PATCH',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          emergencyContactName: data.emergencyContact,
          emergencyContactPhone: data.emergencyContactPhone,
          emergencyContactRelationship: data.emergencyContactRelationship,
        }),
      }
    );

    if (!response.ok) throw new Error('Failed to save');
    await fetchStaff();
  };

  // Save compensation
  const handleSaveCompensation = async (data: {
    payAmount?: number | null;
    payFrequency?: string | null;
    paymentMethod?: string | null;
    lastPayDate?: string | null;
  }) => {
    const token = await getIdToken(true);
    if (!token) throw new Error('Authentication expired');

    const response = await fetch(
      `${API_BASE_URL}/family/household/${householdInfo?.id}/staff/${id}`,
      {
        method: 'PATCH',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(data),
      }
    );

    if (!response.ok) throw new Error('Failed to save');
    await fetchStaff();
  };

  // Save benefits
  const handleSaveBenefits = async (data: {
    hasHealthInsurance?: boolean;
    hasDentalInsurance?: boolean;
    paidTimeOffDays?: number | null;
    sickDays?: number | null;
    hasHolidayPay?: boolean;
  }) => {
    const token = await getIdToken(true);
    if (!token) throw new Error('Authentication expired');

    const response = await fetch(
      `${API_BASE_URL}/family/household/${householdInfo?.id}/staff/${id}`,
      {
        method: 'PATCH',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(data),
      }
    );

    if (!response.ok) throw new Error('Failed to save');
    await fetchStaff();
  };

  if (isLoading) {
    return <LoadingSpinner fullScreen message="Loading staff..." />;
  }

  if (error || !staff) {
    return (
      <SafeAreaView style={styles.container} edges={['bottom']}>
        <Stack.Screen options={{ title: 'Staff Member' }} />
        <View style={styles.errorContainer}>
          <Ionicons name="alert-circle" size={48} color={colors.status.error} />
          <Text style={styles.errorTitle}>Unable to Load Staff</Text>
          <Text style={styles.errorText}>{error || 'Staff member not found'}</Text>
          <TouchableOpacity style={styles.retryButton} onPress={fetchStaff}>
            <Text style={styles.retryText}>Try Again</Text>
          </TouchableOpacity>
        </View>
      </SafeAreaView>
    );
  }

  const fullName = `${staff.firstName} ${staff.lastName}`;
  const initials = `${staff.firstName?.[0] || ''}${staff.lastName?.[0] || ''}`;

  // Format currency
  const formatCurrency = (amount?: number | null) => {
    if (!amount) return null;
    return `$${amount.toLocaleString()}`;
  };

  // Format pay frequency
  const formatPayFrequency = (freq?: PayFrequency | null) => {
    if (!freq) return '';
    const labels: Record<PayFrequency, string> = {
      weekly: '/week',
      biweekly: '/2 weeks',
      monthly: '/month',
    };
    return labels[freq] || '';
  };

  // Format pay method
  const formatPayMethod = (method?: PayMethod | null) => {
    if (!method) return null;
    const labels: Record<PayMethod, string> = {
      check: 'Check',
      direct_deposit: 'Direct Deposit',
      cash: 'Cash',
      payroll_service: 'Payroll Service',
    };
    return labels[method] || method;
  };

  // Role display
  const roleLabel = staff.role
    ? staff.role.charAt(0).toUpperCase() + staff.role.slice(1).replace('_', ' ')
    : staff.relationship || 'Staff';

  // Check for compensation data
  const hasCompensationData = staff.compensation?.payAmount;

  // Check for benefits data
  const hasBenefitsData = staff.compensation?.benefits && (
    staff.compensation.benefits.healthInsurance ||
    staff.compensation.benefits.paidTimeOff ||
    staff.compensation.benefits.sickDays ||
    staff.compensation.benefits.holidayPay
  );

  // Check for reimbursements data
  const hasReimbursementsData = staff.compensation?.reimbursements && (
    staff.compensation.reimbursements.gas ||
    staff.compensation.reimbursements.mileage ||
    staff.compensation.reimbursements.meals ||
    staff.compensation.reimbursements.phone
  );

  return (
    <SafeAreaView style={styles.container} edges={['bottom']}>
      <Stack.Screen
        options={{
          title: 'Staff Member',
          headerRight: () => (
            <TouchableOpacity onPress={() => router.push(`/(tabs)/family/staff/edit/${id}` as any)}>
              <Ionicons name="create-outline" size={24} color={colors.haven.champagne[500]} />
            </TouchableOpacity>
          ),
        }}
      />
      <ScrollView
        contentContainerStyle={styles.scrollContent}
        refreshControl={
          <RefreshControl
            refreshing={isRefreshing}
            onRefresh={() => {
              setIsRefreshing(true);
              fetchStaff();
            }}
          />
        }
      >
        {/* Profile Header */}
        <Card style={styles.profileCard}>
          <View style={styles.avatar}>
            <Text style={styles.avatarText}>{initials}</Text>
          </View>
          <Text style={styles.fullName}>{fullName}</Text>
          <View style={styles.badgeRow}>
            <Badge label={roleLabel} variant="default" />
            {staff.emergencyContact && (
              <Badge label="Emergency Contact" variant="warning" />
            )}
          </View>
        </Card>

        {/* Contact Actions */}
        {(staff.phone || staff.email) && (
          <View style={styles.actionButtons}>
            {staff.phone && (
              <TouchableOpacity style={styles.actionButton} onPress={handleCall}>
                <View style={styles.actionIcon}>
                  <Ionicons name="call" size={24} color={colors.haven.champagne[500]} />
                </View>
                <Text style={styles.actionButtonText}>Call</Text>
              </TouchableOpacity>
            )}
            {staff.phone && (
              <TouchableOpacity style={styles.actionButton} onPress={handleMessage}>
                <View style={styles.actionIcon}>
                  <Ionicons name="chatbubble" size={24} color={colors.haven.champagne[500]} />
                </View>
                <Text style={styles.actionButtonText}>Message</Text>
              </TouchableOpacity>
            )}
            {staff.email && (
              <TouchableOpacity style={styles.actionButton} onPress={handleEmail}>
                <View style={styles.actionIcon}>
                  <Ionicons name="mail" size={24} color={colors.haven.champagne[500]} />
                </View>
                <Text style={styles.actionButtonText}>Email</Text>
              </TouchableOpacity>
            )}
          </View>
        )}

        {/* Contact Info */}
        <Card style={styles.section}>
          <SectionHeader
            title="CONTACT INFORMATION"
            action="Edit"
            onAction={() => setShowContactModal(true)}
          />
          <InfoRow
            icon="call-outline"
            label="Phone"
            value={staff.phone}
            onPress={staff.phone ? handleCall : undefined}
          />
          <InfoRow
            icon="mail-outline"
            label="Email"
            value={staff.email}
            onPress={staff.email ? handleEmail : undefined}
          />
          <InfoRow icon="location-outline" label="Address" value={staff.address} />
          {!staff.phone && !staff.email && !staff.address && (
            <EmptyPrompt
              text="Add contact information"
              onPress={() => setShowContactModal(true)}
            />
          )}
        </Card>

        {/* Schedule & Employment */}
        <Card style={styles.section}>
          <SectionHeader
            title="SCHEDULE & EMPLOYMENT"
            action="Edit"
            onAction={() => router.push(`/(tabs)/family/staff/edit/${id}` as any)}
          />
          {(staff.workSchedule || staff.employment?.schedule) && (
            <View style={styles.scheduleCard}>
              <Ionicons name="calendar-outline" size={20} color={colors.haven.champagne[500]} />
              <View style={styles.scheduleContent}>
                <Text style={styles.scheduleLabel}>Work Schedule</Text>
                <Text style={styles.scheduleText}>
                  {staff.employment?.schedule || staff.workSchedule}
                </Text>
              </View>
            </View>
          )}
          <InfoRow
            icon="briefcase-outline"
            label="Start Date"
            value={formatDate(staff.employment?.startDate || staff.startDate)}
          />
          {staff.employment?.agency && (
            <View style={styles.agencyCard}>
              <Ionicons name="business-outline" size={20} color={colors.text.tertiary} />
              <View style={styles.agencyContent}>
                <Text style={styles.agencyLabel}>Staffing Agency</Text>
                <Text style={styles.agencyName}>{staff.employment.agency}</Text>
                {staff.employment.agencyContact && (
                  <Text style={styles.agencyContact}>{staff.employment.agencyContact}</Text>
                )}
              </View>
              {staff.employment.agencyPhone && (
                <TouchableOpacity
                  style={styles.agencyCallButton}
                  onPress={() => Linking.openURL(`tel:${staff.employment?.agencyPhone}`)}
                >
                  <Ionicons name="call-outline" size={20} color={colors.haven.champagne[500]} />
                </TouchableOpacity>
              )}
            </View>
          )}
          {staff.employment?.responsibilities && staff.employment.responsibilities.length > 0 && (
            <View style={styles.responsibilitiesSection}>
              <Text style={styles.responsibilitiesLabel}>Responsibilities</Text>
              {staff.employment.responsibilities.map((resp, index) => (
                <View key={index} style={styles.responsibilityRow}>
                  <Text style={styles.responsibilityBullet}>•</Text>
                  <Text style={styles.responsibilityText}>{resp}</Text>
                </View>
              ))}
            </View>
          )}
        </Card>

        {/* Compensation */}
        <Card style={styles.section}>
          <SectionHeader
            title="COMPENSATION"
            action="Edit"
            onAction={() => setShowCompensationModal(true)}
          />
          {hasCompensationData ? (
            <>
              <View style={styles.payCard}>
                <View style={styles.payMain}>
                  <Text style={styles.payAmount}>
                    {formatCurrency(staff.compensation?.payAmount)}
                  </Text>
                  <Text style={styles.payFrequency}>
                    {formatPayFrequency(staff.compensation?.payFrequency)}
                  </Text>
                </View>
                {staff.compensation?.payMethod && (
                  <Text style={styles.payMethod}>
                    via {formatPayMethod(staff.compensation.payMethod)}
                  </Text>
                )}
              </View>
              <InfoRow
                icon="calendar-outline"
                label="Last Pay Date"
                value={formatDate(staff.compensation?.lastPayDate)}
              />
            </>
          ) : (
            <EmptyPrompt
              text="Add compensation details"
              onPress={() => setShowCompensationModal(true)}
            />
          )}
        </Card>

        {/* Benefits You Provide */}
        <Card style={styles.section}>
          <SectionHeader
            title="BENEFITS YOU PROVIDE"
            action="Edit"
            onAction={() => setShowBenefitsModal(true)}
          />
          {hasBenefitsData ? (
            <>
              {staff.compensation?.benefits?.healthInsurance && (
                <View style={styles.benefitRow}>
                  <Ionicons name="medkit-outline" size={18} color={colors.status.success} />
                  <View style={styles.benefitContent}>
                    <Text style={styles.benefitLabel}>Health Insurance</Text>
                    {staff.compensation.benefits.healthInsuranceCost && (
                      <Text style={styles.benefitValue}>
                        {formatCurrency(staff.compensation.benefits.healthInsuranceCost)}/mo contribution
                      </Text>
                    )}
                  </View>
                </View>
              )}
              {staff.compensation?.benefits?.dentalInsurance && (
                <View style={styles.benefitRow}>
                  <Ionicons name="happy-outline" size={18} color={colors.status.success} />
                  <Text style={styles.benefitLabel}>Dental Insurance</Text>
                </View>
              )}
              {staff.compensation?.benefits?.paidTimeOff && (
                <View style={styles.benefitRow}>
                  <Ionicons name="calendar-outline" size={18} color={colors.status.success} />
                  <View style={styles.benefitContent}>
                    <Text style={styles.benefitLabel}>Paid Time Off</Text>
                    <Text style={styles.benefitValue}>
                      {staff.compensation.benefits.paidTimeOff} days/year
                    </Text>
                  </View>
                </View>
              )}
              {staff.compensation?.benefits?.sickDays && (
                <View style={styles.benefitRow}>
                  <Ionicons name="bed-outline" size={18} color={colors.status.success} />
                  <View style={styles.benefitContent}>
                    <Text style={styles.benefitLabel}>Sick Days</Text>
                    <Text style={styles.benefitValue}>
                      {staff.compensation.benefits.sickDays} days/year
                    </Text>
                  </View>
                </View>
              )}
              {staff.compensation?.benefits?.holidayPay && (
                <View style={styles.benefitRow}>
                  <Ionicons name="gift-outline" size={18} color={colors.status.success} />
                  <Text style={styles.benefitLabel}>Holiday Pay</Text>
                </View>
              )}
            </>
          ) : (
            <EmptyPrompt
              text="Add benefits information"
              onPress={() => setShowBenefitsModal(true)}
            />
          )}
        </Card>

        {/* Reimbursements */}
        <Card style={styles.section}>
          <SectionHeader
            title="REIMBURSEMENTS"
            action="Edit"
            onAction={() => router.push(`/(tabs)/family/staff/edit/${id}` as any)}
          />
          {hasReimbursementsData ? (
            <>
              {staff.compensation?.reimbursements?.gas && (
                <View style={styles.reimbursementRow}>
                  <Ionicons name="car-outline" size={18} color={colors.text.tertiary} />
                  <View style={styles.reimbursementContent}>
                    <Text style={styles.reimbursementLabel}>Gas</Text>
                    {staff.compensation.reimbursements.gasMonthlyLimit && (
                      <Text style={styles.reimbursementValue}>
                        Up to {formatCurrency(staff.compensation.reimbursements.gasMonthlyLimit)}/mo
                      </Text>
                    )}
                  </View>
                </View>
              )}
              {staff.compensation?.reimbursements?.mileage && (
                <View style={styles.reimbursementRow}>
                  <Ionicons name="speedometer-outline" size={18} color={colors.text.tertiary} />
                  <View style={styles.reimbursementContent}>
                    <Text style={styles.reimbursementLabel}>Mileage</Text>
                    {staff.compensation.reimbursements.mileageRate && (
                      <Text style={styles.reimbursementValue}>
                        ${staff.compensation.reimbursements.mileageRate}/mile
                      </Text>
                    )}
                  </View>
                </View>
              )}
              {staff.compensation?.reimbursements?.meals && (
                <View style={styles.reimbursementRow}>
                  <Ionicons name="restaurant-outline" size={18} color={colors.text.tertiary} />
                  <View style={styles.reimbursementContent}>
                    <Text style={styles.reimbursementLabel}>Meals</Text>
                    {staff.compensation.reimbursements.mealsMonthlyLimit && (
                      <Text style={styles.reimbursementValue}>
                        Up to {formatCurrency(staff.compensation.reimbursements.mealsMonthlyLimit)}/mo
                      </Text>
                    )}
                  </View>
                </View>
              )}
              {staff.compensation?.reimbursements?.phone && (
                <View style={styles.reimbursementRow}>
                  <Ionicons name="phone-portrait-outline" size={18} color={colors.text.tertiary} />
                  <View style={styles.reimbursementContent}>
                    <Text style={styles.reimbursementLabel}>Phone</Text>
                    {staff.compensation.reimbursements.phoneMonthly && (
                      <Text style={styles.reimbursementValue}>
                        {formatCurrency(staff.compensation.reimbursements.phoneMonthly)}/mo
                      </Text>
                    )}
                  </View>
                </View>
              )}
            </>
          ) : (
            <EmptyPrompt
              text="Add reimbursement policy"
              onPress={() => router.push(`/(tabs)/family/staff/edit/${id}` as any)}
            />
          )}
        </Card>

        {/* Documents & Certifications */}
        <Card style={styles.section}>
          <SectionHeader
            title="DOCUMENTS & CERTIFICATIONS"
            action="Edit"
            onAction={() => router.push(`/(tabs)/family/staff/edit/${id}` as any)}
          />
          <ChecklistRow
            label="W-9 on file"
            checked={staff.documents?.w9OnFile}
          />
          <ChecklistRow
            label="I-9 on file"
            checked={staff.documents?.i9OnFile}
          />
          <ChecklistRow
            label="Background check"
            checked={!!staff.documents?.backgroundCheckDate}
            subtitle={staff.documents?.backgroundCheckDate
              ? `Completed ${formatDate(staff.documents.backgroundCheckDate)}`
              : undefined}
          />
          <ChecklistRow
            label="CPR certified"
            checked={staff.documents?.cprCertified}
            subtitle={staff.documents?.cprExpires
              ? `Expires ${formatDate(staff.documents.cprExpires)}`
              : undefined}
          />
          <ChecklistRow
            label="First Aid certified"
            checked={staff.documents?.firstAidCertified}
          />
          {staff.documents?.driversLicense && (
            <InfoRow
              icon="card-outline"
              label="Driver's License"
              value={staff.documents.driversLicense}
            />
          )}
        </Card>

        {/* Emergency Contact */}
        <Card style={styles.section}>
          <SectionHeader
            title="THEIR EMERGENCY CONTACT"
            action="Edit"
            onAction={() => setShowEmergencyModal(true)}
          />
          {staff.staffEmergencyContact?.name ? (
            <>
              <InfoRow
                icon="person-outline"
                label="Name"
                value={staff.staffEmergencyContact.name}
              />
              <InfoRow
                icon="people-outline"
                label="Relationship"
                value={staff.staffEmergencyContact.relationship}
              />
              <InfoRow
                icon="call-outline"
                label="Phone"
                value={staff.staffEmergencyContact.phone}
                onPress={staff.staffEmergencyContact.phone
                  ? () => Linking.openURL(`tel:${staff.staffEmergencyContact?.phone}`)
                  : undefined}
              />
            </>
          ) : (
            <EmptyPrompt
              text="Add emergency contact"
              onPress={() => setShowEmergencyModal(true)}
            />
          )}
        </Card>

        {/* Notes */}
        {staff.notes && (
          <Card style={styles.section}>
            <SectionHeader title="NOTES" />
            <Text style={styles.notes}>{staff.notes}</Text>
          </Card>
        )}

        {/* Delete Button */}
        <TouchableOpacity style={styles.deleteButton} onPress={handleDelete}>
          <Ionicons name="trash-outline" size={20} color={colors.status.error} />
          <Text style={styles.deleteButtonText}>Remove Staff Member</Text>
        </TouchableOpacity>
      </ScrollView>

      {/* Focused Edit Modals */}
      <EditStaffContactModal
        visible={showContactModal}
        onClose={() => setShowContactModal(false)}
        onSave={handleSaveContact}
        initialData={{
          phone: staff.phone,
          email: staff.email,
          address: staff.address,
        }}
      />

      <EditEmergencyContactModal
        visible={showEmergencyModal}
        onClose={() => setShowEmergencyModal(false)}
        onSave={handleSaveEmergencyContact}
        initialData={{
          emergencyContact: staff.staffEmergencyContact?.name,
          emergencyContactPhone: staff.staffEmergencyContact?.phone,
          emergencyContactRelationship: staff.staffEmergencyContact?.relationship,
        }}
      />

      <EditCompensationModal
        visible={showCompensationModal}
        onClose={() => setShowCompensationModal(false)}
        onSave={handleSaveCompensation}
        initialData={{
          payAmount: staff.compensation?.payAmount,
          payFrequency: staff.compensation?.payFrequency?.toUpperCase() as any,
          paymentMethod: staff.compensation?.payMethod,
          lastPayDate: staff.compensation?.lastPayDate,
        }}
      />

      <EditBenefitsModal
        visible={showBenefitsModal}
        onClose={() => setShowBenefitsModal(false)}
        onSave={handleSaveBenefits}
        initialData={{
          hasHealthInsurance: staff.compensation?.benefits?.healthInsurance,
          hasDentalInsurance: staff.compensation?.benefits?.dentalInsurance,
          paidTimeOffDays: staff.compensation?.benefits?.paidTimeOff,
          sickDays: staff.compensation?.benefits?.sickDays,
          hasHolidayPay: staff.compensation?.benefits?.holidayPay,
        }}
      />
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background.secondary,
  },
  scrollContent: {
    padding: spacing[4],
    paddingBottom: spacing[8],
  },
  errorContainer: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    padding: spacing[6],
  },
  errorTitle: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
    marginTop: spacing[4],
  },
  errorText: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    textAlign: 'center',
    marginTop: spacing[2],
  },
  retryButton: {
    marginTop: spacing[4],
    paddingHorizontal: spacing[6],
    paddingVertical: spacing[3],
    backgroundColor: colors.haven.champagne[500],
    borderRadius: borderRadius.lg,
  },
  retryText: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
    color: colors.white,
  },
  // Profile Card
  profileCard: {
    alignItems: 'center',
    padding: spacing[6],
    marginBottom: spacing[4],
  },
  avatar: {
    width: 80,
    height: 80,
    borderRadius: 40,
    backgroundColor: colors.haven.champagne[100],
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: spacing[3],
  },
  avatarText: {
    fontSize: typography.fontSizes['2xl'],
    fontWeight: typography.fontWeights.bold,
    color: colors.haven.champagne[600],
  },
  fullName: {
    fontSize: typography.fontSizes.xl,
    fontWeight: typography.fontWeights.bold,
    color: colors.text.primary,
    marginBottom: spacing[2],
  },
  badgeRow: {
    flexDirection: 'row',
    gap: spacing[2],
  },
  // Action Buttons
  actionButtons: {
    flexDirection: 'row',
    justifyContent: 'center',
    gap: spacing[6],
    marginBottom: spacing[4],
  },
  actionButton: {
    alignItems: 'center',
    gap: spacing[1],
  },
  actionIcon: {
    width: 56,
    height: 56,
    borderRadius: 28,
    backgroundColor: colors.haven.champagne[50],
    alignItems: 'center',
    justifyContent: 'center',
  },
  actionButtonText: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    fontWeight: typography.fontWeights.medium,
  },
  // Section
  section: {
    padding: spacing[4],
    marginBottom: spacing[4],
  },
  // Schedule Card
  scheduleCard: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    gap: spacing[3],
    backgroundColor: colors.haven.champagne[50],
    padding: spacing[4],
    borderRadius: borderRadius.lg,
    marginBottom: spacing[3],
  },
  scheduleContent: {
    flex: 1,
  },
  scheduleLabel: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
    marginBottom: 2,
  },
  scheduleText: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.primary,
  },
  // Agency Card
  agencyCard: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[3],
    paddingVertical: spacing[3],
    borderBottomWidth: 1,
    borderBottomColor: colors.border.light,
  },
  agencyContent: {
    flex: 1,
  },
  agencyLabel: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
    marginBottom: 2,
  },
  agencyName: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.primary,
  },
  agencyContact: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.secondary,
    marginTop: 2,
  },
  agencyCallButton: {
    padding: spacing[2],
  },
  // Responsibilities
  responsibilitiesSection: {
    marginTop: spacing[3],
  },
  responsibilitiesLabel: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
    marginBottom: spacing[2],
  },
  responsibilityRow: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    gap: spacing[2],
    paddingVertical: spacing[1],
  },
  responsibilityBullet: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.tertiary,
  },
  responsibilityText: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.primary,
    flex: 1,
  },
  // Pay Card
  payCard: {
    backgroundColor: colors.haven.navy[50],
    padding: spacing[4],
    borderRadius: borderRadius.lg,
    marginBottom: spacing[3],
  },
  payMain: {
    flexDirection: 'row',
    alignItems: 'baseline',
    gap: spacing[1],
  },
  payAmount: {
    fontSize: typography.fontSizes['2xl'],
    fontWeight: typography.fontWeights.bold,
    color: colors.text.primary,
  },
  payFrequency: {
    fontSize: typography.fontSizes.base,
    color: colors.text.secondary,
  },
  payMethod: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.tertiary,
    marginTop: spacing[1],
  },
  // Benefits
  benefitRow: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    gap: spacing[3],
    paddingVertical: spacing[2],
  },
  benefitContent: {
    flex: 1,
  },
  benefitLabel: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.primary,
  },
  benefitValue: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.secondary,
    marginTop: 2,
  },
  // Reimbursements
  reimbursementRow: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    gap: spacing[3],
    paddingVertical: spacing[2],
  },
  reimbursementContent: {
    flex: 1,
  },
  reimbursementLabel: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.primary,
  },
  reimbursementValue: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.secondary,
    marginTop: 2,
  },
  // Notes
  notes: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    lineHeight: 22,
  },
  // Delete Button
  deleteButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: spacing[2],
    paddingVertical: spacing[4],
    marginTop: spacing[4],
  },
  deleteButtonText: {
    fontSize: typography.fontSizes.base,
    color: colors.status.error,
    fontWeight: typography.fontWeights.medium,
  },
});

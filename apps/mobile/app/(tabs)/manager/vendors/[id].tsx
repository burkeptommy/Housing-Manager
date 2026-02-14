import React, { useState, useEffect, useCallback } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  RefreshControl,
  Alert,
  Linking,
  TextInput,
  Modal,
  Image,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useLocalSearchParams, useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import DateTimePicker from '@react-native-community/datetimepicker';
import { useAuth } from '../../../../src/contexts/auth-context';
import { Card, Badge, LoadingSpinner, Button, AppHeader } from '../../../../src/components';
import { colors, typography, spacing, borderRadius } from '../../../../src/lib/theme';
import { API_BASE_URL } from '../../../../src/lib/api';
import { getIdToken } from '../../../../src/lib/firebase';

// =============================================================================
// TYPES
// =============================================================================

interface VendorActivity {
  id: string;
  type: string;
  title: string;
  description?: string;
  date: string;
  amount?: number;
  isPaid: boolean;
  duration?: number;
  invoiceUrl?: string;
  receiptUrl?: string;
}

interface VendorContact {
  id: string;
  name: string;
  title?: string;
  phone?: string;
  email?: string;
  isPrimary: boolean;
}

interface VendorAccount {
  accountNumber?: string;
  serviceAddress?: string;
  customerSince?: string;
  contractNumber?: string;
}

interface VendorBilling {
  paymentFrequency?: 'monthly' | 'quarterly' | 'annual' | 'per_service' | 'on_demand';
  averageMonthlyBill?: number;
  lastPaymentAmount?: number;
  lastPaymentDate?: string;
  nextPaymentDue?: string;
  autopayEnabled?: boolean;
  paymentMethod?: 'haven' | 'direct' | 'check';
}

interface VendorContract {
  id: string;
  name: string;
  startDate: string;
  endDate?: string;
  value?: number;
  documentUrl?: string;
  autoRenews: boolean;
  renewalNoticeDays?: number;
  notes?: string;
}

// Type-specific data interfaces
interface ElectricVendorData {
  currentRate?: number;
  rateType?: 'fixed' | 'variable' | 'time_of_use';
  ratePlanName?: string;
  rateExpiresAt?: string;
  avgMonthlyUsage?: number;
  budgetBilling?: boolean;
  budgetAmount?: number;
}

interface InternetVendorData {
  planName?: string;
  downloadSpeed?: number;
  uploadSpeed?: number;
  dataCapGB?: number;
  equipmentRental?: number;
  contractEndsAt?: string;
  wifiNetworkName?: string;
}

interface InsuranceVendorData {
  policyType?: string;
  policyNumber?: string;
  coverageAmount?: number;
  deductible?: number;
  premium?: number;
  premiumFrequency?: string;
  renewalDate?: string;
  agentName?: string;
  agentPhone?: string;
}

type VendorTypeSpecificData = ElectricVendorData | InternetVendorData | InsuranceVendorData | Record<string, any>;

interface VendorBillAccount {
  id: string;
  nickname: string;
  category: string;
  accountNumber?: string;
  billingFrequency: string;
  typicalAmount?: number;
  nextDueDate?: string;
  lastPaidDate?: string;
  lastPaidAmount?: number;
  paymentResponsibility: string;
}

interface Vendor {
  id: string;
  displayName: string;
  category: string;
  serviceDescription?: string;
  contactName?: string;
  phone?: string;
  email?: string;
  websiteUrl?: string;
  logoUrl?: string;
  addressLine1?: string;
  addressLine2?: string;
  city?: string;
  state?: string;
  postalCode?: string;
  notes?: string;
  isFavorite?: boolean;
  rating?: number;
  lastContactDate?: string;
  activities?: VendorActivity[];
  activityCount?: number;
  householdVendorId?: string;
  // Enhanced fields
  contacts?: VendorContact[];
  account?: VendorAccount;
  billing?: VendorBilling;
  contracts?: VendorContract[];
  typeSpecificData?: VendorTypeSpecificData;
  billAccounts?: VendorBillAccount[];
}

const ACTIVITY_TYPES = [
  { id: 'SERVICE_CALL', label: 'Service Call', icon: 'construct-outline' },
  { id: 'QUOTE', label: 'Quote', icon: 'document-text-outline' },
  { id: 'PAYMENT', label: 'Payment', icon: 'card-outline' },
  { id: 'PHONE_CALL', label: 'Phone Call', icon: 'call-outline' },
  { id: 'EMAIL', label: 'Email', icon: 'mail-outline' },
  { id: 'SCHEDULED', label: 'Scheduled Visit', icon: 'calendar-outline' },
  { id: 'NOTE', label: 'Note', icon: 'create-outline' },
];

const VENDOR_TYPE_ICONS: Record<string, keyof typeof Ionicons.glyphMap> = {
  electric: 'flash-outline',
  gas: 'flame-outline',
  water: 'water-outline',
  internet: 'wifi-outline',
  cable: 'tv-outline',
  phone: 'call-outline',
  oil_propane: 'flame-outline',
  trash: 'trash-outline',
  landscaping: 'leaf-outline',
  cleaning: 'sparkles-outline',
  pool: 'water-outline',
  hvac: 'thermometer-outline',
  plumbing: 'water-outline',
  electrical: 'flash-outline',
  roofing: 'home-outline',
  pest_control: 'bug-outline',
  security: 'shield-checkmark-outline',
  insurance: 'shield-outline',
  mortgage: 'business-outline',
  other: 'business-outline',
};

const getVendorIcon = (category: string): keyof typeof Ionicons.glyphMap => {
  const normalizedCategory = category.toLowerCase().replace(/[_\s]/g, '_');
  return VENDOR_TYPE_ICONS[normalizedCategory] || 'business-outline';
};

const formatFrequency = (freq?: string): string => {
  const map: Record<string, string> = {
    monthly: 'Monthly',
    quarterly: 'Quarterly',
    annual: 'Annually',
    per_service: 'Per Service',
    on_demand: 'On Demand',
  };
  return freq ? (map[freq] || freq) : '—';
};

const isWithinDays = (dateString: string | undefined, days: number): boolean => {
  if (!dateString) return false;
  const date = new Date(dateString);
  const now = new Date();
  const diff = date.getTime() - now.getTime();
  const diffDays = diff / (1000 * 60 * 60 * 24);
  return diffDays >= 0 && diffDays <= days;
};

const isUtilityType = (category: string): boolean => {
  const utilityTypes = ['electric', 'gas', 'water', 'internet', 'cable', 'phone', 'oil_propane', 'trash'];
  return utilityTypes.includes(category.toLowerCase().replace(/[_\s]/g, '_'));
};

const extractDomain = (url?: string | null): string | null => {
  if (!url) return null;
  try {
    // Handle URLs without protocol
    const urlWithProtocol = url.startsWith('http') ? url : `https://${url}`;
    const parsed = new URL(urlWithProtocol);
    return parsed.hostname.replace('www.', '');
  } catch {
    return null;
  }
};

const getLogoUrl = (domain: string | null): string | null => {
  if (!domain) return null;
  // Use Clearbit Logo API for high-quality logos
  return `https://logo.clearbit.com/${domain}`;
};

// =============================================================================
// COMPONENT
// =============================================================================

export default function VendorDetailScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const router = useRouter();
  const { householdInfo } = useAuth();

  const [vendor, setVendor] = useState<Vendor | null>(null);
  const [activities, setActivities] = useState<VendorActivity[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [showAddActivity, setShowAddActivity] = useState(false);
  const [showRating, setShowRating] = useState(false);

  // Add Activity Form State
  const [activityType, setActivityType] = useState('SERVICE_CALL');
  const [activityTitle, setActivityTitle] = useState('');
  const [activityDescription, setActivityDescription] = useState('');
  const [activityAmount, setActivityAmount] = useState('');
  const [activityDate, setActivityDate] = useState(new Date());
  const [isSubmitting, setIsSubmitting] = useState(false);

  // Edit Contact Modal State
  const [showEditContact, setShowEditContact] = useState(false);
  const [editPhone, setEditPhone] = useState('');
  const [editEmail, setEditEmail] = useState('');
  const [editWebsite, setEditWebsite] = useState('');
  const [editAddress, setEditAddress] = useState('');
  const [editCity, setEditCity] = useState('');
  const [editState, setEditState] = useState('');
  const [editPostalCode, setEditPostalCode] = useState('');
  const [editNotes, setEditNotes] = useState('');
  const [editAccountNumber, setEditAccountNumber] = useState('');
  const [isSavingContact, setIsSavingContact] = useState(false);

  // Logo state - prefer API-provided logoUrl, fallback to client-side extraction
  const [logoError, setLogoError] = useState(false);
  const vendorDomain = vendor ? extractDomain(vendor.websiteUrl) : null;
  const logoUrl = !logoError ? (vendor?.logoUrl || getLogoUrl(vendorDomain)) : null;

  // Reset logo error when vendor website or logo changes
  useEffect(() => {
    setLogoError(false);
  }, [vendor?.websiteUrl, vendor?.logoUrl]);

  const fetchVendor = useCallback(async () => {
    if (!householdInfo?.id || !id) return;

    try {
      const token = await getIdToken(true);
      const response = await fetch(
        `${API_BASE_URL}/vendors/${id}?householdId=${householdInfo.id}`,
        { headers: { Authorization: `Bearer ${token}` } }
      );

      if (response.ok) {
        const data = await response.json();
        setVendor(data);
        setActivities(data.activities || []);
      }
    } catch (err) {
      console.error('Fetch vendor error:', err);
    } finally {
      setIsLoading(false);
      setIsRefreshing(false);
    }
  }, [householdInfo?.id, id]);

  useEffect(() => {
    fetchVendor();
  }, [fetchVendor]);

  const handleCall = () => {
    if (vendor?.phone) {
      Linking.openURL(`tel:${vendor.phone.replace(/[^0-9+]/g, '')}`);
    }
  };

  const handleEmail = () => {
    if (vendor?.email) {
      Linking.openURL(`mailto:${vendor.email}`);
    }
  };

  const handleWebsite = () => {
    if (vendor?.websiteUrl) {
      Linking.openURL(vendor.websiteUrl);
    }
  };

  const handleChat = () => {
    router.push({
      pathname: '/(tabs)/manager',
      params: { prefill: `I need help with my ${vendor?.category?.replace(/_/g, ' ')} vendor ${vendor?.displayName}.` },
    });
  };

  const handleToggleFavorite = async () => {
    if (!vendor || !householdInfo?.id) return;

    try {
      const token = await getIdToken(true);
      await fetch(
        `${API_BASE_URL}/vendors/${id}/toggle-favorite?householdId=${householdInfo.id}`,
        {
          method: 'POST',
          headers: { Authorization: `Bearer ${token}` },
        }
      );
      setVendor({ ...vendor, isFavorite: !vendor.isFavorite });
    } catch (err) {
      console.error('Toggle favorite error:', err);
    }
  };

  const handleSetRating = async (rating: number) => {
    if (!vendor || !householdInfo?.id) return;

    try {
      const token = await getIdToken(true);
      await fetch(
        `${API_BASE_URL}/vendors/${id}/rating?householdId=${householdInfo.id}`,
        {
          method: 'PATCH',
          headers: {
            Authorization: `Bearer ${token}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({ rating }),
        }
      );
      setVendor({ ...vendor, rating });
      setShowRating(false);
    } catch (err) {
      console.error('Set rating error:', err);
    }
  };

  const handleAddActivity = async () => {
    if (!vendor || !householdInfo?.id || !activityTitle.trim()) {
      Alert.alert('Error', 'Please enter an activity title');
      return;
    }

    setIsSubmitting(true);
    try {
      const token = await getIdToken(true);
      const response = await fetch(
        `${API_BASE_URL}/vendors/${id}/activities?householdId=${householdInfo.id}`,
        {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${token}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            type: activityType,
            title: activityTitle.trim(),
            description: activityDescription.trim() || undefined,
            amount: activityAmount ? parseFloat(activityAmount) : undefined,
            date: activityDate.toISOString(),
            isPaid: false,
          }),
        }
      );

      if (response.ok) {
        const newActivity = await response.json();
        setActivities([newActivity, ...activities]);
        setShowAddActivity(false);
        resetActivityForm();
      } else {
        Alert.alert('Error', 'Failed to add activity');
      }
    } catch (err) {
      console.error('Add activity error:', err);
      Alert.alert('Error', 'Failed to add activity');
    } finally {
      setIsSubmitting(false);
    }
  };

  const resetActivityForm = () => {
    setActivityType('SERVICE_CALL');
    setActivityTitle('');
    setActivityDescription('');
    setActivityAmount('');
    setActivityDate(new Date());
  };

  const openEditContact = () => {
    if (vendor) {
      setEditPhone(vendor.phone || '');
      setEditEmail(vendor.email || '');
      setEditWebsite(vendor.websiteUrl || '');
      setEditAddress(vendor.addressLine1 || '');
      setEditCity(vendor.city || '');
      setEditState(vendor.state || '');
      setEditPostalCode(vendor.postalCode || '');
      setEditNotes(vendor.notes || '');
      setEditAccountNumber(vendor.account?.accountNumber || '');
      setShowEditContact(true);
    }
  };

  const handleSaveContact = async () => {
    if (!vendor || !householdInfo?.id) return;

    setIsSavingContact(true);
    try {
      const token = await getIdToken(true);
      const response = await fetch(
        `${API_BASE_URL}/vendors/${id}?householdId=${householdInfo.id}`,
        {
          method: 'PATCH',
          headers: {
            Authorization: `Bearer ${token}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            phone: editPhone.trim() || null,
            email: editEmail.trim() || undefined,
            websiteUrl: editWebsite.trim() || undefined,
            addressLine1: editAddress.trim() || null,
            city: editCity.trim() || null,
            state: editState.trim() || null,
            postalCode: editPostalCode.trim() || null,
            notes: editNotes.trim() || null,
            accountNumber: editAccountNumber.trim() || null,
          }),
        }
      );

      if (response.ok) {
        const updatedVendor = await response.json();
        setVendor(updatedVendor);
        setShowEditContact(false);
        Alert.alert('Success', 'Contact information updated');
      } else {
        Alert.alert('Error', 'Failed to update contact information');
      }
    } catch (err) {
      console.error('Save contact error:', err);
      Alert.alert('Error', 'Failed to update contact information');
    } finally {
      setIsSavingContact(false);
    }
  };

  const handleScheduleService = () => {
    router.push({
      pathname: '/(tabs)/manager/new-request',
      params: { vendorId: id, vendorName: vendor?.displayName },
    });
  };

  const getActivityIcon = (type: string) => {
    return ACTIVITY_TYPES.find(t => t.id === type)?.icon || 'document-outline';
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      month: 'short',
      day: 'numeric',
      year: 'numeric',
    });
  };

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
    }).format(amount);
  };

  const FavoriteButton = () => (
    <TouchableOpacity onPress={handleToggleFavorite}>
      <Ionicons
        name={vendor?.isFavorite ? 'star' : 'star-outline'}
        size={24}
        color={vendor?.isFavorite ? colors.haven.purple[500] : colors.white}
      />
    </TouchableOpacity>
  );

  if (isLoading) {
    return (
      <View style={styles.fullContainer}>
        <AppHeader title="Loading..." showBack />
        <View style={styles.loadingContainer}>
          <LoadingSpinner message="Loading vendor..." />
        </View>
      </View>
    );
  }

  if (!vendor) {
    return (
      <View style={styles.fullContainer}>
        <AppHeader title="Vendor Not Found" showBack />
        <View style={styles.emptyContainer}>
          <Ionicons name="alert-circle-outline" size={48} color={colors.text.tertiary} />
          <Text style={styles.emptyTitle}>Vendor not found</Text>
        </View>
      </View>
    );
  }

  return (
    <View style={styles.fullContainer}>
      <AppHeader
        title={vendor.displayName}
        showBack
        rightAction={<FavoriteButton />}
      />

      <ScrollView
        style={styles.scrollContainer}
        contentContainerStyle={styles.scrollContent}
        refreshControl={
          <RefreshControl
            refreshing={isRefreshing}
            onRefresh={() => {
              setIsRefreshing(true);
              fetchVendor();
            }}
          />
        }
      >
        {/* Header Card */}
        <Card style={styles.headerCard}>
          <View style={styles.vendorHeader}>
            {logoUrl && !logoError ? (
              <View style={styles.vendorLogoContainer}>
                <Image
                  source={{ uri: logoUrl }}
                  style={styles.vendorLogo}
                  onError={() => setLogoError(true)}
                  resizeMode="contain"
                />
              </View>
            ) : (
              <View style={styles.vendorIcon}>
                <Ionicons name={getVendorIcon(vendor.category)} size={32} color={colors.haven.purple[500]} />
              </View>
            )}
            <View style={styles.vendorInfo}>
              <Text style={styles.vendorName}>{vendor.displayName}</Text>
              <Text style={styles.vendorCategory}>
                {vendor.category.replace(/_/g, ' ')}
              </Text>
              {vendor.contactName && (
                <Text style={styles.contactName}>{vendor.contactName}</Text>
              )}
            </View>
          </View>

          {/* Rating */}
          <TouchableOpacity style={styles.ratingRow} onPress={() => setShowRating(true)}>
            <Text style={styles.ratingLabel}>Your Rating:</Text>
            <View style={styles.stars}>
              {[1, 2, 3, 4, 5].map(star => (
                <Ionicons
                  key={star}
                  name={star <= (vendor.rating || 0) ? 'star' : 'star-outline'}
                  size={20}
                  color={colors.haven.purple[500]}
                />
              ))}
            </View>
            <Ionicons name="chevron-forward" size={16} color={colors.text.tertiary} />
          </TouchableOpacity>

          {/* Quick Actions */}
          <View style={styles.quickActions}>
            {vendor.phone && (
              <TouchableOpacity style={styles.actionButton} onPress={handleCall}>
                <Ionicons name="call" size={20} color={colors.white} />
                <Text style={styles.actionText}>Call</Text>
              </TouchableOpacity>
            )}
            {vendor.email && (
              <TouchableOpacity style={styles.actionButton} onPress={handleEmail}>
                <Ionicons name="mail" size={20} color={colors.white} />
                <Text style={styles.actionText}>Email</Text>
              </TouchableOpacity>
            )}
            <TouchableOpacity style={styles.actionButton} onPress={handleChat}>
              <Ionicons name="chatbubble" size={20} color={colors.white} />
              <Text style={styles.actionText}>Message</Text>
            </TouchableOpacity>
          </View>

          {/* Schedule Button */}
          <TouchableOpacity style={styles.scheduleButton} onPress={handleScheduleService}>
            <Ionicons name="calendar" size={20} color={colors.haven.purple[700]} />
            <Text style={styles.scheduleText}>Schedule Service</Text>
          </TouchableOpacity>
        </Card>

        {/* Contact Info */}
        <Card style={styles.sectionCard}>
          <View style={styles.sectionHeaderRow}>
            <Text style={styles.sectionTitle}>Contact Information</Text>
            <TouchableOpacity onPress={openEditContact}>
              <Text style={styles.editLink}>Edit</Text>
            </TouchableOpacity>
          </View>
          {vendor.phone && (
            <View style={styles.infoRow}>
              <Ionicons name="call-outline" size={18} color={colors.text.secondary} />
              <Text style={styles.infoText}>{vendor.phone}</Text>
            </View>
          )}
          {vendor.email && (
            <View style={styles.infoRow}>
              <Ionicons name="mail-outline" size={18} color={colors.text.secondary} />
              <Text style={styles.infoText}>{vendor.email}</Text>
            </View>
          )}
          {vendor.websiteUrl && (
            <TouchableOpacity style={styles.infoRow} onPress={handleWebsite}>
              <Ionicons name="globe-outline" size={18} color={colors.text.secondary} />
              <Text style={[styles.infoText, styles.linkText]}>{vendor.websiteUrl}</Text>
            </TouchableOpacity>
          )}
          {(vendor.addressLine1 || vendor.city) && (
            <View style={styles.infoRow}>
              <Ionicons name="location-outline" size={18} color={colors.text.secondary} />
              <Text style={styles.infoText}>
                {[vendor.addressLine1, vendor.city, vendor.state, vendor.postalCode]
                  .filter(Boolean)
                  .join(', ')}
              </Text>
            </View>
          )}
          {!vendor.phone && !vendor.email && !vendor.websiteUrl && !vendor.addressLine1 && (
            <TouchableOpacity onPress={openEditContact} style={styles.emptyContactRow}>
              <Ionicons name="add-circle-outline" size={20} color={colors.haven.purple[600]} />
              <Text style={styles.addContactText}>Add contact information</Text>
            </TouchableOpacity>
          )}
        </Card>

        {/* Utility Quick Actions - for utilities like electric and internet */}
        {isUtilityType(vendor.category) && (
          <Card style={styles.sectionCard}>
            <View style={styles.sectionHeaderRow}>
              <Text style={styles.sectionTitleSmall}>QUICK ACTIONS</Text>
            </View>
            <View style={styles.utilityActions}>
              <TouchableOpacity
                style={styles.utilityActionButton}
                onPress={() => {
                  if (vendor.websiteUrl) {
                    Linking.openURL(vendor.websiteUrl);
                  } else {
                    Alert.alert('No Website', 'Add a website URL to report outages online.');
                  }
                }}
              >
                <View style={styles.utilityActionIcon}>
                  <Ionicons name="alert-circle" size={22} color={colors.status.error} />
                </View>
                <Text style={styles.utilityActionText}>Report Outage</Text>
              </TouchableOpacity>

              <TouchableOpacity
                style={styles.utilityActionButton}
                onPress={() => {
                  if (vendor.phone) {
                    Linking.openURL(`tel:${vendor.phone.replace(/[^0-9+]/g, '')}`);
                  } else if (vendor.websiteUrl) {
                    Linking.openURL(vendor.websiteUrl);
                  } else {
                    Alert.alert('No Contact', 'Add phone or website to check account.');
                  }
                }}
              >
                <View style={styles.utilityActionIcon}>
                  <Ionicons name="wallet" size={22} color={colors.haven.purple[600]} />
                </View>
                <Text style={styles.utilityActionText}>Check Balance</Text>
              </TouchableOpacity>

              <TouchableOpacity
                style={styles.utilityActionButton}
                onPress={() => {
                  router.push({
                    pathname: '/(tabs)/manager',
                    params: { prefill: `I need support with my ${vendor.category?.replace(/_/g, ' ')} service from ${vendor.displayName}. Can you help?` },
                  });
                }}
              >
                <View style={styles.utilityActionIcon}>
                  <Ionicons name="help-buoy" size={22} color={colors.haven.purple[500]} />
                </View>
                <Text style={styles.utilityActionText}>Get Support</Text>
              </TouchableOpacity>
            </View>

            <TouchableOpacity style={styles.checkRatesButton}>
              <Ionicons name="sparkles" size={16} color={colors.haven.purple[600]} />
              <Text style={styles.checkRatesText}>Ask Alfred to check better rates</Text>
            </TouchableOpacity>
          </Card>
        )}

        {/* Type-Specific Card - for utilities */}
        {isUtilityType(vendor.category) && vendor.typeSpecificData && (
          <Card style={styles.sectionCard}>
            <View style={styles.sectionHeaderRow}>
              <Text style={styles.sectionTitleSmall}>CURRENT PLAN</Text>
            </View>
            {vendor.category.toLowerCase().includes('electric') && (
              <>
                <View style={styles.rateDisplay}>
                  <Text style={styles.rateValue}>
                    ${((vendor.typeSpecificData as ElectricVendorData).currentRate || 0).toFixed(3)}
                  </Text>
                  <Text style={styles.rateUnit}>per kWh</Text>
                </View>
                {(vendor.typeSpecificData as ElectricVendorData).ratePlanName && (
                  <Text style={styles.ratePlan}>
                    {(vendor.typeSpecificData as ElectricVendorData).ratePlanName}
                  </Text>
                )}
              </>
            )}
            {vendor.category.toLowerCase().includes('internet') && (
              <>
                <Text style={styles.planName}>
                  {(vendor.typeSpecificData as InternetVendorData).planName || 'Standard Plan'}
                </Text>
                <View style={styles.speedRow}>
                  <View style={styles.speedItem}>
                    <Ionicons name="arrow-down" size={16} color={colors.status.success} />
                    <Text style={styles.speedValue}>
                      {(vendor.typeSpecificData as InternetVendorData).downloadSpeed || '—'} Mbps
                    </Text>
                  </View>
                  <View style={styles.speedItem}>
                    <Ionicons name="arrow-up" size={16} color={colors.haven.purple[500]} />
                    <Text style={styles.speedValue}>
                      {(vendor.typeSpecificData as InternetVendorData).uploadSpeed || '—'} Mbps
                    </Text>
                  </View>
                </View>
              </>
            )}
          </Card>
        )}

        {/* Account Information */}
        {vendor.account && (vendor.account.accountNumber || vendor.account.serviceAddress) && (
          <Card style={styles.sectionCard}>
            <View style={styles.sectionHeaderRow}>
              <Text style={styles.sectionTitleSmall}>ACCOUNT INFORMATION</Text>
              <TouchableOpacity>
                <Text style={styles.editLink}>Edit</Text>
              </TouchableOpacity>
            </View>
            {vendor.account.accountNumber && (
              <View style={styles.infoRow}>
                <Ionicons name="card-outline" size={18} color={colors.text.secondary} />
                <View style={styles.infoContent}>
                  <Text style={styles.infoLabel}>Account #</Text>
                  <Text style={styles.infoValue}>{vendor.account.accountNumber}</Text>
                </View>
              </View>
            )}
            {vendor.account.serviceAddress && (
              <View style={styles.infoRow}>
                <Ionicons name="location-outline" size={18} color={colors.text.secondary} />
                <View style={styles.infoContent}>
                  <Text style={styles.infoLabel}>Service Address</Text>
                  <Text style={styles.infoValue}>{vendor.account.serviceAddress}</Text>
                </View>
              </View>
            )}
            {vendor.account.customerSince && (
              <View style={styles.infoRow}>
                <Ionicons name="calendar-outline" size={18} color={colors.text.secondary} />
                <View style={styles.infoContent}>
                  <Text style={styles.infoLabel}>Customer Since</Text>
                  <Text style={styles.infoValue}>{formatDate(vendor.account.customerSince)}</Text>
                </View>
              </View>
            )}
          </Card>
        )}

        {/* Primary Contact */}
        {vendor.contacts && vendor.contacts.length > 0 && (
          <Card style={styles.sectionCard}>
            <View style={styles.sectionHeaderRow}>
              <Text style={styles.sectionTitleSmall}>POINT OF CONTACT</Text>
              <TouchableOpacity>
                <Text style={styles.editLink}>Edit</Text>
              </TouchableOpacity>
            </View>
            {vendor.contacts.filter(c => c.isPrimary).slice(0, 1).map(contact => (
              <View key={contact.id}>
                {contact.name && (
                  <View style={styles.infoRow}>
                    <Ionicons name="person-outline" size={18} color={colors.text.secondary} />
                    <View style={styles.infoContent}>
                      <Text style={styles.infoLabel}>Name</Text>
                      <Text style={styles.infoValue}>{contact.name}</Text>
                    </View>
                  </View>
                )}
                {contact.title && (
                  <View style={styles.infoRow}>
                    <Ionicons name="briefcase-outline" size={18} color={colors.text.secondary} />
                    <View style={styles.infoContent}>
                      <Text style={styles.infoLabel}>Title</Text>
                      <Text style={styles.infoValue}>{contact.title}</Text>
                    </View>
                  </View>
                )}
                {contact.phone && (
                  <TouchableOpacity
                    style={styles.infoRow}
                    onPress={() => Linking.openURL(`tel:${contact.phone}`)}
                  >
                    <Ionicons name="call-outline" size={18} color={colors.text.secondary} />
                    <View style={styles.infoContent}>
                      <Text style={styles.infoLabel}>Direct Phone</Text>
                      <Text style={[styles.infoValue, styles.linkText]}>{contact.phone}</Text>
                    </View>
                  </TouchableOpacity>
                )}
                {contact.email && (
                  <TouchableOpacity
                    style={styles.infoRow}
                    onPress={() => Linking.openURL(`mailto:${contact.email}`)}
                  >
                    <Ionicons name="mail-outline" size={18} color={colors.text.secondary} />
                    <View style={styles.infoContent}>
                      <Text style={styles.infoLabel}>Email</Text>
                      <Text style={[styles.infoValue, styles.linkText]}>{contact.email}</Text>
                    </View>
                  </TouchableOpacity>
                )}
              </View>
            ))}
            {vendor.contacts.length > 1 && (
              <TouchableOpacity style={styles.moreContactsLink}>
                <Text style={styles.linkText}>+{vendor.contacts.length - 1} more contacts</Text>
              </TouchableOpacity>
            )}
          </Card>
        )}

        {/* Billing & Payment */}
        {vendor.billing && (
          <Card style={styles.sectionCard}>
            <View style={styles.sectionHeaderRow}>
              <Text style={styles.sectionTitleSmall}>BILLING & PAYMENT</Text>
              <TouchableOpacity>
                <Text style={styles.editLink}>Edit</Text>
              </TouchableOpacity>
            </View>
            {vendor.billing.paymentFrequency && (
              <View style={styles.infoRow}>
                <Ionicons name="repeat-outline" size={18} color={colors.text.secondary} />
                <View style={styles.infoContent}>
                  <Text style={styles.infoLabel}>Frequency</Text>
                  <Text style={styles.infoValue}>{formatFrequency(vendor.billing.paymentFrequency)}</Text>
                </View>
              </View>
            )}
            {vendor.billing.averageMonthlyBill && (
              <View style={styles.infoRow}>
                <Ionicons name="cash-outline" size={18} color={colors.text.secondary} />
                <View style={styles.infoContent}>
                  <Text style={styles.infoLabel}>Avg Monthly</Text>
                  <Text style={styles.infoValue}>{formatCurrency(vendor.billing.averageMonthlyBill)}</Text>
                </View>
              </View>
            )}
            {vendor.billing.lastPaymentAmount && vendor.billing.lastPaymentDate && (
              <View style={styles.infoRow}>
                <Ionicons name="checkmark-circle-outline" size={18} color={colors.text.secondary} />
                <View style={styles.infoContent}>
                  <Text style={styles.infoLabel}>Last Payment</Text>
                  <Text style={styles.infoValue}>
                    {formatCurrency(vendor.billing.lastPaymentAmount)} on {formatDate(vendor.billing.lastPaymentDate)}
                  </Text>
                </View>
              </View>
            )}
            {vendor.billing.nextPaymentDue && (
              <View style={styles.infoRow}>
                <Ionicons
                  name="calendar-outline"
                  size={18}
                  color={isWithinDays(vendor.billing.nextPaymentDue, 7) ? colors.status.warning : colors.text.secondary}
                />
                <View style={styles.infoContent}>
                  <Text style={styles.infoLabel}>Next Due</Text>
                  <Text style={[
                    styles.infoValue,
                    isWithinDays(vendor.billing.nextPaymentDue, 7) && styles.warningText
                  ]}>
                    {formatDate(vendor.billing.nextPaymentDue)}
                    {isWithinDays(vendor.billing.nextPaymentDue, 7) && ' (Due Soon)'}
                  </Text>
                </View>
              </View>
            )}
          </Card>
        )}

        {/* Contracts */}
        {vendor.contracts && vendor.contracts.length > 0 && (
          <Card style={styles.sectionCard}>
            <View style={styles.sectionHeaderRow}>
              <Text style={styles.sectionTitleSmall}>CONTRACTS</Text>
              <TouchableOpacity>
                <Text style={styles.editLink}>+ Add</Text>
              </TouchableOpacity>
            </View>
            {vendor.contracts.map(contract => (
              <TouchableOpacity key={contract.id} style={styles.contractRow}>
                <Ionicons name="document-text-outline" size={20} color={colors.text.secondary} />
                <View style={styles.contractInfo}>
                  <Text style={styles.contractName}>{contract.name}</Text>
                  <Text style={styles.contractDates}>
                    {formatDate(contract.startDate)} - {contract.endDate ? formatDate(contract.endDate) : 'Ongoing'}
                  </Text>
                  {contract.autoRenews && (
                    <View style={styles.autoRenewBadge}>
                      <Ionicons name="refresh" size={12} color={colors.haven.purple[600]} />
                      <Text style={styles.autoRenewText}>Auto-renews</Text>
                    </View>
                  )}
                </View>
                <Ionicons name="chevron-forward" size={20} color={colors.text.tertiary} />
              </TouchableOpacity>
            ))}
          </Card>
        )}

        {/* Notes */}
        {vendor.notes && (
          <Card style={styles.sectionCard}>
            <View style={styles.sectionHeaderRow}>
              <Text style={styles.sectionTitleSmall}>NOTES</Text>
              <TouchableOpacity>
                <Text style={styles.editLink}>Edit</Text>
              </TouchableOpacity>
            </View>
            <Text style={styles.notesText}>{vendor.notes}</Text>
          </Card>
        )}

        {/* Related Bills */}
        {vendor.billAccounts && vendor.billAccounts.length > 0 && (
          <Card style={styles.sectionCard}>
            <View style={styles.sectionHeaderRow}>
              <Text style={styles.sectionTitleSmall}>RELATED BILLS</Text>
              <TouchableOpacity>
                <Text style={styles.editLink}>View All</Text>
              </TouchableOpacity>
            </View>
            {vendor.billAccounts.map(bill => (
              <View key={bill.id} style={styles.billRow}>
                <View style={styles.billIconWrapper}>
                  <Ionicons name="receipt-outline" size={18} color={colors.haven.purple[500]} />
                </View>
                <View style={styles.billInfo}>
                  <Text style={styles.billName}>{bill.nickname}</Text>
                  <Text style={styles.billFrequency}>
                    {bill.billingFrequency.charAt(0) + bill.billingFrequency.slice(1).toLowerCase()}
                    {bill.typicalAmount && ` • ~${formatCurrency(bill.typicalAmount)}`}
                  </Text>
                </View>
                {bill.nextDueDate && (
                  <View style={styles.billDueInfo}>
                    <Text style={[
                      styles.billDueText,
                      isWithinDays(bill.nextDueDate, 7) && styles.warningText
                    ]}>
                      Due {formatDate(bill.nextDueDate)}
                    </Text>
                    {bill.lastPaidAmount && (
                      <Text style={styles.billLastPaid}>
                        Last: {formatCurrency(bill.lastPaidAmount)}
                      </Text>
                    )}
                  </View>
                )}
              </View>
            ))}
          </Card>
        )}

        {/* Activity History */}
        <View style={styles.activitySection}>
          <View style={styles.activityHeader}>
            <Text style={styles.sectionTitle}>Activity History</Text>
            <TouchableOpacity
              style={styles.addActivityBtn}
              onPress={() => setShowAddActivity(true)}
            >
              <Ionicons name="add" size={20} color={colors.haven.purple[600]} />
              <Text style={styles.addActivityText}>Add</Text>
            </TouchableOpacity>
          </View>

          {activities.length === 0 ? (
            <Card style={styles.emptyActivityCard}>
              <Ionicons name="time-outline" size={32} color={colors.text.tertiary} />
              <Text style={styles.emptyActivityText}>No activity recorded yet</Text>
              <Text style={styles.emptyActivitySubtext}>
                Track service calls, payments, and notes
              </Text>
            </Card>
          ) : (
            activities.map(activity => (
              <Card key={activity.id} style={styles.activityCard}>
                <View style={styles.activityRow}>
                  <View style={styles.activityIconWrapper}>
                    <Ionicons
                      name={getActivityIcon(activity.type) as any}
                      size={20}
                      color={colors.haven.purple[500]}
                    />
                  </View>
                  <View style={styles.activityContent}>
                    <Text style={styles.activityTitle}>{activity.title}</Text>
                    <Text style={styles.activityDate}>{formatDate(activity.date)}</Text>
                    {activity.description && (
                      <Text style={styles.activityDescription}>{activity.description}</Text>
                    )}
                  </View>
                  {activity.amount && (
                    <View style={styles.activityAmount}>
                      <Text style={styles.amountText}>{formatCurrency(activity.amount)}</Text>
                      {activity.isPaid && (
                        <Badge label="Paid" variant="success" size="sm" />
                      )}
                    </View>
                  )}
                </View>
              </Card>
            ))
          )}
        </View>
      </ScrollView>

      {/* Add Activity Modal */}
      <Modal visible={showAddActivity} animationType="slide" presentationStyle="pageSheet">
        <SafeAreaView style={styles.modalContainer}>
          <View style={styles.modalHeader}>
            <TouchableOpacity onPress={() => setShowAddActivity(false)}>
              <Text style={styles.modalCancel}>Cancel</Text>
            </TouchableOpacity>
            <Text style={styles.modalTitle}>Add Activity</Text>
            <TouchableOpacity onPress={handleAddActivity} disabled={isSubmitting}>
              <Text style={[styles.modalSave, isSubmitting && styles.modalSaveDisabled]}>
                {isSubmitting ? 'Saving...' : 'Save'}
              </Text>
            </TouchableOpacity>
          </View>

          <ScrollView style={styles.modalContent}>
            {/* Activity Type */}
            <Text style={styles.inputLabel}>Type</Text>
            <ScrollView horizontal showsHorizontalScrollIndicator={false} style={styles.typeScroll}>
              {ACTIVITY_TYPES.map(type => (
                <TouchableOpacity
                  key={type.id}
                  style={[
                    styles.typeChip,
                    activityType === type.id && styles.typeChipActive,
                  ]}
                  onPress={() => setActivityType(type.id)}
                >
                  <Ionicons
                    name={type.icon as any}
                    size={16}
                    color={activityType === type.id ? colors.white : colors.text.secondary}
                  />
                  <Text
                    style={[
                      styles.typeChipText,
                      activityType === type.id && styles.typeChipTextActive,
                    ]}
                  >
                    {type.label}
                  </Text>
                </TouchableOpacity>
              ))}
            </ScrollView>

            {/* Title */}
            <Text style={styles.inputLabel}>Title *</Text>
            <TextInput
              style={styles.textInput}
              value={activityTitle}
              onChangeText={setActivityTitle}
              placeholder="e.g., Annual HVAC maintenance"
              placeholderTextColor={colors.text.tertiary}
            />

            {/* Description */}
            <Text style={styles.inputLabel}>Description</Text>
            <TextInput
              style={[styles.textInput, styles.textArea]}
              value={activityDescription}
              onChangeText={setActivityDescription}
              placeholder="Add notes about this activity..."
              placeholderTextColor={colors.text.tertiary}
              multiline
              numberOfLines={3}
            />

            {/* Amount */}
            <Text style={styles.inputLabel}>Amount (optional)</Text>
            <TextInput
              style={styles.textInput}
              value={activityAmount}
              onChangeText={setActivityAmount}
              placeholder="0.00"
              placeholderTextColor={colors.text.tertiary}
              keyboardType="decimal-pad"
            />

            {/* Date */}
            <Text style={styles.inputLabel}>Date</Text>
            <DateTimePicker
              value={activityDate}
              mode="date"
              display="default"
              onChange={(_, date) => date && setActivityDate(date)}
              style={styles.datePicker}
            />
          </ScrollView>
        </SafeAreaView>
      </Modal>

      {/* Rating Modal */}
      <Modal visible={showRating} transparent animationType="fade">
        <View style={styles.ratingOverlay}>
          <View style={styles.ratingModal}>
            <Text style={styles.ratingModalTitle}>Rate {vendor.displayName}</Text>
            <View style={styles.ratingStars}>
              {[1, 2, 3, 4, 5].map(star => (
                <TouchableOpacity key={star} onPress={() => handleSetRating(star)}>
                  <Ionicons
                    name={star <= (vendor.rating || 0) ? 'star' : 'star-outline'}
                    size={40}
                    color={colors.haven.purple[500]}
                  />
                </TouchableOpacity>
              ))}
            </View>
            <TouchableOpacity
              style={styles.ratingCloseBtn}
              onPress={() => setShowRating(false)}
            >
              <Text style={styles.ratingCloseText}>Cancel</Text>
            </TouchableOpacity>
          </View>
        </View>
      </Modal>

      {/* Edit Contact Modal */}
      <Modal visible={showEditContact} animationType="slide" presentationStyle="pageSheet">
        <SafeAreaView style={styles.modalContainer}>
          <View style={styles.modalHeader}>
            <TouchableOpacity onPress={() => setShowEditContact(false)}>
              <Text style={styles.modalCancel}>Cancel</Text>
            </TouchableOpacity>
            <Text style={styles.modalTitle}>Edit Contact</Text>
            <TouchableOpacity onPress={handleSaveContact} disabled={isSavingContact}>
              <Text style={[styles.modalSave, isSavingContact && styles.modalSaveDisabled]}>
                {isSavingContact ? 'Saving...' : 'Save'}
              </Text>
            </TouchableOpacity>
          </View>

          <ScrollView style={styles.modalContent} keyboardShouldPersistTaps="handled">
            <Text style={styles.inputLabel}>Phone Number</Text>
            <TextInput
              style={styles.textInput}
              value={editPhone}
              onChangeText={setEditPhone}
              placeholder="(555) 123-4567"
              placeholderTextColor={colors.text.tertiary}
              keyboardType="phone-pad"
              autoComplete="tel"
            />

            <Text style={styles.inputLabel}>Email</Text>
            <TextInput
              style={styles.textInput}
              value={editEmail}
              onChangeText={setEditEmail}
              placeholder="contact@company.com"
              placeholderTextColor={colors.text.tertiary}
              keyboardType="email-address"
              autoCapitalize="none"
              autoComplete="email"
            />

            <Text style={styles.inputLabel}>Website</Text>
            <TextInput
              style={styles.textInput}
              value={editWebsite}
              onChangeText={setEditWebsite}
              placeholder="https://www.company.com"
              placeholderTextColor={colors.text.tertiary}
              keyboardType="url"
              autoCapitalize="none"
              autoComplete="url"
            />

            <Text style={styles.inputLabel}>Account Number</Text>
            <TextInput
              style={styles.textInput}
              value={editAccountNumber}
              onChangeText={setEditAccountNumber}
              placeholder="Your account number"
              placeholderTextColor={colors.text.tertiary}
            />

            <Text style={styles.inputLabel}>Street Address</Text>
            <TextInput
              style={styles.textInput}
              value={editAddress}
              onChangeText={setEditAddress}
              placeholder="123 Main St"
              placeholderTextColor={colors.text.tertiary}
              autoComplete="street-address"
            />

            <View style={styles.addressRow}>
              <View style={styles.cityField}>
                <Text style={styles.inputLabel}>City</Text>
                <TextInput
                  style={styles.textInput}
                  value={editCity}
                  onChangeText={setEditCity}
                  placeholder="City"
                  placeholderTextColor={colors.text.tertiary}
                />
              </View>
              <View style={styles.stateField}>
                <Text style={styles.inputLabel}>State</Text>
                <TextInput
                  style={styles.textInput}
                  value={editState}
                  onChangeText={setEditState}
                  placeholder="ST"
                  placeholderTextColor={colors.text.tertiary}
                  maxLength={2}
                  autoCapitalize="characters"
                />
              </View>
              <View style={styles.zipField}>
                <Text style={styles.inputLabel}>ZIP</Text>
                <TextInput
                  style={styles.textInput}
                  value={editPostalCode}
                  onChangeText={setEditPostalCode}
                  placeholder="12345"
                  placeholderTextColor={colors.text.tertiary}
                  keyboardType="number-pad"
                  maxLength={10}
                />
              </View>
            </View>

            <Text style={styles.inputLabel}>Notes</Text>
            <TextInput
              style={[styles.textInput, styles.textArea]}
              value={editNotes}
              onChangeText={setEditNotes}
              placeholder="Add any notes about this vendor..."
              placeholderTextColor={colors.text.tertiary}
              multiline
              numberOfLines={4}
            />
          </ScrollView>
        </SafeAreaView>
      </Modal>
    </View>
  );
}

// =============================================================================
// STYLES
// =============================================================================

const styles = StyleSheet.create({
  fullContainer: {
    flex: 1,
    backgroundColor: colors.haven.purple[900],
  },
  loadingContainer: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: colors.background.secondary,
  },
  container: {
    flex: 1,
    backgroundColor: colors.background.secondary,
  },
  scrollContainer: {
    flex: 1,
    backgroundColor: colors.background.secondary,
  },
  scrollContent: {
    padding: spacing[4],
  },
  headerCard: {
    padding: spacing[4],
    marginBottom: spacing[4],
  },
  vendorHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: spacing[4],
  },
  vendorIcon: {
    width: 64,
    height: 64,
    borderRadius: borderRadius.xl,
    backgroundColor: colors.haven.purple[50],
    alignItems: 'center',
    justifyContent: 'center',
  },
  vendorLogoContainer: {
    width: 64,
    height: 64,
    borderRadius: borderRadius.xl,
    backgroundColor: colors.white,
    alignItems: 'center',
    justifyContent: 'center',
    overflow: 'hidden',
    borderWidth: 1,
    borderColor: colors.border.light,
  },
  vendorLogo: {
    width: 52,
    height: 52,
  },
  vendorInfo: {
    flex: 1,
    marginLeft: spacing[3],
  },
  vendorName: {
    fontSize: typography.fontSizes.xl,
    fontWeight: typography.fontWeights.bold,
    color: colors.text.primary,
  },
  vendorCategory: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    textTransform: 'capitalize',
    marginTop: 2,
  },
  contactName: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.tertiary,
    marginTop: 2,
  },
  ratingRow: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: spacing[3],
    borderTopWidth: 1,
    borderTopColor: colors.border.light,
    marginBottom: spacing[3],
  },
  ratingLabel: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    marginRight: spacing[2],
  },
  stars: {
    flexDirection: 'row',
    flex: 1,
    gap: 4,
  },
  quickActions: {
    flexDirection: 'row',
    gap: spacing[2],
    marginBottom: spacing[3],
  },
  actionButton: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: colors.haven.purple[900],
    paddingVertical: spacing[3],
    borderRadius: borderRadius.lg,
    gap: spacing[1],
  },
  actionText: {
    color: colors.white,
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
  },
  scheduleButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: colors.haven.purple[50],
    paddingVertical: spacing[3],
    borderRadius: borderRadius.lg,
    gap: spacing[2],
  },
  scheduleText: {
    color: colors.haven.purple[700],
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
  },
  sectionCard: {
    padding: spacing[4],
    marginBottom: spacing[4],
  },
  sectionTitle: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
    marginBottom: spacing[3],
  },
  infoRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[2],
    marginBottom: spacing[2],
  },
  infoText: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    flex: 1,
  },
  linkText: {
    color: colors.haven.purple[600],
  },
  // New styles for enhanced sections
  sectionHeaderRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: spacing[3],
  },
  sectionTitleSmall: {
    fontSize: typography.fontSizes.xs,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.tertiary,
    textTransform: 'uppercase',
    letterSpacing: 0.5,
  },
  editLink: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.purple[600],
    fontWeight: typography.fontWeights.medium,
  },
  infoContent: {
    flex: 1,
    marginLeft: spacing[2],
  },
  infoLabel: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
    marginBottom: 2,
  },
  infoValue: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.primary,
    fontWeight: typography.fontWeights.medium,
  },
  warningText: {
    color: colors.status.warning,
  },
  moreContactsLink: {
    marginTop: spacing[3],
    paddingTop: spacing[3],
    borderTopWidth: 1,
    borderTopColor: colors.border.light,
  },
  // Rate display styles
  rateDisplay: {
    flexDirection: 'row',
    alignItems: 'baseline',
    marginBottom: spacing[2],
  },
  rateValue: {
    fontSize: 32,
    fontWeight: typography.fontWeights.bold,
    color: colors.text.primary,
  },
  rateUnit: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    marginLeft: spacing[1],
  },
  ratePlan: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    marginBottom: spacing[3],
  },
  planName: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
    marginBottom: spacing[2],
  },
  speedRow: {
    flexDirection: 'row',
    gap: spacing[6],
    marginBottom: spacing[3],
  },
  speedItem: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[1],
  },
  speedValue: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
  },
  checkRatesButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: spacing[2],
    paddingVertical: spacing[3],
    backgroundColor: colors.haven.purple[50],
    borderRadius: borderRadius.lg,
    marginTop: spacing[2],
  },
  checkRatesText: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.purple[700],
    fontWeight: typography.fontWeights.medium,
  },
  // Contract styles
  contractRow: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: spacing[3],
    borderBottomWidth: 1,
    borderBottomColor: colors.border.light,
  },
  contractInfo: {
    flex: 1,
    marginLeft: spacing[3],
  },
  contractName: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.primary,
  },
  contractDates: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
    marginTop: 2,
  },
  autoRenewBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[1],
    marginTop: spacing[1],
  },
  autoRenewText: {
    fontSize: typography.fontSizes.xs,
    color: colors.haven.purple[600],
    fontWeight: typography.fontWeights.medium,
  },
  notesText: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    lineHeight: 20,
  },
  activitySection: {
    marginBottom: spacing[4],
  },
  activityHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: spacing[3],
  },
  addActivityBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[1],
  },
  addActivityText: {
    color: colors.haven.purple[600],
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
  },
  emptyActivityCard: {
    padding: spacing[6],
    alignItems: 'center',
  },
  emptyActivityText: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.secondary,
    marginTop: spacing[2],
  },
  emptyActivitySubtext: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.tertiary,
    marginTop: spacing[1],
  },
  activityCard: {
    padding: spacing[3],
    marginBottom: spacing[2],
  },
  activityRow: {
    flexDirection: 'row',
    alignItems: 'flex-start',
  },
  activityIconWrapper: {
    width: 36,
    height: 36,
    borderRadius: borderRadius.lg,
    backgroundColor: colors.haven.purple[50],
    alignItems: 'center',
    justifyContent: 'center',
  },
  activityContent: {
    flex: 1,
    marginLeft: spacing[3],
  },
  activityTitle: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.primary,
  },
  activityDate: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
    marginTop: 2,
  },
  activityDescription: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    marginTop: spacing[1],
  },
  activityAmount: {
    alignItems: 'flex-end',
  },
  amountText: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
  },
  emptyContainer: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  emptyTitle: {
    fontSize: typography.fontSizes.lg,
    color: colors.text.secondary,
    marginTop: spacing[2],
  },
  // Modal styles
  modalContainer: {
    flex: 1,
    backgroundColor: colors.background.primary,
  },
  modalHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: spacing[4],
    borderBottomWidth: 1,
    borderBottomColor: colors.border.light,
  },
  modalCancel: {
    fontSize: typography.fontSizes.base,
    color: colors.text.secondary,
  },
  modalTitle: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
  },
  modalSave: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.haven.purple[600],
  },
  modalSaveDisabled: {
    opacity: 0.5,
  },
  modalContent: {
    flex: 1,
    padding: spacing[4],
  },
  inputLabel: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.secondary,
    marginBottom: spacing[2],
    marginTop: spacing[4],
  },
  typeScroll: {
    marginBottom: spacing[2],
  },
  typeChip: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: spacing[2],
    paddingHorizontal: spacing[3],
    borderRadius: borderRadius.full,
    backgroundColor: colors.background.tertiary,
    marginRight: spacing[2],
    gap: spacing[1],
  },
  typeChipActive: {
    backgroundColor: colors.haven.purple[600],
  },
  typeChipText: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
  },
  typeChipTextActive: {
    color: colors.white,
  },
  textInput: {
    backgroundColor: colors.background.primary,
    borderWidth: 1,
    borderColor: colors.border.light,
    borderRadius: borderRadius.lg,
    paddingHorizontal: spacing[3],
    paddingVertical: spacing[3],
    fontSize: typography.fontSizes.base,
    color: colors.text.primary,
  },
  textArea: {
    height: 80,
    textAlignVertical: 'top',
  },
  datePicker: {
    alignSelf: 'flex-start',
  },
  // Rating modal
  ratingOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.5)',
    alignItems: 'center',
    justifyContent: 'center',
  },
  ratingModal: {
    backgroundColor: colors.white,
    borderRadius: borderRadius.xl,
    padding: spacing[6],
    alignItems: 'center',
    width: '80%',
  },
  ratingModalTitle: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
    marginBottom: spacing[4],
  },
  ratingStars: {
    flexDirection: 'row',
    gap: spacing[2],
    marginBottom: spacing[4],
  },
  ratingCloseBtn: {
    paddingVertical: spacing[2],
  },
  ratingCloseText: {
    fontSize: typography.fontSizes.base,
    color: colors.text.secondary,
  },
  // Edit contact modal
  emptyContactRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[2],
    paddingVertical: spacing[3],
  },
  addContactText: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.purple[600],
    fontWeight: typography.fontWeights.medium,
  },
  addressRow: {
    flexDirection: 'row',
    gap: spacing[2],
  },
  cityField: {
    flex: 2,
  },
  stateField: {
    flex: 1,
  },
  zipField: {
    flex: 1.5,
  },
  // Utility actions styles
  utilityActions: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: spacing[3],
  },
  utilityActionButton: {
    flex: 1,
    alignItems: 'center',
    paddingVertical: spacing[2],
  },
  utilityActionIcon: {
    width: 44,
    height: 44,
    borderRadius: borderRadius.full,
    backgroundColor: colors.background.tertiary,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: spacing[1],
  },
  utilityActionText: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.secondary,
    fontWeight: typography.fontWeights.medium,
    textAlign: 'center',
  },
  // Bill section styles
  billRow: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: spacing[3],
    borderBottomWidth: 1,
    borderBottomColor: colors.border.light,
  },
  billIconWrapper: {
    width: 36,
    height: 36,
    borderRadius: borderRadius.lg,
    backgroundColor: colors.haven.purple[50],
    alignItems: 'center',
    justifyContent: 'center',
  },
  billInfo: {
    flex: 1,
    marginLeft: spacing[3],
  },
  billName: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.primary,
  },
  billFrequency: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
    marginTop: 2,
  },
  billDueInfo: {
    alignItems: 'flex-end',
  },
  billDueText: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.secondary,
    fontWeight: typography.fontWeights.medium,
  },
  billLastPaid: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
    marginTop: 2,
  },
});

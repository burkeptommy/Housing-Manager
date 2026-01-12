import { useEffect, useState, useCallback } from 'react';
import {
  View,
  Text,
  ScrollView,
  StyleSheet,
  RefreshControl,
  TouchableOpacity,
  ActivityIndicator,
  Alert,
  Modal,
  TextInput,
  KeyboardAvoidingView,
  Platform,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { useAuth } from '../../src/contexts/auth-context';
import { usePlaid } from '../../src/contexts/plaid-context';
import { colors, spacing, typography, borderRadius, shadows } from '../../src/lib/theme';
import { API_BASE_URL } from '../../src/lib/api';
import { getIdToken } from '../../src/lib/firebase';
import { formatFrequency as formatPlaidFrequency, getCategoryIcon as getPlaidCategoryIcon, DetectedBill } from '../../src/lib/plaid';

// =============================================================================
// TYPES
// =============================================================================

interface Bill {
  id: string;
  category: string;
  name: string;
  payeeName: string | null;
  amount: number;
  frequency: string | null;
  dueDay: number | null;
  status: string;
  havenManaged: boolean;
  verified: boolean;
  currentAutopay: boolean;
  vendor: string | null;
  lastPayment: {
    amount: number;
    date: string;
    status: string;
  } | null;
}

interface CategorySummary {
  category: string;
  billCount: number;
  monthlyTotal: number;
}

interface BillsData {
  bills: Bill[];
  byCategory: CategorySummary[];
  summary: {
    totalBills: number;
    monthlyTotal: number;
    monthlyFunding: number;
  };
}

// =============================================================================
// HELPERS
// =============================================================================

function formatCurrency(amount: number | null | undefined) {
  if (amount === null || amount === undefined) return '$0';
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  }).format(amount);
}

function formatCurrencyDetailed(amount: number | null | undefined) {
  if (amount === null || amount === undefined) return '$0.00';
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  }).format(amount);
}

function getCategoryIcon(category: string): keyof typeof Ionicons.glyphMap {
  const cat = category.toUpperCase();
  if (cat.includes('MORTGAGE') || cat.includes('HOUSING') || cat.includes('RENT')) {
    return 'home-outline';
  }
  if (cat.includes('UTILITY') || cat.includes('ELECTRIC') || cat.includes('GAS') || cat.includes('WATER')) {
    return 'flash-outline';
  }
  if (cat.includes('INSURANCE')) {
    return 'shield-outline';
  }
  if (cat.includes('SERVICE') || cat.includes('CLEANING') || cat.includes('LAWN')) {
    return 'sparkles-outline';
  }
  if (cat.includes('KID') || cat.includes('ACTIVITY') || cat.includes('SCHOOL') || cat.includes('TUITION')) {
    return 'school-outline';
  }
  if (cat.includes('PET')) {
    return 'paw-outline';
  }
  if (cat.includes('VEHICLE') || cat.includes('AUTO') || cat.includes('CAR')) {
    return 'car-outline';
  }
  if (cat.includes('HEALTH') || cat.includes('MEDICAL')) {
    return 'heart-outline';
  }
  if (cat.includes('MAINTENANCE') || cat.includes('REPAIR')) {
    return 'construct-outline';
  }
  return 'cash-outline';
}

function getCategoryColor(category: string) {
  const cat = category.toUpperCase();
  if (cat.includes('MORTGAGE') || cat.includes('HOUSING')) {
    return { bg: '#E0E7FF', text: '#4338CA' }; // indigo
  }
  if (cat.includes('UTILITY')) {
    return { bg: '#FEF3C7', text: '#B45309' }; // amber
  }
  if (cat.includes('INSURANCE')) {
    return { bg: '#F5F0E6', text: '#8B7355' }; // champagne
  }
  if (cat.includes('SERVICE')) {
    return { bg: '#F3E8FF', text: '#7C3AED' }; // purple
  }
  if (cat.includes('KID') || cat.includes('ACTIVITY')) {
    return { bg: '#FCE7F3', text: '#BE185D' }; // pink
  }
  if (cat.includes('PET')) {
    return { bg: '#FFEDD5', text: '#C2410C' }; // orange
  }
  if (cat.includes('VEHICLE')) {
    return { bg: '#DBEAFE', text: '#1D4ED8' }; // blue
  }
  return { bg: colors.slate[100], text: colors.slate[700] };
}

function formatCategoryName(category: string) {
  return category
    .split('_')
    .map((word) => word.charAt(0) + word.slice(1).toLowerCase())
    .join(' ');
}

function formatFrequency(freq: string | null) {
  if (!freq) return 'mo';
  const map: Record<string, string> = {
    WEEKLY: 'wk',
    BIWEEKLY: '2wk',
    SEMI_MONTHLY: '2x/mo',
    MONTHLY: 'mo',
    QUARTERLY: 'qtr',
    ANNUALLY: 'yr',
  };
  return map[freq] || 'mo';
}

// =============================================================================
// COMPONENTS
// =============================================================================

function SummaryHeader({ summary }: { summary: BillsData['summary'] }) {
  const currentMonth = new Date().toLocaleDateString('en-US', { month: 'long' });
  const progress = summary.monthlyFunding > 0
    ? Math.min((summary.monthlyTotal / summary.monthlyFunding) * 100, 100)
    : 0;
  const buffer = summary.monthlyFunding - summary.monthlyTotal;

  return (
    <View style={styles.summaryCard}>
      <View style={styles.summaryHeader}>
        <View style={styles.summaryLabel}>
          <Ionicons name="card-outline" size={16} color={colors.haven.champagne[200]} />
          <Text style={styles.summaryLabelText}>{currentMonth} Bills</Text>
        </View>
      </View>
      <Text style={styles.summaryAmount}>{formatCurrency(summary.monthlyTotal)}</Text>
      <Text style={styles.summarySubtext}>
        {summary.totalBills} active bill{summary.totalBills !== 1 ? 's' : ''} managed by Haven
      </Text>

      {summary.monthlyFunding > 0 && (
        <View style={styles.fundingSection}>
          <View style={styles.fundingHeader}>
            <Text style={styles.fundingLabel}>Monthly Funding</Text>
            <Text style={styles.fundingAmount}>{formatCurrency(summary.monthlyFunding)}</Text>
          </View>
          <View style={styles.progressBar}>
            <View style={[styles.progressFill, { width: `${progress}%` }]} />
          </View>
          <Text style={styles.fundingBuffer}>
            {buffer > 0
              ? `${formatCurrency(buffer)} buffer remaining`
              : 'Bills exceed funding amount'}
          </Text>
        </View>
      )}
    </View>
  );
}

function CategoryCard({
  category,
  bills,
  isExpanded,
  onToggle,
}: {
  category: CategorySummary;
  bills: Bill[];
  isExpanded: boolean;
  onToggle: () => void;
}) {
  const categoryColors = getCategoryColor(category.category);
  const icon = getCategoryIcon(category.category);

  return (
    <View style={styles.categoryCard}>
      <TouchableOpacity
        style={styles.categoryHeader}
        onPress={onToggle}
        activeOpacity={0.7}
      >
        <View style={styles.categoryLeft}>
          <View style={[styles.categoryIcon, { backgroundColor: categoryColors.bg }]}>
            <Ionicons name={icon} size={20} color={categoryColors.text} />
          </View>
          <View>
            <Text style={styles.categoryName}>{formatCategoryName(category.category)}</Text>
            <Text style={styles.categoryCount}>
              {category.billCount} bill{category.billCount !== 1 ? 's' : ''}
            </Text>
          </View>
        </View>
        <View style={styles.categoryRight}>
          <Text style={styles.categoryTotal}>{formatCurrency(category.monthlyTotal)}/mo</Text>
          <Ionicons
            name={isExpanded ? 'chevron-up' : 'chevron-down'}
            size={20}
            color={colors.slate[400]}
          />
        </View>
      </TouchableOpacity>

      {isExpanded && bills.length > 0 && (
        <View style={styles.billsList}>
          {bills.map((bill) => (
            <View key={bill.id} style={styles.billItem}>
              <View style={styles.billInfo}>
                <View style={styles.billNameRow}>
                  <Text style={styles.billName}>{bill.name}</Text>
                  {bill.havenManaged && (
                    <View style={styles.havenBadge}>
                      <Text style={styles.havenBadgeText}>Haven Managed</Text>
                    </View>
                  )}
                </View>
                {bill.payeeName && (
                  <Text style={styles.billPayee}>{bill.payeeName}</Text>
                )}
              </View>
              <View style={styles.billRight}>
                <Text style={styles.billAmount}>
                  {formatCurrencyDetailed(bill.amount)}
                  <Text style={styles.billFrequency}>/{formatFrequency(bill.frequency)}</Text>
                </Text>
                {bill.dueDay && (
                  <Text style={styles.billDue}>Due day {bill.dueDay}</Text>
                )}
                {bill.lastPayment && (
                  <View style={styles.paidRow}>
                    <Ionicons name="checkmark-circle" size={12} color={colors.status.success} />
                    <Text style={styles.paidText}>
                      Paid {new Date(bill.lastPayment.date).toLocaleDateString('en-US', { month: 'short', day: 'numeric' })}
                    </Text>
                  </View>
                )}
              </View>
            </View>
          ))}
        </View>
      )}
    </View>
  );
}

function EmptyState({ onAddBill }: { onAddBill: () => void }) {
  return (
    <View style={styles.emptyState}>
      <Ionicons name="card-outline" size={48} color={colors.slate[300]} />
      <Text style={styles.emptyTitle}>No bills set up yet</Text>
      <Text style={styles.emptySubtext}>
        Add your bills to track expenses and let Haven help manage them.
      </Text>
      <TouchableOpacity style={styles.addBillButton} onPress={onAddBill}>
        <Ionicons name="add" size={20} color={colors.white} />
        <Text style={styles.addBillButtonText}>Add Your First Bill</Text>
      </TouchableOpacity>
    </View>
  );
}

function ConnectBankCard({
  onConnect,
  isLinking,
  isSyncing,
  hasConnections,
}: {
  onConnect: () => void;
  isLinking: boolean;
  isSyncing: boolean;
  hasConnections: boolean;
}) {
  if (hasConnections) return null;

  return (
    <View style={styles.connectBankCard}>
      <View style={styles.connectBankIcon}>
        <Ionicons name="business-outline" size={28} color={colors.haven.champagne[500]} />
      </View>
      <View style={styles.connectBankContent}>
        <Text style={styles.connectBankTitle}>Connect Your Bank</Text>
        <Text style={styles.connectBankSubtitle}>
          Automatically detect and track your recurring bills
        </Text>
      </View>
      <TouchableOpacity
        style={[styles.connectBankButton, (isLinking || isSyncing) && styles.connectBankButtonDisabled]}
        onPress={onConnect}
        disabled={isLinking || isSyncing}
      >
        {isLinking || isSyncing ? (
          <ActivityIndicator size="small" color={colors.white} />
        ) : (
          <>
            <Ionicons name="link-outline" size={18} color={colors.white} />
            <Text style={styles.connectBankButtonText}>Connect</Text>
          </>
        )}
      </TouchableOpacity>
    </View>
  );
}

function DetectedBillsSection({
  bills,
  onConfirm,
  onDismiss,
  isLoading,
}: {
  bills: DetectedBill[];
  onConfirm: (billId: string) => void;
  onDismiss: (billId: string) => void;
  isLoading: boolean;
}) {
  const pendingBills = bills.filter((b) => b.status === 'DETECTED');

  if (pendingBills.length === 0) return null;

  return (
    <View style={styles.detectedBillsSection}>
      <View style={styles.detectedBillsHeader}>
        <View style={styles.detectedBillsHeaderLeft}>
          <View style={styles.detectedBillsBadge}>
            <Ionicons name="sparkles" size={16} color={colors.haven.champagne[500]} />
          </View>
          <View>
            <Text style={styles.detectedBillsTitle}>Bills Found!</Text>
            <Text style={styles.detectedBillsSubtitle}>
              We found {pendingBills.length} recurring bill{pendingBills.length !== 1 ? 's' : ''} in your transactions
            </Text>
          </View>
        </View>
      </View>

      <View style={styles.detectedBillsList}>
        {pendingBills.map((bill) => (
          <View key={bill.id} style={styles.detectedBillItem}>
            <View style={styles.detectedBillInfo}>
              <View style={styles.detectedBillIconContainer}>
                <Ionicons
                  name={getPlaidCategoryIcon(bill.category) as keyof typeof Ionicons.glyphMap}
                  size={20}
                  color={colors.haven.navy[600]}
                />
              </View>
              <View style={styles.detectedBillDetails}>
                <Text style={styles.detectedBillName}>{bill.visibleName}</Text>
                <Text style={styles.detectedBillMeta}>
                  {formatCurrencyDetailed(bill.lastAmount)} · {formatPlaidFrequency(bill.frequency)}
                </Text>
                {bill.accountName && (
                  <Text style={styles.detectedBillAccount}>From: {bill.accountName}</Text>
                )}
              </View>
            </View>
            <View style={styles.detectedBillActions}>
              <TouchableOpacity
                style={styles.confirmButton}
                onPress={() => onConfirm(bill.id)}
                disabled={isLoading}
              >
                <Ionicons name="checkmark" size={18} color={colors.white} />
              </TouchableOpacity>
              <TouchableOpacity
                style={styles.dismissButton}
                onPress={() => onDismiss(bill.id)}
                disabled={isLoading}
              >
                <Ionicons name="close" size={18} color={colors.slate[600]} />
              </TouchableOpacity>
            </View>
          </View>
        ))}
      </View>
    </View>
  );
}

// =============================================================================
// ADD BILL MODAL
// =============================================================================

const BILL_CATEGORIES = [
  { value: 'MORTGAGE_RENT', label: 'Mortgage/Rent' },
  { value: 'UTILITY', label: 'Utility' },
  { value: 'INSURANCE', label: 'Insurance' },
  { value: 'HOME_SERVICE', label: 'Home Service' },
  { value: 'VEHICLE', label: 'Vehicle' },
  { value: 'KID_ACTIVITY', label: 'Kid Activity' },
  { value: 'PET', label: 'Pet' },
  { value: 'HEALTH', label: 'Health' },
  { value: 'OTHER', label: 'Other' },
];

const FREQUENCIES = [
  { value: 'WEEKLY', label: 'Weekly' },
  { value: 'BIWEEKLY', label: 'Bi-weekly' },
  { value: 'MONTHLY', label: 'Monthly' },
  { value: 'QUARTERLY', label: 'Quarterly' },
  { value: 'ANNUALLY', label: 'Annually' },
];

function AddBillModal({
  visible,
  onClose,
  onSave,
  isLoading,
}: {
  visible: boolean;
  onClose: () => void;
  onSave: (bill: { name: string; category: string; amount: string; frequency: string; dueDay: string }) => void;
  isLoading: boolean;
}) {
  const [name, setName] = useState('');
  const [category, setCategory] = useState('UTILITY');
  const [amount, setAmount] = useState('');
  const [frequency, setFrequency] = useState('MONTHLY');
  const [dueDay, setDueDay] = useState('');
  const [showCategoryPicker, setShowCategoryPicker] = useState(false);
  const [showFrequencyPicker, setShowFrequencyPicker] = useState(false);

  const resetForm = () => {
    setName('');
    setCategory('UTILITY');
    setAmount('');
    setFrequency('MONTHLY');
    setDueDay('');
  };

  const handleClose = () => {
    resetForm();
    onClose();
  };

  const handleSave = () => {
    if (!name.trim()) {
      Alert.alert('Error', 'Please enter a bill name');
      return;
    }
    if (!amount.trim() || isNaN(parseFloat(amount))) {
      Alert.alert('Error', 'Please enter a valid amount');
      return;
    }
    onSave({ name: name.trim(), category, amount, frequency, dueDay });
    resetForm();
  };

  const selectedCategory = BILL_CATEGORIES.find(c => c.value === category);
  const selectedFrequency = FREQUENCIES.find(f => f.value === frequency);

  return (
    <Modal visible={visible} animationType="slide" transparent>
      <KeyboardAvoidingView
        behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
        style={styles.modalOverlay}
      >
        <View style={styles.modalContainer}>
          {/* Header */}
          <View style={styles.modalHeader}>
            <TouchableOpacity onPress={handleClose}>
              <Text style={styles.modalCancel}>Cancel</Text>
            </TouchableOpacity>
            <Text style={styles.modalTitle}>Add Bill</Text>
            <TouchableOpacity onPress={handleSave} disabled={isLoading}>
              <Text style={[styles.modalSave, isLoading && styles.modalSaveDisabled]}>
                {isLoading ? 'Saving...' : 'Save'}
              </Text>
            </TouchableOpacity>
          </View>

          <ScrollView style={styles.modalContent}>
            {/* Bill Name */}
            <View style={styles.formGroup}>
              <Text style={styles.formLabel}>Bill Name</Text>
              <TextInput
                style={styles.formInput}
                placeholder="e.g., Electric Bill, Netflix"
                placeholderTextColor={colors.slate[400]}
                value={name}
                onChangeText={setName}
              />
            </View>

            {/* Category */}
            <View style={styles.formGroup}>
              <Text style={styles.formLabel}>Category</Text>
              <TouchableOpacity
                style={styles.formSelect}
                onPress={() => setShowCategoryPicker(!showCategoryPicker)}
              >
                <Text style={styles.formSelectText}>{selectedCategory?.label || 'Select'}</Text>
                <Ionicons name="chevron-down" size={20} color={colors.slate[400]} />
              </TouchableOpacity>
              {showCategoryPicker && (
                <View style={styles.pickerList}>
                  {BILL_CATEGORIES.map((cat) => (
                    <TouchableOpacity
                      key={cat.value}
                      style={[styles.pickerItem, cat.value === category && styles.pickerItemSelected]}
                      onPress={() => {
                        setCategory(cat.value);
                        setShowCategoryPicker(false);
                      }}
                    >
                      <Text
                        style={[
                          styles.pickerItemText,
                          cat.value === category && styles.pickerItemTextSelected,
                        ]}
                      >
                        {cat.label}
                      </Text>
                      {cat.value === category && (
                        <Ionicons name="checkmark" size={18} color={colors.haven.champagne[500]} />
                      )}
                    </TouchableOpacity>
                  ))}
                </View>
              )}
            </View>

            {/* Amount */}
            <View style={styles.formGroup}>
              <Text style={styles.formLabel}>Amount</Text>
              <View style={styles.amountInputContainer}>
                <Text style={styles.currencyPrefix}>$</Text>
                <TextInput
                  style={styles.amountInput}
                  placeholder="0.00"
                  placeholderTextColor={colors.slate[400]}
                  value={amount}
                  onChangeText={setAmount}
                  keyboardType="decimal-pad"
                />
              </View>
            </View>

            {/* Frequency */}
            <View style={styles.formGroup}>
              <Text style={styles.formLabel}>Frequency</Text>
              <TouchableOpacity
                style={styles.formSelect}
                onPress={() => setShowFrequencyPicker(!showFrequencyPicker)}
              >
                <Text style={styles.formSelectText}>{selectedFrequency?.label || 'Select'}</Text>
                <Ionicons name="chevron-down" size={20} color={colors.slate[400]} />
              </TouchableOpacity>
              {showFrequencyPicker && (
                <View style={styles.pickerList}>
                  {FREQUENCIES.map((freq) => (
                    <TouchableOpacity
                      key={freq.value}
                      style={[styles.pickerItem, freq.value === frequency && styles.pickerItemSelected]}
                      onPress={() => {
                        setFrequency(freq.value);
                        setShowFrequencyPicker(false);
                      }}
                    >
                      <Text
                        style={[
                          styles.pickerItemText,
                          freq.value === frequency && styles.pickerItemTextSelected,
                        ]}
                      >
                        {freq.label}
                      </Text>
                      {freq.value === frequency && (
                        <Ionicons name="checkmark" size={18} color={colors.haven.champagne[500]} />
                      )}
                    </TouchableOpacity>
                  ))}
                </View>
              )}
            </View>

            {/* Due Day */}
            <View style={styles.formGroup}>
              <Text style={styles.formLabel}>Due Day (optional)</Text>
              <TextInput
                style={styles.formInput}
                placeholder="e.g., 15 (day of month)"
                placeholderTextColor={colors.slate[400]}
                value={dueDay}
                onChangeText={setDueDay}
                keyboardType="number-pad"
                maxLength={2}
              />
            </View>
          </ScrollView>
        </View>
      </KeyboardAvoidingView>
    </Modal>
  );
}

// =============================================================================
// MAIN COMPONENT
// =============================================================================

export default function BillingScreen() {
  const { householdInfo } = useAuth();
  const {
    connections,
    detectedBills,
    isLinking,
    isSyncing,
    isLoading: plaidLoading,
    connectBank,
    refreshConnections,
    refreshDetectedBills,
    confirmBill,
    dismissBill,
  } = usePlaid();

  const [data, setData] = useState<BillsData | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [expandedCategories, setExpandedCategories] = useState<Set<string>>(new Set());
  const [showAddModal, setShowAddModal] = useState(false);
  const [isSaving, setIsSaving] = useState(false);

  const fetchBills = useCallback(async () => {
    if (!householdInfo?.id) {
      setIsLoading(false);
      return;
    }

    try {
      const token = await getIdToken(true);
      if (!token) {
        setIsLoading(false);
        return;
      }

      const response = await fetch(
        `${API_BASE_URL}/dashboard/household/${householdInfo.id}/bills`,
        {
          headers: { Authorization: `Bearer ${token}` },
        }
      );

      if (!response.ok) {
        throw new Error('Failed to load bills');
      }

      const result: BillsData = await response.json();
      setData(result);

      // Expand first category by default
      if (result.byCategory.length > 0) {
        setExpandedCategories(new Set([result.byCategory[0].category]));
      }
    } catch (err) {
      console.error('Bills error:', err);
      setError(err instanceof Error ? err.message : 'Unknown error');
    } finally {
      setIsLoading(false);
    }
  }, [householdInfo?.id]);

  useEffect(() => {
    fetchBills();
  }, [fetchBills]);

  // Load Plaid data on mount
  useEffect(() => {
    if (householdInfo?.id) {
      refreshConnections(householdInfo.id);
      refreshDetectedBills(householdInfo.id);
    }
  }, [householdInfo?.id, refreshConnections, refreshDetectedBills]);

  const onRefresh = useCallback(async () => {
    setRefreshing(true);
    await Promise.all([
      fetchBills(),
      householdInfo?.id ? refreshConnections(householdInfo.id) : Promise.resolve(),
      householdInfo?.id ? refreshDetectedBills(householdInfo.id) : Promise.resolve(),
    ]);
    setRefreshing(false);
  }, [fetchBills, householdInfo?.id, refreshConnections, refreshDetectedBills]);

  const toggleCategory = (category: string) => {
    setExpandedCategories((prev) => {
      const next = new Set(prev);
      if (next.has(category)) {
        next.delete(category);
      } else {
        next.add(category);
      }
      return next;
    });
  };

  const getBillsForCategory = (category: string) => {
    return data?.bills.filter((b) => b.category === category) || [];
  };

  const handleConnectBank = useCallback(async () => {
    if (!householdInfo?.id) return;
    const result = await connectBank(householdInfo.id);
    if (result.success) {
      // Refresh bills after successful connection
      fetchBills();
    } else if (result.error) {
      Alert.alert('Connection Error', result.error);
    }
  }, [householdInfo?.id, connectBank, fetchBills]);

  const handleConfirmBill = useCallback(async (billId: string) => {
    try {
      await confirmBill(billId);
      // Refresh the main bills list to show the confirmed bill
      fetchBills();
      Alert.alert('Bill Added', 'The bill has been added to your bill list.');
    } catch {
      Alert.alert('Error', 'Failed to confirm bill. Please try again.');
    }
  }, [confirmBill, fetchBills]);

  const handleDismissBill = useCallback(async (billId: string) => {
    try {
      await dismissBill(billId);
    } catch {
      Alert.alert('Error', 'Failed to dismiss bill. Please try again.');
    }
  }, [dismissBill]);

  const handleAddBill = async (bill: {
    name: string;
    category: string;
    amount: string;
    frequency: string;
    dueDay: string;
  }) => {
    if (!householdInfo?.id) return;

    setIsSaving(true);
    try {
      const token = await getIdToken(true);
      if (!token) {
        Alert.alert('Error', 'Authentication expired');
        return;
      }

      const response = await fetch(
        `${API_BASE_URL}/dashboard/household/${householdInfo.id}/bills`,
        {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${token}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            name: bill.name,
            category: bill.category,
            amount: parseFloat(bill.amount),
            frequency: bill.frequency,
            dueDay: bill.dueDay ? parseInt(bill.dueDay, 10) : null,
          }),
        }
      );

      if (!response.ok) {
        throw new Error('Failed to add bill');
      }

      setShowAddModal(false);
      fetchBills(); // Refresh the bills list
      Alert.alert('Success', 'Bill added successfully');
    } catch (err) {
      console.error('Add bill error:', err);
      Alert.alert('Error', 'Failed to add bill. Please try again.');
    } finally {
      setIsSaving(false);
    }
  };

  if (isLoading) {
    return (
      <SafeAreaView style={styles.loadingContainer} edges={['bottom']}>
        <ActivityIndicator size="large" color={colors.haven.champagne[500]} />
      </SafeAreaView>
    );
  }

  if (!householdInfo?.id) {
    return (
      <SafeAreaView style={styles.container} edges={['bottom']}>
        <View style={styles.centerContent}>
          <Ionicons name="wallet-outline" size={48} color={colors.slate[300]} />
          <Text style={styles.emptyTitle}>No household found</Text>
          <Text style={styles.emptySubtext}>Complete onboarding to view billing</Text>
        </View>
      </SafeAreaView>
    );
  }

  if (error) {
    return (
      <SafeAreaView style={styles.container} edges={['bottom']}>
        <View style={styles.centerContent}>
          <Ionicons name="alert-circle-outline" size={48} color={colors.status.error} />
          <Text style={[styles.emptyTitle, { color: colors.status.error }]}>Error loading bills</Text>
          <Text style={styles.emptySubtext}>{error}</Text>
          <TouchableOpacity style={styles.retryButton} onPress={fetchBills}>
            <Text style={styles.retryButtonText}>Try Again</Text>
          </TouchableOpacity>
        </View>
      </SafeAreaView>
    );
  }

  if (!data || data.bills.length === 0) {
    return (
      <SafeAreaView style={styles.container} edges={['bottom']}>
        <ScrollView
          contentContainerStyle={styles.scrollContent}
          refreshControl={
            <RefreshControl
              refreshing={refreshing}
              onRefresh={onRefresh}
              tintColor={colors.haven.champagne[500]}
            />
          }
        >
          {/* Connect Bank Card - Show prominently even when no bills */}
          <ConnectBankCard
            onConnect={handleConnectBank}
            isLinking={isLinking}
            isSyncing={isSyncing}
            hasConnections={connections.length > 0}
          />

          {/* Detected Bills Section - may have bills from Plaid even if no manual bills */}
          <DetectedBillsSection
            bills={detectedBills}
            onConfirm={handleConfirmBill}
            onDismiss={handleDismissBill}
            isLoading={plaidLoading}
          />

          <EmptyState onAddBill={() => setShowAddModal(true)} />
        </ScrollView>
        <AddBillModal
          visible={showAddModal}
          onClose={() => setShowAddModal(false)}
          onSave={handleAddBill}
          isLoading={isSaving}
        />
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView style={styles.container} edges={['bottom']}>
      <ScrollView
        contentContainerStyle={styles.scrollContent}
        refreshControl={
          <RefreshControl
            refreshing={refreshing}
            onRefresh={onRefresh}
            tintColor={colors.haven.champagne[500]}
          />
        }
      >
        {/* Summary Header */}
        <SummaryHeader summary={data.summary} />

        {/* Connect Bank Card */}
        <ConnectBankCard
          onConnect={handleConnectBank}
          isLinking={isLinking}
          isSyncing={isSyncing}
          hasConnections={connections.length > 0}
        />

        {/* Detected Bills Section */}
        <DetectedBillsSection
          bills={detectedBills}
          onConfirm={handleConfirmBill}
          onDismiss={handleDismissBill}
          isLoading={plaidLoading}
        />

        {/* Bills by Category */}
        <View style={styles.categoriesSection}>
          {data.byCategory.map((category) => (
            <CategoryCard
              key={category.category}
              category={category}
              bills={getBillsForCategory(category.category)}
              isExpanded={expandedCategories.has(category.category)}
              onToggle={() => toggleCategory(category.category)}
            />
          ))}
        </View>

        {/* Quick Actions */}
        <View style={styles.quickActions}>
          <TouchableOpacity style={styles.actionCard}>
            <View style={styles.actionContent}>
              <View>
                <Text style={styles.actionTitle}>Monthly Statement</Text>
                <Text style={styles.actionSubtitle}>Download your detailed bill statement</Text>
              </View>
              <View style={styles.actionButton}>
                <Ionicons name="download-outline" size={20} color={colors.haven.navy[700]} />
                <Text style={styles.actionButtonText}>PDF</Text>
              </View>
            </View>
          </TouchableOpacity>
        </View>

        {/* Info Banner */}
        <View style={styles.infoBanner}>
          <Ionicons name="information-circle-outline" size={20} color={colors.haven.navy[600]} />
          <Text style={styles.infoBannerText}>
            Haven automatically pays your bills on time. Sit back and relax!
          </Text>
        </View>
      </ScrollView>

      {/* Floating Add Button */}
      <TouchableOpacity
        style={styles.fab}
        onPress={() => setShowAddModal(true)}
        activeOpacity={0.8}
      >
        <Ionicons name="add" size={28} color={colors.white} />
      </TouchableOpacity>

      {/* Add Bill Modal */}
      <AddBillModal
        visible={showAddModal}
        onClose={() => setShowAddModal(false)}
        onSave={handleAddBill}
        isLoading={isSaving}
      />
    </SafeAreaView>
  );
}

// =============================================================================
// STYLES
// =============================================================================

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.slate[50],
  },
  loadingContainer: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: colors.slate[50],
  },
  centerContent: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    padding: spacing[6],
  },
  scrollContent: {
    padding: spacing[4],
    paddingBottom: spacing[8],
  },

  // Summary Header
  summaryCard: {
    backgroundColor: colors.haven.navy[800],
    borderRadius: borderRadius.xl,
    padding: spacing[6],
    marginBottom: spacing[6],
    overflow: 'hidden',
  },
  summaryHeader: {
    marginBottom: spacing[2],
  },
  summaryLabel: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[2],
  },
  summaryLabelText: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.champagne[200],
  },
  summaryAmount: {
    fontSize: 40,
    fontWeight: typography.fontWeights.bold,
    color: colors.white,
    marginBottom: spacing[1],
  },
  summarySubtext: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.champagne[200],
    marginBottom: spacing[4],
  },
  fundingSection: {
    backgroundColor: 'rgba(255, 255, 255, 0.1)',
    borderRadius: borderRadius.lg,
    padding: spacing[4],
  },
  fundingHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: spacing[2],
  },
  fundingLabel: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.champagne[200],
  },
  fundingAmount: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.white,
  },
  progressBar: {
    height: 8,
    backgroundColor: 'rgba(255, 255, 255, 0.2)',
    borderRadius: borderRadius.full,
    overflow: 'hidden',
  },
  progressFill: {
    height: '100%',
    backgroundColor: colors.haven.champagne[500],
    borderRadius: borderRadius.full,
  },
  fundingBuffer: {
    fontSize: typography.fontSizes.xs,
    color: colors.haven.champagne[200],
    marginTop: spacing[2],
  },

  // Categories Section
  categoriesSection: {
    gap: spacing[4],
    marginBottom: spacing[6],
  },
  categoryCard: {
    backgroundColor: colors.white,
    borderRadius: borderRadius.xl,
    overflow: 'hidden',
    ...shadows.sm,
  },
  categoryHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    padding: spacing[4],
  },
  categoryLeft: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[3],
  },
  categoryIcon: {
    width: 44,
    height: 44,
    borderRadius: borderRadius.lg,
    alignItems: 'center',
    justifyContent: 'center',
  },
  categoryName: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.slate[900],
  },
  categoryCount: {
    fontSize: typography.fontSizes.sm,
    color: colors.slate[500],
    marginTop: 2,
  },
  categoryRight: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[2],
  },
  categoryTotal: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.slate[900],
  },

  // Bills List (expanded)
  billsList: {
    borderTopWidth: 1,
    borderTopColor: colors.slate[100],
    paddingHorizontal: spacing[4],
    paddingBottom: spacing[4],
  },
  billItem: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    paddingVertical: spacing[3],
    paddingHorizontal: spacing[3],
    backgroundColor: colors.slate[50],
    borderRadius: borderRadius.lg,
    marginTop: spacing[3],
  },
  billInfo: {
    flex: 1,
    marginRight: spacing[3],
  },
  billNameRow: {
    flexDirection: 'row',
    alignItems: 'center',
    flexWrap: 'wrap',
    gap: spacing[2],
  },
  billName: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
    color: colors.slate[900],
  },
  havenBadge: {
    backgroundColor: colors.status.success + '20',
    paddingHorizontal: spacing[2],
    paddingVertical: 2,
    borderRadius: borderRadius.sm,
  },
  havenBadgeText: {
    fontSize: 11,  // Minimum for badges
    fontWeight: typography.fontWeights.semibold,  // Bolder to compensate
    color: colors.status.success,
  },
  billPayee: {
    fontSize: typography.fontSizes.xs,
    color: colors.slate[500],
    marginTop: 2,
  },
  billRight: {
    alignItems: 'flex-end',
  },
  billAmount: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
    color: colors.slate[900],
  },
  billFrequency: {
    fontSize: typography.fontSizes.xs,
    fontWeight: typography.fontWeights.normal,
    color: colors.slate[400],
  },
  billDue: {
    fontSize: typography.fontSizes.xs,
    color: colors.slate[500],
    marginTop: 2,
  },
  paidRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    marginTop: 4,
  },
  paidText: {
    fontSize: typography.fontSizes.xs,
    color: colors.status.success,
  },

  // Quick Actions
  quickActions: {
    marginBottom: spacing[4],
  },
  actionCard: {
    backgroundColor: colors.white,
    borderRadius: borderRadius.xl,
    padding: spacing[4],
    ...shadows.sm,
  },
  actionContent: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  actionTitle: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.slate[900],
  },
  actionSubtitle: {
    fontSize: typography.fontSizes.sm,
    color: colors.slate[500],
    marginTop: 2,
  },
  actionButton: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[1],
    backgroundColor: colors.slate[100],
    paddingHorizontal: spacing[3],
    paddingVertical: spacing[2],
    borderRadius: borderRadius.lg,
  },
  actionButtonText: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.haven.navy[700],
  },

  // Info Banner
  infoBanner: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[3],
    backgroundColor: colors.haven.navy[50],
    borderRadius: borderRadius.lg,
    padding: spacing[4],
    borderWidth: 1,
    borderColor: colors.haven.navy[100],
  },
  infoBannerText: {
    flex: 1,
    fontSize: typography.fontSizes.sm,
    color: colors.haven.navy[700],
    lineHeight: 20,
  },

  // Empty State
  emptyState: {
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: spacing[12],
  },
  emptyTitle: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.medium,
    color: colors.slate[600],
    marginTop: spacing[4],
    textAlign: 'center',
  },
  emptySubtext: {
    fontSize: typography.fontSizes.sm,
    color: colors.slate[400],
    marginTop: spacing[2],
    textAlign: 'center',
    maxWidth: 280,
  },

  // Retry Button
  retryButton: {
    backgroundColor: colors.haven.champagne[500],
    paddingHorizontal: spacing[6],
    paddingVertical: spacing[3],
    borderRadius: borderRadius.lg,
    marginTop: spacing[4],
  },
  retryButtonText: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
    color: colors.white,
  },

  // Add Bill Button (Empty State)
  addBillButton: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[2],
    backgroundColor: colors.haven.champagne[500],
    paddingHorizontal: spacing[6],
    paddingVertical: spacing[4],
    borderRadius: borderRadius.xl,
    marginTop: spacing[6],
  },
  addBillButtonText: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.white,
  },

  // FAB
  fab: {
    position: 'absolute',
    bottom: spacing[6],
    right: spacing[4],
    width: 56,
    height: 56,
    borderRadius: 28,
    backgroundColor: colors.haven.champagne[500],
    alignItems: 'center',
    justifyContent: 'center',
    ...shadows.md,
  },

  // Modal Styles
  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0, 0, 0, 0.5)',
    justifyContent: 'flex-end',
  },
  modalContainer: {
    backgroundColor: colors.white,
    borderTopLeftRadius: borderRadius['2xl'],
    borderTopRightRadius: borderRadius['2xl'],
    maxHeight: '90%',
  },
  modalHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    padding: spacing[4],
    borderBottomWidth: 1,
    borderBottomColor: colors.slate[100],
  },
  modalCancel: {
    fontSize: typography.fontSizes.base,
    color: colors.slate[500],
  },
  modalTitle: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.semibold,
    color: colors.slate[900],
  },
  modalSave: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.haven.champagne[500],
  },
  modalSaveDisabled: {
    color: colors.slate[300],
  },
  modalContent: {
    padding: spacing[4],
    paddingBottom: spacing[8],
  },

  // Form Styles
  formGroup: {
    marginBottom: spacing[5],
  },
  formLabel: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.slate[700],
    marginBottom: spacing[2],
  },
  formInput: {
    backgroundColor: colors.slate[50],
    borderRadius: borderRadius.lg,
    padding: spacing[4],
    fontSize: typography.fontSizes.base,
    color: colors.slate[900],
    borderWidth: 1,
    borderColor: colors.slate[200],
  },
  formSelect: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    backgroundColor: colors.slate[50],
    borderRadius: borderRadius.lg,
    padding: spacing[4],
    borderWidth: 1,
    borderColor: colors.slate[200],
  },
  formSelectText: {
    fontSize: typography.fontSizes.base,
    color: colors.slate[900],
  },
  amountInputContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.slate[50],
    borderRadius: borderRadius.lg,
    borderWidth: 1,
    borderColor: colors.slate[200],
  },
  currencyPrefix: {
    fontSize: typography.fontSizes.lg,
    color: colors.slate[500],
    paddingLeft: spacing[4],
  },
  amountInput: {
    flex: 1,
    padding: spacing[4],
    fontSize: typography.fontSizes.base,
    color: colors.slate[900],
  },
  pickerList: {
    marginTop: spacing[2],
    backgroundColor: colors.white,
    borderRadius: borderRadius.lg,
    borderWidth: 1,
    borderColor: colors.slate[200],
    overflow: 'hidden',
  },
  pickerItem: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    padding: spacing[4],
    borderBottomWidth: 1,
    borderBottomColor: colors.slate[100],
  },
  pickerItemSelected: {
    backgroundColor: colors.haven.champagne[50],
  },
  pickerItemText: {
    fontSize: typography.fontSizes.base,
    color: colors.slate[700],
  },
  pickerItemTextSelected: {
    color: colors.haven.champagne[600],
    fontWeight: typography.fontWeights.medium,
  },

  // Connect Bank Card
  connectBankCard: {
    backgroundColor: colors.white,
    borderRadius: borderRadius.xl,
    padding: spacing[4],
    marginBottom: spacing[4],
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[3],
    borderWidth: 1,
    borderColor: colors.haven.champagne[200],
    borderStyle: 'dashed',
    ...shadows.sm,
  },
  connectBankIcon: {
    width: 48,
    height: 48,
    borderRadius: borderRadius.lg,
    backgroundColor: colors.haven.champagne[50],
    alignItems: 'center',
    justifyContent: 'center',
  },
  connectBankContent: {
    flex: 1,
  },
  connectBankTitle: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.slate[900],
  },
  connectBankSubtitle: {
    fontSize: typography.fontSizes.sm,
    color: colors.slate[500],
    marginTop: 2,
  },
  connectBankButton: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[1],
    backgroundColor: colors.haven.champagne[500],
    paddingHorizontal: spacing[4],
    paddingVertical: spacing[2],
    borderRadius: borderRadius.lg,
  },
  connectBankButtonDisabled: {
    backgroundColor: colors.slate[300],
  },
  connectBankButtonText: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
    color: colors.white,
  },

  // Detected Bills Section
  detectedBillsSection: {
    backgroundColor: colors.haven.champagne[50],
    borderRadius: borderRadius.xl,
    marginBottom: spacing[6],
    overflow: 'hidden',
    borderWidth: 1,
    borderColor: colors.haven.champagne[200],
  },
  detectedBillsHeader: {
    padding: spacing[4],
    borderBottomWidth: 1,
    borderBottomColor: colors.haven.champagne[200],
  },
  detectedBillsHeaderLeft: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[3],
  },
  detectedBillsBadge: {
    width: 36,
    height: 36,
    borderRadius: borderRadius.full,
    backgroundColor: colors.white,
    alignItems: 'center',
    justifyContent: 'center',
    ...shadows.sm,
  },
  detectedBillsTitle: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.slate[900],
  },
  detectedBillsSubtitle: {
    fontSize: typography.fontSizes.sm,
    color: colors.slate[600],
    marginTop: 2,
  },
  detectedBillsList: {
    padding: spacing[3],
  },
  detectedBillItem: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    backgroundColor: colors.white,
    borderRadius: borderRadius.lg,
    padding: spacing[3],
    marginBottom: spacing[2],
    ...shadows.sm,
  },
  detectedBillInfo: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[3],
  },
  detectedBillIconContainer: {
    width: 40,
    height: 40,
    borderRadius: borderRadius.lg,
    backgroundColor: colors.slate[100],
    alignItems: 'center',
    justifyContent: 'center',
  },
  detectedBillDetails: {
    flex: 1,
  },
  detectedBillName: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
    color: colors.slate[900],
  },
  detectedBillMeta: {
    fontSize: typography.fontSizes.xs,
    color: colors.slate[600],
    marginTop: 2,
  },
  detectedBillAccount: {
    fontSize: typography.fontSizes.xs,
    color: colors.slate[400],
    marginTop: 2,
  },
  detectedBillActions: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[2],
  },
  confirmButton: {
    width: 36,
    height: 36,
    borderRadius: borderRadius.full,
    backgroundColor: colors.status.success,
    alignItems: 'center',
    justifyContent: 'center',
  },
  dismissButton: {
    width: 36,
    height: 36,
    borderRadius: borderRadius.full,
    backgroundColor: colors.slate[100],
    alignItems: 'center',
    justifyContent: 'center',
  },
});

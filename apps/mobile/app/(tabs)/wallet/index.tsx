import { useEffect, useState, useCallback } from 'react';
import {
  View,
  Text,
  ScrollView,
  StyleSheet,
  RefreshControl,
  TouchableOpacity,
  ActivityIndicator,
  Linking,
  Alert,
} from 'react-native';
import { useRouter } from 'expo-router';
import { useAuth } from '../../../src/contexts/auth-context';
import { ScreenContainer } from '../../../src/components';
import { colors, spacing, typography, borderRadius, shadows } from '../../../src/lib/theme';
import { API_BASE_URL } from '../../../src/lib/api';
import type { Transaction, TransactionStatus, TransactionPayoutMethod, ClientBankAccount, MonthlyInvoiceListItem, MonthlyInvoiceStatus } from '@haven/core';

// Mock data for demo - in production these would come from the API
const mockTransactions: Transaction[] = [
  {
    id: 'tx-1',
    householdId: 'demo-household-id',
    vendorId: 'v3',
    managerId: 'manager-steve',
    description: 'Pool Cleaning',
    amount: 150,
    payoutMethod: 'COMPANY_CARD',
    status: 'PAID_TO_VENDOR',
    isReimbursable: true,
    paidAt: new Date(Date.now() - 86400000).toISOString(), // Yesterday
    billedAt: null,
    settledAt: null,
    receiptUrl: null,
    receiptFileId: null,
    workOrderId: null,
    maintenanceTaskId: null,
    householdInvoiceId: null,
    notes: null,
    createdAt: new Date(Date.now() - 86400000).toISOString(),
    updatedAt: new Date(Date.now() - 86400000).toISOString(),
    vendor: { id: 'v3', displayName: 'Crystal Pool Service', category: 'POOL_SERVICE' },
    manager: { id: 'manager-steve', firstName: 'Steve', lastName: 'Manager', email: 'steve@haven.app' },
    household: { id: 'demo-household-id', name: "Bob's Villa" },
  },
  {
    id: 'tx-2',
    householdId: 'demo-household-id',
    vendorId: 'v4',
    managerId: 'manager-steve',
    description: 'Emergency Locksmith',
    amount: 300,
    payoutMethod: 'CASH',
    status: 'PAID_TO_VENDOR',
    isReimbursable: true,
    paidAt: new Date().toISOString(), // Today
    billedAt: null,
    settledAt: null,
    receiptUrl: null,
    receiptFileId: null,
    workOrderId: null,
    maintenanceTaskId: null,
    householdInvoiceId: null,
    notes: null,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
    vendor: { id: 'v4', displayName: 'SecureLock Locksmith', category: 'HANDYMAN' },
    manager: { id: 'manager-steve', firstName: 'Steve', lastName: 'Manager', email: 'steve@haven.app' },
    household: { id: 'demo-household-id', name: "Bob's Villa" },
  },
  {
    id: 'tx-3',
    householdId: 'demo-household-id',
    vendorId: 'v5',
    managerId: 'manager-steve',
    description: 'Management Fee',
    amount: 100,
    payoutMethod: 'STRIPE',
    status: 'PENDING',
    isReimbursable: true,
    paidAt: null,
    billedAt: null,
    settledAt: null,
    receiptUrl: null,
    receiptFileId: null,
    workOrderId: null,
    maintenanceTaskId: null,
    householdInvoiceId: null,
    notes: 'Monthly management fee',
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
    vendor: { id: 'v5', displayName: 'Haven Home Management', category: 'OTHER' },
    manager: { id: 'manager-steve', firstName: 'Steve', lastName: 'Manager', email: 'steve@haven.app' },
    household: { id: 'demo-household-id', name: "Bob's Villa" },
  },
];

const mockBankAccount: ClientBankAccount = {
  id: 'bank-1',
  householdId: 'demo-household-id',
  stripePaymentMethodId: 'pm_xxx',
  stripeBankAccountId: 'ba_xxx',
  bankName: 'Chase',
  accountType: 'checking',
  last4: '4242',
  routingLast4: '1234',
  isVerified: true,
  verifiedAt: new Date().toISOString(),
  isDefault: true,
  isActive: true,
  createdAt: new Date().toISOString(),
  updatedAt: new Date().toISOString(),
};

// Mock statements data - showing past monthly invoices including one PAST_DUE
const mockStatements: MonthlyInvoiceListItem[] = [
  {
    id: 'inv-nov-2024',
    invoiceNumber: 'INV-2024-1101',
    billingPeriodStart: '2024-11-01',
    billingPeriodEnd: '2024-11-30',
    total: 1450.00,
    status: 'PAST_DUE',
    itemCount: 5,
    createdAt: '2024-12-01T00:00:00Z',
  },
  {
    id: 'inv-oct-2024',
    invoiceNumber: 'INV-2024-1001',
    billingPeriodStart: '2024-10-01',
    billingPeriodEnd: '2024-10-31',
    total: 1125.50,
    status: 'PAID',
    itemCount: 4,
    paidAt: '2024-11-03T14:30:00Z',
    createdAt: '2024-11-01T00:00:00Z',
  },
  {
    id: 'inv-sep-2024',
    invoiceNumber: 'INV-2024-0901',
    billingPeriodStart: '2024-09-01',
    billingPeriodEnd: '2024-09-30',
    total: 875.00,
    status: 'PAID',
    itemCount: 3,
    paidAt: '2024-10-02T10:15:00Z',
    createdAt: '2024-10-01T00:00:00Z',
  },
  {
    id: 'inv-aug-2024',
    invoiceNumber: 'INV-2024-0801',
    billingPeriodStart: '2024-08-01',
    billingPeriodEnd: '2024-08-31',
    total: 2350.00,
    status: 'PAID',
    itemCount: 8,
    paidAt: '2024-09-01T16:45:00Z',
    createdAt: '2024-09-01T00:00:00Z',
  },
];

const STATEMENT_STATUS_LABELS: Record<MonthlyInvoiceStatus, string> = {
  PENDING: 'Pending',
  PROCESSING: 'Processing',
  PAID: 'Paid',
  FAILED: 'Failed',
  PAST_DUE: 'Past Due',
};

const STATEMENT_STATUS_COLORS: Record<MonthlyInvoiceStatus, string> = {
  PENDING: colors.warning,
  PROCESSING: colors.info,
  PAID: colors.success,
  FAILED: colors.error,
  PAST_DUE: colors.error,
};

const STATUS_LABELS: Record<TransactionStatus, string> = {
  PENDING: 'Accrued',
  PAID_TO_VENDOR: 'Paid by Haven',
  BILLED_TO_CLIENT: 'On Invoice',
  SETTLED: 'Settled',
  CANCELLED: 'Cancelled',
};

const STATUS_COLORS: Record<TransactionStatus, string> = {
  PENDING: colors.warning,
  PAID_TO_VENDOR: colors.info,
  BILLED_TO_CLIENT: colors.haven.purple[600],
  SETTLED: colors.success,
  CANCELLED: colors.slate[400],
};

const PAYOUT_ICONS: Record<TransactionPayoutMethod, string> = {
  CHECKBOOK_IO: 'Check',
  STRIPE: 'Transfer',
  CASH: 'Cash',
  COMPANY_CARD: 'Card',
  BANK_TRANSFER: 'Bank',
};

// API_BASE_URL is imported from ../../src/lib/api

export default function WalletScreen() {
  const router = useRouter();
  const { currentHousehold } = useAuth();
  const [transactions, setTransactions] = useState<Transaction[]>([]);
  const [bankAccount, setBankAccount] = useState<ClientBankAccount | null>(null);
  const [statements, setStatements] = useState<MonthlyInvoiceListItem[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);

  // Check if there's a past due or failed invoice
  const hasPastDue = statements.some((s) => s.status === 'PAST_DUE' || s.status === 'FAILED');

  const fetchData = useCallback(async () => {
    // In production, this would call the API
    // For now, we use mock data
    await new Promise((resolve) => setTimeout(resolve, 500));
    setTransactions(mockTransactions);
    setBankAccount(mockBankAccount);
    setStatements(mockStatements);
    setIsLoading(false);
  }, []);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  const onRefresh = useCallback(async () => {
    setRefreshing(true);
    await fetchData();
    setRefreshing(false);
  }, [fetchData]);

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
    }).format(amount);
  };

  const formatDate = (dateStr: string | null) => {
    if (!dateStr) return '';
    const date = new Date(dateStr);
    const now = new Date();
    const diffDays = Math.floor((now.getTime() - date.getTime()) / (1000 * 60 * 60 * 24));

    if (diffDays === 0) return 'Today';
    if (diffDays === 1) return 'Yesterday';
    if (diffDays < 7) return `${diffDays} days ago`;

    return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
  };

  const formatBillingPeriod = (startDate: string) => {
    const date = new Date(startDate);
    return date.toLocaleDateString('en-US', { month: 'long', year: 'numeric' });
  };

  const openStatementPdf = async (invoiceId: string) => {
    const pdfUrl = `${API_BASE_URL}/settlement/invoices/${invoiceId}/pdf`;
    try {
      const supported = await Linking.canOpenURL(pdfUrl);
      if (supported) {
        await Linking.openURL(pdfUrl);
      } else {
        Alert.alert('Error', 'Unable to open PDF. Please try again later.');
      }
    } catch {
      Alert.alert('Error', 'Failed to open statement PDF.');
    }
  };

  // Calculate current month balance (pending + paid to vendor but not yet reimbursed)
  const currentMonthBalance = transactions
    .filter((t) => (t.status === 'PAID_TO_VENDOR' || t.status === 'PENDING') && t.isReimbursable)
    .reduce((sum, t) => sum + t.amount, 0);

  if (isLoading) {
    return (
      <ScreenContainer title="Wallet" onBackPress={() => router.navigate('/more')}>
        <View style={styles.loadingContainer}>
          <ActivityIndicator size="large" color={colors.haven.purple[600]} />
        </View>
      </ScreenContainer>
    );
  }

  if (!currentHousehold) {
    return (
      <ScreenContainer title="Wallet" onBackPress={() => router.navigate('/more')}>
        <View style={styles.emptyCard}>
          <Text style={styles.emptyText}>Select a household to view wallet</Text>
        </View>
      </ScreenContainer>
    );
  }

  return (
    <ScreenContainer
      title="Wallet"
      onBackPress={() => router.navigate('/more')}
      refreshing={refreshing}
      onRefresh={onRefresh}
    >
        {/* Past Due Alert Banner */}
        {hasPastDue && (
          <View style={styles.alertBanner}>
            <View style={styles.alertBadge}>
              <Text style={styles.alertBadgeText}>!</Text>
            </View>
            <View style={styles.alertContent}>
              <Text style={styles.alertTitle}>Payment Failed</Text>
              <Text style={styles.alertText}>Update your bank info to resolve</Text>
            </View>
            <TouchableOpacity style={styles.alertButton}>
              <Text style={styles.alertButtonText}>Update</Text>
            </TouchableOpacity>
          </View>
        )}

        {/* Current Month Balance - Big Bold */}
        <View style={styles.balanceCard}>
          <Text style={styles.balanceLabel}>Current Month Balance</Text>
          <Text style={styles.balanceAmount}>{formatCurrency(currentMonthBalance)}</Text>
          <Text style={styles.balanceSubtext}>
            Expenses paid by Haven, pending reimbursement
          </Text>
        </View>

        {/* Quick Stats */}
        <View style={styles.statsRow}>
          <View style={styles.statItem}>
            <Text style={styles.statValue}>
              {transactions.filter((t) => t.status === 'PAID_TO_VENDOR').length}
            </Text>
            <Text style={styles.statLabel}>Paid</Text>
          </View>
          <View style={styles.statDivider} />
          <View style={styles.statItem}>
            <Text style={styles.statValue}>
              {transactions.filter((t) => t.status === 'PENDING').length}
            </Text>
            <Text style={styles.statLabel}>Pending</Text>
          </View>
          <View style={styles.statDivider} />
          <View style={styles.statItem}>
            <Text style={styles.statValue}>
              {transactions.filter((t) => t.status === 'SETTLED').length}
            </Text>
            <Text style={styles.statLabel}>Settled</Text>
          </View>
        </View>

        {/* Payment Method Card */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Payment Method</Text>
          {bankAccount ? (
            <View style={styles.bankCard}>
              <View style={styles.bankIcon}>
                <View style={styles.bankIconInner}>
                  <Text style={styles.bankIconText}>$</Text>
                </View>
              </View>
              <View style={styles.bankInfo}>
                <Text style={styles.bankName}>{bankAccount.bankName}</Text>
                <Text style={styles.bankDetails}>
                  {bankAccount.accountType.charAt(0).toUpperCase() + bankAccount.accountType.slice(1)} ****{bankAccount.last4}
                </Text>
              </View>
              <TouchableOpacity style={styles.changeButton}>
                <Text style={styles.changeButtonText}>Change</Text>
              </TouchableOpacity>
            </View>
          ) : (
            <TouchableOpacity style={styles.addBankButton}>
              <View style={styles.addBankIcon}>
                <Text style={styles.addBankIconText}>+</Text>
              </View>
              <Text style={styles.addBankText}>Add Bank Account</Text>
            </TouchableOpacity>
          )}
        </View>

        {/* Statements Section */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Statements</Text>
          {statements.length > 0 ? (
            statements.map((statement) => (
              <TouchableOpacity
                key={statement.id}
                style={[
                  styles.statementCard,
                  (statement.status === 'PAST_DUE' || statement.status === 'FAILED') && styles.statementCardPastDue,
                ]}
                onPress={() => openStatementPdf(statement.id)}
              >
                <View style={styles.statementIcon}>
                  <Text style={styles.statementIconText}>
                    {statement.status === 'PAST_DUE' || statement.status === 'FAILED' ? '!' : '$'}
                  </Text>
                </View>
                <View style={styles.statementInfo}>
                  <Text style={styles.statementMonth}>
                    {formatBillingPeriod(statement.billingPeriodStart)}
                  </Text>
                  <View style={styles.statementMeta}>
                    <View
                      style={[
                        styles.statusBadge,
                        { backgroundColor: STATEMENT_STATUS_COLORS[statement.status] + '20' },
                      ]}
                    >
                      <Text
                        style={[
                          styles.statusText,
                          { color: STATEMENT_STATUS_COLORS[statement.status] },
                        ]}
                      >
                        {STATEMENT_STATUS_LABELS[statement.status]}
                      </Text>
                    </View>
                    <Text style={styles.statementItemCount}>
                      {statement.itemCount} item{statement.itemCount !== 1 ? 's' : ''}
                    </Text>
                  </View>
                </View>
                <View style={styles.statementAmount}>
                  <Text
                    style={[
                      styles.statementAmountText,
                      (statement.status === 'PAST_DUE' || statement.status === 'FAILED') && styles.statementAmountPastDue,
                    ]}
                  >
                    {formatCurrency(statement.total)}
                  </Text>
                  <Text style={styles.statementTapHint}>Tap for PDF</Text>
                </View>
              </TouchableOpacity>
            ))
          ) : (
            <View style={styles.emptyCard}>
              <Text style={styles.emptyText}>No statements yet</Text>
              <Text style={styles.emptySubtext}>
                Monthly statements will appear here after your first billing cycle.
              </Text>
            </View>
          )}
        </View>

        {/* Activity Feed */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Activity</Text>
          {transactions.length > 0 ? (
            transactions.map((tx) => (
              <View key={tx.id} style={styles.activityCard}>
                <View style={styles.activityMain}>
                  <View style={styles.activityIcon}>
                    <Text style={styles.activityIconText}>
                      {tx.vendor?.displayName?.charAt(0) || '$'}
                    </Text>
                  </View>
                  <View style={styles.activityInfo}>
                    <Text style={styles.activityTitle}>{tx.description}</Text>
                    <Text style={styles.activitySubtitle}>
                      {tx.vendor?.displayName} {tx.manager && `\u2022 Paid by ${tx.manager.firstName}`}
                    </Text>
                    <View style={styles.activityMeta}>
                      <View
                        style={[
                          styles.statusBadge,
                          { backgroundColor: STATUS_COLORS[tx.status] + '20' },
                        ]}
                      >
                        <Text style={[styles.statusText, { color: STATUS_COLORS[tx.status] }]}>
                          {STATUS_LABELS[tx.status]}
                        </Text>
                      </View>
                      <Text style={styles.activityDate}>
                        {formatDate(tx.paidAt || tx.createdAt)}
                      </Text>
                    </View>
                  </View>
                </View>
                <View style={styles.activityAmount}>
                  <Text style={styles.activityAmountText}>{formatCurrency(tx.amount)}</Text>
                  <Text style={styles.activityPayoutMethod}>{PAYOUT_ICONS[tx.payoutMethod]}</Text>
                </View>
              </View>
            ))
          ) : (
            <View style={styles.emptyCard}>
              <Text style={styles.emptyText}>No transactions yet</Text>
              <Text style={styles.emptySubtext}>
                Expenses paid by your home manager will appear here.
              </Text>
            </View>
          )}
        </View>

        {/* Info Card */}
        <View style={styles.infoCard}>
          <Text style={styles.infoTitle}>How The Float Works</Text>
          <Text style={styles.infoText}>
            Haven pays your vendors immediately so you don't have to worry about managing payments.
            At the end of each billing cycle, we'll consolidate all expenses into a single invoice
            for easy reimbursement.
          </Text>
        </View>
    </ScreenContainer>
  );
}

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
  scrollContent: {
    padding: spacing[4],
  },
  // Balance Card
  balanceCard: {
    backgroundColor: colors.haven.purple[600],
    borderRadius: borderRadius.xl,
    padding: spacing[6],
    marginBottom: spacing[4],
    alignItems: 'center',
  },
  balanceLabel: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.purple[100],
    marginBottom: spacing[2],
  },
  balanceAmount: {
    fontSize: 42,
    fontWeight: typography.fontWeights.bold,
    color: colors.white,
    marginBottom: spacing[2],
  },
  balanceSubtext: {
    fontSize: typography.fontSizes.xs,
    color: colors.haven.purple[200],
    textAlign: 'center',
  },
  // Stats Row
  statsRow: {
    flexDirection: 'row',
    backgroundColor: colors.white,
    borderRadius: borderRadius.lg,
    padding: spacing[4],
    marginBottom: spacing[6],
    ...shadows.sm,
  },
  statItem: {
    flex: 1,
    alignItems: 'center',
  },
  statValue: {
    fontSize: typography.fontSizes.xl,
    fontWeight: typography.fontWeights.bold,
    color: colors.slate[900],
  },
  statLabel: {
    fontSize: typography.fontSizes.xs,
    color: colors.slate[500],
    marginTop: spacing[1],
  },
  statDivider: {
    width: 1,
    backgroundColor: colors.slate[200],
    marginHorizontal: spacing[2],
  },
  // Section
  section: {
    marginBottom: spacing[6],
  },
  sectionTitle: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.semibold,
    color: colors.slate[900],
    marginBottom: spacing[3],
  },
  // Bank Card
  bankCard: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.white,
    borderRadius: borderRadius.lg,
    padding: spacing[4],
    ...shadows.sm,
  },
  bankIcon: {
    width: 48,
    height: 48,
    borderRadius: borderRadius.lg,
    backgroundColor: colors.haven.purple[100],
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: spacing[3],
  },
  bankIconInner: {
    width: 32,
    height: 32,
    borderRadius: 16,
    backgroundColor: colors.haven.purple[600],
    alignItems: 'center',
    justifyContent: 'center',
  },
  bankIconText: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.bold,
    color: colors.white,
  },
  bankInfo: {
    flex: 1,
  },
  bankName: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.slate[900],
  },
  bankDetails: {
    fontSize: typography.fontSizes.sm,
    color: colors.slate[500],
    marginTop: 2,
  },
  changeButton: {
    paddingHorizontal: spacing[3],
    paddingVertical: spacing[2],
    borderRadius: borderRadius.md,
    backgroundColor: colors.slate[100],
  },
  changeButtonText: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.haven.purple[600],
  },
  addBankButton: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.white,
    borderRadius: borderRadius.lg,
    padding: spacing[4],
    borderWidth: 2,
    borderStyle: 'dashed',
    borderColor: colors.slate[300],
  },
  addBankIcon: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: colors.slate[100],
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: spacing[3],
  },
  addBankIconText: {
    fontSize: typography.fontSizes.xl,
    color: colors.slate[400],
  },
  addBankText: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.medium,
    color: colors.slate[600],
  },
  // Activity Card
  activityCard: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    backgroundColor: colors.white,
    borderRadius: borderRadius.lg,
    padding: spacing[4],
    marginBottom: spacing[3],
    ...shadows.sm,
  },
  activityMain: {
    flex: 1,
    flexDirection: 'row',
  },
  activityIcon: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: colors.slate[100],
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: spacing[3],
  },
  activityIconText: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.bold,
    color: colors.slate[600],
  },
  activityInfo: {
    flex: 1,
  },
  activityTitle: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.slate[900],
  },
  activitySubtitle: {
    fontSize: typography.fontSizes.sm,
    color: colors.slate[500],
    marginTop: 2,
  },
  activityMeta: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: spacing[2],
    gap: spacing[2],
  },
  statusBadge: {
    paddingHorizontal: spacing[2],
    paddingVertical: 2,
    borderRadius: borderRadius.sm,
  },
  statusText: {
    fontSize: typography.fontSizes.xs,
    fontWeight: typography.fontWeights.medium,
  },
  activityDate: {
    fontSize: typography.fontSizes.xs,
    color: colors.slate[400],
  },
  activityAmount: {
    alignItems: 'flex-end',
    marginLeft: spacing[2],
  },
  activityAmountText: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.bold,
    color: colors.slate[900],
  },
  activityPayoutMethod: {
    fontSize: typography.fontSizes.xs,
    color: colors.slate[400],
    marginTop: 2,
  },
  // Empty Card
  emptyCard: {
    backgroundColor: colors.white,
    borderRadius: borderRadius.lg,
    padding: spacing[6],
    alignItems: 'center',
    ...shadows.sm,
  },
  emptyText: {
    fontSize: typography.fontSizes.base,
    color: colors.slate[500],
    textAlign: 'center',
  },
  emptySubtext: {
    fontSize: typography.fontSizes.sm,
    color: colors.slate[400],
    textAlign: 'center',
    marginTop: spacing[2],
  },
  // Info Card
  infoCard: {
    backgroundColor: colors.haven.purple[50],
    borderRadius: borderRadius.lg,
    padding: spacing[4],
    borderWidth: 1,
    borderColor: colors.haven.purple[200],
  },
  infoTitle: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
    color: colors.haven.purple[700],
    marginBottom: spacing[2],
  },
  infoText: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.purple[600],
    lineHeight: 20,
  },
  // Alert Banner
  alertBanner: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.error + '15',
    borderRadius: borderRadius.lg,
    padding: spacing[4],
    marginBottom: spacing[4],
    borderWidth: 1,
    borderColor: colors.error + '30',
  },
  alertBadge: {
    width: 32,
    height: 32,
    borderRadius: 16,
    backgroundColor: colors.error,
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: spacing[3],
  },
  alertBadgeText: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.bold,
    color: colors.white,
  },
  alertContent: {
    flex: 1,
  },
  alertTitle: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.error,
  },
  alertText: {
    fontSize: typography.fontSizes.sm,
    color: colors.slate[600],
    marginTop: 2,
  },
  alertButton: {
    paddingHorizontal: spacing[3],
    paddingVertical: spacing[2],
    borderRadius: borderRadius.md,
    backgroundColor: colors.error,
  },
  alertButtonText: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
    color: colors.white,
  },
  // Statement Card
  statementCard: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.white,
    borderRadius: borderRadius.lg,
    padding: spacing[4],
    marginBottom: spacing[3],
    ...shadows.sm,
  },
  statementCardPastDue: {
    borderWidth: 1,
    borderColor: colors.error + '40',
    backgroundColor: colors.error + '08',
  },
  statementIcon: {
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: colors.slate[100],
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: spacing[3],
  },
  statementIconText: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.bold,
    color: colors.slate[600],
  },
  statementInfo: {
    flex: 1,
  },
  statementMonth: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.slate[900],
  },
  statementMeta: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: spacing[1],
    gap: spacing[2],
  },
  statementItemCount: {
    fontSize: typography.fontSizes.xs,
    color: colors.slate[400],
  },
  statementAmount: {
    alignItems: 'flex-end',
  },
  statementAmountText: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.bold,
    color: colors.slate[900],
  },
  statementAmountPastDue: {
    color: colors.error,
  },
  statementTapHint: {
    fontSize: typography.fontSizes.xs,
    color: colors.slate[400],
    marginTop: 2,
  },
});

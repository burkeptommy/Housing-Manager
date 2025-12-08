import { useEffect, useState, useCallback } from 'react';
import {
  View,
  Text,
  ScrollView,
  StyleSheet,
  RefreshControl,
  TouchableOpacity,
  ActivityIndicator,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useAuth } from '../../src/contexts/auth-context';
import { getApiClient } from '../../src/lib/api';
import { colors, spacing, typography, borderRadius, shadows } from '../../src/lib/theme';
import type { BillingSummary, HouseholdInvoiceListItem, HouseholdInvoiceStatus } from '@haven/core';

const STATUS_COLORS: Record<HouseholdInvoiceStatus, string> = {
  PENDING: colors.warning,
  PROCESSING: colors.info,
  PAID: colors.success,
  FAILED: colors.error,
  CANCELLED: colors.slate[400],
};

export default function BillingScreen() {
  const { currentHousehold } = useAuth();
  const [billingSummary, setBillingSummary] = useState<BillingSummary | null>(null);
  const [invoices, setInvoices] = useState<HouseholdInvoiceListItem[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);

  const api = getApiClient();

  const fetchData = useCallback(async () => {
    if (!currentHousehold) return;

    try {
      const [summaryData, invoicesData] = await Promise.all([
        api.getBillingSummary(currentHousehold.id).catch(() => null),
        api.getHouseholdInvoices(currentHousehold.id).catch(() => []),
      ]);
      setBillingSummary(summaryData);
      setInvoices(invoicesData);
    } catch (error) {
      console.error('Failed to fetch billing data:', error);
    } finally {
      setIsLoading(false);
    }
  }, [api, currentHousehold]);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  const onRefresh = useCallback(async () => {
    setRefreshing(true);
    await fetchData();
    setRefreshing(false);
  }, [fetchData]);

  const formatCurrency = (amount: number | null | undefined) => {
    if (amount === null || amount === undefined) return '$0.00';
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
    }).format(amount);
  };

  const formatDate = (date: string | Date | null | undefined) => {
    if (!date) return 'N/A';
    return new Date(date).toLocaleDateString('en-US', {
      month: 'short',
      day: 'numeric',
    });
  };

  // STUB: Subscription pricing
  const subscriptionPricing: Record<string, number> = {
    FREE: 0,
    BASIC: 9.99,
    PREMIUM: 19.99,
    ENTERPRISE: 49.99,
  };

  const getTierName = (tier: string) => {
    const names: Record<string, string> = {
      FREE: 'Free',
      BASIC: 'Basic',
      PREMIUM: 'Premium',
      ENTERPRISE: 'Enterprise',
    };
    return names[tier] || tier;
  };

  if (isLoading) {
    return (
      <SafeAreaView style={styles.loadingContainer} edges={['bottom']}>
        <ActivityIndicator size="large" color={colors.primary[600]} />
      </SafeAreaView>
    );
  }

  if (!currentHousehold) {
    return (
      <SafeAreaView style={styles.container} edges={['bottom']}>
        <View style={styles.emptyCard}>
          <Text style={styles.emptyText}>Select a household to view billing</Text>
        </View>
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
            tintColor={colors.primary[600]}
          />
        }
      >
        {/* Summary Stats */}
        <View style={styles.statsGrid}>
          <View style={styles.statCard}>
            <Text style={styles.statLabel}>Current Plan</Text>
            <Text style={styles.statValue}>
              {getTierName(billingSummary?.subscriptionTier || 'FREE')}
            </Text>
          </View>
          <View style={styles.statCard}>
            <Text style={styles.statLabel}>Subscription</Text>
            <Text style={styles.statValue}>
              {formatCurrency(subscriptionPricing[billingSummary?.subscriptionTier || 'FREE'])}/mo
            </Text>
          </View>
          <View style={styles.statCard}>
            <Text style={styles.statLabel}>Bills Managed</Text>
            <Text style={styles.statValue}>{billingSummary?.totalBillsManaged || 0}</Text>
          </View>
          <View style={styles.statCard}>
            <Text style={styles.statLabel}>Monthly Estimate</Text>
            <Text style={styles.statValue}>
              {formatCurrency(billingSummary?.monthlyBillEstimate)}
            </Text>
          </View>
        </View>

        {/* Latest Invoice */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Latest Invoice</Text>
          {billingSummary?.latestInvoice ? (
            <View style={styles.invoiceCard}>
              <View style={styles.invoiceHeader}>
                <Text style={styles.invoiceNumber}>
                  {billingSummary.latestInvoice.invoiceNumber}
                </Text>
                <View
                  style={[
                    styles.statusBadge,
                    { backgroundColor: STATUS_COLORS[billingSummary.latestInvoice.status] + '20' },
                  ]}
                >
                  <View
                    style={[
                      styles.statusDot,
                      { backgroundColor: STATUS_COLORS[billingSummary.latestInvoice.status] },
                    ]}
                  />
                  <Text
                    style={[
                      styles.statusText,
                      { color: STATUS_COLORS[billingSummary.latestInvoice.status] },
                    ]}
                  >
                    {billingSummary.latestInvoice.status}
                  </Text>
                </View>
              </View>
              <Text style={styles.invoicePeriod}>
                {formatDate(billingSummary.latestInvoice.billingPeriodStart)} - {formatDate(billingSummary.latestInvoice.billingPeriodEnd)}
              </Text>
              <Text style={styles.invoiceItems}>
                {billingSummary.latestInvoice.itemCount} bill(s) included
              </Text>
              <View style={styles.invoiceTotalRow}>
                <Text style={styles.invoiceTotalLabel}>Total</Text>
                <Text style={styles.invoiceTotalAmount}>
                  {formatCurrency(billingSummary.latestInvoice.total)}
                </Text>
              </View>
            </View>
          ) : (
            <View style={styles.emptyCard}>
              <Text style={styles.emptyText}>No invoices yet</Text>
              <Text style={styles.emptySubtext}>
                Consolidated invoices will appear here when you have bills managed by Haven.
              </Text>
            </View>
          )}
        </View>

        {/* Bills Managed */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Bills Managed by Haven</Text>
          {billingSummary?.billAccountsIncluded && billingSummary.billAccountsIncluded.length > 0 ? (
            billingSummary.billAccountsIncluded.slice(0, 5).map((bill) => (
              <View key={bill.id} style={styles.billCard}>
                <View style={styles.billInfo}>
                  <Text style={styles.billNickname}>{bill.nickname}</Text>
                  <Text style={styles.billVendor}>{bill.vendorName}</Text>
                </View>
                <View style={styles.billAmount}>
                  <Text style={styles.billAmountText}>
                    {formatCurrency(bill.typicalAmount)}
                  </Text>
                  <Text style={styles.billAmountLabel}>/month</Text>
                </View>
              </View>
            ))
          ) : (
            <View style={styles.emptyCard}>
              <Text style={styles.emptyText}>No bills set up</Text>
              <Text style={styles.emptySubtext}>
                Add bills with &quot;Haven pays on behalf&quot; to see them here.
              </Text>
            </View>
          )}
        </View>

        {/* Invoice History */}
        {invoices.length > 0 && (
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Invoice History</Text>
            {invoices.slice(0, 5).map((invoice) => (
              <View key={invoice.id} style={styles.historyCard}>
                <View style={styles.historyInfo}>
                  <Text style={styles.historyNumber}>{invoice.invoiceNumber}</Text>
                  <Text style={styles.historyDate}>{formatDate(invoice.createdAt)}</Text>
                </View>
                <View style={styles.historyRight}>
                  <Text style={styles.historyAmount}>{formatCurrency(invoice.total)}</Text>
                  <View
                    style={[
                      styles.historyBadge,
                      { backgroundColor: STATUS_COLORS[invoice.status] + '20' },
                    ]}
                  >
                    <Text
                      style={[
                        styles.historyBadgeText,
                        { color: STATUS_COLORS[invoice.status] },
                      ]}
                    >
                      {invoice.status}
                    </Text>
                  </View>
                </View>
              </View>
            ))}
          </View>
        )}

        {/* Info Card */}
        {/* STUB: Coming soon notice for automatic bill pay */}
        <View style={styles.infoCard}>
          <Text style={styles.infoTitle}>Coming Soon: Automatic Bill Pay</Text>
          <Text style={styles.infoText}>
            Set up bills with &quot;Haven pays on behalf&quot; and we&apos;ll handle payments to your vendors automatically via Stripe Connect.
          </Text>
        </View>
      </ScrollView>
    </SafeAreaView>
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
  statsGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: spacing[3],
    marginBottom: spacing[6],
  },
  statCard: {
    flex: 1,
    minWidth: '45%',
    backgroundColor: colors.white,
    borderRadius: borderRadius.lg,
    padding: spacing[4],
    ...shadows.sm,
  },
  statLabel: {
    fontSize: typography.fontSizes.xs,
    color: colors.slate[500],
    marginBottom: spacing[1],
  },
  statValue: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.bold,
    color: colors.slate[900],
  },
  section: {
    marginBottom: spacing[6],
  },
  sectionTitle: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.semibold,
    color: colors.slate[900],
    marginBottom: spacing[3],
  },
  invoiceCard: {
    backgroundColor: colors.white,
    borderRadius: borderRadius.lg,
    padding: spacing[4],
    ...shadows.sm,
  },
  invoiceHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: spacing[2],
  },
  invoiceNumber: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.slate[900],
  },
  statusBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: spacing[2],
    paddingVertical: 4,
    borderRadius: borderRadius.full,
  },
  statusDot: {
    width: 6,
    height: 6,
    borderRadius: 3,
    marginRight: 4,
  },
  statusText: {
    fontSize: typography.fontSizes.xs,
    fontWeight: typography.fontWeights.medium,
  },
  invoicePeriod: {
    fontSize: typography.fontSizes.sm,
    color: colors.slate[500],
  },
  invoiceItems: {
    fontSize: typography.fontSizes.sm,
    color: colors.slate[500],
    marginTop: spacing[1],
  },
  invoiceTotalRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginTop: spacing[3],
    paddingTop: spacing[3],
    borderTopWidth: 1,
    borderTopColor: colors.slate[200],
  },
  invoiceTotalLabel: {
    fontSize: typography.fontSizes.sm,
    color: colors.slate[500],
  },
  invoiceTotalAmount: {
    fontSize: typography.fontSizes.xl,
    fontWeight: typography.fontWeights.bold,
    color: colors.slate[900],
  },
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
  billCard: {
    backgroundColor: colors.white,
    borderRadius: borderRadius.lg,
    padding: spacing[4],
    marginBottom: spacing[3],
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    ...shadows.sm,
  },
  billInfo: {
    flex: 1,
  },
  billNickname: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.medium,
    color: colors.slate[900],
  },
  billVendor: {
    fontSize: typography.fontSizes.sm,
    color: colors.slate[500],
    marginTop: spacing[1],
  },
  billAmount: {
    alignItems: 'flex-end',
  },
  billAmountText: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.slate[900],
  },
  billAmountLabel: {
    fontSize: typography.fontSizes.xs,
    color: colors.slate[400],
  },
  historyCard: {
    backgroundColor: colors.white,
    borderRadius: borderRadius.lg,
    padding: spacing[4],
    marginBottom: spacing[2],
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    ...shadows.sm,
  },
  historyInfo: {
    flex: 1,
  },
  historyNumber: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.slate[900],
  },
  historyDate: {
    fontSize: typography.fontSizes.xs,
    color: colors.slate[400],
    marginTop: 2,
  },
  historyRight: {
    alignItems: 'flex-end',
  },
  historyAmount: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
    color: colors.slate[900],
  },
  historyBadge: {
    paddingHorizontal: spacing[2],
    paddingVertical: 2,
    borderRadius: borderRadius.sm,
    marginTop: 4,
  },
  historyBadgeText: {
    fontSize: typography.fontSizes.xs,
    fontWeight: typography.fontWeights.medium,
  },
  infoCard: {
    backgroundColor: colors.info + '10',
    borderRadius: borderRadius.lg,
    padding: spacing[4],
    borderWidth: 1,
    borderColor: colors.info + '30',
  },
  infoTitle: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
    color: colors.info,
    marginBottom: spacing[2],
  },
  infoText: {
    fontSize: typography.fontSizes.sm,
    color: colors.info,
    lineHeight: 20,
  },
});

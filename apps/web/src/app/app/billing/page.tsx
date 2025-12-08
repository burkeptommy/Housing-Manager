'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import { useAuth } from '@/contexts/auth-context';
import { getApiClient } from '@/lib/api';
import type { BillingSummary, HouseholdInvoiceListItem, Subscription } from '@haven/core';

export default function BillingPage() {
  const { currentHousehold } = useAuth();
  const [billingSummary, setBillingSummary] = useState<BillingSummary | null>(null);
  const [invoices, setInvoices] = useState<HouseholdInvoiceListItem[]>([]);
  const [subscription, setSubscription] = useState<Subscription | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const loadData = async () => {
      if (!currentHousehold) {
        setIsLoading(false);
        return;
      }

      const api = getApiClient();
      try {
        const [summaryData, invoicesData, subscriptionData] = await Promise.all([
          api.getBillingSummary(currentHousehold.id).catch(() => null),
          api.getHouseholdInvoices(currentHousehold.id).catch(() => []),
          api.getSubscription().catch(() => null),
        ]);
        setBillingSummary(summaryData);
        setInvoices(invoicesData);
        setSubscription(subscriptionData);
      } catch (error) {
        console.error('Failed to load billing data:', error);
      } finally {
        setIsLoading(false);
      }
    };

    loadData();
  }, [currentHousehold]);

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
      year: 'numeric',
    });
  };

  const getStatusBadge = (status: string) => {
    const styles: Record<string, string> = {
      PENDING: 'badge-yellow',
      PROCESSING: 'badge-blue',
      PAID: 'badge-green',
      FAILED: 'badge-red',
      CANCELLED: 'badge-gray',
    };
    return styles[status] || 'badge-gray';
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

  // STUB: Subscription pricing - would come from config/API in production
  const subscriptionPricing: Record<string, number> = {
    FREE: 0,
    BASIC: 9.99,
    PREMIUM: 19.99,
    ENTERPRISE: 49.99,
  };

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  if (!currentHousehold) {
    return (
      <div className="text-center py-12">
        <p className="text-slate-600 dark:text-slate-400">
          Please select or create a household to view billing.
        </p>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Page header */}
      <div>
        <h1 className="text-2xl font-bold text-slate-900 dark:text-white">
          Billing & Invoices
        </h1>
        <p className="text-slate-600 dark:text-slate-400 mt-1">
          Manage your subscription and view consolidated household bills.
        </p>
      </div>

      {/* Summary cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        {/* Subscription card */}
        <div className="card">
          <div className="flex items-center gap-4">
            <div className="w-12 h-12 rounded-lg bg-purple-100 dark:bg-purple-900/30 flex items-center justify-center">
              <svg className="w-6 h-6 text-purple-600 dark:text-purple-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 3v4M3 5h4M6 17v4m-2-2h4m5-16l2.286 6.857L21 12l-5.714 2.143L13 21l-2.286-6.857L5 12l5.714-2.143L13 3z" />
              </svg>
            </div>
            <div>
              <p className="text-2xl font-bold text-slate-900 dark:text-white">
                {getTierName(subscription?.tier || billingSummary?.subscriptionTier || 'FREE')}
              </p>
              <p className="text-sm text-slate-600 dark:text-slate-400">Current Plan</p>
            </div>
          </div>
        </div>

        {/* Monthly subscription */}
        <div className="card">
          <div className="flex items-center gap-4">
            <div className="w-12 h-12 rounded-lg bg-blue-100 dark:bg-blue-900/30 flex items-center justify-center">
              <svg className="w-6 h-6 text-blue-600 dark:text-blue-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z" />
              </svg>
            </div>
            <div>
              <p className="text-2xl font-bold text-slate-900 dark:text-white">
                {formatCurrency(subscriptionPricing[subscription?.tier || 'FREE'])}/mo
              </p>
              <p className="text-sm text-slate-600 dark:text-slate-400">Subscription</p>
            </div>
          </div>
        </div>

        {/* Bills managed */}
        <div className="card">
          <div className="flex items-center gap-4">
            <div className="w-12 h-12 rounded-lg bg-green-100 dark:bg-green-900/30 flex items-center justify-center">
              <svg className="w-6 h-6 text-green-600 dark:text-green-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
              </svg>
            </div>
            <div>
              <p className="text-2xl font-bold text-slate-900 dark:text-white">
                {billingSummary?.totalBillsManaged || 0}
              </p>
              <p className="text-sm text-slate-600 dark:text-slate-400">Bills Managed</p>
            </div>
          </div>
        </div>

        {/* Monthly estimate */}
        <div className="card">
          <div className="flex items-center gap-4">
            <div className="w-12 h-12 rounded-lg bg-yellow-100 dark:bg-yellow-900/30 flex items-center justify-center">
              <svg className="w-6 h-6 text-yellow-600 dark:text-yellow-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
            </div>
            <div>
              <p className="text-2xl font-bold text-slate-900 dark:text-white">
                {formatCurrency(billingSummary?.monthlyBillEstimate)}/mo
              </p>
              <p className="text-sm text-slate-600 dark:text-slate-400">Bill Estimate</p>
            </div>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Latest Invoice */}
        <div className="card">
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-lg font-semibold text-slate-900 dark:text-white">
              Latest Consolidated Invoice
            </h2>
          </div>

          {billingSummary?.latestInvoice ? (
            <div className="space-y-4">
              <div className="p-4 rounded-lg bg-slate-50 dark:bg-slate-700/50">
                <div className="flex items-center justify-between mb-2">
                  <span className="font-medium text-slate-900 dark:text-white">
                    {billingSummary.latestInvoice.invoiceNumber}
                  </span>
                  <span className={`badge ${getStatusBadge(billingSummary.latestInvoice.status)}`}>
                    {billingSummary.latestInvoice.status}
                  </span>
                </div>
                <div className="text-sm text-slate-600 dark:text-slate-400 space-y-1">
                  <p>
                    Period: {formatDate(billingSummary.latestInvoice.billingPeriodStart)} - {formatDate(billingSummary.latestInvoice.billingPeriodEnd)}
                  </p>
                  <p>{billingSummary.latestInvoice.itemCount} bill(s) included</p>
                </div>
                <div className="mt-3 pt-3 border-t border-slate-200 dark:border-slate-600">
                  <div className="flex items-center justify-between">
                    <span className="text-slate-600 dark:text-slate-400">Total</span>
                    <span className="text-xl font-bold text-slate-900 dark:text-white">
                      {formatCurrency(billingSummary.latestInvoice.total)}
                    </span>
                  </div>
                </div>
              </div>
            </div>
          ) : (
            <div className="text-center py-8 text-slate-500 dark:text-slate-400">
              <svg className="w-12 h-12 mx-auto mb-3 text-slate-300 dark:text-slate-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
              </svg>
              <p>No invoices yet</p>
              <p className="text-sm mt-1">
                Consolidated invoices will appear here when you have bills managed by Haven.
              </p>
            </div>
          )}
        </div>

        {/* Bill Accounts Included */}
        <div className="card">
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-lg font-semibold text-slate-900 dark:text-white">
              Bills Managed by Haven
            </h2>
            <Link
              href="/app/bills"
              className="text-sm text-blue-600 hover:text-blue-500 dark:text-blue-400 font-medium"
            >
              Manage
            </Link>
          </div>

          {billingSummary?.billAccountsIncluded && billingSummary.billAccountsIncluded.length > 0 ? (
            <div className="space-y-3">
              {billingSummary.billAccountsIncluded.slice(0, 5).map((bill) => (
                <div
                  key={bill.id}
                  className="flex items-center justify-between p-3 rounded-lg bg-slate-50 dark:bg-slate-700/50"
                >
                  <div className="flex-1 min-w-0">
                    <p className="font-medium text-slate-900 dark:text-white truncate">
                      {bill.nickname}
                    </p>
                    <p className="text-sm text-slate-500 dark:text-slate-400">
                      {bill.vendorName}
                    </p>
                  </div>
                  <div className="text-right">
                    <p className="font-medium text-slate-900 dark:text-white">
                      {formatCurrency(bill.typicalAmount)}
                    </p>
                    <p className="text-xs text-slate-500 dark:text-slate-400">
                      /month
                    </p>
                  </div>
                </div>
              ))}
              {billingSummary.billAccountsIncluded.length > 5 && (
                <p className="text-sm text-center text-slate-500 dark:text-slate-400">
                  +{billingSummary.billAccountsIncluded.length - 5} more
                </p>
              )}
            </div>
          ) : (
            <div className="text-center py-8 text-slate-500 dark:text-slate-400">
              <p>No bills set up for Haven management yet.</p>
              <p className="text-sm mt-1">
                Add bills with &quot;Haven pays on behalf&quot; to see them here.
              </p>
            </div>
          )}
        </div>
      </div>

      {/* Invoice History */}
      <div className="card">
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-lg font-semibold text-slate-900 dark:text-white">
            Invoice History
          </h2>
        </div>

        {invoices.length > 0 ? (
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b border-slate-200 dark:border-slate-700">
                  <th className="text-left py-3 px-4 text-sm font-medium text-slate-600 dark:text-slate-400">
                    Invoice #
                  </th>
                  <th className="text-left py-3 px-4 text-sm font-medium text-slate-600 dark:text-slate-400">
                    Period
                  </th>
                  <th className="text-left py-3 px-4 text-sm font-medium text-slate-600 dark:text-slate-400">
                    Items
                  </th>
                  <th className="text-left py-3 px-4 text-sm font-medium text-slate-600 dark:text-slate-400">
                    Total
                  </th>
                  <th className="text-left py-3 px-4 text-sm font-medium text-slate-600 dark:text-slate-400">
                    Status
                  </th>
                  <th className="text-left py-3 px-4 text-sm font-medium text-slate-600 dark:text-slate-400">
                    Date
                  </th>
                </tr>
              </thead>
              <tbody>
                {invoices.map((invoice) => (
                  <tr
                    key={invoice.id}
                    className="border-b border-slate-100 dark:border-slate-700/50 hover:bg-slate-50 dark:hover:bg-slate-700/30"
                  >
                    <td className="py-3 px-4">
                      <span className="font-medium text-slate-900 dark:text-white">
                        {invoice.invoiceNumber}
                      </span>
                    </td>
                    <td className="py-3 px-4 text-sm text-slate-600 dark:text-slate-400">
                      {formatDate(invoice.billingPeriodStart)} - {formatDate(invoice.billingPeriodEnd)}
                    </td>
                    <td className="py-3 px-4 text-sm text-slate-600 dark:text-slate-400">
                      {invoice.itemCount}
                    </td>
                    <td className="py-3 px-4">
                      <span className="font-medium text-slate-900 dark:text-white">
                        {formatCurrency(invoice.total)}
                      </span>
                    </td>
                    <td className="py-3 px-4">
                      <span className={`badge ${getStatusBadge(invoice.status)}`}>
                        {invoice.status}
                      </span>
                    </td>
                    <td className="py-3 px-4 text-sm text-slate-600 dark:text-slate-400">
                      {formatDate(invoice.createdAt)}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        ) : (
          <div className="text-center py-8 text-slate-500 dark:text-slate-400">
            <p>No invoices yet.</p>
          </div>
        )}
      </div>

      {/* STUB: Future integration notes */}
      <div className="card bg-blue-50 dark:bg-blue-900/20 border-blue-200 dark:border-blue-800">
        <div className="flex items-start gap-3">
          <svg className="w-5 h-5 text-blue-600 dark:text-blue-400 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
          <div>
            <h3 className="font-medium text-blue-900 dark:text-blue-100">
              Coming Soon: Automatic Bill Pay
            </h3>
            <p className="text-sm text-blue-700 dark:text-blue-300 mt-1">
              {/* STUB: This feature is in development. Real vendor payments will be enabled via Stripe Connect. */}
              Set up bills with &quot;Haven pays on behalf&quot; payment responsibility, and we&apos;ll
              collect a monthly consolidated invoice and pay your vendors automatically.
              Vendor payouts via Stripe Connect, check, or manual transfer coming soon.
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}

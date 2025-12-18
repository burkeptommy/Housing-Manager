'use client';

import { useEffect, useState, useCallback } from 'react';
import { useAuth } from '@/contexts/auth-context';
import { getApiClient, getAccessToken } from '@/lib/api';
import type { BillingSummary, HouseholdInvoice, HouseholdInvoiceListItem, BillAccount } from '@haven/core';

const categoryLabels: Record<string, string> = {
  ELECTRIC: 'Electric',
  GAS: 'Gas',
  WATER_SEWER: 'Water/Sewer',
  INTERNET: 'Internet',
  PEST_CONTROL: 'Pest Control',
  CLEANING: 'Cleaning',
  LAWN_CARE: 'Lawn Care',
  HVAC_SERVICE: 'HVAC',
  POOL_SERVICE: 'Pool',
  SECURITY_MONITORING: 'Security',
  TRASH: 'Trash',
  OTHER: 'Other',
};

const suggestedVendorCategories = [
  { category: 'TRASH', name: 'Trash Collection', description: 'Weekly trash and recycling pickup', avgCost: '$35/mo' },
  { category: 'LAWN_CARE', name: 'Lawn Care', description: 'Regular lawn maintenance and landscaping', avgCost: '$150/mo' },
  { category: 'PEST_CONTROL', name: 'Pest Control', description: 'Quarterly pest prevention treatment', avgCost: '$95/quarter' },
  { category: 'CLEANING', name: 'House Cleaning', description: 'Bi-weekly house cleaning service', avgCost: '$150/visit' },
  { category: 'POOL_SERVICE', name: 'Pool Service', description: 'Weekly pool maintenance and chemicals', avgCost: '$175/mo' },
  { category: 'SECURITY_MONITORING', name: 'Security Monitoring', description: '24/7 home security monitoring', avgCost: '$45/mo' },
];

export default function BillingPage() {
  const { currentHousehold, isAuthenticated } = useAuth();
  const [billingSummary, setBillingSummary] = useState<BillingSummary | null>(null);
  const [invoices, setInvoices] = useState<HouseholdInvoiceListItem[]>([]);
  const [billAccounts, setBillAccounts] = useState<BillAccount[]>([]);
  const [latestInvoiceDetail, setLatestInvoiceDetail] = useState<HouseholdInvoice | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [showAddAccountModal, setShowAddAccountModal] = useState(false);
  const [expandedInvoice, setExpandedInvoice] = useState<string | null>(null);

  const api = getApiClient();

  const loadData = useCallback(async () => {
    // Don't fetch if not authenticated or no household or no token
    const token = getAccessToken();
    if (!currentHousehold || !isAuthenticated || !token) {
      setIsLoading(false);
      return;
    }

    try {
      const [summaryData, invoicesData, billAccountsData] = await Promise.all([
        api.getBillingSummary(currentHousehold.id).catch(() => null),
        api.getHouseholdInvoices(currentHousehold.id).catch(() => []),
        api.getBillAccounts(currentHousehold.id).catch(() => []),
      ]);
      setBillingSummary(summaryData);
      setInvoices(invoicesData);
      setBillAccounts(billAccountsData);

      // Load detail for the most recent invoice
      if (invoicesData.length > 0) {
        const latestInvoice = invoicesData[0];
        try {
          const detail = await api.getHouseholdInvoice(latestInvoice.id, currentHousehold.id);
          setLatestInvoiceDetail(detail);
        } catch {
          // Ignore errors loading detail
        }
      }
    } catch (error) {
      console.error('Failed to load billing data:', error);
    } finally {
      setIsLoading(false);
    }
  }, [api, currentHousehold, isAuthenticated]);

  useEffect(() => {
    loadData();
  }, [loadData]);

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
      PENDING: 'bg-yellow-100 text-yellow-700 dark:bg-yellow-900/30 dark:text-yellow-400',
      PROCESSING: 'bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400',
      PAID: 'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400',
      FAILED: 'bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400',
      CANCELLED: 'bg-slate-100 text-slate-700 dark:bg-slate-700 dark:text-slate-300',
    };
    return styles[status] || styles.PENDING;
  };

  // Calculate vendor breakdown from invoice items or bill accounts
  const getVendorBreakdown = () => {
    if (latestInvoiceDetail?.items && latestInvoiceDetail.items.length > 0) {
      const breakdown: Record<string, { name: string; amount: number; category: string }> = {};
      latestInvoiceDetail.items.forEach((item) => {
        const vendorName = item.vendorName || 'Unknown Vendor';
        if (!breakdown[vendorName]) {
          breakdown[vendorName] = { name: vendorName, amount: 0, category: item.category || 'OTHER' };
        }
        breakdown[vendorName].amount += item.amount;
      });
      return Object.values(breakdown).sort((a, b) => b.amount - a.amount);
    }
    // Fallback to bill accounts if no invoice detail
    return billAccounts
      .filter((b) => b.typicalAmount)
      .map((b) => ({
        name: b.vendor?.displayName || b.nickname,
        amount: b.typicalAmount || 0,
        category: b.category,
      }))
      .sort((a, b) => b.amount - a.amount);
  };

  // Get categories not yet added
  const getMissingSuggestions = () => {
    const existingCategories = new Set(billAccounts.map((b) => b.category));
    return suggestedVendorCategories.filter((s) => !existingCategories.has(s.category));
  };

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-emerald-600"></div>
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

  const vendorBreakdown = getVendorBreakdown();
  const suggestions = getMissingSuggestions();

  return (
    <div className="space-y-6">
      {/* Page header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-slate-900 dark:text-white">
            Billing & Invoices
          </h1>
          <p className="text-slate-600 dark:text-slate-400 mt-1">
            View your consolidated bills and manage bill accounts.
          </p>
        </div>
        <button
          onClick={() => setShowAddAccountModal(true)}
          className="inline-flex items-center gap-2 px-4 py-2 bg-emerald-600 text-white font-medium rounded-lg hover:bg-emerald-700 transition-colors"
        >
          <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
          </svg>
          Add Account
        </button>
      </div>

      {/* Summary cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="card">
          <div className="flex items-center gap-4">
            <div className="w-12 h-12 rounded-lg bg-emerald-100 dark:bg-emerald-900/30 flex items-center justify-center">
              <svg className="w-6 h-6 text-emerald-600 dark:text-emerald-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
              </svg>
            </div>
            <div>
              <p className="text-2xl font-bold text-slate-900 dark:text-white">
                {billAccounts.length}
              </p>
              <p className="text-sm text-slate-600 dark:text-slate-400">Bill Accounts</p>
            </div>
          </div>
        </div>

        <div className="card">
          <div className="flex items-center gap-4">
            <div className="w-12 h-12 rounded-lg bg-green-100 dark:bg-green-900/30 flex items-center justify-center">
              <svg className="w-6 h-6 text-green-600 dark:text-green-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
            </div>
            <div>
              <p className="text-2xl font-bold text-slate-900 dark:text-white">
                {formatCurrency(billingSummary?.monthlyBillEstimate || billAccounts.reduce((sum, b) => sum + (b.typicalAmount || 0), 0))}
              </p>
              <p className="text-sm text-slate-600 dark:text-slate-400">Monthly Estimate</p>
            </div>
          </div>
        </div>

        <div className="card">
          <div className="flex items-center gap-4">
            <div className="w-12 h-12 rounded-lg bg-purple-100 dark:bg-purple-900/30 flex items-center justify-center">
              <svg className="w-6 h-6 text-purple-600 dark:text-purple-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
              </svg>
            </div>
            <div>
              <p className="text-2xl font-bold text-slate-900 dark:text-white">
                {invoices.length}
              </p>
              <p className="text-sm text-slate-600 dark:text-slate-400">Invoices</p>
            </div>
          </div>
        </div>

        <div className="card">
          <div className="flex items-center gap-4">
            <div className="w-12 h-12 rounded-lg bg-yellow-100 dark:bg-yellow-900/30 flex items-center justify-center">
              <svg className="w-6 h-6 text-yellow-600 dark:text-yellow-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
              </svg>
            </div>
            <div>
              <p className="text-2xl font-bold text-slate-900 dark:text-white">
                {billAccounts.filter((b) => b.nextDueDate && new Date(b.nextDueDate) <= new Date(Date.now() + 7 * 24 * 60 * 60 * 1000)).length}
              </p>
              <p className="text-sm text-slate-600 dark:text-slate-400">Due This Week</p>
            </div>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Most Recent Consolidated Invoice */}
        <div className="lg:col-span-2 card">
          <h2 className="text-lg font-semibold text-slate-900 dark:text-white mb-4">
            Most Recent Consolidated Invoice
          </h2>

          {invoices.length > 0 && latestInvoiceDetail ? (
            <div className="space-y-4">
              {/* Invoice Header */}
              <div className="p-4 rounded-lg bg-slate-50 dark:bg-slate-700/50">
                <div className="flex items-center justify-between mb-3">
                  <div>
                    <span className="font-semibold text-lg text-slate-900 dark:text-white">
                      {latestInvoiceDetail.invoiceNumber}
                    </span>
                    <p className="text-sm text-slate-500 dark:text-slate-400">
                      {formatDate(latestInvoiceDetail.billingPeriodStart)} - {formatDate(latestInvoiceDetail.billingPeriodEnd)}
                    </p>
                  </div>
                  <span className={`px-3 py-1 text-sm font-medium rounded-full ${getStatusBadge(latestInvoiceDetail.status)}`}>
                    {latestInvoiceDetail.status}
                  </span>
                </div>

                {/* Line Items */}
                <div className="space-y-2 mb-4">
                  {latestInvoiceDetail.items.map((item) => (
                    <div key={item.id} className="flex items-center justify-between py-2 border-b border-slate-200 dark:border-slate-600 last:border-0">
                      <div className="flex-1">
                        <p className="font-medium text-slate-900 dark:text-white text-sm">
                          {item.description}
                        </p>
                        <p className="text-xs text-slate-500 dark:text-slate-400">
                          {item.vendorName || 'Vendor'} - {categoryLabels[item.category || 'OTHER'] || item.category}
                        </p>
                      </div>
                      <span className="font-medium text-slate-900 dark:text-white">
                        {formatCurrency(item.amount)}
                      </span>
                    </div>
                  ))}
                </div>

                {/* Totals */}
                <div className="pt-3 border-t border-slate-300 dark:border-slate-500 space-y-1">
                  <div className="flex justify-between text-sm">
                    <span className="text-slate-600 dark:text-slate-400">Subtotal</span>
                    <span className="text-slate-900 dark:text-white">{formatCurrency(latestInvoiceDetail.subtotal)}</span>
                  </div>
                  {latestInvoiceDetail.platformFee > 0 && (
                    <div className="flex justify-between text-sm">
                      <span className="text-slate-600 dark:text-slate-400">Platform Fee (5%)</span>
                      <span className="text-slate-900 dark:text-white">{formatCurrency(latestInvoiceDetail.platformFee)}</span>
                    </div>
                  )}
                  <div className="flex justify-between font-semibold text-lg pt-2">
                    <span className="text-slate-900 dark:text-white">Total</span>
                    <span className="text-emerald-600 dark:text-emerald-400">{formatCurrency(latestInvoiceDetail.total)}</span>
                  </div>
                </div>
              </div>
            </div>
          ) : invoices.length > 0 ? (
            <div className="p-4 rounded-lg bg-slate-50 dark:bg-slate-700/50">
              <div className="flex items-center justify-between mb-2">
                <span className="font-medium text-slate-900 dark:text-white">
                  {invoices[0].invoiceNumber}
                </span>
                <span className={`px-2 py-1 text-xs font-medium rounded-full ${getStatusBadge(invoices[0].status)}`}>
                  {invoices[0].status}
                </span>
              </div>
              <p className="text-sm text-slate-600 dark:text-slate-400">
                {formatDate(invoices[0].billingPeriodStart)} - {formatDate(invoices[0].billingPeriodEnd)}
              </p>
              <p className="text-sm text-slate-600 dark:text-slate-400">{invoices[0].itemCount} items</p>
              <p className="text-xl font-bold text-slate-900 dark:text-white mt-2">{formatCurrency(invoices[0].total)}</p>
            </div>
          ) : (
            <div className="text-center py-8 text-slate-500 dark:text-slate-400">
              <svg className="w-12 h-12 mx-auto mb-3 text-slate-300 dark:text-slate-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
              </svg>
              <p>No invoices yet</p>
              <p className="text-sm mt-1">Consolidated invoices will appear here.</p>
            </div>
          )}
        </div>

        {/* Vendor Breakdown */}
        <div className="card">
          <h2 className="text-lg font-semibold text-slate-900 dark:text-white mb-4">
            Vendor Breakdown
          </h2>

          {vendorBreakdown.length > 0 ? (
            <div className="space-y-3">
              {vendorBreakdown.map((vendor, idx) => {
                const total = vendorBreakdown.reduce((sum, v) => sum + v.amount, 0);
                const percentage = total > 0 ? (vendor.amount / total) * 100 : 0;
                return (
                  <div key={idx}>
                    <div className="flex items-center justify-between mb-1">
                      <div className="flex-1 min-w-0">
                        <p className="font-medium text-slate-900 dark:text-white text-sm truncate">
                          {vendor.name}
                        </p>
                        <p className="text-xs text-slate-500 dark:text-slate-400">
                          {categoryLabels[vendor.category] || vendor.category}
                        </p>
                      </div>
                      <div className="text-right">
                        <p className="font-medium text-slate-900 dark:text-white text-sm">
                          {formatCurrency(vendor.amount)}
                        </p>
                        <p className="text-xs text-slate-500">{percentage.toFixed(0)}%</p>
                      </div>
                    </div>
                    <div className="w-full bg-slate-200 dark:bg-slate-700 rounded-full h-2">
                      <div
                        className="bg-emerald-600 dark:bg-emerald-500 h-2 rounded-full transition-all"
                        style={{ width: `${percentage}%` }}
                      />
                    </div>
                  </div>
                );
              })}

              <div className="pt-3 mt-3 border-t border-slate-200 dark:border-slate-700">
                <div className="flex justify-between font-semibold">
                  <span className="text-slate-900 dark:text-white">Total</span>
                  <span className="text-emerald-600 dark:text-emerald-400">
                    {formatCurrency(vendorBreakdown.reduce((sum, v) => sum + v.amount, 0))}
                  </span>
                </div>
              </div>
            </div>
          ) : (
            <div className="text-center py-8 text-slate-500 dark:text-slate-400">
              <p className="text-sm">Add bill accounts to see vendor breakdown</p>
            </div>
          )}
        </div>
      </div>

      {/* Bill Accounts */}
      <div className="card">
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-lg font-semibold text-slate-900 dark:text-white">
            Your Bill Accounts
          </h2>
          <button
            onClick={() => setShowAddAccountModal(true)}
            className="text-sm text-emerald-600 hover:text-emerald-500 dark:text-emerald-400 font-medium"
          >
            + Add Account
          </button>
        </div>

        {billAccounts.length > 0 ? (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {billAccounts.map((account) => (
              <div
                key={account.id}
                className="p-4 rounded-lg bg-slate-50 dark:bg-slate-700/50 border border-slate-200 dark:border-slate-600"
              >
                <div className="flex items-start justify-between mb-2">
                  <div>
                    <h3 className="font-medium text-slate-900 dark:text-white">{account.nickname}</h3>
                    <p className="text-sm text-slate-500 dark:text-slate-400">
                      {account.vendor?.displayName || categoryLabels[account.category] || account.category}
                    </p>
                  </div>
                  <span className="text-xs px-2 py-1 rounded bg-slate-200 dark:bg-slate-600 text-slate-700 dark:text-slate-300">
                    {categoryLabels[account.category] || account.category}
                  </span>
                </div>
                {account.accountNumber && (
                  <p className="text-xs text-slate-500 dark:text-slate-400 mb-2">
                    Account: {account.accountNumber}
                  </p>
                )}
                <div className="flex items-center justify-between mt-3">
                  <span className="text-lg font-semibold text-slate-900 dark:text-white">
                    {formatCurrency(account.typicalAmount)}<span className="text-sm font-normal text-slate-500">/mo</span>
                  </span>
                  {account.nextDueDate && (
                    <span className={`text-xs ${new Date(account.nextDueDate) <= new Date(Date.now() + 7 * 24 * 60 * 60 * 1000) ? 'text-yellow-600 dark:text-yellow-400' : 'text-slate-500'}`}>
                      Due {formatDate(account.nextDueDate)}
                    </span>
                  )}
                </div>
              </div>
            ))}
          </div>
        ) : (
          <div className="text-center py-8 text-slate-500 dark:text-slate-400">
            <p>No bill accounts set up yet.</p>
            <button
              onClick={() => setShowAddAccountModal(true)}
              className="mt-2 text-emerald-600 hover:text-emerald-500 dark:text-emerald-400 font-medium"
            >
              Add your first account
            </button>
          </div>
        )}
      </div>

      {/* Suggested Vendors to Add */}
      {suggestions.length > 0 && (
        <div className="card">
          <h2 className="text-lg font-semibold text-slate-900 dark:text-white mb-4">
            Suggested Accounts to Add
          </h2>
          <p className="text-sm text-slate-600 dark:text-slate-400 mb-4">
            Popular services that other homeowners track with Haven
          </p>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {suggestions.slice(0, 6).map((suggestion) => (
              <div
                key={suggestion.category}
                className="p-4 rounded-lg border-2 border-dashed border-slate-300 dark:border-slate-600 hover:border-emerald-400 dark:hover:border-emerald-500 transition-colors cursor-pointer"
                onClick={() => setShowAddAccountModal(true)}
              >
                <div className="flex items-center justify-between mb-2">
                  <h3 className="font-medium text-slate-900 dark:text-white">{suggestion.name}</h3>
                  <span className="text-xs text-slate-500 dark:text-slate-400">{suggestion.avgCost}</span>
                </div>
                <p className="text-sm text-slate-600 dark:text-slate-400">{suggestion.description}</p>
                <div className="mt-3 flex items-center text-emerald-600 dark:text-emerald-400 text-sm font-medium">
                  <svg className="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
                  </svg>
                  Add Account
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Invoice History */}
      {invoices.length > 0 && (
        <div className="card">
          <h2 className="text-lg font-semibold text-slate-900 dark:text-white mb-4">
            Invoice History
          </h2>

          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b border-slate-200 dark:border-slate-700">
                  <th className="text-left py-3 px-4 text-sm font-medium text-slate-600 dark:text-slate-400">Invoice #</th>
                  <th className="text-left py-3 px-4 text-sm font-medium text-slate-600 dark:text-slate-400">Period</th>
                  <th className="text-left py-3 px-4 text-sm font-medium text-slate-600 dark:text-slate-400">Items</th>
                  <th className="text-left py-3 px-4 text-sm font-medium text-slate-600 dark:text-slate-400">Total</th>
                  <th className="text-left py-3 px-4 text-sm font-medium text-slate-600 dark:text-slate-400">Status</th>
                  <th className="text-left py-3 px-4 text-sm font-medium text-slate-600 dark:text-slate-400">Date</th>
                </tr>
              </thead>
              <tbody>
                {invoices.map((invoice) => (
                  <tr
                    key={invoice.id}
                    className="border-b border-slate-100 dark:border-slate-700/50 hover:bg-slate-50 dark:hover:bg-slate-700/30 cursor-pointer"
                    onClick={() => setExpandedInvoice(expandedInvoice === invoice.id ? null : invoice.id)}
                  >
                    <td className="py-3 px-4">
                      <span className="font-medium text-slate-900 dark:text-white">{invoice.invoiceNumber}</span>
                    </td>
                    <td className="py-3 px-4 text-sm text-slate-600 dark:text-slate-400">
                      {formatDate(invoice.billingPeriodStart)} - {formatDate(invoice.billingPeriodEnd)}
                    </td>
                    <td className="py-3 px-4 text-sm text-slate-600 dark:text-slate-400">{invoice.itemCount}</td>
                    <td className="py-3 px-4">
                      <span className="font-medium text-slate-900 dark:text-white">{formatCurrency(invoice.total)}</span>
                    </td>
                    <td className="py-3 px-4">
                      <span className={`px-2 py-1 text-xs font-medium rounded-full ${getStatusBadge(invoice.status)}`}>
                        {invoice.status}
                      </span>
                    </td>
                    <td className="py-3 px-4 text-sm text-slate-600 dark:text-slate-400">{formatDate(invoice.createdAt)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Add Account Modal */}
      {showAddAccountModal && (
        <div className="fixed inset-0 z-50 overflow-y-auto">
          <div className="flex min-h-full items-end justify-center p-4 text-center sm:items-center sm:p-0">
            <div className="fixed inset-0 bg-black/50 transition-opacity" onClick={() => setShowAddAccountModal(false)} />

            <div className="relative transform overflow-hidden rounded-xl bg-white dark:bg-slate-800 text-left shadow-xl transition-all sm:my-8 sm:w-full sm:max-w-lg">
              <div className="border-b border-slate-200 dark:border-slate-700 px-6 py-4">
                <div className="flex items-start justify-between">
                  <h3 className="text-lg font-semibold text-slate-900 dark:text-white">Add Bill Account</h3>
                  <button
                    onClick={() => setShowAddAccountModal(false)}
                    className="text-slate-400 hover:text-slate-500 dark:hover:text-slate-300"
                  >
                    <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                    </svg>
                  </button>
                </div>
              </div>

              <div className="px-6 py-4 space-y-4">
                <div>
                  <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">
                    Account Nickname
                  </label>
                  <input
                    type="text"
                    placeholder="e.g., Electric Bill"
                    className="w-full px-3 py-2 rounded-lg border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-700 text-slate-900 dark:text-white"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">
                    Category
                  </label>
                  <select className="w-full px-3 py-2 rounded-lg border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-700 text-slate-900 dark:text-white">
                    <option value="">Select category...</option>
                    {Object.entries(categoryLabels).map(([value, label]) => (
                      <option key={value} value={value}>{label}</option>
                    ))}
                  </select>
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">
                    Account Number (optional)
                  </label>
                  <input
                    type="text"
                    placeholder="e.g., ACC-1234-5678"
                    className="w-full px-3 py-2 rounded-lg border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-700 text-slate-900 dark:text-white"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">
                    Typical Monthly Amount
                  </label>
                  <input
                    type="number"
                    placeholder="0.00"
                    className="w-full px-3 py-2 rounded-lg border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-700 text-slate-900 dark:text-white"
                  />
                </div>
              </div>

              <div className="border-t border-slate-200 dark:border-slate-700 px-6 py-4 flex gap-3">
                <button
                  onClick={() => setShowAddAccountModal(false)}
                  className="flex-1 px-4 py-2 text-slate-700 dark:text-slate-300 font-medium rounded-lg border border-slate-300 dark:border-slate-600 hover:bg-slate-50 dark:hover:bg-slate-700 transition-colors"
                >
                  Cancel
                </button>
                <button
                  onClick={() => {
                    // TODO: Implement add account
                    setShowAddAccountModal(false);
                  }}
                  className="flex-1 px-4 py-2 bg-emerald-600 text-white font-medium rounded-lg hover:bg-emerald-700 transition-colors"
                >
                  Add Account
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

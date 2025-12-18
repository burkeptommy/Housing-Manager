'use client';

import { useState, useEffect, useCallback } from 'react';
import { getApiClient } from '@/lib/api';
import type {
  VendorPayable,
  TransactionPayoutMethod,
  BatchPayPreview,
  ExecutePayoutResponse,
} from '@haven/core';

interface SelectedPayable {
  transactionId: string;
  payoutMethod: TransactionPayoutMethod;
}

export default function PayablesPage() {
  const [payables, setPayables] = useState<VendorPayable[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState('');
  const [selectedItems, setSelectedItems] = useState<Map<string, SelectedPayable>>(new Map());
  const [showBatchPayModal, setShowBatchPayModal] = useState(false);
  const [batchPreview, setBatchPreview] = useState<BatchPayPreview | null>(null);
  const [isExecuting, setIsExecuting] = useState(false);
  const [executionResult, setExecutionResult] = useState<ExecutePayoutResponse | null>(null);

  const api = getApiClient();

  const loadPayables = useCallback(async () => {
    try {
      setIsLoading(true);
      const data = await api.getPayables();
      setPayables(data);
    } catch (err: unknown) {
      const message =
        err && typeof err === 'object' && 'message' in err
          ? (err as { message: string }).message
          : 'Failed to load payables';
      setError(message);
    } finally {
      setIsLoading(false);
    }
  }, [api]);

  useEffect(() => {
    loadPayables();
  }, [loadPayables]);

  const handleSelectAll = (checked: boolean) => {
    if (checked) {
      const newSelected = new Map<string, SelectedPayable>();
      payables.forEach((p) => {
        newSelected.set(p.transactionId, {
          transactionId: p.transactionId,
          payoutMethod: p.recommendedPayoutMethod,
        });
      });
      setSelectedItems(newSelected);
    } else {
      setSelectedItems(new Map());
    }
  };

  const handleSelectItem = (payable: VendorPayable, checked: boolean) => {
    const newSelected = new Map(selectedItems);
    if (checked) {
      newSelected.set(payable.transactionId, {
        transactionId: payable.transactionId,
        payoutMethod: payable.recommendedPayoutMethod,
      });
    } else {
      newSelected.delete(payable.transactionId);
    }
    setSelectedItems(newSelected);
  };

  const handlePayoutMethodChange = (transactionId: string, method: TransactionPayoutMethod) => {
    const newSelected = new Map(selectedItems);
    const item = newSelected.get(transactionId);
    if (item) {
      newSelected.set(transactionId, { ...item, payoutMethod: method });
      setSelectedItems(newSelected);
    }
  };

  const handleBatchPay = async () => {
    if (selectedItems.size === 0) return;

    try {
      const items = Array.from(selectedItems.values());
      const preview = await api.previewPayout({ items });
      setBatchPreview(preview);
      setShowBatchPayModal(true);
    } catch (err: unknown) {
      const message =
        err && typeof err === 'object' && 'message' in err
          ? (err as { message: string }).message
          : 'Failed to preview payout';
      setError(message);
    }
  };

  const handleExecutePayout = async () => {
    if (!batchPreview) return;

    try {
      setIsExecuting(true);
      const items = Array.from(selectedItems.values());
      const result = await api.executePayout({ items });
      setExecutionResult(result);

      if (result.success) {
        // Reload payables after successful execution
        await loadPayables();
        setSelectedItems(new Map());
      }
    } catch (err: unknown) {
      const message =
        err && typeof err === 'object' && 'message' in err
          ? (err as { message: string }).message
          : 'Failed to execute payout';
      setError(message);
    } finally {
      setIsExecuting(false);
    }
  };

  const closeModal = () => {
    setShowBatchPayModal(false);
    setBatchPreview(null);
    setExecutionResult(null);
  };

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
    }).format(amount);
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      month: 'short',
      day: 'numeric',
      year: 'numeric',
    });
  };

  const getMethodLabel = (method: TransactionPayoutMethod): string => {
    const labels: Record<TransactionPayoutMethod, string> = {
      CHECKBOOK_IO: 'Mail Check',
      STRIPE: 'Stripe Transfer',
      CASH: 'Cash',
      COMPANY_CARD: 'Company Card',
      BANK_TRANSFER: 'Bank Transfer',
    };
    return labels[method];
  };

  const getMethodIcon = (method: TransactionPayoutMethod) => {
    switch (method) {
      case 'CHECKBOOK_IO':
        return (
          <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
          </svg>
        );
      case 'STRIPE':
        return (
          <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 10V3L4 14h7v7l9-11h-7z" />
          </svg>
        );
      default:
        return (
          <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 9V7a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2m2 4h10a2 2 0 002-2v-6a2 2 0 00-2-2H9a2 2 0 00-2 2v6a2 2 0 002 2z" />
          </svg>
        );
    }
  };

  const selectedTotal = Array.from(selectedItems.keys()).reduce((sum, id) => {
    const payable = payables.find((p) => p.transactionId === id);
    return sum + (payable?.amount || 0);
  }, 0);

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-emerald-600"></div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-slate-900 dark:text-white">Pay Bills</h1>
          <p className="text-slate-600 dark:text-slate-400">
            Review and pay unpaid vendor invoices
          </p>
        </div>
        {selectedItems.size > 0 && (
          <button
            onClick={handleBatchPay}
            className="flex items-center gap-2 px-4 py-2 bg-emerald-600 text-white rounded-lg hover:bg-emerald-700 transition-colors font-medium"
          >
            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 9V7a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2m2 4h10a2 2 0 002-2v-6a2 2 0 00-2-2H9a2 2 0 00-2 2v6a2 2 0 002 2z" />
            </svg>
            Batch Pay ({selectedItems.size}) - {formatCurrency(selectedTotal)}
          </button>
        )}
      </div>

      {/* Error */}
      {error && (
        <div className="p-4 rounded-lg bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800">
          <p className="text-sm text-red-600 dark:text-red-400">{error}</p>
          <button
            onClick={() => setError('')}
            className="mt-2 text-sm text-red-700 dark:text-red-300 underline"
          >
            Dismiss
          </button>
        </div>
      )}

      {/* Stats */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="card">
          <div className="flex items-center gap-4">
            <div className="w-12 h-12 rounded-lg bg-blue-100 dark:bg-blue-900/30 flex items-center justify-center">
              <svg className="w-6 h-6 text-blue-600 dark:text-blue-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
              </svg>
            </div>
            <div>
              <p className="text-2xl font-bold text-slate-900 dark:text-white">{payables.length}</p>
              <p className="text-sm text-slate-500 dark:text-slate-400">Unpaid Invoices</p>
            </div>
          </div>
        </div>
        <div className="card">
          <div className="flex items-center gap-4">
            <div className="w-12 h-12 rounded-lg bg-emerald-100 dark:bg-emerald-900/30 flex items-center justify-center">
              <svg className="w-6 h-6 text-emerald-600 dark:text-emerald-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
            </div>
            <div>
              <p className="text-2xl font-bold text-slate-900 dark:text-white">
                {formatCurrency(payables.reduce((sum, p) => sum + p.amount, 0))}
              </p>
              <p className="text-sm text-slate-500 dark:text-slate-400">Total Outstanding</p>
            </div>
          </div>
        </div>
        <div className="card">
          <div className="flex items-center gap-4">
            <div className="w-12 h-12 rounded-lg bg-purple-100 dark:bg-purple-900/30 flex items-center justify-center">
              <svg className="w-6 h-6 text-purple-600 dark:text-purple-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
              </svg>
            </div>
            <div>
              <p className="text-2xl font-bold text-slate-900 dark:text-white">{selectedItems.size}</p>
              <p className="text-sm text-slate-500 dark:text-slate-400">Selected</p>
            </div>
          </div>
        </div>
        <div className="card">
          <div className="flex items-center gap-4">
            <div className="w-12 h-12 rounded-lg bg-yellow-100 dark:bg-yellow-900/30 flex items-center justify-center">
              <svg className="w-6 h-6 text-yellow-600 dark:text-yellow-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 9V7a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2m2 4h10a2 2 0 002-2v-6a2 2 0 00-2-2H9a2 2 0 00-2 2v6a2 2 0 002 2z" />
              </svg>
            </div>
            <div>
              <p className="text-2xl font-bold text-slate-900 dark:text-white">{formatCurrency(selectedTotal)}</p>
              <p className="text-sm text-slate-500 dark:text-slate-400">To Pay</p>
            </div>
          </div>
        </div>
      </div>

      {/* Payables Table */}
      <div className="card overflow-hidden">
        <div className="px-6 py-4 border-b border-slate-200 dark:border-slate-700">
          <h2 className="text-lg font-semibold text-slate-900 dark:text-white">Unpaid Vendor Invoices</h2>
        </div>

        {payables.length === 0 ? (
          <div className="p-12 text-center">
            <svg className="w-12 h-12 mx-auto text-slate-400 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            <h3 className="text-lg font-medium text-slate-900 dark:text-white mb-2">All caught up!</h3>
            <p className="text-slate-600 dark:text-slate-400">No unpaid vendor invoices at the moment.</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead className="bg-slate-50 dark:bg-slate-800">
                <tr>
                  <th className="px-6 py-3 text-left">
                    <input
                      type="checkbox"
                      checked={selectedItems.size === payables.length && payables.length > 0}
                      onChange={(e) => handleSelectAll(e.target.checked)}
                      className="rounded border-slate-300 dark:border-slate-600 text-emerald-600 focus:ring-emerald-500"
                    />
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">
                    Vendor
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">
                    Property
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">
                    Description
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">
                    Date
                  </th>
                  <th className="px-6 py-3 text-right text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">
                    Amount
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">
                    Payout Method
                  </th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-200 dark:divide-slate-700">
                {payables.map((payable) => {
                  const isSelected = selectedItems.has(payable.transactionId);
                  const selectedMethod = selectedItems.get(payable.transactionId)?.payoutMethod || payable.recommendedPayoutMethod;

                  return (
                    <tr
                      key={payable.id}
                      className={`${
                        isSelected
                          ? 'bg-emerald-50 dark:bg-emerald-900/10'
                          : 'hover:bg-slate-50 dark:hover:bg-slate-800/50'
                      }`}
                    >
                      <td className="px-6 py-4">
                        <input
                          type="checkbox"
                          checked={isSelected}
                          onChange={(e) => handleSelectItem(payable, e.target.checked)}
                          className="rounded border-slate-300 dark:border-slate-600 text-emerald-600 focus:ring-emerald-500"
                        />
                      </td>
                      <td className="px-6 py-4">
                        <div>
                          <p className="font-medium text-slate-900 dark:text-white">{payable.vendorName}</p>
                          {payable.vendorEmail && (
                            <p className="text-sm text-slate-500 dark:text-slate-400">{payable.vendorEmail}</p>
                          )}
                        </div>
                      </td>
                      <td className="px-6 py-4 text-slate-600 dark:text-slate-300">
                        {payable.householdName}
                      </td>
                      <td className="px-6 py-4">
                        <p className="text-slate-900 dark:text-white max-w-xs truncate">{payable.description}</p>
                      </td>
                      <td className="px-6 py-4 text-slate-600 dark:text-slate-300">
                        {formatDate(payable.createdAt)}
                      </td>
                      <td className="px-6 py-4 text-right font-medium text-slate-900 dark:text-white">
                        {formatCurrency(payable.amount)}
                      </td>
                      <td className="px-6 py-4">
                        {isSelected ? (
                          <select
                            value={selectedMethod}
                            onChange={(e) =>
                              handlePayoutMethodChange(payable.transactionId, e.target.value as TransactionPayoutMethod)
                            }
                            className="block w-full px-3 py-1.5 text-sm rounded-lg border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-800 text-slate-900 dark:text-white focus:ring-2 focus:ring-emerald-500"
                          >
                            {payable.availablePayoutMethods.map((method) => (
                              <option key={method} value={method}>
                                {getMethodLabel(method)}
                              </option>
                            ))}
                          </select>
                        ) : (
                          <div className="flex items-center gap-2 text-sm text-slate-600 dark:text-slate-400">
                            {getMethodIcon(payable.recommendedPayoutMethod)}
                            <span>{getMethodLabel(payable.recommendedPayoutMethod)}</span>
                          </div>
                        )}
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Batch Pay Modal */}
      {showBatchPayModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50">
          <div className="bg-white dark:bg-slate-800 rounded-xl shadow-xl max-w-lg w-full max-h-[80vh] overflow-hidden">
            {/* Modal Header */}
            <div className="px-6 py-4 border-b border-slate-200 dark:border-slate-700 flex items-center justify-between">
              <h3 className="text-lg font-semibold text-slate-900 dark:text-white">
                {executionResult ? 'Payment Complete' : 'Confirm Batch Payment'}
              </h3>
              <button
                onClick={closeModal}
                className="p-1 text-slate-400 hover:text-slate-600 dark:hover:text-slate-300"
              >
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                </svg>
              </button>
            </div>

            {/* Modal Body */}
            <div className="p-6 overflow-y-auto max-h-[60vh]">
              {executionResult ? (
                <div className="space-y-6">
                  {/* Execution Result */}
                  <div className={`p-4 rounded-lg ${
                    executionResult.success
                      ? 'bg-emerald-50 dark:bg-emerald-900/20 border border-emerald-200 dark:border-emerald-800'
                      : 'bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-800'
                  }`}>
                    <div className="flex items-center gap-3">
                      {executionResult.success ? (
                        <svg className="w-8 h-8 text-emerald-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                        </svg>
                      ) : (
                        <svg className="w-8 h-8 text-yellow-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
                        </svg>
                      )}
                      <div>
                        <p className="font-semibold text-slate-900 dark:text-white">
                          {executionResult.success ? 'All payments processed!' : 'Some payments failed'}
                        </p>
                        <p className="text-sm text-slate-600 dark:text-slate-400">
                          {executionResult.successfulItems} of {executionResult.totalItems} payments successful
                        </p>
                      </div>
                    </div>
                  </div>

                  {/* Summary */}
                  {executionResult.summary && (
                    <div className="grid grid-cols-2 gap-4">
                      {executionResult.summary.checksQueued > 0 && (
                        <div className="p-4 rounded-lg bg-blue-50 dark:bg-blue-900/20">
                          <p className="text-2xl font-bold text-blue-600 dark:text-blue-400">
                            {executionResult.summary.checksQueued}
                          </p>
                          <p className="text-sm text-blue-700 dark:text-blue-300">Checks Queued</p>
                          <p className="text-sm font-medium text-blue-800 dark:text-blue-200 mt-1">
                            {formatCurrency(executionResult.summary.totalCheckAmount)}
                          </p>
                        </div>
                      )}
                      {executionResult.summary.stripeTransfers > 0 && (
                        <div className="p-4 rounded-lg bg-purple-50 dark:bg-purple-900/20">
                          <p className="text-2xl font-bold text-purple-600 dark:text-purple-400">
                            {executionResult.summary.stripeTransfers}
                          </p>
                          <p className="text-sm text-purple-700 dark:text-purple-300">Stripe Transfers</p>
                          <p className="text-sm font-medium text-purple-800 dark:text-purple-200 mt-1">
                            {formatCurrency(executionResult.summary.totalStripeAmount)}
                          </p>
                        </div>
                      )}
                    </div>
                  )}

                  {/* Individual Results */}
                  <div className="space-y-2">
                    {executionResult.results.map((result) => (
                      <div
                        key={result.transactionId}
                        className={`p-3 rounded-lg flex items-center justify-between ${
                          result.success
                            ? 'bg-slate-50 dark:bg-slate-700/50'
                            : 'bg-red-50 dark:bg-red-900/20'
                        }`}
                      >
                        <div className="flex items-center gap-3">
                          {result.success ? (
                            <svg className="w-5 h-5 text-emerald-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                            </svg>
                          ) : (
                            <svg className="w-5 h-5 text-red-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                            </svg>
                          )}
                          <div>
                            <p className="text-sm font-medium text-slate-900 dark:text-white">
                              {getMethodLabel(result.payoutMethod)}
                            </p>
                            {result.referenceId && (
                              <p className="text-xs text-slate-500 dark:text-slate-400">
                                Ref: {result.referenceId}
                              </p>
                            )}
                            {result.error && (
                              <p className="text-xs text-red-600 dark:text-red-400">{result.error}</p>
                            )}
                          </div>
                        </div>
                        {result.estimatedDelivery && (
                          <span className="text-xs text-slate-500 dark:text-slate-400">
                            Est. delivery: {result.estimatedDelivery}
                          </span>
                        )}
                      </div>
                    ))}
                  </div>
                </div>
              ) : batchPreview ? (
                <div className="space-y-6">
                  {/* Preview Summary */}
                  <div className="p-4 rounded-lg bg-slate-50 dark:bg-slate-700/50">
                    <div className="flex items-center justify-between mb-4">
                      <span className="text-lg font-semibold text-slate-900 dark:text-white">Total Amount</span>
                      <span className="text-2xl font-bold text-emerald-600 dark:text-emerald-400">
                        {formatCurrency(batchPreview.totalAmount)}
                      </span>
                    </div>
                    <div className="grid grid-cols-2 gap-4">
                      {batchPreview.checkCount > 0 && (
                        <div className="flex items-center gap-2">
                          <svg className="w-5 h-5 text-blue-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
                          </svg>
                          <span className="text-sm text-slate-600 dark:text-slate-300">
                            {batchPreview.checkCount} checks ({formatCurrency(batchPreview.checkTotal)})
                          </span>
                        </div>
                      )}
                      {batchPreview.stripeCount > 0 && (
                        <div className="flex items-center gap-2">
                          <svg className="w-5 h-5 text-purple-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 10V3L4 14h7v7l9-11h-7z" />
                          </svg>
                          <span className="text-sm text-slate-600 dark:text-slate-300">
                            {batchPreview.stripeCount} Stripe transfers ({formatCurrency(batchPreview.stripeTotal)})
                          </span>
                        </div>
                      )}
                    </div>
                  </div>

                  {/* Items List */}
                  <div className="space-y-2">
                    <h4 className="text-sm font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">
                      Payment Details
                    </h4>
                    {batchPreview.items.map((item) => (
                      <div
                        key={item.transactionId}
                        className="p-3 rounded-lg bg-slate-50 dark:bg-slate-700/50 flex items-center justify-between"
                      >
                        <div>
                          <p className="font-medium text-slate-900 dark:text-white">{item.vendorName}</p>
                          <p className="text-sm text-slate-500 dark:text-slate-400">{item.methodLabel}</p>
                        </div>
                        <span className="font-medium text-slate-900 dark:text-white">
                          {formatCurrency(item.amount)}
                        </span>
                      </div>
                    ))}
                  </div>
                </div>
              ) : null}
            </div>

            {/* Modal Footer */}
            <div className="px-6 py-4 border-t border-slate-200 dark:border-slate-700 flex justify-end gap-3">
              {executionResult ? (
                <button
                  onClick={closeModal}
                  className="px-4 py-2 bg-emerald-600 text-white rounded-lg hover:bg-emerald-700 transition-colors font-medium"
                >
                  Done
                </button>
              ) : (
                <>
                  <button
                    onClick={closeModal}
                    className="px-4 py-2 text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-700 rounded-lg transition-colors font-medium"
                  >
                    Cancel
                  </button>
                  <button
                    onClick={handleExecutePayout}
                    disabled={isExecuting}
                    className="px-4 py-2 bg-emerald-600 text-white rounded-lg hover:bg-emerald-700 transition-colors font-medium disabled:opacity-50 disabled:cursor-not-allowed flex items-center gap-2"
                  >
                    {isExecuting ? (
                      <>
                        <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin"></div>
                        Processing...
                      </>
                    ) : (
                      <>
                        <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                        </svg>
                        Execute Payment
                      </>
                    )}
                  </button>
                </>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

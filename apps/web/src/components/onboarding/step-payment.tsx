'use client';

import { useState, useCallback } from 'react';
import type { SubscriptionPlan } from '@haven/core';
import { SUBSCRIPTION_PLANS } from '@haven/core';

interface StepPaymentProps {
  onSubmit: (data: { plan: SubscriptionPlan; paymentMethodId?: string }) => void;
  onBack: () => void;
  isSubmitting?: boolean;
  stripeClientSecret?: string;
  onSetupStripe?: () => void;
}

export function StepPayment({
  onSubmit,
  onBack,
  isSubmitting,
  stripeClientSecret: _stripeClientSecret,
  onSetupStripe: _onSetupStripe,
}: StepPaymentProps) {
  // Note: stripeClientSecret and onSetupStripe reserved for future Stripe integration
  void _stripeClientSecret;
  void _onSetupStripe;
  const [selectedPlan, setSelectedPlan] = useState<SubscriptionPlan>('ESSENTIALS');
  const [paymentSetup, setPaymentSetup] = useState(false);
  const [cardDetails, setCardDetails] = useState({
    cardNumber: '',
    expiry: '',
    cvc: '',
    name: '',
  });

  const handleSubmit = useCallback(() => {
    // In a real implementation, we would use Stripe Elements here
    // For now, we'll just pass the selected plan
    onSubmit({ plan: selectedPlan });
  }, [selectedPlan, onSubmit]);

  const handleCardNumberChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    let value = e.target.value.replace(/\D/g, '');
    if (value.length > 16) value = value.slice(0, 16);
    // Format with spaces every 4 digits
    const formatted = value.replace(/(.{4})/g, '$1 ').trim();
    setCardDetails((prev) => ({ ...prev, cardNumber: formatted }));
  };

  const handleExpiryChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    let value = e.target.value.replace(/\D/g, '');
    if (value.length > 4) value = value.slice(0, 4);
    if (value.length >= 2) {
      value = value.slice(0, 2) + '/' + value.slice(2);
    }
    setCardDetails((prev) => ({ ...prev, expiry: value }));
  };

  const handleCvcChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    let value = e.target.value.replace(/\D/g, '');
    if (value.length > 4) value = value.slice(0, 4);
    setCardDetails((prev) => ({ ...prev, cvc: value }));
  };

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-lg font-semibold text-slate-900 dark:text-white mb-1">
          Choose your plan
        </h2>
        <p className="text-sm text-slate-600 dark:text-slate-400">
          Select a subscription plan that fits your needs. You can change this anytime.
        </p>
      </div>

      {/* Plan Selection */}
      <div className="space-y-4">
        {(Object.keys(SUBSCRIPTION_PLANS) as SubscriptionPlan[]).map((planId) => {
          const plan = SUBSCRIPTION_PLANS[planId];
          const isSelected = selectedPlan === planId;

          return (
            <label
              key={planId}
              className={`block p-4 rounded-lg border-2 cursor-pointer transition-all ${
                isSelected
                  ? 'border-blue-500 bg-blue-50 dark:bg-blue-900/20'
                  : 'border-slate-200 dark:border-slate-700 hover:border-slate-300 dark:hover:border-slate-600'
              }`}
            >
              <div className="flex items-start gap-4">
                <input
                  type="radio"
                  name="plan"
                  value={planId}
                  checked={isSelected}
                  onChange={() => setSelectedPlan(planId)}
                  className="mt-1"
                />
                <div className="flex-1">
                  <div className="flex items-center justify-between">
                    <div>
                      <h3 className="font-semibold text-slate-900 dark:text-white">
                        {plan.name}
                      </h3>
                      {planId === 'PREMIUM' && (
                        <span className="inline-block mt-1 px-2 py-0.5 text-xs font-medium bg-blue-100 dark:bg-blue-900 text-blue-700 dark:text-blue-300 rounded-full">
                          Recommended
                        </span>
                      )}
                    </div>
                    <div className="text-right">
                      <span className="text-2xl font-bold text-slate-900 dark:text-white">
                        ${plan.price}
                      </span>
                      <span className="text-slate-500 dark:text-slate-400">/mo</span>
                    </div>
                  </div>
                  <ul className="mt-3 space-y-2">
                    {plan.features.map((feature, idx) => (
                      <li key={idx} className="flex items-center gap-2 text-sm text-slate-600 dark:text-slate-400">
                        <svg
                          className="w-4 h-4 text-green-500"
                          fill="none"
                          stroke="currentColor"
                          viewBox="0 0 24 24"
                        >
                          <path
                            strokeLinecap="round"
                            strokeLinejoin="round"
                            strokeWidth={2}
                            d="M5 13l4 4L19 7"
                          />
                        </svg>
                        {feature}
                      </li>
                    ))}
                  </ul>
                </div>
              </div>
            </label>
          );
        })}
      </div>

      {/* Payment Method Section */}
      <div className="space-y-4">
        <h3 className="text-sm font-medium text-slate-700 dark:text-slate-300 border-b border-slate-200 dark:border-slate-700 pb-2">
          Payment Method
        </h3>

        {!paymentSetup ? (
          <div className="p-6 border-2 border-dashed border-slate-300 dark:border-slate-600 rounded-lg text-center">
            <svg
              className="w-12 h-12 mx-auto text-slate-400"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z"
              />
            </svg>
            <p className="mt-2 text-slate-600 dark:text-slate-400">
              Add a payment method to complete your subscription
            </p>
            <button
              type="button"
              onClick={() => setPaymentSetup(true)}
              className="mt-4 btn btn-secondary"
            >
              Add Payment Method
            </button>
          </div>
        ) : (
          <div className="p-4 bg-slate-50 dark:bg-slate-800 rounded-lg space-y-4">
            <div>
              <label className="label block mb-1.5">Cardholder name</label>
              <input
                type="text"
                value={cardDetails.name}
                onChange={(e) => setCardDetails((prev) => ({ ...prev, name: e.target.value }))}
                className="input"
                placeholder="John Doe"
              />
            </div>

            <div>
              <label className="label block mb-1.5">Card number</label>
              <input
                type="text"
                value={cardDetails.cardNumber}
                onChange={handleCardNumberChange}
                className="input font-mono"
                placeholder="1234 5678 9012 3456"
              />
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="label block mb-1.5">Expiry date</label>
                <input
                  type="text"
                  value={cardDetails.expiry}
                  onChange={handleExpiryChange}
                  className="input font-mono"
                  placeholder="MM/YY"
                />
              </div>
              <div>
                <label className="label block mb-1.5">CVC</label>
                <input
                  type="text"
                  value={cardDetails.cvc}
                  onChange={handleCvcChange}
                  className="input font-mono"
                  placeholder="123"
                />
              </div>
            </div>

            <div className="flex items-center gap-2 text-xs text-slate-500 dark:text-slate-400">
              <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"
                />
              </svg>
              Your payment information is secured with 256-bit SSL encryption
            </div>

            <button
              type="button"
              onClick={() => setPaymentSetup(false)}
              className="text-sm text-slate-500 hover:text-slate-700 dark:hover:text-slate-300"
            >
              Cancel
            </button>
          </div>
        )}
      </div>

      {/* Billing Summary */}
      <div className="p-4 bg-slate-50 dark:bg-slate-800 rounded-lg">
        <h4 className="font-medium text-slate-900 dark:text-white mb-2">Billing Summary</h4>
        <div className="flex items-center justify-between text-sm">
          <span className="text-slate-600 dark:text-slate-400">
            {SUBSCRIPTION_PLANS[selectedPlan].name} Plan
          </span>
          <span className="font-medium text-slate-900 dark:text-white">
            ${SUBSCRIPTION_PLANS[selectedPlan].price}/mo
          </span>
        </div>
        <div className="mt-2 pt-2 border-t border-slate-200 dark:border-slate-700 flex items-center justify-between">
          <span className="font-medium text-slate-900 dark:text-white">Due today</span>
          <span className="font-bold text-slate-900 dark:text-white">
            ${SUBSCRIPTION_PLANS[selectedPlan].price}
          </span>
        </div>
        <p className="mt-2 text-xs text-slate-500 dark:text-slate-400">
          Cancel anytime. No long-term contracts.
        </p>
      </div>

      {/* Skip Option */}
      <div className="text-center">
        <button
          type="button"
          onClick={() => onSubmit({ plan: selectedPlan })}
          className="text-sm text-slate-500 hover:text-slate-700 dark:hover:text-slate-300"
        >
          Skip payment for now - set up later
        </button>
      </div>

      <div className="flex gap-3 pt-4">
        <button type="button" onClick={onBack} className="btn btn-secondary flex-1">
          Back
        </button>
        <button
          type="button"
          onClick={handleSubmit}
          disabled={isSubmitting}
          className="btn btn-primary flex-1"
        >
          {isSubmitting ? (
            <>
              <svg className="animate-spin -ml-1 mr-2 h-4 w-4" fill="none" viewBox="0 0 24 24">
                <circle
                  className="opacity-25"
                  cx="12"
                  cy="12"
                  r="10"
                  stroke="currentColor"
                  strokeWidth="4"
                />
                <path
                  className="opacity-75"
                  fill="currentColor"
                  d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                />
              </svg>
              Processing...
            </>
          ) : (
            'Continue'
          )}
        </button>
      </div>
    </div>
  );
}

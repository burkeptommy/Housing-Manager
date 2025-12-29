'use client';

import { usePathname } from 'next/navigation';
import { ProgressStepper } from '@/components/onboarding/ProgressStepper';
import { useOnboarding } from '@/context/OnboardingContext';

const WIZARD_STEPS = [
  { id: 'property', label: 'Property', href: '/onboarding/wizard/property' },
  { id: 'bills', label: 'Bills', href: '/onboarding/wizard/bills' },
  { id: 'bank', label: 'Bank', href: '/onboarding/wizard/bank' },
  { id: 'systems', label: 'Systems', href: '/onboarding/wizard/systems' },
  { id: 'family', label: 'Family', href: '/onboarding/wizard/family' },
  { id: 'review', label: 'Review', href: '/onboarding/wizard/review' },
];

export default function WizardLayout({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const { data } = useOnboarding();

  // Check if we're on the main wizard page (streamlined flow)
  const isStreamlinedFlow = pathname === '/onboarding/wizard';

  // For streamlined flow, don't show the old stepper
  if (isStreamlinedFlow) {
    return <>{children}</>;
  }

  // Legacy flow with stepper (for detailed/self-service mode)
  const currentStep = WIZARD_STEPS.find((step) => pathname.includes(step.id))?.id || 'property';

  const completedSteps = Object.entries(data.steps)
    .filter(([, completed]) => completed)
    .map(([step]) => step);

  return (
    <div>
      <ProgressStepper steps={WIZARD_STEPS} currentStep={currentStep} completedSteps={completedSteps} />
      {children}
    </div>
  );
}

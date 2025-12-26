'use client';

import { usePathname } from 'next/navigation';
import { ProgressStepper } from '@/components/onboarding/ProgressStepper';
import { useOnboarding } from '@/context/OnboardingContext';

const WIZARD_STEPS = [
  { id: 'property', label: 'Property', href: '/onboarding/wizard/property' },
  { id: 'bills', label: 'Bills', href: '/onboarding/wizard/bills' },
  { id: 'systems', label: 'Systems', href: '/onboarding/wizard/systems' },
  { id: 'family', label: 'Family', href: '/onboarding/wizard/family' },
  { id: 'review', label: 'Review', href: '/onboarding/wizard/review' },
];

export default function WizardLayout({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const { data } = useOnboarding();

  // Determine current step from URL
  const currentStep = WIZARD_STEPS.find((step) => pathname.includes(step.id))?.id || 'property';

  // Get completed steps from context
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

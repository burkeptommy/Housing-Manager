import { redirect } from 'next/navigation';

export default function WizardPage() {
  // TODO: Determine first incomplete step and redirect
  redirect('/onboarding/wizard/property');
}

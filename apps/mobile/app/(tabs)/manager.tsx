import React from 'react';
import { useSubscription } from '../../src/contexts/subscription-context';
import { AlfredManagerScreen } from '../../src/screens/AlfredManagerScreen';
import { SarahManagerScreen } from '../../src/screens/SarahManagerScreen';

/**
 * Manager Tab - Shows Alfred (AI) or Sarah (Human) based on subscription tier
 *
 * Essentials ($39/mo): Alfred AI home manager
 * Premium tiers ($349+): Sarah Chen human home manager
 */
export default function ManagerScreen() {
  const { isEssentials } = useSubscription();

  return isEssentials ? <AlfredManagerScreen /> : <SarahManagerScreen />;
}

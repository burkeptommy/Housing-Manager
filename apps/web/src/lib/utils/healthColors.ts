/**
 * Get semantic colors and label based on home health score
 *
 * Score ranges:
 * - 80-100: Excellent (emerald)
 * - 60-79: Good (emerald)
 * - 40-59: Needs Attention (amber)
 * - 0-39: Critical (red)
 */
export function getHealthColors(score: number) {
  if (score >= 80) {
    return {
      bg: 'bg-emerald-50',
      text: 'text-emerald-700',
      border: 'border-emerald-200',
      icon: 'text-emerald-500',
      badge: 'bg-emerald-100 text-emerald-700',
      progress: 'bg-emerald-500',
      progressHex: '#10B981',
      label: 'Excellent',
    };
  } else if (score >= 60) {
    return {
      bg: 'bg-emerald-50',
      text: 'text-emerald-700',
      border: 'border-emerald-200',
      icon: 'text-emerald-500',
      badge: 'bg-emerald-100 text-emerald-700',
      progress: 'bg-emerald-500',
      progressHex: '#10B981',
      label: 'Good',
    };
  } else if (score >= 40) {
    return {
      bg: 'bg-amber-50',
      text: 'text-amber-700',
      border: 'border-amber-200',
      icon: 'text-amber-500',
      badge: 'bg-amber-100 text-amber-700',
      progress: 'bg-amber-500',
      progressHex: '#F59E0B',
      label: 'Needs Attention',
    };
  } else {
    return {
      bg: 'bg-red-50',
      text: 'text-red-700',
      border: 'border-red-200',
      icon: 'text-red-500',
      badge: 'bg-red-100 text-red-700',
      progress: 'bg-red-500',
      progressHex: '#EF4444',
      label: 'Critical',
    };
  }
}

export type HealthColors = ReturnType<typeof getHealthColors>;

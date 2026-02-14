'use client';

import { Car, Zap, Truck, Bike } from 'lucide-react';

const vehicleStyles = {
  tesla: { bg: 'bg-emerald-100', icon: 'text-emerald-600', accent: 'bg-emerald-500' },
  electric: { bg: 'bg-emerald-100', icon: 'text-emerald-600', accent: 'bg-emerald-500' },
  suv: { bg: 'bg-sky-100', icon: 'text-sky-600', accent: 'bg-sky-500' },
  sedan: { bg: 'bg-haven-100', icon: 'text-haven-600', accent: 'bg-haven-500' },
  truck: { bg: 'bg-orange-100', icon: 'text-orange-600', accent: 'bg-orange-500' },
  sports: { bg: 'bg-rose-100', icon: 'text-rose-600', accent: 'bg-rose-500' },
  minivan: { bg: 'bg-violet-100', icon: 'text-violet-600', accent: 'bg-violet-500' },
  motorcycle: { bg: 'bg-amber-100', icon: 'text-amber-600', accent: 'bg-amber-500' },
  default: { bg: 'bg-neutral-100', icon: 'text-neutral-600', accent: 'bg-neutral-500' },
};

type VehicleType = keyof typeof vehicleStyles;

interface VehicleAvatarProps {
  type?: VehicleType;
  make?: string;
  model?: string;
  isElectric?: boolean;
  size?: 'sm' | 'md' | 'lg' | 'xl';
  className?: string;
}

const sizes = {
  sm: { container: 'w-12 h-12', icon: 'w-6 h-6', badge: 'w-4 h-4', badgeIcon: 'w-2.5 h-2.5' },
  md: { container: 'w-16 h-16', icon: 'w-8 h-8', badge: 'w-5 h-5', badgeIcon: 'w-3 h-3' },
  lg: { container: 'w-24 h-24', icon: 'w-12 h-12', badge: 'w-6 h-6', badgeIcon: 'w-3.5 h-3.5' },
  xl: { container: 'w-32 h-32', icon: 'w-16 h-16', badge: 'w-8 h-8', badgeIcon: 'w-4 h-4' },
};

function getVehicleType(make?: string, model?: string, type?: VehicleType, isElectric?: boolean): VehicleType {
  if (type && type !== 'default') return type;

  const makeLower = make?.toLowerCase() || '';
  const modelLower = model?.toLowerCase() || '';
  const combined = `${makeLower} ${modelLower}`;

  // Electric vehicles
  if (makeLower.includes('tesla') || isElectric) return 'electric';
  if (combined.includes('model s') || combined.includes('model 3') || combined.includes('model x') || combined.includes('model y')) return 'electric';
  if (combined.includes('electric') || combined.includes('ev') || combined.includes('bolt') || combined.includes('leaf')) return 'electric';

  // SUVs
  if (combined.includes('x5') || combined.includes('suv') || combined.includes('highlander') || combined.includes('pilot')) return 'suv';
  if (combined.includes('explorer') || combined.includes('tahoe') || combined.includes('4runner') || combined.includes('grand cherokee')) return 'suv';
  if (combined.includes('rav4') || combined.includes('crv') || combined.includes('cr-v') || combined.includes('tucson')) return 'suv';

  // Trucks
  if (combined.includes('truck') || combined.includes('f-150') || combined.includes('silverado') || combined.includes('ram')) return 'truck';
  if (combined.includes('tundra') || combined.includes('tacoma') || combined.includes('frontier')) return 'truck';

  // Sports cars
  if (combined.includes('porsche') || combined.includes('corvette') || combined.includes('mustang')) return 'sports';
  if (combined.includes('camaro') || combined.includes('911') || combined.includes('gt')) return 'sports';

  // Minivans
  if (combined.includes('odyssey') || combined.includes('sienna') || combined.includes('pacifica')) return 'minivan';
  if (combined.includes('caravan') || combined.includes('minivan')) return 'minivan';

  // Default to sedan
  return 'sedan';
}

export function VehicleAvatar({ type, make, model, isElectric, size = 'md', className = '' }: VehicleAvatarProps) {
  const vehicleType = getVehicleType(make, model, type, isElectric);
  const style = vehicleStyles[vehicleType] || vehicleStyles.default;
  const s = sizes[size];

  const Icon = vehicleType === 'truck' ? Truck :
               vehicleType === 'motorcycle' ? Bike :
               Car;

  const showElectricBadge = vehicleType === 'electric' || isElectric;

  return (
    <div className={`relative flex-shrink-0 ${className}`}>
      {/* Main container */}
      <div className={`${s.container} ${style.bg} rounded-2xl flex items-center justify-center`}>
        <Icon className={`${s.icon} ${style.icon}`} />
      </div>

      {/* Electric badge */}
      {showElectricBadge && (
        <div className={`absolute -top-1 -right-1 ${s.badge} bg-emerald-500 rounded-full flex items-center justify-center ring-2 ring-white`}>
          <Zap className={`${s.badgeIcon} text-white fill-current`} />
        </div>
      )}
    </div>
  );
}

export default VehicleAvatar;

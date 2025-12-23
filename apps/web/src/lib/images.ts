// Premium Unsplash images for demo
export const images = {
  properties: {
    greenwich: 'https://images.unsplash.com/photo-1564013799919-ab600027ffc6?w=800&q=80',
    malibu: 'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=800&q=80',
    beverly: 'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=800&q=80',
    scarsdale: 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=800&q=80',
  },

  avatars: {
    sarah: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200&q=80',
    mike: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&q=80',
    bob: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=200&q=80',
    alice: 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=200&q=80',
    carlos: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200&q=80',
  },

  travel: {
    aspen: 'https://images.unsplash.com/photo-1605540436563-5bca919ae766?w=800&q=80',
    turks: 'https://images.unsplash.com/photo-1548574505-5e239809ee19?w=800&q=80',
    sf: 'https://images.unsplash.com/photo-1501594907352-04cda38ebc29?w=800&q=80',
    napa: 'https://images.unsplash.com/photo-1474722883778-792e7990302f?w=800&q=80',
  },

  services: {
    plumbing: 'https://images.unsplash.com/photo-1585704032915-c3400ca199e7?w=400&q=80',
    electrical: 'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?w=400&q=80',
    landscaping: 'https://images.unsplash.com/photo-1558904541-efa843a96f01?w=400&q=80',
    roofing: 'https://images.unsplash.com/photo-1632759145351-1d592919f522?w=400&q=80',
  },
};

export function getAvatarUrl(name: string): string | undefined {
  const map: Record<string, string> = {
    'sarah harrison': images.avatars.sarah,
    'sarah': images.avatars.sarah,
    'mike rodriguez': images.avatars.mike,
    'mike': images.avatars.mike,
    'bob morrison': images.avatars.bob,
    'bob smith': images.avatars.bob,
    'bob': images.avatars.bob,
    'alice morrison': images.avatars.alice,
    'alice johnson': images.avatars.alice,
    'alice': images.avatars.alice,
    'carlos reyes': images.avatars.carlos,
    'carlos': images.avatars.carlos,
  };
  return map[name.toLowerCase()];
}

export function getInitials(name: string): string {
  return name
    .split(' ')
    .map((n) => n[0])
    .join('')
    .toUpperCase()
    .slice(0, 2);
}

export function getPropertyImage(name: string): string {
  const lower = name.toLowerCase();
  if (lower.includes('malibu')) return images.properties.malibu;
  if (lower.includes('beverly')) return images.properties.beverly;
  if (lower.includes('scarsdale') || lower.includes('johnson'))
    return images.properties.scarsdale;
  return images.properties.greenwich;
}

export function getDestinationImage(dest: string): string {
  const lower = dest.toLowerCase();
  if (lower.includes('aspen') || lower.includes('colorado'))
    return images.travel.aspen;
  if (lower.includes('turks') || lower.includes('caicos'))
    return images.travel.turks;
  if (lower.includes('francisco') || lower.includes('sf'))
    return images.travel.sf;
  if (lower.includes('napa')) return images.travel.napa;
  return images.travel.aspen;
}

export function getServiceImage(service: string): string {
  const lower = service.toLowerCase();
  if (lower.includes('plumb') || lower.includes('pipe') || lower.includes('water'))
    return images.services.plumbing;
  if (lower.includes('electric') || lower.includes('wiring') || lower.includes('outlet'))
    return images.services.electrical;
  if (lower.includes('landscape') || lower.includes('garden') || lower.includes('lawn'))
    return images.services.landscaping;
  if (lower.includes('roof') || lower.includes('shingle') || lower.includes('gutter'))
    return images.services.roofing;
  return images.services.plumbing;
}

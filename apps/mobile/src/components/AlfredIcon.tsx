import React from 'react';
import Svg, { Path, Rect, Circle } from 'react-native-svg';

// =============================================================================
// ALFRED TAB ICON (Monochrome - uses currentColor pattern)
// =============================================================================

interface AlfredTabIconProps {
  size?: number;
  color?: string;
}

export function AlfredTabIcon({ size = 24, color = '#000000' }: AlfredTabIconProps) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24" fill="none">
      {/* A-frame house */}
      <Path d="M12 3L21 20H17L12 10L7 20H3L12 3Z" fill={color} />

      {/* Inner warmth triangle - slightly lighter/transparent */}
      <Path d="M12 11L16 19H8L12 11Z" fill={color} opacity={0.3} />

      {/* Sparkle */}
      <Path d="M20 4L20.8 6.2L23 7L20.8 7.8L20 10L19.2 7.8L17 7L19.2 6.2L20 4Z" fill={color} />
    </Svg>
  );
}

// =============================================================================
// ALFRED LOGO (Full Color - for avatars and branding)
// =============================================================================

interface AlfredLogoProps {
  size?: number;
  variant?: 'light' | 'dark'; // 'light' = for light backgrounds, 'dark' = for dark backgrounds
}

export function AlfredLogo({ size = 40, variant = 'light' }: AlfredLogoProps) {
  const houseColor = variant === 'light' ? '#6200EA' : '#ffffff';
  const accentColor = variant === 'light' ? '#B388FF' : '#D1B3FF';
  const cutoutColor = variant === 'light' ? '#6200EA' : '#ffffff';

  // Scale factor from 120x120 viewBox
  const scale = size / 120;

  return (
    <Svg width={size} height={size} viewBox="0 0 120 120" fill="none">
      {/* A-frame house */}
      <Path d="M60 12L99 96H84L60 45L36 96H21L60 12Z" fill={houseColor} />

      {/* Inner warmth - Purple accent */}
      <Path d="M60 51L77 89H43L60 51Z" fill={accentColor} />

      {/* Window cutout */}
      <Rect x={54} y={63} width={12} height={9} rx={1.5} fill={cutoutColor} />

      {/* Door cutout */}
      <Rect x={56} y={75} width={8} height={14} rx={1.5} fill={cutoutColor} />

      {/* Sparkles - Purple accent */}
      {/* Large sparkle top right */}
      <Path d="M93 27L95.5 33.5L102 36L95.5 38.5L93 45L90.5 38.5L84 36L90.5 33.5L93 27Z" fill={accentColor} />

      {/* Medium sparkle top left */}
      <Path
        d="M30 33L31.8 38L37 39.5L31.8 41L30 46L28.2 41L23 39.5L28.2 38L30 33Z"
        fill={accentColor}
        opacity={variant === 'light' ? 0.8 : 0.9}
      />

      {/* Small sparkle right */}
      <Path
        d="M103 54L104.2 57.5L108 58.5L104.2 59.5L103 63L101.8 59.5L98 58.5L101.8 57.5L103 54Z"
        fill={accentColor}
        opacity={variant === 'light' ? 0.6 : 0.7}
      />

      {/* Small sparkle left */}
      <Path
        d="M19 60L20.2 63.5L24 64.5L20.2 65.5L19 69L17.8 65.5L14 64.5L17.8 63.5L19 60Z"
        fill={accentColor}
        opacity={variant === 'light' ? 0.6 : 0.7}
      />

      {/* Tiny accent dots */}
      <Circle cx={99} cy={42} r={1.5} fill={accentColor} opacity={variant === 'light' ? 0.4 : 0.5} />
      <Circle cx={23} cy={51} r={1.5} fill={accentColor} opacity={variant === 'light' ? 0.4 : 0.5} />
    </Svg>
  );
}


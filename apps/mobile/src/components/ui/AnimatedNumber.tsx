import React, { useEffect, useState, useRef } from 'react';
import { Text, StyleSheet, TextStyle } from 'react-native';
import { colors, typography } from '../../lib/theme';

interface AnimatedNumberProps {
  value: number;
  duration?: number;
  style?: TextStyle;
  prefix?: string;
  suffix?: string;
  decimals?: number;
}

/**
 * Animated number counter using JS-based animation
 * Simplified version without react-native-reanimated to avoid native module conflicts
 */
export function AnimatedNumber({
  value,
  duration = 1000,
  style,
  prefix = '',
  suffix = '',
  decimals = 0,
}: AnimatedNumberProps) {
  const [displayValue, setDisplayValue] = useState(0);
  const startValue = useRef(0);
  const startTime = useRef(0);
  const rafRef = useRef<number | null>(null);

  useEffect(() => {
    startValue.current = displayValue;
    startTime.current = Date.now();

    const animate = () => {
      const elapsed = Date.now() - startTime.current;
      const progress = Math.min(elapsed / duration, 1);

      // Ease out cubic
      const eased = 1 - Math.pow(1 - progress, 3);

      const current = startValue.current + (value - startValue.current) * eased;
      setDisplayValue(current);

      if (progress < 1) {
        rafRef.current = requestAnimationFrame(animate);
      }
    };

    rafRef.current = requestAnimationFrame(animate);

    return () => {
      if (rafRef.current) {
        cancelAnimationFrame(rafRef.current);
      }
    };
  }, [value, duration]);

  return (
    <Text style={[styles.text, style]}>
      {prefix}{displayValue.toFixed(decimals)}{suffix}
    </Text>
  );
}

// Specialized component for home health score
interface HomeHealthScoreProps {
  score: number;
  size?: 'sm' | 'md' | 'lg';
}

export function HomeHealthScore({ score, size = 'lg' }: HomeHealthScoreProps) {
  const getColor = () => {
    if (score >= 90) return colors.status.success;
    if (score >= 70) return colors.status.warning;
    return colors.status.error;
  };

  const getFontSize = () => {
    switch (size) {
      case 'sm': return 24;
      case 'md': return 36;
      case 'lg': return 56;
    }
  };

  const scoreStyle: TextStyle = {
    fontSize: getFontSize(),
    fontWeight: '700',
    color: getColor(),
  };

  return (
    <AnimatedNumber
      value={score}
      style={scoreStyle}
      duration={1500}
    />
  );
}

const styles = StyleSheet.create({
  text: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.bold as TextStyle['fontWeight'],
    color: colors.text.primary,
  },
});

import React, { useEffect, useState } from 'react';
import { Text, StyleSheet, TextStyle, TextInput } from 'react-native';
import Animated, {
  useSharedValue,
  useAnimatedProps,
  withTiming,
  Easing,
  runOnJS,
} from 'react-native-reanimated';
import { colors, typography } from '../../lib/theme';

const AnimatedTextInput = Animated.createAnimatedComponent(TextInput);

interface AnimatedNumberProps {
  value: number;
  duration?: number;
  style?: TextStyle;
  prefix?: string;
  suffix?: string;
  decimals?: number;
}

export function AnimatedNumber({
  value,
  duration = 1000,
  style,
  prefix = '',
  suffix = '',
  decimals = 0,
}: AnimatedNumberProps) {
  const [displayText, setDisplayText] = useState(`${prefix}${value.toFixed(decimals)}${suffix}`);
  const animatedValue = useSharedValue(0);

  const updateText = (val: number) => {
    setDisplayText(`${prefix}${val.toFixed(decimals)}${suffix}`);
  };

  useEffect(() => {
    animatedValue.value = withTiming(value, {
      duration,
      easing: Easing.out(Easing.cubic),
    });
  }, [value, duration]);

  const animatedProps = useAnimatedProps(() => {
    const currentValue = animatedValue.value;
    runOnJS(updateText)(currentValue);
    return {};
  });

  return (
    <AnimatedTextInput
      editable={false}
      value={displayText}
      style={[styles.text, style]}
      animatedProps={animatedProps}
    />
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
    fontWeight: typography.fontWeights.bold,
    color: colors.text.primary,
    padding: 0,
    margin: 0,
  },
});

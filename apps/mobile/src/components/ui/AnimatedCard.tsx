import React from 'react';
import { StyleSheet, ViewStyle, TouchableOpacity, View } from 'react-native';
import Animated, {
  useAnimatedStyle,
  useSharedValue,
  withSpring,
  FadeInUp,
  FadeInDown,
} from 'react-native-reanimated';
import { colors, spacing, borderRadius, shadows } from '../../lib/theme';

const AnimatedTouchable = Animated.createAnimatedComponent(TouchableOpacity);

interface AnimatedCardProps {
  children: React.ReactNode;
  onPress?: () => void;
  style?: ViewStyle;
  delay?: number;
  direction?: 'up' | 'down';
  variant?: 'default' | 'elevated' | 'outlined';
}

export function AnimatedCard({
  children,
  onPress,
  style,
  delay = 0,
  direction = 'up',
  variant = 'default',
}: AnimatedCardProps) {
  const scale = useSharedValue(1);

  const animatedStyle = useAnimatedStyle(() => ({
    transform: [{ scale: scale.value }],
  }));

  const handlePressIn = () => {
    scale.value = withSpring(0.97, { damping: 15, stiffness: 300 });
  };

  const handlePressOut = () => {
    scale.value = withSpring(1, { damping: 15, stiffness: 300 });
  };

  const entering = direction === 'up'
    ? FadeInUp.delay(delay).duration(400).springify()
    : FadeInDown.delay(delay).duration(400).springify();

  const cardStyle = [
    styles.base,
    variant === 'elevated' && styles.elevated,
    variant === 'outlined' && styles.outlined,
    style,
  ];

  if (onPress) {
    return (
      <Animated.View entering={entering}>
        <AnimatedTouchable
          style={[cardStyle, animatedStyle]}
          onPress={onPress}
          onPressIn={handlePressIn}
          onPressOut={handlePressOut}
          activeOpacity={1}
        >
          {children}
        </AnimatedTouchable>
      </Animated.View>
    );
  }

  return (
    <Animated.View entering={entering} style={cardStyle}>
      {children}
    </Animated.View>
  );
}

const styles = StyleSheet.create({
  base: {
    backgroundColor: colors.white,
    borderRadius: borderRadius.xl,
    padding: spacing[4],
    ...shadows.md,
  },
  elevated: {
    ...shadows.lg,
  },
  outlined: {
    borderWidth: 1,
    borderColor: colors.border.default,
    shadowColor: 'transparent',
    shadowOpacity: 0,
    elevation: 0,
  },
});

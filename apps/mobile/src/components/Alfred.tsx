import React from 'react';
import { View, StyleSheet, ViewStyle, Animated } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons } from '@expo/vector-icons';
import { colors, borderRadius } from '../lib/theme';

// =============================================================================
// TYPES
// =============================================================================

interface AlfredAvatarProps {
  size?: 'sm' | 'md' | 'lg' | 'xl';
  style?: ViewStyle;
}

// =============================================================================
// SIZE CONFIG
// =============================================================================

const SIZES = {
  sm: { container: 32, icon: 16 },
  md: { container: 44, icon: 22 },
  lg: { container: 56, icon: 28 },
  xl: { container: 72, icon: 36 },
};

// =============================================================================
// ALFRED AVATAR COMPONENT
// =============================================================================

/**
 * Alfred AI avatar with sparkle icon and gradient background
 */
export function AlfredAvatar({ size = 'md', style }: AlfredAvatarProps) {
  const sizeConfig = SIZES[size];

  return (
    <LinearGradient
      colors={[colors.haven.champagne[400], colors.haven.champagne[600]]}
      start={{ x: 0, y: 0 }}
      end={{ x: 1, y: 1 }}
      style={[
        styles.container,
        {
          width: sizeConfig.container,
          height: sizeConfig.container,
          borderRadius: sizeConfig.container / 2,
        },
        style,
      ]}
    >
      <Ionicons
        name="sparkles"
        size={sizeConfig.icon}
        color={colors.white}
      />
    </LinearGradient>
  );
}

// =============================================================================
// ALFRED TYPING INDICATOR
// =============================================================================

interface TypingIndicatorProps {
  dot1Opacity: Animated.Value;
  dot2Opacity: Animated.Value;
  dot3Opacity: Animated.Value;
}

export function AlfredTypingIndicator({ dot1Opacity, dot2Opacity, dot3Opacity }: TypingIndicatorProps) {
  return (
    <View style={styles.typingContainer}>
      <AlfredAvatar size="sm" />
      <View style={styles.typingBubble}>
        <View style={styles.typingDots}>
          <Animated.View style={[styles.dot, { opacity: dot1Opacity }]} />
          <Animated.View style={[styles.dot, { opacity: dot2Opacity }]} />
          <Animated.View style={[styles.dot, { opacity: dot3Opacity }]} />
        </View>
      </View>
    </View>
  );
}

// =============================================================================
// STYLES
// =============================================================================

const styles = StyleSheet.create({
  container: {
    alignItems: 'center',
    justifyContent: 'center',
  },
  typingContainer: {
    flexDirection: 'row',
    alignItems: 'flex-end',
    marginBottom: 12,
  },
  typingBubble: {
    backgroundColor: colors.gray[100],
    paddingHorizontal: 16,
    paddingVertical: 12,
    borderRadius: borderRadius.xl,
    borderBottomLeftRadius: 4,
    marginLeft: 8,
  },
  typingDots: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
  },
  dot: {
    width: 8,
    height: 8,
    borderRadius: 4,
    backgroundColor: colors.gray[400],
  },
});

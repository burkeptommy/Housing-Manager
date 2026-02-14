import React from 'react';
import {
  TouchableOpacity,
  Text,
  StyleSheet,
  ActivityIndicator,
  ViewStyle,
  TextStyle,
  View,
} from 'react-native';
import { colors, typography, spacing, borderRadius, shadows, touchTarget } from '../../lib/theme';

// Lazy import haptics to prevent crash if native module isn't available
let Haptics: typeof import('expo-haptics') | null = null;
try {
  Haptics = require('expo-haptics');
} catch {
  console.log('expo-haptics not available');
}

type ButtonVariant = 'primary' | 'secondary' | 'outline' | 'ghost' | 'destructive' | 'coral' | 'coralOutline';
type ButtonSize = 'sm' | 'md' | 'lg';

interface ButtonProps {
  title: string;
  onPress: () => void;
  variant?: ButtonVariant;
  size?: ButtonSize;
  disabled?: boolean;
  loading?: boolean;
  fullWidth?: boolean;
  icon?: React.ReactNode;
  iconPosition?: 'left' | 'right';
  style?: ViewStyle;
  textStyle?: TextStyle;
  haptic?: boolean;
}

export function Button({
  title,
  onPress,
  variant = 'primary',
  size = 'md',
  disabled = false,
  loading = false,
  fullWidth = false,
  icon,
  iconPosition = 'left',
  style,
  textStyle,
  haptic = true,
}: ButtonProps) {
  const handlePress = () => {
    if (haptic && Haptics) {
      try {
        Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
      } catch {
        // Ignore haptic errors
      }
    }
    onPress();
  };

  const isDisabled = disabled || loading;

  return (
    <TouchableOpacity
      style={[
        styles.base,
        styles[variant],
        styles[`size_${size}`],
        fullWidth && styles.fullWidth,
        isDisabled && styles.disabled,
        style,
      ]}
      onPress={handlePress}
      disabled={isDisabled}
      activeOpacity={0.8}
    >
      {loading ? (
        <ActivityIndicator
          color={variant === 'primary' || variant === 'coral' || variant === 'destructive' ? colors.white : colors.haven.purple[900]}
          size="small"
        />
      ) : (
        <View style={styles.content}>
          {icon && iconPosition === 'left' && <View style={styles.iconLeft}>{icon}</View>}
          <Text
            style={[
              styles.text,
              styles[`text_${variant}`],
              styles[`text_${size}`],
              textStyle,
            ]}
          >
            {title}
          </Text>
          {icon && iconPosition === 'right' && <View style={styles.iconRight}>{icon}</View>}
        </View>
      )}
    </TouchableOpacity>
  );
}

const styles = StyleSheet.create({
  base: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: borderRadius.lg,
    minHeight: touchTarget.minimum,
  },
  content: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
  },
  iconLeft: {
    marginRight: spacing[2],
  },
  iconRight: {
    marginLeft: spacing[2],
  },
  fullWidth: {
    width: '100%',
  },
  disabled: {
    opacity: 0.5,
  },

  // Variants
  primary: {
    backgroundColor: colors.haven.purple[900],
    ...shadows.sm,
  },
  secondary: {
    backgroundColor: colors.haven.purple[500],
    ...shadows.sm,
  },
  outline: {
    backgroundColor: 'transparent',
    borderWidth: 1.5,
    borderColor: colors.haven.purple[900],
  },
  ghost: {
    backgroundColor: 'transparent',
  },
  destructive: {
    backgroundColor: colors.status.error,
    ...shadows.sm,
  },
  coral: {
    backgroundColor: colors.haven.coral[500],
    ...shadows.sm,
  },
  coralOutline: {
    backgroundColor: 'transparent',
    borderWidth: 1.5,
    borderColor: colors.haven.coral[500],
  },

  // Sizes
  size_sm: {
    paddingVertical: spacing[2],
    paddingHorizontal: spacing[3],
    minHeight: 36,
  },
  size_md: {
    paddingVertical: spacing[3],
    paddingHorizontal: spacing[4],
    minHeight: touchTarget.minimum,
  },
  size_lg: {
    paddingVertical: spacing[4],
    paddingHorizontal: spacing[6],
    minHeight: 52,
  },

  // Text base
  text: {
    fontFamily: 'Nunito_600SemiBold',
  },

  // Text variants
  text_primary: {
    color: colors.white,
  },
  text_secondary: {
    color: colors.haven.purple[900],
  },
  text_outline: {
    color: colors.haven.purple[900],
  },
  text_ghost: {
    color: colors.haven.purple[900],
  },
  text_destructive: {
    color: colors.white,
  },
  text_coral: {
    color: colors.white,
  },
  text_coralOutline: {
    color: colors.haven.coral[600],
  },

  // Text sizes
  text_sm: {
    fontSize: typography.fontSizes.sm,
  },
  text_md: {
    fontSize: typography.fontSizes.base,
  },
  text_lg: {
    fontSize: typography.fontSizes.lg,
  },
});

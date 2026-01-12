import React, { useState } from 'react';
import {
  View,
  TextInput,
  Text,
  StyleSheet,
  TextInputProps,
  TouchableOpacity,
  ViewStyle,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { colors, typography, spacing, borderRadius } from '../../lib/theme';

interface InputProps extends Omit<TextInputProps, 'style'> {
  label?: string;
  error?: string;
  hint?: string;
  leftIcon?: keyof typeof Ionicons.glyphMap;
  rightIcon?: keyof typeof Ionicons.glyphMap;
  onRightIconPress?: () => void;
  containerStyle?: ViewStyle;
}

export function Input({
  label,
  error,
  hint,
  leftIcon,
  rightIcon,
  onRightIconPress,
  containerStyle,
  secureTextEntry,
  ...props
}: InputProps) {
  const [isFocused, setIsFocused] = useState(false);
  const [isPasswordVisible, setIsPasswordVisible] = useState(false);

  const showPasswordToggle = secureTextEntry && !rightIcon;
  const actualSecureEntry = secureTextEntry && !isPasswordVisible;

  return (
    <View style={[styles.container, containerStyle]}>
      {label && <Text style={styles.label}>{label}</Text>}

      <View
        style={[
          styles.inputContainer,
          isFocused && styles.inputFocused,
          error && styles.inputError,
        ]}
      >
        {leftIcon && (
          <Ionicons
            name={leftIcon}
            size={20}
            color={colors.haven.navy[400]}
            style={styles.leftIcon}
          />
        )}

        <TextInput
          style={[
            styles.input,
            leftIcon && styles.inputWithLeftIcon,
            (rightIcon || showPasswordToggle) && styles.inputWithRightIcon,
          ]}
          placeholderTextColor={colors.haven.navy[400]}
          onFocus={() => setIsFocused(true)}
          onBlur={() => setIsFocused(false)}
          secureTextEntry={actualSecureEntry}
          {...props}
        />

        {showPasswordToggle && (
          <TouchableOpacity
            onPress={() => setIsPasswordVisible(!isPasswordVisible)}
            style={styles.rightIconContainer}
          >
            <Ionicons
              name={isPasswordVisible ? 'eye-off-outline' : 'eye-outline'}
              size={20}
              color={colors.haven.navy[400]}
            />
          </TouchableOpacity>
        )}

        {rightIcon && onRightIconPress && (
          <TouchableOpacity onPress={onRightIconPress} style={styles.rightIconContainer}>
            <Ionicons name={rightIcon} size={20} color={colors.haven.navy[400]} />
          </TouchableOpacity>
        )}
      </View>

      {hint && !error && <Text style={styles.hint}>{hint}</Text>}
      {error && <Text style={styles.error}>{error}</Text>}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    marginBottom: spacing[4],
  },
  label: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.primary,
    marginBottom: spacing[1.5],
  },
  inputContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.background.tertiary,
    borderWidth: 1,
    borderColor: colors.border.default,
    borderRadius: borderRadius.lg,
    minHeight: 48,
  },
  inputFocused: {
    borderColor: colors.haven.champagne[500],
    borderWidth: 2,
    backgroundColor: colors.white,
  },
  inputError: {
    borderColor: colors.status.error,
  },
  input: {
    flex: 1,
    fontSize: typography.fontSizes.base,
    color: colors.text.primary,
    paddingHorizontal: spacing[3],
    paddingVertical: spacing[3],
  },
  inputWithLeftIcon: {
    paddingLeft: 0,
  },
  inputWithRightIcon: {
    paddingRight: 0,
  },
  leftIcon: {
    marginLeft: spacing[3],
  },
  rightIconContainer: {
    padding: spacing[3],
  },
  hint: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
    marginTop: spacing[1],
  },
  error: {
    fontSize: typography.fontSizes.xs,
    color: colors.status.error,
    marginTop: spacing[1],
  },
});

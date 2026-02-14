import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  KeyboardAvoidingView,
  Platform,
  ScrollView,
} from 'react-native';
import { useRouter } from 'expo-router';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { useAuth } from '../../src/contexts/auth-context';
import { Button, Input } from '../../src/components';
import { colors, typography, spacing, borderRadius } from '../../src/lib/theme';

export default function ForgotPasswordScreen() {
  const router = useRouter();
  const { resetPassword } = useAuth();

  const [email, setEmail] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState(false);

  const handleResetPassword = async () => {
    if (!email.trim()) {
      setError('Please enter your email address');
      return;
    }

    setError('');
    setIsLoading(true);

    const result = await resetPassword(email.trim());

    setIsLoading(false);

    if (result.success) {
      setSuccess(true);
    } else {
      setError(result.error || 'Failed to send reset email');
    }
  };

  if (success) {
    return (
      <SafeAreaView style={styles.container} edges={['top', 'bottom']}>
        <View style={styles.successContainer}>
          <View style={styles.successIcon}>
            <Ionicons name="mail" size={48} color={colors.haven.purple[500]} />
          </View>
          <Text style={styles.successTitle}>Check your email</Text>
          <Text style={styles.successText}>
            We've sent password reset instructions to {email}
          </Text>
          <Button
            title="Back to Sign In"
            onPress={() => router.back()}
            fullWidth
            style={styles.backButton}
          />
        </View>
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView style={styles.container} edges={['top', 'bottom']}>
      <KeyboardAvoidingView
        behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
        style={styles.keyboardView}
      >
        <ScrollView
          contentContainerStyle={styles.scrollContent}
          keyboardShouldPersistTaps="handled"
        >
          <View style={styles.header}>
            <Text style={styles.title}>Reset Password</Text>
            <Text style={styles.subtitle}>
              Enter your email and we'll send you instructions to reset your password
            </Text>
          </View>

          {error ? (
            <View style={styles.errorContainer}>
              <Ionicons name="alert-circle" size={20} color={colors.status.error} />
              <Text style={styles.errorText}>{error}</Text>
            </View>
          ) : null}

          <Input
            label="Email"
            placeholder="you@example.com"
            value={email}
            onChangeText={setEmail}
            keyboardType="email-address"
            autoCapitalize="none"
            autoComplete="email"
            leftIcon="mail-outline"
          />

          <Button
            title={isLoading ? 'Sending...' : 'Send Reset Link'}
            onPress={handleResetPassword}
            loading={isLoading}
            fullWidth
          />

          <Button
            title="Back to Sign In"
            onPress={() => router.back()}
            variant="ghost"
            fullWidth
            style={styles.backButton}
          />
        </ScrollView>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.white,
  },
  keyboardView: {
    flex: 1,
  },
  scrollContent: {
    flexGrow: 1,
    padding: spacing[5],
    justifyContent: 'center',
  },
  header: {
    marginBottom: spacing[6],
  },
  title: {
    fontSize: typography.fontSizes['2xl'],
    fontWeight: typography.fontWeights.bold,
    color: colors.text.primary,
    marginBottom: spacing[2],
  },
  subtitle: {
    fontSize: typography.fontSizes.base,
    color: colors.text.secondary,
    lineHeight: 24,
  },
  errorContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.status.errorLight,
    padding: spacing[3],
    borderRadius: borderRadius.lg,
    marginBottom: spacing[4],
  },
  errorText: {
    flex: 1,
    marginLeft: spacing[2],
    fontSize: typography.fontSizes.sm,
    color: colors.status.error,
  },
  backButton: {
    marginTop: spacing[3],
  },
  successContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: spacing[5],
  },
  successIcon: {
    width: 96,
    height: 96,
    borderRadius: 48,
    backgroundColor: colors.haven.purple[100],
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: spacing[4],
  },
  successTitle: {
    fontSize: typography.fontSizes.xl,
    fontWeight: typography.fontWeights.bold,
    color: colors.text.primary,
    marginBottom: spacing[2],
  },
  successText: {
    fontSize: typography.fontSizes.base,
    color: colors.text.secondary,
    textAlign: 'center',
    marginBottom: spacing[6],
  },
});

import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  KeyboardAvoidingView,
  Platform,
  ScrollView,
  Image,
  Animated,
  StatusBar,
} from 'react-native';
import { useRouter, Link } from 'expo-router';
import { LinearGradient } from 'expo-linear-gradient';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import * as AppleAuthentication from 'expo-apple-authentication';
import { Ionicons } from '@expo/vector-icons';
import { useAuth } from '../../src/contexts/auth-context';
import { Button, Input, LoadingSpinner } from '../../src/components';
import { colors, typography, spacing, borderRadius, shadows } from '../../src/lib/theme';
import { getBiometricName } from '../../src/lib/biometric-auth';
import { GoogleSignInButtonIfAvailable } from '../../src/components/GoogleSignInButton';

export default function LoginScreen() {
  const router = useRouter();
  const insets = useSafeAreaInsets();
  const {
    login,
    loginWithApple,
    loginWithBiometric,
    isLoading,
    isAppleSignInAvailable,
    biometricStatus,
  } = useAuth();

  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [fadeAnim] = useState(new Animated.Value(0));
  const [isGoogleLoading, setIsGoogleLoading] = useState(false);

  // Fade in animation
  useEffect(() => {
    Animated.timing(fadeAnim, {
      toValue: 1,
      duration: 600,
      useNativeDriver: true,
    }).start();
  }, [fadeAnim]);

  // Auto-prompt biometric if available and enabled
  useEffect(() => {
    if (biometricStatus?.isEnabled && biometricStatus?.isAvailable) {
      handleBiometricLogin();
    }
  }, [biometricStatus]);

  const handleEmailLogin = async () => {
    if (!email.trim() || !password.trim()) {
      setError('Please enter your email and password');
      return;
    }

    setError('');
    const result = await login(email.trim(), password);

    if (!result.success) {
      setError(result.error || 'Failed to sign in');
    }
  };

  const handleAppleLogin = async () => {
    setError('');
    const result = await loginWithApple();

    if (!result.success && result.error !== 'Sign in was cancelled') {
      setError(result.error || 'Apple Sign In failed');
    }
  };

  const handleGoogleError = (errorMsg: string) => {
    setError(errorMsg);
  };

  const handleBiometricLogin = async () => {
    setError('');
    const result = await loginWithBiometric();

    if (!result.success && result.error !== 'Authentication failed') {
      if (!result.error?.includes('cancel')) {
        setError(result.error || 'Biometric login failed');
      }
    }
  };

  const handleForgotPassword = () => {
    router.push('/(auth)/forgot-password');
  };

  if ((isLoading || isGoogleLoading) && !email) {
    return <LoadingSpinner fullScreen message="Signing in..." />;
  }

  return (
    <LinearGradient
      colors={[colors.haven.purple[950], '#0d2137', colors.haven.purple[900]]}
      start={{ x: 0, y: 0 }}
      end={{ x: 1, y: 1 }}
      style={styles.gradient}
    >
      <StatusBar barStyle="light-content" backgroundColor={colors.haven.purple[950]} />
      <KeyboardAvoidingView
        behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
        style={styles.keyboardView}
      >
        <ScrollView
          contentContainerStyle={[styles.scrollContent, { paddingTop: insets.top + spacing[6] }]}
          keyboardShouldPersistTaps="handled"
          showsVerticalScrollIndicator={false}
        >
          <Animated.View style={[styles.content, { opacity: fadeAnim }]}>
            {/* Logo Section */}
            <View style={styles.logoSection}>
              <View style={styles.logoContainer}>
                <Image
                  source={require('../../assets/icon.png')}
                  style={styles.logo}
                  resizeMode="contain"
                />
              </View>
              <Text style={styles.brandName}>HAVEN</Text>
              <Text style={styles.tagline}>Home management, simplified</Text>
            </View>

            {/* Card Container */}
            <View style={styles.card}>
              <Text style={styles.welcomeTitle}>Welcome back</Text>
              <Text style={styles.welcomeSubtitle}>Sign in to manage your home</Text>

              {/* Error Message */}
              {error ? (
                <View style={styles.errorContainer}>
                  <Ionicons name="alert-circle" size={18} color={colors.status.error} />
                  <Text style={styles.errorText}>{error}</Text>
                </View>
              ) : null}

              {/* Apple Sign In - Primary */}
              {isAppleSignInAvailable && (
                <AppleAuthentication.AppleAuthenticationButton
                  buttonType={AppleAuthentication.AppleAuthenticationButtonType.SIGN_IN}
                  buttonStyle={AppleAuthentication.AppleAuthenticationButtonStyle.BLACK}
                  cornerRadius={borderRadius.xl}
                  style={styles.appleButton}
                  onPress={handleAppleLogin}
                />
              )}

              {/* Google Sign In */}
              <GoogleSignInButtonIfAvailable
                onError={handleGoogleError}
                onLoadingChange={setIsGoogleLoading}
              />

              {/* Biometric */}
              {biometricStatus?.isAvailable && biometricStatus?.isEnabled && (
                <TouchableOpacity style={styles.biometricButton} onPress={handleBiometricLogin}>
                  <Ionicons
                    name={biometricStatus.biometricType === 'facial' ? 'scan' : 'finger-print'}
                    size={22}
                    color={colors.haven.purple[500]}
                  />
                  <Text style={styles.biometricButtonText}>
                    {getBiometricName(biometricStatus.biometricType)}
                  </Text>
                </TouchableOpacity>
              )}

              {/* Divider */}
              <View style={styles.divider}>
                <View style={styles.dividerLine} />
                <Text style={styles.dividerText}>or</Text>
                <View style={styles.dividerLine} />
              </View>

              {/* Email/Password Form */}
              <View style={styles.form}>
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

                <Input
                  label="Password"
                  placeholder="Enter your password"
                  value={password}
                  onChangeText={setPassword}
                  secureTextEntry
                  autoCapitalize="none"
                  autoComplete="password"
                  leftIcon="lock-closed-outline"
                />

                <TouchableOpacity style={styles.forgotPassword} onPress={handleForgotPassword}>
                  <Text style={styles.forgotPasswordText}>Forgot password?</Text>
                </TouchableOpacity>

                <Button
                  title={isLoading ? 'Signing in...' : 'Sign In'}
                  onPress={handleEmailLogin}
                  loading={isLoading}
                  fullWidth
                  style={styles.signInButton}
                />
              </View>
            </View>

            {/* Sign Up Link */}
            <View style={styles.signUpContainer}>
              <Text style={styles.signUpText}>Don't have an account? </Text>
              <Link href="/(auth)/register" asChild>
                <TouchableOpacity>
                  <Text style={styles.signUpLink}>Sign up</Text>
                </TouchableOpacity>
              </Link>
            </View>

            {/* Demo Credentials (Dev only) */}
            {__DEV__ && (
              <View style={styles.devSection}>
                <TouchableOpacity
                  style={styles.devButton}
                  onPress={() => {
                    setEmail('bob@example.com');
                    setPassword('Bob123!');
                  }}
                >
                  <Text style={styles.devButtonText}>Fill Demo Login</Text>
                </TouchableOpacity>
              </View>
            )}
          </Animated.View>
        </ScrollView>
      </KeyboardAvoidingView>
    </LinearGradient>
  );
}

const styles = StyleSheet.create({
  gradient: {
    flex: 1,
  },
  keyboardView: {
    flex: 1,
  },
  scrollContent: {
    flexGrow: 1,
    justifyContent: 'center',
    padding: spacing[5],
    paddingTop: spacing[10],
    paddingBottom: spacing[8],
  },
  content: {
    flex: 1,
    justifyContent: 'center',
  },
  logoSection: {
    alignItems: 'center',
    marginBottom: spacing[6],
  },
  logoContainer: {
    width: 88,
    height: 88,
    borderRadius: borderRadius['2xl'],
    backgroundColor: 'rgba(255,255,255,0.1)',
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: spacing[3],
    ...shadows.lg,
  },
  logo: {
    width: 64,
    height: 64,
  },
  brandName: {
    fontSize: 28,
    fontWeight: '300',
    letterSpacing: 8,
    color: colors.white,
    marginBottom: spacing[1],
  },
  tagline: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.purple[300],
    letterSpacing: 0.5,
  },
  card: {
    backgroundColor: colors.white,
    borderRadius: borderRadius['2xl'],
    padding: spacing[6],
    ...shadows.xl,
  },
  welcomeTitle: {
    fontSize: typography.fontSizes['2xl'],
    fontWeight: typography.fontWeights.bold,
    color: colors.haven.purple[900],
    textAlign: 'center',
    marginBottom: spacing[1],
  },
  welcomeSubtitle: {
    fontSize: typography.fontSizes.base,
    color: colors.text.secondary,
    textAlign: 'center',
    marginBottom: spacing[5],
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
  appleButton: {
    width: '100%',
    height: 52,
    marginBottom: spacing[3],
  },
  googleButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: colors.white,
    padding: spacing[3],
    borderRadius: borderRadius.xl,
    borderWidth: 1.5,
    borderColor: colors.border.default,
    gap: spacing[2],
    height: 52,
    marginBottom: spacing[3],
  },
  googleLogo: {
    width: 20,
    height: 20,
  },
  googleButtonText: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.primary,
  },
  biometricButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: colors.haven.purple[50],
    padding: spacing[3],
    borderRadius: borderRadius.xl,
    gap: spacing[2],
    height: 52,
    borderWidth: 1,
    borderColor: colors.haven.purple[200],
  },
  biometricButtonText: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.medium,
    color: colors.haven.purple[600],
  },
  divider: {
    flexDirection: 'row',
    alignItems: 'center',
    marginVertical: spacing[5],
  },
  dividerLine: {
    flex: 1,
    height: 1,
    backgroundColor: colors.border.default,
  },
  dividerText: {
    marginHorizontal: spacing[3],
    fontSize: typography.fontSizes.sm,
    color: colors.text.tertiary,
    textTransform: 'uppercase',
    letterSpacing: 1,
  },
  form: {
    gap: spacing[1],
  },
  forgotPassword: {
    alignSelf: 'flex-end',
    marginBottom: spacing[4],
    marginTop: spacing[1],
  },
  forgotPasswordText: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.purple[600],
    fontWeight: typography.fontWeights.medium,
  },
  signInButton: {
    marginTop: spacing[2],
    height: 52,
    borderRadius: borderRadius.xl,
  },
  signUpContainer: {
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center',
    marginTop: spacing[6],
  },
  signUpText: {
    fontSize: typography.fontSizes.base,
    color: colors.haven.purple[300],
  },
  signUpLink: {
    fontSize: typography.fontSizes.base,
    color: colors.haven.purple[400],
    fontWeight: typography.fontWeights.semibold,
  },
  devSection: {
    marginTop: spacing[6],
    alignItems: 'center',
  },
  devButton: {
    backgroundColor: 'rgba(196, 165, 116, 0.2)',
    paddingHorizontal: spacing[4],
    paddingVertical: spacing[2],
    borderRadius: borderRadius.lg,
    borderWidth: 1,
    borderColor: 'rgba(196, 165, 116, 0.3)',
  },
  devButtonText: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.purple[400],
    fontWeight: typography.fontWeights.medium,
  },
});

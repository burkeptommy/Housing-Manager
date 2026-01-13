import React, { useEffect, useState } from 'react';
import {
  TouchableOpacity,
  Text,
  Image,
  StyleSheet,
  ActivityIndicator,
} from 'react-native';
import { useGoogleAuth, handleGoogleAuthResponse, isGoogleSignInConfigured } from '../lib/google-auth';
import { colors, typography, spacing, borderRadius } from '../lib/theme';

interface Props {
  onError?: (error: string) => void;
  onLoadingChange?: (loading: boolean) => void;
  style?: any;
}

/**
 * Google Sign In Button component
 * Only renders if Google Sign In is properly configured for the platform
 */
export function GoogleSignInButton({ onError, onLoadingChange, style }: Props) {
  const [isLoading, setIsLoading] = useState(false);

  // This hook will only be called if the component renders
  // The component only renders when isGoogleSignInConfigured() is true
  const [request, response, promptAsync] = useGoogleAuth();

  // Handle Google auth response
  useEffect(() => {
    if (response) {
      setIsLoading(true);
      onLoadingChange?.(true);
      handleGoogleAuthResponse(response).then((result) => {
        setIsLoading(false);
        onLoadingChange?.(false);
        if (!result.success && result.error !== 'Sign in was cancelled') {
          onError?.(result.error || 'Google Sign In failed');
        }
      });
    }
  }, [response, onError, onLoadingChange]);

  const handlePress = async () => {
    if (request) {
      await promptAsync();
    } else {
      onError?.('Google Sign In is not available');
    }
  };

  return (
    <TouchableOpacity
      style={[styles.googleButton, style]}
      onPress={handlePress}
      disabled={isLoading || !request}
    >
      {isLoading ? (
        <ActivityIndicator color={colors.text.primary} size="small" />
      ) : (
        <>
          <Image
            source={{
              uri: 'https://developers.google.com/identity/images/g-logo.png',
            }}
            style={styles.googleLogo}
          />
          <Text style={styles.googleButtonText}>Continue with Google</Text>
        </>
      )}
    </TouchableOpacity>
  );
}

/**
 * Wrapper that only renders GoogleSignInButton if configured
 */
export function GoogleSignInButtonIfAvailable(props: Props) {
  if (!isGoogleSignInConfigured()) {
    return null;
  }
  return <GoogleSignInButton {...props} />;
}

const styles = StyleSheet.create({
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
});

export default GoogleSignInButtonIfAvailable;

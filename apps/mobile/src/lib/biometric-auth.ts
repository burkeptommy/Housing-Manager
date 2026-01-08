import * as LocalAuthentication from 'expo-local-authentication';
import * as SecureStore from 'expo-secure-store';

const BIOMETRIC_ENABLED_KEY = 'haven_biometric_enabled';
const BIOMETRIC_USER_KEY = 'haven_biometric_user_email';

export interface BiometricStatus {
  isAvailable: boolean;
  isEnabled: boolean;
  biometricType: 'fingerprint' | 'facial' | 'iris' | 'none';
}

/**
 * Get the type of biometric authentication available
 */
async function getBiometricType(): Promise<'fingerprint' | 'facial' | 'iris' | 'none'> {
  const types = await LocalAuthentication.supportedAuthenticationTypesAsync();

  if (types.includes(LocalAuthentication.AuthenticationType.FACIAL_RECOGNITION)) {
    return 'facial';
  }
  if (types.includes(LocalAuthentication.AuthenticationType.FINGERPRINT)) {
    return 'fingerprint';
  }
  if (types.includes(LocalAuthentication.AuthenticationType.IRIS)) {
    return 'iris';
  }
  return 'none';
}

/**
 * Check biometric authentication status
 */
export async function getBiometricStatus(): Promise<BiometricStatus> {
  const isAvailable = await LocalAuthentication.hasHardwareAsync();
  const isEnrolled = await LocalAuthentication.isEnrolledAsync();
  const biometricType = await getBiometricType();

  let isEnabled = false;
  try {
    const enabled = await SecureStore.getItemAsync(BIOMETRIC_ENABLED_KEY);
    isEnabled = enabled === 'true';
  } catch {
    // Ignore
  }

  return {
    isAvailable: isAvailable && isEnrolled,
    isEnabled,
    biometricType,
  };
}

/**
 * Enable biometric authentication for a user
 */
export async function enableBiometric(userEmail: string): Promise<boolean> {
  try {
    await SecureStore.setItemAsync(BIOMETRIC_ENABLED_KEY, 'true');
    await SecureStore.setItemAsync(BIOMETRIC_USER_KEY, userEmail);
    return true;
  } catch (error) {
    console.error('Failed to enable biometric:', error);
    return false;
  }
}

/**
 * Disable biometric authentication
 */
export async function disableBiometric(): Promise<boolean> {
  try {
    await SecureStore.deleteItemAsync(BIOMETRIC_ENABLED_KEY);
    await SecureStore.deleteItemAsync(BIOMETRIC_USER_KEY);
    return true;
  } catch (error) {
    console.error('Failed to disable biometric:', error);
    return false;
  }
}

/**
 * Get the email for biometric login
 */
export async function getBiometricUserEmail(): Promise<string | null> {
  try {
    return await SecureStore.getItemAsync(BIOMETRIC_USER_KEY);
  } catch {
    return null;
  }
}

/**
 * Authenticate with biometrics
 */
export async function authenticateWithBiometric(): Promise<{
  success: boolean;
  error?: string;
}> {
  try {
    const status = await getBiometricStatus();

    if (!status.isAvailable) {
      return {
        success: false,
        error: 'Biometric authentication is not available',
      };
    }

    if (!status.isEnabled) {
      return {
        success: false,
        error: 'Biometric authentication is not enabled',
      };
    }

    const promptMessage =
      status.biometricType === 'facial'
        ? 'Use Face ID to sign in to Haven'
        : 'Use Touch ID to sign in to Haven';

    const result = await LocalAuthentication.authenticateAsync({
      promptMessage,
      cancelLabel: 'Cancel',
      disableDeviceFallback: false,
      fallbackLabel: 'Use Password',
    });

    if (result.success) {
      return { success: true };
    }

    return {
      success: false,
      error: result.error || 'Authentication failed',
    };
  } catch (error: any) {
    return {
      success: false,
      error: error.message || 'Biometric authentication failed',
    };
  }
}

/**
 * Get friendly name for biometric type
 */
export function getBiometricName(type: 'fingerprint' | 'facial' | 'iris' | 'none'): string {
  switch (type) {
    case 'facial':
      return 'Face ID';
    case 'fingerprint':
      return 'Touch ID';
    case 'iris':
      return 'Iris Scan';
    default:
      return 'Biometric';
  }
}

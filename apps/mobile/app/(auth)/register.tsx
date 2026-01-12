import { useState, useRef } from 'react';
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  KeyboardAvoidingView,
  Platform,
  ScrollView,
  ActivityIndicator,
  Alert,
} from 'react-native';
import { Link, useRouter } from 'expo-router';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { useAuth } from '../../src/contexts/auth-context';
import { colors, spacing, typography, borderRadius } from '../../src/lib/theme';

// US States for picker
const US_STATES = [
  { value: 'CT', label: 'Connecticut' },
  { value: 'NY', label: 'New York' },
  { value: 'NJ', label: 'New Jersey' },
  { value: 'MA', label: 'Massachusetts' },
  { value: 'PA', label: 'Pennsylvania' },
  // Add more states as needed
];

export default function RegisterScreen() {
  const { registerSimple } = useAuth();
  const router = useRouter();

  // Step tracking
  const [step, setStep] = useState<'account' | 'address'>('account');

  // Account fields
  const [firstName, setFirstName] = useState('');
  const [lastName, setLastName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');

  // Address fields
  const [addressLine1, setAddressLine1] = useState('');
  const [addressLine2, setAddressLine2] = useState('');
  const [city, setCity] = useState('');
  const [state, setState] = useState('CT');
  const [zipCode, setZipCode] = useState('');

  const [isLoading, setIsLoading] = useState(false);
  const [showStatePicker, setShowStatePicker] = useState(false);

  // Refs for input focus
  const lastNameRef = useRef<TextInput>(null);
  const emailRef = useRef<TextInput>(null);
  const passwordRef = useRef<TextInput>(null);
  const confirmPasswordRef = useRef<TextInput>(null);
  const addressLine2Ref = useRef<TextInput>(null);
  const cityRef = useRef<TextInput>(null);
  const zipRef = useRef<TextInput>(null);

  const validateAccountStep = () => {
    if (!firstName.trim() || !lastName.trim() || !email.trim() || !password.trim()) {
      Alert.alert('Error', 'Please fill in all fields');
      return false;
    }

    if (password !== confirmPassword) {
      Alert.alert('Error', 'Passwords do not match');
      return false;
    }

    if (password.length < 8) {
      Alert.alert('Error', 'Password must be at least 8 characters');
      return false;
    }

    // Basic email validation
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email.trim())) {
      Alert.alert('Error', 'Please enter a valid email address');
      return false;
    }

    return true;
  };

  const validateAddressStep = () => {
    if (!addressLine1.trim() || !city.trim() || !state || !zipCode.trim()) {
      Alert.alert('Error', 'Please fill in all required address fields');
      return false;
    }

    // Basic ZIP code validation (5 digits)
    const zipRegex = /^\d{5}(-\d{4})?$/;
    if (!zipRegex.test(zipCode.trim())) {
      Alert.alert('Error', 'Please enter a valid ZIP code');
      return false;
    }

    return true;
  };

  const handleNextStep = () => {
    if (validateAccountStep()) {
      setStep('address');
    }
  };

  const handleRegister = async () => {
    if (!validateAddressStep()) {
      return;
    }

    setIsLoading(true);

    const result = await registerSimple({
      email: email.trim(),
      password,
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      address: {
        addressLine1: addressLine1.trim(),
        addressLine2: addressLine2.trim() || undefined,
        city: city.trim(),
        state,
        zipCode: zipCode.trim(),
      },
    });

    if (!result.success) {
      Alert.alert('Registration Failed', result.error || 'Unable to create account');
    }
    // If successful, auth-context will handle navigation to main app
    setIsLoading(false);
  };

  const renderAccountStep = () => (
    <>
      <View style={styles.row}>
        <View style={[styles.inputContainer, styles.halfWidth]}>
          <Text style={styles.label}>First Name</Text>
          <TextInput
            style={styles.input}
            placeholder="First"
            placeholderTextColor={colors.haven.navy[400]}
            value={firstName}
            onChangeText={setFirstName}
            autoCapitalize="words"
            autoComplete="given-name"
            returnKeyType="next"
            onSubmitEditing={() => lastNameRef.current?.focus()}
          />
        </View>
        <View style={[styles.inputContainer, styles.halfWidth]}>
          <Text style={styles.label}>Last Name</Text>
          <TextInput
            ref={lastNameRef}
            style={styles.input}
            placeholder="Last"
            placeholderTextColor={colors.haven.navy[400]}
            value={lastName}
            onChangeText={setLastName}
            autoCapitalize="words"
            autoComplete="family-name"
            returnKeyType="next"
            onSubmitEditing={() => emailRef.current?.focus()}
          />
        </View>
      </View>

      <View style={styles.inputContainer}>
        <Text style={styles.label}>Email</Text>
        <TextInput
          ref={emailRef}
          style={styles.input}
          placeholder="Enter your email"
          placeholderTextColor={colors.haven.navy[400]}
          value={email}
          onChangeText={setEmail}
          autoCapitalize="none"
          keyboardType="email-address"
          autoComplete="email"
          returnKeyType="next"
          onSubmitEditing={() => passwordRef.current?.focus()}
        />
      </View>

      <View style={styles.inputContainer}>
        <Text style={styles.label}>Password</Text>
        <TextInput
          ref={passwordRef}
          style={styles.input}
          placeholder="Create a password (min 8 chars)"
          placeholderTextColor={colors.haven.navy[400]}
          value={password}
          onChangeText={setPassword}
          secureTextEntry
          autoComplete="new-password"
          returnKeyType="next"
          onSubmitEditing={() => confirmPasswordRef.current?.focus()}
        />
      </View>

      <View style={styles.inputContainer}>
        <Text style={styles.label}>Confirm Password</Text>
        <TextInput
          ref={confirmPasswordRef}
          style={styles.input}
          placeholder="Confirm your password"
          placeholderTextColor={colors.haven.navy[400]}
          value={confirmPassword}
          onChangeText={setConfirmPassword}
          secureTextEntry
          autoComplete="new-password"
          returnKeyType="done"
          onSubmitEditing={handleNextStep}
        />
      </View>

      <TouchableOpacity
        style={styles.button}
        onPress={handleNextStep}
      >
        <Text style={styles.buttonText}>Continue</Text>
        <Ionicons name="arrow-forward" size={20} color={colors.white} />
      </TouchableOpacity>
    </>
  );

  const renderAddressStep = () => (
    <>
      <TouchableOpacity
        style={styles.backButton}
        onPress={() => setStep('account')}
      >
        <Ionicons name="arrow-back" size={20} color={colors.haven.navy[600]} />
        <Text style={styles.backButtonText}>Back</Text>
      </TouchableOpacity>

      <Text style={styles.stepTitle}>Your Home Address</Text>
      <Text style={styles.stepSubtitle}>
        We'll use this to set up your home profile and find local services
      </Text>

      <View style={styles.inputContainer}>
        <Text style={styles.label}>Street Address</Text>
        <TextInput
          style={styles.input}
          placeholder="123 Main Street"
          placeholderTextColor={colors.haven.navy[400]}
          value={addressLine1}
          onChangeText={setAddressLine1}
          autoCapitalize="words"
          autoComplete="street-address"
          returnKeyType="next"
          onSubmitEditing={() => addressLine2Ref.current?.focus()}
        />
      </View>

      <View style={styles.inputContainer}>
        <Text style={styles.label}>Apt/Unit (optional)</Text>
        <TextInput
          ref={addressLine2Ref}
          style={styles.input}
          placeholder="Apt 4B"
          placeholderTextColor={colors.haven.navy[400]}
          value={addressLine2}
          onChangeText={setAddressLine2}
          autoCapitalize="words"
          returnKeyType="next"
          onSubmitEditing={() => cityRef.current?.focus()}
        />
      </View>

      <View style={styles.row}>
        <View style={[styles.inputContainer, { flex: 2 }]}>
          <Text style={styles.label}>City</Text>
          <TextInput
            ref={cityRef}
            style={styles.input}
            placeholder="City"
            placeholderTextColor={colors.haven.navy[400]}
            value={city}
            onChangeText={setCity}
            autoCapitalize="words"
            returnKeyType="next"
            onSubmitEditing={() => zipRef.current?.focus()}
          />
        </View>
        <View style={[styles.inputContainer, { flex: 1, marginLeft: spacing[3] }]}>
          <Text style={styles.label}>State</Text>
          <TouchableOpacity
            style={styles.statePicker}
            onPress={() => setShowStatePicker(!showStatePicker)}
          >
            <Text style={styles.statePickerText}>{state}</Text>
            <Ionicons
              name={showStatePicker ? "chevron-up" : "chevron-down"}
              size={16}
              color={colors.haven.navy[600]}
            />
          </TouchableOpacity>
        </View>
      </View>

      {showStatePicker && (
        <View style={styles.stateList}>
          {US_STATES.map((s) => (
            <TouchableOpacity
              key={s.value}
              style={[
                styles.stateOption,
                state === s.value && styles.stateOptionSelected,
              ]}
              onPress={() => {
                setState(s.value);
                setShowStatePicker(false);
              }}
            >
              <Text
                style={[
                  styles.stateOptionText,
                  state === s.value && styles.stateOptionTextSelected,
                ]}
              >
                {s.label} ({s.value})
              </Text>
            </TouchableOpacity>
          ))}
        </View>
      )}

      <View style={styles.inputContainer}>
        <Text style={styles.label}>ZIP Code</Text>
        <TextInput
          ref={zipRef}
          style={styles.input}
          placeholder="06810"
          placeholderTextColor={colors.haven.navy[400]}
          value={zipCode}
          onChangeText={setZipCode}
          keyboardType="number-pad"
          maxLength={10}
          returnKeyType="done"
          onSubmitEditing={handleRegister}
        />
      </View>

      <TouchableOpacity
        style={[styles.button, isLoading && styles.buttonDisabled]}
        onPress={handleRegister}
        disabled={isLoading}
      >
        {isLoading ? (
          <ActivityIndicator color={colors.white} />
        ) : (
          <>
            <Text style={styles.buttonText}>Create Account</Text>
            <Ionicons name="checkmark-circle" size={20} color={colors.white} />
          </>
        )}
      </TouchableOpacity>
    </>
  );

  return (
    <SafeAreaView style={styles.container}>
      <KeyboardAvoidingView
        behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
        style={styles.keyboardView}
      >
        <ScrollView
          contentContainerStyle={styles.scrollContent}
          keyboardShouldPersistTaps="handled"
        >
          {/* Header */}
          <View style={styles.header}>
            <View style={styles.logoContainer}>
              <View style={styles.logo}>
                <Text style={styles.logoText}>H</Text>
              </View>
            </View>
            <Text style={styles.title}>
              {step === 'account' ? 'Create Account' : 'Almost There!'}
            </Text>
            <Text style={styles.subtitle}>
              {step === 'account'
                ? 'Join Haven Home Manager'
                : 'Step 2 of 2'}
            </Text>

            {/* Progress indicator */}
            <View style={styles.progressContainer}>
              <View style={[styles.progressDot, styles.progressDotActive]} />
              <View style={styles.progressLine} />
              <View style={[
                styles.progressDot,
                step === 'address' && styles.progressDotActive
              ]} />
            </View>
          </View>

          {/* Form */}
          <View style={styles.form}>
            {step === 'account' ? renderAccountStep() : renderAddressStep()}

            <View style={styles.footer}>
              <Text style={styles.footerText}>Already have an account? </Text>
              <Link href="/(auth)/login" asChild>
                <TouchableOpacity>
                  <Text style={styles.linkText}>Sign In</Text>
                </TouchableOpacity>
              </Link>
            </View>
          </View>
        </ScrollView>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.haven.navy[50],
  },
  keyboardView: {
    flex: 1,
  },
  scrollContent: {
    flexGrow: 1,
    justifyContent: 'center',
    padding: spacing[6],
  },
  header: {
    alignItems: 'center',
    marginBottom: spacing[6],
  },
  logoContainer: {
    marginBottom: spacing[4],
  },
  logo: {
    width: 64,
    height: 64,
    borderRadius: borderRadius.lg,
    backgroundColor: colors.haven.navy[900],
    alignItems: 'center',
    justifyContent: 'center',
  },
  logoText: {
    fontSize: 32,
    fontWeight: typography.fontWeights.bold,
    color: colors.haven.champagne[500],
  },
  title: {
    fontSize: typography.fontSizes['2xl'],
    fontWeight: typography.fontWeights.bold,
    color: colors.haven.navy[900],
  },
  subtitle: {
    fontSize: typography.fontSizes.base,
    color: colors.haven.navy[500],
    marginTop: spacing[1],
  },
  progressContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: spacing[4],
  },
  progressDot: {
    width: 10,
    height: 10,
    borderRadius: 5,
    backgroundColor: colors.haven.navy[200],
  },
  progressDotActive: {
    backgroundColor: colors.haven.champagne[500],
  },
  progressLine: {
    width: 40,
    height: 2,
    backgroundColor: colors.haven.navy[200],
    marginHorizontal: spacing[2],
  },
  form: {
    backgroundColor: colors.white,
    borderRadius: borderRadius.xl,
    padding: spacing[6],
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  backButton: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: spacing[4],
  },
  backButtonText: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.navy[600],
    marginLeft: spacing[1],
  },
  stepTitle: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.semibold,
    color: colors.haven.navy[900],
    marginBottom: spacing[1],
  },
  stepSubtitle: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.navy[500],
    marginBottom: spacing[4],
  },
  row: {
    flexDirection: 'row',
    gap: spacing[3],
  },
  halfWidth: {
    flex: 1,
  },
  inputContainer: {
    marginBottom: spacing[4],
  },
  label: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.haven.navy[700],
    marginBottom: spacing[2],
  },
  input: {
    backgroundColor: colors.haven.navy[50],
    borderWidth: 1,
    borderColor: colors.haven.navy[200],
    borderRadius: borderRadius.lg,
    padding: spacing[4],
    fontSize: typography.fontSizes.base,
    color: colors.haven.navy[900],
  },
  statePicker: {
    backgroundColor: colors.haven.navy[50],
    borderWidth: 1,
    borderColor: colors.haven.navy[200],
    borderRadius: borderRadius.lg,
    padding: spacing[4],
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  statePickerText: {
    fontSize: typography.fontSizes.base,
    color: colors.haven.navy[900],
  },
  stateList: {
    backgroundColor: colors.white,
    borderWidth: 1,
    borderColor: colors.haven.navy[200],
    borderRadius: borderRadius.lg,
    marginBottom: spacing[4],
    marginTop: -spacing[2],
  },
  stateOption: {
    padding: spacing[3],
    borderBottomWidth: 1,
    borderBottomColor: colors.haven.navy[100],
  },
  stateOptionSelected: {
    backgroundColor: colors.haven.champagne[50],
  },
  stateOptionText: {
    fontSize: typography.fontSizes.base,
    color: colors.haven.navy[700],
  },
  stateOptionTextSelected: {
    color: colors.haven.champagne[600],
    fontWeight: typography.fontWeights.medium,
  },
  button: {
    backgroundColor: colors.haven.champagne[500],
    borderRadius: borderRadius.lg,
    padding: spacing[4],
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: spacing[2],
    marginTop: spacing[4],
  },
  buttonDisabled: {
    opacity: 0.7,
  },
  buttonText: {
    color: colors.white,
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
  },
  footer: {
    flexDirection: 'row',
    justifyContent: 'center',
    marginTop: spacing[6],
  },
  footerText: {
    color: colors.haven.navy[500],
    fontSize: typography.fontSizes.sm,
  },
  linkText: {
    color: colors.haven.champagne[600],
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
  },
});

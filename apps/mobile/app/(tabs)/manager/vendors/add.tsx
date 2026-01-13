import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TextInput,
  TouchableOpacity,
  Alert,
  KeyboardAvoidingView,
  Platform,
} from 'react-native';
import { useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { useAuth } from '../../../../src/contexts/auth-context';
import { Card, Button, LoadingSpinner, AppHeader } from '../../../../src/components';
import { colors, typography, spacing, borderRadius } from '../../../../src/lib/theme';
import { API_BASE_URL } from '../../../../src/lib/api';
import { getIdToken } from '../../../../src/lib/firebase';

// =============================================================================
// CONSTANTS
// =============================================================================

const VENDOR_CATEGORIES = [
  { id: 'PLUMBER', label: 'Plumber', icon: 'water-outline' },
  { id: 'ELECTRICIAN', label: 'Electrician', icon: 'flash-outline' },
  { id: 'HVAC_SERVICE', label: 'HVAC', icon: 'thermometer-outline' },
  { id: 'LANDSCAPING', label: 'Landscaping', icon: 'leaf-outline' },
  { id: 'CLEANING', label: 'Cleaning', icon: 'sparkles-outline' },
  { id: 'HANDYMAN', label: 'Handyman', icon: 'construct-outline' },
  { id: 'PEST_CONTROL', label: 'Pest Control', icon: 'bug-outline' },
  { id: 'ROOFING', label: 'Roofing', icon: 'home-outline' },
  { id: 'POOL_SERVICE', label: 'Pool Service', icon: 'water-outline' },
  { id: 'APPLIANCE_REPAIR', label: 'Appliance Repair', icon: 'hardware-chip-outline' },
  { id: 'PAINTING', label: 'Painting', icon: 'color-palette-outline' },
  { id: 'FLOORING', label: 'Flooring', icon: 'grid-outline' },
  { id: 'OTHER', label: 'Other', icon: 'ellipsis-horizontal-outline' },
];

// =============================================================================
// COMPONENT
// =============================================================================

export default function AddVendorScreen() {
  const router = useRouter();
  const { householdInfo } = useAuth();

  const [isSubmitting, setIsSubmitting] = useState(false);
  const [category, setCategory] = useState('');
  const [displayName, setDisplayName] = useState('');
  const [contactName, setContactName] = useState('');
  const [phone, setPhone] = useState('');
  const [email, setEmail] = useState('');
  const [websiteUrl, setWebsiteUrl] = useState('');
  const [addressLine1, setAddressLine1] = useState('');
  const [city, setCity] = useState('');
  const [state, setState] = useState('');
  const [postalCode, setPostalCode] = useState('');
  const [serviceDescription, setServiceDescription] = useState('');
  const [notes, setNotes] = useState('');
  const [accountNumber, setAccountNumber] = useState('');

  const handleSubmit = async () => {
    if (!displayName.trim()) {
      Alert.alert('Error', 'Please enter a business name');
      return;
    }
    if (!category) {
      Alert.alert('Error', 'Please select a category');
      return;
    }
    if (!householdInfo?.id) {
      Alert.alert('Error', 'Household not found');
      return;
    }

    setIsSubmitting(true);
    try {
      const token = await getIdToken(true);
      const response = await fetch(`${API_BASE_URL}/households/${householdInfo.id}/vendors`, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          displayName: displayName.trim(),
          category,
          contactName: contactName.trim() || undefined,
          phone: phone.trim() || undefined,
          email: email.trim() || undefined,
          websiteUrl: websiteUrl.trim() || undefined,
          addressLine1: addressLine1.trim() || undefined,
          city: city.trim() || undefined,
          state: state.trim() || undefined,
          postalCode: postalCode.trim() || undefined,
          serviceDescription: serviceDescription.trim() || undefined,
          notes: notes.trim() || undefined,
          accountNumber: accountNumber.trim() || undefined,
        }),
      });

      if (response.ok) {
        const newVendor = await response.json();
        Alert.alert('Success', 'Vendor added successfully', [
          {
            text: 'View Vendor',
            onPress: () => router.replace(`/(tabs)/manager/vendors/${newVendor.id}`),
          },
          {
            text: 'Add Another',
            onPress: () => resetForm(),
          },
        ]);
      } else {
        const error = await response.json();
        Alert.alert('Error', error.message || 'Failed to add vendor');
      }
    } catch (err) {
      console.error('Add vendor error:', err);
      Alert.alert('Error', 'Failed to add vendor. Please try again.');
    } finally {
      setIsSubmitting(false);
    }
  };

  const resetForm = () => {
    setCategory('');
    setDisplayName('');
    setContactName('');
    setPhone('');
    setEmail('');
    setWebsiteUrl('');
    setAddressLine1('');
    setCity('');
    setState('');
    setPostalCode('');
    setServiceDescription('');
    setNotes('');
    setAccountNumber('');
  };

  const SaveButton = () => (
    <TouchableOpacity onPress={handleSubmit} disabled={isSubmitting}>
      <Text style={[styles.saveButton, isSubmitting && styles.saveButtonDisabled]}>
        {isSubmitting ? 'Saving...' : 'Save'}
      </Text>
    </TouchableOpacity>
  );

  return (
    <View style={styles.fullContainer}>
      <AppHeader title="Add Vendor" showBack rightAction={<SaveButton />} />

      <KeyboardAvoidingView
        style={styles.keyboardView}
        behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
      >
        <ScrollView contentContainerStyle={styles.scrollContent}>
          {/* Category Selection */}
          <Text style={styles.sectionTitle}>Category *</Text>
          <ScrollView
            horizontal
            showsHorizontalScrollIndicator={false}
            style={styles.categoryScroll}
          >
            {VENDOR_CATEGORIES.map(cat => (
              <TouchableOpacity
                key={cat.id}
                style={[
                  styles.categoryChip,
                  category === cat.id && styles.categoryChipActive,
                ]}
                onPress={() => setCategory(cat.id)}
              >
                <Ionicons
                  name={cat.icon as any}
                  size={18}
                  color={category === cat.id ? colors.white : colors.text.secondary}
                />
                <Text
                  style={[
                    styles.categoryChipText,
                    category === cat.id && styles.categoryChipTextActive,
                  ]}
                >
                  {cat.label}
                </Text>
              </TouchableOpacity>
            ))}
          </ScrollView>

          {/* Basic Info */}
          <Card style={styles.formCard}>
            <Text style={styles.cardTitle}>Business Information</Text>

            <Text style={styles.inputLabel}>Business Name *</Text>
            <TextInput
              style={styles.textInput}
              value={displayName}
              onChangeText={setDisplayName}
              placeholder="e.g., Ace Plumbing Services"
              placeholderTextColor={colors.text.tertiary}
            />

            <Text style={styles.inputLabel}>Contact Person</Text>
            <TextInput
              style={styles.textInput}
              value={contactName}
              onChangeText={setContactName}
              placeholder="e.g., John Smith"
              placeholderTextColor={colors.text.tertiary}
            />

            <Text style={styles.inputLabel}>Services Offered</Text>
            <TextInput
              style={[styles.textInput, styles.textArea]}
              value={serviceDescription}
              onChangeText={setServiceDescription}
              placeholder="Describe their services..."
              placeholderTextColor={colors.text.tertiary}
              multiline
              numberOfLines={2}
            />
          </Card>

          {/* Contact Info */}
          <Card style={styles.formCard}>
            <Text style={styles.cardTitle}>Contact Information</Text>

            <Text style={styles.inputLabel}>Phone Number</Text>
            <TextInput
              style={styles.textInput}
              value={phone}
              onChangeText={setPhone}
              placeholder="(555) 123-4567"
              placeholderTextColor={colors.text.tertiary}
              keyboardType="phone-pad"
            />

            <Text style={styles.inputLabel}>Email</Text>
            <TextInput
              style={styles.textInput}
              value={email}
              onChangeText={setEmail}
              placeholder="contact@business.com"
              placeholderTextColor={colors.text.tertiary}
              keyboardType="email-address"
              autoCapitalize="none"
            />

            <Text style={styles.inputLabel}>Website</Text>
            <TextInput
              style={styles.textInput}
              value={websiteUrl}
              onChangeText={setWebsiteUrl}
              placeholder="https://www.example.com"
              placeholderTextColor={colors.text.tertiary}
              keyboardType="url"
              autoCapitalize="none"
            />

            <Text style={styles.inputLabel}>Account Number</Text>
            <TextInput
              style={styles.textInput}
              value={accountNumber}
              onChangeText={setAccountNumber}
              placeholder="Your account # with this vendor"
              placeholderTextColor={colors.text.tertiary}
            />
            <Text style={styles.inputHint}>
              For utilities: helps us track and pay your bills
            </Text>
          </Card>

          {/* Address */}
          <Card style={styles.formCard}>
            <Text style={styles.cardTitle}>Address (Optional)</Text>

            <Text style={styles.inputLabel}>Street Address</Text>
            <TextInput
              style={styles.textInput}
              value={addressLine1}
              onChangeText={setAddressLine1}
              placeholder="123 Main Street"
              placeholderTextColor={colors.text.tertiary}
            />

            <View style={styles.row}>
              <View style={styles.flex2}>
                <Text style={styles.inputLabel}>City</Text>
                <TextInput
                  style={styles.textInput}
                  value={city}
                  onChangeText={setCity}
                  placeholder="City"
                  placeholderTextColor={colors.text.tertiary}
                />
              </View>
              <View style={styles.flex1}>
                <Text style={styles.inputLabel}>State</Text>
                <TextInput
                  style={styles.textInput}
                  value={state}
                  onChangeText={setState}
                  placeholder="CA"
                  placeholderTextColor={colors.text.tertiary}
                  maxLength={2}
                  autoCapitalize="characters"
                />
              </View>
              <View style={styles.flex1}>
                <Text style={styles.inputLabel}>ZIP</Text>
                <TextInput
                  style={styles.textInput}
                  value={postalCode}
                  onChangeText={setPostalCode}
                  placeholder="12345"
                  placeholderTextColor={colors.text.tertiary}
                  keyboardType="number-pad"
                  maxLength={10}
                />
              </View>
            </View>
          </Card>

          {/* Notes */}
          <Card style={styles.formCard}>
            <Text style={styles.cardTitle}>Notes</Text>
            <TextInput
              style={[styles.textInput, styles.textArea]}
              value={notes}
              onChangeText={setNotes}
              placeholder="Add any notes about this vendor..."
              placeholderTextColor={colors.text.tertiary}
              multiline
              numberOfLines={3}
            />
          </Card>

          {/* Submit Button */}
          <TouchableOpacity
            style={[styles.submitButton, isSubmitting && styles.submitButtonDisabled]}
            onPress={handleSubmit}
            disabled={isSubmitting}
          >
            {isSubmitting ? (
              <LoadingSpinner size="small" />
            ) : (
              <>
                <Ionicons name="add-circle" size={20} color={colors.white} />
                <Text style={styles.submitButtonText}>Add Vendor</Text>
              </>
            )}
          </TouchableOpacity>
        </ScrollView>
      </KeyboardAvoidingView>
    </View>
  );
}

// =============================================================================
// STYLES
// =============================================================================

const styles = StyleSheet.create({
  fullContainer: {
    flex: 1,
    backgroundColor: colors.haven.navy[900],
  },
  container: {
    flex: 1,
    backgroundColor: colors.background.secondary,
  },
  keyboardView: {
    flex: 1,
    backgroundColor: colors.background.secondary,
  },
  scrollContent: {
    padding: spacing[4],
    paddingBottom: spacing[10],
  },
  saveButton: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.haven.champagne[500],
  },
  saveButtonDisabled: {
    opacity: 0.5,
  },
  sectionTitle: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.secondary,
    marginBottom: spacing[2],
    textTransform: 'uppercase',
    letterSpacing: 0.5,
  },
  categoryScroll: {
    marginBottom: spacing[4],
  },
  categoryChip: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: spacing[2],
    paddingHorizontal: spacing[3],
    borderRadius: borderRadius.full,
    backgroundColor: colors.white,
    borderWidth: 1,
    borderColor: colors.border.light,
    marginRight: spacing[2],
    gap: spacing[1],
  },
  categoryChipActive: {
    backgroundColor: colors.haven.champagne[500],
    borderColor: colors.haven.champagne[500],
  },
  categoryChipText: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    fontWeight: typography.fontWeights.medium,
  },
  categoryChipTextActive: {
    color: colors.white,
  },
  formCard: {
    padding: spacing[4],
    marginBottom: spacing[4],
  },
  cardTitle: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
    marginBottom: spacing[3],
  },
  inputLabel: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.secondary,
    marginBottom: spacing[1],
    marginTop: spacing[3],
  },
  textInput: {
    backgroundColor: colors.background.secondary,
    borderWidth: 1,
    borderColor: colors.border.light,
    borderRadius: borderRadius.lg,
    paddingHorizontal: spacing[3],
    paddingVertical: spacing[3],
    fontSize: typography.fontSizes.base,
    color: colors.text.primary,
  },
  textArea: {
    height: 80,
    textAlignVertical: 'top',
  },
  inputHint: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
    marginTop: spacing[1],
    fontStyle: 'italic',
  },
  row: {
    flexDirection: 'row',
    gap: spacing[2],
  },
  flex1: {
    flex: 1,
  },
  flex2: {
    flex: 2,
  },
  submitButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: colors.haven.champagne[500],
    paddingVertical: spacing[4],
    borderRadius: borderRadius.lg,
    gap: spacing[2],
    marginTop: spacing[2],
  },
  submitButtonDisabled: {
    opacity: 0.7,
  },
  submitButtonText: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.white,
  },
});

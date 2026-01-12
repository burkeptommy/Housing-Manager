import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  Modal,
  TouchableOpacity,
  ScrollView,
  TextInput,
  KeyboardAvoidingView,
  Platform,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { colors, typography, spacing, borderRadius } from '../../lib/theme';
import { API_BASE_URL } from '../../lib/api';
import { getIdToken } from '../../lib/firebase';
import { Button } from '../ui/Button';

// =============================================================================
// TYPES
// =============================================================================

type AssetCategory =
  | 'APPLIANCE' | 'HVAC' | 'PLUMBING' | 'ELECTRICAL' | 'STRUCTURAL'
  | 'FURNITURE' | 'ELECTRONICS' | 'OUTDOOR' | 'VEHICLE' | 'SAFETY' | 'OTHER';

interface Zone {
  id: string;
  name: string;
  type: string;
}

interface AddAssetModalProps {
  visible: boolean;
  onClose: () => void;
  householdId: string;
  zones: Zone[];
  onSuccess: () => void;
  defaultZoneId?: string;
  defaultName?: string;
  defaultCategory?: AssetCategory;
}

// =============================================================================
// COMPONENT
// =============================================================================

const ASSET_CATEGORIES: { value: AssetCategory; label: string; icon: keyof typeof Ionicons.glyphMap }[] = [
  { value: 'APPLIANCE', label: 'Appliance', icon: 'cube-outline' },
  { value: 'HVAC', label: 'HVAC', icon: 'thermometer-outline' },
  { value: 'PLUMBING', label: 'Plumbing', icon: 'water-outline' },
  { value: 'ELECTRICAL', label: 'Electrical', icon: 'flash-outline' },
  { value: 'STRUCTURAL', label: 'Structural', icon: 'construct-outline' },
  { value: 'FURNITURE', label: 'Furniture', icon: 'bed-outline' },
  { value: 'ELECTRONICS', label: 'Electronics', icon: 'tv-outline' },
  { value: 'OUTDOOR', label: 'Outdoor', icon: 'leaf-outline' },
  { value: 'SAFETY', label: 'Safety', icon: 'shield-checkmark-outline' },
  { value: 'OTHER', label: 'Other', icon: 'ellipsis-horizontal' },
];

const CONDITIONS = [
  { value: 'Excellent', label: 'Excellent' },
  { value: 'Good', label: 'Good' },
  { value: 'Fair', label: 'Fair' },
  { value: 'Needs Service', label: 'Needs Service' },
];

export function AddAssetModal({
  visible,
  onClose,
  householdId,
  zones,
  onSuccess,
  defaultZoneId,
  defaultName,
  defaultCategory,
}: AddAssetModalProps) {
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Form state
  const [name, setName] = useState(defaultName || '');
  const [category, setCategory] = useState<AssetCategory>(defaultCategory || 'APPLIANCE');
  const [zoneId, setZoneId] = useState(defaultZoneId || '');
  const [brand, setBrand] = useState('');
  const [model, setModel] = useState('');
  const [serialNumber, setSerialNumber] = useState('');
  const [condition, setCondition] = useState('Good');
  const [notes, setNotes] = useState('');

  // Update form when defaults change (e.g., from suggestion)
  React.useEffect(() => {
    if (defaultName) setName(defaultName);
    if (defaultCategory) setCategory(defaultCategory);
  }, [defaultName, defaultCategory]);

  const resetForm = () => {
    setName(defaultName || '');
    setCategory(defaultCategory || 'APPLIANCE');
    setZoneId(defaultZoneId || '');
    setBrand('');
    setModel('');
    setSerialNumber('');
    setCondition('Good');
    setNotes('');
    setError(null);
  };

  const handleClose = () => {
    resetForm();
    onClose();
  };

  const handleSubmit = async () => {
    if (!name.trim()) {
      setError('Item name is required');
      return;
    }

    setIsSubmitting(true);
    setError(null);

    try {
      const token = await getIdToken(true);
      if (!token) {
        setError('Authentication expired. Please sign in again.');
        return;
      }

      const response = await fetch(
        `${API_BASE_URL}/property/assets/household/${householdId}`,
        {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${token}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            name: name.trim(),
            category,
            zoneId: zoneId || undefined,
            brand: brand.trim() || undefined,
            model: model.trim() || undefined,
            serialNumber: serialNumber.trim() || undefined,
            condition,
            notes: notes.trim() || undefined,
          }),
        }
      );

      if (!response.ok) {
        throw new Error('Failed to add item');
      }

      handleClose();
      onSuccess();
    } catch (err) {
      console.error('Add asset error:', err);
      setError('Failed to add item. Please try again.');
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <Modal
      visible={visible}
      animationType="slide"
      presentationStyle="pageSheet"
      onRequestClose={handleClose}
    >
      <SafeAreaView style={styles.container} edges={['top']}>
        <KeyboardAvoidingView
          behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
          style={styles.keyboardView}
        >
          {/* Header */}
          <View style={styles.header}>
            <TouchableOpacity onPress={handleClose} style={styles.closeButton}>
              <Ionicons name="close" size={24} color={colors.text.primary} />
            </TouchableOpacity>
            <Text style={styles.title}>Add Item</Text>
            <View style={styles.placeholder} />
          </View>

          <ScrollView
            contentContainerStyle={styles.scrollContent}
            showsVerticalScrollIndicator={false}
            keyboardShouldPersistTaps="handled"
          >
            {/* Item Name */}
            <View style={styles.section}>
              <Text style={styles.label}>Item Name *</Text>
              <TextInput
                style={styles.input}
                value={name}
                onChangeText={setName}
                placeholder="e.g., Refrigerator, Water Heater"
                placeholderTextColor={colors.text.tertiary}
              />
            </View>

            {/* Category */}
            <View style={styles.section}>
              <Text style={styles.label}>Category</Text>
              <View style={styles.typeGrid}>
                {ASSET_CATEGORIES.map((cat) => (
                  <TouchableOpacity
                    key={cat.value}
                    style={[
                      styles.typeButton,
                      category === cat.value && styles.typeButtonActive,
                    ]}
                    onPress={() => setCategory(cat.value)}
                  >
                    <Ionicons
                      name={cat.icon}
                      size={16}
                      color={category === cat.value ? colors.haven.champagne[600] : colors.text.tertiary}
                    />
                    <Text
                      style={[
                        styles.typeButtonText,
                        category === cat.value && styles.typeButtonTextActive,
                      ]}
                    >
                      {cat.label}
                    </Text>
                  </TouchableOpacity>
                ))}
              </View>
            </View>

            {/* Zone Selection */}
            {zones.length > 0 && (
              <View style={styles.section}>
                <Text style={styles.label}>Location (Zone)</Text>
                <View style={styles.zoneButtons}>
                  <TouchableOpacity
                    style={[
                      styles.zoneButton,
                      !zoneId && styles.zoneButtonActive,
                    ]}
                    onPress={() => setZoneId('')}
                  >
                    <Text
                      style={[
                        styles.zoneButtonText,
                        !zoneId && styles.zoneButtonTextActive,
                      ]}
                    >
                      No Zone
                    </Text>
                  </TouchableOpacity>
                  {zones.map((zone) => (
                    <TouchableOpacity
                      key={zone.id}
                      style={[
                        styles.zoneButton,
                        zoneId === zone.id && styles.zoneButtonActive,
                      ]}
                      onPress={() => setZoneId(zone.id)}
                    >
                      <Text
                        style={[
                          styles.zoneButtonText,
                          zoneId === zone.id && styles.zoneButtonTextActive,
                        ]}
                      >
                        {zone.name}
                      </Text>
                    </TouchableOpacity>
                  ))}
                </View>
              </View>
            )}

            {/* Brand & Model */}
            <View style={styles.sectionDivider}>
              <Text style={styles.sectionTitle}>Details</Text>
            </View>

            <View style={styles.section}>
              <Text style={styles.label}>Brand</Text>
              <TextInput
                style={styles.input}
                value={brand}
                onChangeText={setBrand}
                placeholder="e.g., Samsung, Carrier"
                placeholderTextColor={colors.text.tertiary}
              />
            </View>

            <View style={styles.section}>
              <Text style={styles.label}>Model</Text>
              <TextInput
                style={styles.input}
                value={model}
                onChangeText={setModel}
                placeholder="Enter model name/number"
                placeholderTextColor={colors.text.tertiary}
              />
            </View>

            <View style={styles.section}>
              <Text style={styles.label}>Serial Number</Text>
              <TextInput
                style={styles.input}
                value={serialNumber}
                onChangeText={setSerialNumber}
                placeholder="Enter serial number"
                placeholderTextColor={colors.text.tertiary}
              />
            </View>

            {/* Condition */}
            <View style={styles.section}>
              <Text style={styles.label}>Condition</Text>
              <View style={styles.conditionButtons}>
                {CONDITIONS.map((cond) => (
                  <TouchableOpacity
                    key={cond.value}
                    style={[
                      styles.conditionButton,
                      condition === cond.value && styles.conditionButtonActive,
                    ]}
                    onPress={() => setCondition(cond.value)}
                  >
                    <Text
                      style={[
                        styles.conditionButtonText,
                        condition === cond.value && styles.conditionButtonTextActive,
                      ]}
                    >
                      {cond.label}
                    </Text>
                  </TouchableOpacity>
                ))}
              </View>
            </View>

            {/* Notes */}
            <View style={styles.section}>
              <Text style={styles.label}>Notes</Text>
              <TextInput
                style={[styles.input, styles.textArea]}
                value={notes}
                onChangeText={setNotes}
                placeholder="Any notes about this item..."
                placeholderTextColor={colors.text.tertiary}
                multiline
                numberOfLines={3}
                textAlignVertical="top"
              />
            </View>

            {/* Error */}
            {error && (
              <View style={styles.errorContainer}>
                <Text style={styles.errorText}>{error}</Text>
              </View>
            )}

            {/* Submit Button */}
            <View style={styles.buttonContainer}>
              <Button
                title={isSubmitting ? 'Adding...' : 'Add Item'}
                onPress={handleSubmit}
                disabled={isSubmitting || !name.trim()}
                variant="primary"
              />
            </View>
          </ScrollView>
        </KeyboardAvoidingView>
      </SafeAreaView>
    </Modal>
  );
}

// =============================================================================
// STYLES
// =============================================================================

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background.primary,
  },
  keyboardView: {
    flex: 1,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: spacing[4],
    paddingVertical: spacing[3],
    borderBottomWidth: 1,
    borderBottomColor: colors.border.light,
  },
  closeButton: {
    padding: spacing[2],
  },
  title: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
  },
  placeholder: {
    width: 40,
  },
  scrollContent: {
    padding: spacing[4],
    paddingBottom: spacing[8],
  },
  section: {
    marginBottom: spacing[4],
  },
  sectionDivider: {
    marginTop: spacing[4],
    marginBottom: spacing[4],
    paddingBottom: spacing[2],
    borderBottomWidth: 1,
    borderBottomColor: colors.border.light,
  },
  sectionTitle: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
  },
  label: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.secondary,
    marginBottom: spacing[2],
  },
  input: {
    backgroundColor: colors.background.secondary,
    borderRadius: borderRadius.lg,
    paddingHorizontal: spacing[4],
    paddingVertical: spacing[3],
    fontSize: typography.fontSizes.base,
    color: colors.text.primary,
    borderWidth: 1,
    borderColor: colors.border.light,
  },
  textArea: {
    minHeight: 80,
    paddingTop: spacing[3],
  },
  typeGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: spacing[2],
  },
  typeButton: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: spacing[2],
    paddingHorizontal: spacing[3],
    borderRadius: borderRadius.lg,
    backgroundColor: colors.background.secondary,
    borderWidth: 1,
    borderColor: colors.border.light,
    gap: spacing[1],
  },
  typeButtonActive: {
    backgroundColor: colors.haven.champagne[50],
    borderColor: colors.haven.champagne[500],
  },
  typeButtonText: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.secondary,
  },
  typeButtonTextActive: {
    color: colors.haven.champagne[600],
  },
  zoneButtons: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: spacing[2],
  },
  zoneButton: {
    paddingVertical: spacing[2],
    paddingHorizontal: spacing[4],
    borderRadius: borderRadius.full,
    backgroundColor: colors.background.secondary,
    borderWidth: 1,
    borderColor: colors.border.light,
  },
  zoneButtonActive: {
    backgroundColor: colors.haven.navy[50],
    borderColor: colors.haven.navy[500],
  },
  zoneButtonText: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.secondary,
  },
  zoneButtonTextActive: {
    color: colors.haven.navy[700],
  },
  conditionButtons: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: spacing[2],
  },
  conditionButton: {
    paddingVertical: spacing[2],
    paddingHorizontal: spacing[4],
    borderRadius: borderRadius.full,
    backgroundColor: colors.background.secondary,
    borderWidth: 1,
    borderColor: colors.border.light,
  },
  conditionButtonActive: {
    backgroundColor: colors.haven.navy[50],
    borderColor: colors.haven.navy[500],
  },
  conditionButtonText: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.secondary,
  },
  conditionButtonTextActive: {
    color: colors.haven.navy[700],
  },
  errorContainer: {
    backgroundColor: colors.status.error + '20',
    padding: spacing[3],
    borderRadius: borderRadius.md,
    marginBottom: spacing[4],
  },
  errorText: {
    fontSize: typography.fontSizes.sm,
    color: colors.status.error,
    textAlign: 'center',
  },
  buttonContainer: {
    marginTop: spacing[4],
  },
});

import React, { useState, useEffect } from 'react';
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
import DateTimePicker from '@react-native-community/datetimepicker';
import { colors, typography, spacing, borderRadius } from '../../lib/theme';
import { Button } from '../ui/Button';

// =============================================================================
// TYPES
// =============================================================================

export type FieldType = 'text' | 'phone' | 'email' | 'date' | 'currency' | 'multiline' | 'number';

export interface EditField {
  key: string;
  label: string;
  value: string;
  type: FieldType;
  placeholder?: string;
  required?: boolean;
}

export interface EditInfoModalProps {
  visible: boolean;
  title: string;
  fields: EditField[];
  onSave: (values: Record<string, string>) => Promise<void>;
  onClose: () => void;
  isLoading?: boolean;
}

// =============================================================================
// COMPONENT
// =============================================================================

export function EditInfoModal({
  visible,
  title,
  fields,
  onSave,
  onClose,
  isLoading = false,
}: EditInfoModalProps) {
  const [values, setValues] = useState<Record<string, string>>({});
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [showDatePicker, setShowDatePicker] = useState<string | null>(null);

  // Initialize values from fields when modal opens
  useEffect(() => {
    if (visible) {
      const initialValues: Record<string, string> = {};
      fields.forEach((field) => {
        initialValues[field.key] = field.value || '';
      });
      setValues(initialValues);
      setError(null);
    }
  }, [visible, fields]);

  const handleClose = () => {
    setError(null);
    onClose();
  };

  const handleChange = (key: string, value: string) => {
    setValues((prev) => ({ ...prev, [key]: value }));
  };

  const handleSubmit = async () => {
    // Validate required fields
    for (const field of fields) {
      if (field.required && !values[field.key]?.trim()) {
        setError(`${field.label} is required`);
        return;
      }
    }

    setIsSubmitting(true);
    setError(null);

    try {
      await onSave(values);
      handleClose();
    } catch (err) {
      console.error('Save error:', err);
      setError('Failed to save. Please try again.');
    } finally {
      setIsSubmitting(false);
    }
  };

  const formatCurrencyInput = (value: string): string => {
    // Remove non-numeric characters except decimal
    const cleaned = value.replace(/[^0-9.]/g, '');
    // Ensure only one decimal point
    const parts = cleaned.split('.');
    if (parts.length > 2) {
      return parts[0] + '.' + parts.slice(1).join('');
    }
    return cleaned;
  };

  const formatPhoneInput = (value: string): string => {
    // Remove non-numeric characters
    const cleaned = value.replace(/\D/g, '');
    // Format as (XXX) XXX-XXXX
    if (cleaned.length <= 3) {
      return cleaned;
    }
    if (cleaned.length <= 6) {
      return `(${cleaned.slice(0, 3)}) ${cleaned.slice(3)}`;
    }
    return `(${cleaned.slice(0, 3)}) ${cleaned.slice(3, 6)}-${cleaned.slice(6, 10)}`;
  };

  const handleDateChange = (key: string, event: any, selectedDate?: Date) => {
    setShowDatePicker(null);
    if (selectedDate) {
      handleChange(key, selectedDate.toISOString());
    }
  };

  const formatDateDisplay = (isoString: string): string => {
    if (!isoString) return '';
    try {
      return new Date(isoString).toLocaleDateString('en-US', {
        month: 'long',
        day: 'numeric',
        year: 'numeric',
      });
    } catch {
      return isoString;
    }
  };

  const renderField = (field: EditField) => {
    const value = values[field.key] || '';

    switch (field.type) {
      case 'date':
        return (
          <View key={field.key} style={styles.fieldContainer}>
            <Text style={styles.label}>
              {field.label}
              {field.required && <Text style={styles.required}> *</Text>}
            </Text>
            <TouchableOpacity
              style={styles.dateInput}
              onPress={() => setShowDatePicker(field.key)}
            >
              <Text style={value ? styles.dateText : styles.datePlaceholder}>
                {value ? formatDateDisplay(value) : field.placeholder || 'Select date'}
              </Text>
              <Ionicons name="calendar-outline" size={20} color={colors.text.tertiary} />
            </TouchableOpacity>
            {showDatePicker === field.key && (
              <DateTimePicker
                value={value ? new Date(value) : new Date()}
                mode="date"
                display={Platform.OS === 'ios' ? 'spinner' : 'default'}
                onChange={(event, date) => handleDateChange(field.key, event, date)}
              />
            )}
          </View>
        );

      case 'multiline':
        return (
          <View key={field.key} style={styles.fieldContainer}>
            <Text style={styles.label}>
              {field.label}
              {field.required && <Text style={styles.required}> *</Text>}
            </Text>
            <TextInput
              style={[styles.input, styles.multilineInput]}
              value={value}
              onChangeText={(text) => handleChange(field.key, text)}
              placeholder={field.placeholder}
              placeholderTextColor={colors.text.tertiary}
              multiline
              numberOfLines={4}
              textAlignVertical="top"
            />
          </View>
        );

      case 'currency':
        return (
          <View key={field.key} style={styles.fieldContainer}>
            <Text style={styles.label}>
              {field.label}
              {field.required && <Text style={styles.required}> *</Text>}
            </Text>
            <View style={styles.currencyInputContainer}>
              <Text style={styles.currencyPrefix}>$</Text>
              <TextInput
                style={[styles.input, styles.currencyInput]}
                value={value}
                onChangeText={(text) => handleChange(field.key, formatCurrencyInput(text))}
                placeholder={field.placeholder || '0.00'}
                placeholderTextColor={colors.text.tertiary}
                keyboardType="decimal-pad"
              />
            </View>
          </View>
        );

      case 'phone':
        return (
          <View key={field.key} style={styles.fieldContainer}>
            <Text style={styles.label}>
              {field.label}
              {field.required && <Text style={styles.required}> *</Text>}
            </Text>
            <TextInput
              style={styles.input}
              value={value}
              onChangeText={(text) => handleChange(field.key, formatPhoneInput(text))}
              placeholder={field.placeholder || '(555) 555-5555'}
              placeholderTextColor={colors.text.tertiary}
              keyboardType="phone-pad"
              maxLength={14}
            />
          </View>
        );

      case 'email':
        return (
          <View key={field.key} style={styles.fieldContainer}>
            <Text style={styles.label}>
              {field.label}
              {field.required && <Text style={styles.required}> *</Text>}
            </Text>
            <TextInput
              style={styles.input}
              value={value}
              onChangeText={(text) => handleChange(field.key, text)}
              placeholder={field.placeholder || 'email@example.com'}
              placeholderTextColor={colors.text.tertiary}
              keyboardType="email-address"
              autoCapitalize="none"
              autoCorrect={false}
            />
          </View>
        );

      case 'number':
        return (
          <View key={field.key} style={styles.fieldContainer}>
            <Text style={styles.label}>
              {field.label}
              {field.required && <Text style={styles.required}> *</Text>}
            </Text>
            <TextInput
              style={styles.input}
              value={value}
              onChangeText={(text) => handleChange(field.key, text.replace(/[^0-9]/g, ''))}
              placeholder={field.placeholder}
              placeholderTextColor={colors.text.tertiary}
              keyboardType="number-pad"
            />
          </View>
        );

      default: // text
        return (
          <View key={field.key} style={styles.fieldContainer}>
            <Text style={styles.label}>
              {field.label}
              {field.required && <Text style={styles.required}> *</Text>}
            </Text>
            <TextInput
              style={styles.input}
              value={value}
              onChangeText={(text) => handleChange(field.key, text)}
              placeholder={field.placeholder}
              placeholderTextColor={colors.text.tertiary}
              autoCapitalize="words"
            />
          </View>
        );
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
            <Text style={styles.title}>{title}</Text>
            <View style={styles.placeholder} />
          </View>

          <ScrollView
            contentContainerStyle={styles.scrollContent}
            showsVerticalScrollIndicator={false}
            keyboardShouldPersistTaps="handled"
          >
            {/* Fields */}
            {fields.map(renderField)}

            {/* Error */}
            {error && (
              <View style={styles.errorContainer}>
                <Text style={styles.errorText}>{error}</Text>
              </View>
            )}

            {/* Submit Button */}
            <View style={styles.buttonContainer}>
              <Button
                title={isSubmitting || isLoading ? 'Saving...' : 'Save'}
                onPress={handleSubmit}
                disabled={isSubmitting || isLoading}
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
  fieldContainer: {
    marginBottom: spacing[4],
  },
  label: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.secondary,
    marginBottom: spacing[2],
  },
  required: {
    color: colors.status.error,
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
  multilineInput: {
    minHeight: 100,
    paddingTop: spacing[3],
  },
  currencyInputContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.background.secondary,
    borderRadius: borderRadius.lg,
    borderWidth: 1,
    borderColor: colors.border.light,
  },
  currencyPrefix: {
    paddingLeft: spacing[4],
    fontSize: typography.fontSizes.base,
    color: colors.text.tertiary,
  },
  currencyInput: {
    flex: 1,
    borderWidth: 0,
    backgroundColor: 'transparent',
  },
  dateInput: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    backgroundColor: colors.background.secondary,
    borderRadius: borderRadius.lg,
    paddingHorizontal: spacing[4],
    paddingVertical: spacing[3],
    borderWidth: 1,
    borderColor: colors.border.light,
  },
  dateText: {
    fontSize: typography.fontSizes.base,
    color: colors.text.primary,
  },
  datePlaceholder: {
    fontSize: typography.fontSizes.base,
    color: colors.text.tertiary,
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

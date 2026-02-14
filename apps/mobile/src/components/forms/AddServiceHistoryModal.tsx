import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  Modal,
  TouchableOpacity,
  TextInput,
  ScrollView,
  KeyboardAvoidingView,
  Platform,
  Alert,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import * as DocumentPicker from 'expo-document-picker';
import { Button } from '../ui/Button';
import { colors, typography, spacing, borderRadius } from '../../lib/theme';
import { API_BASE_URL } from '../../lib/api';
import { getIdToken } from '../../lib/firebase';

interface AddServiceHistoryModalProps {
  visible: boolean;
  onClose: () => void;
  vehicleId: string;
  householdId: string;
  onSuccess: () => void;
}

const SERVICE_TYPES = [
  { id: 'OIL_CHANGE', label: 'Oil Change', icon: 'water-outline' },
  { id: 'TIRE_ROTATION', label: 'Tire Rotation', icon: 'ellipse-outline' },
  { id: 'GENERAL_MAINTENANCE', label: 'Tire Replacement', icon: 'ellipse' },
  { id: 'BRAKE_SERVICE', label: 'Brake Service', icon: 'disc-outline' },
  { id: 'INSPECTION', label: 'Inspection', icon: 'clipboard-outline' },
  { id: 'TRANSMISSION_SERVICE', label: 'Transmission', icon: 'cog-outline' },
  { id: 'BATTERY_REPLACEMENT', label: 'Battery', icon: 'battery-charging-outline' },
  { id: 'AIR_FILTER', label: 'Air Filter', icon: 'funnel-outline' },
  { id: 'COOLANT_FLUSH', label: 'Coolant Flush', icon: 'thermometer-outline' },
  { id: 'REPAIR', label: 'Repair', icon: 'build-outline' },
  { id: 'OTHER', label: 'Other', icon: 'construct-outline' },
];

export function AddServiceHistoryModal({
  visible,
  onClose,
  vehicleId,
  householdId,
  onSuccess,
}: AddServiceHistoryModalProps) {
  const [serviceType, setServiceType] = useState('OIL_CHANGE');
  const [date, setDate] = useState(new Date().toISOString().split('T')[0]);
  const [mileage, setMileage] = useState('');
  const [cost, setCost] = useState('');
  const [vendor, setVendor] = useState('');
  const [description, setDescription] = useState('');
  const [notes, setNotes] = useState('');
  const [documents, setDocuments] = useState<{ uri: string; name: string }[]>([]);
  const [isSaving, setIsSaving] = useState(false);

  const handlePickDocument = async () => {
    try {
      const result = await DocumentPicker.getDocumentAsync({
        type: ['application/pdf', 'image/*'],
        copyToCacheDirectory: true,
      });

      if (result.canceled) return;

      setDocuments(prev => [...prev, {
        uri: result.assets[0].uri,
        name: result.assets[0].name,
      }]);
    } catch (err) {
      Alert.alert('Error', 'Failed to pick document');
    }
  };

  const handleSave = async () => {
    if (!date) {
      Alert.alert('Required', 'Service date is required');
      return;
    }

    setIsSaving(true);
    try {
      const token = await getIdToken(true);
      if (!token) throw new Error('Authentication expired');

      // Create the service record
      const response = await fetch(
        `${API_BASE_URL}/family/vehicles/${vehicleId}/service-records`,
        {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${token}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            serviceType,
            serviceDate: date,
            mileageAt: mileage ? parseInt(mileage, 10) : undefined,
            cost: cost ? parseFloat(cost) : undefined,
            shopName: vendor || undefined,
            description: description || SERVICE_TYPES.find(t => t.id === serviceType)?.label,
            notes: notes || undefined,
          }),
        }
      );

      if (!response.ok) throw new Error('Failed to save service record');

      const serviceRecord = await response.json();

      // Upload documents if any
      for (const doc of documents) {
        const formData = new FormData();
        formData.append('file', {
          uri: doc.uri,
          name: doc.name,
          type: doc.name.endsWith('.pdf') ? 'application/pdf' : 'image/jpeg',
        } as any);
        formData.append('category', 'SERVICE_RECORD');
        formData.append('vehicleId', vehicleId);
        formData.append('serviceRecordId', serviceRecord.id);

        await fetch(`${API_BASE_URL}/vault/upload`, {
          method: 'POST',
          headers: { Authorization: `Bearer ${token}` },
          body: formData,
        });
      }

      onSuccess();
      onClose();

      // Reset form
      setServiceType('oil_change');
      setDate(new Date().toISOString().split('T')[0]);
      setMileage('');
      setCost('');
      setVendor('');
      setDescription('');
      setNotes('');
      setDocuments([]);

      Alert.alert('Success', 'Service record added');
    } catch (err) {
      Alert.alert('Error', 'Failed to save service record');
    } finally {
      setIsSaving(false);
    }
  };

  return (
    <Modal visible={visible} animationType="slide" presentationStyle="pageSheet">
      <SafeAreaView style={styles.container} edges={['top']}>
        <KeyboardAvoidingView
          behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
          style={styles.keyboard}
        >
          {/* Header */}
          <View style={styles.header}>
            <TouchableOpacity onPress={onClose} style={styles.closeButton}>
              <Ionicons name="close" size={24} color={colors.text.primary} />
            </TouchableOpacity>
            <Text style={styles.title}>Add Service Record</Text>
            <View style={styles.placeholder} />
          </View>

          <ScrollView style={styles.content} showsVerticalScrollIndicator={false}>
            {/* Service Type */}
            <Text style={styles.label}>Service Type</Text>
            <ScrollView
              horizontal
              showsHorizontalScrollIndicator={false}
              style={styles.typeScroll}
              contentContainerStyle={styles.typeScrollContent}
            >
              {SERVICE_TYPES.map(type => (
                <TouchableOpacity
                  key={type.id}
                  style={[styles.typeChip, serviceType === type.id && styles.typeChipActive]}
                  onPress={() => setServiceType(type.id)}
                >
                  <Ionicons
                    name={type.icon as any}
                    size={16}
                    color={serviceType === type.id ? colors.white : colors.text.secondary}
                  />
                  <Text style={[
                    styles.typeChipText,
                    serviceType === type.id && styles.typeChipTextActive
                  ]}>
                    {type.label}
                  </Text>
                </TouchableOpacity>
              ))}
            </ScrollView>

            {/* Date */}
            <Text style={styles.label}>Service Date *</Text>
            <TextInput
              style={styles.input}
              value={date}
              onChangeText={setDate}
              placeholder="YYYY-MM-DD"
              placeholderTextColor={colors.text.tertiary}
            />

            {/* Mileage */}
            <Text style={styles.label}>Mileage at Service</Text>
            <TextInput
              style={styles.input}
              value={mileage}
              onChangeText={setMileage}
              placeholder="e.g., 45000"
              placeholderTextColor={colors.text.tertiary}
              keyboardType="numeric"
            />

            {/* Cost */}
            <Text style={styles.label}>Cost</Text>
            <TextInput
              style={styles.input}
              value={cost}
              onChangeText={setCost}
              placeholder="e.g., 75.00"
              placeholderTextColor={colors.text.tertiary}
              keyboardType="decimal-pad"
            />

            {/* Vendor */}
            <Text style={styles.label}>Service Provider</Text>
            <TextInput
              style={styles.input}
              value={vendor}
              onChangeText={setVendor}
              placeholder="e.g., Joe's Auto Shop"
              placeholderTextColor={colors.text.tertiary}
            />

            {/* Description */}
            <Text style={styles.label}>Description</Text>
            <TextInput
              style={styles.input}
              value={description}
              onChangeText={setDescription}
              placeholder="Details about the service..."
              placeholderTextColor={colors.text.tertiary}
            />

            {/* Documents */}
            <Text style={styles.label}>Receipts & Documents</Text>
            <TouchableOpacity style={styles.uploadButton} onPress={handlePickDocument}>
              <Ionicons name="cloud-upload-outline" size={20} color={colors.haven.purple[500]} />
              <Text style={styles.uploadButtonText}>Upload Receipt or Invoice</Text>
            </TouchableOpacity>
            {documents.map((doc, index) => (
              <View key={index} style={styles.documentRow}>
                <Ionicons name="document-outline" size={18} color={colors.text.secondary} />
                <Text style={styles.documentName} numberOfLines={1}>{doc.name}</Text>
                <TouchableOpacity onPress={() => setDocuments(prev => prev.filter((_, i) => i !== index))}>
                  <Ionicons name="close-circle" size={20} color={colors.text.tertiary} />
                </TouchableOpacity>
              </View>
            ))}

            {/* Notes */}
            <Text style={styles.label}>Notes</Text>
            <TextInput
              style={[styles.input, styles.textArea]}
              value={notes}
              onChangeText={setNotes}
              placeholder="Any additional notes..."
              placeholderTextColor={colors.text.tertiary}
              multiline
              numberOfLines={3}
            />
          </ScrollView>

          {/* Footer */}
          <View style={styles.footer}>
            <Button
              title="Cancel"
              variant="outline"
              onPress={onClose}
              style={styles.cancelButton}
            />
            <Button
              title={isSaving ? 'Saving...' : 'Save Record'}
              onPress={handleSave}
              disabled={isSaving}
              style={styles.saveButton}
            />
          </View>
        </KeyboardAvoidingView>
      </SafeAreaView>
    </Modal>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background.primary,
  },
  keyboard: {
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
    marginLeft: -spacing[2],
  },
  title: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
  },
  placeholder: {
    width: 40,
  },
  content: {
    flex: 1,
    padding: spacing[4],
  },
  label: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.primary,
    marginBottom: spacing[2],
    marginTop: spacing[4],
  },
  input: {
    backgroundColor: colors.gray[50],
    borderWidth: 1,
    borderColor: colors.border.default,
    borderRadius: borderRadius.lg,
    paddingHorizontal: spacing[4],
    paddingVertical: spacing[3],
    fontSize: typography.fontSizes.base,
    color: colors.text.primary,
  },
  textArea: {
    minHeight: 80,
    textAlignVertical: 'top',
  },
  typeScroll: {
    marginHorizontal: -spacing[4],
  },
  typeScrollContent: {
    paddingHorizontal: spacing[4],
    gap: spacing[2],
  },
  typeChip: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: spacing[2],
    paddingHorizontal: spacing[3],
    borderRadius: borderRadius.full,
    backgroundColor: colors.gray[100],
    gap: spacing[1],
    marginRight: spacing[2],
  },
  typeChipActive: {
    backgroundColor: colors.haven.purple[500],
  },
  typeChipText: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
  },
  typeChipTextActive: {
    color: colors.white,
    fontWeight: typography.fontWeights.medium,
  },
  uploadButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: spacing[2],
    paddingVertical: spacing[3],
    borderWidth: 1,
    borderColor: colors.haven.purple[300],
    borderStyle: 'dashed',
    borderRadius: borderRadius.lg,
    backgroundColor: colors.haven.purple[50],
  },
  uploadButtonText: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.haven.purple[500],
  },
  documentRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[2],
    paddingVertical: spacing[2],
    paddingHorizontal: spacing[3],
    backgroundColor: colors.gray[50],
    borderRadius: borderRadius.md,
    marginTop: spacing[2],
  },
  documentName: {
    flex: 1,
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
  },
  footer: {
    flexDirection: 'row',
    padding: spacing[4],
    backgroundColor: colors.white,
    borderTopWidth: 1,
    borderTopColor: colors.border.light,
    gap: spacing[3],
  },
  cancelButton: {
    flex: 1,
  },
  saveButton: {
    flex: 1,
  },
});

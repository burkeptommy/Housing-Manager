import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Alert,
  Image,
  ActivityIndicator,
  Platform,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useRouter, Stack } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import * as ImagePicker from 'expo-image-picker';
import * as DocumentPicker from 'expo-document-picker';
import DateTimePicker from '@react-native-community/datetimepicker';
import { useAuth } from '../../../src/contexts/auth-context';
import { Card, Button, Input, ImageUpload } from '../../../src/components';
import { colors, typography, spacing, borderRadius } from '../../../src/lib/theme';
import { API_BASE_URL } from '../../../src/lib/api';
import { getIdToken } from '../../../src/lib/firebase';

const CATEGORIES = [
  { id: 'PROPERTY', label: 'Property', icon: 'home-outline' },
  { id: 'INSURANCE', label: 'Insurance', icon: 'shield-outline' },
  { id: 'WARRANTY', label: 'Warranty', icon: 'document-text-outline' },
  { id: 'MANUAL', label: 'Manual', icon: 'book-outline' },
  { id: 'TAX', label: 'Tax', icon: 'calculator-outline' },
  { id: 'CONTRACT', label: 'Contract', icon: 'create-outline' },
  { id: 'RECEIPT', label: 'Receipt', icon: 'receipt-outline' },
  { id: 'PERMIT', label: 'Permit', icon: 'ribbon-outline' },
  { id: 'MAINTENANCE', label: 'Maintenance', icon: 'construct-outline' },
  { id: 'OTHER', label: 'Other', icon: 'document-outline' },
];

interface SelectedFile {
  uri: string;
  name: string;
  type: string;
  size?: number;
}

export default function VaultUploadScreen() {
  const router = useRouter();
  const { householdInfo } = useAuth();
  const [isUploading, setIsUploading] = useState(false);
  const [selectedFile, setSelectedFile] = useState<SelectedFile | null>(null);
  const [showDatePicker, setShowDatePicker] = useState(false);

  const [formData, setFormData] = useState({
    title: '',
    category: 'OTHER',
    description: '',
    expirationDate: null as Date | null,
  });

  const takePhoto = async () => {
    const { status } = await ImagePicker.requestCameraPermissionsAsync();
    if (status !== 'granted') {
      Alert.alert('Permission needed', 'Camera permission is required');
      return;
    }

    const result = await ImagePicker.launchCameraAsync({
      quality: 0.8,
      allowsEditing: true,
    });

    if (!result.canceled && result.assets[0]) {
      const asset = result.assets[0];
      setSelectedFile({
        uri: asset.uri,
        name: `document_${Date.now()}.jpg`,
        type: 'image/jpeg',
      });
    }
  };

  const pickImage = async () => {
    const result = await ImagePicker.launchImageLibraryAsync({
      mediaTypes: ['images'],
      quality: 0.8,
      allowsEditing: true,
    });

    if (!result.canceled && result.assets[0]) {
      const asset = result.assets[0];
      setSelectedFile({
        uri: asset.uri,
        name: asset.fileName || `image_${Date.now()}.jpg`,
        type: asset.mimeType || 'image/jpeg',
      });
    }
  };

  const pickDocument = async () => {
    const result = await DocumentPicker.getDocumentAsync({
      type: ['application/pdf', 'image/*', 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'],
      copyToCacheDirectory: true,
    });

    if (!result.canceled && result.assets[0]) {
      const asset = result.assets[0];
      setSelectedFile({
        uri: asset.uri,
        name: asset.name,
        type: asset.mimeType || 'application/octet-stream',
        size: asset.size,
      });
    }
  };

  const showUploadOptions = () => {
    Alert.alert('Add Document', 'Choose upload method', [
      { text: 'Take Photo', onPress: takePhoto },
      { text: 'Photo Library', onPress: pickImage },
      { text: 'Browse Files', onPress: pickDocument },
      { text: 'Cancel', style: 'cancel' },
    ]);
  };

  const handleUpload = async () => {
    if (!selectedFile) {
      Alert.alert('Required', 'Please select a file to upload');
      return;
    }

    if (!formData.title.trim()) {
      Alert.alert('Required', 'Please enter a document name');
      return;
    }

    if (!householdInfo?.id) {
      Alert.alert('Error', 'No household found');
      return;
    }

    setIsUploading(true);
    try {
      const token = await getIdToken(true);
      if (!token) {
        Alert.alert('Error', 'Authentication expired');
        return;
      }

      const uploadData = new FormData();
      uploadData.append('file', {
        uri: selectedFile.uri,
        name: selectedFile.name,
        type: selectedFile.type,
      } as any);
      uploadData.append('title', formData.title.trim());
      uploadData.append('category', formData.category);
      if (formData.description.trim()) {
        uploadData.append('description', formData.description.trim());
      }
      if (formData.expirationDate) {
        uploadData.append('expiresAt', formData.expirationDate.toISOString());
      }

      const response = await fetch(
        `${API_BASE_URL}/documents/household/${householdInfo.id}/upload`,
        {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${token}`,
          },
          body: uploadData,
        }
      );

      if (!response.ok) {
        throw new Error('Upload failed');
      }

      Alert.alert('Success', 'Document uploaded successfully', [
        { text: 'OK', onPress: () => router.back() },
      ]);
    } catch (error) {
      console.error('Upload error:', error);
      Alert.alert('Error', 'Failed to upload document. Please try again.');
    } finally {
      setIsUploading(false);
    }
  };

  const getFileIcon = () => {
    if (!selectedFile) return 'document-outline';
    if (selectedFile.type.includes('pdf')) return 'document-text';
    if (selectedFile.type.includes('image')) return 'image';
    return 'document';
  };

  const formatFileSize = (bytes?: number) => {
    if (!bytes) return '';
    if (bytes < 1024) return `${bytes} B`;
    if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
    return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
  };

  return (
    <SafeAreaView style={styles.container} edges={['bottom']}>
      <Stack.Screen options={{ title: 'Upload Document' }} />
      <ScrollView
        contentContainerStyle={styles.scrollContent}
        showsVerticalScrollIndicator={false}
      >
        {/* File Selection */}
        <Card style={styles.card}>
          <Text style={styles.cardTitle}>Document File</Text>

          {selectedFile ? (
            <View style={styles.selectedFile}>
              {selectedFile.type.includes('image') ? (
                <Image source={{ uri: selectedFile.uri }} style={styles.previewImage} />
              ) : (
                <View style={styles.filePreview}>
                  <Ionicons name={getFileIcon() as any} size={48} color={colors.haven.purple[500]} />
                </View>
              )}
              <View style={styles.fileInfo}>
                <Text style={styles.fileName} numberOfLines={1}>{selectedFile.name}</Text>
                {selectedFile.size && (
                  <Text style={styles.fileSize}>{formatFileSize(selectedFile.size)}</Text>
                )}
              </View>
              <TouchableOpacity
                style={styles.changeButton}
                onPress={showUploadOptions}
              >
                <Text style={styles.changeButtonText}>Change</Text>
              </TouchableOpacity>
            </View>
          ) : (
            <View style={styles.uploadArea}>
              <View style={styles.uploadButtons}>
                <TouchableOpacity style={styles.uploadOption} onPress={takePhoto}>
                  <View style={styles.uploadOptionIcon}>
                    <Ionicons name="camera" size={24} color={colors.haven.purple[500]} />
                  </View>
                  <Text style={styles.uploadOptionText}>Take Photo</Text>
                </TouchableOpacity>

                <TouchableOpacity style={styles.uploadOption} onPress={pickImage}>
                  <View style={styles.uploadOptionIcon}>
                    <Ionicons name="images" size={24} color={colors.haven.purple[500]} />
                  </View>
                  <Text style={styles.uploadOptionText}>Photo Library</Text>
                </TouchableOpacity>

                <TouchableOpacity style={styles.uploadOption} onPress={pickDocument}>
                  <View style={styles.uploadOptionIcon}>
                    <Ionicons name="folder-open" size={24} color={colors.haven.purple[500]} />
                  </View>
                  <Text style={styles.uploadOptionText}>Browse Files</Text>
                </TouchableOpacity>
              </View>
            </View>
          )}
        </Card>

        {/* Document Details */}
        <Card style={styles.card}>
          <Text style={styles.cardTitle}>Document Details</Text>

          <Input
            label="Document Name"
            value={formData.title}
            onChangeText={(v) => setFormData({ ...formData, title: v })}
            placeholder="e.g., Home Insurance Policy 2024"
            leftIcon="document-text-outline"
          />

          <Input
            label="Description (Optional)"
            value={formData.description}
            onChangeText={(v) => setFormData({ ...formData, description: v })}
            placeholder="Add any notes about this document..."
            multiline
            numberOfLines={2}
          />
        </Card>

        {/* Category */}
        <Card style={styles.card}>
          <Text style={styles.cardTitle}>Category</Text>
          <View style={styles.categoryGrid}>
            {CATEGORIES.map((cat) => (
              <TouchableOpacity
                key={cat.id}
                style={[
                  styles.categoryItem,
                  formData.category === cat.id && styles.categoryItemSelected,
                ]}
                onPress={() => setFormData({ ...formData, category: cat.id })}
              >
                <Ionicons
                  name={cat.icon as any}
                  size={20}
                  color={formData.category === cat.id ? colors.haven.purple[500] : colors.text.secondary}
                />
                <Text
                  style={[
                    styles.categoryLabel,
                    formData.category === cat.id && styles.categoryLabelSelected,
                  ]}
                >
                  {cat.label}
                </Text>
              </TouchableOpacity>
            ))}
          </View>
        </Card>

        {/* Expiration Date */}
        <Card style={styles.card}>
          <Text style={styles.cardTitle}>Expiration Date (Optional)</Text>
          <Text style={styles.cardSubtitle}>
            Set a date to receive reminders before this document expires
          </Text>

          <TouchableOpacity
            style={styles.dateButton}
            onPress={() => setShowDatePicker(true)}
          >
            <Ionicons name="calendar-outline" size={20} color={colors.haven.purple[500]} />
            <Text style={styles.dateValue}>
              {formData.expirationDate
                ? formData.expirationDate.toLocaleDateString('en-US', {
                    month: 'long',
                    day: 'numeric',
                    year: 'numeric',
                  })
                : 'No expiration date'}
            </Text>
            {formData.expirationDate && (
              <TouchableOpacity
                onPress={() => setFormData({ ...formData, expirationDate: null })}
                hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}
              >
                <Ionicons name="close-circle" size={20} color={colors.text.tertiary} />
              </TouchableOpacity>
            )}
          </TouchableOpacity>

          {showDatePicker && (
            <DateTimePicker
              value={formData.expirationDate || new Date()}
              mode="date"
              display="spinner"
              minimumDate={new Date()}
              onChange={(_: any, date?: Date) => {
                setShowDatePicker(Platform.OS === 'ios');
                if (date) setFormData({ ...formData, expirationDate: date });
              }}
            />
          )}
        </Card>
      </ScrollView>

      {/* Footer */}
      <View style={styles.footer}>
        <Button
          title="Cancel"
          variant="outline"
          onPress={() => router.back()}
          style={styles.cancelButton}
        />
        <Button
          title={isUploading ? 'Uploading...' : 'Upload Document'}
          onPress={handleUpload}
          loading={isUploading}
          disabled={isUploading || !selectedFile || !formData.title.trim()}
          style={styles.uploadButton}
        />
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background.secondary,
  },
  scrollContent: {
    padding: spacing[4],
  },
  card: {
    padding: spacing[4],
    marginBottom: spacing[4],
  },
  cardTitle: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
    marginBottom: spacing[2],
  },
  cardSubtitle: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    marginBottom: spacing[4],
  },
  uploadArea: {
    marginTop: spacing[2],
  },
  uploadButtons: {
    flexDirection: 'row',
    gap: spacing[3],
  },
  uploadOption: {
    flex: 1,
    alignItems: 'center',
    padding: spacing[4],
    borderRadius: borderRadius.lg,
    borderWidth: 1,
    borderColor: colors.haven.purple[200],
    borderStyle: 'dashed',
    backgroundColor: colors.haven.purple[50],
  },
  uploadOptionIcon: {
    width: 48,
    height: 48,
    borderRadius: 24,
    backgroundColor: colors.white,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: spacing[2],
  },
  uploadOptionText: {
    fontSize: typography.fontSizes.xs,
    color: colors.haven.purple[600],
    fontWeight: typography.fontWeights.medium,
    textAlign: 'center',
  },
  selectedFile: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: spacing[3],
    backgroundColor: colors.gray[50],
    borderRadius: borderRadius.lg,
    marginTop: spacing[2],
  },
  previewImage: {
    width: 60,
    height: 60,
    borderRadius: borderRadius.md,
  },
  filePreview: {
    width: 60,
    height: 60,
    borderRadius: borderRadius.md,
    backgroundColor: colors.haven.purple[50],
    alignItems: 'center',
    justifyContent: 'center',
  },
  fileInfo: {
    flex: 1,
    marginLeft: spacing[3],
  },
  fileName: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.primary,
  },
  fileSize: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
    marginTop: 2,
  },
  changeButton: {
    padding: spacing[2],
  },
  changeButtonText: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.purple[500],
    fontWeight: typography.fontWeights.medium,
  },
  categoryGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: spacing[2],
  },
  categoryItem: {
    width: '31%',
    alignItems: 'center',
    padding: spacing[3],
    borderRadius: borderRadius.lg,
    borderWidth: 1,
    borderColor: colors.border.default,
    backgroundColor: colors.white,
  },
  categoryItemSelected: {
    borderColor: colors.haven.purple[500],
    backgroundColor: colors.haven.purple[50],
  },
  categoryLabel: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.secondary,
    marginTop: spacing[1],
    textAlign: 'center',
  },
  categoryLabelSelected: {
    color: colors.haven.purple[600],
    fontWeight: typography.fontWeights.medium,
  },
  dateButton: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: spacing[3],
    borderRadius: borderRadius.lg,
    backgroundColor: colors.gray[50],
    borderWidth: 1,
    borderColor: colors.border.default,
    gap: spacing[3],
  },
  dateValue: {
    flex: 1,
    fontSize: typography.fontSizes.base,
    color: colors.text.primary,
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
  uploadButton: {
    flex: 1,
  },
});

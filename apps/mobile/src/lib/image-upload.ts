import * as ImagePicker from 'expo-image-picker';
import * as FileSystem from 'expo-file-system';
import { API_BASE_URL } from './api';
import { getIdToken } from './firebase';
import { Alert } from 'react-native';

export type EntityType = 'family-member' | 'pet' | 'household' | 'user' | 'vehicle';

/**
 * Request camera permissions
 */
export async function requestCameraPermission(): Promise<boolean> {
  const { status } = await ImagePicker.requestCameraPermissionsAsync();
  if (status !== 'granted') {
    Alert.alert(
      'Permission Required',
      'Camera access is needed to take photos.',
      [{ text: 'OK' }]
    );
    return false;
  }
  return true;
}

/**
 * Request media library permissions
 */
export async function requestMediaLibraryPermission(): Promise<boolean> {
  const { status } = await ImagePicker.requestMediaLibraryPermissionsAsync();
  if (status !== 'granted') {
    Alert.alert(
      'Permission Required',
      'Photo library access is needed to select photos.',
      [{ text: 'OK' }]
    );
    return false;
  }
  return true;
}

/**
 * Open image picker to select from library
 */
export async function pickImage(): Promise<string | null> {
  const hasPermission = await requestMediaLibraryPermission();
  if (!hasPermission) return null;

  const result = await ImagePicker.launchImageLibraryAsync({
    mediaTypes: ImagePicker.MediaTypeOptions.Images,
    allowsEditing: true,
    aspect: [1, 1],
    quality: 0.8,
  });

  if (result.canceled) return null;
  return result.assets[0].uri;
}

/**
 * Open camera to take a photo
 */
export async function takePhoto(): Promise<string | null> {
  const hasPermission = await requestCameraPermission();
  if (!hasPermission) return null;

  const result = await ImagePicker.launchCameraAsync({
    allowsEditing: true,
    aspect: [1, 1],
    quality: 0.8,
  });

  if (result.canceled) return null;
  return result.assets[0].uri;
}

/**
 * Show action sheet to pick or take photo
 */
export function showImageOptions(
  onImageSelected: (uri: string) => void,
  currentPhotoUrl?: string
): void {
  const buttons: Array<{
    text: string;
    style?: 'cancel' | 'destructive' | 'default';
    onPress?: () => void;
  }> = [];

  if (currentPhotoUrl) {
    buttons.push({
      text: 'Remove Photo',
      style: 'destructive',
      onPress: () => onImageSelected(''),
    });
  }

  buttons.push(
    {
      text: 'Take Photo',
      onPress: async () => {
        const uri = await takePhoto();
        if (uri) onImageSelected(uri);
      },
    },
    {
      text: 'Choose from Library',
      onPress: async () => {
        const uri = await pickImage();
        if (uri) onImageSelected(uri);
      },
    },
    {
      text: 'Cancel',
      style: 'cancel',
    }
  );

  Alert.alert('Profile Photo', 'Choose an option', buttons);
}

/**
 * Upload image to server
 */
export async function uploadProfileImage(
  entityType: EntityType,
  entityId: string,
  imageUri: string
): Promise<string> {
  const token = await getIdToken(true);
  if (!token) throw new Error('Not authenticated');

  // Read the file as base64
  const base64 = await FileSystem.readAsStringAsync(imageUri, {
    encoding: 'base64',
  });

  // Upload to server
  const response = await fetch(`${API_BASE_URL}/uploads/profile-image`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      entityType,
      entityId,
      image: base64,
      mimeType: 'image/jpeg',
    }),
  });

  if (!response.ok) {
    const error = await response.text();
    throw new Error(`Upload failed: ${error}`);
  }

  const data = await response.json();
  return data.imageUrl;
}

/**
 * Remove profile image
 */
export async function removeProfileImage(
  entityType: EntityType,
  entityId: string
): Promise<void> {
  const token = await getIdToken(true);
  if (!token) throw new Error('Not authenticated');

  const response = await fetch(`${API_BASE_URL}/uploads/profile-image`, {
    method: 'DELETE',
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ entityType, entityId }),
  });

  if (!response.ok) {
    throw new Error('Failed to remove image');
  }
}

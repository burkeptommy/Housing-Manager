import React from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  Image,
  Alert,
  ActivityIndicator,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import * as ImagePicker from 'expo-image-picker';
import { colors, typography, spacing, borderRadius } from '../lib/theme';

export interface ImageUploadProps {
  onImageSelected: (uri: string) => void;
  currentImage?: string | null;
  placeholder?: string;
  shape?: 'circle' | 'square' | 'rectangle';
  size?: 'small' | 'medium' | 'large';
  disabled?: boolean;
  loading?: boolean;
  showEditBadge?: boolean;
}

const SIZE_MAP = {
  small: { width: 60, height: 60 },
  medium: { width: 100, height: 100 },
  large: { width: 150, height: 150 },
};

const ASPECT_MAP = {
  circle: [1, 1] as [number, number],
  square: [1, 1] as [number, number],
  rectangle: [4, 3] as [number, number],
};

export function ImageUpload({
  onImageSelected,
  currentImage,
  placeholder = 'Add Photo',
  shape = 'square',
  size = 'medium',
  disabled = false,
  loading = false,
  showEditBadge = true,
}: ImageUploadProps) {
  const dimensions = SIZE_MAP[size];
  const aspectRatio = ASPECT_MAP[shape];
  const borderRadiusValue = shape === 'circle' ? dimensions.width / 2 : borderRadius.lg;

  const pickImage = async () => {
    const result = await ImagePicker.launchImageLibraryAsync({
      mediaTypes: ['images'],
      allowsEditing: true,
      aspect: aspectRatio,
      quality: 0.8,
    });

    if (!result.canceled && result.assets[0]) {
      onImageSelected(result.assets[0].uri);
    }
  };

  const takePhoto = async () => {
    const { status } = await ImagePicker.requestCameraPermissionsAsync();
    if (status !== 'granted') {
      Alert.alert('Permission needed', 'Camera permission is required to take photos');
      return;
    }

    const result = await ImagePicker.launchCameraAsync({
      allowsEditing: true,
      aspect: aspectRatio,
      quality: 0.8,
    });

    if (!result.canceled && result.assets[0]) {
      onImageSelected(result.assets[0].uri);
    }
  };

  const showOptions = () => {
    if (disabled || loading) return;

    Alert.alert('Upload Photo', 'Choose an option', [
      { text: 'Take Photo', onPress: takePhoto },
      { text: 'Choose from Library', onPress: pickImage },
      ...(currentImage ? [{ text: 'Remove Photo', onPress: () => onImageSelected(''), style: 'destructive' as const }] : []),
      { text: 'Cancel', style: 'cancel' },
    ]);
  };

  return (
    <TouchableOpacity
      onPress={showOptions}
      disabled={disabled || loading}
      activeOpacity={0.7}
      style={[
        styles.container,
        {
          width: shape === 'rectangle' ? dimensions.width * 1.33 : dimensions.width,
          height: dimensions.height,
          borderRadius: borderRadiusValue,
        },
        disabled && styles.disabled,
      ]}
    >
      {loading ? (
        <ActivityIndicator size="small" color={colors.haven.champagne[500]} />
      ) : currentImage ? (
        <>
          <Image
            source={{ uri: currentImage }}
            style={[
              styles.image,
              {
                width: shape === 'rectangle' ? dimensions.width * 1.33 : dimensions.width,
                height: dimensions.height,
                borderRadius: borderRadiusValue,
              },
            ]}
          />
          {showEditBadge && !disabled && (
            <View style={[styles.editBadge, shape === 'circle' && styles.editBadgeCircle]}>
              <Ionicons name="camera" size={14} color={colors.white} />
            </View>
          )}
        </>
      ) : (
        <View style={styles.placeholder}>
          <Ionicons name="camera-outline" size={size === 'small' ? 20 : 28} color={colors.haven.champagne[500]} />
          <Text style={[styles.placeholderText, size === 'small' && styles.placeholderTextSmall]}>
            {placeholder}
          </Text>
        </View>
      )}
    </TouchableOpacity>
  );
}

const styles = StyleSheet.create({
  container: {
    backgroundColor: colors.gray[100],
    borderWidth: 1,
    borderColor: colors.border.default,
    borderStyle: 'dashed',
    alignItems: 'center',
    justifyContent: 'center',
    overflow: 'hidden',
  },
  disabled: {
    opacity: 0.5,
  },
  image: {
    resizeMode: 'cover',
  },
  editBadge: {
    position: 'absolute',
    bottom: spacing[2],
    right: spacing[2],
    width: 28,
    height: 28,
    borderRadius: 14,
    backgroundColor: colors.haven.champagne[500],
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 2,
    borderColor: colors.white,
  },
  editBadgeCircle: {
    bottom: 0,
    right: 0,
  },
  placeholder: {
    alignItems: 'center',
    justifyContent: 'center',
    gap: spacing[1],
  },
  placeholderText: {
    fontSize: typography.fontSizes.xs,
    color: colors.haven.champagne[500],
    fontWeight: typography.fontWeights.medium,
    textAlign: 'center',
  },
  placeholderTextSmall: {
    fontSize: typography.fontSizes['2xs'],
  },
});

export default ImageUpload;

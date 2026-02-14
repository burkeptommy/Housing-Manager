import React from 'react';
import { View, Text, TouchableOpacity, StyleSheet } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';

interface AppHeaderProps {
  title: string;
  showBack?: boolean;
  onBackPress?: () => void;
  rightAction?: React.ReactNode;
  backgroundColor?: string;
  textColor?: string;
}

const PURPLE = '#6200EA';

export function AppHeader({
  title,
  showBack = false,
  onBackPress,
  rightAction,
  backgroundColor = PURPLE,
  textColor = '#ffffff',
}: AppHeaderProps) {
  const router = useRouter();
  const insets = useSafeAreaInsets();

  const handleBack = () => {
    if (onBackPress) {
      onBackPress();
    } else if (router.canGoBack()) {
      router.back();
    }
  };

  return (
    <View style={[styles.container, { backgroundColor, paddingTop: insets.top }]}>
      <View style={styles.content}>
        {/* Left - Back button */}
        <View style={styles.leftSection}>
          {showBack && (
            <TouchableOpacity
              onPress={handleBack}
              style={styles.backButton}
              hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}
            >
              <Ionicons name="chevron-back" size={28} color={textColor} />
            </TouchableOpacity>
          )}
        </View>

        {/* Center - Title */}
        <View style={styles.centerSection}>
          <Text style={[styles.title, { color: textColor }]} numberOfLines={1}>
            {title}
          </Text>
        </View>

        {/* Right - Optional action */}
        <View style={styles.rightSection}>{rightAction}</View>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    width: '100%',
  },
  content: {
    flexDirection: 'row',
    alignItems: 'center',
    height: 56,
    paddingHorizontal: 16,
  },
  leftSection: {
    width: 60,
    alignItems: 'flex-start',
  },
  centerSection: {
    flex: 1,
    alignItems: 'center',
  },
  rightSection: {
    width: 60,
    alignItems: 'flex-end',
  },
  backButton: {
    padding: 8,
    marginLeft: -8,
  },
  title: {
    fontSize: 17,
    fontFamily: 'Nunito_600SemiBold',
  },
});

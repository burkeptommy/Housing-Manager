import React from 'react';
import { View, ScrollView, StyleSheet, ViewStyle, RefreshControl, StatusBar, Platform } from 'react-native';
import { AppHeader } from './AppHeader';

const PURPLE = '#6200EA';
const BACKGROUND = '#f9fafb';

interface ScreenContainerProps {
  title: string;
  showBack?: boolean;
  onBackPress?: () => void;
  rightAction?: React.ReactNode;
  children: React.ReactNode;
  scrollable?: boolean;
  backgroundColor?: string;
  contentStyle?: ViewStyle;
  refreshing?: boolean;
  onRefresh?: () => void;
}

export function ScreenContainer({
  title,
  showBack = true,
  onBackPress,
  rightAction,
  children,
  scrollable = true,
  backgroundColor = BACKGROUND,
  contentStyle,
  refreshing,
  onRefresh,
}: ScreenContainerProps) {
  return (
    <View style={styles.container}>
      <StatusBar
        barStyle="light-content"
        backgroundColor={PURPLE}
        translucent={Platform.OS === 'android'}
      />
      <AppHeader
        title={title}
        showBack={showBack}
        onBackPress={onBackPress}
        rightAction={rightAction}
      />
      {scrollable ? (
        <ScrollView
          style={[styles.content, { backgroundColor }]}
          contentContainerStyle={[styles.scrollContent, contentStyle]}
          showsVerticalScrollIndicator={false}
          refreshControl={
            onRefresh ? (
              <RefreshControl refreshing={refreshing || false} onRefresh={onRefresh} />
            ) : undefined
          }
        >
          {children}
        </ScrollView>
      ) : (
        <View style={[styles.content, { backgroundColor }, contentStyle]}>
          {children}
        </View>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: PURPLE, // Match header for status bar area
  },
  content: {
    flex: 1,
  },
  scrollContent: {
    flexGrow: 1,
  },
});

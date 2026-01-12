import React from 'react';
import { View, StyleSheet } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

interface HomeHeaderProps {
  children: React.ReactNode;
}

const NAVY = '#0a1929';

export function HomeHeader({ children }: HomeHeaderProps) {
  const insets = useSafeAreaInsets();

  return (
    <View style={[styles.container, { paddingTop: insets.top }]}>
      {children}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    backgroundColor: NAVY,
    paddingBottom: 20,
  },
});

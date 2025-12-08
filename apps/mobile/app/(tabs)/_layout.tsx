import { Tabs } from 'expo-router';
import { View, Text, StyleSheet } from 'react-native';
import { colors, typography } from '../../src/lib/theme';

// Tab bar icons as simple components
function HomeIcon({ focused }: { focused: boolean }) {
  return (
    <View style={styles.iconContainer}>
      <View style={[styles.homeIcon, focused && styles.iconActive]}>
        <View style={styles.homeRoof} />
        <View style={styles.homeBody}>
          <View style={styles.homeDoor} />
        </View>
      </View>
    </View>
  );
}

function PlusIcon({ focused }: { focused: boolean }) {
  return (
    <View style={styles.iconContainer}>
      <View style={[styles.plusIcon, focused && styles.iconActive]}>
        <View style={styles.plusHorizontal} />
        <View style={styles.plusVertical} />
      </View>
    </View>
  );
}

function ChatIcon({ focused }: { focused: boolean }) {
  return (
    <View style={styles.iconContainer}>
      <View style={[styles.chatIcon, focused && styles.iconActive]}>
        <View style={styles.chatBubble} />
      </View>
    </View>
  );
}

function SettingsIcon({ focused }: { focused: boolean }) {
  return (
    <View style={styles.iconContainer}>
      <View style={[styles.settingsIcon, focused && styles.iconActive]}>
        <View style={styles.settingsGear} />
      </View>
    </View>
  );
}

export default function TabsLayout() {
  return (
    <Tabs
      screenOptions={{
        tabBarActiveTintColor: colors.primary[600],
        tabBarInactiveTintColor: colors.slate[400],
        tabBarStyle: {
          backgroundColor: colors.white,
          borderTopColor: colors.slate[200],
          paddingTop: 8,
          paddingBottom: 8,
          height: 70,
        },
        tabBarLabelStyle: {
          fontSize: typography.fontSizes.xs,
          fontWeight: typography.fontWeights.medium,
          marginTop: 4,
        },
        headerStyle: {
          backgroundColor: colors.primary[600],
        },
        headerTintColor: colors.white,
        headerTitleStyle: {
          fontWeight: typography.fontWeights.semibold,
        },
      }}
    >
      <Tabs.Screen
        name="index"
        options={{
          title: 'Home',
          headerTitle: 'Haven',
          tabBarIcon: ({ focused }) => <HomeIcon focused={focused} />,
        }}
      />
      <Tabs.Screen
        name="new-request"
        options={{
          title: 'New Request',
          tabBarIcon: ({ focused }) => <PlusIcon focused={focused} />,
        }}
      />
      <Tabs.Screen
        name="chat"
        options={{
          title: 'Chat',
          tabBarIcon: ({ focused }) => <ChatIcon focused={focused} />,
        }}
      />
      <Tabs.Screen
        name="settings"
        options={{
          title: 'Settings',
          tabBarIcon: ({ focused }) => <SettingsIcon focused={focused} />,
        }}
      />
    </Tabs>
  );
}

const styles = StyleSheet.create({
  iconContainer: {
    width: 24,
    height: 24,
    alignItems: 'center',
    justifyContent: 'center',
  },
  // Home icon styles
  homeIcon: {
    width: 20,
    height: 20,
    alignItems: 'center',
  },
  homeRoof: {
    width: 0,
    height: 0,
    borderLeftWidth: 10,
    borderRightWidth: 10,
    borderBottomWidth: 8,
    borderLeftColor: 'transparent',
    borderRightColor: 'transparent',
    borderBottomColor: colors.slate[400],
  },
  homeBody: {
    width: 14,
    height: 10,
    backgroundColor: colors.slate[400],
    alignItems: 'center',
    justifyContent: 'flex-end',
  },
  homeDoor: {
    width: 4,
    height: 6,
    backgroundColor: colors.white,
  },
  // Plus icon styles
  plusIcon: {
    width: 20,
    height: 20,
    alignItems: 'center',
    justifyContent: 'center',
  },
  plusHorizontal: {
    position: 'absolute',
    width: 16,
    height: 3,
    backgroundColor: colors.slate[400],
    borderRadius: 2,
  },
  plusVertical: {
    position: 'absolute',
    width: 3,
    height: 16,
    backgroundColor: colors.slate[400],
    borderRadius: 2,
  },
  // Chat icon styles
  chatIcon: {
    width: 20,
    height: 20,
    alignItems: 'center',
    justifyContent: 'center',
  },
  chatBubble: {
    width: 18,
    height: 14,
    backgroundColor: colors.slate[400],
    borderRadius: 8,
    borderBottomLeftRadius: 2,
  },
  // Settings icon styles
  settingsIcon: {
    width: 20,
    height: 20,
    alignItems: 'center',
    justifyContent: 'center',
  },
  settingsGear: {
    width: 16,
    height: 16,
    borderRadius: 8,
    borderWidth: 3,
    borderColor: colors.slate[400],
  },
  iconActive: {},
});

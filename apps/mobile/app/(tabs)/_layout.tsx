import { Tabs } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { colors, typography, spacing } from '../../src/lib/theme';

type TabIconName = 'home' | 'add-circle' | 'chatbubble' | 'card' | 'wallet' | 'settings';

function TabIcon({ name, focused }: { name: TabIconName; focused: boolean }) {
  const iconMap: Record<TabIconName, keyof typeof Ionicons.glyphMap> = {
    home: focused ? 'home' : 'home-outline',
    'add-circle': focused ? 'add-circle' : 'add-circle-outline',
    chatbubble: focused ? 'chatbubble' : 'chatbubble-outline',
    card: focused ? 'card' : 'card-outline',
    wallet: focused ? 'wallet' : 'wallet-outline',
    settings: focused ? 'settings' : 'settings-outline',
  };

  return (
    <Ionicons
      name={iconMap[name]}
      size={24}
      color={focused ? colors.haven.champagne[500] : colors.haven.navy[400]}
    />
  );
}

export default function TabsLayout() {
  return (
    <Tabs
      screenOptions={{
        tabBarActiveTintColor: colors.haven.champagne[500],
        tabBarInactiveTintColor: colors.haven.navy[400],
        tabBarStyle: {
          backgroundColor: colors.white,
          borderTopColor: colors.border.default,
          borderTopWidth: 1,
          paddingTop: spacing[2],
          paddingBottom: spacing[2],
          height: 80,
        },
        tabBarLabelStyle: {
          fontSize: typography.fontSizes.xs,
          fontWeight: typography.fontWeights.medium,
          marginTop: spacing[1],
        },
        headerStyle: {
          backgroundColor: colors.haven.navy[900],
        },
        headerTintColor: colors.white,
        headerTitleStyle: {
          fontWeight: typography.fontWeights.semibold,
          fontSize: typography.fontSizes.lg,
        },
        headerShadowVisible: false,
      }}
    >
      <Tabs.Screen
        name="index"
        options={{
          title: 'Home',
          headerTitle: 'Haven',
          tabBarIcon: ({ focused }) => <TabIcon name="home" focused={focused} />,
        }}
      />
      <Tabs.Screen
        name="new-request"
        options={{
          title: 'Request',
          tabBarIcon: ({ focused }) => <TabIcon name="add-circle" focused={focused} />,
        }}
      />
      <Tabs.Screen
        name="chat"
        options={{
          title: 'Sarah',
          tabBarIcon: ({ focused }) => <TabIcon name="chatbubble" focused={focused} />,
        }}
      />
      <Tabs.Screen
        name="billing"
        options={{
          title: 'Money',
          tabBarIcon: ({ focused }) => <TabIcon name="card" focused={focused} />,
        }}
      />
      <Tabs.Screen
        name="wallet"
        options={{
          title: 'Wallet',
          tabBarIcon: ({ focused }) => <TabIcon name="wallet" focused={focused} />,
        }}
      />
      <Tabs.Screen
        name="settings"
        options={{
          title: 'Settings',
          tabBarIcon: ({ focused }) => <TabIcon name="settings" focused={focused} />,
        }}
      />
    </Tabs>
  );
}

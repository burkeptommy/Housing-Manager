import { useState, useEffect } from 'react';
import { Tabs, useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { colors } from '../../src/lib/theme';
import { API_BASE_URL } from '../../src/lib/api';
import { getIdToken } from '../../src/lib/firebase';
import { useAuth } from '../../src/contexts/auth-context';
import { useSubscription } from '../../src/contexts/subscription-context';
import { AlfredTabIcon } from '../../src/components/AlfredIcon';

export default function TabLayout() {
  const router = useRouter();
  const { householdInfo } = useAuth();
  const { isEssentials, managerInfo } = useSubscription();
  const [unreadMessages, setUnreadMessages] = useState<number>(0);
  const [pendingApprovals, setPendingApprovals] = useState<number>(0);

  // Fetch badge counts
  useEffect(() => {
    const fetchBadgeCounts = async () => {
      if (!householdInfo?.id) return;

      try {
        const token = await getIdToken(true);
        if (!token) return;

        // Fetch conversations for unread count
        const conversationsRes = await fetch(`${API_BASE_URL}/conversations`, {
          headers: { Authorization: `Bearer ${token}` },
        });
        if (conversationsRes.ok) {
          const conversations = await conversationsRes.json();
          const unread = conversations.reduce(
            (sum: number, c: { unreadCount?: number }) => sum + (c.unreadCount || 0),
            0
          );
          setUnreadMessages(unread);
        }

        // Fetch approvals for pending count
        const approvalsRes = await fetch(`${API_BASE_URL}/approvals`, {
          headers: { Authorization: `Bearer ${token}` },
        });
        if (approvalsRes.ok) {
          const approvals = await approvalsRes.json();
          const pending = approvals.filter(
            (a: { status: string }) => a.status === 'PENDING'
          ).length;
          setPendingApprovals(pending);
        }
      } catch (err) {
        console.error('Fetch badge counts error:', err);
      }
    };

    fetchBadgeCounts();

    // Refresh badge counts every 30 seconds
    const interval = setInterval(fetchBadgeCounts, 30000);
    return () => clearInterval(interval);
  }, [householdInfo?.id]);

  return (
    <Tabs
      screenOptions={{
        tabBarActiveTintColor: colors.haven.navy[600],  // Navy - professional active state
        tabBarInactiveTintColor: colors.gray[400],
        tabBarStyle: {
          backgroundColor: colors.white,
          borderTopColor: colors.border.light,
          borderTopWidth: 1,
          height: 88,
          paddingBottom: 28,
          paddingTop: 8,
          // Subtle top shadow for depth
          shadowColor: '#0a1929',
          shadowOffset: { width: 0, height: -2 },
          shadowOpacity: 0.04,
          shadowRadius: 4,
          elevation: 8,
        },
        tabBarLabelStyle: {
          fontSize: 11,
          fontWeight: '600',
          letterSpacing: 0.25,
        },
        headerStyle: {
          backgroundColor: colors.haven.navy[950],
        },
        headerTintColor: colors.white,
        headerTitleStyle: {
          fontWeight: '600',
        },
        headerShadowVisible: false,
      }}
    >
      {/* ===== MAIN 5 TABS: Home, Alfred, Money, Maintenance, More ===== */}
      <Tabs.Screen
        name="index"
        options={{
          title: 'Home',
          tabBarIcon: ({ color, size }) => (
            <Ionicons name="home-outline" size={size} color={color} />
          ),
          headerShown: false,
        }}
      />
      <Tabs.Screen
        name="manager"
        options={{
          title: isEssentials ? 'Alfred' : managerInfo.name.split(' ')[0],
          tabBarIcon: ({ color, size }) => (
            isEssentials ? (
              <AlfredTabIcon size={size} color={color} />
            ) : (
              <Ionicons name="person-circle-outline" size={size} color={color} />
            )
          ),
          tabBarBadge: (pendingApprovals + unreadMessages) > 0 ? (pendingApprovals + unreadMessages) : undefined,
          tabBarBadgeStyle: {
            backgroundColor: colors.status.error,
            fontSize: 10,
            minWidth: 18,
            maxHeight: 18,
          },
          headerShown: false,
        }}
        listeners={{
          tabPress: (e) => {
            // Always navigate to the manager index when tab is pressed
            e.preventDefault();
            router.navigate('/manager');
          },
        }}
      />
      <Tabs.Screen
        name="billing"
        options={{
          title: 'Money',
          tabBarIcon: ({ color, size }) => (
            <Ionicons name="wallet-outline" size={size} color={color} />
          ),
          headerTitle: 'Bills & Payments',
          headerStyle: {
            backgroundColor: colors.haven.navy[950],
          },
          headerTintColor: colors.white,
        }}
      />
      <Tabs.Screen
        name="maintenance"
        options={{
          title: 'Tasks',
          tabBarIcon: ({ color, size }) => (
            <Ionicons name="construct-outline" size={size} color={color} />
          ),
          headerTitle: 'Maintenance',
          headerStyle: {
            backgroundColor: colors.haven.navy[950],
          },
          headerTintColor: colors.white,
        }}
      />
      <Tabs.Screen
        name="more"
        options={{
          title: 'More',
          tabBarIcon: ({ color, size }) => (
            <Ionicons name="menu-outline" size={size} color={color} />
          ),
          headerTitle: 'More',
          headerStyle: {
            backgroundColor: colors.haven.navy[950],
          },
          headerTintColor: colors.white,
        }}
      />

      {/* ===== HIDDEN SCREENS (accessible via navigation, not in tab bar) ===== */}
      <Tabs.Screen name="activity" options={{ href: null, headerShown: false }} />
      <Tabs.Screen name="approvals" options={{ href: null, headerShown: false }} />
      <Tabs.Screen name="chat" options={{ href: null, headerShown: false }} />
      <Tabs.Screen name="family" options={{ href: null, headerShown: false }} />
      <Tabs.Screen name="home" options={{ href: null, headerShown: false }} />
      <Tabs.Screen name="messages" options={{ href: null, headerShown: false }} />
      <Tabs.Screen name="new-request" options={{ href: null, headerShown: false }} />
      <Tabs.Screen name="profile" options={{ href: null, headerShown: false }} />
      <Tabs.Screen name="sarah" options={{ href: null, headerShown: false }} />
      <Tabs.Screen name="settings" options={{ href: null, headerShown: false }} />
      <Tabs.Screen name="vault" options={{ href: null, headerShown: false }} />
      <Tabs.Screen name="wallet" options={{ href: null, headerShown: false }} />
    </Tabs>
  );
}

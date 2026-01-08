import { useState, useEffect } from 'react';
import { TouchableOpacity } from 'react-native';
import { Tabs, useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { colors } from '../../src/lib/theme';
import { API_BASE_URL } from '../../src/lib/api';
import { getIdToken } from '../../src/lib/firebase';
import { useAuth } from '../../src/contexts/auth-context';
import { useSubscription } from '../../src/contexts/subscription-context';

// Back button component for nested screens
function BackButton() {
  const router = useRouter();
  return (
    <TouchableOpacity onPress={() => router.back()} style={{ marginLeft: 8 }}>
      <Ionicons name="arrow-back" size={24} color={colors.haven.navy[900]} />
    </TouchableOpacity>
  );
}

export default function TabLayout() {
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
        tabBarActiveTintColor: colors.haven.navy[900],
        tabBarInactiveTintColor: colors.gray[400],
        tabBarStyle: {
          backgroundColor: colors.white,
          borderTopColor: colors.border.light,
          borderTopWidth: 1,
          height: 88,
          paddingBottom: 28,
          paddingTop: 8,
        },
        tabBarLabelStyle: {
          fontSize: 12,
          fontWeight: '500',
        },
        headerStyle: {
          backgroundColor: colors.white,
        },
        headerTintColor: colors.haven.navy[900],
        headerTitleStyle: {
          fontWeight: '600',
        },
        headerShadowVisible: false,
      }}
    >
      {/* ===== MAIN 5 TABS (visible in tab bar) ===== */}
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
              <Ionicons name="sparkles" size={size} color={color} />
            ) : (
              <Ionicons name="person-circle-outline" size={size} color={color} />
            )
          ),
          tabBarBadge: pendingApprovals > 0 ? pendingApprovals : undefined,
          tabBarBadgeStyle: {
            backgroundColor: colors.status.error,
            fontSize: 10,
            minWidth: 18,
            maxHeight: 18,
          },
          headerTitle: isEssentials ? 'Your AI Home Manager' : 'Your Home Manager',
        }}
      />
      <Tabs.Screen
        name="messages"
        options={{
          title: 'Messages',
          tabBarIcon: ({ color, size }) => (
            <Ionicons name="chatbubbles-outline" size={size} color={color} />
          ),
          tabBarBadge: unreadMessages > 0 ? unreadMessages : undefined,
          tabBarBadgeStyle: {
            backgroundColor: colors.status.error,
            fontSize: 10,
            minWidth: 18,
            maxHeight: 18,
          },
          headerTitle: 'Messages',
        }}
      />
      <Tabs.Screen
        name="billing"
        options={{
          title: 'Money',
          tabBarIcon: ({ color, size }) => (
            <Ionicons name="wallet-outline" size={size} color={color} />
          ),
          headerTitle: 'Financial',
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
        }}
      />

      {/* ===== HIDDEN SCREENS (accessible via navigation, not in tab bar) ===== */}

      {/* Top-level hidden screens */}
      <Tabs.Screen name="approvals" options={{ href: null, headerTitle: 'Approvals', headerLeft: () => <BackButton /> }} />
      <Tabs.Screen name="maintenance" options={{ href: null, headerTitle: 'Maintenance', headerLeft: () => <BackButton /> }} />
      <Tabs.Screen name="vault" options={{ href: null, headerTitle: 'Document Vault', headerLeft: () => <BackButton /> }} />
      <Tabs.Screen name="family" options={{ href: null, headerTitle: 'Family & Household', headerLeft: () => <BackButton /> }} />
      <Tabs.Screen name="settings" options={{ href: null, headerTitle: 'Settings', headerLeft: () => <BackButton /> }} />
      <Tabs.Screen name="profile" options={{ href: null, headerTitle: 'Profile', headerLeft: () => <BackButton /> }} />
      <Tabs.Screen name="chat" options={{ href: null, headerTitle: 'Chat', headerLeft: () => <BackButton /> }} />
      <Tabs.Screen name="wallet" options={{ href: null, headerTitle: 'Wallet', headerLeft: () => <BackButton /> }} />
      <Tabs.Screen name="new-request" options={{ href: null, headerTitle: 'New Request', headerLeft: () => <BackButton /> }} />
      <Tabs.Screen name="sarah" options={{ href: null, headerShown: false }} />

      {/* Sarah sub-routes (Premium) */}
      <Tabs.Screen name="sarah/chat" options={{ href: null, headerTitle: 'Chat with Sarah', headerLeft: () => <BackButton /> }} />
      <Tabs.Screen name="sarah/new-request" options={{ href: null, headerTitle: 'New Request', headerLeft: () => <BackButton /> }} />
      <Tabs.Screen name="sarah/requests" options={{ href: null, headerTitle: 'Requests', headerLeft: () => <BackButton /> }} />

      {/* Manager sub-routes (Alfred or Sarah) */}
      <Tabs.Screen name="manager/chat" options={{ href: null, headerTitle: isEssentials ? 'Chat with Alfred' : 'Chat with Sarah', headerLeft: () => <BackButton /> }} />
      <Tabs.Screen name="manager/requests" options={{ href: null, headerTitle: 'Requests', headerLeft: () => <BackButton /> }} />
      <Tabs.Screen name="manager/new-request" options={{ href: null, headerTitle: 'New Request', headerLeft: () => <BackButton /> }} />
      <Tabs.Screen name="manager/checklist" options={{ href: null, headerTitle: 'Maintenance Checklist', headerLeft: () => <BackButton /> }} />
      <Tabs.Screen name="manager/handyman" options={{ href: null, headerTitle: 'Book Handyman', headerLeft: () => <BackButton /> }} />
      <Tabs.Screen name="manager/vendors" options={{ href: null, headerTitle: 'Vendors', headerLeft: () => <BackButton /> }} />

      {/* Messages sub-routes */}
      <Tabs.Screen name="messages/[id]" options={{ href: null, headerTitle: 'Conversation', headerLeft: () => <BackButton /> }} />

      {/* Approvals sub-routes */}
      <Tabs.Screen name="approvals/[id]" options={{ href: null, headerTitle: 'Approval Details', headerLeft: () => <BackButton /> }} />

      {/* Maintenance sub-routes */}
      <Tabs.Screen name="maintenance/[id]" options={{ href: null, headerTitle: 'Task Details', headerLeft: () => <BackButton /> }} />
      <Tabs.Screen name="maintenance/edit/[id]" options={{ href: null, headerTitle: 'Edit Task', headerLeft: () => <BackButton /> }} />
      <Tabs.Screen name="maintenance/upload-photo/[id]" options={{ href: null, headerTitle: 'Upload Photo', headerLeft: () => <BackButton /> }} />

      {/* Vault sub-routes */}
      <Tabs.Screen name="vault/[id]" options={{ href: null, headerTitle: 'Document', headerLeft: () => <BackButton /> }} />
      <Tabs.Screen name="vault/upload" options={{ href: null, headerTitle: 'Upload Document', headerLeft: () => <BackButton /> }} />

      {/* Family sub-routes */}
      <Tabs.Screen name="family/member/[id]" options={{ href: null, headerTitle: 'Family Member', headerLeft: () => <BackButton /> }} />
      <Tabs.Screen name="family/member/edit/[id]" options={{ href: null, headerTitle: 'Edit Member', headerLeft: () => <BackButton /> }} />
      <Tabs.Screen name="family/vehicle/[id]" options={{ href: null, headerTitle: 'Vehicle', headerLeft: () => <BackButton /> }} />
      <Tabs.Screen name="family/vehicle/edit/[id]" options={{ href: null, headerTitle: 'Edit Vehicle', headerLeft: () => <BackButton /> }} />
      <Tabs.Screen name="family/pet/[id]" options={{ href: null, headerTitle: 'Pet', headerLeft: () => <BackButton /> }} />
      <Tabs.Screen name="family/staff/[id]" options={{ href: null, headerTitle: 'Staff Member', headerLeft: () => <BackButton /> }} />

      {/* Profile sub-routes */}
      <Tabs.Screen name="profile/edit" options={{ href: null, headerTitle: 'Edit Profile', headerLeft: () => <BackButton /> }} />
    </Tabs>
  );
}

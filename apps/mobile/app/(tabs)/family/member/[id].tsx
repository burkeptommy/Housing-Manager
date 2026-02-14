import React, { useState, useEffect, useCallback } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Alert,
  RefreshControl,
  Linking,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useLocalSearchParams, useRouter, Stack } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { useAuth } from '../../../../src/contexts/auth-context';
import { Card, Badge, LoadingSpinner } from '../../../../src/components';
import { ProfilePhotoEditor } from '../../../../src/components/ProfilePhotoEditor';
import { colors, typography, spacing, borderRadius } from '../../../../src/lib/theme';
import { API_BASE_URL } from '../../../../src/lib/api';
import { getIdToken } from '../../../../src/lib/firebase';
import { EditMemberContactModal } from '../../../../src/components/forms/EditMemberContactModal';
import { EditEmergencyContactModal } from '../../../../src/components/forms/EditEmergencyContactModal';
import { EditMedicalInfoModal } from '../../../../src/components/forms/EditMedicalInfoModal';
import { EditSchoolModal } from '../../../../src/components/forms/EditSchoolModal';
import { EditActivityModal, ActivityData } from '../../../../src/components/forms/EditActivityModal';
import { EditWorkModal } from '../../../../src/components/forms/EditWorkModal';
import { EditMembershipModal, MembershipData } from '../../../../src/components/forms/EditMembershipModal';

// Helper function to get icon for activity type
const getActivityIcon = (type: string): keyof typeof Ionicons.glyphMap => {
  const typeLC = type.toLowerCase();
  if (typeLC.includes('sport') || typeLC.includes('soccer') || typeLC.includes('basketball') || typeLC.includes('baseball')) {
    return 'football-outline';
  }
  if (typeLC.includes('swim')) {
    return 'water-outline';
  }
  if (typeLC.includes('music') || typeLC.includes('piano') || typeLC.includes('guitar')) {
    return 'musical-notes-outline';
  }
  if (typeLC.includes('dance') || typeLC.includes('ballet')) {
    return 'body-outline';
  }
  if (typeLC.includes('art') || typeLC.includes('paint')) {
    return 'color-palette-outline';
  }
  if (typeLC.includes('school') || typeLC.includes('tutor') || typeLC.includes('class')) {
    return 'school-outline';
  }
  if (typeLC.includes('camp')) {
    return 'bonfire-outline';
  }
  if (typeLC.includes('gym') || typeLC.includes('fitness')) {
    return 'barbell-outline';
  }
  if (typeLC.includes('club')) {
    return 'people-outline';
  }
  if (typeLC.includes('martial') || typeLC.includes('karate') || typeLC.includes('taekwondo')) {
    return 'hand-left-outline';
  }
  return 'star-outline';
};

interface Activity {
  id: string;
  name: string;
  type: string;
  schedule?: string | null;
  location?: string | null;
}

interface Membership {
  id: string;
  name: string;
  type: 'gym' | 'country_club' | 'social_club' | 'professional' | 'other';
  memberNumber?: string;
  expiresAt?: string;
  monthlyFee?: number;
  notes?: string;
}

interface MemberDetail {
  id: string;
  firstName: string;
  lastName: string;
  nickname?: string | null;
  relationship?: string | null;
  email?: string | null;
  phone?: string | null;
  birthDate?: string | null;
  type?: string; // ADULT, CHILD, STAFF
  profilePhotoUrl?: string | null;
  // Child-specific fields
  age?: number | null;
  school?: string | null;
  schoolGrade?: string | null;
  teacher?: string | null;
  schoolPhone?: string | null;
  busNumber?: string | null;
  pickupTime?: string | null;
  dropoffTime?: string | null;
  activities?: Activity[];
  // Adult-specific - Work
  occupation?: string | null;
  employer?: string | null;
  workPhone?: string | null;
  workEmail?: string | null;
  workAddress?: string | null;
  workSchedule?: string | null;
  // Memberships (adults)
  memberships?: Membership[];
  // Medical Information
  primaryDoctorName?: string | null;
  primaryDoctorPhone?: string | null;
  primaryDoctorAddress?: string | null;
  dentistName?: string | null;
  dentistPhone?: string | null;
  dentistAddress?: string | null;
  bloodType?: string | null;
  allergies?: string[];
  medications?: string[];
  specialNeeds?: string | null;
  medicalNotes?: string | null;
  insuranceProvider?: string | null;
  insuranceMemberId?: string | null;
  // Emergency contacts
  emergencyContact?: string | null;
  emergencyContactPhone?: string | null;
  emergencyContactRelationship?: string | null;
  // Preferences
  dietaryRestrictions?: string[];
  clothingSize?: string | null;
  shoeSize?: string | null;
  interests?: string[];
  notes?: string | null;
}

export default function MemberDetailScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const router = useRouter();
  const { householdInfo, user } = useAuth();
  const [member, setMember] = useState<MemberDetail | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Permission check: Can the current user edit this family member?
  // OWNER can edit anyone, regular members can only edit their own profile
  const isOwner = householdInfo?.role === 'OWNER';
  const isOwnProfile = user?.email && member?.email &&
    user.email.toLowerCase() === member.email.toLowerCase();
  const canEdit = isOwner || isOwnProfile;
  const canDelete = isOwner; // Only owner can delete

  // Modal states
  const [showContactModal, setShowContactModal] = useState(false);
  const [showEmergencyModal, setShowEmergencyModal] = useState(false);
  const [showMedicalModal, setShowMedicalModal] = useState(false);
  const [showSchoolModal, setShowSchoolModal] = useState(false);
  const [showActivityModal, setShowActivityModal] = useState(false);
  const [showWorkModal, setShowWorkModal] = useState(false);
  const [showMembershipModal, setShowMembershipModal] = useState(false);
  const [editingActivity, setEditingActivity] = useState<Activity | null>(null);
  const [editingMembership, setEditingMembership] = useState<Membership | null>(null);

  const fetchMember = useCallback(async () => {
    if (!id || !householdInfo?.id) return;

    try {
      const token = await getIdToken(true);
      if (!token) {
        setError('Authentication expired.');
        setIsLoading(false);
        return;
      }

      const response = await fetch(
        `${API_BASE_URL}/family/household/${householdInfo.id}/member/${id}`,
        {
          headers: {
            Authorization: `Bearer ${token}`,
            'Content-Type': 'application/json',
          },
        }
      );

      if (!response.ok) {
        throw new Error(`Failed to fetch member: ${response.status}`);
      }

      const data: MemberDetail = await response.json();
      setMember(data);
      setError(null);
    } catch (err) {
      console.error('Fetch member error:', err);
      setError('Failed to load member details.');
    } finally {
      setIsLoading(false);
      setIsRefreshing(false);
    }
  }, [id, householdInfo?.id]);

  useEffect(() => {
    fetchMember();
  }, [fetchMember]);

  const handleCall = () => {
    if (member?.phone) {
      Linking.openURL(`tel:${member.phone}`);
    }
  };

  const handleEmail = () => {
    if (member?.email) {
      Linking.openURL(`mailto:${member.email}`);
    }
  };

  const handleDelete = async () => {
    Alert.alert(
      'Remove Member',
      'Are you sure you want to remove this family member? This cannot be undone.',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Remove',
          style: 'destructive',
          onPress: async () => {
            try {
              const token = await getIdToken(true);
              if (!token) {
                Alert.alert('Error', 'Authentication expired.');
                return;
              }

              const response = await fetch(
                `${API_BASE_URL}/family/household/${householdInfo?.id}/member/${id}`,
                {
                  method: 'DELETE',
                  headers: {
                    Authorization: `Bearer ${token}`,
                  },
                }
              );

              if (!response.ok) throw new Error('Failed to delete');

              Alert.alert('Removed', 'Family member has been removed.');
              router.back();
            } catch (err) {
              Alert.alert('Error', 'Failed to remove family member.');
            }
          },
        },
      ]
    );
  };

  const formatDate = (dateString?: string | null) => {
    if (!dateString) return null;
    return new Date(dateString).toLocaleDateString('en-US', {
      month: 'long',
      day: 'numeric',
      year: 'numeric',
    });
  };

  const isChild = member?.type === 'CHILD' || member?.age !== undefined || member?.school !== undefined;
  const isAdult = member?.type === 'ADULT' || (!isChild && member?.type !== 'STAFF');

  const handleEditSection = (section: string) => {
    switch (section) {
      case 'contact':
        setShowContactModal(true);
        break;
      case 'emergency':
        setShowEmergencyModal(true);
        break;
      case 'medical':
        setShowMedicalModal(true);
        break;
      case 'school':
        setShowSchoolModal(true);
        break;
      case 'activities':
        setEditingActivity(null); // New activity
        setShowActivityModal(true);
        break;
      case 'work':
        setShowWorkModal(true);
        break;
      case 'memberships':
        setEditingMembership(null); // New membership
        setShowMembershipModal(true);
        break;
      default:
        // For sections without focused modals, go to full edit page
        router.push(`/(tabs)/family/member/edit/${id}` as any);
    }
  };

  // Save handlers for focused modals
  const handleSaveContact = async (data: {
    phone?: string | null;
    email?: string | null;
    birthDate?: string | null;
  }) => {
    const token = await getIdToken(true);
    if (!token) throw new Error('Authentication expired');

    const response = await fetch(
      `${API_BASE_URL}/family/household/${householdInfo?.id}/member/${id}`,
      {
        method: 'PATCH',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(data),
      }
    );

    if (!response.ok) throw new Error('Failed to save');
    await fetchMember();
  };

  const handleSaveEmergencyContact = async (data: {
    emergencyContact?: string | null;
    emergencyContactPhone?: string | null;
    emergencyContactRelationship?: string | null;
  }) => {
    const token = await getIdToken(true);
    if (!token) throw new Error('Authentication expired');

    const response = await fetch(
      `${API_BASE_URL}/family/household/${householdInfo?.id}/member/${id}`,
      {
        method: 'PATCH',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(data),
      }
    );

    if (!response.ok) throw new Error('Failed to save');
    await fetchMember();
  };

  const handleSaveMedical = async (data: {
    primaryDoctorName?: string | null;
    primaryDoctorPhone?: string | null;
    bloodType?: string | null;
    insuranceProvider?: string | null;
    insuranceMemberId?: string | null;
  }) => {
    const token = await getIdToken(true);
    if (!token) throw new Error('Authentication expired');

    const response = await fetch(
      `${API_BASE_URL}/family/household/${householdInfo?.id}/member/${id}`,
      {
        method: 'PATCH',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(data),
      }
    );

    if (!response.ok) throw new Error('Failed to save');
    await fetchMember();
  };

  const handleSaveSchool = async (data: {
    school?: string | null;
    schoolGrade?: string | null;
    teacher?: string | null;
    schoolPhone?: string | null;
    busNumber?: string | null;
    pickupTime?: string | null;
    dropoffTime?: string | null;
  }) => {
    const token = await getIdToken(true);
    if (!token) throw new Error('Authentication expired');

    const response = await fetch(
      `${API_BASE_URL}/family/household/${householdInfo?.id}/member/${id}`,
      {
        method: 'PATCH',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(data),
      }
    );

    if (!response.ok) throw new Error('Failed to save');
    await fetchMember();
  };

  const handleSaveActivity = async (data: ActivityData) => {
    const token = await getIdToken(true);
    if (!token) throw new Error('Authentication expired');

    const endpoint = data.id
      ? `${API_BASE_URL}/family/household/${householdInfo?.id}/member/${id}/activity/${data.id}`
      : `${API_BASE_URL}/family/household/${householdInfo?.id}/member/${id}/activity`;

    const response = await fetch(endpoint, {
      method: data.id ? 'PATCH' : 'POST',
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(data),
    });

    if (!response.ok) throw new Error('Failed to save');
    await fetchMember();
  };

  const handleDeleteActivity = async (activityId: string) => {
    const token = await getIdToken(true);
    if (!token) throw new Error('Authentication expired');

    const response = await fetch(
      `${API_BASE_URL}/family/household/${householdInfo?.id}/member/${id}/activity/${activityId}`,
      {
        method: 'DELETE',
        headers: { Authorization: `Bearer ${token}` },
      }
    );

    if (!response.ok) throw new Error('Failed to delete');
    await fetchMember();
  };

  const handleSaveWork = async (data: {
    employer?: string | null;
    occupation?: string | null;
    workPhone?: string | null;
    workEmail?: string | null;
    workAddress?: string | null;
    workSchedule?: string | null;
  }) => {
    const token = await getIdToken(true);
    if (!token) throw new Error('Authentication expired');

    const response = await fetch(
      `${API_BASE_URL}/family/household/${householdInfo?.id}/member/${id}`,
      {
        method: 'PATCH',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(data),
      }
    );

    if (!response.ok) throw new Error('Failed to save');
    await fetchMember();
  };

  const handleSaveMembership = async (data: MembershipData) => {
    const token = await getIdToken(true);
    if (!token) throw new Error('Authentication expired');

    const endpoint = data.id
      ? `${API_BASE_URL}/family/household/${householdInfo?.id}/member/${id}/membership/${data.id}`
      : `${API_BASE_URL}/family/household/${householdInfo?.id}/member/${id}/membership`;

    const response = await fetch(endpoint, {
      method: data.id ? 'PATCH' : 'POST',
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(data),
    });

    if (!response.ok) throw new Error('Failed to save');
    await fetchMember();
  };

  const handleDeleteMembership = async (membershipId: string) => {
    const token = await getIdToken(true);
    if (!token) throw new Error('Authentication expired');

    const response = await fetch(
      `${API_BASE_URL}/family/household/${householdInfo?.id}/member/${id}/membership/${membershipId}`,
      {
        method: 'DELETE',
        headers: { Authorization: `Bearer ${token}` },
      }
    );

    if (!response.ok) throw new Error('Failed to delete');
    await fetchMember();
  };

  // Section Header component
  const SectionHeader = ({ title, action, onAction }: { title: string; action?: string; onAction?: () => void }) => (
    <View style={styles.sectionHeader}>
      <Text style={styles.sectionTitle}>{title}</Text>
      {action && onAction && (
        <TouchableOpacity onPress={onAction}>
          <Text style={styles.sectionAction}>{action}</Text>
        </TouchableOpacity>
      )}
    </View>
  );

  // Info Row component
  const InfoRow = ({ icon, label, value, onPress }: { icon: keyof typeof Ionicons.glyphMap; label: string; value?: string | null; onPress?: () => void }) => {
    if (!value) return null;
    const content = (
      <View style={styles.detailRow}>
        <Ionicons name={icon} size={18} color={colors.text.tertiary} />
        <View style={styles.detailContent}>
          <Text style={styles.detailLabel}>{label}</Text>
          <Text style={[styles.detailValue, onPress && styles.linkText]}>{value}</Text>
        </View>
      </View>
    );
    return onPress ? <TouchableOpacity onPress={onPress}>{content}</TouchableOpacity> : content;
  };

  // Empty prompt component
  const EmptyPrompt = ({ text, onPress }: { text: string; onPress: () => void }) => (
    <TouchableOpacity style={styles.emptyPrompt} onPress={onPress}>
      <Ionicons name="add-circle-outline" size={20} color={colors.haven.purple[500]} />
      <Text style={styles.emptyPromptText}>{text}</Text>
    </TouchableOpacity>
  );

  const getMembershipIcon = (type: string): keyof typeof Ionicons.glyphMap => {
    switch (type) {
      case 'gym': return 'barbell-outline';
      case 'country_club': return 'golf-outline';
      case 'social_club': return 'people-outline';
      case 'professional': return 'briefcase-outline';
      default: return 'card-outline';
    }
  };

  if (isLoading) {
    return <LoadingSpinner fullScreen message="Loading member..." />;
  }

  if (error || !member) {
    return (
      <SafeAreaView style={styles.container} edges={['bottom']}>
        <Stack.Screen options={{ title: 'Family Member' }} />
        <View style={styles.errorContainer}>
          <Ionicons name="alert-circle" size={48} color={colors.status.error} />
          <Text style={styles.errorTitle}>Unable to Load Member</Text>
          <Text style={styles.errorText}>{error || 'Member not found'}</Text>
          <TouchableOpacity style={styles.retryButton} onPress={fetchMember}>
            <Text style={styles.retryText}>Try Again</Text>
          </TouchableOpacity>
        </View>
      </SafeAreaView>
    );
  }

  const fullName = `${member.firstName} ${member.lastName}`;
  const initials = `${member.firstName?.[0] || ''}${member.lastName?.[0] || ''}`;

  return (
    <SafeAreaView style={styles.container} edges={['bottom']}>
      <Stack.Screen
        options={{
          title: fullName,
          headerRight: canEdit ? () => (
            <TouchableOpacity onPress={() => router.push(`/(tabs)/family/member/edit/${id}` as any)}>
              <Ionicons name="create-outline" size={24} color={colors.haven.purple[500]} />
            </TouchableOpacity>
          ) : undefined,
        }}
      />
      <ScrollView
        contentContainerStyle={styles.scrollContent}
        refreshControl={
          <RefreshControl
            refreshing={isRefreshing}
            onRefresh={() => {
              setIsRefreshing(true);
              fetchMember();
            }}
          />
        }
      >
        {/* Profile Header */}
        <Card style={styles.profileCard}>
          <View style={styles.photoSection}>
            <ProfilePhotoEditor
              currentUrl={member.profilePhotoUrl}
              entityType="family-member"
              entityId={member.id}
              size={100}
              name={fullName}
              onPhotoUpdated={(url) => {
                setMember({ ...member, profilePhotoUrl: url });
              }}
            />
            <Text style={styles.photoHint}>Tap to change photo</Text>
          </View>
          <Text style={styles.fullName}>{fullName}</Text>
          {member.nickname && (
            <Text style={styles.nickname}>"{member.nickname}"</Text>
          )}
          <View style={styles.badgeRow}>
            <Badge
              label={member.relationship || (isChild ? 'Child' : 'Adult')}
              variant="default"
            />
            {isChild && member.age && (
              <Badge label={`Age ${member.age}`} variant="info" />
            )}
          </View>
        </Card>

        {/* Contact Actions */}
        {(member.phone || member.email) && (
          <View style={styles.actionButtons}>
            {member.phone && (
              <TouchableOpacity style={styles.actionButton} onPress={handleCall}>
                <View style={styles.actionIcon}>
                  <Ionicons name="call" size={24} color={colors.haven.purple[500]} />
                </View>
                <Text style={styles.actionButtonText}>Call</Text>
              </TouchableOpacity>
            )}
            {member.email && (
              <TouchableOpacity style={styles.actionButton} onPress={handleEmail}>
                <View style={styles.actionIcon}>
                  <Ionicons name="mail" size={24} color={colors.haven.purple[500]} />
                </View>
                <Text style={styles.actionButtonText}>Email</Text>
              </TouchableOpacity>
            )}
          </View>
        )}

        {/* Contact Info */}
        <Card style={styles.section}>
          <SectionHeader title="CONTACT INFORMATION" action={canEdit ? "Edit" : undefined} onAction={canEdit ? () => handleEditSection('contact') : undefined} />
          <InfoRow icon="call-outline" label="Phone" value={member.phone} onPress={member.phone ? handleCall : undefined} />
          <InfoRow icon="mail-outline" label="Email" value={member.email} onPress={member.email ? handleEmail : undefined} />
          <InfoRow icon="calendar-outline" label="Birthday" value={formatDate(member.birthDate)} />
          {canEdit && !member.phone && !member.email && !member.birthDate && (
            <EmptyPrompt text="Add contact information" onPress={() => handleEditSection('contact')} />
          )}
        </Card>

        {/* Allergies Alert - Prominent if present */}
        {member.allergies && member.allergies.length > 0 && (
          <Card style={[styles.section, styles.alertCard]}>
            <View style={styles.allergyHeader}>
              <Ionicons name="warning" size={20} color={colors.status.error} />
              <Text style={styles.allergyTitle}>ALLERGIES</Text>
            </View>
            {member.allergies.map((allergy, index) => (
              <Text key={index} style={styles.allergyItem}>• {allergy}</Text>
            ))}
          </Card>
        )}

        {/* School Info (Children) */}
        {isChild && (
          <Card style={styles.section}>
            <SectionHeader title="SCHOOL" action={canEdit ? "Edit" : undefined} onAction={canEdit ? () => handleEditSection('school') : undefined} />
            {member.school || member.schoolGrade ? (
              <>
                <InfoRow icon="school-outline" label="School" value={member.school} />
                <InfoRow icon="ribbon-outline" label="Grade" value={member.schoolGrade} />
                <InfoRow icon="person-outline" label="Teacher" value={member.teacher} />
                <InfoRow icon="bus-outline" label="Bus #" value={member.busNumber} />
                <InfoRow icon="time-outline" label="Drop-off" value={member.dropoffTime} />
                <InfoRow icon="time-outline" label="Pickup" value={member.pickupTime} />
                <InfoRow icon="call-outline" label="School Phone" value={member.schoolPhone} onPress={member.schoolPhone ? () => Linking.openURL(`tel:${member.schoolPhone}`) : undefined} />
              </>
            ) : canEdit ? (
              <EmptyPrompt text="Add school information" onPress={() => handleEditSection('school')} />
            ) : null}
          </Card>
        )}

        {/* Activities (for children - sports, activities) */}
        {isChild && (
          <Card style={styles.section}>
            <SectionHeader title="ACTIVITIES & SPORTS" action={canEdit ? "+ Add" : undefined} onAction={canEdit ? () => handleEditSection('activities') : undefined} />
            {member.activities && member.activities.length > 0 ? (
              member.activities.map((activity) => (
                <TouchableOpacity
                  key={activity.id}
                  style={styles.activityItem}
                  onPress={canEdit ? () => {
                    setEditingActivity(activity);
                    setShowActivityModal(true);
                  } : undefined}
                  disabled={!canEdit}
                >
                  <View style={styles.activityIcon}>
                    <Ionicons
                      name={getActivityIcon(activity.type)}
                      size={16}
                      color={colors.haven.purple[500]}
                    />
                  </View>
                  <View style={styles.activityInfo}>
                    <Text style={styles.activityName}>{activity.name}</Text>
                    <Text style={styles.activityType}>{activity.type}</Text>
                    {activity.schedule && (
                      <Text style={styles.activitySchedule}>{activity.schedule}</Text>
                    )}
                    {activity.location && (
                      <Text style={styles.activityLocation}>{activity.location}</Text>
                    )}
                  </View>
                  {canEdit && <Ionicons name="chevron-forward" size={16} color={colors.text.tertiary} />}
                </TouchableOpacity>
              ))
            ) : canEdit ? (
              <EmptyPrompt text="Add activities and sports" onPress={() => handleEditSection('activities')} />
            ) : (
              <Text style={styles.emptyText}>No activities added</Text>
            )}
          </Card>
        )}

        {/* Work Info (Adults) */}
        {isAdult && (
          <Card style={styles.section}>
            <SectionHeader title="WORK" action={canEdit ? "Edit" : undefined} onAction={canEdit ? () => handleEditSection('work') : undefined} />
            {member.employer || member.occupation ? (
              <>
                <InfoRow icon="business-outline" label="Employer" value={member.employer} />
                <InfoRow icon="briefcase-outline" label="Title" value={member.occupation} />
                <InfoRow icon="call-outline" label="Work Phone" value={member.workPhone} onPress={member.workPhone ? () => Linking.openURL(`tel:${member.workPhone}`) : undefined} />
                <InfoRow icon="mail-outline" label="Work Email" value={member.workEmail} onPress={member.workEmail ? () => Linking.openURL(`mailto:${member.workEmail}`) : undefined} />
                <InfoRow icon="location-outline" label="Office" value={member.workAddress} />
                <InfoRow icon="time-outline" label="Schedule" value={member.workSchedule} />
              </>
            ) : canEdit ? (
              <EmptyPrompt text="Add work information" onPress={() => handleEditSection('work')} />
            ) : null}
          </Card>
        )}

        {/* Memberships (Adults) */}
        {isAdult && (
          <Card style={styles.section}>
            <SectionHeader title="MEMBERSHIPS" action={canEdit ? "+ Add" : undefined} onAction={canEdit ? () => handleEditSection('memberships') : undefined} />
            {member.memberships && member.memberships.length > 0 ? (
              member.memberships.map((membership) => (
                <TouchableOpacity
                  key={membership.id}
                  style={styles.membershipRow}
                  onPress={canEdit ? () => {
                    setEditingMembership(membership);
                    setShowMembershipModal(true);
                  } : undefined}
                  disabled={!canEdit}
                >
                  <View style={styles.membershipIcon}>
                    <Ionicons name={getMembershipIcon(membership.type)} size={18} color={colors.haven.purple[500]} />
                  </View>
                  <View style={styles.membershipInfo}>
                    <Text style={styles.membershipName}>{membership.name}</Text>
                    {membership.memberNumber && (
                      <Text style={styles.membershipNumber}>Member #{membership.memberNumber}</Text>
                    )}
                    {membership.monthlyFee && (
                      <Text style={styles.membershipFee}>${membership.monthlyFee}/month</Text>
                    )}
                  </View>
                  {canEdit && <Ionicons name="chevron-forward" size={16} color={colors.text.tertiary} />}
                </TouchableOpacity>
              ))
            ) : canEdit ? (
              <EmptyPrompt text="Add gym, club, or other memberships" onPress={() => handleEditSection('memberships')} />
            ) : (
              <Text style={styles.emptyText}>No memberships added</Text>
            )}
          </Card>
        )}

        {/* Activities/Memberships (Adults - clubs, gyms) */}
        {isAdult && member.activities && member.activities.length > 0 && (
          <Card style={styles.section}>
            <SectionHeader title="ACTIVITIES" action={canEdit ? "+ Add" : undefined} onAction={canEdit ? () => handleEditSection('activities') : undefined} />
            {member.activities.map((activity) => (
              <TouchableOpacity
                key={activity.id}
                style={styles.activityItem}
                onPress={canEdit ? () => {
                  setEditingActivity(activity);
                  setShowActivityModal(true);
                } : undefined}
                disabled={!canEdit}
              >
                <View style={styles.activityIcon}>
                  <Ionicons
                    name={getActivityIcon(activity.type)}
                    size={16}
                    color={colors.haven.purple[500]}
                  />
                </View>
                <View style={styles.activityInfo}>
                  <Text style={styles.activityName}>{activity.name}</Text>
                  <Text style={styles.activityType}>{activity.type}</Text>
                  {activity.schedule && (
                    <Text style={styles.activitySchedule}>{activity.schedule}</Text>
                  )}
                  {activity.location && (
                    <Text style={styles.activityLocation}>{activity.location}</Text>
                  )}
                </View>
                {canEdit && <Ionicons name="chevron-forward" size={16} color={colors.text.tertiary} />}
              </TouchableOpacity>
            ))}
          </Card>
        )}

        {/* Emergency Contact */}
        <Card style={styles.section}>
          <SectionHeader title="EMERGENCY CONTACT" action={canEdit ? "Edit" : undefined} onAction={canEdit ? () => handleEditSection('emergency') : undefined} />
          {member.emergencyContact ? (
            <>
              <InfoRow icon="person-outline" label="Name" value={member.emergencyContact} />
              <InfoRow icon="people-outline" label="Relationship" value={member.emergencyContactRelationship} />
              <InfoRow icon="call-outline" label="Phone" value={member.emergencyContactPhone} onPress={member.emergencyContactPhone ? () => Linking.openURL(`tel:${member.emergencyContactPhone}`) : undefined} />
            </>
          ) : canEdit ? (
            <EmptyPrompt text="Add emergency contact" onPress={() => handleEditSection('emergency')} />
          ) : (
            <Text style={styles.emptyText}>No emergency contact added</Text>
          )}
        </Card>

        {/* Medical Information */}
        <Card style={styles.section}>
          <SectionHeader title="MEDICAL INFORMATION" action={canEdit ? "Edit" : undefined} onAction={canEdit ? () => handleEditSection('medical') : undefined} />
          {member.primaryDoctorName || member.bloodType || member.insuranceProvider ? (
            <>
              <InfoRow icon="medkit-outline" label="Primary Doctor" value={member.primaryDoctorName} />
              <InfoRow icon="call-outline" label="Doctor Phone" value={member.primaryDoctorPhone} onPress={member.primaryDoctorPhone ? () => Linking.openURL(`tel:${member.primaryDoctorPhone}`) : undefined} />
              <InfoRow icon="water-outline" label="Blood Type" value={member.bloodType} />
              <InfoRow icon="shield-outline" label="Insurance" value={member.insuranceProvider} />
              <InfoRow icon="card-outline" label="Member ID" value={member.insuranceMemberId} />
              {member.medications && member.medications.length > 0 && (
                <View style={styles.detailRow}>
                  <Ionicons name="medical-outline" size={18} color={colors.text.tertiary} />
                  <View style={styles.detailContent}>
                    <Text style={styles.detailLabel}>Medications</Text>
                    <Text style={styles.detailValue}>{member.medications.join(', ')}</Text>
                  </View>
                </View>
              )}
            </>
          ) : canEdit ? (
            <EmptyPrompt text="Add medical information" onPress={() => handleEditSection('medical')} />
          ) : (
            <Text style={styles.emptyText}>No medical information added</Text>
          )}
        </Card>

        {/* Preferences (optional) */}
        {(member.dietaryRestrictions?.length || member.clothingSize || member.interests?.length) && (
          <Card style={styles.section}>
            <SectionHeader title="PREFERENCES" action={canEdit ? "Edit" : undefined} onAction={canEdit ? () => handleEditSection('preferences') : undefined} />
            {member.dietaryRestrictions && member.dietaryRestrictions.length > 0 && (
              <View style={styles.detailRow}>
                <Ionicons name="restaurant-outline" size={18} color={colors.text.tertiary} />
                <View style={styles.detailContent}>
                  <Text style={styles.detailLabel}>Dietary</Text>
                  <Text style={styles.detailValue}>{member.dietaryRestrictions.join(', ')}</Text>
                </View>
              </View>
            )}
            <InfoRow icon="shirt-outline" label="Clothing Size" value={member.clothingSize} />
            <InfoRow icon="footsteps-outline" label="Shoe Size" value={member.shoeSize} />
            {member.interests && member.interests.length > 0 && (
              <View style={styles.detailRow}>
                <Ionicons name="heart-outline" size={18} color={colors.text.tertiary} />
                <View style={styles.detailContent}>
                  <Text style={styles.detailLabel}>Interests</Text>
                  <Text style={styles.detailValue}>{member.interests.join(', ')}</Text>
                </View>
              </View>
            )}
          </Card>
        )}

        {/* Danger Zone - Only show for household owner */}
        {canDelete && (
          <TouchableOpacity style={styles.deleteButton} onPress={handleDelete}>
            <Ionicons name="trash-outline" size={20} color={colors.status.error} />
            <Text style={styles.deleteButtonText}>Remove Family Member</Text>
          </TouchableOpacity>
        )}
      </ScrollView>

      {/* Focused Edit Modals */}
      <EditMemberContactModal
        visible={showContactModal}
        onClose={() => setShowContactModal(false)}
        onSave={handleSaveContact}
        initialData={{
          phone: member.phone,
          email: member.email,
          birthDate: member.birthDate,
        }}
      />

      <EditEmergencyContactModal
        visible={showEmergencyModal}
        onClose={() => setShowEmergencyModal(false)}
        onSave={handleSaveEmergencyContact}
        initialData={{
          emergencyContact: member.emergencyContact,
          emergencyContactPhone: member.emergencyContactPhone,
          emergencyContactRelationship: member.emergencyContactRelationship,
        }}
      />

      <EditMedicalInfoModal
        visible={showMedicalModal}
        onClose={() => setShowMedicalModal(false)}
        onSave={handleSaveMedical}
        initialData={{
          primaryDoctorName: member.primaryDoctorName,
          primaryDoctorPhone: member.primaryDoctorPhone,
          bloodType: member.bloodType,
          insuranceProvider: member.insuranceProvider,
          insuranceMemberId: member.insuranceMemberId,
        }}
      />

      <EditSchoolModal
        visible={showSchoolModal}
        onClose={() => setShowSchoolModal(false)}
        onSave={handleSaveSchool}
        initialData={{
          school: member.school,
          schoolGrade: member.schoolGrade,
          teacher: member.teacher,
          schoolPhone: member.schoolPhone,
          busNumber: member.busNumber,
          pickupTime: member.pickupTime,
          dropoffTime: member.dropoffTime,
        }}
      />

      <EditActivityModal
        visible={showActivityModal}
        onClose={() => {
          setShowActivityModal(false);
          setEditingActivity(null);
        }}
        onSave={handleSaveActivity}
        onDelete={handleDeleteActivity}
        initialData={editingActivity ? {
          id: editingActivity.id,
          name: editingActivity.name,
          type: editingActivity.type,
          location: editingActivity.location,
          schedule: editingActivity.schedule,
        } : null}
        isNew={!editingActivity}
      />

      <EditWorkModal
        visible={showWorkModal}
        onClose={() => setShowWorkModal(false)}
        onSave={handleSaveWork}
        initialData={{
          employer: member.employer,
          occupation: member.occupation,
          workPhone: member.workPhone,
          workEmail: member.workEmail,
          workAddress: member.workAddress,
          workSchedule: member.workSchedule,
        }}
      />

      <EditMembershipModal
        visible={showMembershipModal}
        onClose={() => {
          setShowMembershipModal(false);
          setEditingMembership(null);
        }}
        onSave={handleSaveMembership}
        onDelete={handleDeleteMembership}
        initialData={editingMembership ? {
          id: editingMembership.id,
          name: editingMembership.name,
          type: editingMembership.type,
          memberNumber: editingMembership.memberNumber,
          expiresAt: editingMembership.expiresAt,
          monthlyFee: editingMembership.monthlyFee,
          notes: editingMembership.notes,
        } : null}
        isNew={!editingMembership}
      />
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
    paddingBottom: spacing[8],
  },
  errorContainer: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    padding: spacing[6],
  },
  errorTitle: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
    marginTop: spacing[4],
  },
  errorText: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    textAlign: 'center',
    marginTop: spacing[2],
  },
  retryButton: {
    marginTop: spacing[4],
    paddingHorizontal: spacing[6],
    paddingVertical: spacing[3],
    backgroundColor: colors.haven.purple[500],
    borderRadius: borderRadius.lg,
  },
  retryText: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
    color: colors.white,
  },
  profileCard: {
    alignItems: 'center',
    padding: spacing[6],
    marginBottom: spacing[4],
  },
  photoSection: {
    alignItems: 'center',
    marginBottom: spacing[3],
  },
  photoHint: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
    marginTop: spacing[2],
  },
  fullName: {
    fontSize: typography.fontSizes.xl,
    fontWeight: typography.fontWeights.bold,
    color: colors.text.primary,
    marginBottom: spacing[1],
  },
  nickname: {
    fontSize: typography.fontSizes.base,
    color: colors.text.secondary,
    fontStyle: 'italic',
    marginBottom: spacing[2],
  },
  badgeRow: {
    flexDirection: 'row',
    gap: spacing[2],
  },
  actionButtons: {
    flexDirection: 'row',
    justifyContent: 'center',
    gap: spacing[6],
    marginBottom: spacing[4],
  },
  actionButton: {
    alignItems: 'center',
    gap: spacing[1],
  },
  actionIcon: {
    width: 56,
    height: 56,
    borderRadius: 28,
    backgroundColor: colors.haven.purple[50],
    alignItems: 'center',
    justifyContent: 'center',
  },
  actionButtonText: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    fontWeight: typography.fontWeights.medium,
  },
  section: {
    padding: spacing[4],
    marginBottom: spacing[4],
  },
  sectionHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: spacing[3],
  },
  sectionTitle: {
    fontSize: typography.fontSizes.xs,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.tertiary,
    textTransform: 'uppercase',
    letterSpacing: 0.5,
  },
  sectionAction: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.purple[500],
    fontWeight: typography.fontWeights.medium,
  },
  emptyPrompt: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: spacing[2],
    paddingVertical: spacing[4],
  },
  emptyPromptText: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.purple[500],
    fontWeight: typography.fontWeights.medium,
  },
  alertCard: {
    backgroundColor: colors.status.error + '10',
    borderWidth: 1,
    borderColor: colors.status.error + '30',
  },
  allergyHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[2],
    marginBottom: spacing[2],
  },
  allergyTitle: {
    fontSize: typography.fontSizes.xs,
    fontWeight: typography.fontWeights.bold,
    color: colors.status.error,
    textTransform: 'uppercase',
    letterSpacing: 0.5,
  },
  allergyItem: {
    fontSize: typography.fontSizes.base,
    color: colors.status.error,
    fontWeight: typography.fontWeights.medium,
    marginLeft: spacing[6],
    marginTop: spacing[1],
  },
  membershipRow: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: spacing[3],
    borderBottomWidth: 1,
    borderBottomColor: colors.border.light,
  },
  membershipIcon: {
    width: 36,
    height: 36,
    borderRadius: 18,
    backgroundColor: colors.haven.purple[50],
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: spacing[3],
  },
  membershipInfo: {
    flex: 1,
  },
  membershipName: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.primary,
  },
  membershipNumber: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
    marginTop: 2,
  },
  membershipFee: {
    fontSize: typography.fontSizes.xs,
    color: colors.haven.purple[600],
    marginTop: 2,
  },
  detailRow: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    paddingVertical: spacing[3],
    borderBottomWidth: 1,
    borderBottomColor: colors.border.light,
    gap: spacing[3],
  },
  detailContent: {
    flex: 1,
  },
  detailLabel: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
    marginBottom: 2,
  },
  detailValue: {
    fontSize: typography.fontSizes.base,
    color: colors.text.primary,
  },
  emptyText: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.tertiary,
    textAlign: 'center',
    paddingVertical: spacing[4],
  },
  activityItem: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    paddingVertical: spacing[3],
    borderBottomWidth: 1,
    borderBottomColor: colors.border.light,
  },
  activityIcon: {
    width: 32,
    height: 32,
    borderRadius: 16,
    backgroundColor: colors.haven.purple[50],
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: spacing[3],
  },
  activityInfo: {
    flex: 1,
  },
  activityName: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.primary,
  },
  activityType: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.purple[600],
    marginTop: 2,
  },
  activitySchedule: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
    marginTop: 2,
  },
  activityLocation: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
    marginTop: 2,
  },
  deleteButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: spacing[2],
    paddingVertical: spacing[4],
    marginTop: spacing[4],
  },
  deleteButtonText: {
    fontSize: typography.fontSizes.base,
    color: colors.status.error,
    fontWeight: typography.fontWeights.medium,
  },
  emptyValue: {
    fontSize: typography.fontSizes.base,
    color: colors.text.tertiary,
    fontStyle: 'italic',
  },
  linkText: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.purple[500],
    marginTop: 2,
  },
});

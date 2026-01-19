import React from 'react';
import { View, Text, StyleSheet, ViewStyle } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { Button } from './Button';
import { colors, typography, spacing } from '../../lib/theme';

interface EmptyStateProps {
  icon?: keyof typeof Ionicons.glyphMap;
  iconColor?: string;
  title: string;
  description?: string;
  actionLabel?: string;
  onAction?: () => void;
  secondaryActionLabel?: string;
  onSecondaryAction?: () => void;
  style?: ViewStyle;
}

export function EmptyState({
  icon = 'document-outline',
  iconColor = colors.haven.navy[300],
  title,
  description,
  actionLabel,
  onAction,
  secondaryActionLabel,
  onSecondaryAction,
  style,
}: EmptyStateProps) {
  return (
    <View style={[styles.container, style]}>
      <View style={styles.iconContainer}>
        <View style={styles.iconBackground}>
          <Ionicons name={icon} size={48} color={iconColor} />
        </View>
      </View>

      <Text style={styles.title}>
        {title}
      </Text>

      {description && (
        <Text style={styles.description}>
          {description}
        </Text>
      )}

      {actionLabel && onAction && (
        <View style={styles.actions}>
          <Button
            title={actionLabel}
            onPress={onAction}
            style={styles.button}
          />
          {secondaryActionLabel && onSecondaryAction && (
            <Button
              title={secondaryActionLabel}
              variant="outline"
              onPress={onSecondaryAction}
              style={styles.secondaryButton}
            />
          )}
        </View>
      )}
    </View>
  );
}

// Pre-built empty states for common scenarios
export function NoMessagesEmptyState({ onAction }: { onAction?: () => void }) {
  return (
    <EmptyState
      icon="chatbubbles-outline"
      title="No messages yet"
      description="Start a conversation with your home manager to get help with anything around your home."
      actionLabel="Send a Message"
      onAction={onAction}
    />
  );
}

export function NoApprovalsEmptyState() {
  return (
    <EmptyState
      icon="checkmark-done-circle-outline"
      iconColor={colors.status.success}
      title="All caught up!"
      description="You have no pending approvals. We'll notify you when something needs your attention."
    />
  );
}

export function NoMaintenanceEmptyState({ onAction }: { onAction?: () => void }) {
  return (
    <EmptyState
      icon="construct-outline"
      title="No maintenance tasks"
      description="Your home is in great shape! Schedule maintenance to keep it that way."
      actionLabel="Schedule Service"
      onAction={onAction}
    />
  );
}

export function NoDocumentsEmptyState({ onAction }: { onAction?: () => void }) {
  return (
    <EmptyState
      icon="folder-open-outline"
      title="No documents yet"
      description="Store important home documents like warranties, manuals, and contracts in your secure vault."
      actionLabel="Upload Document"
      onAction={onAction}
    />
  );
}

export function NoSearchResultsEmptyState({ query }: { query: string }) {
  return (
    <EmptyState
      icon="search-outline"
      title="No results found"
      description={`We couldn't find anything matching "${query}". Try adjusting your search.`}
    />
  );
}

export function ErrorEmptyState({ onRetry }: { onRetry?: () => void }) {
  return (
    <EmptyState
      icon="cloud-offline-outline"
      iconColor={colors.status.error}
      title="Something went wrong"
      description="We couldn't load this content. Please check your connection and try again."
      actionLabel="Try Again"
      onAction={onRetry}
    />
  );
}

// Bills Empty States
export function NoBillsEmptyState({ onAction, onSecondaryAction }: { onAction?: () => void; onSecondaryAction?: () => void }) {
  return (
    <EmptyState
      icon="card-outline"
      iconColor={colors.haven.champagne[500]}
      title="No bills detected yet"
      description="Connect your bank to auto-detect bills, or add them manually to track your home expenses."
      actionLabel="Connect Bank"
      onAction={onAction}
      secondaryActionLabel="Add Manually"
      onSecondaryAction={onSecondaryAction}
    />
  );
}

// Family Empty States
export function NoFamilyEmptyState({ onAction }: { onAction?: () => void }) {
  return (
    <EmptyState
      icon="people-outline"
      iconColor={colors.haven.champagne[500]}
      title="Add your household"
      description="Keep track of family members, their activities, medical info, and emergency contacts all in one place."
      actionLabel="Add Family Member"
      onAction={onAction}
    />
  );
}

// Vendors Empty States
export function NoVendorsEmptyState({ onAction }: { onAction?: () => void }) {
  return (
    <EmptyState
      icon="business-outline"
      iconColor={colors.haven.champagne[500]}
      title="No vendors added"
      description="Add your service providers like plumbers, electricians, and landscapers for quick access when you need them."
      actionLabel="Add Vendor"
      onAction={onAction}
    />
  );
}

// Home Systems Empty States
export function NoSystemsEmptyState({ onAction }: { onAction?: () => void }) {
  return (
    <EmptyState
      icon="construct-outline"
      iconColor={colors.haven.champagne[500]}
      title="No home systems documented"
      description="Add your HVAC, plumbing, and other systems to get maintenance reminders and track service history."
      actionLabel="Add System"
      onAction={onAction}
    />
  );
}

// Pets Empty State
export function NoPetsEmptyState({ onAction }: { onAction?: () => void }) {
  return (
    <EmptyState
      icon="paw-outline"
      iconColor={colors.haven.champagne[500]}
      title="No pets added"
      description="Track your furry friends' vet visits, medications, and care instructions."
      actionLabel="Add Pet"
      onAction={onAction}
    />
  );
}

// Vehicles Empty State
export function NoVehiclesEmptyState({ onAction }: { onAction?: () => void }) {
  return (
    <EmptyState
      icon="car-outline"
      iconColor={colors.haven.champagne[500]}
      title="No vehicles added"
      description="Track maintenance, registration, and insurance for your vehicles."
      actionLabel="Add Vehicle"
      onAction={onAction}
    />
  );
}

// Activities Empty State
export function NoActivitiesEmptyState({ onAction }: { onAction?: () => void }) {
  return (
    <EmptyState
      icon="calendar-outline"
      iconColor={colors.haven.champagne[500]}
      title="No activities added"
      description="Track sports, lessons, and other activities for your family members."
      actionLabel="Add Activity"
      onAction={onAction}
    />
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    padding: spacing[6],
  },
  iconContainer: {
    marginBottom: spacing[4],
  },
  iconBackground: {
    width: 96,
    height: 96,
    borderRadius: 48,
    backgroundColor: colors.haven.navy[50],
    alignItems: 'center',
    justifyContent: 'center',
  },
  title: {
    fontSize: typography.fontSizes.xl,
    fontWeight: typography.fontWeights.semibold as '600',
    color: colors.text.primary,
    textAlign: 'center',
    marginBottom: spacing[2],
  },
  description: {
    fontSize: typography.fontSizes.base,
    color: colors.text.secondary,
    textAlign: 'center',
    lineHeight: 24,
    maxWidth: 280,
  },
  actions: {
    marginTop: spacing[6],
    alignItems: 'center',
  },
  button: {
    minWidth: 180,
  },
  secondaryButton: {
    marginTop: spacing[3],
    minWidth: 180,
  },
});

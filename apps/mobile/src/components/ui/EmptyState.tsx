import React from 'react';
import { View, Text, StyleSheet, ViewStyle } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import Animated, { FadeIn, FadeInUp } from 'react-native-reanimated';
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
    <Animated.View
      entering={FadeIn.duration(300)}
      style={[styles.container, style]}
    >
      <Animated.View
        entering={FadeInUp.delay(100).duration(400)}
        style={styles.iconContainer}
      >
        <View style={styles.iconBackground}>
          <Ionicons name={icon} size={48} color={iconColor} />
        </View>
      </Animated.View>

      <Animated.Text
        entering={FadeInUp.delay(200).duration(400)}
        style={styles.title}
      >
        {title}
      </Animated.Text>

      {description && (
        <Animated.Text
          entering={FadeInUp.delay(300).duration(400)}
          style={styles.description}
        >
          {description}
        </Animated.Text>
      )}

      {actionLabel && onAction && (
        <Animated.View
          entering={FadeInUp.delay(400).duration(400)}
          style={styles.actions}
        >
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
        </Animated.View>
      )}
    </Animated.View>
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
    fontWeight: typography.fontWeights.semibold,
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

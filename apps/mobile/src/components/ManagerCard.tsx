import React from 'react';
import { View, Text, TouchableOpacity, StyleSheet, Linking } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { useSubscription } from '../contexts/subscription-context';
import { AlfredCard, AlfredAvatar } from './Alfred';
import { AlfredTabIcon } from './AlfredIcon';
import { colors, typography, spacing, borderRadius } from '../lib/theme';

// =============================================================================
// TYPES
// =============================================================================

interface ManagerCardProps {
  message?: string;
  showActions?: boolean;
  onChat?: () => void;
  onCall?: () => void;
}

interface ManagerAvatarProps {
  size?: 'small' | 'medium' | 'large';
}

// =============================================================================
// SIZE CONFIGURATIONS
// =============================================================================

const AVATAR_SIZES = {
  small: { container: 32, fontSize: 12 },
  medium: { container: 48, fontSize: 16 },
  large: { container: 80, fontSize: 28 },
};

// =============================================================================
// MANAGER CARD - Shows Alfred OR Sarah based on tier
// =============================================================================

export function ManagerCard({ message, showActions = true, onChat, onCall }: ManagerCardProps) {
  const { isEssentials, managerInfo } = useSubscription();

  // Essentials tier gets Alfred (AI manager)
  if (isEssentials) {
    return (
      <AlfredCard
        message={message || "How can I help you today? I can schedule vendors, answer questions, or help with maintenance tasks."}
        showActions={showActions}
        onChat={onChat}
      />
    );
  }

  // Premium tiers get human manager (Sarah)
  return (
    <View style={styles.card}>
      <View style={styles.header}>
        <View style={styles.humanAvatar}>
          <Text style={styles.humanAvatarText}>
            {managerInfo.name.split(' ').map(n => n[0]).join('')}
          </Text>
        </View>
        <View style={styles.info}>
          <Text style={styles.name}>{managerInfo.name}</Text>
          <Text style={styles.title}>{managerInfo.title}</Text>
        </View>
        {showActions && (
          <View style={styles.actions}>
            {onChat && (
              <TouchableOpacity style={styles.actionButton} onPress={onChat} activeOpacity={0.7}>
                <Ionicons name="chatbubble" size={20} color={colors.haven.champagne[500]} />
              </TouchableOpacity>
            )}
            {onCall && (
              <TouchableOpacity style={styles.actionButton} onPress={onCall} activeOpacity={0.7}>
                <Ionicons name="call" size={20} color={colors.haven.champagne[500]} />
              </TouchableOpacity>
            )}
          </View>
        )}
      </View>
      {message && (
        <View style={styles.messageContainer}>
          <Text style={styles.messageText}>{message}</Text>
        </View>
      )}
    </View>
  );
}

// =============================================================================
// MANAGER AVATAR - Shows Alfred OR Sarah avatar based on tier
// =============================================================================

export function ManagerAvatar({ size = 'medium' }: ManagerAvatarProps) {
  const { isEssentials, managerInfo } = useSubscription();

  // Map ManagerAvatar sizes to AlfredAvatar sizes
  const alfredSizeMap = {
    small: 'sm' as const,
    medium: 'md' as const,
    large: 'lg' as const,
  };

  // Essentials tier gets Alfred avatar
  if (isEssentials) {
    return <AlfredAvatar size={alfredSizeMap[size]} />;
  }

  // Premium tiers get human manager avatar
  const sizeConfig = AVATAR_SIZES[size];

  return (
    <View style={[
      styles.humanAvatar,
      {
        width: sizeConfig.container,
        height: sizeConfig.container,
        borderRadius: sizeConfig.container / 2,
      }
    ]}>
      <Text style={[styles.humanAvatarText, { fontSize: sizeConfig.fontSize }]}>
        {managerInfo.name.split(' ').map(n => n[0]).join('')}
      </Text>
    </View>
  );
}

// =============================================================================
// MANAGER NAME TEXT - Returns the manager's name
// =============================================================================

export function ManagerName() {
  const { managerInfo } = useSubscription();
  return <Text style={styles.managerNameText}>{managerInfo.name}</Text>;
}

// =============================================================================
// CONTACT MANAGER BUTTON
// =============================================================================

interface ContactManagerButtonProps {
  variant?: 'primary' | 'secondary' | 'outline';
  onPress?: () => void;
  showIcon?: boolean;
}

export function ContactManagerButton({ variant = 'primary', onPress, showIcon = true }: ContactManagerButtonProps) {
  const { isEssentials, managerInfo } = useSubscription();

  const buttonStyles = {
    primary: styles.contactButtonPrimary,
    secondary: styles.contactButtonSecondary,
    outline: styles.contactButtonOutline,
  };

  const textStyles = {
    primary: styles.contactButtonTextPrimary,
    secondary: styles.contactButtonTextSecondary,
    outline: styles.contactButtonTextOutline,
  };

  const iconColor = {
    primary: colors.white,
    secondary: colors.haven.navy[900],
    outline: colors.haven.champagne[500],
  };

  return (
    <TouchableOpacity
      style={[styles.contactButton, buttonStyles[variant]]}
      onPress={onPress}
      activeOpacity={0.8}
    >
      {showIcon && (
        isEssentials ? (
          <AlfredTabIcon size={18} color={iconColor[variant]} />
        ) : (
          <Ionicons name="chatbubble" size={18} color={iconColor[variant]} />
        )
      )}
      <Text style={[styles.contactButtonText, textStyles[variant]]}>
        {isEssentials ? 'Chat with Alfred' : `Message ${managerInfo.name.split(' ')[0]}`}
      </Text>
    </TouchableOpacity>
  );
}

// =============================================================================
// MANAGER HELP BANNER - Contextual help from manager
// =============================================================================

interface ManagerHelpBannerProps {
  context: 'maintenance' | 'billing' | 'vendors' | 'general';
  onDismiss?: () => void;
  onChat?: () => void;
}

const HELP_MESSAGES = {
  maintenance: {
    alfred: "I can help schedule vendors, create maintenance reminders, or answer questions about your home systems.",
    human: "I'm here to help with any maintenance needs. Just send me a message and I'll take care of it.",
  },
  billing: {
    alfred: "I can explain your bills, set up payment reminders, or help you understand your monthly funding.",
    human: "Questions about your statement? I'm happy to walk you through the details.",
  },
  vendors: {
    alfred: "Need to find a vendor? I can search our network and schedule appointments for you.",
    human: "I can coordinate with any of our trusted vendors on your behalf.",
  },
  general: {
    alfred: "How can I help you today?",
    human: "I'm here whenever you need anything.",
  },
};

export function ManagerHelpBanner({ context, onDismiss, onChat }: ManagerHelpBannerProps) {
  const { isEssentials, managerInfo } = useSubscription();

  const message = isEssentials
    ? HELP_MESSAGES[context].alfred
    : HELP_MESSAGES[context].human;

  return (
    <View style={styles.helpBanner}>
      <View style={styles.helpBannerHeader}>
        <ManagerAvatar size="small" />
        <View style={styles.helpBannerInfo}>
          <Text style={styles.helpBannerName}>{managerInfo.name}</Text>
          <Text style={styles.helpBannerTitle}>{managerInfo.title}</Text>
        </View>
        {onDismiss && (
          <TouchableOpacity onPress={onDismiss} style={styles.dismissButton}>
            <Ionicons name="close" size={18} color={colors.text.tertiary} />
          </TouchableOpacity>
        )}
      </View>
      <Text style={styles.helpBannerMessage}>{message}</Text>
      {onChat && (
        <TouchableOpacity style={styles.helpBannerAction} onPress={onChat}>
          {isEssentials ? (
            <AlfredTabIcon size={16} color={colors.haven.champagne[500]} />
          ) : (
            <Ionicons name="chatbubble-outline" size={16} color={colors.haven.champagne[500]} />
          )}
          <Text style={styles.helpBannerActionText}>
            {isEssentials ? 'Ask Alfred' : 'Send Message'}
          </Text>
        </TouchableOpacity>
      )}
    </View>
  );
}

// =============================================================================
// STYLES
// =============================================================================

const styles = StyleSheet.create({
  // Card
  card: {
    backgroundColor: colors.white,
    borderRadius: borderRadius.xl,
    padding: spacing[4],
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.08,
    shadowRadius: 8,
    elevation: 3,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  humanAvatar: {
    backgroundColor: colors.haven.navy[900],
    justifyContent: 'center',
    alignItems: 'center',
  },
  humanAvatarText: {
    color: colors.white,
    fontWeight: typography.fontWeights.semibold,
  },
  info: {
    flex: 1,
    marginLeft: spacing[3],
  },
  name: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.semibold,
    color: colors.haven.navy[900],
  },
  title: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.champagne[500],
    marginTop: 2,
  },
  actions: {
    flexDirection: 'row',
    gap: spacing[2],
  },
  actionButton: {
    padding: spacing[2],
    backgroundColor: `${colors.haven.champagne[500]}15`,
    borderRadius: borderRadius.lg,
  },
  messageContainer: {
    marginTop: spacing[3],
    backgroundColor: colors.background.secondary,
    borderRadius: borderRadius.lg,
    padding: spacing[3],
  },
  messageText: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    lineHeight: 20,
  },

  // Manager Name
  managerNameText: {
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
  },

  // Contact Button
  contactButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: spacing[2],
    paddingVertical: spacing[3],
    paddingHorizontal: spacing[4],
    borderRadius: borderRadius.xl,
  },
  contactButtonPrimary: {
    backgroundColor: colors.haven.navy[900],
  },
  contactButtonSecondary: {
    backgroundColor: colors.haven.champagne[100],
  },
  contactButtonOutline: {
    backgroundColor: 'transparent',
    borderWidth: 1,
    borderColor: colors.haven.champagne[500],
  },
  contactButtonText: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
  },
  contactButtonTextPrimary: {
    color: colors.white,
  },
  contactButtonTextSecondary: {
    color: colors.haven.navy[900],
  },
  contactButtonTextOutline: {
    color: colors.haven.champagne[500],
  },

  // Help Banner
  helpBanner: {
    backgroundColor: colors.white,
    borderRadius: borderRadius.xl,
    padding: spacing[4],
    borderLeftWidth: 4,
    borderLeftColor: colors.haven.champagne[500],
  },
  helpBannerHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: spacing[3],
  },
  helpBannerInfo: {
    flex: 1,
    marginLeft: spacing[2],
  },
  helpBannerName: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
  },
  helpBannerTitle: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
  },
  dismissButton: {
    padding: spacing[1],
  },
  helpBannerMessage: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    lineHeight: 20,
  },
  helpBannerAction: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[2],
    marginTop: spacing[3],
    paddingTop: spacing[3],
    borderTopWidth: 1,
    borderTopColor: colors.border.light,
  },
  helpBannerActionText: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.haven.champagne[500],
  },
});

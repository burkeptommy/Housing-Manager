# Haven Mobile: M09 - Polish & TestFlight

**Created:** December 29, 2024  
**Priority:** P0 - Required for release  
**Estimated Time:** 4-5 hours  
**Dependencies:** M01-M08 complete, Apple Developer License active

---

## Overview

Final polish and TestFlight submission:
1. App icons and splash screen
2. Loading states and animations
3. Error handling improvements
4. Accessibility audit
5. TestFlight build configuration
6. Submission to TestFlight

---

## PHASE 1: App Icons

### Task 1.1: Create App Icon

Create proper app icons. The icon should be the Haven logo (H or house icon) with navy background.

Required sizes for iOS (place in `apps/mobile/assets/`):
- `icon.png` - 1024x1024 (App Store)

The Expo build process will generate all required sizes.

Create `apps/mobile/assets/icon.png`:
- Background: Haven Navy (#0a1929)
- Icon: Champagne colored house or "H" logo
- No transparency
- No rounded corners (iOS adds them)

### Task 1.2: Create Adaptive Icon (Android)

Create `apps/mobile/assets/adaptive-icon.png`:
- 1024x1024
- Foreground only (background set in config)
- Safe zone: center 66% of image

---

## PHASE 2: Splash Screen

### Task 2.1: Create Splash Screen

Create `apps/mobile/assets/splash.png`:
- Size: 1284x2778 (iPhone 14 Pro Max)
- Background: Haven Navy (#0a1929)
- Center: Haven logo in champagne
- Simple, clean design

### Task 2.2: Update Splash Config

Update `apps/mobile/app.json`:

```json
{
  "expo": {
    "splash": {
      "image": "./assets/splash.png",
      "resizeMode": "contain",
      "backgroundColor": "#0a1929"
    }
  }
}
```

---

## PHASE 3: Loading States

### Task 3.1: Create Skeleton Components

Create `apps/mobile/src/components/ui/Skeleton.tsx`:

```typescript
import React, { useEffect, useRef } from 'react';
import { View, StyleSheet, Animated, ViewStyle } from 'react-native';
import { colors, borderRadius } from '../../lib/theme';

interface SkeletonProps {
  width?: number | string;
  height?: number;
  borderRadius?: number;
  style?: ViewStyle;
}

export function Skeleton({
  width = '100%',
  height = 20,
  borderRadius: radius = borderRadius.md,
  style,
}: SkeletonProps) {
  const opacity = useRef(new Animated.Value(0.3)).current;

  useEffect(() => {
    const animation = Animated.loop(
      Animated.sequence([
        Animated.timing(opacity, {
          toValue: 0.7,
          duration: 800,
          useNativeDriver: true,
        }),
        Animated.timing(opacity, {
          toValue: 0.3,
          duration: 800,
          useNativeDriver: true,
        }),
      ])
    );
    animation.start();
    return () => animation.stop();
  }, [opacity]);

  return (
    <Animated.View
      style={[
        styles.skeleton,
        { width, height, borderRadius: radius, opacity },
        style,
      ]}
    />
  );
}

export function SkeletonCard({ style }: { style?: ViewStyle }) {
  return (
    <View style={[styles.card, style]}>
      <View style={styles.cardHeader}>
        <Skeleton width={48} height={48} borderRadius={24} />
        <View style={styles.cardHeaderText}>
          <Skeleton width={120} height={16} />
          <Skeleton width={80} height={12} style={{ marginTop: 8 }} />
        </View>
      </View>
      <Skeleton height={12} style={{ marginTop: 16 }} />
      <Skeleton height={12} width="80%" style={{ marginTop: 8 }} />
    </View>
  );
}

export function SkeletonList({ count = 3 }: { count?: number }) {
  return (
    <View>
      {Array.from({ length: count }).map((_, index) => (
        <SkeletonCard key={index} style={{ marginBottom: 12 }} />
      ))}
    </View>
  );
}

const styles = StyleSheet.create({
  skeleton: {
    backgroundColor: colors.gray[200],
  },
  card: {
    backgroundColor: colors.white,
    borderRadius: borderRadius.xl,
    padding: 16,
  },
  cardHeader: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  cardHeaderText: {
    marginLeft: 12,
    flex: 1,
  },
});
```

---

## PHASE 4: Error Handling

### Task 4.1: Create Error Boundary

Create `apps/mobile/src/components/ErrorBoundary.tsx`:

```typescript
import React, { Component, ReactNode } from 'react';
import { View, Text, StyleSheet, TouchableOpacity } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { colors, typography, spacing, borderRadius } from '../lib/theme';

interface Props {
  children: ReactNode;
  fallback?: ReactNode;
}

interface State {
  hasError: boolean;
  error?: Error;
}

export class ErrorBoundary extends Component<Props, State> {
  constructor(props: Props) {
    super(props);
    this.state = { hasError: false };
  }

  static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error };
  }

  componentDidCatch(error: Error, errorInfo: React.ErrorInfo) {
    console.error('ErrorBoundary caught error:', error, errorInfo);
    // TODO: Send to error reporting service
  }

  handleReset = () => {
    this.setState({ hasError: false, error: undefined });
  };

  render() {
    if (this.state.hasError) {
      if (this.props.fallback) {
        return this.props.fallback;
      }

      return (
        <View style={styles.container}>
          <View style={styles.iconContainer}>
            <Ionicons name="alert-circle" size={64} color={colors.status.error} />
          </View>
          <Text style={styles.title}>Something went wrong</Text>
          <Text style={styles.message}>
            We're sorry, but something unexpected happened. Please try again.
          </Text>
          <TouchableOpacity style={styles.button} onPress={this.handleReset}>
            <Text style={styles.buttonText}>Try Again</Text>
          </TouchableOpacity>
        </View>
      );
    }

    return this.props.children;
  }
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: spacing[6],
    backgroundColor: colors.background.secondary,
  },
  iconContainer: {
    marginBottom: spacing[4],
  },
  title: {
    fontSize: typography.fontSizes.xl,
    fontWeight: typography.fontWeights.bold,
    color: colors.text.primary,
    marginBottom: spacing[2],
    textAlign: 'center',
  },
  message: {
    fontSize: typography.fontSizes.base,
    color: colors.text.secondary,
    textAlign: 'center',
    marginBottom: spacing[6],
    lineHeight: 24,
  },
  button: {
    backgroundColor: colors.haven.navy[900],
    paddingHorizontal: spacing[6],
    paddingVertical: spacing[3],
    borderRadius: borderRadius.lg,
  },
  buttonText: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.white,
  },
});
```

### Task 4.2: Create Offline Banner

Create `apps/mobile/src/components/OfflineBanner.tsx`:

```typescript
import React, { useEffect, useState } from 'react';
import { View, Text, StyleSheet, Animated } from 'react-native';
import NetInfo from '@react-native-community/netinfo';
import { Ionicons } from '@expo/vector-icons';
import { colors, typography, spacing } from '../lib/theme';

export function OfflineBanner() {
  const [isOffline, setIsOffline] = useState(false);
  const translateY = useState(new Animated.Value(-50))[0];

  useEffect(() => {
    const unsubscribe = NetInfo.addEventListener((state) => {
      setIsOffline(!state.isConnected);
    });

    return () => unsubscribe();
  }, []);

  useEffect(() => {
    Animated.timing(translateY, {
      toValue: isOffline ? 0 : -50,
      duration: 300,
      useNativeDriver: true,
    }).start();
  }, [isOffline, translateY]);

  return (
    <Animated.View style={[styles.container, { transform: [{ translateY }] }]}>
      <Ionicons name="cloud-offline" size={16} color={colors.white} />
      <Text style={styles.text}>No internet connection</Text>
    </Animated.View>
  );
}

const styles = StyleSheet.create({
  container: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    backgroundColor: colors.status.error,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: spacing[2],
    paddingTop: spacing[6],
    gap: spacing[2],
    zIndex: 1000,
  },
  text: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.white,
  },
});
```

---

## PHASE 5: Accessibility

### Task 5.1: Add Accessibility Labels

Update key components with accessibility props:

```typescript
// Example for Button component
<TouchableOpacity
  accessible={true}
  accessibilityLabel={title}
  accessibilityRole="button"
  accessibilityState={{ disabled: disabled || loading }}
  // ...
>
```

### Task 5.2: Accessibility Checklist

Verify these are implemented across the app:
- [ ] All buttons have `accessibilityLabel`
- [ ] All images have `accessibilityLabel` or `accessible={false}`
- [ ] Icons used as buttons have `accessibilityRole="button"`
- [ ] Form inputs have `accessibilityLabel` and `accessibilityHint`
- [ ] Touch targets are at least 44x44 points
- [ ] Color contrast meets WCAG AA standards
- [ ] Screen reader can navigate all screens

---

## PHASE 6: Final app.json Configuration

### Task 6.1: Update app.json for Production

Replace `apps/mobile/app.json`:

```json
{
  "expo": {
    "name": "Haven",
    "slug": "haven-mobile",
    "version": "1.0.0",
    "orientation": "portrait",
    "icon": "./assets/icon.png",
    "scheme": "haven",
    "userInterfaceStyle": "light",
    "splash": {
      "image": "./assets/splash.png",
      "resizeMode": "contain",
      "backgroundColor": "#0a1929"
    },
    "assetBundlePatterns": ["**/*"],
    "ios": {
      "supportsTablet": true,
      "bundleIdentifier": "com.havenhome.app",
      "buildNumber": "1",
      "infoPlist": {
        "NSCameraUsageDescription": "Haven needs camera access to scan documents and take photos for your home manager.",
        "NSPhotoLibraryUsageDescription": "Haven needs photo library access to upload documents and photos.",
        "NSFaceIDUsageDescription": "Haven uses Face ID for secure, quick login to your account.",
        "NSLocationWhenInUseUsageDescription": "Haven uses your location to find local service providers.",
        "LSApplicationQueriesSchemes": ["plaidlink"],
        "ITSAppUsesNonExemptEncryption": false
      },
      "associatedDomains": [
        "applinks:havenhome.dev",
        "applinks:api.havenhome.dev"
      ],
      "config": {
        "usesNonExemptEncryption": false
      }
    },
    "android": {
      "adaptiveIcon": {
        "foregroundImage": "./assets/adaptive-icon.png",
        "backgroundColor": "#0a1929"
      },
      "package": "com.havenhome.app",
      "versionCode": 1
    },
    "plugins": [
      "expo-router",
      "expo-secure-store",
      "expo-apple-authentication",
      [
        "expo-local-authentication",
        {
          "faceIDPermission": "Allow Haven to use Face ID for quick login."
        }
      ],
      [
        "expo-image-picker",
        {
          "photosPermission": "Haven needs photo access to upload documents.",
          "cameraPermission": "Haven needs camera access to scan documents."
        }
      ],
      [
        "expo-notifications",
        {
          "icon": "./assets/notification-icon.png",
          "color": "#c4a574"
        }
      ],
      [
        "react-native-plaid-link-sdk",
        {}
      ]
    ],
    "extra": {
      "eas": {
        "projectId": "96316a4d-0c79-4641-bcaa-db50358dda7c"
      }
    },
    "owner": "havenhome",
    "runtimeVersion": {
      "policy": "appVersion"
    },
    "updates": {
      "url": "https://u.expo.dev/96316a4d-0c79-4641-bcaa-db50358dda7c"
    }
  }
}
```

---

## PHASE 7: Build & Submit to TestFlight

### Task 7.1: Update eas.json

Ensure `apps/mobile/eas.json` is configured:

```json
{
  "cli": {
    "version": ">= 5.0.0"
  },
  "build": {
    "development": {
      "developmentClient": true,
      "distribution": "internal",
      "ios": {
        "simulator": false
      }
    },
    "preview": {
      "distribution": "internal",
      "ios": {
        "simulator": false
      }
    },
    "production": {
      "distribution": "store",
      "ios": {
        "simulator": false
      }
    }
  },
  "submit": {
    "production": {
      "ios": {
        "appleId": "YOUR_APPLE_ID",
        "ascAppId": "YOUR_APP_STORE_CONNECT_APP_ID",
        "appleTeamId": "YOUR_TEAM_ID"
      }
    }
  }
}
```

### Task 7.2: Run Pre-flight Checks

```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/mobile

# Check for TypeScript errors
pnpm typecheck

# Check for lint errors
pnpm lint

# Verify all dependencies
pnpm install
```

### Task 7.3: Build for TestFlight

```bash
# Build for internal testing (TestFlight)
eas build --platform ios --profile preview

# Wait for build to complete (check status)
eas build:list

# Submit to TestFlight
eas submit --platform ios --latest
```

### Task 7.4: TestFlight Configuration

After submitting to TestFlight:

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Select Haven app
3. Click **TestFlight** tab
4. Wait for build processing (5-10 minutes)
5. Add **Test Information**:
   - Beta App Description: "Haven - Home Management. Manage your home with a dedicated manager."
   - Feedback Email: support@havenhome.dev
6. Add **Internal Testers** (your Apple ID)
7. Start testing!

---

## PHASE 8: Pre-Launch Checklist

### Before submitting to App Store:

- [ ] All features working
- [ ] No TypeScript errors
- [ ] No console errors/warnings
- [ ] App icons look correct
- [ ] Splash screen displays properly
- [ ] All permissions request correctly
- [ ] Push notifications work
- [ ] Biometric login works
- [ ] Plaid connection works
- [ ] Subscription purchase works (sandbox)
- [ ] Sign out works
- [ ] Offline handling works
- [ ] Accessibility verified

### App Store Assets Needed:

- [ ] 6.7" Screenshots (1290 x 2796) - at least 3
- [ ] 6.5" Screenshots (1284 x 2778) - at least 3
- [ ] App Store description (4000 chars max)
- [ ] Keywords (100 chars max)
- [ ] Support URL
- [ ] Privacy Policy URL
- [ ] Marketing URL (optional)

---

## Summary

After completing this prompt:
1. ✅ Professional app icons
2. ✅ Branded splash screen
3. ✅ Skeleton loading states
4. ✅ Error boundary
5. ✅ Offline detection
6. ✅ Accessibility improvements
7. ✅ Production app.json config
8. ✅ TestFlight build ready

**The Haven mobile app is ready for beta testing via TestFlight!**

---

## Next Steps After TestFlight

1. Test on multiple devices
2. Gather feedback from beta testers
3. Fix any reported issues
4. Prepare App Store listing
5. Submit for App Store review
6. Launch! 🚀

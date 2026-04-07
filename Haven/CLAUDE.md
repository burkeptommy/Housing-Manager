# Haven iOS App -- Context for Claude Code

## Architecture: MVVM + Services

Every feature follows: **View** -> **ViewModel** (@MainActor, ObservableObject) -> **DatabaseService** -> Supabase

ViewModels own all state. Views are declarative SwiftUI. No business logic in views.

## File Organization Convention

```
Features/{FeatureName}/
├── Components/     # Reusable subviews specific to this feature
├── Models/         # Feature-specific data models (if not in DatabaseModels.swift)
├── ViewModels/     # @MainActor ObservableObject classes
├── Views/          # SwiftUI views
└── Services/       # Feature-specific services (rare -- most go in Core/Services/)
```

## DatabaseModels.swift Pattern

Every Supabase table has three types in `Core/Networking/DatabaseModels.swift`:
- `{Table}Row` -- for reading (Codable, Identifiable)
- `{Table}Insert` -- for creating (Codable)
- `{Table}Update` -- for updating (Codable, all fields optional)

All use `CodingKeys` for snake_case <-> camelCase mapping. Use resilient decoding (`try?`) for optional fields that Claude might omit or return in unexpected formats.

## Edge Function Calls

All go through `HavenSupabase` in `Core/Networking/SupabaseClient.swift`:

```swift
// Typed convenience methods exist for each function:
let data = try await HavenSupabase.analyzeDocument(documentId: id, text: text, imageBase64: nil, householdId: hid)
let data = try await HavenSupabase.chat(message: msg, history: hist, contextType: nil, contextId: nil, householdId: hid)
let response = try await HavenSupabase.searchEquipment(query: "bosch dishwasher")
```

Under the hood, `callEdgeFunction()` handles auth token refresh, URL construction, headers, and error logging.

## Theme System (USE THESE, not hardcoded values)

### Colors -- Always use `HavenColors.*`
```swift
HavenColors.cream          // #F2EEE5 -- screen backgrounds
HavenColors.creamLight     // #F8F6F1 -- cards, elevated surfaces
HavenColors.navy800        // #1B2A4A -- primary text, buttons, icons
HavenColors.navy700        // #243660 -- pressed states
HavenColors.beige200       // #F0EBE1 -- borders, input backgrounds
HavenColors.beige300       // #E3D9C6 -- dividers
HavenColors.textPrimary    // adaptive (navy in light, cream in dark)
HavenColors.textSecondary  // muted
HavenColors.textOnNavy     // text on navy surfaces
HavenColors.background     // adaptive screen background
HavenColors.surface        // adaptive card surface
HavenColors.border         // adaptive border
```

### Typography -- Always use `HavenTypography.*`
```swift
// Georgia serif -- for content
HavenTypography.title      // 22pt Bold -- screen titles
HavenTypography.title2     // 18pt Semibold -- section titles
HavenTypography.title3     // 16pt Semibold -- card titles
HavenTypography.headline   // 15pt Semibold -- card headlines
HavenTypography.body       // 14pt -- body text, AI chat messages
HavenTypography.bodySmall  // 13pt -- secondary descriptions
HavenTypography.caption    // 12pt -- captions, footnotes

// SF Pro system -- for UI chrome
HavenTypography.uiLabel       // 13pt Medium -- metadata labels
HavenTypography.uiLabelSmall  // 11pt Medium -- badge text
HavenTypography.uiButton      // 15pt Semibold -- button labels
HavenTypography.uiSectionHeader // 10pt Semibold -- section headers (ALL CAPS)
```

### Spacing -- Always use `HavenTheme.*`
```swift
HavenTheme.spacing8     // 8pt -- tight
HavenTheme.spacing16    // 16pt -- standard
HavenTheme.spacing20    // 20pt -- page margin (use .pageMargin)
HavenTheme.spacing24    // 24pt -- section spacing
HavenTheme.radiusLarge  // 16pt -- cards
HavenTheme.radiusButton // 14pt -- buttons
HavenTheme.radiusMedium // 12pt -- inputs
```

### Shadows -- Use `.havenShadow()` modifier
```swift
.havenShadow()                          // default card shadow
.havenShadow(HavenTheme.shadowElevated) // elevated element
.havenShadow(HavenTheme.shadowFloat)    // FAB / floating
// Shadows auto-disable in dark mode
```

### Animation
```swift
HavenTheme.animationStandard  // default spring
HavenTheme.animationQuick     // fast interactions
HavenTheme.animationCard      // card appearance
HavenTheme.animationPress     // button press
```

## Common Patterns

### Navigation
```swift
// Pop to root via notification
NotificationCenter.default.post(name: .popToRoot, object: nil, userInfo: ["tab": 0])

// Switch tabs
NotificationCenter.default.post(name: .switchToTab, object: nil, userInfo: ["tab": 2])

// Open Scenario Studio with pre-filled query
NotificationCenter.default.post(name: .openScenarioStudio, object: nil, userInfo: ["query": "What if I sell my house?"])

// Open Alfred with context
NotificationCenter.default.post(name: .openAlfredWithContext, object: nil)
```

### Data Sync Between Tabs
Post these after mutations so other tabs refresh:
```swift
NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil)
NotificationCenter.default.post(name: .homeSystemChanged, object: nil)
NotificationCenter.default.post(name: .documentChanged, object: nil)
NotificationCenter.default.post(name: .propertyChanged, object: nil)
NotificationCenter.default.post(name: .projectChanged, object: nil)
NotificationCenter.default.post(name: .contractorChanged, object: nil)
```

### Analytics
```swift
Analytics.track(.eventName, ["key": value])
```

### Haptics
```swift
Haptics.selection()  // tab changes, list selections
Haptics.light()      // subtle confirmations
Haptics.medium()     // button taps
Haptics.success()    // completed actions
Haptics.error()      // failures
```

### Loading States
Use skeleton loading (via `LoadingView`), never spinners. The app should feel premium -- no jarring loading indicators.

### Security
- `ScreenshotPrevention.install()` is called at app launch
- Sensitive documents use vault lock (`VaultLockService`)
- Document encryption via `DocumentEncryption` (AES-256-GCM)
- Biometric auth at app launch (`BiometricAuthView`)
- Jailbreak detection with user warning

## Info.plist Permissions

Camera (document scanning), Photo Library (document upload), Face ID (biometric auth), Location (local service providers), Contacts (save forwarding email), Calendar (family events sync). NSAppTransportSecurity: no arbitrary loads, local networking allowed.

## Orientation

Portrait only on iPhone. All orientations on iPad (future Home Hub mode).

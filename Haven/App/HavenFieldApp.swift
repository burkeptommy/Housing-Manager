import SwiftUI
import Supabase
import UserNotifications

@main
struct HavenFieldApp: App {
    @UIApplicationDelegateAdaptor(HavenFieldAppDelegate.self) var appDelegate
    @StateObject private var appState = AppState()
    @State private var showJailbreakAlert = false

    init() {
        configureNavigationBarAppearance()
        UIWindow.appearance().backgroundColor = UIColor(
            red: 0.973, green: 0.976, blue: 0.980, alpha: 1.0
        )
    }

    var body: some Scene {
        WindowGroup {
            HavenFieldContentView()
                .environmentObject(appState)
                .background(HavenColors.cream)
                .tint(HavenColors.action)
                .task {
                    appState.initialize()
                    performSecurityChecks()
                    let granted = await NotificationService.shared.requestPermission()
                    print("[Push] Chez Field permission granted: \(granted)")
                    await MainActor.run {
                        PushNotificationService.shared.registerForPushNotifications()
                    }
                    Analytics.track(.appLaunched)
                }
                .alert("Security Warning", isPresented: $showJailbreakAlert) {
                    Button("I Understand", role: .cancel) {}
                } message: {
                    Text("This device may be jailbroken. We recommend using Chez Field on a non-jailbroken device for secure access to homeowner information.")
                }
        }
    }

    private func performSecurityChecks() {
        ScreenshotPrevention.install()

        let result = JailbreakDetection.check()
        if result.isJailbroken {
            SecureLogger.warning("Chez Field jailbreak indicators detected: \(result.indicators.joined(separator: ", "))")
            showJailbreakAlert = true
        }
    }

    private func configureNavigationBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color.havenCream)
        appearance.shadowColor = UIColor(red: 0.847, green: 0.855, blue: 0.875, alpha: 0.3)

        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor(Color.havenNavy),
            .font: HavenTypography.frauncesUIFont(size: 28, weight: 700),
        ]

        appearance.titleTextAttributes = [
            .foregroundColor: UIColor(Color.havenNavy),
            .font: HavenTypography.frauncesUIFont(size: 17, weight: 700),
        ]

        let buttonAppearance = UIBarButtonItemAppearance()
        buttonAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(Color.havenNavy700),
        ]
        appearance.buttonAppearance = buttonAppearance

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().tintColor = UIColor(Color.havenNavy700)
    }
}

final class HavenFieldAppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        PushNotificationService.shared.handleDeviceToken(deviceToken)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        PushNotificationService.shared.handleRegistrationError(error)
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
        NotificationCenter.default.post(name: .inboxItemUpdated, object: nil)
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // T1.5 (post-overnight) — typed deep-link routing per push payload.
        // Mirrors the homeowner pattern at HavenApp.swift:223-295. Server
        // already accepts a generic `data?: Record<string,string>` field
        // in send-push-notification (see send-push-notification/index.ts:22).
        // The field app routes by userInfo["type"]:
        //
        //   homeowner_message / handyman_request_message
        //     → Messages tab + open the related thread
        //   quote_accepted_by_homeowner / quote_countered_by_homeowner /
        //   quote_declined_by_homeowner
        //     → Visits tab + open the related visit (status changed)
        //   visit_confirmed_by_homeowner / visit_cancelled_by_homeowner /
        //   visit_rescheduled_by_homeowner / visit_starting_soon
        //     → Visits tab + open the related visit
        //   homeowner_punch_added / visit_punch_item_added
        //     → Visits tab + open the active visit's punch list
        //   customer_link_accepted / customer_link_declined /
        //   pairing_completed
        //     → Homes tab + open the related home (if id provided)
        //   chez_assessment_review_requested / assessment_corrections_*
        //     → Visits tab (assessments live there until T2.1 lands)
        //   anything else → generic dashboard refresh only
        //
        // Pre-T1.5 this handler did ONLY `.inboxItemUpdated` with no
        // payload parsing. Tap a "quote accepted" push → land on whatever
        // tab was already open. Now: handler routes to the right tab + entity.
        let userInfo = response.notification.request.content.userInfo
        routeFieldPushTap(userInfo: userInfo)
        // Always also post the legacy refresh signal so any unrelated
        // observer (e.g. inbox badges) still updates.
        NotificationCenter.default.post(name: .inboxItemUpdated, object: nil)
        NotificationCenter.default.post(name: .havenFieldVisitChanged, object: nil)
        completionHandler()
    }

    private func routeFieldPushTap(userInfo: [AnyHashable: Any]) {
        guard let type = userInfo["type"] as? String, !type.isEmpty else { return }
        let requestId = (userInfo["request_id"] as? String) ?? (userInfo["requestId"] as? String)
        let propertyId = (userInfo["property_id"] as? String) ?? (userInfo["propertyId"] as? String)

        switch type {
        case "homeowner_message",
             "handyman_request_message",
             "thread_message_received":
            NotificationCenter.default.post(
                name: .havenFieldSwitchTab,
                object: nil,
                userInfo: ["tab": "messages"]
            )
            if let requestId, !requestId.isEmpty {
                NotificationCenter.default.post(
                    name: .havenFieldOpenThread,
                    object: nil,
                    userInfo: ["request_id": requestId]
                )
            }

        case "quote_accepted_by_homeowner",
             "quote_countered_by_homeowner",
             "quote_declined_by_homeowner",
             "quote_viewed_by_homeowner",
             "visit_confirmed_by_homeowner",
             "visit_cancelled_by_homeowner",
             "visit_rescheduled_by_homeowner",
             "visit_alternate_dates_proposed",
             "visit_starting_soon",
             "homeowner_punch_added",
             "visit_punch_item_added",
             "follow_up_requested",
             "chez_assessment_review_requested",
             "chez_assessment_corrections_received":
            NotificationCenter.default.post(
                name: .havenFieldSwitchTab,
                object: nil,
                userInfo: ["tab": "visits"]
            )
            if let requestId, !requestId.isEmpty {
                NotificationCenter.default.post(
                    name: .havenFieldOpenVisit,
                    object: nil,
                    userInfo: ["request_id": requestId]
                )
            }

        case "customer_link_accepted",
             "customer_link_declined",
             "pairing_completed":
            NotificationCenter.default.post(
                name: .havenFieldSwitchTab,
                object: nil,
                userInfo: ["tab": "homes"]
            )
            if let propertyId, !propertyId.isEmpty {
                NotificationCenter.default.post(
                    name: .havenFieldOpenHome,
                    object: nil,
                    userInfo: ["property_id": propertyId]
                )
            }

        default:
            // Unknown type: fall through to the generic refresh signals
            // already posted by the caller. Don't try to guess routing.
            break
        }
    }
}

struct HavenFieldContentView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showAuth = false

    var body: some View {
        Group {
            if appState.requiresUpdate,
               let message = appState.forceUpdateMessage,
               let url = appState.forceUpdateAppStoreURL {
                ForceUpdateView(message: message, appStoreURL: url)
            } else if appState.isLoading {
                ChezFieldLoadingView()
            } else if appState.isAuthenticated && appState.sessionManager.isLocked {
                BiometricAuthView()
                    .environmentObject(appState)
            } else if appState.isAuthenticated
                        && appState.fieldDashboard?.needsWorkspace == false {
                // Authoritative: dashboard fetch returned a real workspace
                // membership for this auth user. Always show the field root
                // here, regardless of whatever `activeExperience` happens
                // to be — the membership row IS the truth.
                HavenFieldRootView()
                    .environmentObject(appState)
            } else if appState.isAuthenticated
                        && appState.activeExperience == .field {
                // Belt-and-suspenders: respect activeExperience too in case
                // some path sets it without populating fieldDashboard.
                HavenFieldRootView()
                    .environmentObject(appState)
            } else if appState.isAuthenticated {
                // Authenticated but no field dashboard yet — could be a
                // legitimate fresh signup, or a transient fetch failure.
                // The setup form lets sole proprietors self-serve and the
                // server's email-fallback claim handles re-claiming an
                // existing workspace if the user already created one.
                HavenFieldWorkspaceSetupView()
                    .environmentObject(appState)
            } else if showAuth {
                HavenFieldSignInView(onBack: { showAuth = false })
                    .environmentObject(appState)
            } else {
                HavenFieldWelcomeView(onSignIn: { showAuth = true })
            }
        }
        .animation(.easeInOut(duration: 0.3), value: appState.requiresUpdate)
        .animation(.easeInOut(duration: 0.3), value: appState.isAuthenticated)
        .animation(.easeInOut(duration: 0.3), value: appState.sessionManager.isLocked)
        .animation(.easeInOut(duration: 0.3), value: appState.activeExperience)
        .animation(.easeInOut(duration: 0.3), value: showAuth)
    }
}

private struct ChezFieldLoadingView: View {
    var body: some View {
        ZStack {
            Color("ChezFieldLaunchBackground")
                .ignoresSafeArea()

            VStack(spacing: 28) {
                Image("ChezFieldLaunch")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 172, height: 172)

                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(Color.white.opacity(0.92))
                    .scaleEffect(1.1)
            }
        }
    }
}

private struct HavenFieldWelcomeView: View {
    let onSignIn: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    fieldHero

                    FieldAuthInfoCard(
                        title: "Built for the day in the field",
                        copy: "See your stops, coordinate with homeowners, capture model labels, and complete visits without carrying the full back office on your phone."
                    )

                    FieldAuthInfoCard(
                        title: "Use desktop for setup and quoting",
                        copy: "Company setup, dispatching, quoting, and team planning still live in the Chez Field desktop command center."
                    )

                    VStack(spacing: 12) {
                        HavenButton(title: "Sign in to Chez Field") {
                            onSignIn()
                        }

                        Link(destination: URL(string: "https://getchez.com/handyman")!) {
                            Text("Open desktop command center")
                                .font(HavenTypography.uiLabel)
                                .foregroundStyle(HavenColors.textPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                                        .stroke(HavenColors.beige400, lineWidth: 1)
                                )
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
            .background(HavenColors.background.ignoresSafeArea())
        }
    }

    private var fieldHero: some View {
        VStack(alignment: .leading, spacing: 16) {
            Image("ChezFieldBrand")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 320)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .shadow(color: HavenColors.navy900.opacity(0.12), radius: 22, x: 0, y: 12)

            VStack(alignment: .leading, spacing: 8) {
                Text("Chez Field")
                    .font(HavenTypography.fraunces(size: 40, weight: 600))
                    .foregroundStyle(HavenColors.navy900)

                Text("The technician app for visits, systems, files, and homeowner coordination.")
                    .font(HavenTypography.body)
                    .foregroundStyle(HavenColors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.980, green: 0.937, blue: 0.921),
                            Color(red: 0.996, green: 0.972, blue: 0.956),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
    }
}

private enum HavenFieldAuthMode {
    case signIn
    case signUp
}

private struct HavenFieldSignInView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = AuthViewModel()
    @StateObject private var appleSignIn = AppleSignInCoordinator()
    @State private var mode: HavenFieldAuthMode = .signIn

    let onBack: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    VStack(spacing: 10) {
                        Text("Chez Field")
                            .font(HavenTypography.fraunces(size: 34, weight: 600))
                            .foregroundStyle(HavenColors.navy900)
                        Text(mode == .signIn
                             ? "Sign in with your technician or company account."
                             : "Create a secure field account for your company.")
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)

                    HStack(spacing: 8) {
                        authModeButton("Sign In", mode: .signIn)
                        authModeButton("Create Account", mode: .signUp)
                    }
                    .padding(6)
                    .background(
                        RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                            .fill(HavenColors.beige100)
                    )

                    VStack(spacing: 16) {
                        if mode == .signUp {
                            HavenTextField(title: "First name", text: $viewModel.firstName)
                                .textContentType(.givenName)
                            HavenTextField(title: "Last name", text: $viewModel.lastName)
                                .textContentType(.familyName)
                        }

                        HavenTextField(title: "Email", text: $viewModel.email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            // Sprint #3 R3-E-5: clear stale validation
                            // error as soon as the user edits / pastes
                            // into the field. Without this the
                            // "Please enter your email." caption
                            // persists despite the visible field
                            // showing a valid pasted value.
                            .onChange(of: viewModel.email) { _, _ in
                                if viewModel.errorMessage != nil {
                                    viewModel.errorMessage = nil
                                }
                            }

                        HavenTextField(title: "Password", text: $viewModel.password, isSecure: true)
                            .textContentType(.password)
                            // Sprint #3 R3-E-5: same stale-validation
                            // clear pattern for password.
                            .onChange(of: viewModel.password) { _, _ in
                                if viewModel.errorMessage != nil {
                                    viewModel.errorMessage = nil
                                }
                            }

                        if mode == .signUp {
                            HavenTextField(title: "Confirm password", text: $viewModel.confirmPassword, isSecure: true)
                                .textContentType(.password)
                        }

                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(HavenTypography.caption)
                                .foregroundStyle(HavenColors.critical)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }

                    VStack(spacing: 12) {
                        HavenButton(title: primaryButtonTitle) {
                            Task {
                                if mode == .signIn {
                                    await viewModel.signIn(authService: appState.authService)
                                } else {
                                    await viewModel.signUp(authService: appState.authService)
                                }
                            }
                        }
                        .disabled(viewModel.isLoading)

                        Button {
                            appleSignIn.onCredential = { credential in
                                Task {
                                    do {
                                        try await appState.authService.signInWithApple(credential: credential)
                                    } catch {
                                        viewModel.errorMessage = "Apple sign-in failed. Please try again."
                                    }
                                }
                            }
                            appleSignIn.onError = { error in
                                let friendly = AppleSignInCoordinator.friendlyMessage(for: error)
                                viewModel.errorMessage = friendly.isEmpty ? nil : friendly
                            }
                            appleSignIn.startSignInFlow()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "apple.logo")
                                    .font(.system(size: 18, weight: .medium))
                                Text("Continue with Apple")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.black)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                        }

                        if mode == .signIn {
                            Button("Forgot Password?") {
                                viewModel.showForgotPassword = true
                            }
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textPrimary)
                        }
                    }

                    VStack(spacing: 8) {
                        Text(mode == .signIn ? "Need an account?" : "Already have an account?")
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)
                        Button(mode == .signIn ? "Create it here" : "Sign in instead") {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                mode = mode == .signIn ? .signUp : .signIn
                                viewModel.errorMessage = nil
                            }
                        }
                        .font(HavenTypography.uiLabel)
                        .foregroundStyle(HavenColors.action)

                        Link("Open desktop command center", destination: URL(string: "https://getchez.com/handyman")!)
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textPrimary)
                    }
                }
                .padding(.horizontal, HavenTheme.padding)
                .padding(.bottom, 32)
            }
            .background(HavenColors.background.ignoresSafeArea())
            .navigationTitle("Sign In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Back") {
                        onBack()
                    }
                    .foregroundStyle(HavenColors.textPrimary)
                }
            }
            .sheet(isPresented: $viewModel.showForgotPassword, onDismiss: {
                // Drop any stale error so re-opening the sheet starts clean.
                viewModel.resetPasswordError = nil
            }) {
                NavigationStack {
                    VStack(spacing: 24) {
                        VStack(spacing: 8) {
                            Image(systemName: "key.fill")
                                .font(.system(size: 44))
                                .foregroundStyle(HavenColors.textPrimary)
                            Text("Reset Password")
                                .font(HavenTypography.title2)
                            Text("Enter your work email and we’ll send a reset link.")
                                .font(HavenTypography.bodySmall)
                                .foregroundStyle(HavenColors.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 24)

                        HavenTextField(title: "Email", text: $viewModel.email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .onChange(of: viewModel.email) { _, newValue in
                                // Clear stale validation error once the user starts typing.
                                if !newValue.trimmingCharacters(in: .whitespaces).isEmpty {
                                    viewModel.resetPasswordError = nil
                                }
                            }

                        if let resetError = viewModel.resetPasswordError, !resetError.isEmpty {
                            Text(resetError)
                                .font(HavenTypography.caption)
                                .foregroundStyle(HavenColors.critical)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        HavenButton(title: viewModel.isLoading ? "Sending..." : "Send Reset Link") {
                            Task { await viewModel.resetPassword(authService: appState.authService) }
                        }
                        .disabled(viewModel.isLoading)
                    }
                    .padding()
                    .presentationDetents([.height(380)])
                    .navigationTitle("Reset Password")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { viewModel.showForgotPassword = false }
                        }
                    }
                }
            }
            .alert("Check Your Email", isPresented: $viewModel.resetEmailSent) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("If an account exists with that email, you’ll receive a reset link shortly.")
            }
            .alert("Check your email", isPresented: $viewModel.confirmationEmailSent) {
                Button("OK", role: .cancel) {
                    mode = .signIn
                }
            } message: {
                Text("Your account was created. Confirm your email, then come back here and sign in to finish setting up Chez Field.")
            }
        }
    }

    private var primaryButtonTitle: String {
        if viewModel.isLoading {
            return mode == .signIn ? "Signing in..." : "Creating account..."
        }
        return mode == .signIn ? "Sign In" : "Create Account"
    }

    @ViewBuilder
    private func authModeButton(_ title: String, mode buttonMode: HavenFieldAuthMode) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                mode = buttonMode
                viewModel.errorMessage = nil
            }
        } label: {
            Text(title)
                .font(HavenTypography.uiLabel)
                .foregroundStyle(mode == buttonMode ? Color.white : HavenColors.navy900)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                        .fill(mode == buttonMode ? HavenColors.action : Color.clear)
                )
        }
        .buttonStyle(.plain)
    }
}

private struct HavenFieldWorkspaceSetupView: View {
    @EnvironmentObject private var appState: AppState
    @State private var fullName = ""
    @State private var companyName = ""
    @State private var phone = ""
    @State private var website = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var didPrefill = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Image("ChezFieldBrand")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 280)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .shadow(color: HavenColors.navy900.opacity(0.12), radius: 22, x: 0, y: 12)

                    FieldAuthInfoCard(
                        title: "Finish your field workspace",
                        copy: "One quick setup turns this login into the owner account for your company. After that, Chez Field will open directly into visits, messages, and today's work."
                    )

                    VStack(spacing: 16) {
                        HavenTextField(title: "Your name", text: $fullName)
                            .textContentType(.name)
                        HavenTextField(title: "Company name", text: $companyName)
                            .textContentType(.organizationName)
                        HavenTextField(title: "Phone", text: $phone)
                            .keyboardType(.phonePad)
                            .textContentType(.telephoneNumber)
                        HavenTextField(title: "Website (optional)", text: $website)
                            .keyboardType(.URL)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }

                    if let email = appState.fieldDashboard?.currentUser?.email, !email.isEmpty {
                        FieldAuthInfoCard(
                            title: "Signed in as \(email)",
                            copy: "If this is the business owner email you used on desktop, using the same company details here will restore the field workspace on this device."
                        )
                    }

                    if let errorMessage, !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.critical)
                    }

                    VStack(spacing: 12) {
                        HavenButton(title: isLoading ? "Setting up workspace..." : "Enter Chez Field") {
                            Task { await bootstrapWorkspace() }
                        }
                        .disabled(isLoading)

                        Link(destination: URL(string: "https://getchez.com/handyman")!) {
                            Text("Open desktop command center")
                                .font(HavenTypography.uiLabel)
                                .foregroundStyle(HavenColors.textPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                                        .stroke(HavenColors.beige400, lineWidth: 1)
                                )
                        }

                        Button("Sign out") {
                            appState.authService.signOut()
                        }
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                    }
                }
                .padding(.horizontal, HavenTheme.padding)
                .padding(.vertical, 24)
            }
            .background(HavenColors.background.ignoresSafeArea())
            .navigationTitle("Set Up")
            .navigationBarTitleDisplayMode(.inline)
        }
        .task { await prefillIfNeeded() }
    }

    private func prefillIfNeeded() async {
        guard !didPrefill else { return }
        didPrefill = true
        if let dashName = appState.fieldDashboard?.currentUser?.fullName, !dashName.isEmpty {
            fullName = dashName
            return
        }
        // Fallback: read the name out of the Supabase auth session metadata.
        // Stamped at signup so it's available even when fetchDashboard threw
        // and fieldDashboard is nil (the path that used to dead-end users).
        if let session = try? await HavenSupabase.auth.session {
            if let metaName = session.user.userMetadata["full_name"]?.value as? String, !metaName.isEmpty {
                fullName = metaName
                return
            }
            let first = (session.user.userMetadata["first_name"]?.value as? String) ?? ""
            let last = (session.user.userMetadata["last_name"]?.value as? String) ?? ""
            let combined = [first, last].filter { !$0.isEmpty }.joined(separator: " ")
            if !combined.isEmpty {
                fullName = combined
            }
        }
    }

    private func bootstrapWorkspace() async {
        let trimmedName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCompany = companyName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPhone = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedWebsite = website.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else {
            errorMessage = "Enter your name so Chez Field can label the owner account correctly."
            return
        }
        guard !trimmedCompany.isEmpty else {
            errorMessage = "Enter your company name to finish setting up the field workspace."
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let dashboard = try await HavenFieldService.shared.bootstrapWorkspace(
                fullName: trimmedName,
                companyName: trimmedCompany,
                phone: trimmedPhone,
                website: trimmedWebsite
            )
            appState.fieldDashboard = dashboard
            if dashboard.needsWorkspace {
                appState.activeExperience = .homeowner
                appState.needsOnboarding = false
                appState.primaryProperty = nil
                appState.hasCheckedPrimaryProperty = true
            } else {
                HavenFieldCache.saveDashboard(dashboard)
                appState.activeExperience = .field
                appState.needsOnboarding = false
                appState.primaryProperty = nil
                appState.hasCheckedPrimaryProperty = true
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct FieldAuthInfoCard: View {
    let title: String
    let copy: String

    var bodyView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(HavenTypography.title3)
                .foregroundStyle(HavenColors.textPrimary)
            Text(copy)
                .font(HavenTypography.body)
                .foregroundStyle(HavenColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(HavenColors.beige300, lineWidth: 1)
        )
    }

    var body: some View { bodyView }
}

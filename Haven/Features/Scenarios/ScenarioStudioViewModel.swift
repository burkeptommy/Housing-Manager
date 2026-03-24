import Foundation
import Combine

// MARK: - Recent Scenario Model

struct RecentScenario: Identifiable {
    let id: UUID
    let title: String
    let timestamp: Date
    let cachedResult: ScenarioResult
}

// MARK: - View Model

@MainActor
final class ScenarioStudioViewModel: ObservableObject {
    @Published var recentScenarios: [RecentScenario] = []
    @Published var error: String?

    /// Reference to the shared background runner
    let runner = ScenarioRunnerService.shared

    private var householdId: UUID?
    private var cancellables = Set<AnyCancellable>()

    // Show 8 random inspiration chips
    let inspirationChips: [String] = {
        Array(ScenarioStudioViewModel.allInspirationChips.shuffled().prefix(8))
    }()

    init() {
        // Forward runner errors to local error for display
        runner.$completedError
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] err in
                Analytics.track(.scenarioFailed, ["error": String(err.prefix(200))])
                self?.error = err
            }
            .store(in: &cancellables)

        // When a result completes, refresh history
        runner.$completedResult
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                Task { await self?.loadRecentScenarios() }
            }
            .store(in: &cancellables)
    }

    func loadHousehold() async {
        do {
            let user = try await DatabaseService.shared.fetchCurrentUser()
            householdId = user.householdId
            if let id = user.householdId {
                runner.setHouseholdId(id)
            }
        } catch {
            self.error = "Could not load your household data."
        }
    }

    // MARK: - Run Scenarios (delegates to background runner)

    func runScenario(id: String, params: [String: String]? = nil) {
        error = nil
        runner.runScenario(id: id, params: params)
    }

    func runCustomScenario(query: String) {
        error = nil
        runner.runCustomScenario(query: query)
    }

    // MARK: - Scenario History

    @Published var allScenarios: [RecentScenario] = []

    func loadRecentScenarios() async {
        guard let householdId else { return }
        do {
            struct HistoryRow: Decodable {
                let id: UUID
                let scenario_id: String?
                let custom_query: String?
                let result_json: String?
                let created_at: String
            }

            let rows: [HistoryRow] = try await HavenSupabase.from("scenario_history")
                .select()
                .eq("household_id", value: householdId.uuidString)
                .order("created_at", ascending: false)
                .limit(50)
                .execute()
                .value

            let parsed: [RecentScenario] = rows.compactMap { row in
                guard let jsonStr = row.result_json,
                      let jsonData = jsonStr.data(using: .utf8),
                      let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
                else { return nil }

                let result = ScenarioResult(from: json)

                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                let date = formatter.date(from: row.created_at) ?? Date()

                return RecentScenario(
                    id: row.id,
                    title: result.title,
                    timestamp: date,
                    cachedResult: result
                )
            }

            allScenarios = parsed
            recentScenarios = Array(parsed.prefix(5))
        } catch {
            print("[Scenario] Failed to load history: \(error)")
        }
    }

    // MARK: - Inspiration Chips

    static let allInspirationChips: [String] = [
        "What if we both died tomorrow?",
        "What happens if I become incapacitated?",
        "What goes through probate in my estate?",
        "Is my family protected if something happens to me?",
        "What if my successor trustee can't serve?",
        "Are my beneficiary designations up to date?",
        "What if I created an irrevocable trust?",
        "How can I reduce my tax bill next year?",
        "What if I hired my kids in my business?",
        "Should I convert my IRA to a Roth?",
        "What tax deductions am I missing?",
        "What if I maxed out all retirement accounts?",
        "Can I deduct a home office?",
        "What if I did a cost segregation study?",
        "How do I minimize capital gains when I sell?",
        "What is my house worth today?",
        "What if I sold my house right now?",
        "Should I refinance my mortgage?",
        "What if I rented out my house?",
        "What renovations have the best ROI?",
        "What if I added solar panels?",
        "What if I finished my basement?",
        "What if my house was destroyed in a fire?",
        "Is my home properly insured?",
        "What if I bought a rental property?",
        "What if I did a cash-out refinance?",
        "How do I build generational wealth?",
        "Should I elect S-Corp for my LLC?",
        "What if I set up a SEP-IRA?",
        "How much should I be saving for retirement?",
        "Am I on track to retire by 55?",
        "What if I invested $500/month for 20 years?",
        "Should I buy life insurance inside a trust?",
        "What if I gifted $18K to each kid annually?",
        "How do I protect assets from lawsuits?",
        "Will the 529s be enough for college?",
        "What if college costs double by then?",
        "Can I use 529 money for private school?",
        "What if one kid gets a scholarship?",
        "Should I superfund the 529s?",
        "What if I set up a Roth IRA for my kids?",
        "Do I have enough life insurance?",
        "What if I got sued for $2 million?",
        "Do I need long-term care insurance?",
        "Is my umbrella policy large enough?",
        "What gaps exist in my insurance coverage?",
        "What if we had another baby?",
        "What if I inherited $500K from a parent?",
        "What if one of us lost their job?",
        "What if we moved to a no-income-tax state?",
        "What if I bought a vacation home?",
        "What if I wanted to retire early at 50?",
        "What should I do before the end of this tax year?",
        "Walk me through my complete financial picture",
    ]
}

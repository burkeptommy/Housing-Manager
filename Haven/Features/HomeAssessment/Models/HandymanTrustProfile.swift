import Foundation

// MARK: - HandymanTrustProfile (Phase 85 PR 3)
//
// Codable mapping of the public.handyman_member_stats view. Powers the
// iOS PreVisitTrustCard that surfaces who's coming to the homeowner's
// house before the assessment visit.
//
// Schema lives in 20261214_handyman_profiles_and_reviews.sql.

struct HandymanTrustProfile: Codable, Identifiable {
    let handymanMemberId: UUID
    let workspaceId: UUID
    let userId: UUID
    let displayName: String?
    let photoUrl: String?
    let bio: String?
    let yearsInBusiness: Int?
    let specialties: [String]
    let licenseNumber: String?
    let licenseState: String?
    let licenseVerifiedAt: Date?
    let insuranceCarrier: String?
    let insuranceExpiry: Date?
    let insuranceVerifiedAt: Date?
    let backgroundCheckCompletedAt: Date?
    let backgroundCheckProvider: String?
    let vehiclePhotoUrl: String?
    let reviewCount: Int
    let avgRating: Double?

    var id: UUID { handymanMemberId }

    enum CodingKeys: String, CodingKey {
        case handymanMemberId = "handyman_member_id"
        case workspaceId = "workspace_id"
        case userId = "user_id"
        case displayName = "display_name"
        case photoUrl = "photo_url"
        case bio
        case yearsInBusiness = "years_in_business"
        case specialties
        case licenseNumber = "license_number"
        case licenseState = "license_state"
        case licenseVerifiedAt = "license_verified_at"
        case insuranceCarrier = "insurance_carrier"
        case insuranceExpiry = "insurance_expiry"
        case insuranceVerifiedAt = "insurance_verified_at"
        case backgroundCheckCompletedAt = "background_check_completed_at"
        case backgroundCheckProvider = "background_check_provider"
        case vehiclePhotoUrl = "vehicle_photo_url"
        case reviewCount = "review_count"
        case avgRating = "avg_rating"
    }

    /// Resilient decoder per CLAUDE.md.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.handymanMemberId = try c.decode(UUID.self, forKey: .handymanMemberId)
        self.workspaceId = try c.decode(UUID.self, forKey: .workspaceId)
        self.userId = try c.decode(UUID.self, forKey: .userId)
        self.displayName = try? c.decodeIfPresent(String.self, forKey: .displayName)
        self.photoUrl = try? c.decodeIfPresent(String.self, forKey: .photoUrl)
        self.bio = try? c.decodeIfPresent(String.self, forKey: .bio)
        self.yearsInBusiness = try? c.decodeIfPresent(Int.self, forKey: .yearsInBusiness)
        self.specialties = (try? c.decodeIfPresent([String].self, forKey: .specialties)) ?? []
        self.licenseNumber = try? c.decodeIfPresent(String.self, forKey: .licenseNumber)
        self.licenseState = try? c.decodeIfPresent(String.self, forKey: .licenseState)
        self.licenseVerifiedAt = try? c.decodeIfPresent(Date.self, forKey: .licenseVerifiedAt)
        self.insuranceCarrier = try? c.decodeIfPresent(String.self, forKey: .insuranceCarrier)
        self.insuranceExpiry = try? c.decodeIfPresent(Date.self, forKey: .insuranceExpiry)
        self.insuranceVerifiedAt = try? c.decodeIfPresent(Date.self, forKey: .insuranceVerifiedAt)
        self.backgroundCheckCompletedAt = try? c.decodeIfPresent(Date.self, forKey: .backgroundCheckCompletedAt)
        self.backgroundCheckProvider = try? c.decodeIfPresent(String.self, forKey: .backgroundCheckProvider)
        self.vehiclePhotoUrl = try? c.decodeIfPresent(String.self, forKey: .vehiclePhotoUrl)
        self.reviewCount = (try? c.decodeIfPresent(Int.self, forKey: .reviewCount)) ?? 0
        self.avgRating = try? c.decodeIfPresent(Double.self, forKey: .avgRating)
    }
}

// MARK: - Display helpers

extension HandymanTrustProfile {
    /// What homeowner sees as the handyman's name. Falls back to a
    /// generic placeholder if not yet filled in.
    var presentationName: String {
        displayName ?? "Your Chez handyman"
    }

    /// Pre-formatted rating label like "4.8 ★ · 47 reviews", or nil if
    /// no reviews yet.
    var ratingLabel: String? {
        guard reviewCount > 0, let avg = avgRating else { return nil }
        let formatted = String(format: "%.1f", avg)
        return "\(formatted) ★ · \(reviewCount) review\(reviewCount == 1 ? "" : "s")"
    }

    /// Insurance label: "Insured through Apr 2026" if expiry set,
    /// "Insured" if carrier set but no expiry, nil otherwise.
    var insuranceLabel: String? {
        if let expiry = insuranceExpiry {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM yyyy"
            return "Insured through \(formatter.string(from: expiry))"
        }
        if insuranceCarrier != nil {
            return "Insured"
        }
        return nil
    }

    /// License label: "License #12345 · NY" or nil.
    var licenseLabel: String? {
        guard let number = licenseNumber else { return nil }
        if let state = licenseState {
            return "License #\(number) · \(state)"
        }
        return "License #\(number)"
    }

    /// Background-check label: "Background check · Checkr" or nil.
    var backgroundCheckLabel: String? {
        guard backgroundCheckCompletedAt != nil else { return nil }
        if let provider = backgroundCheckProvider {
            return "Background check · \(provider)"
        }
        return "Background check verified"
    }

    /// Whether ALL three credentials are admin-verified. Drives the
    /// "Chez Verified" master badge on the trust card.
    var isFullyVerified: Bool {
        licenseVerifiedAt != nil && insuranceVerifiedAt != nil && backgroundCheckCompletedAt != nil
    }
}

import SwiftUI

/// Three-tier logo fallback for vendor/contractor rows in list contexts.
/// Uses rounded squares (8pt radius) -- circles are reserved for people avatars.
///
/// Fallback tiers:
/// 1. Brandfetch logo (from logoUrl)
/// 2. Category SF Symbol (mapped from category string)
/// 3. Initials from vendor name
struct VendorLogoView: View {
    var logoUrl: String?
    var category: String?
    var vendorName: String?
    var specialties: [String]?
    var size: CGFloat = 40

    /// Convenience init from a ContractorRow.
    init(contractor: ContractorRow, size: CGFloat = 40) {
        self.logoUrl = contractor.logoUrl
        self.category = contractor.category
        self.vendorName = contractor.companyName
        self.specialties = contractor.specialties
        self.size = size
    }

    /// Standalone init for non-contractor contexts (e.g. category-only icons).
    init(logoUrl: String? = nil, category: String? = nil, vendorName: String? = nil, size: CGFloat = 40) {
        self.logoUrl = logoUrl
        self.category = category
        self.vendorName = vendorName
        self.size = size
    }

    var body: some View {
        Group {
            if let logoUrlString = logoUrl,
               let url = URL(string: logoUrlString) {
                // Tier 1: Brand logo
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .padding(size * 0.15)
                    default:
                        categoryIconOrInitials
                    }
                }
            } else {
                categoryIconOrInitials
            }
        }
        .frame(width: size, height: size)
        .background(HavenColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(HavenColors.beige200, lineWidth: 1))
    }

    @ViewBuilder
    private var categoryIconOrInitials: some View {
        if let symbolName = Self.categorySymbol(for: category)
            ?? specialties?.lazy.compactMap({ Self.categorySymbol(for: $0) }).first {
            // Tier 2: Category icon
            Image(systemName: symbolName)
                .font(.system(size: size * 0.4, weight: .medium))
                .foregroundStyle(HavenColors.textPrimary)
        } else if let name = vendorName, !name.isEmpty {
            // Tier 3: Initials
            Text(Self.initials(from: name))
                .font(.system(size: size * 0.36, weight: .semibold))
                .foregroundStyle(HavenColors.textPrimary)
        } else {
            // Tier 3 fallback: generic icon
            Image(systemName: "wrench.and.screwdriver")
                .font(.system(size: size * 0.4, weight: .medium))
                .foregroundStyle(HavenColors.navy.opacity(0.4))
        }
    }

    /// Extract first letters of up to 2 words.
    static func initials(from name: String) -> String {
        let words = name.split(separator: " ").prefix(2)
        return words.map { String($0.prefix(1)).uppercased() }.joined()
    }

    static func categorySymbol(for category: String?) -> String? {
        guard let cat = category?.lowercased() else { return nil }
        // Phase 56.1: match "pet" against waste categories ("pet waste",
        // "pet waste removal") before the generic "waste" branch so they
        // land on a paw instead of a trash can.
        if cat.contains("pet") { return "pawprint.fill" }
        switch cat {
        case let c where c.contains("security"):    return "lock.shield"
        case let c where c.contains("landscap"):    return "leaf"
        case let c where c.contains("pest"):        return "ant"
        case let c where c.contains("mosquito"),
             let c where c.contains("tick"):        return "ladybug.fill"
        case let c where c.contains("plumb"):       return "drop.fill"
        case let c where c.contains("hvac"),
             let c where c.contains("heat"),
             let c where c.contains("air"):         return "wind"
        case let c where c.contains("electric"):    return "bolt.fill"
        case let c where c.contains("clean"):       return "sparkles"
        case let c where c.contains("internet"),
             let c where c.contains("cable"):       return "wifi"
        case let c where c.contains("trash"),
             let c where c.contains("waste"):       return "trash"
        case let c where c.contains("snow"):        return "snowflake"
        case let c where c.contains("oil"),
             let c where c.contains("propane"),
             let c where c.contains("fuel"):        return "fuelpump.fill"
        case let c where c.contains("insur"):       return "shield.fill"
        case let c where c.contains("attorney"),
             let c where c.contains("legal"):       return "building.columns.fill"
        case let c where c.contains("financ"),
             let c where c.contains("advisor"),
             let c where c.contains("cpa"),
             let c where c.contains("tax"):         return "chart.line.uptrend.xyaxis"
        case let c where c.contains("generator"):   return "bolt.batteryblock.fill"
        case let c where c.contains("contractor"),
             let c where c.contains("builder"),
             let c where c.contains("handyman"):    return "hammer.fill"
        case let c where c.contains("pool"):        return "drop.triangle.fill"
        case let c where c.contains("roof"):        return "house.fill"
        case let c where c.contains("tree"):        return "tree.fill"
        case let c where c.contains("chimney"):     return "fireplace.fill"
        case let c where c.contains("septic"):      return "arrow.down.to.line"
        case let c where c.contains("well"):        return "drop.circle.fill"
        case let c where c.contains("solar"):       return "sun.max.fill"
        case let c where c.contains("garage"):      return "door.garage.closed"
        case let c where c.contains("paint"):       return "paintbrush.fill"
        case let c where c.contains("flooring"),
             let c where c.contains("carpet"):      return "square.grid.3x3"
        default: return nil
        }
    }
}

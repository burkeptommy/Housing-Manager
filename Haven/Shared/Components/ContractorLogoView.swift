import SwiftUI

/// Three-tier logo fallback for contractor rows:
/// 1. Brandfetch logo (if logoUrl exists)
/// 2. Category SF Symbol (mapped from contractor.category)
/// 3. Default person icon
struct ContractorLogoView: View {
    let contractor: ContractorRow
    var size: CGFloat = 36

    var body: some View {
        Group {
            if let logoUrlString = contractor.logoUrl,
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
                        categoryIconOrDefault
                    }
                }
            } else {
                categoryIconOrDefault
            }
        }
        .frame(width: size, height: size)
        .background(HavenColors.surface)
        .clipShape(Circle())
        .overlay(Circle().stroke(HavenColors.beige200, lineWidth: 1))
    }

    @ViewBuilder
    private var categoryIconOrDefault: some View {
        if let symbolName = Self.categorySymbol(for: contractor.category)
            ?? contractor.specialties?.lazy.compactMap({ Self.categorySymbol(for: $0) }).first {
            // Tier 2: Category icon
            Image(systemName: symbolName)
                .font(.system(size: size * 0.4, weight: .medium))
                .foregroundStyle(HavenColors.navy)
        } else {
            // Tier 3: Default
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: size * 0.6, weight: .regular))
                .foregroundStyle(HavenColors.navy.opacity(0.4))
        }
    }

    static func categorySymbol(for category: String?) -> String? {
        guard let cat = category?.lowercased() else { return nil }
        switch cat {
        case let c where c.contains("security"):    return "lock.shield"
        case let c where c.contains("landscap"):    return "leaf"
        case let c where c.contains("pest"):        return "ant"
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

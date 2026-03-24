import SwiftUI

// MARK: - Project Category

enum ProjectCategory: String, CaseIterable, Identifiable {
    case kitchen = "Kitchen Renovation"
    case bathroom = "Bathroom Renovation"
    case flooring = "Flooring"
    case painting = "Painting"
    case roofing = "Roofing"
    case windows = "Windows & Doors"
    case deck = "Deck / Patio"
    case landscaping = "Landscaping"
    case electrical = "Electrical"
    case plumbing = "Plumbing"
    case hvac = "HVAC"
    case basement = "Basement"
    case garage = "Garage"
    case builtins = "Built-ins & Shelving"
    case fencing = "Fencing"
    case siding = "Siding / Exterior"
    case insulation = "Insulation"
    case smartHome = "Smart Home"
    case additions = "Additions"
    case other = "Other"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .kitchen: return "fork.knife"
        case .bathroom: return "shower.fill"
        case .flooring: return "square.grid.3x3.topleft.filled"
        case .painting: return "paintbrush.fill"
        case .roofing: return "house.lodge.fill"
        case .windows: return "window.horizontal"
        case .deck: return "sun.and.horizon.fill"
        case .landscaping: return "leaf.fill"
        case .electrical: return "bolt.fill"
        case .plumbing: return "drop.fill"
        case .hvac: return "fan.fill"
        case .basement: return "stairs"
        case .garage: return "car.fill"
        case .builtins: return "books.vertical.fill"
        case .fencing: return "fence.fill"
        case .siding: return "building.2.fill"
        case .insulation: return "thermometer.snowflake"
        case .smartHome: return "homekit"
        case .additions: return "plus.square.on.square"
        case .other: return "hammer.fill"
        }
    }
}

// MARK: - Project Status

enum ProjectStatus: String, CaseIterable {
    case planning, inProgress = "in_progress", completed, onHold = "on_hold"

    var displayName: String {
        switch self {
        case .planning: return "Planning"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        case .onHold: return "On Hold"
        }
    }

    var color: Color {
        switch self {
        case .planning: return HavenColors.info
        case .inProgress: return HavenColors.warning
        case .completed: return HavenColors.success
        case .onHold: return HavenColors.textTertiary
        }
    }

    var icon: String {
        switch self {
        case .planning: return "lightbulb.fill"
        case .inProgress: return "hammer.fill"
        case .completed: return "checkmark.circle.fill"
        case .onHold: return "pause.circle.fill"
        }
    }
}

// MARK: - Project Type (DIY vs Pro)

enum ProjectApproach: String, CaseIterable {
    case diy, professional, undecided

    var displayName: String {
        switch self {
        case .diy: return "DIY"
        case .professional: return "Hire a Pro"
        case .undecided: return "Not Sure Yet"
        }
    }

    var icon: String {
        switch self {
        case .diy: return "hammer.fill"
        case .professional: return "person.badge.shield.checkmark.fill"
        case .undecided: return "questionmark.circle.fill"
        }
    }
}

// MARK: - Line Item Category

enum LineItemCategory: String, CaseIterable {
    case materials, tools, permits, labor, rental, other

    var displayName: String { rawValue.capitalized }

    var icon: String {
        switch self {
        case .materials: return "shippingbox.fill"
        case .tools: return "wrench.fill"
        case .permits: return "doc.text.fill"
        case .labor: return "person.fill"
        case .rental: return "clock.arrow.2.circlepath"
        case .other: return "ellipsis.circle.fill"
        }
    }
}

// MARK: - Item Units

enum ItemUnit: String, CaseIterable {
    case each, sqFt = "sq ft", linearFt = "linear ft"
    case gallon, quart, hour, bundle, box, bag, roll, sheet, set
}

// MARK: - Necessity Group (for line item sectioning)

enum NecessityGroup: String, CaseIterable {
    case required
    case optional
    case likelyOwned = "likely_owned"

    var displayName: String {
        switch self {
        case .required: return "REQUIRED"
        case .optional: return "OPTIONAL"
        case .likelyOwned: return "YOU MAY ALREADY HAVE"
        }
    }

    var icon: String {
        switch self {
        case .required: return "checkmark.circle.fill"
        case .optional: return "sparkles"
        case .likelyOwned: return "house.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .required: return HavenColors.textPrimary
        case .optional: return HavenColors.info
        case .likelyOwned: return HavenColors.textTertiary
        }
    }
}

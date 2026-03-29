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
        case .fencing: return "square.split.2x2"
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
    case diy, professional

    var displayName: String {
        switch self {
        case .diy: return "DIY"
        case .professional: return "Hiring a Pro"
        }
    }

    var icon: String {
        switch self {
        case .diy: return "hammer.fill"
        case .professional: return "person.badge.shield.checkmark.fill"
        }
    }
}

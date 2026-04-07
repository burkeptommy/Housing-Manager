import SwiftUI

/// Contextual subtype picker shown in AddSystemView/EditSystemSheet.
/// Renders only for categories where subtype meaningfully changes the maintenance task set
/// (Landscaping, HVAC, Water Heater, Pool/Spa, Roofing). Otherwise renders nothing.
struct SystemSubtypePicker: View {
    let category: String
    @Binding var subtype: String?

    var body: some View {
        if let options = Self.options(for: category) {
            Picker(options.label, selection: Binding(
                get: { subtype ?? options.defaultValue },
                set: { subtype = $0 }
            )) {
                ForEach(options.choices, id: \.value) { choice in
                    Text(choice.label).tag(choice.value)
                }
            }
        }
    }

    struct Choice { let label: String; let value: String }
    struct Options { let label: String; let defaultValue: String; let choices: [Choice] }

    static func options(for category: String) -> Options? {
        switch category.lowercased() {
        case "landscaping":
            return Options(label: "Yard Type", defaultValue: "lawn", choices: [
                Choice(label: "Natural Lawn", value: "lawn"),
                Choice(label: "Artificial Turf", value: "turf"),
                Choice(label: "Xeriscape", value: "xeriscape"),
                Choice(label: "No Yard", value: "none"),
            ])
        case "hvac":
            return Options(label: "HVAC Type", defaultValue: "central_ducted", choices: [
                Choice(label: "Central (Ducted)", value: "central_ducted"),
                Choice(label: "Heat Pump", value: "heat_pump"),
                Choice(label: "Ductless Mini-Split", value: "mini_split"),
                Choice(label: "Boiler / Radiant", value: "boiler_radiant"),
                Choice(label: "Window Units", value: "window_units"),
                Choice(label: "Geothermal", value: "geothermal"),
            ])
        case "water heater":
            return Options(label: "Water Heater Type", defaultValue: "tank", choices: [
                Choice(label: "Tank", value: "tank"),
                Choice(label: "Tankless", value: "tankless"),
                Choice(label: "Hybrid Heat Pump", value: "hybrid_heat_pump"),
                Choice(label: "Solar", value: "solar"),
            ])
        case "pool/spa", "pool":
            return Options(label: "Pool Type", defaultValue: "chlorine", choices: [
                Choice(label: "Chlorine", value: "chlorine"),
                Choice(label: "Saltwater", value: "saltwater"),
                Choice(label: "Natural / Bio", value: "natural_bio"),
                Choice(label: "None", value: "none"),
            ])
        case "roofing":
            return Options(label: "Roof Type", defaultValue: "asphalt_shingle", choices: [
                Choice(label: "Asphalt Shingle", value: "asphalt_shingle"),
                Choice(label: "Metal", value: "metal"),
                Choice(label: "Tile", value: "tile"),
                Choice(label: "Flat / Membrane", value: "flat_membrane"),
                Choice(label: "Wood Shake", value: "wood_shake"),
                Choice(label: "Slate", value: "slate"),
            ])
        default:
            return nil
        }
    }
}

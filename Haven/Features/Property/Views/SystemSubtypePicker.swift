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
                get: { Self.normalize(subtype: subtype, category: category, defaultValue: options.defaultValue) },
                set: { subtype = $0 }
            )) {
                ForEach(options.choices, id: \.value) { choice in
                    Text(choice.label).tag(choice.value)
                }
            }
        }
    }

    /// Maps legacy subtype values to their current canonical equivalents so the
    /// picker displays the right selection for systems created before later
    /// phases renamed the subtype. Returns the input unchanged if no migration
    /// applies. This is read-only — the DB still has the legacy value until the
    /// user touches the picker, at which point the new value gets written.
    private static func normalize(subtype: String?, category: String, defaultValue: String) -> String {
        guard let raw = subtype, !raw.isEmpty else { return defaultValue }
        switch category.lowercased() {
        case "landscaping":
            // Phase 19j renamed "lawn" → "natural_lawn". Old systems still
            // have "lawn" in the DB; activeSubtypes treats both as equivalent
            // but the picker UI needs to render the new name.
            if raw == "lawn" { return "natural_lawn" }
            // Phase 18-era values "turf"/"xeriscape"/"none" no longer map to
            // any active subtype. Show synthetic_turf as the closest match
            // for "turf"; everything else falls back to the default.
            if raw == "turf" { return "synthetic_turf" }
            if raw == "xeriscape" || raw == "none" { return defaultValue }
            return raw
        default:
            return raw
        }
    }

    struct Choice { let label: String; let value: String }
    struct Options { let label: String; let defaultValue: String; let choices: [Choice] }

    static func options(for category: String) -> Options? {
        switch category.lowercased() {
        case "landscaping":
            // Phase 19j: matches MaintenanceTemplates.activeSubtypes for landscaping.
            // Only natural_lawn and synthetic_turf are recognized — "mixed" households
            // get TWO separate Landscaping system rows from the quiz answer mapper, so
            // the picker (which edits a single system) doesn't offer "mixed" as an option.
            // The legacy "lawn" value is preserved as the default for backward compat
            // with pre-Phase-19j systems — `activeSubtypes` treats it as natural_lawn.
            return Options(label: "Yard Type", defaultValue: "natural_lawn", choices: [
                Choice(label: "Natural Grass", value: "natural_lawn"),
                Choice(label: "Synthetic Turf", value: "synthetic_turf"),
            ])
        case "hvac":
            // Phase 19b/19c: full subtype list matches q3b_hvac_type quiz options
            // and the activeSubtypes mapping in MaintenanceTemplates. The "Not sure"
            // option is the safe default for households that haven't confirmed their
            // exact configuration yet — falls back to universal HVAC tune-ups only.
            return Options(label: "HVAC Type", defaultValue: "central_ducted", choices: [
                Choice(label: "Central (Ducted)", value: "central_ducted"),
                Choice(label: "Ductless Mini-Split", value: "mini_split"),
                Choice(label: "Boiler + Central AC", value: "boiler_with_central_ac"),
                Choice(label: "Boiler / Radiators", value: "boiler_radiant"),
                Choice(label: "Boiler + Window AC", value: "boiler_with_window_ac"),
                Choice(label: "Heat Pump", value: "heat_pump"),
                Choice(label: "Geothermal", value: "geothermal"),
                Choice(label: "Window Units", value: "window_units"),
                Choice(label: "Not Sure", value: "not_sure"),
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

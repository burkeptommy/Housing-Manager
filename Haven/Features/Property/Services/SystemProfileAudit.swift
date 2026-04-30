import Foundation

/// Single source of truth for "what details does this system actually
/// need?". Driven by the system's category — Crawl Space doesn't need
/// brand/model/serial, but a generator does. The Overview "Systems
/// missing profile" card and the SystemDetailView "Profile to finish"
/// checklist both consume this so the list of asks stays consistent.
///
/// Audit lives here (not on SystemDetailView) so PropertyDetailView can
/// compute completeness across the whole property without instantiating
/// every detail view.
enum SystemProfileAudit {
    struct Item: Identifiable, Hashable {
        let id: String
        let title: String
        let detail: String
    }

    /// Computes the missing-detail checklist for a single system.
    /// Pass any warranties / service records the caller has already
    /// loaded — the audit will treat their presence as completion
    /// signals where it makes sense (roof warranty, septic pump-out
    /// history, HVAC service log).
    static func missingItems(
        for system: HomeSystemRow,
        warranties: [WarrantyRow] = [],
        serviceRecords: [ServiceRecordRow] = [],
        catalogLinked: Bool = false,
        manualLinkCount: Int = 0
    ) -> [Item] {
        let category = system.category.lowercased()
        let key = "\(system.category) \(system.displayName)".lowercased()
        let notesText = (system.notes ?? "").lowercased()

        let hasBrand = !(system.manufacturer?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        let hasModel = !(system.modelNumber?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        let hasSerial = !(system.serialNumber?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        // Treat install_date as satisfied when ANY of:
        //   - explicit value present
        //   - source is 'unknown' AND user said so within the last 90 days
        //     (so we don't nag the user again right away)
        // The "estimated" / "exact" sources both have a real install_date
        // value, so they fall into the first branch naturally.
        let hasExplicitInstallDate = !(system.installDate?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        let inUnknownCooldown: Bool = {
            guard system.installDateSource == "unknown",
                  let stampedAt = system.installDateUnknownAt else { return false }
            return Date().timeIntervalSince(stampedAt) < 60 * 60 * 24 * 90
        }()
        let hasInstallDate = hasExplicitInstallDate || inUnknownCooldown
        let hasNotes = !notesText.isEmpty
        let hasWarrantyInfo = !warranties.isEmpty
        let hasServiceHistory = !serviceRecords.isEmpty || !(system.lastServiceDate?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        let hasVendor = system.preferredContractorId != nil
        let hasCatalogMatch = catalogLinked || system.catalogEntryId != nil || manualLinkCount > 0
        let hasFuelType = !(system.catalogFuelType?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
            || containsAny(notesText, ["natural gas", "propane", "diesel", "gas", "electric"])
        let hasPanelDetails = containsAny(notesText, ["breaker", "panel schedule", "amperage", "amp", "subpanel"])
        let hasRoofMaterial = !(system.subtype?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
            || containsAny(notesText, ["shingle", "metal", "slate", "cedar", "tile", "membrane"])
        let hasFilterDetails = containsAny(notesText, ["filter", "merv", "16x", "20x", "25x", "size"])

        var items: [Item] = []
        func addIfMissing(_ id: String, _ title: String, _ detail: String, _ isComplete: Bool) {
            guard !isComplete else { return }
            items.append(Item(id: id, title: title, detail: detail))
        }

        // === Structural / shell — no brand/model/serial.
        let structuralCategories: Set<String> = [
            "crawl space", "attic & foundation", "attic", "foundation", "basement", "insulation",
        ]
        if structuralCategories.contains(category) || key.contains("crawl space") || key.contains("attic") || key.contains("foundation") {
            addIfMissing("install-date", "Last work date", "If this has been waterproofed, insulated, or repaired, add the year so Chez can track its history.", hasInstallDate)
            addIfMissing("notes", "Condition notes", "Note any visible issues, treatments, or recent inspections.", hasNotes)
            addIfMissing("vendor", "Service contact", "Add the contractor who did the work or who you'd call for issues.", hasVendor)
            return items
        }

        // === Roof.
        if category == "roofing" || key.contains("roof") {
            addIfMissing("roof-age", "Approximate age", "Add the install year or your best estimate.", hasInstallDate)
            addIfMissing("roof-material", "Roof material", "Add shingles, metal, slate, or another roof type.", hasRoofMaterial)
            addIfMissing("roof-warranty", "Warranty or install paperwork", "Upload the roofer warranty or invoice so Chez can keep it on file.", hasWarrantyInfo)
            return items
        }

        // === Material features.
        let materialCategories: Set<String> = [
            "siding/exterior", "windows", "doors", "fencing", "flooring",
            "driveway sealcoating", "hardscape",
        ]
        if materialCategories.contains(category) || key.contains("hardscape") || key.contains("driveway") {
            addIfMissing("install-date", "Install date", "Add the install year or your best estimate.", hasInstallDate)
            addIfMissing("material", "Material details", "Note the material, finish, or color in case you need to match it later.", hasNotes)
            addIfMissing("vendor", "Installer or contact", "Add the contractor or installer's contact info.", hasVendor)
            return items
        }

        // === Septic.
        if category == "septic system" || key.contains("septic") {
            addIfMissing("install-date", "Install date", "Add the year the tank was installed.", hasInstallDate)
            addIfMissing("capacity", "Tank capacity", "Note the gallon capacity in case you need to schedule pumping.", hasNotes)
            addIfMissing("service-history", "Last pump-out", "Log the most recent pumping date.", hasServiceHistory)
            addIfMissing("vendor", "Septic vendor", "Add your septic pumper's contact info.", hasVendor)
            return items
        }

        // === Chimney.
        if category == "chimney" || key.contains("chimney") {
            addIfMissing("install-date", "Install or last reline", "Add the install date or last reline year.", hasInstallDate)
            addIfMissing("type", "Chimney type", "Note whether it's wood, gas, masonry, or prefab.", hasNotes)
            addIfMissing("service-history", "Last sweep or inspection", "Log the most recent chimney sweep or inspection.", hasServiceHistory)
            addIfMissing("vendor", "Chimney sweep", "Add your chimney sweep's contact info.", hasVendor)
            return items
        }

        // === Pool/Spa parent.
        if category == "pool/spa" || key.contains("pool") || key.contains("hot tub") {
            addIfMissing("install-date", "Install date", "Add the year the pool was installed.", hasInstallDate)
            addIfMissing("type", "Pool type", "Confirm chlorine, salt, or natural so Chez can plan chemistry tasks.", !(system.subtype?.isEmpty ?? true))
            addIfMissing("vendor", "Pool service", "Add your pool service's contact info.", hasVendor)
            return items
        }

        // === Generator.
        if category == "generator" || key.contains("generator") {
            addIfMissing("brand", "Brand", "Take a label photo or enter the manufacturer manually.", hasBrand)
            addIfMissing("model", "Model", "Add the model number so Chez can match manuals, parts, and recalls.", hasModel)
            addIfMissing("serial", "Serial number", "Capture the serial from the label so service and warranty records stay accurate.", hasSerial)
            addIfMissing("fuel-type", "Fuel type", "A label photo usually lets Chez confirm whether this is natural gas, propane, or diesel.", hasFuelType)
            return items
        }

        // === Water Heater.
        if category == "water heater" || key.contains("water heater") {
            addIfMissing("brand", "Brand", "Add the manufacturer from the label.", hasBrand)
            addIfMissing("model", "Model", "Add the model number so Chez can match the right manuals and parts.", hasModel)
            addIfMissing("install-date", "Install date", "Add the install date or best estimate for replacement planning.", hasInstallDate)
            return items
        }

        // === Electrical Panel.
        if category == "electrical" || key.contains("electrical") || key.contains("panel") {
            addIfMissing("panel-brand", "Panel brand", "Take a panel label photo or enter the brand manually.", hasBrand)
            addIfMissing("amperage", "Amperage", "Add the panel rating in notes so Chez can reference it later.", hasPanelDetails)
            addIfMissing("breaker-details", "Breaker details", "Add key breaker or subpanel details in notes for future troubleshooting.", hasPanelDetails)
            return items
        }

        // === HVAC family.
        if category == "hvac" || category == "heating" || category == "air conditioning"
            || key.contains("boiler") || key.contains("furnace") || key.contains("heat pump") || key.contains("hvac") {
            addIfMissing("brand", "Brand", "Add the manufacturer from the label.", hasBrand)
            addIfMissing("model", "Model", "Add the model number so Chez can match the correct manuals and maintenance guidance.", hasModel)
            addIfMissing("filter-size", "Filter size", "Add the filter size in notes so replacements are easy to order.", hasFilterDetails)
            addIfMissing("service-history", "Service history", "Log the last service date or upload a recent service record.", hasServiceHistory)
            return items
        }

        // === Well + Sump.
        if category == "well system" || key.contains("well ") || key.contains("sump") {
            addIfMissing("brand", "Pump brand", "Add the manufacturer from the pump label.", hasBrand)
            addIfMissing("install-date", "Install date", "Add the install date or best estimate.", hasInstallDate)
            addIfMissing("service-history", "Maintenance history", "Log the last service date or upload a recent invoice.", hasServiceHistory)
            return items
        }

        // === Refrigerator gets a filter prompt.
        if key.contains("refrigerator") {
            addIfMissing("model", "Model", "Add the model number so Chez can find the correct manual and filter.", hasModel)
            addIfMissing("serial", "Serial number", "Capture the serial from the label for warranty and service history.", hasSerial)
            addIfMissing("filter-type", "Filter type", "Add the filter details in notes or capture them from a label photo.", hasFilterDetails)
            return items
        }

        // === Appliances.
        let applianceKeywords = [
            "appliance", "dishwasher", "washer", "dryer", "oven",
            "range", "cooktop", "microwave", "freezer", "ice maker",
            "wine cooler", "wine fridge", "rangehood", "vent hood",
        ]
        if category == "appliance" || applianceKeywords.contains(where: { key.contains($0) }) {
            addIfMissing("brand", "Brand", "Add the manufacturer from the label.", hasBrand)
            addIfMissing("model", "Model", "Add the model number so Chez can match the correct manuals and parts.", hasModel)
            addIfMissing("serial", "Serial number", "Capture the serial from the label for warranty and service records.", hasSerial)
            addIfMissing("install-date", "Install date", "Add the install date or best estimate.", hasInstallDate)
            return items
        }

        // === Solar / EV / Garage Door / Security / Elevator.
        let equipmentCategories: Set<String> = [
            "solar", "garage door", "security system", "smart home",
            "elevator", "fire protection", "ev charger",
        ]
        if equipmentCategories.contains(category) {
            addIfMissing("brand", "Brand", "Add the manufacturer from the label.", hasBrand)
            addIfMissing("model", "Model", "Add the model number for manuals, parts, and recall matching.", hasModel)
            addIfMissing("install-date", "Install date", "Add the install date for warranty and lifecycle planning.", hasInstallDate)
            return items
        }

        // === Service-shaped legacy rows.
        let serviceCategories: Set<String> = [
            "pest control", "pet waste", "snow removal", "mosquito & tick",
            "cleaning service", "tree service", "tree care",
            "window cleaning", "gutter cleaning", "pressure washing",
            "irrigation", "landscaping", "handyman",
            // Phase 67E/F (admin feedback 05d688b7): Trash & Recycling
            // is purely a routine surface — the hauler comes weekly,
            // there's no equipment with serial numbers / install dates.
            // Existing system rows on legacy households get archived
            // by the v2 bump on `hasArchivedServiceSystemsP1_*`.
            "trash & recycling",
        ]
        if serviceCategories.contains(category) {
            addIfMissing("vendor", "Service vendor", "Add the contractor's contact info so Chez can plan visits.", hasVendor)
            addIfMissing("service-history", "Last service", "Log the last visit so Chez knows when the next one is due.", hasServiceHistory)
            return items
        }

        // === Default — generic, conservative.
        addIfMissing("notes", "What is this?", "Add a short description so Chez can plan the right kind of care.", hasNotes)
        addIfMissing("vendor", "Service contact", "Add a contractor or vendor for this system.", hasVendor)
        addIfMissing("install-date", "Install or installed date", "If you know when this was installed or last worked on, add it here.", hasInstallDate)
        _ = hasCatalogMatch  // reserved for future "catalog match" suggestion
        return items
    }

    private static func containsAny(_ source: String, _ keywords: [String]) -> Bool {
        keywords.contains { source.contains($0) }
    }
}

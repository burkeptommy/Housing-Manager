import SwiftUI

/// Maps brand slugs to their primary color from Brandfetch.
/// Used for subtle brand accents in system detail cards.
enum BrandTheme {
    static func color(for brand: String) -> Color? {
        guard let hex = brandColors[brand.lowercased()] ?? brandColors[slugify(brand)] else {
            return nil
        }
        return Color(hex: hex)
    }

    static func assetName(for brand: String) -> String? {
        guard let slug = AppliancesListView.brandAssetMap[brand.lowercased()] else { return nil }
        return "brand-\(slug)"
    }

    private static func slugify(_ name: String) -> String {
        name.lowercased()
            .replacingOccurrences(of: " & ", with: "-")
            .replacingOccurrences(of: " + ", with: "-")
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: ".", with: "")
    }

    // Brand primary colors from Brandfetch API
    private static let brandColors: [String: String] = [
        "samsung": "#1428a0", "lg": "#a50034", "bosch": "#ea0016",
        "whirlpool": "#1c4b82", "ge-appliances": "#00223e", "ge-profile": "#00223e",
        "kitchenaid": "#b21e28", "miele": "#be0a26", "kohler": "#000000",
        "carrier": "#0055a5", "trane": "#ee3524", "lennox": "#0072ce",
        "rheem": "#6b2fa0", "frigidaire": "#0055a5", "electrolux": "#041e42",
        "maytag": "#002f6c", "honda": "#cc0000", "generac": "#008744",
        "toto": "#003978", "moen": "#00548f", "daikin": "#009bdb",
        "sub-zero": "#333333", "wolf": "#333333", "thermador": "#b20000",
        "gaggenau": "#000000", "cafe": "#866d4b", "monogram": "#000000",
        "jennair": "#000000", "fisher-paykel": "#000000", "amana": "#f42434",
        "bryant": "#003087", "goodman": "#003399", "ruud": "#006341",
        "speed-queen": "#c8102e", "beko": "#ed1c24", "brizo": "#1a1a1a",
        "hansgrohe": "#005c3f", "grohe": "#005c3f", "delta-faucet": "#1a1a1a",
        "hayward": "#00447c", "pentair": "#0072ce", "rinnai": "#e60012",
        "mitsubishi": "#e60012", "mitsubishi-electric": "#e60012",
        "fujitsu": "#c8102e", "viessmann": "#007a33", "american-standard": "#000000",
        "american-standard-hvac": "#0067b0", "dacor": "#1a1a1a", "viking": "#000000",
        "bertazzoni": "#c8102e", "la-cornue": "#000000", "smeg": "#ed1c24",
        "blomberg": "#00457c", "asko": "#002f6c", "hisense": "#1da64b",
        "sharp": "#000000", "kenmore": "#1a3668", "noritz": "#0060af",
        "navien": "#003a70", "rain-bird": "#007a33", "duravit": "#003057",
        "orbit": "#f7931e", "ao-smith": "#003a70", "bradford-white": "#00457c",
        "stiebel-eltron": "#e60012", "wayne": "#ffc20e", "everbilt": "#f96302",
        "symmons": "#00467f", "cummins": "#c8102e", "yamaha": "#6c1d5f",
        "grundfos": "#003399", "jacuzzi": "#003a70", "zodiac": "#0060af",
        "york": "#003087", "buderus": "#005c3f", "weil-mclain": "#003a70",
        "thermo-pride": "#d4272e", "heil": "#e31837", "ducane": "#003a70",
        "armstrong-air": "#003a70", "comfortmaker": "#003a70", "tempstar": "#003a70",
        "coleman-hvac": "#003a70", "luxaire": "#003087", "napoleon": "#d4a843",
        "ameristar": "#003087", "runtru": "#ee3524", "payne": "#e67a1d",
        "caterpillar": "#ffcc00", "craftsman": "#cc0000", "ryobi": "#4ea83d",
        "ridgid": "#ff6600", "toro": "#cc0000", "culligan": "#0068a6",
        "kinetico": "#00447c", "zoeller": "#003a70", "ecoflow": "#1da64b",
        "bluetti": "#40c7fb", "jackery": "#f7931e", "goal-zero": "#f7931e",
        "ego-power": "#56a832", "rachio": "#00a5e3", "pfister": "#000000",
        "kraus": "#000000", "dornbracht": "#000000", "kallista": "#000000",
        "villeroy-boch": "#003057", "ecosmart": "#00a651", "haier": "#1e3a7b",
        "hotpoint": "#001e3c", "magic-chef": "#000000",
    ]
}

// Color(hex:) extension is defined in Color+Haven.swift

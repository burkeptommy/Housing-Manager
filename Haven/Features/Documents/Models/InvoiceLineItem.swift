import Foundation

/// Phase 59: An invoice line item extracted by `process-invoice`. Each
/// invoice-category `DocumentRow` may carry a `[InvoiceLineItem]` array
/// in its `invoiceLineItems` field so the vendor detail timeline can
/// expand into per-line detail on tap.
struct InvoiceLineItem: Codable, Hashable {
    let description: String
    let quantity: Double?
    let unitPrice: Double?
    let total: Double

    enum CodingKeys: String, CodingKey {
        case description, quantity, total
        case unitPrice = "unit_price"
    }

    /// Resilient decoding so malformed entries in the JSONB array don't
    /// break the whole document decode.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        description = (try? container.decode(String.self, forKey: .description)) ?? ""
        quantity = try? container.decode(Double.self, forKey: .quantity)
        unitPrice = try? container.decode(Double.self, forKey: .unitPrice)
        total = (try? container.decode(Double.self, forKey: .total)) ?? 0
    }

    init(description: String, quantity: Double? = nil, unitPrice: Double? = nil, total: Double) {
        self.description = description
        self.quantity = quantity
        self.unitPrice = unitPrice
        self.total = total
    }
}

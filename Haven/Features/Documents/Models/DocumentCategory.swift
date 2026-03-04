import Foundation

enum DocumentCategory: String, CaseIterable, Codable {
    // Estate Planning
    case will = "Will"
    case trust = "Trust"
    case powerOfAttorney = "Power of Attorney"
    case healthcareDirective = "Healthcare Directive"
    case guardianshipDesignation = "Guardianship Designation"
    case letterOfIntent = "Letter of Intent"

    // Entity Documents
    case llcOperatingAgreement = "LLC Operating Agreement"
    case lpAgreement = "LP Agreement"
    case sCorpDocuments = "S-Corp Documents"
    case ein = "EIN Documentation"
    case annualFilings = "Annual Filings"
    case bylaws = "Bylaws"

    // Real Estate
    case deed = "Deed"
    case mortgage = "Mortgage"
    case titleInsurance = "Title Insurance"
    case survey = "Survey"
    case hoaDocuments = "HOA Documents"
    case leaseAgreement = "Lease Agreement"
    case propertyTax = "Property Tax Records"

    // Insurance
    case lifeInsurance = "Life Insurance"
    case umbrellaInsurance = "Umbrella Insurance"
    case homeownersInsurance = "Homeowners Insurance"
    case autoInsurance = "Auto Insurance"
    case jewelryArtRider = "Jewelry/Art Rider"
    case longTermCare = "Long-Term Care Insurance"
    case disabilityInsurance = "Disability Insurance"
    case dAndO = "Directors & Officers Insurance"

    // Financial Accounts
    case brokerageStatement = "Brokerage Account"
    case retirementAccount = "Retirement Account (IRA/401k)"
    case bankAccount = "Bank Account"
    case plan529 = "529 Plan"
    case beneficiaryDesignation = "Beneficiary Designation"
    case stockOptions = "Stock Options/RSUs"
    case cryptoWallet = "Crypto Wallet"
    case alternativeInvestments = "Alternative Investments"

    // Tax Records
    case federalTaxReturn = "Federal Tax Return"
    case stateTaxReturn = "State Tax Return"
    case giftTaxReturn = "Gift Tax Return (Form 709)"
    case propertyTaxRecord = "Property Tax Record"
    case estateAndTrustReturn = "Estate & Trust Return (Form 1041)"

    // Personal Property
    case vehicleTitle = "Vehicle Title"
    case artAppraisal = "Art Appraisal"
    case jewelryAppraisal = "Jewelry Appraisal"
    case collectiblesDocumentation = "Collectibles Documentation"
    case boatRegistration = "Boat/Aircraft Registration"

    // Digital Assets
    case domainNames = "Domain Names"
    case digitalAccountInventory = "Digital Account Inventory"
    case socialMediaAccounts = "Social Media Accounts"
    case intellectualProperty = "Intellectual Property"

    // Personal Identification
    case passport = "Passport"
    case birthCertificate = "Birth Certificate"
    case marriageCertificate = "Marriage Certificate"
    case divorcedDecree = "Divorce Decree"
    case socialSecurityCard = "Social Security Card"
    case citizenshipDocuments = "Citizenship/Immigration"
    case deathCertificate = "Death Certificate"

    // Professional & Business
    case employmentAgreement = "Employment Agreement"
    case nonCompete = "Non-Compete/NDA"
    case partnershipAgreement = "Partnership Agreement"
    case buySellagreement = "Buy-Sell Agreement"
    case successionPlan = "Succession Plan"

    var sectionGroup: String {
        switch self {
        case .will, .trust, .powerOfAttorney, .healthcareDirective, .guardianshipDesignation, .letterOfIntent:
            return "Estate Planning"
        case .llcOperatingAgreement, .lpAgreement, .sCorpDocuments, .ein, .annualFilings, .bylaws:
            return "Entity Documents"
        case .deed, .mortgage, .titleInsurance, .survey, .hoaDocuments, .leaseAgreement, .propertyTax:
            return "Real Estate"
        case .lifeInsurance, .umbrellaInsurance, .homeownersInsurance, .autoInsurance, .jewelryArtRider, .longTermCare, .disabilityInsurance, .dAndO:
            return "Insurance"
        case .brokerageStatement, .retirementAccount, .bankAccount, .plan529, .beneficiaryDesignation, .stockOptions, .cryptoWallet, .alternativeInvestments:
            return "Financial Accounts"
        case .federalTaxReturn, .stateTaxReturn, .giftTaxReturn, .propertyTaxRecord, .estateAndTrustReturn:
            return "Tax Records"
        case .vehicleTitle, .artAppraisal, .jewelryAppraisal, .collectiblesDocumentation, .boatRegistration:
            return "Personal Property"
        case .domainNames, .digitalAccountInventory, .socialMediaAccounts, .intellectualProperty:
            return "Digital Assets"
        case .passport, .birthCertificate, .marriageCertificate, .divorcedDecree, .socialSecurityCard, .citizenshipDocuments, .deathCertificate:
            return "Personal Identification"
        case .employmentAgreement, .nonCompete, .partnershipAgreement, .buySellagreement, .successionPlan:
            return "Professional & Business"
        }
    }

    static var groupedCategories: [(String, [DocumentCategory])] {
        let groups = Dictionary(grouping: allCases) { $0.sectionGroup }
        let order = ["Estate Planning", "Entity Documents", "Real Estate", "Insurance", "Financial Accounts", "Tax Records", "Personal Property", "Digital Assets", "Personal Identification", "Professional & Business"]
        return order.compactMap { key in
            guard let values = groups[key] else { return nil }
            return (key, values)
        }
    }
}

# Haven Home Profile - Complete Build Instructions for Claude Code

## PROMPT FOR CLAUDE CODE

Copy and paste everything below the line into Claude Code:

---

Update the home profile page at `apps/web/src/app/app/home/page.tsx` to fully build out the Vehicles, Financial, and Documents tabs. Currently they show "coming soon" placeholders - replace them with complete, functional implementations.

## VEHICLES TAB - Full Implementation

Build a comprehensive vehicle tracking system:

**For each vehicle, display:**
- Vehicle photo (if available)
- Nickname, year, make, model, trim, color
- VIN number
- License plate and state
- Current mileage
- Fuel type (gas, hybrid, electric)
- Ownership status badge (Owned / Financed / Leased)

**Registration & Inspection section:**
- Registration expiry date (highlight red if expired)
- Registration cost
- Inspection expiry date
- Inspection type (emissions, safety, etc.)

**Insurance section:**
- Provider name
- Policy number
- Premium amount and frequency
- Expiry date
- Deductible
- Coverage type

**Service section:**
- Primary service provider (name, phone, address)
- Oil change interval
- Last oil change date
- Next oil change date
- Tire rotation info

**Loan/Lease section (if applicable):**
- Lender name
- Current balance
- Monthly payment
- Interest rate
- Maturity date
- Progress bar showing percent paid
- Remaining payments count

**Service History:**
- List of all service records
- Each shows: date, description, vendor, cost, mileage at service
- Type badges (scheduled, repair, oil-change, tire, brake, inspection)

**Documents:**
- Title, registration, insurance cards, manuals, loan/lease agreements
- Click to view/download

**Sample data - create 3 vehicles:**
1. 2023 Tesla Model Y Long Range (financed, $42K balance, 24,500 miles)
2. 2022 Toyota Highlander Hybrid Platinum (owned/paid off, 35,200 miles)
3. 2024 Mercedes-Benz GLE 450 (leased, $68K balance, 8,750 miles)

## FINANCIAL TAB - Full Implementation

Build a comprehensive financial dashboard:

**Summary Cards at top:**
- Total monthly debt payments
- Total debt balance
- Annual insurance premiums
- Annual property taxes

**Loans & Mortgages section:**
For each loan show a card with:
- Type badge (MORTGAGE, HELOC, AUTO, STUDENT, PERSONAL)
- Nickname (e.g., "Primary Mortgage", "MBA Student Loans")
- Lender name and account number (masked)
- Original amount vs current balance
- Progress bar showing percent paid off
- Interest rate and type (fixed/variable)
- Monthly payment amount
- Payment due day and next payment date
- Remaining payments
- Autopay status
- Payment method
- Lender contact (phone, website)

**For mortgages specifically, add escrow breakdown:**
- Principal & Interest portion
- Property tax portion (monthly)
- Homeowners insurance portion (monthly)

**Sample loans to create:**
1. Primary Mortgage - First Republic, $1.75M original, $1.425M balance, 3.125% fixed, 30-year
2. HELOC - First Republic, $500K limit, $125K balance, 7.25% variable
3. Tesla Auto Loan - Tesla Financing, $65K original, $42K balance, 4.99% fixed
4. MBA Student Loans - SoFi, $85K original, $34.2K balance, 4.25% fixed
5. Mercedes Lease - MBFS, $72K, $68K remaining, 36-month term

**Insurance Policies section:**
For each policy show:
- Type icon (home, car, umbrella, life)
- Provider and policy number
- Premium and frequency
- Coverage amount
- Deductible
- Coverage period (effective - expiry)
- Auto-renew badge if applicable
- Coverage details list
- Covered items (for auto - list vehicles)
- Agent contact info (name, phone, email)

**Sample policies:**
1. Homeowners - Chubb, $4.5M coverage, $12,500/year, $10K deductible
2. Auto - Chubb, 3 vehicles, $5,600/year, $500 deductible
3. Umbrella - Chubb, $5M coverage, $1,500/year
4. Life - Northwestern Mutual, $2M term, $2,400/year

**Property Tax section:**
- Annual amount ($24,500)
- Assessed value ($2.85M)
- Mill/tax rate (11.59)
- Payment schedule (semi-annual)
- Next payment date and amount
- Paid through escrow indicator
- Payment history table

**Property Value card (gradient background):**
- Purchase price and date
- Current estimated value
- Appreciation amount and percentage
- Current equity (value minus mortgage)
- Mortgage balance
- LTV ratio

## DOCUMENTS TAB - Full Implementation

Build a complete document management system:

**Search and Filter bar:**
- Search input to filter by document name
- Category dropdown filter
- Upload button

**Stats row:**
- Total documents count
- Number of categories
- Documents with expiry dates
- Favorited documents count

**Quick Access section:**
- Show favorited documents for one-click access
- Only show when not filtering

**Documents grouped by category:**
Each category is a collapsible section showing:
- Category name with folder icon
- File count

Each document row shows:
- File type icon (PDF red, image blue, spreadsheet green)
- Document name
- Favorite star if favorited
- Expiry date badge if applicable
- File size
- Upload date
- Subcategory
- Linked item (e.g., "Primary Mortgage", "Tesla Model Y")
- Hover actions: View, Download, More options

**Document categories to create:**
1. Property - Deed, survey, title insurance, purchase agreement, closing docs, inspection report
2. Financial - Mortgage note, statements, HELOC agreement, tax bills
3. Insurance - All policy documents, insurance cards
4. Warranties - HVAC, generator, appliances
5. Manuals - Appliance manuals, pool equipment
6. Maintenance - Inspection reports (roof, septic, well, chimney)
7. Vehicles - Titles, registrations, lease agreements
8. Projects - Renovation plans, permits, contracts

**Create 25+ sample documents with realistic names and metadata**

## TECHNICAL REQUIREMENTS

1. Use existing Lucide icons - add any needed imports
2. Use the existing color scheme (haven-*, warm-*)
3. Use Tailwind CSS classes
4. Make everything responsive (mobile-first)
5. Use the formatCurrency helper for all money values
6. Progress bars should use the same style as maintenance progress bars
7. Keep the same card/modal patterns used elsewhere in the file
8. Add proper TypeScript interfaces for Vehicle, Loan, InsurancePolicy, PropertyTax, Document

## DESIGN PRINCIPLES

1. **Not overwhelming** - Show summary info on cards, full details on click/expand
2. **Progressive disclosure** - Most important info visible first
3. **Consistent styling** - Match the existing maintenance and systems tabs
4. **Mobile responsive** - Works well on phone screens
5. **Visual hierarchy** - Use color, size, and spacing to guide the eye

---

After making changes, run `pnpm dev` and test all three tabs thoroughly.

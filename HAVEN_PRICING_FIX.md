# Haven Pricing Page - Correct Tier Structure

## PRICING TIERS

| Tier | Price | Description |
|------|-------|-------------|
| **Haven Essentials** | $39/mo | Self-service bill consolidation & home tracking |
| **Haven Lite** | $349/mo | Text-based home manager with reactive support |
| **Haven** | $749/mo | Proactive home manager with handyman included |
| **Haven+** | $1,499/mo | Personal assistant + enhanced services |
| **Haven Estate** | $3,499/mo | Full estate management, multiple properties |

---

## FEATURE BREAKDOWN

### Haven Essentials - $39/month
*Self-service home management*
- Bill consolidation (unlimited accounts)
- Complete home profile & systems tracking
- Maintenance reminders & scheduling
- Vendor directory with neighbor reviews
- Document storage
- Messages with vendors
- Money dashboard
- **Pay-per-use handyman visits ($99/visit)**
- **No home manager** - you handle everything

### Haven Lite - $349/month
*Light-touch manager support*
- Your complete home profile
- Bill consolidation (unlimited accounts)
- Vendor coordination (reactive)
- **Text-based home manager**
- Document vault & home manual
- **Same-day response time**

### Haven - $749/month
*Your dedicated home manager*
- Everything in Essentials
- **Proactive home manager**
- **Monthly handyman visit (2 hours)**
- Vendor oversight & negotiation
- Maintenance scheduling & oversight
- **12-hour response time**

### Haven+ - $1,499/month *(expandable dropdown)*
*Personal assistant services*
- Everything in Haven
- Personal assistant services
- Errands, shopping & returns
- Travel coordination
- Event planning
- **4-hour priority response**
- **Enhanced handyman (4 hrs/month)**

### Haven Estate - $3,499/month *(expandable dropdown)*
*White-glove estate management*
- Your personal estate manager anticipating needs, coordinating staff, and ensuring every detail of your properties is handled with discretion and excellence
- **Multiple properties supported**
- **Priority 24/7 concierge access**
- **Custom service agreements**

---

# FILE: `apps/web/src/app/(marketing)/page.tsx`

## Update Hero Section

Change the hero to prominently feature $39:

```tsx
{/* Hero Section */}
<section className="relative overflow-hidden bg-gradient-to-b from-haven-50 to-white pt-16 pb-20 sm:pt-24 sm:pb-32">
  <div className="max-w-6xl mx-auto px-4 sm:px-6">
    <div className="text-center">
      {/* Badge */}
      <div className="inline-flex items-center gap-2 px-4 py-2 bg-haven-100 rounded-full mb-6">
        <span className="text-haven-700 text-sm font-medium">
          Now serving Greenwich, Darien & New Canaan
        </span>
      </div>

      {/* Headline */}
      <h1 className="text-4xl sm:text-5xl lg:text-6xl font-bold text-warm-900 tracking-tight">
        Your home, managed.
        <br />
        <span className="text-haven-600">Starting at just $39/month.</span>
      </h1>

      {/* Subheadline */}
      <p className="mt-6 text-lg sm:text-xl text-warm-600 max-w-2xl mx-auto">
        From simple bill consolidation to full estate management. 
        Choose the level of support that fits your life.
      </p>

      {/* CTA Buttons */}
      <div className="mt-8 flex flex-col sm:flex-row items-center justify-center gap-4">
        <a
          href="#pricing"
          className="w-full sm:w-auto px-8 py-4 bg-haven-600 text-white font-semibold rounded-xl hover:bg-haven-700 transition-colors text-lg"
        >
          Start for $39/month
        </a>
        <a
          href="#how-it-works"
          className="w-full sm:w-auto px-8 py-4 border border-warm-300 text-warm-700 font-semibold rounded-xl hover:bg-warm-50 transition-colors text-lg"
        >
          See How It Works
        </a>
      </div>

      {/* Trust badges */}
      <div className="mt-8 flex items-center justify-center gap-6 text-sm text-warm-500">
        <span className="flex items-center gap-1">
          <CheckCircle2 className="w-4 h-4 text-green-500" />
          No setup fees
        </span>
        <span className="flex items-center gap-1">
          <CheckCircle2 className="w-4 h-4 text-green-500" />
          Cancel anytime
        </span>
        <span className="flex items-center gap-1">
          <CheckCircle2 className="w-4 h-4 text-green-500" />
          30-day guarantee
        </span>
      </div>
    </div>
  </div>
</section>
```

---

## Pricing Section - 3 Columns + Expandable Premium

```tsx
{/* Pricing Section */}
<section id="pricing" className="py-16 sm:py-24 bg-warm-50">
  <div className="max-w-6xl mx-auto px-4 sm:px-6">
    {/* Header */}
    <div className="text-center mb-12">
      <h2 className="text-3xl sm:text-4xl font-bold text-warm-900">
        Choose Your Level of Support
      </h2>
      <p className="text-lg text-warm-600 mt-4 max-w-2xl mx-auto">
        Start with Essentials and upgrade anytime. All plans include unlimited bill consolidation.
      </p>
    </div>

    {/* Main 3 Pricing Cards */}
    <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
      
      {/* ESSENTIALS - $39 */}
      <div className="bg-white rounded-2xl border border-warm-200 shadow-sm overflow-hidden flex flex-col">
        <div className="p-6 flex-1">
          <div className="text-center">
            <h3 className="text-lg font-semibold text-warm-900">Haven Essentials</h3>
            <p className="text-sm text-warm-500 mt-1">Self-service home management</p>
            <div className="mt-4">
              <span className="text-4xl font-bold text-warm-900">$39</span>
              <span className="text-warm-500">/month</span>
            </div>
          </div>

          <div className="mt-6 space-y-3">
            {[
              'Bill consolidation (unlimited)',
              'Home profile & systems tracking',
              'Maintenance reminders',
              'Vendor directory',
              'Document storage',
              'Money dashboard',
              'Handyman visits ($99 each)',
            ].map((feature, idx) => (
              <div key={idx} className="flex items-start gap-3">
                <Check className="w-5 h-5 text-haven-600 flex-shrink-0 mt-0.5" />
                <span className="text-sm text-warm-700">{feature}</span>
              </div>
            ))}
          </div>

          <div className="mt-4 pt-4 border-t border-warm-100">
            <p className="text-xs text-warm-500 text-center">
              Perfect for DIY homeowners who want organization
            </p>
          </div>
        </div>

        <div className="p-6 pt-0">
          <button className="w-full py-3 bg-warm-100 text-warm-700 font-semibold rounded-xl hover:bg-warm-200 transition-colors">
            Get Started
          </button>
        </div>
      </div>

      {/* LITE - $349 - POPULAR */}
      <div className="bg-white rounded-2xl border-2 border-haven-500 shadow-lg overflow-hidden flex flex-col relative">
        {/* Popular Badge */}
        <div className="absolute top-0 left-1/2 -translate-x-1/2 -translate-y-1/2">
          <span className="px-4 py-1 bg-haven-600 text-white text-sm font-semibold rounded-full">
            Most Popular
          </span>
        </div>

        <div className="p-6 pt-8 flex-1">
          <div className="text-center">
            <h3 className="text-lg font-semibold text-warm-900">Haven Lite</h3>
            <p className="text-sm text-warm-500 mt-1">Light-touch manager support</p>
            <div className="mt-4">
              <span className="text-4xl font-bold text-warm-900">$349</span>
              <span className="text-warm-500">/month</span>
            </div>
          </div>

          <div className="mt-6 space-y-3">
            {[
              'Your complete home profile',
              'Bill consolidation (unlimited)',
              'Vendor coordination (reactive)',
              'Text-based home manager',
              'Document vault & home manual',
              'Same-day response time',
            ].map((feature, idx) => (
              <div key={idx} className="flex items-start gap-3">
                <Check className="w-5 h-5 text-haven-600 flex-shrink-0 mt-0.5" />
                <span className="text-sm text-warm-700">{feature}</span>
              </div>
            ))}
          </div>

          <div className="mt-4 pt-4 border-t border-warm-100">
            <p className="text-xs text-warm-500 text-center">
              For busy professionals who want backup support
            </p>
          </div>
        </div>

        <div className="p-6 pt-0">
          <button className="w-full py-3 bg-haven-600 text-white font-semibold rounded-xl hover:bg-haven-700 transition-colors">
            Get Started
          </button>
        </div>
      </div>

      {/* HAVEN - $749 */}
      <div className="bg-white rounded-2xl border border-warm-200 shadow-sm overflow-hidden flex flex-col">
        <div className="p-6 flex-1">
          <div className="text-center">
            <h3 className="text-lg font-semibold text-warm-900">Haven</h3>
            <p className="text-sm text-warm-500 mt-1">Your dedicated home manager</p>
            <div className="mt-4">
              <span className="text-4xl font-bold text-warm-900">$749</span>
              <span className="text-warm-500">/month</span>
            </div>
          </div>

          <div className="mt-6 space-y-3">
            {[
              'Everything in Essentials',
              'Proactive home manager',
              'Monthly handyman visit (2 hrs)',
              'Vendor oversight & negotiation',
              'Maintenance scheduling',
              '12-hour response time',
            ].map((feature, idx) => (
              <div key={idx} className="flex items-start gap-3">
                <Check className="w-5 h-5 text-haven-600 flex-shrink-0 mt-0.5" />
                <span className="text-sm text-warm-700">{feature}</span>
              </div>
            ))}
          </div>

          <div className="mt-4 pt-4 border-t border-warm-100">
            <p className="text-xs text-warm-500 text-center">
              For those who want their home truly managed
            </p>
          </div>
        </div>

        <div className="p-6 pt-0">
          <button className="w-full py-3 bg-warm-100 text-warm-700 font-semibold rounded-xl hover:bg-warm-200 transition-colors">
            Get Started
          </button>
        </div>
      </div>
    </div>

    {/* Premium Tiers - Expandable */}
    <div className="space-y-3">
      {/* Haven+ Expandable */}
      <PremiumTierDropdown
        name="Haven+"
        price={1499}
        tagline="Personal assistant + enhanced services"
        features={[
          'Everything in Haven',
          'Personal assistant services',
          'Errands, shopping & returns',
          'Travel coordination',
          'Event planning',
          '4-hour priority response',
          'Enhanced handyman (4 hrs/month)',
        ]}
      />

      {/* Haven Estate Expandable */}
      <PremiumTierDropdown
        name="Haven Estate"
        price={3499}
        tagline="White-glove estate management"
        description="Your personal estate manager anticipating needs, coordinating staff, and ensuring every detail of your properties is handled with discretion and excellence."
        features={[
          'Multiple properties supported',
          'Priority 24/7 concierge access',
          'Custom service agreements',
          'Staff coordination',
          'Dedicated estate manager',
        ]}
        isContact={true}
      />
    </div>

    {/* Trust line */}
    <div className="mt-12 text-center">
      <p className="text-sm text-warm-500">
        All plans include unlimited bill consolidation • No setup fees • Cancel anytime • 30-day money-back guarantee
      </p>
    </div>
  </div>
</section>
```

---

## Premium Tier Dropdown Component

```tsx
function PremiumTierDropdown({
  name,
  price,
  tagline,
  description,
  features,
  isContact = false,
}: {
  name: string;
  price: number;
  tagline: string;
  description?: string;
  features: string[];
  isContact?: boolean;
}) {
  const [isExpanded, setIsExpanded] = useState(false);

  return (
    <div className="bg-white rounded-xl border border-warm-200 overflow-hidden">
      <button
        onClick={() => setIsExpanded(!isExpanded)}
        className="w-full p-4 sm:p-6 flex items-center justify-between hover:bg-warm-50 transition-colors"
      >
        <div className="flex items-center gap-4">
          <div className="w-12 h-12 rounded-xl bg-amber-100 flex items-center justify-center">
            {name === 'Haven+' ? (
              <Star className="w-6 h-6 text-amber-600" />
            ) : (
              <Crown className="w-6 h-6 text-amber-600" />
            )}
          </div>
          <div className="text-left">
            <h3 className="text-lg font-semibold text-warm-900">{name}</h3>
            <p className="text-sm text-warm-500">{tagline}</p>
          </div>
        </div>
        <div className="flex items-center gap-4">
          <div className="text-right">
            <span className="text-2xl font-bold text-warm-900">${price.toLocaleString()}</span>
            <span className="text-warm-500 text-sm">/month</span>
          </div>
          {isExpanded ? (
            <ChevronUp className="w-5 h-5 text-warm-400" />
          ) : (
            <ChevronDown className="w-5 h-5 text-warm-400" />
          )}
        </div>
      </button>

      {isExpanded && (
        <div className="px-4 sm:px-6 pb-6 border-t border-warm-100">
          <div className="pt-6">
            {description && (
              <p className="text-warm-600 mb-4">{description}</p>
            )}
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              {features.map((feature, idx) => (
                <div key={idx} className="flex items-center gap-2">
                  <Check className="w-4 h-4 text-amber-600 flex-shrink-0" />
                  <span className="text-sm text-warm-700">{feature}</span>
                </div>
              ))}
            </div>
            <button className={`mt-6 w-full py-3 font-semibold rounded-xl transition-colors ${
              isContact
                ? 'bg-warm-900 text-white hover:bg-warm-800'
                : 'bg-amber-600 text-white hover:bg-amber-700'
            }`}>
              {isContact ? 'Contact Sales' : `Upgrade to ${name}`}
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
```

---

## Comparison Table - 3 Columns

```tsx
{/* Comparison Section */}
<section className="py-16 sm:py-24 bg-white">
  <div className="max-w-5xl mx-auto px-4 sm:px-6">
    <h2 className="text-2xl sm:text-3xl font-bold text-center text-warm-900 mb-8">
      Compare Plans
    </h2>

    {/* Desktop Table */}
    <div className="hidden lg:block">
      <table className="w-full">
        <thead>
          <tr className="border-b border-warm-200">
            <th className="text-left py-4 px-4 font-semibold text-warm-600 w-1/4">Feature</th>
            <th className="text-center py-4 px-4 w-1/4">
              <div className="font-semibold text-warm-900">Essentials</div>
              <div className="text-2xl font-bold text-warm-900">$39<span className="text-sm font-normal text-warm-500">/mo</span></div>
            </th>
            <th className="text-center py-4 px-4 bg-haven-50 rounded-t-xl w-1/4">
              <div className="font-semibold text-haven-700">Lite</div>
              <div className="text-2xl font-bold text-haven-700">$349<span className="text-sm font-normal text-haven-600">/mo</span></div>
            </th>
            <th className="text-center py-4 px-4 w-1/4">
              <div className="font-semibold text-warm-900">Haven</div>
              <div className="text-2xl font-bold text-warm-900">$749<span className="text-sm font-normal text-warm-500">/mo</span></div>
            </th>
          </tr>
        </thead>
        <tbody className="divide-y divide-warm-100">
          {[
            { feature: 'Bill Consolidation', essentials: 'Unlimited', lite: 'Unlimited', haven: 'Unlimited' },
            { feature: 'Home Profile & Systems', essentials: true, lite: true, haven: true },
            { feature: 'Maintenance Reminders', essentials: true, lite: true, haven: true },
            { feature: 'Vendor Directory', essentials: true, lite: true, haven: true },
            { feature: 'Document Storage', essentials: true, lite: 'Vault + Manual', haven: 'Vault + Manual' },
            { feature: 'Home Manager', essentials: false, lite: 'Text-based', haven: 'Proactive' },
            { feature: 'Vendor Coordination', essentials: false, lite: 'Reactive', haven: 'Full oversight' },
            { feature: 'Response Time', essentials: 'Self-service', lite: 'Same-day', haven: '12 hours' },
            { feature: 'Handyman Visits', essentials: '$99/visit', lite: 'Add-on', haven: '2 hrs/month' },
            { feature: 'Vendor Negotiation', essentials: false, lite: false, haven: true },
          ].map((row, idx) => (
            <tr key={idx}>
              <td className="py-4 px-4 text-warm-700">{row.feature}</td>
              <td className="py-4 px-4 text-center">
                {row.essentials === true ? (
                  <Check className="w-5 h-5 text-green-500 mx-auto" />
                ) : row.essentials === false ? (
                  <X className="w-5 h-5 text-warm-300 mx-auto" />
                ) : (
                  <span className="text-sm text-warm-600">{row.essentials}</span>
                )}
              </td>
              <td className="py-4 px-4 text-center bg-haven-50">
                {row.lite === true ? (
                  <Check className="w-5 h-5 text-haven-600 mx-auto" />
                ) : row.lite === false ? (
                  <X className="w-5 h-5 text-warm-300 mx-auto" />
                ) : (
                  <span className="text-sm font-medium text-haven-700">{row.lite}</span>
                )}
              </td>
              <td className="py-4 px-4 text-center">
                {row.haven === true ? (
                  <Check className="w-5 h-5 text-green-500 mx-auto" />
                ) : row.haven === false ? (
                  <X className="w-5 h-5 text-warm-300 mx-auto" />
                ) : (
                  <span className="text-sm text-warm-600">{row.haven}</span>
                )}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>

    {/* Mobile Cards */}
    <div className="lg:hidden space-y-3">
      {[
        { feature: 'Bill Consolidation', essentials: 'Unlimited', lite: 'Unlimited', haven: 'Unlimited' },
        { feature: 'Home Manager', essentials: '—', lite: 'Text-based', haven: 'Proactive', highlight: true },
        { feature: 'Response Time', essentials: 'Self-service', lite: 'Same-day', haven: '12 hours' },
        { feature: 'Handyman Visits', essentials: '$99/visit', lite: 'Add-on', haven: '2 hrs included', highlight: true },
        { feature: 'Vendor Coordination', essentials: '—', lite: 'Reactive', haven: 'Full oversight' },
      ].map((row, idx) => (
        <div key={idx} className={`bg-white rounded-xl border overflow-hidden ${row.highlight ? 'border-haven-300' : 'border-warm-200'}`}>
          <div className="bg-warm-100 px-4 py-2">
            <span className="font-medium text-warm-700 text-sm">{row.feature}</span>
          </div>
          <div className="grid grid-cols-3 divide-x divide-warm-100">
            <div className="p-3 text-center">
              <div className="text-xs text-warm-400 mb-1">$39</div>
              <div className="text-sm text-warm-600">{row.essentials}</div>
            </div>
            <div className="p-3 text-center bg-haven-50/50">
              <div className="text-xs text-haven-600 mb-1">$349</div>
              <div className="text-sm font-medium text-haven-700">{row.lite}</div>
            </div>
            <div className="p-3 text-center">
              <div className="text-xs text-warm-400 mb-1">$749</div>
              <div className="text-sm text-warm-600">{row.haven}</div>
            </div>
          </div>
        </div>
      ))}
    </div>
  </div>
</section>
```

---

## Update CTA Throughout Page

Any "Get Started" or pricing CTA should now reference $39:

```tsx
{/* Bottom CTA Section */}
<section className="py-16 sm:py-24 bg-haven-600">
  <div className="max-w-4xl mx-auto px-4 sm:px-6 text-center">
    <h2 className="text-3xl sm:text-4xl font-bold text-white">
      Ready to simplify your home life?
    </h2>
    <p className="mt-4 text-lg text-haven-100">
      Start with bill consolidation for just $39/month. Upgrade anytime.
    </p>
    <div className="mt-8 flex flex-col sm:flex-row items-center justify-center gap-4">
      <button className="w-full sm:w-auto px-8 py-4 bg-white text-haven-700 font-semibold rounded-xl hover:bg-haven-50 transition-colors text-lg">
        Start for $39/month
      </button>
      <button className="w-full sm:w-auto px-8 py-4 border-2 border-white text-white font-semibold rounded-xl hover:bg-haven-500 transition-colors text-lg">
        Compare All Plans
      </button>
    </div>
  </div>
</section>
```

---

# SUMMARY

## Pricing Display:
1. **Hero**: "Starting at just $39/month"
2. **3 main cards**: Essentials ($39), Lite ($349), Haven ($749)
3. **Expandable dropdowns**: Haven+ ($1,499), Haven Estate ($3,499)
4. **Comparison table**: 3 columns showing feature differences

## Key Features by Tier:

| Feature | $39 Essentials | $349 Lite | $749 Haven |
|---------|----------------|-----------|------------|
| Bill Consolidation | Unlimited | Unlimited | Unlimited |
| Home Profile | ✓ | ✓ | ✓ |
| Maintenance Reminders | ✓ | ✓ | ✓ |
| Vendors + Messages | ✓ | ✓ | ✓ |
| Home Manager | — | Text-based | Proactive |
| Response Time | Self-service | Same-day | 12 hours |
| Handyman | $99/visit | Add-on | 2 hrs/month |
| Vendor Negotiation | — | — | ✓ |

---

## Run in Claude Code:

```
Read and apply HAVEN_PRICING_FIX.md

Update the marketing/pricing page with correct tiers:

1. Hero should say "Starting at just $39/month"

2. Show 3 pricing cards side by side:
   - Haven Essentials: $39/mo (self-service, bill consolidation, home tracking)
   - Haven Lite: $349/mo (text-based home manager, reactive support) - mark as "Most Popular"
   - Haven: $749/mo (proactive home manager, 2hr handyman included)

3. Add expandable dropdowns for premium tiers:
   - Haven+: $1,499/mo (personal assistant, 4hr handyman)
   - Haven Estate: $3,499/mo (estate management, multiple properties)

4. Update comparison table to show all 3 main tiers

5. Update all CTAs to say "Start for $39/month"

Key: Essentials at $39 is the entry point for adoption. No home manager, just bill consolidation + tracking + pay-per-use handyman.
```

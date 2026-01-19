# Haven Website Design Overhaul

**Objective:** Transform the Haven marketing website into a spectacular, premium experience that looks stunning on mobile and desktop. Convey sophistication, warmth, and trust.

**Design Philosophy:** Apple-level attention to detail. Linear-inspired modern elegance. The visual sophistication of a fintech platform combined with the warmth of a premium hospitality brand. NOT corporate—elegant, warm, inviting.

---

## CRITICAL RULES

1. **DO NOT CHANGE THE MEANING OF ANY COPY** - Preserve intent, but follow messaging guidelines below
2. **Maintain all functionality** - Links, buttons, interactivity work identically
3. **Keep the same sections and order** - Same information architecture
4. **Use the Sage Green color palette** - See below
5. **Mobile-first** - Must look spectacular on mobile (375px) AND desktop

---

## Messaging Guidelines

### Hero Section Messaging

**DO NOT** lead with Alfred in the hero. The hero establishes **Haven** as the brand and communicates the value proposition. Alfred is introduced later in "How It Works."

**Hero badge options** (pick one):
- "Home Management, Simplified"
- "One Bill. One Contact. Zero Hassle."
- Remove the badge entirely and let the headline speak

**Hero subheadline:** Focus on OUTCOMES, not who does them:
> "Track your bills. Get reminded before things break. Find savings you're missing. One monthly payment for everything. Stop managing. Start living."

NOT: "Alfred tracks your bills..." or "Haven tracks your bills..."

**Price/CTA:** Put price IN the button, not floating separately:
- Primary: `[Start for $39/mo →]`
- Below button (small): "No contracts. Cancel anytime."

### "How It Works" Section

**ADD "Meet Alfred" badge** above this section heading. This is where Alfred gets introduced as the mechanism that delivers Haven's value.

```tsx
<div className="inline-flex items-center gap-2 px-3 py-1.5 bg-sage-100 
                rounded-full text-sage-700 text-sm font-medium mb-4">
  <Sparkles className="w-4 h-4" />
  Meet Alfred
</div>
<h2 className="font-serif ...">How Alfred Works</h2>
```

### Handyman Pricing (UPDATED)

| Tier | Handyman |
|------|----------|
| Essentials $39/mo | $99/visit |
| Lite $349/mo | 1 quarterly visit included |
| Haven $749/mo | Monthly visits included |
| Haven+ $1,499/mo | Monthly visits included |
| Estate $3,499/mo | Unlimited visits included |

Update any handyman references to reflect: **"Included with Lite ($349+)"** for quarterly, **"Monthly visits included with Haven ($749+)"**

---

## Official Color Palette: Sage Green

**Vibe:** Natural, grounded, calm. A well-organized home with a garden. Modern without being cold.

| Role | Name | Hex | Usage |
|------|------|-----|-------|
| **Primary** | Navy | `#0a1929` | Headers, primary buttons, dark sections |
| **Accent** | Sage | `#7D8E74` | Badges, checkmarks, icons, subtle highlights |
| **Soft Accent** | Light Sage | `#A4B494` | Hover states, soft highlights |
| **Light BG** | Soft Green | `#F4F6F2` | Alternating section backgrounds |
| **Card BG** | Cream | `#FAFAF7` | Cards, content areas |

### Tailwind Sage Configuration

```typescript
sage: {
  50: '#F4F6F2',
  100: '#E8EDE4',
  200: '#D1DBC9',
  300: '#A4B494',
  400: '#8FA37F',
  500: '#7D8E74',
  600: '#6B7A63',
  700: '#5A6853',
  800: '#4A5544',
  900: '#3B4536',
},
cream: {
  50: '#FEFDFB',
  100: '#FAFAF7',
  200: '#F5F4F0',
},
```

### Button Rules (CRITICAL)

- **Dark backgrounds (navy):** White buttons with navy text
- **Light backgrounds:** Navy buttons with white text
- **Sage is NEVER for primary CTAs** — only accents, badges, checkmarks

### Typography Rules (CRITICAL)

- **Headlines (H1, H2):** `font-serif` (Playfair Display) - sophisticated, elegant
- **Body text:** `font-sans` (Inter) - clean, readable
- **Hero headline MUST be font-serif**
- **ALL section headlines MUST be font-serif**

---

## PHASE 1: Design System Setup

### 1.1 Typography

Add to `tailwind.config.ts`:

```typescript
fontSize: {
  'display-2xl': ['4.5rem', { lineHeight: '1.1', letterSpacing: '-0.03em' }],
  'display-xl': ['3.75rem', { lineHeight: '1.1', letterSpacing: '-0.025em' }],
  'display-lg': ['3rem', { lineHeight: '1.15', letterSpacing: '-0.02em' }],
  'display-md': ['2.25rem', { lineHeight: '1.2', letterSpacing: '-0.015em' }],
  'display-sm': ['1.875rem', { lineHeight: '1.25', letterSpacing: '-0.01em' }],
},
```

### 1.2 Premium Shadows

```typescript
boxShadow: {
  'elegant': '0 1px 2px rgba(11, 17, 32, 0.04), 0 4px 8px rgba(11, 17, 32, 0.04), 0 8px 16px rgba(11, 17, 32, 0.02)',
  'elegant-lg': '0 2px 4px rgba(11, 17, 32, 0.02), 0 8px 16px rgba(11, 17, 32, 0.06), 0 16px 32px rgba(11, 17, 32, 0.04)',
  'elegant-xl': '0 4px 8px rgba(11, 17, 32, 0.02), 0 16px 32px rgba(11, 17, 32, 0.08), 0 32px 64px rgba(11, 17, 32, 0.04)',
  'card-hover': '0 12px 32px rgba(11, 17, 32, 0.12)',
},
```

### 1.3 Animations

```typescript
animation: {
  'float': 'float 6s ease-in-out infinite',
  'float-slow': 'float 8s ease-in-out infinite',
  'reveal-up': 'revealUp 0.7s cubic-bezier(0.16, 1, 0.3, 1) forwards',
  'fade-in': 'fadeIn 0.5s ease-out forwards',
},
keyframes: {
  float: {
    '0%, 100%': { transform: 'translateY(0)' },
    '50%': { transform: 'translateY(-12px)' },
  },
  revealUp: {
    '0%': { opacity: '0', transform: 'translateY(24px)' },
    '100%': { opacity: '1', transform: 'translateY(0)' },
  },
  fadeIn: {
    '0%': { opacity: '0' },
    '100%': { opacity: '1' },
  },
},
```

---

## PHASE 2: Hero Section

### 2.1 Background

```tsx
<section className="relative overflow-hidden min-h-[100dvh] flex flex-col">
  {/* Rich gradient background */}
  <div className="absolute inset-0 bg-gradient-to-br from-haven-navy-900 via-haven-navy-950 to-[#050a14]" />
  
  {/* Subtle radial glow */}
  <div className="absolute inset-0 bg-[radial-gradient(ellipse_80%_50%_at_50%_-20%,rgba(164,180,148,0.12),transparent)]" />
  
  {/* Subtle grid pattern */}
  <div className="absolute inset-0 opacity-[0.02]"
       style={{
         backgroundImage: `linear-gradient(rgba(255,255,255,0.1) 1px, transparent 1px),
                          linear-gradient(90deg, rgba(255,255,255,0.1) 1px, transparent 1px)`,
         backgroundSize: '48px 48px'
       }} />
  
  {/* Floating ambient orbs - hidden on mobile for performance */}
  <div className="hidden sm:block absolute top-20 right-[15%] w-[350px] h-[350px] rounded-full 
                  bg-gradient-to-br from-sage-400/8 to-transparent blur-3xl animate-float" />
  <div className="hidden sm:block absolute bottom-32 left-[10%] w-[250px] h-[250px] rounded-full 
                  bg-gradient-to-tr from-haven-navy-600/20 to-transparent blur-3xl animate-float-slow" />
```

### 2.2 Hero Content (Mobile-First)

```tsx
<div className="relative flex-1 flex items-center">
  <div className="max-w-6xl mx-auto px-5 sm:px-6 py-20 sm:py-24 lg:py-32 w-full">
    <div className="grid lg:grid-cols-2 gap-10 lg:gap-12 items-center">
      
      {/* Left - Copy */}
      <div className="text-center lg:text-left">
        
        {/* Optional badge - Haven focused, NOT Alfred */}
        <div className="inline-flex items-center gap-2 px-4 py-2 bg-white/10 backdrop-blur-sm 
                        rounded-full border border-white/10 mb-6">
          <span className="text-sm font-medium text-white/90">
            One Bill. One Contact. Zero Hassle.
          </span>
        </div>

        {/* Headline - MUST use font-serif (Playfair Display) */}
        <h1 className="font-serif">
          <span className="block text-[2.5rem] sm:text-5xl lg:text-6xl xl:text-7xl 
                           font-bold tracking-tight leading-[1.08] text-white">
            Your home, finally
          </span>
          <span className="block text-[2.5rem] sm:text-5xl lg:text-6xl xl:text-7xl 
                           font-bold tracking-tight leading-[1.08]
                           bg-gradient-to-r from-sage-300 via-sage-200 to-sage-400 
                           bg-clip-text text-transparent">
            under control.
          </span>
        </h1>

        {/* Subheadline - Focus on OUTCOMES, not who does them */}
        <p className="mt-6 text-base sm:text-lg lg:text-xl text-white/70 max-w-xl 
                      mx-auto lg:mx-0 leading-relaxed">
          Track your bills. Get reminded before things break. Find savings you're missing. 
          One monthly payment for everything.
          <span className="block sm:inline sm:ml-1 text-white/90 font-medium mt-2 sm:mt-0">
            Stop managing. Start living.
          </span>
        </p>

        {/* Value props - stacked on mobile, inline on desktop */}
        <div className="mt-6 flex flex-col sm:flex-row flex-wrap justify-center lg:justify-start 
                        gap-3 sm:gap-4 text-sm">
          {[
            'One bill for everything',
            'Never miss maintenance', 
            'Handyman who knows your home'
          ].map((item, i) => (
            <span key={i} className="flex items-center justify-center lg:justify-start gap-2 text-white/80">
              <CheckCircle2 className="w-4 h-4 text-sage-300 flex-shrink-0" />
              {item}
            </span>
          ))}
        </div>

        {/* CTAs - Price IN the button */}
        <div className="mt-8 flex flex-col sm:flex-row items-center justify-center lg:justify-start 
                        gap-3 sm:gap-4">
          
          {/* Primary CTA - White on dark, price in button */}
          <Link
            href="/onboarding/welcome"
            className="group w-full sm:w-auto px-8 py-4 bg-white text-haven-navy-900 
                       font-semibold rounded-xl transition-all duration-300
                       hover:shadow-[0_8px_32px_rgba(255,255,255,0.2)] hover:-translate-y-0.5
                       flex items-center justify-center gap-2 text-base">
            Start for $39/mo
            <ArrowRight className="w-5 h-5 transition-transform group-hover:translate-x-1" />
          </Link>
          
          {/* Secondary CTA */}
          <a
            href="#how-it-works"
            className="w-full sm:w-auto px-8 py-4 bg-white/5 backdrop-blur-sm
                       border border-white/20 text-white font-semibold rounded-xl
                       transition-all duration-300 hover:bg-white/10 hover:border-white/30
                       flex items-center justify-center gap-2 text-base">
            See How It Works
          </a>
        </div>
        
        {/* Small print below CTA */}
        <p className="mt-4 text-sm text-white/50 text-center lg:text-left">
          No contracts. Cancel anytime.
        </p>

        {/* Trust indicators */}
        <div className="mt-8 pt-6 border-t border-white/10">
          <div className="flex flex-wrap items-center justify-center lg:justify-start gap-3 sm:gap-4">
            {[
              { icon: Shield, text: 'Bank-Level Security' },
              { icon: Star, text: '4.9/5 Rating', filled: true },
              { icon: Award, text: '500+ Homes' },
            ].map((item, i) => (
              <div key={i} className="flex items-center gap-2 px-3 py-1.5 rounded-full
                                      bg-white/5 border border-white/10 text-xs sm:text-sm">
                <item.icon className={`w-3.5 h-3.5 ${item.filled ? 'text-sage-300 fill-sage-300' : 'text-white/60'}`} />
                <span className="text-white/80">{item.text}</span>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Right - Chat Preview (hidden on mobile, shown on lg+) */}
      <div className="hidden lg:block">
        <AlfredChatPreview />
      </div>
    </div>
  </div>
</div>

{/* Scroll indicator - mobile only */}
<div className="sm:hidden flex justify-center pb-6">
  <a href="#how-it-works" className="flex flex-col items-center gap-1 text-white/40">
    <span className="text-xs">Scroll to learn more</span>
    <ChevronDown className="w-5 h-5 animate-bounce" />
  </a>
</div>
```

---

## PHASE 3: "How It Works" Section

**IMPORTANT:** This is where Alfred gets introduced!

```tsx
<section id="how-it-works" className="py-16 sm:py-24 lg:py-32 bg-white">
  <div className="max-w-6xl mx-auto px-5 sm:px-6">
    
    {/* Section header - Introduce Alfred HERE */}
    <div className="text-center mb-12 sm:mb-16">
      
      {/* "Meet Alfred" badge - Alfred's introduction */}
      <div className="inline-flex items-center gap-2 px-4 py-2 bg-sage-100 
                      rounded-full text-sage-700 text-sm font-medium mb-4">
        <Sparkles className="w-4 h-4" />
        Meet Alfred
      </div>
      
      {/* Headline - font-serif */}
      <h2 className="text-3xl sm:text-4xl lg:text-5xl font-bold text-haven-navy-900 
                     tracking-tight font-serif">
        How Alfred Works
      </h2>
      
      <p className="mt-4 text-base sm:text-lg text-warm-600 max-w-2xl mx-auto">
        Add your home once. Alfred handles everything else — tracking, reminders, bills, and more.
      </p>
    </div>

    {/* Steps - Stack on mobile, grid on desktop */}
    <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-6 lg:gap-8">
      {steps.map((step, index) => (
        <div key={index} 
             className="group relative bg-white rounded-2xl p-6 sm:p-8 
                        shadow-elegant hover:shadow-elegant-lg
                        border border-warm-100 hover:border-sage-200
                        transition-all duration-500 hover:-translate-y-1">
          
          {/* Step number */}
          <div className="absolute -top-3 -left-3 sm:-top-4 sm:-left-4 w-8 h-8 sm:w-10 sm:h-10 
                          bg-haven-navy-900 rounded-xl flex items-center justify-center
                          text-white font-bold text-sm sm:text-base
                          group-hover:bg-sage-600 transition-colors duration-300">
            {step.number}
          </div>
          
          {/* Icon */}
          <div className="w-12 h-12 sm:w-14 sm:h-14 rounded-xl 
                          bg-gradient-to-br from-sage-100 to-sage-50 
                          flex items-center justify-center mb-5
                          group-hover:scale-105 transition-transform duration-300">
            <step.icon className="w-6 h-6 sm:w-7 sm:h-7 text-sage-600" />
          </div>
          
          <h3 className="text-lg sm:text-xl font-bold text-haven-navy-900 mb-2 sm:mb-3">
            {step.title}
          </h3>
          
          <p className="text-sm sm:text-base text-warm-600 leading-relaxed">
            {step.description}
          </p>
        </div>
      ))}
    </div>
  </div>
</section>
```

---

## PHASE 4: Cards & Content Sections

### Standard Card Pattern

```tsx
<div className="group bg-white rounded-2xl p-6 sm:p-8 
                shadow-elegant hover:shadow-elegant-lg
                border border-warm-100 hover:border-sage-200
                transition-all duration-500 hover:-translate-y-1">
  
  {/* Icon */}
  <div className="w-12 h-12 rounded-xl bg-haven-navy-900 
                  flex items-center justify-center mb-5
                  group-hover:bg-sage-600 transition-colors duration-300">
    <IconComponent className="w-6 h-6 text-white" />
  </div>
  
  <h3 className="text-lg sm:text-xl font-bold text-haven-navy-900 mb-2">
    Card Title
  </h3>
  
  <p className="text-sm sm:text-base text-warm-600 leading-relaxed">
    Card description.
  </p>
</div>
```

### Feature List Pattern

```tsx
<ul className="space-y-3 sm:space-y-4">
  {features.map((feature, i) => (
    <li key={i} className="flex items-start gap-3">
      <div className="mt-0.5 w-5 h-5 rounded-full bg-sage-100 
                      flex items-center justify-center flex-shrink-0">
        <Check className="w-3 h-3 text-sage-600" />
      </div>
      <span className="text-sm sm:text-base text-warm-700">{feature}</span>
    </li>
  ))}
</ul>
```

---

## PHASE 5: Handyman Section (Dark)

```tsx
<section className="py-16 sm:py-24 lg:py-32 bg-gradient-to-b from-haven-navy-950 to-haven-navy-900 
                    overflow-hidden relative">
  
  {/* Subtle glow */}
  <div className="absolute top-0 left-1/2 -translate-x-1/2 w-[500px] h-[300px]
                  bg-gradient-radial from-sage-400/5 to-transparent blur-3xl" />
  
  <div className="relative max-w-6xl mx-auto px-5 sm:px-6">
    <div className="grid lg:grid-cols-2 gap-10 lg:gap-16 items-center">
      
      {/* Left - Copy */}
      <div className="text-center lg:text-left">
        
        <div className="inline-flex items-center gap-2 px-3 py-1.5 bg-sage-400/10 
                        rounded-full text-sage-300 text-sm font-medium mb-6 
                        border border-sage-400/20">
          <Wrench className="w-4 h-4" />
          Haven Handyman
        </div>
        
        {/* font-serif headline */}
        <h2 className="text-2xl sm:text-3xl lg:text-4xl xl:text-5xl font-bold text-white 
                       tracking-tight font-serif leading-tight">
          A Real Handyman Who Knows
          <span className="block text-sage-300">Your Home</span>
        </h2>
        
        <p className="mt-5 sm:mt-6 text-base sm:text-lg text-white/70 leading-relaxed 
                      max-w-lg mx-auto lg:mx-0">
          No more explaining your home's quirks to every contractor. 
          Your Haven handyman has access to your complete home profile 
          and maintenance history.
        </p>
        
        {/* Features */}
        <ul className="mt-6 sm:mt-8 space-y-3 sm:space-y-4 text-left max-w-md mx-auto lg:mx-0">
          {[
            'Background-checked and insured',
            'Knows your home systems before they arrive',
            'Same handyman every time (when possible)',
            'Can handle 90% of small repairs',
            'Escalates to specialists when needed',
          ].map((feature, i) => (
            <li key={i} className="flex items-start gap-3">
              <div className="mt-0.5 w-5 h-5 rounded-full bg-sage-400/20 
                              flex items-center justify-center flex-shrink-0">
                <Check className="w-3 h-3 text-sage-300" />
              </div>
              <span className="text-sm sm:text-base text-white/80">{feature}</span>
            </li>
          ))}
        </ul>
        
        {/* Pricing badges - UPDATED */}
        <div className="mt-8 sm:mt-10 flex flex-wrap justify-center lg:justify-start gap-4">
          <div className="px-5 py-3 bg-white/5 backdrop-blur-sm rounded-xl border border-white/10">
            <span className="text-white/50 text-xs sm:text-sm block">Essentials</span>
            <div className="text-xl sm:text-2xl font-bold text-white">
              $99<span className="text-sm font-normal text-white/50">/visit</span>
            </div>
          </div>
          <div className="px-5 py-3 bg-sage-400/10 backdrop-blur-sm rounded-xl border border-sage-400/20">
            <span className="text-sage-300 text-xs sm:text-sm block">Lite $349+</span>
            <div className="text-xl sm:text-2xl font-bold text-white">Quarterly</div>
          </div>
          <div className="px-5 py-3 bg-sage-400/10 backdrop-blur-sm rounded-xl border border-sage-400/20">
            <span className="text-sage-300 text-xs sm:text-sm block">Haven $749+</span>
            <div className="text-xl sm:text-2xl font-bold text-white">Monthly</div>
          </div>
        </div>
      </div>
      
      {/* Right - Handyman Profile Card */}
      <div className="relative hidden lg:block">
        {/* Card glow */}
        <div className="absolute -inset-4 bg-gradient-to-r from-sage-400/10 to-sage-300/5 
                        rounded-3xl blur-2xl" />
        <div className="relative bg-white rounded-2xl shadow-elegant-xl overflow-hidden">
          {/* Handyman card content */}
        </div>
      </div>
    </div>
  </div>
</section>
```

---

## PHASE 6: Pricing Section

```tsx
<section id="pricing" className="py-16 sm:py-24 lg:py-32 bg-white">
  <div className="max-w-6xl mx-auto px-5 sm:px-6">
    
    <div className="text-center mb-12 sm:mb-16">
      <h2 className="text-3xl sm:text-4xl lg:text-5xl font-bold text-haven-navy-900 
                     tracking-tight font-serif">
        Simple, Transparent Pricing
      </h2>
      <p className="mt-4 text-base sm:text-lg text-warm-600 max-w-2xl mx-auto">
        Most homeowners start with Essentials. Upgrade anytime if you need more hands-on support.
      </p>
    </div>

    {/* Pricing cards - horizontal scroll on mobile */}
    <div className="flex overflow-x-auto snap-x snap-mandatory gap-4 pb-4 -mx-5 px-5
                    sm:grid sm:grid-cols-2 lg:grid-cols-3 sm:gap-6 lg:gap-8 
                    sm:overflow-visible sm:mx-0 sm:px-0 sm:pb-0
                    max-w-5xl sm:mx-auto">
      
      {/* Essentials - Featured */}
      <div className="flex-shrink-0 w-[85%] snap-start sm:w-auto relative p-6 sm:p-8 rounded-2xl 
                      bg-gradient-to-b from-haven-navy-900 to-haven-navy-950 
                      text-white ring-2 ring-sage-400 shadow-elegant-xl">
        
        {/* Badge */}
        <div className="absolute -top-3 left-1/2 -translate-x-1/2">
          <div className="px-4 py-1.5 bg-sage-500 text-white 
                          text-xs font-bold rounded-full shadow-lg whitespace-nowrap">
            Start Here
          </div>
        </div>

        <div className="mt-2">
          <h3 className="text-lg sm:text-xl font-bold text-white">Essentials</h3>
          <p className="text-sage-300 text-sm mt-1">Alfred + Core Features</p>
        </div>

        <div className="flex items-baseline gap-1 mt-5 sm:mt-6 mb-6 sm:mb-8">
          <span className="text-3xl sm:text-4xl font-bold text-white">$39</span>
          <span className="text-white/60">/month</span>
        </div>

        <ul className="space-y-3 mb-6 sm:mb-8">
          {essentialsFeatures.map((f, i) => (
            <li key={i} className="flex items-start gap-3">
              <Check className="w-5 h-5 text-sage-300 mt-0.5 flex-shrink-0" />
              <span className="text-white/80 text-sm">{f}</span>
            </li>
          ))}
        </ul>

        {/* White CTA on dark */}
        <Link
          href="/onboarding/welcome"
          className="block w-full py-3.5 bg-white text-haven-navy-900 
                     font-semibold rounded-xl text-center text-sm sm:text-base
                     hover:bg-sage-50 transition-colors">
          Get Started
        </Link>
      </div>

      {/* Lite */}
      <div className="flex-shrink-0 w-[85%] snap-start sm:w-auto p-6 sm:p-8 rounded-2xl 
                      bg-white border border-warm-100 shadow-elegant
                      hover:shadow-elegant-lg hover:border-sage-200
                      transition-all duration-500">
        
        <h3 className="text-lg sm:text-xl font-bold text-haven-navy-900">Haven Lite</h3>
        <p className="text-sage-600 text-sm mt-1">Text-based Support</p>

        <div className="flex items-baseline gap-1 mt-5 sm:mt-6 mb-6 sm:mb-8">
          <span className="text-3xl sm:text-4xl font-bold text-haven-navy-900">$349</span>
          <span className="text-warm-500">/month</span>
        </div>

        <ul className="space-y-3 mb-6 sm:mb-8">
          {liteFeatures.map((f, i) => (
            <li key={i} className="flex items-start gap-3">
              <Check className="w-5 h-5 text-sage-500 mt-0.5 flex-shrink-0" />
              <span className="text-warm-700 text-sm">{f}</span>
            </li>
          ))}
        </ul>

        {/* Navy CTA on light */}
        <Link
          href="/onboarding/welcome"
          className="block w-full py-3.5 bg-haven-navy-900 text-white 
                     font-semibold rounded-xl text-center text-sm sm:text-base
                     hover:bg-haven-navy-800 transition-colors">
          Choose Lite
        </Link>
      </div>

      {/* Haven */}
      <div className="flex-shrink-0 w-[85%] snap-start sm:w-auto p-6 sm:p-8 rounded-2xl 
                      bg-white border border-warm-100 shadow-elegant
                      hover:shadow-elegant-lg hover:border-sage-200
                      transition-all duration-500">
        
        <h3 className="text-lg sm:text-xl font-bold text-haven-navy-900">Haven</h3>
        <p className="text-sage-600 text-sm mt-1">Proactive Management</p>

        <div className="flex items-baseline gap-1 mt-5 sm:mt-6 mb-6 sm:mb-8">
          <span className="text-3xl sm:text-4xl font-bold text-haven-navy-900">$749</span>
          <span className="text-warm-500">/month</span>
        </div>

        <ul className="space-y-3 mb-6 sm:mb-8">
          {havenFeatures.map((f, i) => (
            <li key={i} className="flex items-start gap-3">
              <Check className="w-5 h-5 text-sage-500 mt-0.5 flex-shrink-0" />
              <span className="text-warm-700 text-sm">{f}</span>
            </li>
          ))}
        </ul>

        {/* Navy CTA on light */}
        <Link
          href="/onboarding/welcome"
          className="block w-full py-3.5 bg-haven-navy-900 text-white 
                     font-semibold rounded-xl text-center text-sm sm:text-base
                     hover:bg-haven-navy-800 transition-colors">
          Choose Haven
        </Link>
      </div>
    </div>

    {/* Show premium tiers toggle */}
    <div className="text-center mt-6 sm:mt-8">
      <button className="text-haven-navy-600 hover:text-haven-navy-900 font-medium 
                         text-sm sm:text-base transition-colors">
        Show premium tiers
      </button>
    </div>
  </div>
</section>
```

---

## PHASE 7: Final CTA Section

```tsx
<section className="py-16 sm:py-24 lg:py-32 bg-gradient-to-br from-haven-navy-900 via-haven-navy-950 to-[#050a14]">
  <div className="max-w-4xl mx-auto px-5 sm:px-6 text-center relative">
    
    {/* Glow */}
    <div className="absolute left-1/2 -translate-x-1/2 -top-20 w-[400px] sm:w-[600px] h-[400px] 
                    bg-gradient-radial from-sage-400/8 to-transparent blur-3xl" />
    
    {/* font-serif headline */}
    <h2 className="relative text-2xl sm:text-3xl lg:text-4xl xl:text-5xl font-bold text-white 
                   tracking-tight font-serif">
      Ready to take control of your home?
    </h2>
    
    <p className="mt-5 sm:mt-6 text-base sm:text-lg lg:text-xl text-white/70 max-w-2xl mx-auto">
      One bill. One app. A handyman who knows your home. 
      Join 500+ families who stopped managing and started living.
    </p>
    
    <div className="mt-8 sm:mt-10">
      {/* White CTA with price */}
      <Link
        href="/onboarding/welcome"
        className="group inline-flex items-center justify-center gap-2 
                   px-8 py-4 bg-white text-haven-navy-900 
                   font-semibold rounded-xl transition-all duration-300
                   hover:shadow-[0_8px_32px_rgba(255,255,255,0.25)] hover:-translate-y-0.5
                   text-base sm:text-lg">
        Get Started — $39/mo
        <ArrowRight className="w-5 h-5 transition-transform group-hover:translate-x-1" />
      </Link>
    </div>
    
    <p className="mt-4 sm:mt-6 text-sm text-white/50">
      No contracts. Cancel anytime.
    </p>
  </div>
</section>
```

---

## PHASE 8: Mobile-Specific Optimizations

### 8.1 Touch Targets

All interactive elements must be at least 44x44px:

```css
/* Add to globals.css */
@media (max-width: 640px) {
  button, a, [role="button"] {
    min-height: 44px;
  }
}
```

### 8.2 Safe Areas

```tsx
{/* Hero section */}
<section className="min-h-[100dvh] pt-safe pb-safe">
```

### 8.3 Horizontal Scroll for Cards

On mobile, card grids become horizontal scrollers:

```tsx
<div className="flex overflow-x-auto snap-x snap-mandatory gap-4 pb-4 -mx-5 px-5
                md:grid md:grid-cols-3 md:gap-8 md:overflow-visible md:mx-0 md:px-0 md:pb-0">
  {cards.map((card, i) => (
    <div key={i} className="flex-shrink-0 w-[85%] snap-start md:w-auto">
      {/* Card content */}
    </div>
  ))}
</div>
```

### 8.4 Hide Decorative Elements on Mobile

```tsx
{/* Floating orbs - performance optimization */}
<div className="hidden sm:block absolute ...">
```

### 8.5 Reduced Motion

```css
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    transition-duration: 0.01ms !important;
  }
}
```

---

## Verification Checklist

After implementation:

- [ ] Hero shows Haven brand, NOT Alfred (Alfred introduced in "How It Works")
- [ ] Hero CTA says "Start for $39/mo" (price in button)
- [ ] "No contracts. Cancel anytime." is small text below CTA
- [ ] "Meet Alfred" badge appears above "How Alfred Works" section
- [ ] Handyman pricing: $99/visit (Essentials), Quarterly (Lite $349), Monthly (Haven $749)
- [ ] All headlines use `font-serif` (Playfair Display)
- [ ] Buttons: White on dark backgrounds, Navy on light backgrounds
- [ ] Sage only used for accents, never primary CTAs
- [ ] Looks stunning on mobile (375px)
- [ ] Looks stunning on desktop (1440px)
- [ ] Horizontal scroll works for cards on mobile
- [ ] Touch targets are 44px minimum
- [ ] `pnpm build` passes

---

## Run Command

```bash
cd /Users/tomburke/Projects/Housing-Manager

# Open Claude Code and run:
Read and implement prompts/WEBSITE-DESIGN-OVERHAUL.md

Focus on:
1. Hero messaging changes (Haven brand, not Alfred)
2. Price in CTA button
3. "Meet Alfred" badge at How It Works
4. Handyman pricing update
5. Mobile excellence
```

---

*This prompt creates a premium, mobile-first website that properly introduces Haven's brand before revealing Alfred as the mechanism that delivers the value.*

# Prompt 012: Website Design Elevation

**Objective:** Transform the Haven marketing website from good to spectacular. Elevate every visual detail to convey sophistication, trust, and premium quality while maintaining all existing content exactly as-is.

**Design Philosophy:** Apple-level attention to detail. Linear-inspired modern elegance. The visual sophistication of a fintech platform combined with the warmth of a premium hospitality brand.

---

## CRITICAL CONSTRAINTS

1. **DO NOT CHANGE ANY COPY** - All text content must remain exactly as written
2. **Maintain all functionality** - Links, buttons, interactivity must work identically
3. **Keep the same information architecture** - Same sections, same order
4. **Use the official Sage Green color palette** (see below)

---

## Official Color Palette: Sage Green

**Vibe:** Natural, grounded, calm. A well-organized home with a garden. Modern without being cold.

| Role | Name | Hex | Usage |
|------|------|-----|-------|
| **Primary** | Navy | `#0a1929` | Headers, primary buttons, dark sections |
| **Accent** | Sage | `#7D8E74` | Accent highlights, icons, secondary elements |
| **Soft Accent** | Light Sage | `#A4B494` | Hover states, checkmarks, soft highlights |
| **Light BG** | Soft Green | `#F4F6F2` | Page backgrounds, light sections |
| **Card BG** | Cream | `#FAFAF7` | Cards, content areas |
| **Text Dark** | Navy | `#0a1929` | Primary text |
| **Text Muted** | Warm Gray | `#6B7280` | Secondary text |

### Tailwind Sage Colors

```typescript
sage: {
  50: '#F4F6F2',   // Light BG / Soft Green
  100: '#E8EDE4',  // Subtle backgrounds
  200: '#D1DBC9',  // Borders, dividers
  300: '#A4B494',  // Light Sage / soft accent
  400: '#8FA37F',  // Medium accent
  500: '#7D8E74',  // Primary Sage accent
  600: '#6B7A63',  // Darker accent / hover
  700: '#5A6853',  // Dark accent
  800: '#4A5544',  // Very dark
  900: '#3B4536',  // Darkest
}
```

### Color Usage Rules

- **White buttons** on dark (navy) backgrounds
- **Navy buttons** on light backgrounds  
- **Sage** for accents, badges, checkmarks, icons - NOT for primary CTAs
- **Light Sage** (`#A4B494`) for hover states and soft highlights
- **Soft Green** (`#F4F6F2`) for alternating section backgrounds
- **Cream** (`#FAFAF7`) for card backgrounds

---

## PHASE 1: Global Design System Enhancements

### 1.1 Typography Refinement

Update `tailwind.config.ts` to add refined typography settings:

```typescript
// Add to theme.extend:
fontSize: {
  'display-2xl': ['4.5rem', { lineHeight: '1.1', letterSpacing: '-0.03em' }],
  'display-xl': ['3.75rem', { lineHeight: '1.1', letterSpacing: '-0.025em' }],
  'display-lg': ['3rem', { lineHeight: '1.15', letterSpacing: '-0.02em' }],
  'display-md': ['2.25rem', { lineHeight: '1.2', letterSpacing: '-0.015em' }],
  'display-sm': ['1.875rem', { lineHeight: '1.25', letterSpacing: '-0.01em' }],
},
letterSpacing: {
  'tighter': '-0.03em',
  'tight': '-0.015em',
  'relaxed': '0.015em',
  'wide': '0.05em',
  'wider': '0.1em',
},
```

### 1.2 Enhanced Shadows & Depth

Add premium shadow system:

```typescript
boxShadow: {
  // Existing shadows...
  'elegant': '0 1px 2px rgba(11, 17, 32, 0.04), 0 4px 8px rgba(11, 17, 32, 0.04), 0 8px 16px rgba(11, 17, 32, 0.02)',
  'elegant-lg': '0 2px 4px rgba(11, 17, 32, 0.02), 0 8px 16px rgba(11, 17, 32, 0.06), 0 16px 32px rgba(11, 17, 32, 0.04)',
  'elegant-xl': '0 4px 8px rgba(11, 17, 32, 0.02), 0 16px 32px rgba(11, 17, 32, 0.08), 0 32px 64px rgba(11, 17, 32, 0.04)',
  'card-hover': '0 8px 24px rgba(11, 17, 32, 0.12), 0 16px 48px rgba(11, 17, 32, 0.08)',
  'button': '0 1px 2px rgba(11, 17, 32, 0.08), 0 2px 4px rgba(11, 17, 32, 0.04)',
  'button-hover': '0 4px 12px rgba(11, 17, 32, 0.15), 0 8px 24px rgba(11, 17, 32, 0.08)',
  'inner-glow': 'inset 0 1px 0 rgba(255, 255, 255, 0.15), inset 0 -1px 0 rgba(0, 0, 0, 0.05)',
  'glow-primary': '0 0 0 3px rgba(16, 42, 67, 0.1), 0 0 24px rgba(16, 42, 67, 0.2)',
  'glow-accent': '0 0 0 3px rgba(125, 142, 116, 0.15), 0 0 24px rgba(125, 142, 116, 0.25)',
},
```

### 1.3 Enhanced Animations

Add sophisticated animation library:

```typescript
animation: {
  // Existing animations...
  'float': 'float 6s ease-in-out infinite',
  'float-slow': 'float 8s ease-in-out infinite',
  'float-delayed': 'float 6s ease-in-out 2s infinite',
  'gradient-shift': 'gradientShift 8s ease infinite',
  'reveal-up': 'revealUp 0.7s cubic-bezier(0.16, 1, 0.3, 1) forwards',
  'reveal-right': 'revealRight 0.6s cubic-bezier(0.16, 1, 0.3, 1) forwards',
  'scale-up': 'scaleUp 0.5s cubic-bezier(0.16, 1, 0.3, 1) forwards',
  'blur-in': 'blurIn 0.8s ease-out forwards',
  'count-up': 'countUp 2s ease-out forwards',
  'shine': 'shine 3s ease-in-out infinite',
},
keyframes: {
  // Existing keyframes...
  float: {
    '0%, 100%': { transform: 'translateY(0)' },
    '50%': { transform: 'translateY(-12px)' },
  },
  gradientShift: {
    '0%, 100%': { backgroundPosition: '0% 50%' },
    '50%': { backgroundPosition: '100% 50%' },
  },
  revealUp: {
    '0%': { opacity: '0', transform: 'translateY(30px)' },
    '100%': { opacity: '1', transform: 'translateY(0)' },
  },
  revealRight: {
    '0%': { opacity: '0', transform: 'translateX(-20px)' },
    '100%': { opacity: '1', transform: 'translateX(0)' },
  },
  scaleUp: {
    '0%': { opacity: '0', transform: 'scale(0.9)' },
    '100%': { opacity: '1', transform: 'scale(1)' },
  },
  blurIn: {
    '0%': { opacity: '0', filter: 'blur(8px)' },
    '100%': { opacity: '1', filter: 'blur(0)' },
  },
  shine: {
    '0%': { left: '-100%' },
    '50%, 100%': { left: '100%' },
  },
},
```

### 1.4 Create Shared Animation Styles

Create `apps/web/src/styles/animations.css`:

```css
/* Scroll-triggered animations */
.animate-on-scroll {
  opacity: 0;
}

.animate-on-scroll.is-visible {
  animation: revealUp 0.7s cubic-bezier(0.16, 1, 0.3, 1) forwards;
}

/* Staggered children */
.stagger-children > * {
  opacity: 0;
  animation: revealUp 0.5s cubic-bezier(0.16, 1, 0.3, 1) forwards;
}

.stagger-children.is-visible > *:nth-child(1) { animation-delay: 0ms; }
.stagger-children.is-visible > *:nth-child(2) { animation-delay: 100ms; }
.stagger-children.is-visible > *:nth-child(3) { animation-delay: 200ms; }
.stagger-children.is-visible > *:nth-child(4) { animation-delay: 300ms; }
.stagger-children.is-visible > *:nth-child(5) { animation-delay: 400ms; }
.stagger-children.is-visible > *:nth-child(6) { animation-delay: 500ms; }

/* Premium button styles */
.btn-primary {
  position: relative;
  overflow: hidden;
  transition: all 0.3s cubic-bezier(0.16, 1, 0.3, 1);
}

.btn-primary::before {
  content: '';
  position: absolute;
  top: 0;
  left: -100%;
  width: 100%;
  height: 100%;
  background: linear-gradient(
    90deg,
    transparent,
    rgba(255, 255, 255, 0.2),
    transparent
  );
  transition: left 0.5s ease;
}

.btn-primary:hover::before {
  left: 100%;
}

.btn-primary:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 24px rgba(11, 17, 32, 0.2);
}

/* Card hover effects */
.card-hover {
  transition: all 0.4s cubic-bezier(0.16, 1, 0.3, 1);
}

.card-hover:hover {
  transform: translateY(-4px);
  box-shadow: 0 12px 32px rgba(11, 17, 32, 0.12);
}

/* Gradient text */
.gradient-text {
  background: linear-gradient(135deg, #A4B494 0%, #7D8E74 100%);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
}

/* Glass effect */
.glass {
  background: rgba(255, 255, 255, 0.7);
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
  border: 1px solid rgba(255, 255, 255, 0.2);
}

.glass-dark {
  background: rgba(11, 17, 32, 0.8);
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
  border: 1px solid rgba(255, 255, 255, 0.1);
}
```

---

## PHASE 2: Hero Section Transformation

The hero is the first impression. Make it commanding, sophisticated, and memorable.

### 2.1 Enhanced Hero Background

Replace current gradient with a more dynamic, layered approach:

```tsx
<section className="relative overflow-hidden min-h-[100dvh] sm:min-h-0">
  {/* Multi-layer gradient background */}
  <div className="absolute inset-0 bg-gradient-to-br from-haven-navy-900 via-haven-navy-950 to-[#050a14]" />
  
  {/* Animated gradient overlay */}
  <div className="absolute inset-0 bg-[radial-gradient(ellipse_80%_80%_at_50%_-20%,rgba(164,180,148,0.15),transparent)] animate-gradient-shift" 
       style={{ backgroundSize: '200% 200%' }} />
  
  {/* Subtle grid pattern */}
  <div className="absolute inset-0 opacity-[0.03]"
       style={{
         backgroundImage: `linear-gradient(rgba(255,255,255,0.1) 1px, transparent 1px),
                          linear-gradient(90deg, rgba(255,255,255,0.1) 1px, transparent 1px)`,
         backgroundSize: '64px 64px'
       }} />
  
  {/* Floating orbs */}
  <div className="absolute top-20 right-[15%] w-[400px] h-[400px] rounded-full 
                  bg-gradient-to-br from-sage-400/10 to-transparent blur-3xl animate-float" />
  <div className="absolute bottom-20 left-[10%] w-[300px] h-[300px] rounded-full 
                  bg-gradient-to-tr from-haven-navy-700/30 to-transparent blur-3xl animate-float-delayed" />
  
  {/* Noise texture overlay for depth */}
  <div className="absolute inset-0 opacity-[0.015] mix-blend-soft-light"
       style={{ backgroundImage: 'url(/noise.png)' }} />
```

### 2.2 Refined Hero Typography

Make the headline more impactful:

```tsx
{/* Animated badge */}
<div className="inline-flex items-center gap-2 px-4 py-2 bg-white/10 backdrop-blur-sm 
                rounded-full border border-white/10 mb-6 animate-reveal-up"
     style={{ animationDelay: '0.1s' }}>
  <div className="w-2 h-2 rounded-full bg-sage-400 animate-pulse" />
  <span className="text-sm font-medium text-white/90 tracking-wide">Meet Alfred</span>
  <span className="text-white/40 mx-1">•</span>
  <span className="text-sm text-sage-300/90">Your Home Manager</span>
</div>

{/* Headline with refined styling */}
<h1 className="animate-reveal-up" style={{ animationDelay: '0.2s' }}>
  <span className="block text-[2.75rem] sm:text-5xl lg:text-6xl xl:text-7xl 
                   font-bold text-white tracking-tight leading-[1.05] font-serif">
    Your home, finally
  </span>
  <span className="block text-[2.75rem] sm:text-5xl lg:text-6xl xl:text-7xl 
                   font-bold tracking-tight leading-[1.05] font-serif
                   bg-gradient-to-r from-sage-300 via-sage-200 to-sage-400 
                   bg-clip-text text-transparent">
    under control.
  </span>
</h1>

{/* Subheadline with better rhythm */}
<p className="mt-6 text-lg sm:text-xl text-white/70 max-w-xl leading-relaxed 
              animate-reveal-up" style={{ animationDelay: '0.3s' }}>
  Alfred tracks your bills, reminds you before things break, finds savings 
  you're missing, and consolidates everything into one monthly payment. 
  <span className="text-white/90 font-medium">Stop managing. Start living.</span>
</p>
```

### 2.3 Premium CTA Buttons

```tsx
{/* Primary CTA - Premium button */}
<Link
  href="/onboarding/welcome"
  className="group relative w-full sm:w-auto px-8 py-4 bg-white text-haven-navy-900 
             font-semibold rounded-xl overflow-hidden transition-all duration-300
             hover:shadow-[0_8px_32px_rgba(255,255,255,0.25)] hover:-translate-y-0.5">
  {/* Shine effect */}
  <span className="absolute inset-0 -translate-x-full group-hover:translate-x-full 
                   transition-transform duration-700 bg-gradient-to-r 
                   from-transparent via-haven-navy-100/50 to-transparent" />
  <span className="relative flex items-center justify-center gap-2">
    Get Started
    <ArrowRight className="w-5 h-5 transition-transform group-hover:translate-x-1" />
  </span>
</Link>

{/* Secondary CTA - Glass button */}
<a
  href="#how-it-works"
  className="group w-full sm:w-auto px-8 py-4 bg-white/5 backdrop-blur-sm
             border border-white/20 text-white font-semibold rounded-xl
             transition-all duration-300 hover:bg-white/10 hover:border-white/30
             flex items-center justify-center gap-2">
  See How It Works
  <ChevronDown className="w-4 h-4 transition-transform group-hover:translate-y-1" />
</a>
```

### 2.4 Elevated Trust Indicators

```tsx
{/* Trust bar with glass effect */}
<div className="mt-10 pt-8 border-t border-white/10 animate-reveal-up" 
     style={{ animationDelay: '0.6s' }}>
  <div className="flex flex-wrap items-center justify-center lg:justify-start gap-6 sm:gap-8">
    {[
      { icon: Shield, text: 'Bank-Level Security', highlight: false },
      { icon: Star, text: '4.9/5 Rating', highlight: true },
      { icon: Award, text: '500+ Homes', highlight: false },
    ].map((item, i) => (
      <div key={i} className="flex items-center gap-2.5 px-4 py-2 rounded-full
                               bg-white/5 border border-white/10 backdrop-blur-sm">
        <item.icon className={`w-4 h-4 ${item.highlight ? 'text-sage-300 fill-sage-300' : 'text-white/60'}`} />
        <span className="text-sm text-white/80 font-medium">{item.text}</span>
      </div>
    ))}
  </div>
</div>
```

---

## PHASE 3: Alfred Chat Preview Enhancement

Make the chat preview feel like a premium product screenshot.

### 3.1 Refined Chat Container

```tsx
{/* Floating chat preview with enhanced presentation */}
<div className="relative animate-float-slow">
  {/* Glow behind */}
  <div className="absolute -inset-4 bg-gradient-to-r from-sage-400/20 via-sage-300/10 to-sage-400/20 
                  rounded-3xl blur-2xl opacity-60" />
  
  {/* Browser chrome frame */}
  <div className="relative bg-gradient-to-b from-haven-navy-800 to-haven-navy-900 
                  rounded-2xl shadow-elegant-xl border border-white/10 overflow-hidden">
    {/* Window controls */}
    <div className="flex items-center gap-2 px-4 py-3 bg-haven-navy-800/50 
                    border-b border-white/5">
      <div className="flex gap-1.5">
        <div className="w-3 h-3 rounded-full bg-red-400/80" />
        <div className="w-3 h-3 rounded-full bg-yellow-400/80" />
        <div className="w-3 h-3 rounded-full bg-green-400/80" />
      </div>
      <div className="flex-1 flex justify-center">
        <div className="px-4 py-1 bg-white/5 rounded-md text-xs text-white/50 font-medium">
          alfred.havenhome.dev
        </div>
      </div>
    </div>
    
    {/* Chat content */}
    <div className="p-6 space-y-4">
      {/* Chat messages with refined styling... */}
    </div>
  </div>
  
  {/* Floating stats badges */}
  <div className="absolute -right-4 top-1/4 bg-white rounded-xl shadow-elegant-lg 
                  p-3 animate-float" style={{ animationDelay: '1s' }}>
    <div className="flex items-center gap-2">
      <div className="w-8 h-8 rounded-full bg-sage-100 flex items-center justify-center">
        <TrendingDown className="w-4 h-4 text-sage-600" />
      </div>
      <div>
        <div className="text-xs text-warm-500 font-medium">Savings Found</div>
        <div className="text-lg font-bold text-haven-navy-900">$340</div>
      </div>
    </div>
  </div>
</div>
```

---

## PHASE 4: Section-by-Section Polish

### 4.1 "How It Works" Section

```tsx
<section id="how-it-works" className="relative py-24 sm:py-32 bg-gradient-to-b from-white to-warm-50/50 overflow-hidden">
  {/* Subtle background decoration */}
  <div className="absolute top-0 left-1/2 -translate-x-1/2 w-[800px] h-[800px] 
                  bg-gradient-radial from-sage-100/40 to-transparent opacity-50" />
  
  <div className="relative max-w-6xl mx-auto px-4 sm:px-6">
    {/* Section header with refined styling */}
    <div className="text-center mb-16 sm:mb-20">
      <div className="inline-flex items-center gap-2 px-3 py-1.5 bg-sage-100 
                      rounded-full text-sage-700 text-sm font-medium mb-4">
        <Sparkles className="w-4 h-4" />
        Simple Setup
      </div>
      <h2 className="text-3xl sm:text-4xl lg:text-5xl font-bold text-haven-navy-900 
                     tracking-tight font-serif">
        How Alfred Works
      </h2>
      <p className="mt-4 text-lg text-warm-600 max-w-2xl mx-auto">
        Add your home once. Alfred handles everything else — tracking, 
        reminders, bills, and more.
      </p>
    </div>

    {/* Steps with enhanced cards */}
    <div className="grid md:grid-cols-3 gap-8 lg:gap-12">
      {steps.map((step, index) => (
        <div key={index} 
             className="group relative bg-white rounded-2xl p-8 
                        shadow-elegant hover:shadow-elegant-lg 
                        border border-warm-100 hover:border-sage-200
                        transition-all duration-500 card-hover">
          {/* Step number */}
          <div className="absolute -top-4 -left-4 w-10 h-10 bg-haven-navy-900 
                          rounded-xl flex items-center justify-center
                          shadow-button text-white font-bold text-lg
                          group-hover:bg-sage-600 transition-colors duration-300">
            {step.step}
          </div>
          
          {/* Icon with animated background */}
          <div className="w-14 h-14 rounded-xl bg-gradient-to-br from-sage-100 to-sage-50 
                          flex items-center justify-center mb-6
                          group-hover:scale-110 transition-transform duration-300">
            <step.Icon className="w-7 h-7 text-sage-600" />
          </div>
          
          <h3 className="text-xl font-bold text-haven-navy-900 mb-3">
            {step.title}
          </h3>
          <p className="text-warm-600 leading-relaxed">
            {step.description}
          </p>
        </div>
      ))}
    </div>
  </div>
</section>
```

### 4.2 Email Categories Grid

```tsx
{/* Email categories with elegant grid */}
<div className="mt-16 sm:mt-20">
  <p className="text-center text-warm-500 text-sm font-medium tracking-wide uppercase mb-8">
    Emails Alfred handles for you
  </p>
  <div className="grid grid-cols-2 sm:grid-cols-4 gap-4 max-w-4xl mx-auto">
    {emailTypes.map((type, index) => (
      <div key={index}
           className="group flex flex-col items-center p-5 bg-white rounded-xl
                      border border-warm-100 hover:border-sage-200
                      shadow-sm hover:shadow-elegant transition-all duration-300
                      cursor-default">
        <div className="w-12 h-12 rounded-xl bg-haven-navy-50 
                        flex items-center justify-center mb-3
                        group-hover:bg-sage-100 transition-colors duration-300">
          <type.icon className="w-6 h-6 text-haven-navy-600 group-hover:text-sage-700 
                                transition-colors duration-300" />
        </div>
        <span className="text-sm font-medium text-haven-navy-900">{type.label}</span>
        <span className="text-xs text-warm-500 mt-1">{type.example}</span>
      </div>
    ))}
  </div>
</div>
```

### 4.3 "What Alfred Does" Feature Cards

```tsx
<section className="py-24 sm:py-32 bg-white">
  <div className="max-w-6xl mx-auto px-4 sm:px-6">
    <div className="text-center mb-16">
      <h2 className="text-3xl sm:text-4xl lg:text-5xl font-bold text-haven-navy-900 
                     tracking-tight font-serif">
        What Alfred Does for You
      </h2>
      <p className="mt-4 text-lg text-warm-600 max-w-3xl mx-auto">
        Think of Alfred as your personal home assistant who never sleeps, 
        never forgets, and actually enjoys organizing your life.
      </p>
    </div>

    <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-6 lg:gap-8">
      {features.map((feature, index) => (
        <div key={index}
             className="group relative p-8 rounded-2xl bg-gradient-to-br from-warm-50/50 to-white
                        border border-warm-100 hover:border-sage-200
                        transition-all duration-500 card-hover">
          {/* Subtle gradient on hover */}
          <div className="absolute inset-0 rounded-2xl bg-gradient-to-br 
                          from-sage-50/0 to-sage-100/0 
                          group-hover:from-sage-50/50 group-hover:to-sage-100/30
                          transition-all duration-500 -z-10" />
          
          <div className="w-12 h-12 rounded-xl bg-haven-navy-900 
                          flex items-center justify-center mb-5
                          group-hover:bg-sage-600 transition-colors duration-300
                          shadow-button">
            <feature.icon className="w-6 h-6 text-white" />
          </div>
          
          <h3 className="text-xl font-bold text-haven-navy-900 mb-2">
            {feature.title}
          </h3>
          <p className="text-warm-600 leading-relaxed">
            {feature.description}
          </p>
        </div>
      ))}
    </div>
  </div>
</section>
```

### 4.4 Handyman Section with Premium Card

```tsx
<section className="py-24 sm:py-32 bg-gradient-to-b from-haven-navy-950 to-haven-navy-900 overflow-hidden">
  <div className="max-w-6xl mx-auto px-4 sm:px-6">
    <div className="grid lg:grid-cols-2 gap-12 lg:gap-16 items-center">
      {/* Left - Copy */}
      <div>
        <div className="inline-flex items-center gap-2 px-3 py-1.5 bg-sage-400/10 
                        rounded-full text-sage-300 text-sm font-medium mb-6 
                        border border-sage-400/20">
          <Wrench className="w-4 h-4" />
          Haven Handyman
        </div>
        
        <h2 className="text-3xl sm:text-4xl lg:text-5xl font-bold text-white 
                       tracking-tight font-serif leading-tight">
          A Real Handyman Who Knows
          <span className="block text-sage-300">Your Home</span>
        </h2>
        
        <p className="mt-6 text-lg text-white/70 leading-relaxed">
          No more explaining your home's quirks to every contractor. 
          Your Haven handyman has access to your complete home profile 
          and maintenance history.
        </p>
        
        {/* Feature list */}
        <ul className="mt-8 space-y-4">
          {handymanFeatures.map((feature, i) => (
            <li key={i} className="flex items-start gap-3">
              <div className="mt-0.5 w-5 h-5 rounded-full bg-sage-400/20 
                              flex items-center justify-center flex-shrink-0">
                <Check className="w-3 h-3 text-sage-300" />
              </div>
              <span className="text-white/80">{feature}</span>
            </li>
          ))}
        </ul>
        
        {/* Pricing badges */}
        <div className="mt-10 flex flex-wrap gap-4">
          <div className="px-6 py-3 bg-white/5 backdrop-blur-sm rounded-xl 
                          border border-white/10">
            <span className="text-white/50 text-sm">Essentials</span>
            <div className="text-2xl font-bold text-white">$99<span className="text-base font-normal text-white/50">/visit</span></div>
          </div>
          <div className="px-6 py-3 bg-sage-400/10 backdrop-blur-sm rounded-xl 
                          border border-sage-400/20">
            <span className="text-sage-300 text-sm">Haven $749+</span>
            <div className="text-2xl font-bold text-white">Included</div>
          </div>
        </div>
      </div>
      
      {/* Right - Handyman Profile Card */}
      <div className="relative">
        <div className="absolute -inset-4 bg-gradient-to-r from-sage-400/10 to-sage-300/5 
                        rounded-3xl blur-2xl" />
        <div className="relative bg-white rounded-2xl shadow-elegant-xl overflow-hidden">
          {/* Card content... */}
        </div>
      </div>
    </div>
  </div>
</section>
```

### 4.5 Personas/Use Cases Section

```tsx
<section className="py-24 sm:py-32 bg-white">
  <div className="max-w-6xl mx-auto px-4 sm:px-6">
    <div className="text-center mb-16">
      <h2 className="text-3xl sm:text-4xl lg:text-5xl font-bold text-haven-navy-900 
                     tracking-tight font-serif">
        Is Haven Right for You?
      </h2>
      <p className="mt-4 text-lg text-warm-600">
        Most homeowners start with Essentials. Here's who we help most.
      </p>
    </div>

    <div className="grid md:grid-cols-3 gap-6 lg:gap-8">
      {personas.map((persona, index) => (
        <div key={index}
             className={`group relative p-8 rounded-2xl transition-all duration-500
                        ${persona.popular 
                          ? 'bg-haven-navy-900 text-white shadow-elegant-xl scale-[1.02] lg:scale-105' 
                          : 'bg-white border border-warm-100 hover:border-sage-200 card-hover'}`}>
          {/* Popular badge */}
          {persona.popular && (
            <div className="absolute -top-3 left-1/2 -translate-x-1/2 px-4 py-1 
                            bg-sage-400 text-haven-navy-900 text-xs font-bold 
                            rounded-full uppercase tracking-wide">
              Most Popular
            </div>
          )}
          
          {/* Icon */}
          <div className={`w-14 h-14 rounded-xl flex items-center justify-center mb-6
                          ${persona.popular 
                            ? 'bg-white/10' 
                            : 'bg-gradient-to-br from-sage-100 to-sage-50'}`}>
            <persona.icon className={`w-7 h-7 ${persona.popular ? 'text-sage-300' : 'text-sage-600'}`} />
          </div>
          
          <h3 className={`text-xl font-bold mb-2 ${persona.popular ? 'text-white' : 'text-haven-navy-900'}`}>
            {persona.title}
          </h3>
          <p className={`text-sm leading-relaxed mb-6 ${persona.popular ? 'text-white/70' : 'text-warm-600'}`}>
            {persona.description}
          </p>
          
          {/* Feature list */}
          <ul className="space-y-3 mb-8">
            {persona.features.map((feature, i) => (
              <li key={i} className="flex items-start gap-2">
                <Check className={`w-4 h-4 mt-0.5 flex-shrink-0 
                                  ${persona.popular ? 'text-sage-300' : 'text-sage-500'}`} />
                <span className={`text-sm ${persona.popular ? 'text-white/80' : 'text-warm-700'}`}>
                  {feature}
                </span>
              </li>
            ))}
          </ul>
          
          {/* Price and CTA */}
          <div className={`pt-6 border-t ${persona.popular ? 'border-white/10' : 'border-warm-100'}`}>
            <div className="flex items-baseline gap-1 mb-4">
              <span className={`text-3xl font-bold ${persona.popular ? 'text-white' : 'text-haven-navy-900'}`}>
                {persona.price}
              </span>
              <span className={`text-sm ${persona.popular ? 'text-white/60' : 'text-warm-500'}`}>/mo</span>
            </div>
            <div className={`text-sm ${persona.popular ? 'text-sage-300' : 'text-sage-600'} font-medium`}>
              {persona.tier}
            </div>
          </div>
        </div>
      ))}
    </div>
  </div>
</section>
```

### 4.6 "One Bill" Section Enhancement

```tsx
<section className="py-24 sm:py-32 bg-gradient-to-b from-warm-50 to-white overflow-hidden">
  <div className="max-w-6xl mx-auto px-4 sm:px-6">
    <div className="text-center mb-16">
      <h2 className="text-3xl sm:text-4xl lg:text-5xl font-bold text-haven-navy-900 
                     tracking-tight font-serif">
        One Bill. Seriously.
      </h2>
      <p className="mt-4 text-lg text-warm-600 max-w-2xl mx-auto">
        Stop juggling seven different payment due dates. Haven consolidates 
        everything into one simple monthly payment.
      </p>
    </div>

    <div className="grid lg:grid-cols-2 gap-8 lg:gap-16 items-center max-w-5xl mx-auto">
      {/* Before - Chaotic bills */}
      <div className="relative p-6 bg-white rounded-2xl border border-warm-200 shadow-elegant">
        <div className="absolute -top-3 left-6 px-3 py-1 bg-warm-100 text-warm-600 
                        text-xs font-bold rounded-full flex items-center gap-1.5">
          <span className="w-2 h-2 rounded-full bg-red-400" />
          Before Haven
        </div>
        
        <div className="space-y-3 mt-4">
          {beforeBills.map((bill, i) => (
            <div key={i} className="flex items-center justify-between p-3 
                                    bg-warm-50 rounded-lg border border-warm-100">
              <div>
                <span className="text-sm font-medium text-haven-navy-900">{bill.name}</span>
                <span className="ml-2 text-xs text-warm-500">Due: {bill.due}</span>
              </div>
              <span className="text-sm font-semibold text-haven-navy-900">{bill.amount}</span>
            </div>
          ))}
        </div>
        
        <div className="mt-4 pt-4 border-t border-warm-100 flex items-center justify-between">
          <span className="text-sm text-warm-500">7 different payments</span>
          <span className="text-sm text-red-500 font-medium">7 chances to be late</span>
        </div>
      </div>
      
      {/* After - Single Haven bill */}
      <div className="relative">
        <div className="absolute -inset-4 bg-gradient-to-r from-sage-200/50 to-sage-100/30 
                        rounded-3xl blur-2xl" />
        <div className="relative p-8 bg-gradient-to-br from-haven-navy-900 to-haven-navy-950 
                        rounded-2xl shadow-elegant-xl border border-haven-navy-800">
          <div className="absolute -top-3 left-6 px-3 py-1 bg-sage-400 text-haven-navy-900 
                          text-xs font-bold rounded-full flex items-center gap-1.5">
            <Check className="w-3 h-3" />
            With Haven
          </div>
          
          <div className="flex items-center gap-4 mt-4">
            <div className="w-16 h-16 rounded-xl bg-white/10 flex items-center justify-center">
              <Home className="w-8 h-8 text-sage-300" />
            </div>
            <div>
              <span className="text-6xl font-bold text-white">1</span>
              <div className="text-white/70">Monthly Bill</div>
            </div>
          </div>
          
          <div className="mt-6 space-y-2">
            <div className="flex items-center gap-2 text-white/80 text-sm">
              <Check className="w-4 h-4 text-sage-300" />
              Same day every month
            </div>
            <div className="flex items-center gap-2 text-white/80 text-sm">
              <Check className="w-4 h-4 text-sage-300" />
              All bills included
            </div>
            <div className="flex items-center gap-2 text-white/80 text-sm">
              <Check className="w-4 h-4 text-sage-300" />
              Never late
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</section>
```

### 4.7 Pricing Section Refinement

```tsx
<section id="pricing" className="py-24 sm:py-32 bg-white">
  <div className="max-w-6xl mx-auto px-4 sm:px-6">
    <div className="text-center mb-16">
      <h2 className="text-3xl sm:text-4xl lg:text-5xl font-bold text-haven-navy-900 
                     tracking-tight font-serif">
        Simple, Transparent Pricing
      </h2>
      <p className="mt-4 text-lg text-warm-600">
        Most homeowners start with Essentials. Upgrade anytime if you need more hands-on support.
      </p>
    </div>

    <div className="grid md:grid-cols-3 gap-6 lg:gap-8 max-w-5xl mx-auto">
      {pricingTiers.map((tier, index) => (
        <div key={index}
             className={`relative p-8 rounded-2xl transition-all duration-500
                        ${tier.featured 
                          ? 'bg-gradient-to-b from-haven-navy-900 to-haven-navy-950 text-white ring-2 ring-sage-400 shadow-elegant-xl' 
                          : 'bg-white border border-warm-100 hover:border-sage-200 shadow-elegant card-hover'}`}>
          
          {/* Featured badge */}
          {tier.featured && (
            <div className="absolute -top-4 left-1/2 -translate-x-1/2">
              <div className="px-4 py-1.5 bg-sage-400 text-haven-navy-900 
                              text-xs font-bold rounded-full shadow-lg">
                Start Here
              </div>
            </div>
          )}

          <div className="mb-6">
            <h3 className={`text-xl font-bold ${tier.featured ? 'text-white' : 'text-haven-navy-900'}`}>
              {tier.name}
            </h3>
            <p className={`text-sm mt-1 ${tier.featured ? 'text-sage-300' : 'text-sage-600'}`}>
              {tier.tagline}
            </p>
          </div>

          <div className="flex items-baseline gap-1 mb-8">
            <span className={`text-4xl font-bold ${tier.featured ? 'text-white' : 'text-haven-navy-900'}`}>
              ${tier.price}
            </span>
            <span className={`text-base ${tier.featured ? 'text-white/60' : 'text-warm-500'}`}>
              /month
            </span>
          </div>

          <ul className="space-y-3 mb-8">
            {tier.features.map((feature, i) => (
              <li key={i} className="flex items-start gap-3">
                <Check className={`w-5 h-5 mt-0.5 flex-shrink-0 
                                  ${tier.featured ? 'text-sage-300' : 'text-sage-500'}`} />
                <span className={`text-sm ${tier.featured ? 'text-white/80' : 'text-warm-700'}`}>
                  {feature}
                </span>
              </li>
            ))}
          </ul>

          <Link
            href="/onboarding/welcome"
            className={`block w-full py-3.5 rounded-xl font-semibold text-center 
                       transition-all duration-300
                       ${tier.featured 
                         ? 'bg-white text-haven-navy-900 hover:bg-sage-50 shadow-lg hover:shadow-xl' 
                         : 'bg-haven-navy-900 text-white hover:bg-haven-navy-800 shadow-button hover:shadow-button-hover'}`}>
            {tier.cta}
          </Link>
        </div>
      ))}
    </div>

    {/* Premium tiers toggle */}
    <div className="text-center mt-8">
      <button
        onClick={() => setShowPremiumTiers(!showPremiumTiers)}
        className="inline-flex items-center gap-2 text-haven-navy-600 
                   hover:text-haven-navy-900 font-medium transition-colors">
        {showPremiumTiers ? 'Hide' : 'Show'} premium tiers
        <ChevronDown className={`w-4 h-4 transition-transform duration-300 
                                ${showPremiumTiers ? 'rotate-180' : ''}`} />
      </button>
    </div>
  </div>
</section>
```

### 4.8 Testimonials with Premium Styling

```tsx
<section className="py-24 sm:py-32 bg-gradient-to-b from-warm-50/50 to-white">
  <div className="max-w-6xl mx-auto px-4 sm:px-6">
    <div className="text-center mb-16">
      <h2 className="text-3xl sm:text-4xl lg:text-5xl font-bold text-haven-navy-900 
                     tracking-tight font-serif">
        Real Homeowners. Real Results.
      </h2>
    </div>

    <div className="grid md:grid-cols-3 gap-6 lg:gap-8">
      {testimonials.map((testimonial, index) => (
        <div key={index} 
             className="group relative bg-white rounded-2xl p-8 
                        shadow-elegant hover:shadow-elegant-lg
                        border border-warm-100 hover:border-sage-200
                        transition-all duration-500 card-hover">
          {/* Quote icon */}
          <div className="absolute -top-3 -left-3 w-8 h-8 bg-sage-100 rounded-lg
                          flex items-center justify-center rotate-12
                          group-hover:rotate-0 transition-transform duration-300">
            <Quote className="w-4 h-4 text-sage-600" />
          </div>
          
          {/* Stars */}
          <div className="flex gap-1 mb-4">
            {[...Array(5)].map((_, i) => (
              <Star key={i} className="w-4 h-4 text-sage-400 fill-current" />
            ))}
          </div>
          
          <p className="text-warm-700 leading-relaxed mb-6 italic">
            "{testimonial.quote}"
          </p>
          
          <div className="flex items-center gap-3 pt-4 border-t border-warm-100">
            <div className="w-10 h-10 rounded-full bg-haven-navy-100 
                            flex items-center justify-center">
              <span className="text-sm font-bold text-haven-navy-700">
                {testimonial.initials}
              </span>
            </div>
            <div>
              <div className="font-medium text-haven-navy-900">{testimonial.name}</div>
              <div className="text-sm text-warm-500">{testimonial.role}</div>
            </div>
          </div>
        </div>
      ))}
    </div>

    {/* Stats bar */}
    <div className="mt-16 grid grid-cols-2 md:grid-cols-4 gap-6">
      {[
        { value: '$400', label: 'Avg. savings found/year' },
        { value: '500+', label: 'Homes managed' },
        { value: '4.9/5', label: 'Customer rating' },
        { value: '1', label: 'Bill to pay' },
      ].map((stat, i) => (
        <div key={i} className="text-center p-6 bg-white rounded-xl border border-warm-100 shadow-sm">
          <div className="text-3xl sm:text-4xl font-bold text-haven-navy-900">{stat.value}</div>
          <div className="text-sm text-warm-500 mt-1">{stat.label}</div>
        </div>
      ))}
    </div>
  </div>
</section>
```

### 4.9 FAQ Section Refinement

```tsx
<section className="py-24 sm:py-32 bg-white">
  <div className="max-w-3xl mx-auto px-4 sm:px-6">
    <div className="text-center mb-16">
      <h2 className="text-3xl sm:text-4xl lg:text-5xl font-bold text-haven-navy-900 
                     tracking-tight font-serif">
        Questions? We've Got Answers.
      </h2>
    </div>

    <div className="space-y-4">
      {faqs.map((faq, index) => (
        <div key={index}
             className={`rounded-2xl border transition-all duration-300
                        ${openFaq === index 
                          ? 'bg-warm-50 border-sage-200 shadow-elegant' 
                          : 'bg-white border-warm-100 hover:border-warm-200'}`}>
          <button
            onClick={() => setOpenFaq(openFaq === index ? null : index)}
            className="w-full flex items-center justify-between p-6 text-left">
            <span className={`font-semibold pr-4 transition-colors
                             ${openFaq === index ? 'text-haven-navy-900' : 'text-haven-navy-800'}`}>
              {faq.question}
            </span>
            <div className={`w-8 h-8 rounded-full flex items-center justify-center 
                            flex-shrink-0 transition-all duration-300
                            ${openFaq === index 
                              ? 'bg-sage-500 text-white rotate-180' 
                              : 'bg-warm-100 text-warm-600'}`}>
              <ChevronDown className="w-5 h-5" />
            </div>
          </button>
          
          <div className={`overflow-hidden transition-all duration-300 ease-out
                          ${openFaq === index ? 'max-h-96 pb-6' : 'max-h-0'}`}>
            <p className="px-6 text-warm-600 leading-relaxed">
              {faq.answer}
            </p>
          </div>
        </div>
      ))}
    </div>
  </div>
</section>
```

### 4.10 Final CTA Section

```tsx
<section className="py-24 sm:py-32 bg-gradient-to-br from-haven-navy-900 via-haven-navy-950 to-[#050a14]">
  <div className="max-w-4xl mx-auto px-4 sm:px-6 text-center">
    {/* Decorative elements */}
    <div className="absolute left-1/2 -translate-x-1/2 -top-32 w-[600px] h-[600px] 
                    bg-gradient-radial from-sage-400/10 to-transparent opacity-50 blur-3xl" />
    
    <h2 className="relative text-3xl sm:text-4xl lg:text-5xl font-bold text-white 
                   tracking-tight font-serif">
      Ready to take control of your home?
    </h2>
    
    <p className="mt-6 text-lg sm:text-xl text-white/70 max-w-2xl mx-auto">
      One bill. One app. A handyman who knows your home. 
      Join 500+ families who stopped managing and started living.
    </p>
    
    <div className="mt-10 flex flex-col sm:flex-row items-center justify-center gap-4">
      <Link
        href="/onboarding/welcome"
        className="group relative w-full sm:w-auto px-8 py-4 bg-white text-haven-navy-900 
                   font-semibold rounded-xl overflow-hidden transition-all duration-300
                   hover:shadow-[0_8px_32px_rgba(255,255,255,0.3)] hover:-translate-y-0.5">
        <span className="absolute inset-0 -translate-x-full group-hover:translate-x-full 
                         transition-transform duration-700 bg-gradient-to-r 
                         from-transparent via-sage-200/50 to-transparent" />
        <span className="relative flex items-center justify-center gap-2">
          Get Started with Alfred — $39/mo
          <ArrowRight className="w-5 h-5 transition-transform group-hover:translate-x-1" />
        </span>
      </Link>
    </div>
    
    <p className="mt-6 text-sm text-white/50">
      No contracts. Cancel anytime.
    </p>
  </div>
</section>
```

---

## PHASE 5: Mobile-First Refinements

### 5.1 Touch-Friendly Targets

Ensure all interactive elements have minimum 44x44px touch targets:

```css
/* Add to globals.css */
@media (max-width: 640px) {
  .touch-target {
    min-height: 44px;
    min-width: 44px;
  }
  
  /* Increase padding on mobile buttons */
  .btn-mobile {
    padding: 14px 24px;
  }
  
  /* Better tap feedback */
  .tap-highlight {
    -webkit-tap-highlight-color: rgba(164, 180, 148, 0.2);
  }
}
```

### 5.2 Mobile Hero Optimization

- Full viewport height with safe area insets
- Thumb-friendly CTA placement
- Simplified visual hierarchy
- Faster animation timing on mobile

### 5.3 Card Stacking & Scrolling

```css
/* Horizontal scroll containers for mobile */
@media (max-width: 768px) {
  .scroll-container {
    display: flex;
    overflow-x: auto;
    scroll-snap-type: x mandatory;
    -webkit-overflow-scrolling: touch;
    padding-bottom: 16px;
    margin: 0 -16px;
    padding: 0 16px;
  }
  
  .scroll-container > * {
    scroll-snap-align: start;
    flex-shrink: 0;
    width: 85%;
    margin-right: 12px;
  }
  
  .scroll-container::-webkit-scrollbar {
    display: none;
  }
}
```

---

## PHASE 6: Performance & Polish

### 6.1 Image Optimization

- Use Next.js Image component with priority for hero
- Add blur placeholders for all images
- Lazy load below-the-fold images

### 6.2 Animation Performance

```css
/* Use transform and opacity for animations (GPU accelerated) */
.animate-gpu {
  will-change: transform, opacity;
  transform: translateZ(0);
}

/* Reduce motion for accessibility */
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
  }
}
```

### 6.3 Add Scroll-Triggered Animations

Create a hook for intersection observer animations:

```tsx
// hooks/useScrollAnimation.ts
import { useEffect, useRef, useState } from 'react';

export function useScrollAnimation(threshold = 0.1) {
  const ref = useRef<HTMLDivElement>(null);
  const [isVisible, setIsVisible] = useState(false);

  useEffect(() => {
    const observer = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting) {
          setIsVisible(true);
          observer.disconnect();
        }
      },
      { threshold }
    );

    if (ref.current) {
      observer.observe(ref.current);
    }

    return () => observer.disconnect();
  }, [threshold]);

  return { ref, isVisible };
}
```

---

## PHASE 7: Final Checklist

After implementing all changes:

1. **Visual QA**
   - [ ] Hero looks stunning on desktop (1440px+)
   - [ ] Hero looks stunning on mobile (375px)
   - [ ] All cards have consistent styling
   - [ ] Color contrast passes WCAG AA
   - [ ] No layout shifts on load

2. **Interaction QA**
   - [ ] All hover states feel premium
   - [ ] Animations are smooth (60fps)
   - [ ] Touch targets are adequate
   - [ ] FAQ accordion is silky smooth

3. **Performance QA**
   - [ ] LCP under 2.5s
   - [ ] No jank on scroll
   - [ ] Images lazy load properly

4. **Cross-Browser**
   - [ ] Chrome ✓
   - [ ] Safari ✓
   - [ ] Firefox ✓
   - [ ] Mobile Safari ✓
   - [ ] Chrome Android ✓

---

## Assets Needed

1. **Noise texture** - Create `/public/noise.png` (subtle noise overlay)
2. **Alfred icon** - Ensure `/public/alfred-icon.svg` looks crisp
3. **Open Graph image** - Update for new visual style

---

## Key Design Principles to Follow

1. **Restraint over excess** - Every element should earn its place
2. **Subtle depth** - Use shadows and layers thoughtfully
3. **Premium whitespace** - Let elements breathe
4. **Consistent rhythm** - Spacing should follow a scale (8, 16, 24, 32, 48, 64, 96)
5. **Motion with purpose** - Animations guide attention, not distract
6. **Hierarchy through contrast** - Make important things pop, secondary things recede
7. **Mobile-native feel** - Not just responsive, but designed for touch

---

*This prompt maintains every word of content while transforming the visual presentation from good to exceptional. The result should feel like a premium fintech or luxury hospitality brand - sophisticated, trustworthy, and memorable.*

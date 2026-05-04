/* Phase 84.5 — Field-app shared module for the assessment branch.
 *
 * Defines:
 *   • The 11 walking-order zones (G22)
 *   • The 15+ trade chips for vendor capture (G8 — mirrors Q15b)
 *   • Default recommendation urgency tiers + display copy (G25)
 *   • Helpers for adding / updating recommendations (G18, G19, G45, G46, G48)
 *
 * Loaded only when handyman-visit.html detects
 * `visit_type ∈ ('home_assessment', 'home_assessment_continuation')`.
 */
(function (global) {
  'use strict';

  // ============================================================
  // Walking zones (G22)
  // ============================================================
  // Physical-order navigation. Field app moves through these in order;
  // each zone filters the systems checklist to what's typically captured
  // in that physical area.
  global.ASSESSMENT_ZONES = [
    {
      id: 'arrival',
      label: 'Arrival',
      icon: '👋',
      timeMinutes: 5,
      systemCategories: [],
      isBookend: true,
      hint: 'Greet, share verification code, confirm scope, capture homeowner concerns.',
    },
    {
      id: 'exterior_approach',
      label: 'Exterior approach',
      icon: '🚪',
      timeMinutes: 5,
      systemCategories: ['Driveway', 'Walkway', 'Mailbox', 'Exterior Lighting', 'Doorbell'],
      hint: 'Driveway material, walkway condition, mailbox, doorbell/intercom.',
    },
    {
      id: 'roof_gutters',
      label: 'Roof + gutters',
      icon: '🏠',
      timeMinutes: 10,
      systemCategories: ['Roofing', 'Gutters', 'Chimney'],
      hint: 'Visual from ground. Roof material, age, gutter condition, downspouts.',
    },
    {
      id: 'yard_landscaping',
      label: 'Yard / landscaping',
      icon: '🌳',
      timeMinutes: 10,
      systemCategories: [
        'Landscaping', 'Irrigation', 'Pool/Spa', 'Hot Tub',
        'Tree Service', 'Pest Control', 'Snow Removal',
      ],
      hint: 'Front, back, sides. Hardscape, irrigation, pool/hot tub, garden, trees, fences.',
    },
    {
      id: 'garage',
      label: 'Garage',
      icon: '🚗',
      timeMinutes: 5,
      systemCategories: ['Garage Door', 'EV Charger', 'Vehicles'],
      hint: 'Vehicles (VIN photo), EV charger if any, garage door + opener.',
    },
    {
      id: 'mechanical',
      label: 'Mechanical / basement',
      icon: '🔧',
      timeMinutes: 15,
      systemCategories: [
        'HVAC', 'Water Heater', 'Electrical', 'Well System',
        'Septic System', 'Plumbing', 'Sump Pump', 'Generator',
      ],
      hint: 'Boiler/furnace, water heater, electrical panel, well, softener, sump.',
    },
    {
      id: 'kitchen',
      label: 'Kitchen',
      icon: '🍳',
      timeMinutes: 5,
      systemCategories: ['Appliance'],
      hint: 'Refrigerator, range, dishwasher, microwave, garbage disposal, sink.',
    },
    {
      id: 'laundry',
      label: 'Laundry',
      icon: '🧺',
      timeMinutes: 3,
      systemCategories: ['Appliance', 'Dryer Vent'],
      hint: 'Washer, dryer, dryer vent, utility sink.',
    },
    {
      id: 'bathrooms',
      label: 'Bathrooms',
      icon: '🚿',
      timeMinutes: 5,
      systemCategories: ['Plumbing', 'Bathroom Ventilation'],
      hint: 'Fixtures, ventilation, water pressure, drain function.',
    },
    {
      id: 'living_spaces',
      label: 'Living spaces',
      icon: '🛋️',
      timeMinutes: 5,
      systemCategories: [
        'Fireplace', 'HVAC', 'Smoke Detector', 'CO Detector', 'Ceiling Fans',
      ],
      hint: 'Fireplaces, HVAC vents, smoke/CO detectors, ceiling fans.',
    },
    {
      id: 'attic',
      label: 'Attic',
      icon: '🏚️',
      timeMinutes: 5,
      systemCategories: ['Insulation', 'Ventilation'],
      hint: 'Insulation, ventilation, leak signs, vermiculite hazard check.',
    },
    {
      id: 'wrapup',
      label: 'Wrap-up',
      icon: '✅',
      timeMinutes: 10,
      systemCategories: [],
      isBookend: true,
      hint: 'Review summary with homeowner. Capture per-recommendation responses.',
    },
  ];

  // ============================================================
  // Q15b trade chips (G8) — mirrors HouseQuizAnswerMapper
  // ============================================================
  global.ASSESSMENT_TRADE_CHIPS = [
    { id: 'handyman', label: 'Handyman', category: 'Handyman' },
    { id: 'hvac_service', label: 'HVAC service', category: 'HVAC' },
    { id: 'plumber', label: 'Plumber', category: 'Plumbing' },
    { id: 'electrician', label: 'Electrician', category: 'Electrical' },
    { id: 'roofer', label: 'Roofer', category: 'Roofing' },
    { id: 'tree_service', label: 'Tree service', category: 'Tree Service' },
    { id: 'pest_control', label: 'Pest control', category: 'Pest Control' },
    { id: 'snow_removal', label: 'Snow plow', category: 'Snow Removal' },
    { id: 'septic_pumper', label: 'Septic pumper', category: 'Septic System', stateGated: true },
    { id: 'well_water_service', label: 'Well service', category: 'Well System' },
    { id: 'chimney_sweep', label: 'Chimney sweep', category: 'Chimney' },
    { id: 'hardscape', label: 'Hardscape / masonry', category: 'Landscaping' },
    { id: 'generator_service', label: 'Generator service', category: 'Generator' },
    { id: 'pool_service', label: 'Pool service', category: 'Pool/Spa' },
    { id: 'solar_service', label: 'Solar service', category: 'Solar' },
    { id: 'security_service', label: 'Security monitoring', category: 'Security System' },
    { id: 'cleaning', label: 'House cleaning', category: 'Cleaning Service' },
    { id: 'mosquito_tick', label: 'Mosquito & tick', category: 'Mosquito & Tick' },
    { id: 'pet_waste', label: 'Pet waste', category: 'Pet Waste' },
    { id: 'waterproofing', label: 'Waterproofing', category: 'Crawl Space' },
  ];

  // ============================================================
  // Urgency tiers (G25)
  // ============================================================
  global.ASSESSMENT_URGENCY_TIERS = [
    {
      id: 'urgent',
      label: 'Urgent',
      caption: 'Safety / code — fires admin push immediately',
      color: '#D32F2F',
    },
    {
      id: 'soon',
      label: 'Soon',
      caption: 'Overdue service — 24h SLA',
      color: '#F57C00',
    },
    {
      id: 'next_season',
      label: 'Next season',
      caption: 'Timing-bound work — routine seeded',
      color: '#ED6955',
    },
    {
      id: 'opportunistic',
      label: 'When ready',
      caption: 'Improvement — backlog, no SLA',
      color: '#787878',
    },
  ];

  // ============================================================
  // Owner tiers (G19)
  // ============================================================
  global.ASSESSMENT_OWNER_TIERS = [
    { id: 'homeowner_diy', label: 'Homeowner DIY' },
    { id: 'chez_handyman', label: 'Chez handyman' },
    { id: 'chez_vendor', label: 'Chez vendor' },
  ];

  // ============================================================
  // Vendor dedup helper (G7) — match by phone or normalized name
  // ============================================================
  function normalizeName(name) {
    return (name || '')
      .toLowerCase()
      .replace(/\b(llc|inc|corp|company|co|the)\b/g, '')
      .replace(/[^a-z0-9]+/g, '')
      .trim();
  }

  function normalizePhone(phone) {
    return (phone || '').replace(/\D/g, '');
  }

  global.assessmentIsLikelySameVendor = function (a, b) {
    const phoneA = normalizePhone(a.phone);
    const phoneB = normalizePhone(b.phone);
    if (phoneA && phoneB && phoneA === phoneB) return true;

    const nameA = normalizeName(a.companyName || a.company_name);
    const nameB = normalizeName(b.companyName || b.company_name);
    if (!nameA || !nameB) return false;
    return nameA === nameB;
  };

  // ============================================================
  // Voice transcription wrapper (G23)
  // ============================================================
  // Wraps the Web Speech API for the notes fields. Falls back gracefully
  // when the browser doesn't support recognition.
  global.assessmentStartVoiceCapture = function (onTranscript, onError) {
    const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;
    if (!SpeechRecognition) {
      onError && onError('Voice not supported in this browser');
      return null;
    }
    const recognition = new SpeechRecognition();
    recognition.continuous = true;
    recognition.interimResults = true;
    recognition.lang = 'en-US';
    recognition.onresult = (event) => {
      let transcript = '';
      for (let i = 0; i < event.results.length; i++) {
        transcript += event.results[i][0].transcript + ' ';
      }
      onTranscript(transcript.trim());
    };
    recognition.onerror = (event) => {
      onError && onError(event.error);
    };
    recognition.start();
    return recognition;
  };
})(window);

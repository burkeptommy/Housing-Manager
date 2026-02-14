# Fix Alfred Messaging, Forecasts Crash, and Create Test Emails

**Created:** February 3, 2026
**Priority:** HIGH - Beta testing blockers

---

## ISSUE 1: Vendor Messaging Navigation Wrong (Alfred Chat is FINE)

**Problem:** When user goes to Alfred tab → Messages → **Message a Vendor**, it navigates to a separate page with wrong header color that doesn't feel integrated within the app.

**IMPORTANT:** The main Alfred chat/messaging feature works perfectly. DO NOT TOUCH IT. This fix is ONLY for the "message a vendor" flow.

**Expected:** When user wants to message a vendor from within Alfred, it should:
- Stay within the Alfred tab structure
- Maintain consistent header styling (Navy #0a1929 or proper sage accents)
- Feel like part of the Alfred experience, not a completely different page

**Fix:**
1. Find where "Message a Vendor" navigates to
2. It's likely navigating to a top-level `/messages` route instead of staying in Alfred
3. Either:
   - Create a vendor messaging screen under Alfred tab (`alfred/vendor-message/[id].tsx`)
   - Or fix the existing screen to use proper Haven styling with `ScreenContainer`
4. Header should match the rest of the app - consistent colors

**Files to check:**
- Look for vendor message button/link in Alfred tab and trace where it navigates
- `apps/mobile/app/(tabs)/messages/` - this might be the wrong destination
- The destination screen needs Haven styling (ScreenContainer, correct colors)

**DO NOT MODIFY:**
- Alfred chat functionality
- Alfred cases
- Any existing Alfred screens that work correctly

---

## ISSUE 2: Forecasts Crash - No Bank Connected

**Problem:** Clicking "Forecasts" crashes the app, likely because there's no bank connected and the code doesn't handle the empty state.

**Expected:** If no bank is connected, show a friendly empty state:
```
┌─────────────────────────────────────┐
│                                     │
│      📊 Home Forecasts              │
│                                     │
│  Connect your bank to unlock        │
│  intelligent home forecasting.      │
│                                     │
│  We'll analyze your spending to     │
│  predict maintenance costs and      │
│  system replacements.               │
│                                     │
│  [Connect Your Bank]                │
│                                     │
└─────────────────────────────────────┘
```

**Fix:**
1. Add try/catch around data fetching
2. Check for bank connection status FIRST
3. If no bank/no data, show empty state with Plaid connect button
4. The Plaid connect should use the existing Plaid Link flow

**Files to check:**
- `apps/mobile/app/(tabs)/money/forecast.tsx` or similar
- Check what API endpoint it calls and add null checks
- Wrap in error boundary if needed

**Empty State Pattern:**
```tsx
if (!hasBankConnected) {
  return (
    <ScreenContainer title="Forecasts">
      <View style={styles.emptyContainer}>
        <Ionicons name="analytics-outline" size={64} color={colors.haven.navy[300]} />
        <Text style={styles.emptyTitle}>Home Forecasts</Text>
        <Text style={styles.emptyText}>
          Connect your bank to unlock intelligent home forecasting.
        </Text>
        <TouchableOpacity 
          style={styles.connectButton}
          onPress={() => router.push('/(tabs)/money/connect')}
        >
          <Text style={styles.connectButtonText}>Connect Your Bank</Text>
        </TouchableOpacity>
      </View>
    </ScreenContainer>
  );
}
```

---

## ISSUE 3: Create Test Emails for Alfred

**Goal:** Create a script/endpoint to simulate emails being sent to Alfred so we can test the full flow without actually sending emails.

**Test User:** tom@example.com  
**Alfred Email:** 146Putnamparkrd@alfred.havenhome.dev

### Create Test Endpoint

**File:** `apps/api/src/alfred-email/alfred-email.controller.ts`

Add a test endpoint (dev/staging only):

```typescript
/**
 * DEV ONLY: Simulate an inbound email for testing
 */
@Post('test/simulate-email')
@UseGuards(JwtAuthGuard)
async simulateEmail(
  @CurrentUser() user: User,
  @Body() body: {
    scenario: 'camp_registration' | 'utility_bill' | 'vendor_quote' | 'appointment' | 'school_event' | 'home_inspection';
  },
) {
  if (process.env.NODE_ENV === 'production') {
    throw new ForbiddenException('Test endpoint not available in production');
  }
  
  return this.alfredEmailService.simulateTestEmail(user, body.scenario);
}
```

**File:** `apps/api/src/alfred-email/alfred-email.service.ts`

```typescript
async simulateTestEmail(user: User, scenario: string) {
  const household = await this.getHousehold(user);
  
  const testEmails: Record<string, any> = {
    camp_registration: {
      from: 'info@campwonderland.com',
      subject: 'Registration Confirmed - Summer Camp 2026',
      text: `Dear Morrison Family,

Thank you for registering Emma for Camp Wonderland!

Session Details:
- Dates: June 15-19, 2026
- Time: 9:00 AM - 3:00 PM daily
- Location: 45 Camp Road, Greenwich, CT

Registration Fee: $450 (due by March 1, 2026)

What to bring:
- Sunscreen
- Water bottle
- Lunch and snacks

We're excited to have Emma join us!

Best,
Camp Wonderland Team
(203) 555-0300`,
    },
    
    utility_bill: {
      from: 'noreply@eversource.com',
      subject: 'Your Eversource Bill is Ready',
      text: `Your monthly electric bill is now available.

Account: Morrison, Robert
Service Address: 146 Putnam Park Rd, Greenwich, CT

Amount Due: $287.43
Due Date: February 20, 2026

This is higher than your average bill of $215.00.

View and pay at eversource.com or call 800-286-2000.

Thank you for being an Eversource customer.`,
    },
    
    vendor_quote: {
      from: 'mike@acegutters.com',
      subject: 'Quote for Gutter Cleaning - 146 Putnam Park Rd',
      text: `Hi Bob,

Thanks for reaching out about gutter cleaning. Here's your quote:

Service: Full gutter cleaning and inspection
Property: 146 Putnam Park Rd, Greenwich, CT
Price: $275.00

Includes:
- Clean all gutters and downspouts
- Flush downspouts
- Minor repairs (up to 10 ft of resealing)
- Inspection report

We can schedule anytime in the next 2 weeks. Quote valid through March 1, 2026.

Let me know if you'd like to proceed!

Mike Rodriguez
Ace Gutters LLC
(203) 555-0199
mike@acegutters.com`,
    },
    
    appointment: {
      from: 'appointments@greenwichdental.com',
      subject: 'Appointment Reminder - Jack Morrison',
      text: `This is a reminder of your upcoming appointment:

Patient: Jack Morrison
Date: February 10, 2026
Time: 2:30 PM
Provider: Dr. Sarah Williams
Type: 6-Month Cleaning

Location:
Greenwich Dental Care
123 Main Street, Suite 200
Greenwich, CT 06830

Please arrive 10 minutes early. Call (203) 555-0400 to reschedule.`,
    },
    
    school_event: {
      from: 'events@gcds.net',
      subject: 'Save the Date: Spring Concert - March 15',
      text: `Dear GCDS Families,

Please save the date for our annual Spring Concert!

Event: Spring Concert 2026
Date: Saturday, March 15, 2026
Time: 7:00 PM
Location: Performing Arts Center

Emma Morrison will be performing with the 7th Grade Chorus.

Tickets: $15 adults, free for students
RSVP by March 10 at gcds.net/springconcert

We hope to see you there!

Greenwich Country Day School
Music Department`,
    },
    
    home_inspection: {
      from: 'reports@homeinspectpro.com',
      subject: 'Inspection Report Ready - 146 Putnam Park Rd',
      text: `Your home inspection report is ready.

Property: 146 Putnam Park Rd, Greenwich, CT 06830
Inspection Date: January 28, 2026
Inspector: James Chen, License #HI-2845

Summary Findings:
- HVAC: Furnace is 18 years old, recommend service
- Roof: Good condition, 8 years remaining life
- Water Heater: 12 years old, near end of life (recommend budgeting for replacement)
- Foundation: No issues
- Electrical: Panel updated, good condition

Full report attached (simulated).

Please call with any questions: (203) 555-0888

HomeInspect Pro
Licensed & Insured`,
    },
  };

  const emailData = testEmails[scenario];
  if (!emailData) {
    throw new BadRequestException(`Unknown scenario: ${scenario}`);
  }

  // Process as if it came from SendGrid webhook
  return this.processInboundEmail({
    from: emailData.from,
    to: `${household.alfredEmailCode}@alfred.havenhome.dev`,
    subject: emailData.subject,
    text: emailData.text,
    html: null,
    attachments: [],
    messageId: `test_${Date.now()}`,
  });
}
```

### Mobile Test UI

Add a debug section in Alfred settings (dev only) to trigger test emails:

**File:** `apps/mobile/app/(tabs)/alfred/settings.tsx` or similar

```tsx
{__DEV__ && (
  <View style={styles.debugSection}>
    <Text style={styles.debugTitle}>🧪 Test Scenarios</Text>
    
    {['camp_registration', 'utility_bill', 'vendor_quote', 'appointment', 'school_event', 'home_inspection'].map((scenario) => (
      <TouchableOpacity
        key={scenario}
        style={styles.debugButton}
        onPress={() => simulateEmail(scenario)}
      >
        <Text style={styles.debugButtonText}>
          {scenario.replace('_', ' ').toUpperCase()}
        </Text>
      </TouchableOpacity>
    ))}
  </View>
)}
```

---

## ISSUE 4: Verify Calendar Integration

**Goal:** When user selects "Add to Calendar" action from Alfred, it should create an actual Google Calendar event.

**Verify:**
1. The calendar action execution calls the Google Calendar API
2. OAuth tokens are properly refreshed if expired
3. Event is created in user's primary calendar
4. User receives confirmation

**File to check:** `apps/api/src/alfred-email/alfred-email.service.ts`

In `executeCalendarAction`:
```typescript
private async executeCalendarAction(householdId: string, data: any) {
  // Should call Google Calendar API
  const calendarService = this.moduleRef.get(CalendarService);
  
  const event = await calendarService.createEvent(householdId, {
    title: data.title,
    startDate: data.startDate,
    endDate: data.endDate,
    location: data.location,
    description: data.description,
  });
  
  return event;
}
```

Make sure this actually uses the Google Calendar integration, not just saving to database.

---

## DEPLOYMENT

After fixes:

```bash
# Deploy API
cd apps/api
gcloud builds submit --config=cloudbuild-api.yaml --project=home-manager-480616

# Build mobile
cd apps/mobile  
eas build --platform ios --profile production --auto-submit
```

---

## TEST CHECKLIST

- [ ] Alfred → Messages → Vendor stays in Alfred tab with correct styling
- [ ] Forecasts shows "Connect Bank" empty state when no bank connected
- [ ] Test email endpoint works at POST /alfred/test/simulate-email
- [ ] Camp registration test creates case with calendar action
- [ ] Selecting "Add to Calendar" actually creates Google Calendar event
- [ ] Bill test creates case with bill tracking action
- [ ] Vendor quote test creates case with vendor save action

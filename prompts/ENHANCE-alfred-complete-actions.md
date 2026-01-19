# Alfred Email - Complete Action Handler Enhancement

## OVERVIEW

The current Alfred implementation handles only 5 email categories. This prompt expands it to handle **EVERY possible email type** a homeowner might forward.

**Principle:** There is ALWAYS a reason someone forwards an email to Alfred. We must ALWAYS take action.

---

## COMPLETE ACTION TAXONOMY

### CATEGORY 1: CALENDAR & SCHEDULING

```typescript
// In EmailActionsService, add these handlers:

interface CalendarAction {
  type: 
    | 'CAMP_REGISTRATION'      // Summer camp, sports camp, day camp
    | 'SCHOOL_EVENT'           // Parent-teacher, performances, field trips
    | 'APPOINTMENT'            // Doctor, dentist, vet, lawyer, accountant
    | 'SERVICE_WINDOW'         // Delivery, installation, repair visit
    | 'TRAVEL_ITINERARY'       // Flights, hotels, car rentals, activities
    | 'RECURRING_EVENT'        // Weekly lessons, monthly meetings
    | 'DEADLINE'               // Applications, renewals, registrations
    | 'PARTY_INVITATION'       // Kids birthday, neighborhood events
    | 'SPORTS_SCHEDULE'        // Game times, practice schedules
    | 'LESSON_SCHEDULE'        // Piano, tutoring, swimming
    | 'RESERVATION'            // Restaurant, tickets, tours
    | 'MEETING'                // HOA, school board, community
}

async handleCalendarEvent(case: EmailCase, event: CalendarAction) {
  // Create calendar event
  const calendarEvent = await this.prisma.calendarEvent.create({
    data: {
      householdId: case.householdId,
      title: event.title,
      startDate: event.startDate,
      endDate: event.endDate,
      location: event.location,
      description: event.description,
      allDay: event.allDay,
      recurrence: event.recurrence,
      reminders: event.reminders || ['1d', '1h'], // Default reminders
      sourceEmailCaseId: case.id,
      // Link to family member if identified
      familyMemberId: event.familyMemberId,
    }
  });
  
  await this.logActivity(case.id, 'CALENDAR_EVENT_CREATED', {
    eventType: event.type,
    title: event.title,
    date: event.startDate,
  });
  
  // If we couldn't determine which family member, ask
  if (event.needsFamilyMemberClarification) {
    await this.askQuestion(case, 
      `I found an event "${event.title}" on ${formatDate(event.startDate)}. Who is this for?`,
      this.getFamilyMemberOptions(case.householdId)
    );
  }
}
```

### CATEGORY 2: FINANCIAL & BILLS

```typescript
interface FinancialAction {
  type:
    | 'INVOICE'                // New bill to pay
    | 'PAYMENT_CONFIRMATION'   // Receipt, payment processed
    | 'PAYMENT_REMINDER'       // Due date reminder
    | 'SUBSCRIPTION_NOTICE'    // Renewal, price change, cancellation
    | 'FEE_INCREASE'           // Rate increase notification
    | 'REFUND_NOTICE'          // Refund processed
    | 'TAX_DOCUMENT'           // W2, 1099, property tax
    | 'INSURANCE_RENEWAL'      // Policy renewal, premium change
    | 'INSURANCE_CLAIM'        // Claim status, payout
    | 'BANK_STATEMENT'         // Monthly statement
    | 'CREDIT_CARD_STATEMENT'  // Monthly statement
    | 'LOAN_STATEMENT'         // Mortgage, HELOC, auto
    | 'TUITION_BILL'           // School, camp, lessons
    | 'MEDICAL_BILL'           // Doctor, hospital, pharmacy
    | 'UTILITY_BILL'           // Electric, gas, water, internet
    | 'MEMBERSHIP_DUES'        // Club, gym, association
    | 'DONATION_RECEIPT'       // Charitable contributions
    | 'ESTIMATE'               // Quote for future work
}

async handleFinancialItem(case: EmailCase, item: FinancialAction) {
  switch (item.type) {
    case 'INVOICE':
    case 'TUITION_BILL':
    case 'MEDICAL_BILL':
    case 'UTILITY_BILL':
    case 'MEMBERSHIP_DUES':
      await this.createBill(case, item);
      break;
      
    case 'PAYMENT_CONFIRMATION':
    case 'REFUND_NOTICE':
      await this.recordPayment(case, item);
      break;
      
    case 'SUBSCRIPTION_NOTICE':
    case 'FEE_INCREASE':
      await this.updateRecurringBill(case, item);
      await this.askQuestion(case,
        `${item.vendor} is changing your rate from $${item.oldAmount} to $${item.newAmount}. Should I update your records?`,
        ['Yes, update it', 'Remind me to cancel', 'I\'ll handle it']
      );
      break;
      
    case 'TAX_DOCUMENT':
    case 'DONATION_RECEIPT':
      await this.saveToDocuments(case, item, 'tax');
      await this.logActivity(case.id, 'DOCUMENT_SAVED', {
        category: 'tax',
        year: item.taxYear,
      });
      break;
      
    case 'INSURANCE_RENEWAL':
      await this.updateInsurancePolicy(case, item);
      await this.createReminder(case, item.renewalDate, 'Insurance renewal due');
      break;
      
    case 'ESTIMATE':
      await this.saveEstimate(case, item);
      await this.askQuestion(case,
        `I received an estimate from ${item.vendor} for $${item.amount}. Would you like me to schedule this work?`,
        ['Yes, schedule it', 'Get more quotes', 'Save for later', 'Decline']
      );
      break;
  }
}
```

### CATEGORY 3: VENDOR & SERVICE PROVIDERS

```typescript
interface VendorAction {
  type:
    | 'NEW_VENDOR_CONTACT'     // Business card, introduction
    | 'SERVICE_QUOTE'          // Quote for work
    | 'SERVICE_AGREEMENT'      // Contract, terms
    | 'SERVICE_CONFIRMATION'   // Appointment confirmed
    | 'SERVICE_COMPLETION'     // Work completed
    | 'WARRANTY_INFO'          // Product/service warranty
    | 'MAINTENANCE_AGREEMENT'  // Annual service contract
    | 'VENDOR_UPDATE'          // New phone, email, address
    | 'RECOMMENDATION'         // Someone recommending a vendor
    | 'REVIEW_REQUEST'         // Asking for review
}

async handleVendorItem(case: EmailCase, item: VendorAction) {
  // Always try to match or create vendor
  let vendor = await this.findOrCreateVendor(case.householdId, {
    name: item.vendorName,
    email: item.vendorEmail,
    phone: item.vendorPhone,
    category: item.category,
    website: item.website,
  });
  
  switch (item.type) {
    case 'SERVICE_QUOTE':
      await this.saveQuote(case, vendor, item);
      await this.logActivity(case.id, 'QUOTE_SAVED', { vendor: vendor.name, amount: item.amount });
      break;
      
    case 'WARRANTY_INFO':
      await this.saveWarranty(case, item);
      if (item.expirationDate) {
        await this.createReminder(case, 
          subMonths(item.expirationDate, 1), 
          `Warranty expiring: ${item.productName}`
        );
      }
      break;
      
    case 'SERVICE_CONFIRMATION':
      await this.createCalendarEvent(case, {
        title: `${vendor.name} - ${item.serviceType}`,
        startDate: item.appointmentDate,
        location: item.location || 'Home',
      });
      break;
      
    case 'MAINTENANCE_AGREEMENT':
      await this.saveDocument(case, item, 'contracts');
      await this.createRecurringReminder(case, item.frequency, `${vendor.name} maintenance due`);
      break;
      
    case 'RECOMMENDATION':
      await this.createVendor(case.householdId, item);
      await this.logActivity(case.id, 'VENDOR_CREATED', { 
        source: 'recommendation',
        recommendedBy: item.recommendedBy 
      });
      break;
  }
}
```

### CATEGORY 4: HOME & PROPERTY

```typescript
interface HomeAction {
  type:
    | 'INSPECTION_REPORT'      // Home inspection, pest, radon
    | 'MAINTENANCE_REMINDER'   // Service due
    | 'HOA_NOTICE'             // Dues, violations, meetings
    | 'UTILITY_NOTICE'         // Service changes, outages
    | 'PERMIT_STATUS'          // Application, approval, inspection
    | 'PROPERTY_TAX'           // Assessment, bill
    | 'APPRAISAL'              // Property valuation
    | 'TITLE_DOCUMENT'         // Deed, title insurance
    | 'SURVEY'                 // Property survey
    | 'ZONING_NOTICE'          // Zoning changes
    | 'CODE_VIOLATION'         // Building code issues
    | 'RENOVATION_UPDATE'      // Contractor progress
    | 'APPLIANCE_REGISTRATION' // Product registration
    | 'RECALL_NOTICE'          // Product recalls
    | 'ENERGY_AUDIT'           // Energy efficiency report
}

async handleHomeItem(case: EmailCase, item: HomeAction) {
  switch (item.type) {
    case 'INSPECTION_REPORT':
      // Extract ALL systems mentioned
      for (const system of item.systems) {
        await this.addOrUpdateSystem(case.householdId, {
          name: system.name,
          category: system.category,
          condition: system.condition,
          notes: system.notes,
          recommendedAction: system.recommendedAction,
          sourceEmailCaseId: case.id,
        });
        await this.logActivity(case.id, 'SYSTEM_ADDED', { system: system.name });
        
        // Create tasks for any recommended actions
        if (system.recommendedAction) {
          await this.createTask(case, {
            title: `${system.name}: ${system.recommendedAction}`,
            priority: system.urgency,
            dueDate: system.recommendedDate,
          });
        }
      }
      break;
      
    case 'HOA_NOTICE':
      if (item.hasDueDate) {
        await this.createBill(case, {
          vendor: 'HOA',
          amount: item.amount,
          dueDate: item.dueDate,
        });
      }
      if (item.hasMeeting) {
        await this.createCalendarEvent(case, {
          title: 'HOA Meeting',
          startDate: item.meetingDate,
          location: item.meetingLocation,
        });
      }
      if (item.hasViolation) {
        await this.createTask(case, {
          title: `HOA Violation: ${item.violationDescription}`,
          priority: 'HIGH',
          dueDate: item.responseDeadline,
        });
        await this.askQuestion(case,
          `You received an HOA violation notice about "${item.violationDescription}". Would you like me to draft a response?`,
          ['Yes, draft response', 'Create task to fix', 'I\'ll handle it']
        );
      }
      break;
      
    case 'RECALL_NOTICE':
      await this.createTask(case, {
        title: `URGENT: Product recall - ${item.productName}`,
        priority: 'URGENT',
        description: item.recallDetails,
      });
      await this.logActivity(case.id, 'RECALL_LOGGED', { product: item.productName });
      break;
      
    case 'PERMIT_STATUS':
      await this.updateProject(case, item.projectId, {
        permitStatus: item.status,
        permitNumber: item.permitNumber,
      });
      if (item.status === 'APPROVED') {
        await this.askQuestion(case,
          `Your permit for ${item.projectName} was approved! Ready to schedule the work?`,
          ['Yes, contact contractor', 'Schedule for later', 'Just save this']
        );
      }
      break;
  }
}
```

### CATEGORY 5: FAMILY & HOUSEHOLD

```typescript
interface FamilyAction {
  type:
    | 'MEDICAL_RECORD'         // Test results, prescriptions, records
    | 'SCHOOL_REPORT'          // Report card, progress report
    | 'SCHOOL_NOTICE'          // Announcements, closures
    | 'ACTIVITY_REGISTRATION'  // Sports, arts, clubs
    | 'PET_RECORD'             // Vet visits, vaccinations
    | 'PRESCRIPTION_NOTICE'    // Refill reminders, ready for pickup
    | 'IMMUNIZATION_RECORD'    // Vaccination records
    | 'DENTAL_RECORD'          // Cleanings, x-rays
    | 'VISION_RECORD'          // Eye exams, prescriptions
    | 'THERAPY_RECORD'         // PT, OT, counseling
    | 'ALLERGY_INFO'           // Allergy test results
    | 'EMERGENCY_CONTACT'      // Updated contact info
    | 'CHILDCARE_INVOICE'      // Nanny, daycare, babysitter
    | 'ELDERCARE_UPDATE'       // For those caring for parents
}

async handleFamilyItem(case: EmailCase, item: FamilyAction) {
  // Try to identify which family member this is for
  const familyMember = await this.identifyFamilyMember(case.householdId, item);
  
  switch (item.type) {
    case 'MEDICAL_RECORD':
    case 'DENTAL_RECORD':
    case 'VISION_RECORD':
    case 'IMMUNIZATION_RECORD':
    case 'ALLERGY_INFO':
      await this.saveToFamilyMember(familyMember, 'medical', item);
      await this.logActivity(case.id, 'MEDICAL_RECORD_SAVED', { 
        member: familyMember?.name,
        type: item.type 
      });
      break;
      
    case 'PRESCRIPTION_NOTICE':
      if (item.readyForPickup) {
        await this.createTask(case, {
          title: `Pick up prescription: ${item.medicationName}`,
          priority: 'HIGH',
          location: item.pharmacyName,
        });
      }
      if (item.refillReminder) {
        await this.createReminder(case, item.refillDate, 
          `Refill ${item.medicationName} for ${familyMember?.name}`
        );
      }
      break;
      
    case 'SCHOOL_REPORT':
      await this.saveToFamilyMember(familyMember, 'school', item);
      // Notify parents
      await this.notifyHousehold(case.householdId, 
        `${familyMember?.name}'s ${item.reportType} is ready to review`
      );
      break;
      
    case 'ACTIVITY_REGISTRATION':
      await this.createBill(case, {
        description: `${item.activityName} - ${familyMember?.name}`,
        amount: item.cost,
        dueDate: item.paymentDueDate,
      });
      // Add activity schedule to calendar
      for (const session of item.schedule) {
        await this.createCalendarEvent(case, {
          title: `${familyMember?.name} - ${item.activityName}`,
          startDate: session.date,
          recurrence: session.recurrence,
          location: item.location,
        });
      }
      break;
      
    case 'PET_RECORD':
      const pet = await this.identifyPet(case.householdId, item);
      await this.updatePetRecord(pet, item);
      if (item.nextAppointmentDue) {
        await this.createReminder(case, item.nextAppointmentDue,
          `${pet?.name} - ${item.appointmentType} due`
        );
      }
      break;
  }
  
  // If we couldn't identify the family member, ask
  if (!familyMember && item.requiresFamilyMember) {
    await this.askQuestion(case,
      `I received a ${item.type.toLowerCase().replace('_', ' ')}. Which family member is this for?`,
      await this.getFamilyMemberOptions(case.householdId)
    );
  }
}
```

### CATEGORY 6: DISPUTES & CORRESPONDENCE

```typescript
interface DisputeAction {
  type:
    | 'BILLING_DISPUTE'        // Incorrect charge
    | 'SERVICE_COMPLAINT'      // Poor service
    | 'WARRANTY_CLAIM'         // Product defect
    | 'INSURANCE_CLAIM'        // Damage, loss
    | 'REFUND_REQUEST'         // Requesting money back
    | 'CANCELLATION_REQUEST'   // Cancel service
    | 'PRICE_NEGOTIATION'      // Negotiate better rate
    | 'LATE_FEE_WAIVER'        // Request fee removal
    | 'CONTRACT_DISPUTE'       // Terms disagreement
    | 'NEIGHBOR_DISPUTE'       // Property line, noise, etc.
}

async handleDisputeItem(case: EmailCase, item: DisputeAction) {
  // All disputes require user approval before sending
  const draftResponse = await this.generateDisputeResponse(item);
  
  await this.prisma.emailCase.update({
    where: { id: case.id },
    data: {
      status: 'AWAITING_INPUT',
      pendingQuestion: `I've drafted a response for your ${item.type.toLowerCase().replace('_', ' ')}. Would you like to review it?`,
      extractedData: {
        ...case.extractedData,
        draftResponse: draftResponse,
        disputeType: item.type,
        disputeDetails: item,
      },
    },
  });
  
  await this.logActivity(case.id, 'DISPUTE_DRAFT_CREATED', {
    type: item.type,
    vendor: item.vendor,
  });
}

async generateDisputeResponse(item: DisputeAction): Promise<string> {
  // Use Claude to generate appropriate response
  const prompt = `Generate a professional but firm ${item.type} letter for:
    Vendor: ${item.vendor}
    Issue: ${item.description}
    Desired Outcome: ${item.desiredOutcome}
    Supporting Details: ${JSON.stringify(item.supportingDetails)}
    
    Keep it concise, factual, and actionable.`;
    
  return await this.claudeService.generateResponse(prompt);
}
```

### CATEGORY 7: INFORMATIONAL & UPDATES

```typescript
interface InformationalAction {
  type:
    | 'NEWSLETTER'             // Company newsletters
    | 'ANNOUNCEMENT'           // General announcements
    | 'POLICY_UPDATE'          // Terms changes
    | 'ACCOUNT_UPDATE'         // Password, security alerts
    | 'SHIPPING_UPDATE'        // Package tracking
    | 'ORDER_CONFIRMATION'     // Purchase confirmations
    | 'RESERVATION_CONFIRMATION' // Bookings
    | 'TRAVEL_UPDATE'          // Flight changes, gate info
    | 'WEATHER_ALERT'          // Severe weather
    | 'COMMUNITY_ALERT'        // Local emergencies
    | 'SCHOOL_CLOSURE'         // Snow days, emergencies
    | 'PRODUCT_UPDATE'         // Software updates, features
}

async handleInformationalItem(case: EmailCase, item: InformationalAction) {
  switch (item.type) {
    case 'SHIPPING_UPDATE':
      if (item.deliveryDate) {
        await this.createCalendarEvent(case, {
          title: `Package delivery: ${item.itemDescription || 'Order'}`,
          startDate: item.deliveryDate,
          allDay: true,
        });
      }
      await this.logActivity(case.id, 'DELIVERY_TRACKED', { 
        carrier: item.carrier,
        tracking: item.trackingNumber 
      });
      break;
      
    case 'ORDER_CONFIRMATION':
      await this.saveDocument(case, item, 'receipts');
      if (item.estimatedDelivery) {
        await this.createCalendarEvent(case, {
          title: `Expected delivery: ${item.vendor}`,
          startDate: item.estimatedDelivery,
          allDay: true,
        });
      }
      break;
      
    case 'SCHOOL_CLOSURE':
    case 'WEATHER_ALERT':
    case 'COMMUNITY_ALERT':
      // High priority notification
      await this.notifyHousehold(case.householdId, {
        title: item.type.replace('_', ' '),
        message: item.summary,
        priority: 'URGENT',
      });
      // Update calendar if school closure
      if (item.type === 'SCHOOL_CLOSURE') {
        await this.createCalendarEvent(case, {
          title: `NO SCHOOL: ${item.reason}`,
          startDate: item.date,
          allDay: true,
        });
      }
      break;
      
    case 'TRAVEL_UPDATE':
      // Update existing travel calendar events
      await this.updateTravelItinerary(case, item);
      if (item.isSignificantChange) {
        await this.notifyHousehold(case.householdId, {
          title: 'Travel Update',
          message: item.changeDescription,
          priority: 'HIGH',
        });
      }
      break;
      
    case 'NEWSLETTER':
      // Extract any actionable items from newsletter
      const actions = await this.parseNewsletterForActions(item);
      if (actions.length > 0) {
        await this.askQuestion(case,
          `I found ${actions.length} item(s) in this newsletter that might need action: ${actions.map(a => a.summary).join(', ')}. Would you like me to handle any of these?`,
          [...actions.map(a => a.summary), 'No thanks']
        );
      } else {
        await this.markAsCompleted(case, 'Informational newsletter - no action needed');
      }
      break;
      
    default:
      // For purely informational, just acknowledge
      await this.logActivity(case.id, 'INFORMATION_LOGGED', { type: item.type });
      await this.markAsCompleted(case, `Logged ${item.type.toLowerCase().replace('_', ' ')}`);
  }
}
```

### CATEGORY 8: UNKNOWN / CATCH-ALL (CRITICAL!)

```typescript
async handleUnknownEmail(case: EmailCase, parsedResult: ParsedEmailResult) {
  // NEVER do nothing. ALWAYS take action.
  
  // Extract whatever we can
  const observations = [];
  
  if (parsedResult.dates?.length > 0) {
    observations.push(`dates mentioned (${parsedResult.dates.map(d => formatDate(d)).join(', ')})`);
  }
  if (parsedResult.amounts?.length > 0) {
    observations.push(`amounts mentioned ($${parsedResult.amounts.join(', $')})`);
  }
  if (parsedResult.people?.length > 0) {
    observations.push(`people mentioned (${parsedResult.people.join(', ')})`);
  }
  if (parsedResult.companies?.length > 0) {
    observations.push(`companies mentioned (${parsedResult.companies.join(', ')})`);
  }
  if (parsedResult.phoneNumbers?.length > 0) {
    observations.push(`phone numbers found`);
  }
  if (parsedResult.addresses?.length > 0) {
    observations.push(`addresses found`);
  }
  
  // Build smart suggestions based on what we found
  const suggestions = ['Save for reference'];
  
  if (parsedResult.dates?.length > 0) {
    suggestions.unshift('Add to calendar');
  }
  if (parsedResult.amounts?.length > 0) {
    suggestions.unshift('Track as a bill');
  }
  if (parsedResult.companies?.length > 0 || parsedResult.phoneNumbers?.length > 0) {
    suggestions.unshift('Save as vendor contact');
  }
  if (parsedResult.hasAttachment) {
    suggestions.unshift('Save document to vault');
  }
  
  suggestions.push('Create a task/reminder');
  suggestions.push('Something else (tell me)');
  
  // Construct the question
  let question = `I received your forwarded email about "${case.subject}".`;
  
  if (observations.length > 0) {
    question += ` I noticed ${observations.join(', ')}.`;
  }
  
  question += ` How would you like me to help with this?`;
  
  await this.prisma.emailCase.update({
    where: { id: case.id },
    data: {
      status: 'AWAITING_INPUT',
      pendingQuestion: question,
      questionOptions: suggestions,
      detectedIntent: 'UNKNOWN',
      summary: parsedResult.summary || `Email from ${case.fromEmail} about ${case.subject}`,
    },
  });
  
  await this.logActivity(case.id, 'QUESTION_ASKED', {
    reason: 'Could not determine specific intent',
    observations,
    suggestedActions: suggestions,
  });
}

// Handle user's response to unknown email
async handleUnknownEmailResponse(case: EmailCase, userResponse: string) {
  const parsedResult = case.extractedData;
  
  switch (userResponse) {
    case 'Add to calendar':
      if (parsedResult.dates?.length > 0) {
        await this.createCalendarEvent(case, {
          title: case.subject,
          startDate: parsedResult.dates[0],
        });
      } else {
        await this.askQuestion(case, 'What date should I add this to?', ['today', 'tomorrow', 'this weekend', 'Let me type a date']);
      }
      break;
      
    case 'Track as a bill':
      await this.askQuestion(case, 
        `What's the amount and due date?`,
        ['Let me type the details']
      );
      break;
      
    case 'Save as vendor contact':
      const vendorInfo = parsedResult.companies?.[0] || case.fromName;
      await this.createVendor(case.householdId, {
        name: vendorInfo,
        email: case.fromEmail,
        phone: parsedResult.phoneNumbers?.[0],
      });
      await this.markAsCompleted(case, `Added ${vendorInfo} as a vendor`);
      break;
      
    case 'Save document to vault':
      await this.saveDocument(case, { category: 'general' }, 'general');
      await this.markAsCompleted(case, 'Saved to document vault');
      break;
      
    case 'Save for reference':
      await this.markAsCompleted(case, 'Saved for reference - no action taken');
      break;
      
    case 'Create a task/reminder':
      await this.askQuestion(case,
        'What should I remind you about, and when?',
        ['Remind me tomorrow', 'Remind me next week', 'Let me type the details']
      );
      break;
      
    default:
      // User typed something custom
      await this.handleCustomResponse(case, userResponse);
  }
}
```

---

## ENHANCED EMAIL PARSER PROMPT

Update the Claude prompt in `EmailParserService` to extract MORE information:

```typescript
const PARSER_SYSTEM_PROMPT = `You are Alfred, a home management AI assistant. Analyze this email and extract ALL actionable information.

You must identify:

1. **Intent Classification** (pick the most specific one):
   - CALENDAR: Any event, appointment, deadline, schedule
   - BILL: Invoice, payment due, subscription, fee
   - VENDOR: Service provider info, quotes, contracts
   - HOME: Property-related (inspection, HOA, maintenance, permits)
   - FAMILY: Related to family members (school, medical, activities)
   - DISPUTE: Complaints, refunds, issues to resolve
   - TRAVEL: Itineraries, bookings, updates
   - SHIPPING: Package tracking, deliveries
   - INFORMATIONAL: Updates, newsletters, announcements
   - UNKNOWN: Cannot determine - extract what you can

2. **Extract ALL of these if present**:
   - Dates (any date or time mentioned)
   - Amounts (any dollar amounts)
   - People names
   - Company/organization names
   - Phone numbers
   - Email addresses
   - Physical addresses
   - Account numbers
   - Confirmation numbers
   - Tracking numbers

3. **Determine urgency**:
   - URGENT: Deadline within 48 hours, safety issue, time-sensitive
   - HIGH: Deadline within 1 week, financial impact
   - NORMAL: Standard processing
   - LOW: Informational only

4. **Identify which family member** this relates to (if any)

5. **Suggest specific actions** Alfred should take

6. **Summarize** the email in one sentence

IMPORTANT: Even if you can't determine the exact intent, ALWAYS extract whatever information is available. Never return an empty result.`;
```

---

## ADDITIONAL ACTIONS TO IMPLEMENT

### Document Management

```typescript
async saveDocument(case: EmailCase, item: any, category: string) {
  // Save email and attachments to document vault
  const doc = await this.prisma.document.create({
    data: {
      householdId: case.householdId,
      name: item.filename || case.subject,
      category: category, // tax, contracts, receipts, medical, school, general
      sourceType: 'EMAIL',
      sourceEmailCaseId: case.id,
      // Store original email content
      metadata: {
        originalFrom: case.fromEmail,
        originalDate: case.receivedAt,
        originalSubject: case.subject,
      },
    },
  });
  
  // Process attachments
  for (const attachment of case.attachments) {
    await this.prisma.documentAttachment.create({
      data: {
        documentId: doc.id,
        filename: attachment.filename,
        contentType: attachment.contentType,
        url: attachment.storageUrl,
      },
    });
  }
  
  await this.logActivity(case.id, 'DOCUMENT_SAVED', {
    documentId: doc.id,
    category,
  });
}
```

### Task Creation

```typescript
async createTask(case: EmailCase, task: {
  title: string;
  description?: string;
  priority?: 'LOW' | 'NORMAL' | 'HIGH' | 'URGENT';
  dueDate?: Date;
  assignedToId?: string;
}) {
  const newTask = await this.prisma.task.create({
    data: {
      householdId: case.householdId,
      title: task.title,
      description: task.description,
      priority: task.priority || 'NORMAL',
      dueDate: task.dueDate,
      assignedToId: task.assignedToId,
      sourceEmailCaseId: case.id,
      status: 'TODO',
    },
  });
  
  await this.logActivity(case.id, 'TASK_CREATED', {
    taskId: newTask.id,
    title: task.title,
  });
}
```

### Reminder Creation

```typescript
async createReminder(case: EmailCase, date: Date, message: string) {
  await this.prisma.reminder.create({
    data: {
      householdId: case.householdId,
      message,
      remindAt: date,
      sourceEmailCaseId: case.id,
    },
  });
  
  await this.logActivity(case.id, 'REMINDER_CREATED', {
    date: date.toISOString(),
    message,
  });
}
```

---

## VERIFICATION: COMPLETE COVERAGE

After implementation, verify Alfred can handle:

| Category | Email Types | ✓ |
|----------|-------------|---|
| Calendar | Camp, school, appointments, travel, parties, sports, lessons, reservations | |
| Financial | Invoices, payments, subscriptions, refunds, tax docs, insurance, medical bills | |
| Vendor | Quotes, contracts, warranties, maintenance agreements, recommendations | |
| Home | Inspections, HOA, permits, recalls, renovations, energy audits | |
| Family | Medical, school, activities, prescriptions, pet records | |
| Disputes | Billing, service, warranty, insurance, refunds, contracts | |
| Informational | Shipping, orders, travel updates, weather, school closures | |
| **Unknown** | **ANYTHING ELSE - always ask, never ignore** | |

---

## MOBILE: CASES LIST SCREEN

Add `apps/mobile/app/(tabs)/more/alfred-cases.tsx`:

```typescript
// Shows all email cases with:
// - Case number (ALF-2026-000042)
// - Subject line
// - Status badge (color-coded)
// - Date received
// - Actions taken count
// - Tap to view details/respond
```

Add `apps/mobile/app/(tabs)/more/alfred-cases/[id].tsx`:

```typescript
// Shows case details:
// - Original email content
// - Alfred's summary
// - Actions taken (timeline)
// - Pending question (if any)
// - Quick reply buttons
// - Free-form text input
// - Archive button
```

---

## RUN THIS PROMPT

```bash
cd apps/api
pnpm prisma migrate dev --name enhance_alfred_actions
```

Then implement all the handlers in `EmailActionsService`.

**Goal:** After this enhancement, there is NO email that Alfred cannot handle. He either takes automatic action or intelligently asks the user what to do.

# Haven Major Feature Update - Messages, Projects, Maintenance, Requests, Money

## Run in Claude Code:
```bash
cd /Users/tomburke/Projects/Housing-Manager
claude --dangerously-skip-permissions
```

---

# FIX 1: FIND PROS POPUP - FIT FULL NAME

**File:** `apps/web/src/app/app/community/page.tsx`

The name "Estate Grounds Maintenance" is still being cut off. Need to make the card wider and allow name to wrap.

### Replace VendorPopup component:

```tsx
function VendorPopup({ vendor }: { vendor: Vendor }) {
  return (
    <div className="w-[320px] max-w-[calc(100vw-32px)]">
      <div className="bg-white rounded-xl overflow-hidden shadow-lg">
        {/* Header */}
        <div className="p-4">
          <div className="flex items-start gap-3">
            <VendorAvatar name={vendor.name} size="lg" className="flex-shrink-0" />
            <div className="flex-1 min-w-0">
              {/* Name - allow wrap, no truncate */}
              <h3 className="font-semibold text-warm-900 text-sm leading-snug">
                {vendor.name}
              </h3>
              {vendor.havenTrusted && (
                <span className="inline-flex items-center gap-1 mt-1.5 px-2 py-0.5 bg-haven-100 text-haven-700 text-xs font-medium rounded-full">
                  <Shield className="w-3 h-3 flex-shrink-0" />
                  Haven Trusted
                </span>
              )}
            </div>
          </div>
          
          {/* Rating */}
          <div className="mt-3 flex items-center gap-2 text-sm">
            <Star className="w-4 h-4 text-amber-500 fill-current flex-shrink-0" />
            <span className="font-medium text-warm-900">{vendor.rating}</span>
            <span className="text-warm-400">•</span>
            <span className="text-warm-500">{vendor.reviewCount} reviews</span>
          </div>
          
          {/* Stats */}
          <div className="mt-2 flex items-center gap-4 text-sm text-warm-600">
            <div className="flex items-center gap-1.5">
              <Users className="w-4 h-4 text-warm-400 flex-shrink-0" />
              <span>{vendor.neighborsUsed} neighbors</span>
            </div>
            <div className="flex items-center gap-1.5">
              <MapPin className="w-4 h-4 text-warm-400 flex-shrink-0" />
              <span>{vendor.distance} mi</span>
            </div>
          </div>
        </div>
        
        {/* Buttons */}
        <div className="px-4 pb-4 flex gap-2">
          <button className="flex-1 py-2.5 bg-haven-600 text-white text-sm font-medium rounded-lg hover:bg-haven-700 transition-colors">
            Request Quote
          </button>
          <a
            href={`tel:${vendor.phone}`}
            className="px-4 py-2.5 border border-warm-200 rounded-lg hover:bg-warm-50 transition-colors flex items-center justify-center flex-shrink-0"
          >
            <Phone className="w-4 h-4 text-warm-600" />
          </a>
        </div>
      </div>
    </div>
  );
}
```

---

# FIX 2: MESSAGES PAGE - WORKING NEW MESSAGE BUTTON

**File:** `apps/web/src/app/app/messages/page.tsx`

Add a "New Message" modal that lets user select a recipient.

### Add state for new message modal (near other useState):
```tsx
const [showNewMessageModal, setShowNewMessageModal] = useState(false);
const [newMessageRecipient, setNewMessageRecipient] = useState<Contact | null>(null);
```

### Update the "+" button to open modal:
```tsx
<button 
  onClick={() => setShowNewMessageModal(true)}
  className="p-2 bg-haven-600 text-white rounded-xl hover:bg-haven-700 transition-colors"
>
  <Plus className="w-5 h-5" />
</button>
```

### Add New Message Modal at end of component (before final closing div):

```tsx
{/* New Message Modal */}
{showNewMessageModal && (
  <div className="fixed inset-0 z-50 overflow-y-auto">
    <div className="flex min-h-full items-center justify-center p-4">
      <div className="fixed inset-0 bg-black/50" onClick={() => {
        setShowNewMessageModal(false);
        setNewMessageRecipient(null);
      }} />
      <div className="relative bg-white rounded-xl shadow-xl w-full max-w-md max-h-[80vh] overflow-hidden">
        <div className="p-4 border-b border-warm-200">
          <div className="flex items-center justify-between">
            <h3 className="text-lg font-semibold text-warm-900">New Message</h3>
            <button 
              onClick={() => {
                setShowNewMessageModal(false);
                setNewMessageRecipient(null);
              }}
              className="p-2 hover:bg-warm-100 rounded-lg transition-colors"
            >
              <X className="w-5 h-5 text-warm-400" />
            </button>
          </div>
        </div>

        {!newMessageRecipient ? (
          <>
            {/* Search */}
            <div className="p-4 border-b border-warm-100">
              <div className="relative">
                <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-warm-400" />
                <input
                  type="text"
                  placeholder="Search contacts..."
                  className="w-full pl-9 pr-4 py-2 border border-warm-200 rounded-lg text-sm focus:ring-2 focus:ring-haven-500 focus:border-transparent"
                />
              </div>
            </div>

            {/* Contact List */}
            <div className="max-h-[400px] overflow-y-auto">
              {/* Your Team */}
              <div className="px-4 py-2 bg-warm-50">
                <span className="text-xs font-semibold text-warm-500 uppercase tracking-wide">Your Team</span>
              </div>
              {contacts.filter(c => c.category === 'team').map(contact => (
                <button
                  key={contact.id}
                  onClick={() => setNewMessageRecipient(contact)}
                  className="w-full flex items-center gap-3 p-3 hover:bg-warm-50 transition-colors text-left"
                >
                  <InitialsAvatar name={contact.name} size="md" />
                  <div className="flex-1 min-w-0">
                    <p className="font-medium text-warm-900 text-sm">{contact.name}</p>
                    <p className="text-xs text-warm-500 truncate">{contact.role}</p>
                  </div>
                  {contact.isOnline && (
                    <div className="w-2 h-2 bg-green-500 rounded-full" />
                  )}
                </button>
              ))}

              {/* Vendors */}
              <div className="px-4 py-2 bg-warm-50">
                <span className="text-xs font-semibold text-warm-500 uppercase tracking-wide">Vendors</span>
              </div>
              {contacts.filter(c => c.category === 'vendors').map(contact => (
                <button
                  key={contact.id}
                  onClick={() => setNewMessageRecipient(contact)}
                  className="w-full flex items-center gap-3 p-3 hover:bg-warm-50 transition-colors text-left"
                >
                  <VendorAvatar name={contact.name} size="md" />
                  <div className="flex-1 min-w-0">
                    <p className="font-medium text-warm-900 text-sm">{contact.name}</p>
                    <p className="text-xs text-warm-500 truncate">{contact.role}</p>
                  </div>
                </button>
              ))}

              {/* Community */}
              <div className="px-4 py-2 bg-warm-50">
                <span className="text-xs font-semibold text-warm-500 uppercase tracking-wide">Community</span>
              </div>
              {contacts.filter(c => c.category === 'community').map(contact => (
                <button
                  key={contact.id}
                  onClick={() => setNewMessageRecipient(contact)}
                  className="w-full flex items-center gap-3 p-3 hover:bg-warm-50 transition-colors text-left"
                >
                  <InitialsAvatar name={contact.name} size="md" />
                  <div className="flex-1 min-w-0">
                    <p className="font-medium text-warm-900 text-sm">{contact.name}</p>
                    <p className="text-xs text-warm-500 truncate">{contact.role}</p>
                  </div>
                </button>
              ))}
            </div>
          </>
        ) : (
          /* Message Compose View */
          <div className="flex flex-col h-[400px]">
            {/* Recipient Header */}
            <div className="p-3 border-b border-warm-100 flex items-center gap-3">
              <button 
                onClick={() => setNewMessageRecipient(null)}
                className="p-1 hover:bg-warm-100 rounded"
              >
                <ChevronLeft className="w-5 h-5 text-warm-400" />
              </button>
              <InitialsAvatar name={newMessageRecipient.name} size="sm" />
              <div>
                <p className="font-medium text-warm-900 text-sm">{newMessageRecipient.name}</p>
                <p className="text-xs text-warm-500">{newMessageRecipient.role}</p>
              </div>
            </div>

            {/* Message Area */}
            <div className="flex-1 p-4 bg-warm-50">
              <p className="text-sm text-warm-400 text-center mt-8">Start a conversation with {newMessageRecipient.name.split(' ')[0]}</p>
            </div>

            {/* Input */}
            <div className="p-3 border-t border-warm-200 bg-white">
              <div className="flex gap-2">
                <input
                  type="text"
                  placeholder="Type a message..."
                  className="flex-1 px-4 py-2 border border-warm-200 rounded-xl text-sm focus:ring-2 focus:ring-haven-500 focus:border-transparent"
                  autoFocus
                />
                <button className="px-4 py-2 bg-haven-600 text-white rounded-xl hover:bg-haven-700 transition-colors">
                  <Send className="w-4 h-4" />
                </button>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  </div>
)}
```

### Add imports at top:
```tsx
import { ChevronLeft, Send } from 'lucide-react';
```

---

# FIX 3: HOME PROFILE PAGE - CORRECT HOUSE IMAGE

**File:** `apps/web/src/app/app/properties/page.tsx` (or wherever home profile is)

Find where the house image is set and use the correct Greenwich house image.

### Look for the property/house image URL and replace with:
```tsx
// Use the Greenwich house image for the Burke residence
const GREENWICH_HOUSE_IMAGE = 'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=1200&h=800&fit=crop';

// Or if using the uploaded image, reference it from public folder:
// const GREENWICH_HOUSE_IMAGE = '/images/greenwich-house.jpg';
```

Search for any hardcoded house image URLs and replace them with this consistent image.

---

# FIX 4: PROJECT PLANNING PAGE - FIX PHOTO OVERLAY & BUILD OUT

**File:** `apps/web/src/app/app/projects/page.tsx`

### 4a. Fix the project detail view so photo doesn't take up entire screen:

Find the project detail/modal view and update the image section:

```tsx
{/* Project Header Image - Constrained Height */}
<div className="relative h-48 sm:h-64 overflow-hidden">
  <img
    src={project.image}
    alt={project.title}
    className="w-full h-full object-cover"
  />
  <div className="absolute inset-0 bg-gradient-to-t from-black/60 to-transparent" />
  <div className="absolute bottom-4 left-4 right-4">
    <span className={`inline-block px-2 py-1 text-xs font-medium rounded-full ${
      project.status === 'planning' ? 'bg-blue-100 text-blue-700' :
      project.status === 'in-progress' ? 'bg-amber-100 text-amber-700' :
      project.status === 'completed' ? 'bg-green-100 text-green-700' :
      'bg-warm-100 text-warm-700'
    }`}>
      {project.status}
    </span>
    <h2 className="text-xl sm:text-2xl font-bold text-white mt-2">{project.title}</h2>
  </div>
</div>
```

### 4b. Add more sample projects with Home Manager ideas:

```tsx
const MOCK_PROJECTS = [
  {
    id: 'proj-1',
    title: 'Kitchen Backsplash Upgrade',
    description: 'Replace dated backsplash with modern subway tile',
    status: 'planning',
    category: 'Kitchen',
    image: 'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=800&h=600&fit=crop',
    estimatedCost: { low: 2500, high: 4000 },
    timeline: '3-5 days',
    priority: 'medium',
    managerNotes: 'Sarah recommends scheduling this during your March vacation. She has quotes from 3 tile contractors ready for review.',
    nextSteps: [
      { task: 'Review tile samples', status: 'pending', dueDate: 'Jan 15' },
      { task: 'Approve contractor quote', status: 'pending', dueDate: 'Jan 20' },
      { task: 'Schedule installation', status: 'not-started', dueDate: 'Feb 1' },
    ],
    vendorRecommendations: [
      { name: 'Tile Masters CT', quote: 3200, rating: 4.9, neighborsUsed: 12 },
      { name: 'Greenwich Tile & Stone', quote: 3800, rating: 4.7, neighborsUsed: 8 },
    ],
  },
  {
    id: 'proj-2',
    title: 'Master Bathroom Renovation',
    description: 'Full renovation including new vanity, tile, and fixtures',
    status: 'in-progress',
    category: 'Bathroom',
    image: 'https://images.unsplash.com/photo-1552321554-5fefe8c9ef14?w=800&h=600&fit=crop',
    estimatedCost: { low: 25000, high: 40000 },
    timeline: '4-6 weeks',
    priority: 'high',
    managerNotes: 'Mike\'s Plumbing is on schedule. Tile delivery expected Thursday. Sarah will be on-site for inspection.',
    progress: 45,
    nextSteps: [
      { task: 'Plumbing rough-in', status: 'completed', dueDate: 'Dec 15' },
      { task: 'Tile installation', status: 'in-progress', dueDate: 'Dec 28' },
      { task: 'Fixture installation', status: 'not-started', dueDate: 'Jan 5' },
      { task: 'Final inspection', status: 'not-started', dueDate: 'Jan 10' },
    ],
  },
  {
    id: 'proj-3',
    title: 'Outdoor Kitchen Addition',
    description: 'Built-in grill, mini fridge, and prep counter on back patio',
    status: 'planning',
    category: 'Outdoor',
    image: 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=800&h=600&fit=crop',
    estimatedCost: { low: 15000, high: 25000 },
    timeline: '2-3 weeks',
    priority: 'low',
    managerNotes: 'Sarah suggests waiting until spring for better weather. She can have designs ready by February.',
    nextSteps: [
      { task: 'Finalize design', status: 'pending', dueDate: 'Feb 1' },
      { task: 'Permit application', status: 'not-started', dueDate: 'Feb 15' },
    ],
  },
  {
    id: 'proj-4',
    title: 'Whole-Home Generator Installation',
    description: 'Generac 22kW automatic standby generator with transfer switch',
    status: 'planning',
    category: 'Electrical',
    image: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=800&h=600&fit=crop',
    estimatedCost: { low: 12000, high: 18000 },
    timeline: '2-3 days',
    priority: 'high',
    managerNotes: 'After the October outage, Sarah recommends prioritizing this. Tesla Certified Electricians have availability in January.',
    nextSteps: [
      { task: 'Site assessment', status: 'completed', dueDate: 'Dec 10' },
      { task: 'Approve quote', status: 'pending', dueDate: 'Dec 30' },
      { task: 'Schedule installation', status: 'not-started', dueDate: 'Jan 15' },
    ],
  },
  {
    id: 'proj-5',
    title: 'Pool House Refresh',
    description: 'New paint, updated furniture, improved lighting',
    status: 'idea',
    category: 'Outdoor',
    image: 'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?w=800&h=600&fit=crop',
    estimatedCost: { low: 8000, high: 12000 },
    timeline: '1-2 weeks',
    priority: 'low',
    managerNotes: 'Sarah noticed the pool house could use updating before summer. She can coordinate painters and furniture delivery.',
  },
  {
    id: 'proj-6',
    title: 'Smart Home Integration',
    description: 'Unified smart home system - lighting, thermostats, security, audio',
    status: 'planning',
    category: 'Technology',
    image: 'https://images.unsplash.com/photo-1558002038-1055907df827?w=800&h=600&fit=crop',
    estimatedCost: { low: 5000, high: 15000 },
    timeline: '1-2 weeks',
    priority: 'medium',
    managerNotes: 'Security Systems Plus can integrate your existing cameras with a new Control4 system. Sarah recommends this for easier management.',
    nextSteps: [
      { task: 'System design consultation', status: 'pending', dueDate: 'Jan 10' },
      { task: 'Equipment selection', status: 'not-started', dueDate: 'Jan 20' },
    ],
  },
];
```

### 4c. Add Project Detail View Component:

```tsx
function ProjectDetailView({ project, onClose }: { project: Project; onClose: () => void }) {
  return (
    <div className="fixed inset-0 z-50 overflow-y-auto">
      <div className="min-h-full">
        <div className="fixed inset-0 bg-black/50" onClick={onClose} />
        <div className="relative bg-white min-h-full sm:min-h-0 sm:max-w-2xl sm:mx-auto sm:my-8 sm:rounded-xl overflow-hidden">
          {/* Close button */}
          <button
            onClick={onClose}
            className="absolute top-4 right-4 z-10 p-2 bg-white/90 rounded-full shadow-lg hover:bg-white transition-colors"
          >
            <X className="w-5 h-5 text-warm-600" />
          </button>

          {/* Header Image - CONSTRAINED */}
          <div className="relative h-48 sm:h-56">
            <img
              src={project.image}
              alt={project.title}
              className="w-full h-full object-cover"
            />
            <div className="absolute inset-0 bg-gradient-to-t from-black/70 via-black/20 to-transparent" />
            <div className="absolute bottom-4 left-4 right-4">
              <div className="flex items-center gap-2 mb-2">
                <span className={`px-2 py-1 text-xs font-medium rounded-full ${
                  project.status === 'planning' ? 'bg-blue-100 text-blue-700' :
                  project.status === 'in-progress' ? 'bg-amber-100 text-amber-700' :
                  project.status === 'completed' ? 'bg-green-100 text-green-700' :
                  'bg-purple-100 text-purple-700'
                }`}>
                  {project.status === 'idea' ? 'Idea' : project.status}
                </span>
                <span className="px-2 py-1 text-xs font-medium rounded-full bg-white/20 text-white">
                  {project.category}
                </span>
              </div>
              <h2 className="text-xl sm:text-2xl font-bold text-white">{project.title}</h2>
            </div>
          </div>

          {/* Content */}
          <div className="p-4 sm:p-6 space-y-6">
            {/* Description */}
            <p className="text-warm-600">{project.description}</p>

            {/* Quick Stats */}
            <div className="grid grid-cols-3 gap-3">
              <div className="bg-warm-50 rounded-xl p-3 text-center">
                <DollarSign className="w-5 h-5 text-haven-600 mx-auto mb-1" />
                <p className="text-xs text-warm-500">Estimated</p>
                <p className="font-semibold text-warm-900 text-sm">
                  ${project.estimatedCost.low.toLocaleString()} - ${project.estimatedCost.high.toLocaleString()}
                </p>
              </div>
              <div className="bg-warm-50 rounded-xl p-3 text-center">
                <Clock className="w-5 h-5 text-haven-600 mx-auto mb-1" />
                <p className="text-xs text-warm-500">Timeline</p>
                <p className="font-semibold text-warm-900 text-sm">{project.timeline}</p>
              </div>
              <div className="bg-warm-50 rounded-xl p-3 text-center">
                <Flag className="w-5 h-5 text-haven-600 mx-auto mb-1" />
                <p className="text-xs text-warm-500">Priority</p>
                <p className={`font-semibold text-sm ${
                  project.priority === 'high' ? 'text-red-600' :
                  project.priority === 'medium' ? 'text-amber-600' :
                  'text-warm-600'
                }`}>
                  {project.priority.charAt(0).toUpperCase() + project.priority.slice(1)}
                </p>
              </div>
            </div>

            {/* Progress Bar (if in progress) */}
            {project.progress && (
              <div>
                <div className="flex items-center justify-between mb-2">
                  <span className="text-sm font-medium text-warm-700">Progress</span>
                  <span className="text-sm font-bold text-haven-600">{project.progress}%</span>
                </div>
                <div className="h-2 bg-warm-100 rounded-full overflow-hidden">
                  <div 
                    className="h-full bg-haven-500 rounded-full transition-all"
                    style={{ width: `${project.progress}%` }}
                  />
                </div>
              </div>
            )}

            {/* Manager Notes */}
            {project.managerNotes && (
              <div className="bg-haven-50 border border-haven-200 rounded-xl p-4">
                <div className="flex items-start gap-3">
                  <div className="w-8 h-8 bg-haven-100 rounded-full flex items-center justify-center flex-shrink-0">
                    <MessageSquare className="w-4 h-4 text-haven-600" />
                  </div>
                  <div>
                    <p className="text-sm font-medium text-haven-800">Sarah's Recommendation</p>
                    <p className="text-sm text-haven-700 mt-1">{project.managerNotes}</p>
                  </div>
                </div>
              </div>
            )}

            {/* Next Steps */}
            {project.nextSteps && project.nextSteps.length > 0 && (
              <div>
                <h3 className="font-semibold text-warm-900 mb-3">Next Steps</h3>
                <div className="space-y-2">
                  {project.nextSteps.map((step, idx) => (
                    <div key={idx} className="flex items-center gap-3 p-3 bg-warm-50 rounded-lg">
                      <div className={`w-6 h-6 rounded-full flex items-center justify-center flex-shrink-0 ${
                        step.status === 'completed' ? 'bg-green-100' :
                        step.status === 'in-progress' ? 'bg-amber-100' :
                        step.status === 'pending' ? 'bg-blue-100' :
                        'bg-warm-200'
                      }`}>
                        {step.status === 'completed' ? (
                          <Check className="w-3 h-3 text-green-600" />
                        ) : step.status === 'in-progress' ? (
                          <Clock className="w-3 h-3 text-amber-600" />
                        ) : (
                          <Circle className="w-3 h-3 text-warm-400" />
                        )}
                      </div>
                      <div className="flex-1 min-w-0">
                        <p className={`text-sm ${step.status === 'completed' ? 'text-warm-500 line-through' : 'text-warm-900'}`}>
                          {step.task}
                        </p>
                      </div>
                      <span className="text-xs text-warm-500">{step.dueDate}</span>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* Vendor Recommendations */}
            {project.vendorRecommendations && project.vendorRecommendations.length > 0 && (
              <div>
                <h3 className="font-semibold text-warm-900 mb-3">Vendor Quotes</h3>
                <div className="space-y-2">
                  {project.vendorRecommendations.map((vendor, idx) => (
                    <div key={idx} className="flex items-center justify-between p-3 bg-warm-50 rounded-lg">
                      <div className="flex items-center gap-3">
                        <VendorAvatar name={vendor.name} size="md" />
                        <div>
                          <p className="font-medium text-warm-900 text-sm">{vendor.name}</p>
                          <div className="flex items-center gap-2 text-xs text-warm-500">
                            <Star className="w-3 h-3 text-amber-500 fill-current" />
                            <span>{vendor.rating}</span>
                            <span>•</span>
                            <span>{vendor.neighborsUsed} neighbors used</span>
                          </div>
                        </div>
                      </div>
                      <div className="text-right">
                        <p className="font-bold text-warm-900">${vendor.quote.toLocaleString()}</p>
                        <button className="text-xs text-haven-600 font-medium hover:text-haven-700">
                          View Details
                        </button>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* Action Buttons */}
            <div className="flex gap-3 pt-4">
              <button className="flex-1 py-3 bg-haven-600 text-white font-medium rounded-xl hover:bg-haven-700 transition-colors">
                Approve & Schedule
              </button>
              <button className="px-4 py-3 border border-warm-200 rounded-xl hover:bg-warm-50 transition-colors">
                <MessageSquare className="w-5 h-5 text-warm-600" />
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
```

---

# FIX 5: MAINTENANCE PAGE - ADD VEHICLES & OTHER SYSTEMS

**File:** `apps/web/src/app/app/maintenance/page.tsx`

### CIO Decision: YES, include vehicles and all household systems

The Maintenance page should be a comprehensive view of ALL things that need maintaining:
- Home Systems (HVAC, plumbing, electrical, appliances)
- Vehicles (oil changes, registration, inspections, tires)
- Pool & Spa
- Lawn & Garden equipment
- Security systems
- And anything else the family owns

### Add Vehicle Maintenance Section:

```tsx
// Add to categories/types
type MaintenanceCategory = 'hvac' | 'plumbing' | 'electrical' | 'appliances' | 'vehicles' | 'pool' | 'outdoor' | 'security';

// Add vehicle maintenance items to mock data
const VEHICLE_MAINTENANCE = [
  {
    id: 'vm-1',
    title: "Bob's Tesla - Tire Rotation",
    category: 'vehicles',
    vehicle: '2023 Tesla Model Y',
    dueDate: getDate(45),
    dueMileage: 30000,
    currentMileage: 24500,
    priority: 'medium',
    estimatedCost: 75,
    vendor: 'Tesla Service Center',
    lastCompleted: getDate(-90),
    notes: 'Recommend every 7,500 miles',
  },
  {
    id: 'vm-2',
    title: 'Highlander - Oil Change',
    category: 'vehicles',
    vehicle: '2022 Toyota Highlander',
    dueDate: getDate(30),
    dueMileage: 37500,
    currentMileage: 35200,
    priority: 'high',
    estimatedCost: 85,
    vendor: 'Greenwich Toyota',
    lastCompleted: getDate(-45),
    notes: 'Every 5,000 miles or 6 months',
  },
  {
    id: 'vm-3',
    title: "Bob's Tesla - Registration Renewal",
    category: 'vehicles',
    vehicle: '2023 Tesla Model Y',
    dueDate: getDate(45),
    priority: 'high',
    estimatedCost: 250,
    notes: 'Sarah will handle DMV paperwork',
    isAdminTask: true,
  },
  {
    id: 'vm-4',
    title: 'Highlander - State Inspection',
    category: 'vehicles',
    vehicle: '2022 Toyota Highlander',
    dueDate: getDate(90),
    priority: 'medium',
    estimatedCost: 35,
    vendor: 'Greenwich Toyota',
  },
];

// Add vehicles category config
const categoryConfig = {
  // ... existing categories ...
  vehicles: { 
    label: 'Vehicles', 
    icon: Car, 
    color: 'text-blue-600',
    bgColor: 'bg-blue-100',
  },
  pool: {
    label: 'Pool & Spa',
    icon: Droplets, // or custom pool icon
    color: 'text-cyan-600',
    bgColor: 'bg-cyan-100',
  },
  outdoor: {
    label: 'Outdoor/Lawn',
    icon: TreePine,
    color: 'text-green-600',
    bgColor: 'bg-green-100',
  },
  security: {
    label: 'Security',
    icon: Shield,
    color: 'text-purple-600',
    bgColor: 'bg-purple-100',
  },
};
```

### Add category tabs that include Vehicles:

```tsx
{/* Category Tabs */}
<div className="flex gap-2 overflow-x-auto pb-2 scrollbar-hide">
  <button
    onClick={() => setSelectedCategory('all')}
    className={`px-4 py-2 rounded-full text-sm font-medium whitespace-nowrap transition-all ${
      selectedCategory === 'all' ? 'bg-haven-600 text-white' : 'bg-warm-100 text-warm-600'
    }`}
  >
    All Systems
  </button>
  {Object.entries(categoryConfig).map(([key, config]) => {
    const Icon = config.icon;
    return (
      <button
        key={key}
        onClick={() => setSelectedCategory(key)}
        className={`flex items-center gap-2 px-4 py-2 rounded-full text-sm font-medium whitespace-nowrap transition-all ${
          selectedCategory === key ? 'bg-haven-600 text-white' : 'bg-warm-100 text-warm-600'
        }`}
      >
        <Icon className="w-4 h-4" />
        {config.label}
      </button>
    );
  })}
</div>
```

---

# FIX 6: REQUESTS PAGE - NOTIFICATION BUBBLE & APPROVAL WORKFLOW

**File:** `apps/web/src/app/app/requests/page.tsx`

### 6a. Update sidebar/nav to show notification count:

In the sidebar component, add a badge showing pending requests count:

```tsx
// In desktop-sidebar.tsx or wherever nav items are
{
  name: 'Requests',
  href: '/app/requests',
  icon: Inbox,
  badge: 5, // Number of pending requests needing attention
}

// Render with badge:
<Link href={item.href} className="...">
  <item.icon className="w-5 h-5" />
  <span>{item.name}</span>
  {item.badge && item.badge > 0 && (
    <span className="ml-auto px-2 py-0.5 bg-red-500 text-white text-xs font-bold rounded-full">
      {item.badge}
    </span>
  )}
</Link>
```

### 6b. Redesign Requests page for easy approval/denial:

```tsx
'use client';

import { useState } from 'react';
import {
  Inbox,
  Check,
  X,
  Clock,
  AlertCircle,
  MessageSquare,
  DollarSign,
  Calendar,
  ChevronRight,
  Filter,
  CheckCircle2,
  XCircle,
  HelpCircle,
} from 'lucide-react';
import { InitialsAvatar } from '@/components/ui/avatar';

type RequestStatus = 'pending' | 'approved' | 'denied' | 'info-needed';
type RequestType = 'approval' | 'question' | 'scheduling' | 'expense' | 'recommendation';

interface Request {
  id: string;
  type: RequestType;
  title: string;
  description: string;
  from: string;
  fromRole: string;
  status: RequestStatus;
  priority: 'urgent' | 'normal' | 'low';
  createdAt: string;
  amount?: number;
  options?: { id: string; label: string; recommended?: boolean }[];
  attachments?: string[];
}

const MOCK_REQUESTS: Request[] = [
  {
    id: 'req-1',
    type: 'expense',
    title: 'Approve plumber invoice',
    description: 'Mike\'s Plumbing completed the bathroom repair. Invoice attached for your approval.',
    from: 'Sarah Chen',
    fromRole: 'Home Manager',
    status: 'pending',
    priority: 'urgent',
    createdAt: '2 hours ago',
    amount: 450,
  },
  {
    id: 'req-2',
    type: 'scheduling',
    title: 'HVAC maintenance date',
    description: 'Comfort Zone HVAC has two available slots for the annual maintenance. Which works better?',
    from: 'Sarah Chen',
    fromRole: 'Home Manager',
    status: 'pending',
    priority: 'normal',
    createdAt: '5 hours ago',
    options: [
      { id: 'opt-1', label: 'Tuesday, Jan 7 at 9am', recommended: true },
      { id: 'opt-2', label: 'Thursday, Jan 9 at 2pm' },
    ],
  },
  {
    id: 'req-3',
    type: 'question',
    title: 'Kitchen backsplash tile selection',
    description: 'I\'ve narrowed down the tile options to three choices. Which style do you prefer?',
    from: 'Sarah Chen',
    fromRole: 'Home Manager',
    status: 'pending',
    priority: 'normal',
    createdAt: 'Yesterday',
    options: [
      { id: 'tile-1', label: 'White subway tile (classic)', recommended: true },
      { id: 'tile-2', label: 'Herringbone pattern (modern)' },
      { id: 'tile-3', label: 'Marble mosaic (luxury)' },
    ],
  },
  {
    id: 'req-4',
    type: 'recommendation',
    title: 'Generator installation quote',
    description: 'After the last outage, I recommend installing a whole-home generator. Tesla Certified Electricians quoted $14,500. Should I proceed?',
    from: 'Sarah Chen',
    fromRole: 'Home Manager',
    status: 'pending',
    priority: 'normal',
    createdAt: 'Yesterday',
    amount: 14500,
  },
  {
    id: 'req-5',
    type: 'expense',
    title: 'Pool opening service',
    description: 'Pool Paradise CT is ready to open the pool for summer. Standard opening package.',
    from: 'Sarah Chen',
    fromRole: 'Home Manager',
    status: 'pending',
    priority: 'low',
    createdAt: '2 days ago',
    amount: 350,
  },
];

export default function RequestsPage() {
  const [requests, setRequests] = useState(MOCK_REQUESTS);
  const [filter, setFilter] = useState<'all' | 'pending' | 'resolved'>('pending');
  const [selectedRequest, setSelectedRequest] = useState<Request | null>(null);

  const pendingCount = requests.filter(r => r.status === 'pending').length;
  const filteredRequests = requests.filter(r => {
    if (filter === 'pending') return r.status === 'pending';
    if (filter === 'resolved') return r.status === 'approved' || r.status === 'denied';
    return true;
  });

  const handleApprove = (id: string, optionId?: string) => {
    setRequests(prev => prev.map(r => 
      r.id === id ? { ...r, status: 'approved' as RequestStatus } : r
    ));
    setSelectedRequest(null);
  };

  const handleDeny = (id: string) => {
    setRequests(prev => prev.map(r => 
      r.id === id ? { ...r, status: 'denied' as RequestStatus } : r
    ));
    setSelectedRequest(null);
  };

  const getTypeIcon = (type: RequestType) => {
    switch (type) {
      case 'expense': return DollarSign;
      case 'scheduling': return Calendar;
      case 'question': return HelpCircle;
      case 'recommendation': return AlertCircle;
      default: return Inbox;
    }
  };

  return (
    <div className="min-h-screen bg-warm-50">
      {/* Header */}
      <div className="bg-white border-b border-warm-200 sticky top-0 z-10">
        <div className="max-w-4xl mx-auto px-4 py-4">
          <div className="flex items-center justify-between mb-4">
            <div>
              <h1 className="text-2xl font-bold text-warm-900">Requests</h1>
              <p className="text-sm text-warm-500">
                {pendingCount} item{pendingCount !== 1 ? 's' : ''} need{pendingCount === 1 ? 's' : ''} your attention
              </p>
            </div>
          </div>

          {/* Filter Tabs */}
          <div className="flex gap-1 p-1 bg-warm-100 rounded-xl">
            {[
              { id: 'pending', label: 'Pending', count: pendingCount },
              { id: 'resolved', label: 'Resolved' },
              { id: 'all', label: 'All' },
            ].map(tab => (
              <button
                key={tab.id}
                onClick={() => setFilter(tab.id as typeof filter)}
                className={`flex-1 flex items-center justify-center gap-2 px-4 py-2 rounded-lg text-sm font-medium transition-all ${
                  filter === tab.id
                    ? 'bg-white text-warm-900 shadow-sm'
                    : 'text-warm-600 hover:text-warm-900'
                }`}
              >
                {tab.label}
                {tab.count !== undefined && tab.count > 0 && (
                  <span className={`px-1.5 py-0.5 text-xs rounded-full ${
                    filter === tab.id ? 'bg-haven-100 text-haven-700' : 'bg-warm-200 text-warm-600'
                  }`}>
                    {tab.count}
                  </span>
                )}
              </button>
            ))}
          </div>
        </div>
      </div>

      {/* Request List */}
      <div className="max-w-4xl mx-auto px-4 py-4 space-y-3">
        {filteredRequests.map(request => {
          const TypeIcon = getTypeIcon(request.type);
          return (
            <div
              key={request.id}
              className={`bg-white rounded-xl border overflow-hidden transition-all ${
                request.status === 'pending' 
                  ? 'border-warm-200 hover:border-haven-300 hover:shadow-md cursor-pointer'
                  : 'border-warm-100 opacity-75'
              }`}
              onClick={() => request.status === 'pending' && setSelectedRequest(request)}
            >
              <div className="p-4">
                <div className="flex items-start gap-3">
                  {/* Type Icon */}
                  <div className={`w-10 h-10 rounded-xl flex items-center justify-center flex-shrink-0 ${
                    request.type === 'expense' ? 'bg-green-100' :
                    request.type === 'scheduling' ? 'bg-blue-100' :
                    request.type === 'question' ? 'bg-purple-100' :
                    'bg-amber-100'
                  }`}>
                    <TypeIcon className={`w-5 h-5 ${
                      request.type === 'expense' ? 'text-green-600' :
                      request.type === 'scheduling' ? 'text-blue-600' :
                      request.type === 'question' ? 'text-purple-600' :
                      'text-amber-600'
                    }`} />
                  </div>

                  {/* Content */}
                  <div className="flex-1 min-w-0">
                    <div className="flex items-start justify-between gap-2">
                      <div>
                        <h3 className="font-medium text-warm-900">{request.title}</h3>
                        <p className="text-sm text-warm-500 mt-0.5 line-clamp-2">{request.description}</p>
                      </div>
                      {request.priority === 'urgent' && request.status === 'pending' && (
                        <span className="px-2 py-0.5 bg-red-100 text-red-700 text-xs font-medium rounded-full flex-shrink-0">
                          Urgent
                        </span>
                      )}
                    </div>

                    {/* Meta */}
                    <div className="flex items-center gap-3 mt-2 text-xs text-warm-500">
                      <span>From {request.from}</span>
                      <span>•</span>
                      <span>{request.createdAt}</span>
                      {request.amount && (
                        <>
                          <span>•</span>
                          <span className="font-medium text-warm-700">${request.amount.toLocaleString()}</span>
                        </>
                      )}
                    </div>
                  </div>

                  {/* Status/Arrow */}
                  {request.status === 'pending' ? (
                    <ChevronRight className="w-5 h-5 text-warm-400 flex-shrink-0" />
                  ) : request.status === 'approved' ? (
                    <CheckCircle2 className="w-5 h-5 text-green-500 flex-shrink-0" />
                  ) : (
                    <XCircle className="w-5 h-5 text-red-500 flex-shrink-0" />
                  )}
                </div>

                {/* Quick Actions for Pending */}
                {request.status === 'pending' && !request.options && (
                  <div className="flex gap-2 mt-3 pt-3 border-t border-warm-100">
                    <button
                      onClick={(e) => {
                        e.stopPropagation();
                        handleApprove(request.id);
                      }}
                      className="flex-1 flex items-center justify-center gap-2 py-2 bg-haven-600 text-white text-sm font-medium rounded-lg hover:bg-haven-700 transition-colors"
                    >
                      <Check className="w-4 h-4" />
                      Approve
                    </button>
                    <button
                      onClick={(e) => {
                        e.stopPropagation();
                        handleDeny(request.id);
                      }}
                      className="flex-1 flex items-center justify-center gap-2 py-2 border border-warm-200 text-warm-600 text-sm font-medium rounded-lg hover:bg-warm-50 transition-colors"
                    >
                      <X className="w-4 h-4" />
                      Deny
                    </button>
                  </div>
                )}

                {/* Options for questions/scheduling */}
                {request.status === 'pending' && request.options && (
                  <div className="mt-3 pt-3 border-t border-warm-100 space-y-2">
                    {request.options.map(option => (
                      <button
                        key={option.id}
                        onClick={(e) => {
                          e.stopPropagation();
                          handleApprove(request.id, option.id);
                        }}
                        className={`w-full flex items-center justify-between p-3 rounded-lg border transition-colors ${
                          option.recommended 
                            ? 'border-haven-200 bg-haven-50 hover:bg-haven-100'
                            : 'border-warm-200 hover:bg-warm-50'
                        }`}
                      >
                        <span className="text-sm text-warm-900">{option.label}</span>
                        {option.recommended && (
                          <span className="text-xs text-haven-600 font-medium">Recommended</span>
                        )}
                      </button>
                    ))}
                  </div>
                )}
              </div>
            </div>
          );
        })}

        {filteredRequests.length === 0 && (
          <div className="text-center py-12">
            <CheckCircle2 className="w-12 h-12 text-haven-300 mx-auto mb-3" />
            <p className="text-warm-500">No {filter} requests</p>
          </div>
        )}
      </div>
    </div>
  );
}
```

---

# FIX 7: TASKS PAGE - ADD ERRANDS FEATURE

**File:** `apps/web/src/app/app/tasks/page.tsx`

Add an "Add Errand" button and modal for subscribers to add tasks to the manager's queue:

```tsx
// Add state
const [showAddErrandModal, setShowAddErrandModal] = useState(false);

// Add button in header
<button
  onClick={() => setShowAddErrandModal(true)}
  className="flex items-center gap-2 px-4 py-2 bg-haven-600 text-white font-medium rounded-xl hover:bg-haven-700 transition-colors"
>
  <Plus className="w-5 h-5" />
  Add Errand
</button>

// Add modal
{showAddErrandModal && (
  <div className="fixed inset-0 z-50 overflow-y-auto">
    <div className="flex min-h-full items-center justify-center p-4">
      <div className="fixed inset-0 bg-black/50" onClick={() => setShowAddErrandModal(false)} />
      <div className="relative bg-white rounded-xl shadow-xl w-full max-w-md">
        <div className="p-4 border-b border-warm-200">
          <div className="flex items-center justify-between">
            <h3 className="text-lg font-semibold text-warm-900">Add Errand for Sarah</h3>
            <button onClick={() => setShowAddErrandModal(false)} className="p-2 hover:bg-warm-100 rounded-lg">
              <X className="w-5 h-5 text-warm-400" />
            </button>
          </div>
        </div>

        <div className="p-4 space-y-4">
          <div>
            <label className="block text-sm font-medium text-warm-700 mb-2">What do you need?</label>
            <input
              type="text"
              placeholder="e.g., Pick up dry cleaning"
              className="w-full px-4 py-2.5 border border-warm-200 rounded-xl focus:ring-2 focus:ring-haven-500 focus:border-transparent"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-warm-700 mb-2">Category</label>
            <select className="w-full px-4 py-2.5 border border-warm-200 rounded-xl focus:ring-2 focus:ring-haven-500">
              <option>Shopping</option>
              <option>Pickup/Delivery</option>
              <option>Appointment</option>
              <option>Research</option>
              <option>Other</option>
            </select>
          </div>

          <div>
            <label className="block text-sm font-medium text-warm-700 mb-2">Priority</label>
            <div className="flex gap-2">
              {['Low', 'Normal', 'Urgent'].map(p => (
                <button
                  key={p}
                  className="flex-1 py-2 border border-warm-200 rounded-lg text-sm font-medium hover:bg-warm-50"
                >
                  {p}
                </button>
              ))}
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-warm-700 mb-2">Details (optional)</label>
            <textarea
              placeholder="Any additional details..."
              rows={3}
              className="w-full px-4 py-2.5 border border-warm-200 rounded-xl focus:ring-2 focus:ring-haven-500 focus:border-transparent resize-none"
            />
          </div>
        </div>

        <div className="p-4 border-t border-warm-200 flex gap-3">
          <button
            onClick={() => setShowAddErrandModal(false)}
            className="flex-1 py-2.5 border border-warm-200 text-warm-700 font-medium rounded-xl hover:bg-warm-50"
          >
            Cancel
          </button>
          <button
            onClick={() => {
              // Add errand logic
              setShowAddErrandModal(false);
            }}
            className="flex-1 py-2.5 bg-haven-600 text-white font-medium rounded-xl hover:bg-haven-700"
          >
            Send to Sarah
          </button>
        </div>
      </div>
    </div>
  </div>
)}
```

---

# FIX 8: MONEY PAGE - REMOVE SLATE, USE WARM PALETTE

**File:** `apps/web/src/app/app/money/page.tsx`

### CIO Decision: Remove ALL slate colors from the app

The app should use a consistent warm palette throughout. Replace all slate references with warm equivalents:

```
slate-50 → warm-50
slate-100 → warm-100
slate-200 → warm-200
slate-300 → warm-300
slate-400 → warm-400
slate-500 → warm-500
slate-600 → warm-600
slate-700 → warm-700
slate-800 → warm-800
slate-900 → warm-900
slate-950 → warm-950
```

Search and replace in the Money page:
- `bg-slate-` → `bg-warm-`
- `text-slate-` → `text-warm-`
- `border-slate-` → `border-warm-`

The dark financial summary cards can use `bg-forest-900` or `bg-warm-900` instead of `bg-slate-900`.

### Example for financial summary card:
```tsx
{/* Financial Roll-up - use forest or warm-900 instead of slate */}
<div className="bg-gradient-to-r from-forest-900 to-forest-800 rounded-xl p-6 text-white">
  {/* ... content ... */}
</div>
```

---

# SUMMARY

| Fix | Description |
|-----|-------------|
| 1 | Find Pros popup - wider card (320px), full name display |
| 2 | Messages - working "+" button with recipient selection |
| 3 | Home profile - correct Greenwich house image |
| 4 | Project Planning - constrained image, more projects with manager notes |
| 5 | Maintenance - add vehicles, pool, outdoor, security categories |
| 6 | Requests - notification badge, easy approve/deny workflow |
| 7 | Tasks - add errands feature for subscribers |
| 8 | Money - replace slate with warm palette |

---

## Run in Claude Code:

```
Read and apply all fixes in HAVEN_MAJOR_UPDATE.md

Key changes:
1. Vendor popup - wider (320px), name wraps fully
2. Messages - add new message modal with contact selection
3. Project planning - fix image height, add 6 detailed projects with manager recommendations
4. Maintenance - add Vehicles, Pool, Outdoor, Security categories  
5. Requests - add nav badge, redesign for easy approve/deny
6. Tasks - add "Add Errand" feature
7. Money - replace all slate colors with warm palette
```

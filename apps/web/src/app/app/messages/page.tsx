'use client';

import { useState } from 'react';
import {
  Search,
  MessageSquare,
  Phone,
  Video,
  MoreVertical,
  Pin,
  Star,
  Clock,
  CheckCheck,
  Circle,
  ChevronRight,
  ChevronLeft,
  Plus,
  Filter,
  Users,
  Briefcase,
  GraduationCap,
  Home,
  Wrench,
  Shield,
  Building,
  FolderOpen,
  Hash,
  ArrowRight,
  X,
  Send,
} from 'lucide-react';
import { getUserAvatar, getVendorAvatar } from '@/lib/avatars';
import { InitialsAvatar, VendorAvatar, ManagerAvatar, HandymanAvatar, ConciergeAvatar, PersonAvatar } from '@/components/ui/avatar';

// ============================================================================
// TYPES
// ============================================================================

type TabType = 'conversations' | 'projects';
type CategoryType = 'team' | 'vendors' | 'community' | 'schools';

interface Contact {
  id: string;
  name: string;
  role: string;
  avatar: string;
  isPinned: boolean;
  isOnline: boolean;
  lastMessage: string;
  lastMessageTime: string;
  unreadCount: number;
  category: CategoryType;
  isHavenTeam?: boolean;
}

interface ProjectConversation {
  id: string;
  title: string;
  category: string;
  status: 'active' | 'pending' | 'resolved';
  participants: { name: string; avatar: string; role: string }[];
  lastMessage: string;
  lastMessageTime: string;
  unreadCount: number;
  vendor?: string;
}

// ============================================================================
// MOCK DATA
// ============================================================================

const contacts: Contact[] = [
  // Your Team - Pinned
  {
    id: 'sarah-chen',
    name: 'Sarah Chen',
    role: 'Your Home Manager',
    avatar: getUserAvatar('Sarah Chen'),
    isPinned: true,
    isOnline: true,
    lastMessage: 'The landscaper confirmed for Thursday at 9am',
    lastMessageTime: '2m ago',
    unreadCount: 2,
    category: 'team',
    isHavenTeam: true,
  },
  {
    id: 'marcus-johnson',
    name: 'Marcus Johnson',
    role: 'Your Handyman',
    avatar: getUserAvatar('Marcus Johnson'),
    isPinned: true,
    isOnline: false,
    lastMessage: 'Fixed the cabinet hinge, all set!',
    lastMessageTime: '1h ago',
    unreadCount: 0,
    category: 'team',
    isHavenTeam: true,
  },
  {
    id: 'haven-concierge',
    name: 'Haven Concierge',
    role: 'AI Assistant',
    avatar: '/haven-logo.svg',
    isPinned: true,
    isOnline: true,
    lastMessage: 'How can I help you today?',
    lastMessageTime: 'Now',
    unreadCount: 0,
    category: 'team',
    isHavenTeam: true,
  },

  // Vendors
  {
    id: 'mikes-plumbing',
    name: "Mike's Plumbing Pro",
    role: 'Plumber • Haven Trusted',
    avatar: getVendorAvatar("Mike's Plumbing Pro"),
    isPinned: false,
    isOnline: false,
    lastMessage: 'Quote sent for the bathroom repair',
    lastMessageTime: 'Yesterday',
    unreadCount: 1,
    category: 'vendors',
  },
  {
    id: 'country-landscape',
    name: 'Country Landscape Design',
    role: 'Landscaper • Haven Trusted',
    avatar: getVendorAvatar('Country Landscape Design'),
    isPinned: false,
    isOnline: true,
    lastMessage: 'Spring cleanup scheduled for next week',
    lastMessageTime: '2d ago',
    unreadCount: 0,
    category: 'vendors',
  },
  {
    id: 'comfort-zone',
    name: 'Comfort Zone HVAC',
    role: 'HVAC • Haven Trusted',
    avatar: getVendorAvatar('Comfort Zone HVAC'),
    isPinned: false,
    isOnline: false,
    lastMessage: 'Annual maintenance complete',
    lastMessageTime: '1w ago',
    unreadCount: 0,
    category: 'vendors',
  },

  // Community
  {
    id: 'bob-neighbor',
    name: 'Bob Thompson',
    role: 'Neighbor • 42 Bedford Rd',
    avatar: getUserAvatar('Bob Thompson'),
    isPinned: false,
    isOnline: false,
    lastMessage: 'Thanks for the contractor recommendation!',
    lastMessageTime: '3d ago',
    unreadCount: 0,
    category: 'community',
  },
  {
    id: 'alice-neighbor',
    name: 'Alice Martinez',
    role: 'Neighbor • 56 Bedford Rd',
    avatar: getUserAvatar('Alice Martinez'),
    isPinned: false,
    isOnline: true,
    lastMessage: 'Are you going to the block party?',
    lastMessageTime: '5d ago',
    unreadCount: 0,
    category: 'community',
  },

  // Schools
  {
    id: 'greenwich-academy',
    name: 'Greenwich Academy',
    role: 'Private School • Admissions',
    avatar: getVendorAvatar('Greenwich Academy'),
    isPinned: false,
    isOnline: false,
    lastMessage: 'Application deadline reminder: Jan 15',
    lastMessageTime: '1w ago',
    unreadCount: 1,
    category: 'schools',
  },
  {
    id: 'brunswick-school',
    name: 'Brunswick School',
    role: 'Private School • Athletics',
    avatar: getVendorAvatar('Brunswick School'),
    isPinned: false,
    isOnline: false,
    lastMessage: 'Soccer tryouts schedule attached',
    lastMessageTime: '2w ago',
    unreadCount: 0,
    category: 'schools',
  },
];

const projectConversations: ProjectConversation[] = [
  {
    id: 'proj-1',
    title: 'Master Bathroom Renovation',
    category: 'Plumbing',
    status: 'active',
    participants: [
      { name: 'Sarah Chen', avatar: getUserAvatar('Sarah Chen'), role: 'Home Manager' },
      { name: "Mike's Plumbing", avatar: getVendorAvatar("Mike's Plumbing Pro"), role: 'Vendor' },
    ],
    lastMessage: 'Tile samples arriving tomorrow',
    lastMessageTime: '30m ago',
    unreadCount: 3,
    vendor: "Mike's Plumbing Pro",
  },
  {
    id: 'proj-2',
    title: 'HVAC Annual Maintenance',
    category: 'HVAC',
    status: 'resolved',
    participants: [
      { name: 'Sarah Chen', avatar: getUserAvatar('Sarah Chen'), role: 'Home Manager' },
      { name: 'Comfort Zone', avatar: getVendorAvatar('Comfort Zone HVAC'), role: 'Vendor' },
    ],
    lastMessage: 'All systems checked and running efficiently',
    lastMessageTime: '1w ago',
    unreadCount: 0,
    vendor: 'Comfort Zone HVAC',
  },
  {
    id: 'proj-3',
    title: 'Spring Landscaping Project',
    category: 'Landscaping',
    status: 'pending',
    participants: [
      { name: 'Sarah Chen', avatar: getUserAvatar('Sarah Chen'), role: 'Home Manager' },
      { name: 'Country Landscape', avatar: getVendorAvatar('Country Landscape Design'), role: 'Vendor' },
    ],
    lastMessage: 'Waiting for plant delivery confirmation',
    lastMessageTime: '2d ago',
    unreadCount: 0,
    vendor: 'Country Landscape Design',
  },
  {
    id: 'proj-4',
    title: 'Cabinet Door Repair',
    category: 'Handyman',
    status: 'resolved',
    participants: [
      { name: 'Marcus Johnson', avatar: getUserAvatar('Marcus Johnson'), role: 'Handyman' },
    ],
    lastMessage: 'Fixed the cabinet hinge, all set!',
    lastMessageTime: '1h ago',
    unreadCount: 0,
  },
  {
    id: 'proj-5',
    title: 'Pool Opening 2025',
    category: 'Pool',
    status: 'pending',
    participants: [
      { name: 'Sarah Chen', avatar: getUserAvatar('Sarah Chen'), role: 'Home Manager' },
    ],
    lastMessage: 'Scheduled for May 1st pending weather',
    lastMessageTime: '3d ago',
    unreadCount: 1,
  },
];

const categoryConfig = {
  team: { label: 'Your Team', icon: Shield, color: 'text-haven-700' },
  vendors: { label: 'Vendors', icon: Wrench, color: 'text-amber-600' },
  community: { label: 'Community', icon: Users, color: 'text-blue-600' },
  schools: { label: 'Schools', icon: GraduationCap, color: 'text-purple-600' },
};

// ============================================================================
// MAIN COMPONENT
// ============================================================================

export default function MessagesPage() {
  const [activeTab, setActiveTab] = useState<TabType>('conversations');
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCategory, setSelectedCategory] = useState<CategoryType | 'all'>('all');
  const [projectFilter, setProjectFilter] = useState<'all' | 'active' | 'pending' | 'resolved'>('all');
  const [showNewMessageModal, setShowNewMessageModal] = useState(false);
  const [newMessageRecipient, setNewMessageRecipient] = useState<Contact | null>(null);

  // Filter contacts
  const filteredContacts = contacts.filter(contact => {
    if (searchQuery) {
      const query = searchQuery.toLowerCase();
      return contact.name.toLowerCase().includes(query) ||
             contact.role.toLowerCase().includes(query);
    }
    if (selectedCategory !== 'all' && contact.category !== selectedCategory) {
      return false;
    }
    return true;
  });

  // Group contacts by category (pinned first)
  const pinnedContacts = filteredContacts.filter(c => c.isPinned);
  const groupedContacts = {
    team: filteredContacts.filter(c => !c.isPinned && c.category === 'team'),
    vendors: filteredContacts.filter(c => c.category === 'vendors'),
    community: filteredContacts.filter(c => c.category === 'community'),
    schools: filteredContacts.filter(c => c.category === 'schools'),
  };

  // Filter projects
  const filteredProjects = projectConversations.filter(proj => {
    if (searchQuery) {
      const query = searchQuery.toLowerCase();
      return proj.title.toLowerCase().includes(query) ||
             proj.category.toLowerCase().includes(query);
    }
    if (projectFilter !== 'all' && proj.status !== projectFilter) {
      return false;
    }
    return true;
  });

  return (
    <div className="min-h-screen bg-warm-50">
      {/* Header */}
      <div className="bg-white border-b border-warm-200 sticky top-0 z-20">
        <div className="max-w-4xl mx-auto px-4 py-4">
          <div className="flex items-center justify-between mb-4">
            <h1 className="text-2xl font-bold text-warm-900">Messages</h1>
            <button
              onClick={() => setShowNewMessageModal(true)}
              className="p-2 bg-haven-700 text-white rounded-xl hover:bg-haven-800 transition-colors"
            >
              <Plus className="w-5 h-5" />
            </button>
          </div>

          {/* Search */}
          <div className="relative mb-4">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-warm-400" />
            <input
              type="text"
              placeholder="Search messages..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full pl-10 pr-4 py-2.5 border border-warm-200 rounded-xl focus:ring-2 focus:ring-haven-600 focus:border-transparent bg-warm-50"
            />
          </div>

          {/* Tabs */}
          <div className="flex gap-1 p-1 bg-warm-100 rounded-xl">
            <button
              onClick={() => setActiveTab('conversations')}
              className={`flex-1 flex items-center justify-center gap-2 px-4 py-2.5 rounded-lg text-sm font-medium transition-all ${
                activeTab === 'conversations'
                  ? 'bg-white text-warm-900 shadow-sm'
                  : 'text-warm-600 hover:text-warm-900'
              }`}
            >
              <MessageSquare className="w-4 h-4" />
              Conversations
            </button>
            <button
              onClick={() => setActiveTab('projects')}
              className={`flex-1 flex items-center justify-center gap-2 px-4 py-2.5 rounded-lg text-sm font-medium transition-all ${
                activeTab === 'projects'
                  ? 'bg-white text-warm-900 shadow-sm'
                  : 'text-warm-600 hover:text-warm-900'
              }`}
            >
              <FolderOpen className="w-4 h-4" />
              Projects
              {projectConversations.filter(p => p.unreadCount > 0).length > 0 && (
                <span className="px-1.5 py-0.5 bg-haven-600 text-white text-xs rounded-full">
                  {projectConversations.reduce((acc, p) => acc + p.unreadCount, 0)}
                </span>
              )}
            </button>
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="max-w-4xl mx-auto">
        {activeTab === 'conversations' ? (
          <div>
            {/* Category Filter Pills */}
            <div className="px-4 py-3 flex gap-2 overflow-x-auto scrollbar-hide">
              <button
                onClick={() => setSelectedCategory('all')}
                className={`px-4 py-2 rounded-full text-sm font-medium whitespace-nowrap transition-all ${
                  selectedCategory === 'all'
                    ? 'bg-haven-700 text-white'
                    : 'bg-white text-warm-600 border border-warm-200 hover:bg-warm-50'
                }`}
              >
                All
              </button>
              {Object.entries(categoryConfig).map(([key, config]) => {
                const Icon = config.icon;
                return (
                  <button
                    key={key}
                    onClick={() => setSelectedCategory(key as CategoryType)}
                    className={`flex items-center gap-2 px-4 py-2 rounded-full text-sm font-medium whitespace-nowrap transition-all ${
                      selectedCategory === key
                        ? 'bg-haven-700 text-white'
                        : 'bg-white text-warm-600 border border-warm-200 hover:bg-warm-50'
                    }`}
                  >
                    <Icon className="w-4 h-4" />
                    {config.label}
                  </button>
                );
              })}
            </div>

            {/* Pinned Section */}
            {pinnedContacts.length > 0 && selectedCategory === 'all' && (
              <div className="px-4 mb-2">
                <div className="flex items-center gap-2 py-2">
                  <Pin className="w-4 h-4 text-haven-700" />
                  <span className="text-xs font-semibold text-warm-500 uppercase tracking-wide">
                    Pinned
                  </span>
                </div>
                <div className="space-y-1">
                  {pinnedContacts.map(contact => (
                    <ContactRow key={contact.id} contact={contact} />
                  ))}
                </div>
              </div>
            )}

            {/* Grouped Categories */}
            {Object.entries(groupedContacts).map(([category, categoryContacts]) => {
              if (categoryContacts.length === 0) return null;
              if (selectedCategory !== 'all' && selectedCategory !== category) return null;

              const config = categoryConfig[category as CategoryType];
              const Icon = config.icon;

              return (
                <div key={category} className="px-4 mb-2">
                  <div className="flex items-center gap-2 py-2 mt-2">
                    <Icon className={`w-4 h-4 ${config.color}`} />
                    <span className="text-xs font-semibold text-warm-500 uppercase tracking-wide">
                      {config.label}
                    </span>
                  </div>
                  <div className="space-y-1">
                    {categoryContacts.map(contact => (
                      <ContactRow key={contact.id} contact={contact} />
                    ))}
                  </div>
                </div>
              );
            })}
          </div>
        ) : (
          /* Projects Tab */
          <div>
            {/* Project Filter Pills */}
            <div className="px-4 py-3 flex gap-2 overflow-x-auto scrollbar-hide">
              {['all', 'active', 'pending', 'resolved'].map(filter => (
                <button
                  key={filter}
                  onClick={() => setProjectFilter(filter as typeof projectFilter)}
                  className={`px-4 py-2 rounded-full text-sm font-medium whitespace-nowrap transition-all ${
                    projectFilter === filter
                      ? 'bg-haven-700 text-white'
                      : 'bg-white text-warm-600 border border-warm-200 hover:bg-warm-50'
                  }`}
                >
                  {filter === 'all' ? 'All Projects' : filter.charAt(0).toUpperCase() + filter.slice(1)}
                </button>
              ))}
            </div>

            {/* Project List */}
            <div className="px-4 space-y-3">
              {filteredProjects.map(project => (
                <ProjectRow key={project.id} project={project} />
              ))}

              {filteredProjects.length === 0 && (
                <div className="text-center py-12 text-warm-500">
                  No projects found
                </div>
              )}
            </div>
          </div>
        )}
      </div>

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
                        className="w-full pl-9 pr-4 py-2 border border-warm-200 rounded-lg text-sm focus:ring-2 focus:ring-haven-600 focus:border-transparent"
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
                        {contact.id === 'sarah-chen' ? (
                          <ManagerAvatar size="md" />
                        ) : contact.id === 'marcus-johnson' ? (
                          <HandymanAvatar size="md" />
                        ) : contact.id === 'haven-concierge' ? (
                          <ConciergeAvatar size="md" />
                        ) : (
                          <InitialsAvatar name={contact.name} size="md" />
                        )}
                        <div className="flex-1 min-w-0">
                          <p className="font-medium text-warm-900 text-sm">{contact.name}</p>
                          <p className="text-xs text-warm-500 truncate">{contact.role}</p>
                        </div>
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
                        className="flex-1 px-4 py-2 border border-warm-200 rounded-xl text-sm focus:ring-2 focus:ring-haven-600 focus:border-transparent"
                        autoFocus
                      />
                      <button className="px-4 py-2 bg-haven-700 text-white rounded-xl hover:bg-haven-800 transition-colors">
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
    </div>
  );
}

// ============================================================================
// SUB-COMPONENTS
// ============================================================================

function ContactRow({ contact }: { contact: Contact }) {
  // Determine the proper avatar for each contact type
  const renderAvatar = () => {
    if (contact.id === 'sarah-chen') {
      return <ManagerAvatar size="lg" />;
    }
    if (contact.id === 'marcus-johnson') {
      return <HandymanAvatar size="lg" />;
    }
    if (contact.id === 'haven-concierge') {
      return <ConciergeAvatar size="lg" />;
    }
    if (contact.category === 'vendors' || contact.category === 'schools') {
      return <VendorAvatar name={contact.name} size="lg" />;
    }
    // Community neighbors get person avatars
    if (contact.category === 'community') {
      return <PersonAvatar name={contact.name} type={contact.name.includes('Alice') ? 'female' : 'male'} size="lg" />;
    }
    return <InitialsAvatar name={contact.name} size="lg" />;
  };

  return (
    <div className="flex items-center gap-3 p-3 bg-white rounded-xl hover:bg-warm-50 cursor-pointer transition-colors">
      {/* Avatar with online indicator */}
      <div className="relative">
        {renderAvatar()}
        {contact.isOnline && !contact.isHavenTeam && (
          <div className="absolute bottom-0 right-0 w-3 h-3 bg-green-500 rounded-full border-2 border-white" />
        )}
      </div>

      {/* Content */}
      <div className="flex-1 min-w-0">
        <div className="flex items-center gap-2">
          <h3 className="font-medium text-warm-900 truncate">{contact.name}</h3>
          {contact.isPinned && (
            <Pin className="w-3 h-3 text-haven-700 flex-shrink-0" />
          )}
        </div>
        <p className="text-xs text-warm-500 truncate">{contact.role}</p>
        <p className="text-sm text-warm-600 truncate mt-0.5">{contact.lastMessage}</p>
      </div>

      {/* Meta */}
      <div className="flex flex-col items-end gap-1">
        <span className="text-xs text-warm-400">{contact.lastMessageTime}</span>
        {contact.unreadCount > 0 && (
          <span className="px-2 py-0.5 bg-haven-700 text-white text-xs font-medium rounded-full">
            {contact.unreadCount}
          </span>
        )}
      </div>
    </div>
  );
}

function ProjectRow({ project }: { project: ProjectConversation }) {
  const statusColors = {
    active: 'bg-green-100 text-green-700',
    pending: 'bg-amber-100 text-amber-700',
    resolved: 'bg-warm-100 text-warm-600',
  };

  return (
    <div className="bg-white rounded-xl p-4 hover:shadow-md cursor-pointer transition-all border border-warm-100">
      <div className="flex items-start justify-between mb-3">
        <div>
          <div className="flex items-center gap-2">
            <h3 className="font-semibold text-warm-900">{project.title}</h3>
            <span className={`px-2 py-0.5 text-xs font-medium rounded-full ${statusColors[project.status]}`}>
              {project.status}
            </span>
          </div>
          <div className="flex items-center gap-2 mt-1">
            <Hash className="w-3 h-3 text-warm-400" />
            <span className="text-sm text-warm-500">{project.category}</span>
            {project.vendor && (
              <>
                <span className="text-warm-300">•</span>
                <span className="text-sm text-warm-500">{project.vendor}</span>
              </>
            )}
          </div>
        </div>
        {project.unreadCount > 0 && (
          <span className="px-2 py-0.5 bg-haven-700 text-white text-xs font-medium rounded-full">
            {project.unreadCount}
          </span>
        )}
      </div>

      {/* Participants */}
      <div className="flex items-center gap-2 mb-3">
        <div className="flex -space-x-2">
          {project.participants.map((participant, idx) => (
            <div key={idx} className="border-2 border-white rounded-full">
              {participant.role === 'Home Manager' ? (
                <ManagerAvatar size="sm" showBadge={false} />
              ) : participant.role === 'Handyman' ? (
                <HandymanAvatar size="sm" showBadge={false} />
              ) : participant.role === 'Vendor' ? (
                <VendorAvatar name={participant.name} size="sm" />
              ) : (
                <InitialsAvatar name={participant.name} size="sm" />
              )}
            </div>
          ))}
        </div>
        <span className="text-xs text-warm-500">
          {project.participants.map(p => p.name).join(', ')}
        </span>
      </div>

      {/* Last message */}
      <div className="flex items-center justify-between">
        <p className="text-sm text-warm-600 truncate flex-1">{project.lastMessage}</p>
        <span className="text-xs text-warm-400 ml-2 flex-shrink-0">{project.lastMessageTime}</span>
      </div>
    </div>
  );
}

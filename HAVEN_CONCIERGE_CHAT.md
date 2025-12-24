# Haven Concierge Chat Widget - Luxury Redesign

## PROBLEM

The chat bubble widget has:
- Black text on blue background (unreadable)
- Doesn't match the navy + champagne brand
- Doesn't feel premium/luxury

## GOAL

Create a refined, luxury chat experience that:
- Has perfect contrast and readability
- Matches navy + champagne brand
- Feels like a high-end concierge service
- Is functional and intuitive

---

## DESIGN CONCEPT

### Visual Language
- **Background:** Clean white with subtle warm tint
- **Header:** Navy gradient (haven-700 → haven-800)
- **Accents:** Champagne for highlights
- **Typography:** Clear hierarchy, generous spacing
- **Feel:** Private banker, not tech support

### Chat Widget States

```
COLLAPSED (Floating Button):
┌─────────────────┐
│     💬  Chat    │  ← Navy button, white text
│                 │     Subtle champagne glow on hover
└─────────────────┘

EXPANDED (Chat Panel):
┌─────────────────────────────────────┐
│ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ │  ← Navy header
│ ▓  ✨ Haven Concierge          ✕  ▓ │     White text
│ ▓     Here to help 24/7           ▓ │     Champagne sparkle
│ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ │
│                                     │
│  ┌─────────────────────────────┐   │  ← Sarah's message
│  │ ✨ Welcome back, Bob.       │   │     Warm white bg
│  │    How can I help you today?│   │
│  └─────────────────────────────┘   │
│                          10:32 AM   │
│                                     │
│         ┌─────────────────────┐    │  ← User's message
│         │ I need help with    │    │     Navy bg, white text
│         │ the roof repair     │    │
│         └─────────────────────┘    │
│                          10:33 AM   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ ✨ Of course. I see we have │   │
│  │    a pending approval for   │   │
│  │    $1,200. Would you like   │   │
│  │    me to walk you through   │   │
│  │    the quotes?              │   │
│  └─────────────────────────────┘   │
│                                     │
│ ┌─────────────────────────────────┐│
│ │ Type a message...            📎 ││  ← Input area
│ └─────────────────────────────────┘│
│                                     │
│  Quick Actions:                     │
│  ┌─────────┐ ┌─────────┐ ┌───────┐ │
│  │ Approve │ │ Schedule│ │ Call  │ │  ← Champagne buttons
│  └─────────┘ └─────────┘ └───────┘ │
└─────────────────────────────────────┘
```

---

## IMPLEMENTATION

### File: `apps/web/src/components/chat/ConciergeChat.tsx`

```tsx
'use client';

import { useState, useRef, useEffect } from 'react';
import { MessageCircle, X, Send, Paperclip, Phone, Sparkles, ChevronDown } from 'lucide-react';

interface Message {
  id: string;
  text: string;
  sender: 'user' | 'concierge';
  timestamp: Date;
}

export function ConciergeChat() {
  const [isOpen, setIsOpen] = useState(false);
  const [message, setMessage] = useState('');
  const [messages, setMessages] = useState<Message[]>([
    {
      id: '1',
      text: "Welcome back, Bob. How can I help you today?",
      sender: 'concierge',
      timestamp: new Date(),
    },
  ]);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  const handleSend = () => {
    if (!message.trim()) return;
    
    setMessages(prev => [...prev, {
      id: Date.now().toString(),
      text: message,
      sender: 'user',
      timestamp: new Date(),
    }]);
    setMessage('');
    
    // Simulate response (replace with actual API call)
    setTimeout(() => {
      setMessages(prev => [...prev, {
        id: (Date.now() + 1).toString(),
        text: "I'll look into that right away. Give me just a moment.",
        sender: 'concierge',
        timestamp: new Date(),
      }]);
    }, 1000);
  };

  const quickActions = [
    { label: 'Approve pending', action: () => {} },
    { label: 'Schedule service', action: () => {} },
    { label: 'Call Sarah', action: () => {} },
  ];

  return (
    <>
      {/* Floating Button */}
      {!isOpen && (
        <button
          onClick={() => setIsOpen(true)}
          className="fixed bottom-6 right-6 z-50 flex items-center gap-2 px-5 py-3 
                     bg-haven-700 text-white font-medium rounded-full
                     shadow-lg shadow-haven-900/20
                     hover:bg-haven-800 hover:shadow-xl hover:shadow-haven-900/25
                     transition-all duration-200
                     group"
        >
          <MessageCircle className="w-5 h-5" />
          <span>Chat</span>
          {/* Notification dot */}
          <span className="absolute -top-1 -right-1 w-3 h-3 bg-champagne-400 rounded-full 
                          ring-2 ring-white" />
        </button>
      )}

      {/* Chat Panel */}
      {isOpen && (
        <div className="fixed bottom-6 right-6 z-50 w-96 h-[600px] max-h-[80vh]
                        bg-white rounded-2xl shadow-2xl shadow-warm-900/20
                        flex flex-col overflow-hidden
                        border border-warm-200
                        animate-in slide-in-from-bottom-4 duration-200">
          
          {/* Header */}
          <div className="bg-gradient-to-r from-haven-700 to-haven-800 px-5 py-4">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                {/* Concierge Avatar */}
                <div className="w-10 h-10 rounded-full bg-champagne-200 
                                flex items-center justify-center
                                ring-2 ring-champagne-300/50">
                  <Sparkles className="w-5 h-5 text-champagne-600" />
                </div>
                <div>
                  <h3 className="font-semibold text-white">Haven Concierge</h3>
                  <p className="text-xs text-haven-200">Here to help 24/7</p>
                </div>
              </div>
              <div className="flex items-center gap-2">
                <button 
                  onClick={() => {/* Open phone */}}
                  className="p-2 text-white/70 hover:text-white hover:bg-white/10 
                             rounded-lg transition-colors"
                >
                  <Phone className="w-5 h-5" />
                </button>
                <button 
                  onClick={() => setIsOpen(false)}
                  className="p-2 text-white/70 hover:text-white hover:bg-white/10 
                             rounded-lg transition-colors"
                >
                  <X className="w-5 h-5" />
                </button>
              </div>
            </div>
          </div>

          {/* Messages Area */}
          <div className="flex-1 overflow-y-auto p-4 space-y-4 bg-warm-50">
            {messages.map((msg) => (
              <div
                key={msg.id}
                className={`flex ${msg.sender === 'user' ? 'justify-end' : 'justify-start'}`}
              >
                <div className={`max-w-[80%] ${msg.sender === 'user' ? 'order-1' : 'order-2'}`}>
                  {/* Avatar for concierge messages */}
                  {msg.sender === 'concierge' && (
                    <div className="flex items-start gap-2">
                      <div className="w-8 h-8 rounded-full bg-champagne-100 
                                      flex items-center justify-center flex-shrink-0">
                        <Sparkles className="w-4 h-4 text-champagne-600" />
                      </div>
                      <div>
                        <div className="bg-white rounded-2xl rounded-tl-sm px-4 py-3 
                                        shadow-sm border border-warm-100">
                          <p className="text-warm-800 text-sm leading-relaxed">{msg.text}</p>
                        </div>
                        <p className="text-xs text-warm-400 mt-1 ml-2">
                          {msg.timestamp.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                        </p>
                      </div>
                    </div>
                  )}
                  
                  {/* User messages */}
                  {msg.sender === 'user' && (
                    <div>
                      <div className="bg-haven-700 text-white rounded-2xl rounded-tr-sm px-4 py-3">
                        <p className="text-sm leading-relaxed">{msg.text}</p>
                      </div>
                      <p className="text-xs text-warm-400 mt-1 mr-2 text-right">
                        {msg.timestamp.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                      </p>
                    </div>
                  )}
                </div>
              </div>
            ))}
            <div ref={messagesEndRef} />
          </div>

          {/* Quick Actions */}
          <div className="px-4 py-2 bg-white border-t border-warm-100">
            <div className="flex gap-2 overflow-x-auto pb-1 scrollbar-hide">
              {quickActions.map((action, idx) => (
                <button
                  key={idx}
                  onClick={action.action}
                  className="flex-shrink-0 px-3 py-1.5 text-xs font-medium
                             bg-champagne-100 text-champagne-700 
                             hover:bg-champagne-200
                             rounded-full transition-colors"
                >
                  {action.label}
                </button>
              ))}
            </div>
          </div>

          {/* Input Area */}
          <div className="p-4 bg-white border-t border-warm-100">
            <div className="flex items-center gap-2">
              <button className="p-2 text-warm-400 hover:text-warm-600 
                                 hover:bg-warm-100 rounded-lg transition-colors">
                <Paperclip className="w-5 h-5" />
              </button>
              <input
                type="text"
                value={message}
                onChange={(e) => setMessage(e.target.value)}
                onKeyDown={(e) => e.key === 'Enter' && handleSend()}
                placeholder="Type a message..."
                className="flex-1 px-4 py-2.5 bg-warm-50 border border-warm-200 
                           rounded-xl text-sm
                           placeholder:text-warm-400
                           focus:outline-none focus:border-haven-500 focus:ring-2 focus:ring-haven-500/20
                           transition-all"
              />
              <button
                onClick={handleSend}
                disabled={!message.trim()}
                className="p-2.5 bg-haven-700 text-white rounded-xl
                           hover:bg-haven-800 disabled:opacity-50 disabled:cursor-not-allowed
                           transition-colors"
              >
                <Send className="w-5 h-5" />
              </button>
            </div>
          </div>
        </div>
      )}
    </>
  );
}

export default ConciergeChat;
```

---

## COLOR SPECIFICATIONS

| Element | Light Mode | Notes |
|---------|------------|-------|
| **Button (collapsed)** | `bg-haven-700` | Navy, white text |
| **Button hover** | `bg-haven-800` | Darker navy |
| **Notification dot** | `bg-champagne-400` | Warm attention |
| **Header** | `from-haven-700 to-haven-800` | Navy gradient |
| **Header text** | `text-white` | Primary |
| **Header subtext** | `text-haven-200` | Secondary |
| **Concierge avatar** | `bg-champagne-200` | Warm, inviting |
| **Concierge icon** | `text-champagne-600` | Sparkles |
| **Messages background** | `bg-warm-50` | Warm off-white |
| **Concierge bubble** | `bg-white` | Clean |
| **User bubble** | `bg-haven-700` | Navy, white text |
| **Quick actions** | `bg-champagne-100 text-champagne-700` | Champagne pills |
| **Input background** | `bg-warm-50` | Subtle |
| **Send button** | `bg-haven-700` | Navy |

---

## INTEGRATION

### Add to App Layout

**File:** `apps/web/src/app/app/layout.tsx`

```tsx
import { ConciergeChat } from '@/components/chat/ConciergeChat';

export default function AppLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="...">
      {/* Sidebar */}
      {/* Main content */}
      {children}
      
      {/* Concierge Chat - Always available */}
      <ConciergeChat />
    </div>
  );
}
```

---

## LUXURY DETAILS

### Micro-interactions
- Button has subtle shadow that grows on hover
- Panel slides up smoothly when opened
- Messages fade in gently
- Typing indicator with elegant animation

### Typography
- Clean, readable 14px for messages
- Generous line height (1.5+)
- Proper contrast ratios (WCAG AA)

### Spacing
- Generous padding throughout
- Messages don't feel cramped
- Clear visual hierarchy

---

## ALTERNATIVE: UPDATE EXISTING WIDGET

If there's an existing chat widget file, search for it:

```bash
grep -r "Haven Concierge\|chat.*widget\|ChatWidget\|ConciergeChat" apps/web/src --include="*.tsx"
```

Then apply these color fixes:

```tsx
// WRONG (unreadable)
className="bg-blue-600 text-black"

// CORRECT
className="bg-haven-700 text-white"

// Header should be:
className="bg-gradient-to-r from-haven-700 to-haven-800"

// All text on dark backgrounds:
className="text-white" // primary
className="text-haven-200" // secondary

// Concierge avatar:
className="bg-champagne-200"
<Sparkles className="text-champagne-600" />
```

---

## EXECUTION

```bash
cd /Users/tomburke/Projects/Housing-Manager
claude --dangerously-skip-permissions
```

Paste:

```
Fix the Haven Concierge chat widget for luxury experience:

1. Find the existing chat widget component (search for "Haven Concierge", "ChatWidget", "chat bubble")

2. Fix contrast issues:
   - Header: bg-gradient-to-r from-haven-700 to-haven-800
   - Header text: text-white (NOT black)
   - Subtext: text-haven-200

3. Update colors to match brand:
   - Floating button: bg-haven-700 text-white
   - Concierge avatar: bg-champagne-200 with Sparkles icon in text-champagne-600
   - User messages: bg-haven-700 text-white
   - Concierge messages: bg-white with warm-800 text
   - Quick action buttons: bg-champagne-100 text-champagne-700
   - Send button: bg-haven-700
   - Messages area background: bg-warm-50

4. If no existing component, create apps/web/src/components/chat/ConciergeChat.tsx with the full implementation from HAVEN_CONCIERGE_CHAT.md

5. Ensure it's included in the app layout

The chat should feel like a luxury concierge service, not tech support.

Run pnpm build to verify.
```

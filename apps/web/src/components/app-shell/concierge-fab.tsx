'use client';

import { useState, useRef, useEffect } from 'react';
import { MessageCircle, X, Send, Minimize2, Phone, Paperclip, Sparkles } from 'lucide-react';

interface Message {
  id: string;
  content: string;
  sender: 'user' | 'concierge';
  timestamp: Date;
}

export function ConciergeFab() {
  const [isOpen, setIsOpen] = useState(false);
  const [messages, setMessages] = useState<Message[]>([
    {
      id: '1',
      content: "Welcome back! How can I help you today?",
      sender: 'concierge',
      timestamp: new Date(),
    },
  ]);
  const [inputValue, setInputValue] = useState('');
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const inputRef = useRef<HTMLInputElement>(null);

  // Scroll to bottom when messages change
  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  // Focus input when chat opens
  useEffect(() => {
    if (isOpen) {
      inputRef.current?.focus();
    }
  }, [isOpen]);

  const handleSend = () => {
    if (!inputValue.trim()) return;

    const userMessage: Message = {
      id: Date.now().toString(),
      content: inputValue,
      sender: 'user',
      timestamp: new Date(),
    };

    setMessages((prev) => [...prev, userMessage]);
    setInputValue('');

    // Simulate concierge response
    setTimeout(() => {
      const conciergeMessage: Message = {
        id: (Date.now() + 1).toString(),
        content: "I'll look into that right away. Give me just a moment.",
        sender: 'concierge',
        timestamp: new Date(),
      };
      setMessages((prev) => [...prev, conciergeMessage]);
    }, 1000);
  };

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      handleSend();
    }
  };

  const quickActions = [
    { label: 'Approve pending', action: () => {} },
    { label: 'Schedule service', action: () => {} },
    { label: 'Call Sarah', action: () => {} },
  ];

  return (
    <>
      {/* Chat Popover */}
      {isOpen && (
        <div className="fixed bottom-36 lg:bottom-24 right-4 lg:right-6 w-[calc(100vw-2rem)] sm:w-[380px] h-[500px] lg:h-[560px] bg-white rounded-2xl shadow-2xl shadow-warm-900/20 border border-warm-200 flex flex-col z-50 overflow-hidden animate-in slide-in-from-bottom-4 duration-200">
          {/* Header - Navy gradient */}
          <div className="bg-gradient-to-r from-haven-700 to-haven-800 px-4 py-4">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                {/* Concierge Avatar - Champagne with Sparkles */}
                <div className="w-10 h-10 rounded-full bg-champagne-200 flex items-center justify-center ring-2 ring-champagne-300/50">
                  <Sparkles className="w-5 h-5 text-champagne-600" />
                </div>
                <div>
                  <h3 className="font-semibold text-white text-sm">Haven Concierge</h3>
                  <p className="text-xs text-haven-200">Here to help 24/7</p>
                </div>
              </div>
              <div className="flex items-center gap-1">
                <button
                  onClick={() => {/* Open phone */}}
                  className="p-2 text-white/70 hover:text-white hover:bg-white/10 rounded-lg transition-colors"
                  aria-label="Call"
                >
                  <Phone className="w-4 h-4" />
                </button>
                <button
                  onClick={() => setIsOpen(false)}
                  className="p-2 text-white/70 hover:text-white hover:bg-white/10 rounded-lg transition-colors"
                  aria-label="Minimize"
                >
                  <Minimize2 className="w-4 h-4" />
                </button>
                <button
                  onClick={() => setIsOpen(false)}
                  className="p-2 text-white/70 hover:text-white hover:bg-white/10 rounded-lg transition-colors"
                  aria-label="Close"
                >
                  <X className="w-4 h-4" />
                </button>
              </div>
            </div>
          </div>

          {/* Messages - Warm background */}
          <div className="flex-1 overflow-y-auto p-4 space-y-4 bg-warm-50">
            {messages.map((message) => (
              <div
                key={message.id}
                className={`flex ${message.sender === 'user' ? 'justify-end' : 'justify-start'}`}
              >
                {/* Concierge messages */}
                {message.sender === 'concierge' && (
                  <div className="flex items-start gap-2 max-w-[85%]">
                    <div className="w-8 h-8 rounded-full bg-champagne-100 flex items-center justify-center flex-shrink-0">
                      <Sparkles className="w-4 h-4 text-champagne-600" />
                    </div>
                    <div>
                      <div className="bg-white rounded-2xl rounded-tl-sm px-4 py-3 shadow-sm border border-warm-100">
                        <p className="text-warm-800 text-sm leading-relaxed">{message.content}</p>
                      </div>
                      <p className="text-xs text-warm-400 mt-1 ml-2">
                        {message.timestamp.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                      </p>
                    </div>
                  </div>
                )}

                {/* User messages */}
                {message.sender === 'user' && (
                  <div className="max-w-[80%]">
                    <div className="bg-haven-700 text-white rounded-2xl rounded-tr-sm px-4 py-3">
                      <p className="text-sm leading-relaxed">{message.content}</p>
                    </div>
                    <p className="text-xs text-warm-400 mt-1 mr-2 text-right">
                      {message.timestamp.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                    </p>
                  </div>
                )}
              </div>
            ))}
            <div ref={messagesEndRef} />
          </div>

          {/* Quick Actions - Champagne pills */}
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
          <div className="p-4 border-t border-warm-100 bg-white">
            <div className="flex items-center gap-2">
              <button className="p-2 text-warm-400 hover:text-warm-600 hover:bg-warm-100 rounded-lg transition-colors">
                <Paperclip className="w-5 h-5" />
              </button>
              <input
                ref={inputRef}
                type="text"
                value={inputValue}
                onChange={(e) => setInputValue(e.target.value)}
                onKeyDown={handleKeyDown}
                placeholder="Type a message..."
                className="flex-1 px-4 py-2.5 bg-warm-50 border border-warm-200
                           rounded-xl text-sm
                           placeholder:text-warm-400
                           focus:outline-none focus:border-haven-500 focus:ring-2 focus:ring-haven-500/20
                           transition-all"
              />
              <button
                onClick={handleSend}
                disabled={!inputValue.trim()}
                className="p-2.5 bg-haven-700 text-white rounded-xl
                           hover:bg-haven-800 disabled:opacity-50 disabled:cursor-not-allowed
                           transition-colors"
                aria-label="Send message"
              >
                <Send className="w-5 h-5" />
              </button>
            </div>
          </div>
        </div>
      )}

      {/* FAB Button - Navy with champagne notification dot */}
      <button
        onClick={() => setIsOpen(!isOpen)}
        className={`fixed bottom-20 lg:bottom-6 right-4 lg:right-6 z-50 transition-all duration-200 ${
          isOpen
            ? 'w-14 h-14 rounded-full bg-warm-800 hover:bg-warm-700 shadow-lg'
            : 'flex items-center gap-2 px-5 py-3 bg-haven-700 hover:bg-haven-800 rounded-full shadow-lg shadow-haven-900/20 hover:shadow-xl hover:shadow-haven-900/25'
        }`}
        aria-label={isOpen ? 'Close chat' : 'Open chat'}
      >
        {isOpen ? (
          <X className="w-6 h-6 text-white" />
        ) : (
          <>
            <MessageCircle className="w-5 h-5 text-white" />
            <span className="text-white font-medium">Chat</span>
            {/* Notification dot */}
            <span className="absolute -top-1 -right-1 w-3 h-3 bg-champagne-400 rounded-full ring-2 ring-white" />
          </>
        )}
      </button>
    </>
  );
}

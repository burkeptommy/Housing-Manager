'use client';

import { useState, useMemo, useCallback, useEffect, useRef } from 'react';
import {
  ShoppingCart,
  Package,
  Plus,
  Search,
  Check,
  X,
  Clock,
  AlertTriangle,
  CheckCircle2,
  Store,
  Home,
  Apple,
  Milk,
  Beef,
  Croissant,
  Wine,
  Sparkles,
  Wrench,
  Pill,
  Baby,
  Dog,
  Snowflake,
  BoxIcon,
  RefreshCw,
  Mic,
  MicOff,
  ChevronRight,
  Headphones,
  ToggleLeft,
  ToggleRight,
} from 'lucide-react';
import { useAuth } from '@/contexts/auth-context';
import { getDemoImage } from '@/lib/imageUtils';

// ============================================================================
// TYPES
// ============================================================================

type ItemCategory = 'produce' | 'dairy' | 'meat' | 'bakery' | 'beverages' | 'pantry' | 'frozen' | 'household' | 'health' | 'baby' | 'pet' | 'other';
type ShoppingStatus = 'NEEDED' | 'IN_CART' | 'ORDERED' | 'DELIVERED';
type OrderSource = 'Amazon' | 'Instacart' | 'Costco' | 'Whole Foods' | 'Handyman' | 'Other';
type ViewMode = 'shopping' | 'inventory' | 'auto-reorder';

interface ShoppingList {
  id: string;
  name: string;
  icon: typeof ShoppingCart;
  status: ShoppingStatus;
  statusMessage: string;
  itemCount: number;
  orderSource?: OrderSource;
  expectedDelivery?: string;
  isDeliveredToday?: boolean;
}

interface ShoppingItem {
  id: string;
  listId: string;
  name: string;
  quantity: string;
  category: ItemCategory;
  status: ShoppingStatus;
  addedAt: Date;
  orderedVia?: OrderSource;
  orderedAt?: Date;
  deliveredAt?: Date;
  cost?: number;
}

interface InventoryItem {
  id: string;
  name: string;
  category: ItemCategory;
  currentLevel: number;
  minLevel: number;
  unit: string;
  location?: string;
  isLow: boolean;
  onShoppingList: boolean;
}

interface AutoReorderItem {
  id: string;
  name: string;
  category: ItemCategory;
  frequency: 'weekly' | 'biweekly' | 'monthly' | 'quarterly';
  lastOrdered?: Date;
  nextOrder?: Date;
  enabled: boolean;
  preferredSource?: OrderSource;
}

// ============================================================================
// CONSTANTS
// ============================================================================

const HOUSING_MANAGER = {
  name: 'Sarah',
  avatar: getDemoImage('avatar-female', 100, 100, 'sarah-manager'),
};

const CATEGORIES: Record<ItemCategory, { label: string; icon: typeof Apple; color: string }> = {
  produce: { label: 'Produce', icon: Apple, color: 'text-green-600 bg-green-50' },
  dairy: { label: 'Dairy', icon: Milk, color: 'text-blue-600 bg-blue-50' },
  meat: { label: 'Meat & Seafood', icon: Beef, color: 'text-red-600 bg-red-50' },
  bakery: { label: 'Bakery', icon: Croissant, color: 'text-amber-600 bg-amber-50' },
  beverages: { label: 'Beverages', icon: Wine, color: 'text-purple-600 bg-purple-50' },
  pantry: { label: 'Pantry', icon: BoxIcon, color: 'text-orange-600 bg-orange-50' },
  frozen: { label: 'Frozen', icon: Snowflake, color: 'text-cyan-600 bg-cyan-50' },
  household: { label: 'Household', icon: Home, color: 'text-warm-600 bg-warm-50' },
  health: { label: 'Health & Beauty', icon: Pill, color: 'text-pink-600 bg-pink-50' },
  baby: { label: 'Baby', icon: Baby, color: 'text-sky-600 bg-sky-50' },
  pet: { label: 'Pet Supplies', icon: Dog, color: 'text-yellow-600 bg-yellow-50' },
  other: { label: 'Other', icon: Sparkles, color: 'text-gray-600 bg-gray-50' },
};

// Auto-categorization and list suggestion keywords
const CATEGORY_KEYWORDS: Record<string, { category: ItemCategory; suggestedList?: string }> = {
  // Produce
  apple: { category: 'produce', suggestedList: 'Weekly Groceries' },
  banana: { category: 'produce', suggestedList: 'Weekly Groceries' },
  lettuce: { category: 'produce', suggestedList: 'Weekly Groceries' },
  tomato: { category: 'produce', suggestedList: 'Weekly Groceries' },
  // Dairy
  milk: { category: 'dairy', suggestedList: 'Weekly Groceries' },
  cheese: { category: 'dairy', suggestedList: 'Weekly Groceries' },
  yogurt: { category: 'dairy', suggestedList: 'Weekly Groceries' },
  eggs: { category: 'dairy', suggestedList: 'Weekly Groceries' },
  // Meat
  chicken: { category: 'meat', suggestedList: 'Weekly Groceries' },
  beef: { category: 'meat', suggestedList: 'Costco Run' },
  salmon: { category: 'meat', suggestedList: 'Weekly Groceries' },
  // Household - often bulk or hardware
  'paper towel': { category: 'household', suggestedList: 'Costco Run' },
  'toilet paper': { category: 'household', suggestedList: 'Costco Run' },
  battery: { category: 'household', suggestedList: 'Hardware Store' },
  batteries: { category: 'household', suggestedList: 'Hardware Store' },
  'light bulb': { category: 'household', suggestedList: 'Hardware Store' },
  lightbulb: { category: 'household', suggestedList: 'Hardware Store' },
  filter: { category: 'household', suggestedList: 'Hardware Store' },
  'hvac filter': { category: 'household', suggestedList: 'Hardware Store' },
  'trash bag': { category: 'household', suggestedList: 'Costco Run' },
  detergent: { category: 'household', suggestedList: 'Costco Run' },
  // Pet
  'dog food': { category: 'pet', suggestedList: 'Costco Run' },
  'cat food': { category: 'pet', suggestedList: 'Pet Supplies' },
  'pet food': { category: 'pet', suggestedList: 'Pet Supplies' },
  litter: { category: 'pet', suggestedList: 'Pet Supplies' },
  // Health
  vitamin: { category: 'health', suggestedList: 'Amazon' },
  medicine: { category: 'health', suggestedList: 'Pharmacy' },
  shampoo: { category: 'health', suggestedList: 'Weekly Groceries' },
  toothpaste: { category: 'health', suggestedList: 'Weekly Groceries' },
};

// Quick pick suggestions
const QUICK_PICKS = [
  'Paper towels',
  'Milk',
  'Batteries',
  'Dog food',
  'Light bulbs',
  'Trash bags',
];

// ============================================================================
// MOCK DATA
// ============================================================================

const MOCK_LISTS: ShoppingList[] = [
  {
    id: 'list-1',
    name: 'Weekly Groceries',
    icon: ShoppingCart,
    status: 'IN_CART',
    statusMessage: 'In Instacart cart',
    itemCount: 12,
    orderSource: 'Instacart',
  },
  {
    id: 'list-2',
    name: 'Costco Run',
    icon: Store,
    status: 'DELIVERED',
    statusMessage: 'Delivered today!',
    itemCount: 6,
    orderSource: 'Costco',
    isDeliveredToday: true,
  },
  {
    id: 'list-3',
    name: 'Hardware Store',
    icon: Wrench,
    status: 'ORDERED',
    statusMessage: 'Handyman picking up Tue',
    itemCount: 3,
    orderSource: 'Handyman',
    expectedDelivery: 'Tuesday',
  },
  {
    id: 'list-4',
    name: 'Amazon',
    icon: Package,
    status: 'ORDERED',
    statusMessage: 'Arriving Friday',
    itemCount: 4,
    orderSource: 'Amazon',
    expectedDelivery: 'Friday, Dec 27',
  },
];

const MOCK_ITEMS: ShoppingItem[] = [
  // Weekly Groceries (IN_CART)
  { id: 'item-1', listId: 'list-1', name: 'Organic Whole Milk', quantity: '1 Gal', category: 'dairy', status: 'IN_CART', addedAt: new Date() },
  { id: 'item-2', listId: 'list-1', name: 'Free-Range Eggs', quantity: '1 Dozen', category: 'dairy', status: 'IN_CART', addedAt: new Date() },
  { id: 'item-3', listId: 'list-1', name: 'Avocados', quantity: '4', category: 'produce', status: 'IN_CART', addedAt: new Date() },
  { id: 'item-4', listId: 'list-1', name: 'Bananas', quantity: '1 Bunch', category: 'produce', status: 'IN_CART', addedAt: new Date() },
  { id: 'item-5', listId: 'list-1', name: 'Sourdough Bread', quantity: '1 Loaf', category: 'bakery', status: 'IN_CART', addedAt: new Date() },
  // Costco (DELIVERED)
  { id: 'item-20', listId: 'list-2', name: 'Toilet Paper', quantity: '30 Pack', category: 'household', status: 'DELIVERED', addedAt: new Date(), deliveredAt: new Date(), cost: 24.99 },
  { id: 'item-21', listId: 'list-2', name: 'Kirkland Water', quantity: '40 Pack', category: 'beverages', status: 'DELIVERED', addedAt: new Date(), deliveredAt: new Date(), cost: 4.99 },
  { id: 'item-22', listId: 'list-2', name: 'Dog Food', quantity: '40 lb', category: 'pet', status: 'DELIVERED', addedAt: new Date(), deliveredAt: new Date(), cost: 42.99 },
  // Hardware (ORDERED - Handyman picking up)
  { id: 'item-30', listId: 'list-3', name: 'HVAC Filters (20x25)', quantity: '4 Pack', category: 'household', status: 'ORDERED', addedAt: new Date(), orderedVia: 'Handyman' },
  { id: 'item-31', listId: 'list-3', name: 'LED Bulbs (60W)', quantity: '8 Pack', category: 'household', status: 'ORDERED', addedAt: new Date(), orderedVia: 'Handyman' },
  { id: 'item-32', listId: 'list-3', name: 'Smoke Detector Batteries', quantity: '6', category: 'household', status: 'ORDERED', addedAt: new Date(), orderedVia: 'Handyman' },
  // Amazon (ORDERED)
  { id: 'item-40', listId: 'list-4', name: 'Vitamins D3', quantity: '1 Bottle', category: 'health', status: 'ORDERED', addedAt: new Date(), orderedVia: 'Amazon' },
  { id: 'item-41', listId: 'list-4', name: 'Dish Soap', quantity: '3 Pack', category: 'household', status: 'ORDERED', addedAt: new Date(), orderedVia: 'Amazon' },
];

const MOCK_INVENTORY: InventoryItem[] = [
  { id: 'inv-1', name: 'AA Batteries', category: 'household', currentLevel: 8, minLevel: 4, unit: 'count', location: 'Utility Drawer', isLow: false, onShoppingList: false },
  { id: 'inv-2', name: 'AAA Batteries', category: 'household', currentLevel: 2, minLevel: 4, unit: 'count', location: 'Utility Drawer', isLow: true, onShoppingList: true },
  { id: 'inv-3', name: 'Light Bulbs (60W)', category: 'household', currentLevel: 4, minLevel: 4, unit: 'bulbs', location: 'Garage', isLow: false, onShoppingList: false },
  { id: 'inv-4', name: 'Trash Bags (13 Gal)', category: 'household', currentLevel: 1, minLevel: 20, unit: 'bags', location: 'Under Sink', isLow: true, onShoppingList: true },
  { id: 'inv-5', name: 'Paper Towels', category: 'household', currentLevel: 3, minLevel: 6, unit: 'rolls', location: 'Kitchen Pantry', isLow: true, onShoppingList: true },
  { id: 'inv-6', name: 'HVAC Filters', category: 'household', currentLevel: 1, minLevel: 2, unit: 'filters', location: 'Garage', isLow: true, onShoppingList: true },
  { id: 'inv-7', name: 'Dog Food', category: 'pet', currentLevel: 40, minLevel: 10, unit: 'lbs', location: 'Pantry', isLow: false, onShoppingList: false },
  { id: 'inv-8', name: 'Dish Soap', category: 'household', currentLevel: 2, minLevel: 2, unit: 'bottles', location: 'Under Sink', isLow: false, onShoppingList: false },
];

const MOCK_AUTO_REORDER: AutoReorderItem[] = [
  { id: 'auto-1', name: 'Blue Buffalo Dog Food (30lb)', category: 'pet', frequency: 'monthly', enabled: true, preferredSource: 'Costco', lastOrdered: new Date('2024-11-20'), nextOrder: new Date('2024-12-20') },
  { id: 'auto-2', name: 'HVAC Filters (4-pack)', category: 'household', frequency: 'quarterly', enabled: true, preferredSource: 'Amazon', lastOrdered: new Date('2024-09-15'), nextOrder: new Date('2024-12-15') },
  { id: 'auto-3', name: 'Paper Towels (12-roll)', category: 'household', frequency: 'monthly', enabled: false, preferredSource: 'Costco' },
  { id: 'auto-4', name: 'Trash Bags (100 count)', category: 'household', frequency: 'biweekly', enabled: true, preferredSource: 'Amazon', lastOrdered: new Date('2024-12-05'), nextOrder: new Date('2024-12-19') },
];

// ============================================================================
// UTILITY FUNCTIONS
// ============================================================================

function categorizeItem(name: string): { category: ItemCategory; suggestedList?: string } {
  const lowerName = name.toLowerCase();
  for (const [keyword, info] of Object.entries(CATEGORY_KEYWORDS)) {
    if (lowerName.includes(keyword)) return info;
  }
  return { category: 'other' };
}

function parseItemInput(input: string): { name: string; quantity: string }[] {
  // Split by comma, "and", "&"
  const parts = input.split(/,|\band\b|&/i).map(p => p.trim()).filter(p => p.length > 0);
  return parts.map(part => {
    // Try to extract quantity
    const qtyMatch = part.match(/^(\d+\s*(?:lb|lbs|oz|gal|gallons?|pack|dozen|count|rolls?|bottles?)?)\s+(?:of\s+)?(.+)$/i);
    if (qtyMatch && qtyMatch[1] && qtyMatch[2]) {
      return { quantity: qtyMatch[1], name: qtyMatch[2] };
    }
    const qtyEndMatch = part.match(/^(.+?)\s+(\d+\s*(?:lb|lbs|oz|gal|gallons?|pack|dozen|count|rolls?|bottles?)?)$/i);
    if (qtyEndMatch && qtyEndMatch[1] && qtyEndMatch[2]) {
      return { quantity: qtyEndMatch[2], name: qtyEndMatch[1] };
    }
    return { quantity: '1', name: part };
  });
}

function getStatusIcon(status: ShoppingStatus) {
  switch (status) {
    case 'NEEDED': return <Clock className="w-4 h-4" />;
    case 'IN_CART': return <ShoppingCart className="w-4 h-4" />;
    case 'ORDERED': return <Package className="w-4 h-4" />;
    case 'DELIVERED': return <CheckCircle2 className="w-4 h-4" />;
  }
}

function getStatusColor(status: ShoppingStatus) {
  switch (status) {
    case 'NEEDED': return 'bg-warm-100 text-warm-700';
    case 'IN_CART': return 'bg-blue-100 text-blue-700';
    case 'ORDERED': return 'bg-amber-100 text-amber-700';
    case 'DELIVERED': return 'bg-emerald-100 text-emerald-700';
  }
}

// ============================================================================
// COMPONENTS
// ============================================================================

// Quick Add Input - The primary way homeowners add items
function QuickAddInput({
  onAdd,
  isSubmitting,
}: {
  onAdd: (items: { name: string; quantity: string }[]) => void;
  isSubmitting: boolean;
}) {
  const [input, setInput] = useState('');
  const [isListening, setIsListening] = useState(false);
  const inputRef = useRef<HTMLInputElement>(null);

  const handleVoiceInput = () => {
    setIsListening(!isListening);
    if (!isListening) {
      // Simulate voice input
      setTimeout(() => {
        setInput('Paper towels, batteries, and dog food');
        setIsListening(false);
      }, 2000);
    }
  };

  const handleSubmit = () => {
    if (!input.trim() || isSubmitting) return;
    const parsedItems = parseItemInput(input);
    onAdd(parsedItems);
    setInput('');
  };

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      handleSubmit();
    }
  };

  const handleQuickPick = (item: string) => {
    const current = input.trim();
    if (current) {
      setInput(current + ', ' + item);
    } else {
      setInput(item);
    }
    inputRef.current?.focus();
  };

  return (
    <div className="bg-white rounded-2xl border border-warm-200 shadow-sm overflow-hidden">
      <div className="p-4 pb-2">
        <h2 className="text-lg font-semibold text-warm-900 mb-3">What do you need?</h2>
        <div className="flex items-center gap-3">
          <input
            ref={inputRef}
            type="text"
            value={input}
            onChange={(e) => setInput(e.target.value)}
            onKeyDown={handleKeyDown}
            placeholder="Paper towels, batteries, dog food..."
            className="flex-1 text-lg bg-transparent border-none outline-none placeholder:text-warm-400"
            disabled={isSubmitting}
          />
          <button
            onClick={handleVoiceInput}
            className={`p-2 rounded-full transition-colors ${
              isListening
                ? 'bg-red-100 text-red-600 animate-pulse'
                : 'bg-warm-100 text-warm-500 hover:bg-warm-200'
            }`}
            disabled={isSubmitting}
          >
            {isListening ? <MicOff className="w-5 h-5" /> : <Mic className="w-5 h-5" />}
          </button>
          {input.trim() && (
            <button
              onClick={handleSubmit}
              disabled={isSubmitting}
              className="px-4 py-2 bg-emerald-600 text-white rounded-lg hover:bg-emerald-700 transition-colors font-medium disabled:opacity-50"
            >
              Add Items
            </button>
          )}
        </div>
        {isListening && (
          <div className="mt-2 flex items-center gap-2 text-red-600">
            <div className="w-2 h-2 bg-red-500 rounded-full animate-pulse" />
            <span className="text-sm">Listening...</span>
          </div>
        )}
      </div>

      <div className="px-4 pb-4">
        <p className="text-xs text-warm-500 mb-2">Tip: Separate with commas or say &quot;and&quot;</p>
        <div className="flex flex-wrap gap-2">
          {QUICK_PICKS.map((pick) => (
            <button
              key={pick}
              onClick={() => handleQuickPick(pick)}
              className="px-3 py-1.5 bg-warm-50 text-warm-600 rounded-full text-sm hover:bg-warm-100 transition-colors"
              disabled={isSubmitting}
            >
              + {pick}
            </button>
          ))}
        </div>
      </div>
    </div>
  );
}

// Manager Summary - Shows Sarah is handling procurement
function ManagerSummary({
  totalItems,
  listsInProgress,
}: {
  totalItems: number;
  listsInProgress: number;
}) {
  return (
    <div className="bg-gradient-to-br from-emerald-600 to-emerald-700 rounded-xl p-4 text-white">
      <div className="flex items-center gap-3">
        <div className="relative">
          <div className="w-12 h-12 rounded-full bg-white/20 flex items-center justify-center">
            <Headphones className="w-6 h-6" />
          </div>
          <div className="absolute -bottom-0.5 -right-0.5 w-4 h-4 bg-emerald-400 rounded-full flex items-center justify-center">
            <Check className="w-2.5 h-2.5 text-white" />
          </div>
        </div>
        <div className="flex-1">
          <p className="font-semibold">
            {HOUSING_MANAGER.name} is handling {totalItems} items
          </p>
          <p className="text-emerald-100 text-sm">
            {listsInProgress} {listsInProgress === 1 ? 'order' : 'orders'} in progress
          </p>
        </div>
      </div>
    </div>
  );
}

// List Status Card - Shows status for each shopping list
function ListStatusCard({
  list,
  onClick,
  isActive,
}: {
  list: ShoppingList;
  onClick: () => void;
  isActive: boolean;
}) {
  const ListIcon = list.icon;

  const getStatusEmoji = () => {
    switch (list.status) {
      case 'IN_CART': return '🛒';
      case 'ORDERED': return '⏳';
      case 'DELIVERED': return '📦';
      default: return '📝';
    }
  };

  return (
    <button
      onClick={onClick}
      className={`w-full flex items-center gap-3 p-4 rounded-xl transition-all text-left ${
        isActive
          ? 'bg-emerald-50 border-2 border-emerald-500'
          : list.isDeliveredToday
          ? 'bg-emerald-50 border border-emerald-200'
          : 'bg-white border border-warm-200 hover:border-warm-300'
      }`}
    >
      <div className={`p-2 rounded-lg ${isActive ? 'bg-emerald-100' : 'bg-warm-100'}`}>
        <ListIcon className={`w-5 h-5 ${isActive ? 'text-emerald-600' : 'text-warm-600'}`} />
      </div>
      <div className="flex-1 min-w-0">
        <div className="font-medium text-warm-900">{list.name}</div>
        <div className="text-sm text-warm-500">{list.itemCount} items</div>
      </div>
      <div className="text-right">
        <div className="text-lg">{getStatusEmoji()}</div>
        <div className="text-xs text-warm-500">{list.statusMessage}</div>
      </div>
    </button>
  );
}

// Inventory Level Card
function InventoryLevelCard({
  item,
  onAddToList,
}: {
  item: InventoryItem;
  onAddToList: () => void;
}) {
  const catConfig = CATEGORIES[item.category];
  const CatIcon = catConfig.icon;

  const getStatusIcon = () => {
    if (item.isLow && item.onShoppingList) return '⚠️';
    if (item.isLow) return '⚠️';
    return '✓';
  };

  const getStatusText = () => {
    if (item.isLow && item.onShoppingList) return 'Low - on list';
    if (item.isLow) return 'Low';
    return 'Good';
  };

  return (
    <div className={`flex items-center gap-3 p-3 rounded-lg ${item.isLow ? 'bg-amber-50' : 'bg-white'}`}>
      <div className={`p-2 rounded-lg ${catConfig.color}`}>
        <CatIcon className="w-4 h-4" />
      </div>
      <div className="flex-1 min-w-0">
        <div className="font-medium text-warm-900 text-sm">{item.name}</div>
        <div className="text-xs text-warm-500">{item.currentLevel} {item.unit} remaining</div>
      </div>
      <div className="text-sm">
        {getStatusIcon()} <span className={item.isLow ? 'text-amber-700' : 'text-emerald-700'}>{getStatusText()}</span>
      </div>
      {item.isLow && !item.onShoppingList && (
        <button
          onClick={onAddToList}
          className="px-2 py-1 bg-emerald-600 text-white text-xs rounded hover:bg-emerald-700 transition-colors"
        >
          Add
        </button>
      )}
    </div>
  );
}

// Auto-Reorder Item Card
function AutoReorderCard({
  item,
  onToggle,
}: {
  item: AutoReorderItem;
  onToggle: () => void;
}) {
  const catConfig = CATEGORIES[item.category];
  const CatIcon = catConfig.icon;

  const getFrequencyLabel = () => {
    switch (item.frequency) {
      case 'weekly': return 'Weekly';
      case 'biweekly': return 'Every 2 weeks';
      case 'monthly': return 'Monthly';
      case 'quarterly': return 'Quarterly';
    }
  };

  const formatDate = (date?: Date) => {
    if (!date) return '-';
    return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
  };

  return (
    <div className={`flex items-center gap-3 p-4 rounded-xl border ${item.enabled ? 'bg-white border-warm-200' : 'bg-warm-50 border-warm-100'}`}>
      <div className={`p-2 rounded-lg ${catConfig.color}`}>
        <CatIcon className="w-4 h-4" />
      </div>
      <div className="flex-1 min-w-0">
        <div className={`font-medium ${item.enabled ? 'text-warm-900' : 'text-warm-500'}`}>{item.name}</div>
        <div className="text-xs text-warm-500 flex items-center gap-2">
          <span>{getFrequencyLabel()}</span>
          {item.nextOrder && item.enabled && (
            <>
              <span>•</span>
              <span>Next: {formatDate(item.nextOrder)}</span>
            </>
          )}
        </div>
      </div>
      <button onClick={onToggle} className="flex-shrink-0">
        {item.enabled ? (
          <ToggleRight className="w-10 h-6 text-emerald-600" />
        ) : (
          <ToggleLeft className="w-10 h-6 text-warm-400" />
        )}
      </button>
    </div>
  );
}

// Recently Delivered Toast
function DeliveredToast({
  list,
  onDismiss,
}: {
  list: ShoppingList;
  onDismiss: () => void;
}) {
  useEffect(() => {
    const timer = setTimeout(onDismiss, 6000);
    return () => clearTimeout(timer);
  }, [onDismiss]);

  return (
    <div className="fixed top-4 left-1/2 -tranwarm-x-1/2 z-[60] animate-in slide-in-from-top-2">
      <div className="flex items-center gap-3 px-4 py-3 bg-emerald-600 text-white rounded-xl shadow-lg">
        <CheckCircle2 className="w-5 h-5" />
        <span className="font-medium">{list.name} delivered! 📦</span>
        <button onClick={onDismiss} className="p-1 hover:bg-white/20 rounded">
          <X className="w-4 h-4" />
        </button>
      </div>
    </div>
  );
}

// List Detail View
function ListDetailView({
  list,
  items,
  onBack,
}: {
  list: ShoppingList;
  items: ShoppingItem[];
  onBack: () => void;
}) {
  const ListIcon = list.icon;

  // Group items by category
  const groupedItems = useMemo(() => {
    const groups: Record<ItemCategory, ShoppingItem[]> = {} as Record<ItemCategory, ShoppingItem[]>;
    items.forEach(item => {
      if (!groups[item.category]) groups[item.category] = [];
      groups[item.category].push(item);
    });
    return groups;
  }, [items]);

  const totalCost = items.reduce((sum, item) => sum + (item.cost || 0), 0);

  return (
    <div className="space-y-4">
      {/* Header */}
      <div className="bg-white rounded-xl border border-warm-200 p-4">
        <button
          onClick={onBack}
          className="flex items-center gap-2 text-warm-600 hover:text-warm-900 mb-3"
        >
          <ChevronRight className="w-4 h-4 rotate-180" />
          <span className="text-sm">Back to lists</span>
        </button>

        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="p-3 bg-emerald-100 rounded-lg">
              <ListIcon className="w-6 h-6 text-emerald-600" />
            </div>
            <div>
              <h2 className="font-semibold text-warm-900 text-lg">{list.name}</h2>
              <div className={`inline-flex items-center gap-1.5 px-2 py-1 rounded-full text-xs font-medium mt-1 ${getStatusColor(list.status)}`}>
                {getStatusIcon(list.status)}
                {list.statusMessage}
              </div>
            </div>
          </div>

          {list.status === 'DELIVERED' && totalCost > 0 && (
            <div className="text-right">
              <div className="text-2xl font-bold text-warm-900">${totalCost.toFixed(2)}</div>
              <div className="text-sm text-warm-500">Total cost</div>
            </div>
          )}
        </div>
      </div>

      {/* Items */}
      {Object.entries(groupedItems).map(([category, categoryItems]) => {
        const catConfig = CATEGORIES[category as ItemCategory];
        const CatIcon = catConfig.icon;
        return (
          <div key={category} className="bg-white rounded-xl border border-warm-200 overflow-hidden">
            <div className={`flex items-center gap-2 px-4 py-2 ${catConfig.color} border-b border-warm-100`}>
              <CatIcon className="w-4 h-4" />
              <span className="font-medium text-sm">{catConfig.label}</span>
              <span className="text-xs opacity-60">({categoryItems.length})</span>
            </div>
            <div className="divide-y divide-warm-100">
              {categoryItems.map(item => (
                <div key={item.id} className="flex items-center gap-3 px-4 py-3">
                  <div className={`w-6 h-6 rounded-full flex items-center justify-center ${
                    item.status === 'DELIVERED' ? 'bg-emerald-100 text-emerald-600' : 'bg-warm-100 text-warm-400'
                  }`}>
                    {item.status === 'DELIVERED' ? <Check className="w-4 h-4" /> : <Clock className="w-4 h-4" />}
                  </div>
                  <div className="flex-1">
                    <div className="font-medium text-warm-900">{item.name}</div>
                    <div className="text-sm text-warm-500">{item.quantity}</div>
                  </div>
                  {item.cost && (
                    <div className="text-sm font-medium text-warm-700">${item.cost.toFixed(2)}</div>
                  )}
                </div>
              ))}
            </div>
          </div>
        );
      })}
    </div>
  );
}

// ============================================================================
// MAIN PAGE
// ============================================================================

export default function InventoryPage() {
  useAuth(); // Will use for API calls when connected

  // State
  const [viewMode, setViewMode] = useState<ViewMode>('shopping');
  const [lists, setLists] = useState<ShoppingList[]>(MOCK_LISTS);
  const [items, setItems] = useState<ShoppingItem[]>(MOCK_ITEMS);
  const [inventory, setInventory] = useState<InventoryItem[]>(MOCK_INVENTORY);
  const [autoReorder, setAutoReorder] = useState<AutoReorderItem[]>(MOCK_AUTO_REORDER);
  const [selectedListId, setSelectedListId] = useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [showDeliveredToast, setShowDeliveredToast] = useState<ShoppingList | null>(null);
  const [searchQuery, setSearchQuery] = useState('');

  // Check for recently delivered items on mount
  useEffect(() => {
    const delivered = lists.find(l => l.isDeliveredToday);
    if (delivered) {
      setShowDeliveredToast(delivered);
    }
  }, []);

  // Computed values
  const totalItemsInProgress = useMemo(() =>
    items.filter(i => i.status !== 'DELIVERED').length
  , [items]);

  const listsInProgress = useMemo(() =>
    lists.filter(l => l.status !== 'DELIVERED' && l.status !== 'NEEDED').length
  , [lists]);

  const lowStockItems = useMemo(() =>
    inventory.filter(i => i.isLow)
  , [inventory]);

  const selectedList = selectedListId ? lists.find(l => l.id === selectedListId) : null;
  const selectedListItems = selectedListId ? items.filter(i => i.listId === selectedListId) : [];

  // Handlers
  const handleAddItems = useCallback(async (newItems: { name: string; quantity: string }[]) => {
    setIsSubmitting(true);
    await new Promise(r => setTimeout(r, 500));

    const timestamp = Date.now();
    const addedItems: ShoppingItem[] = newItems.map((item, idx) => {
      const { category } = categorizeItem(item.name);
      return {
        id: `item-new-${timestamp}-${idx}`,
        listId: 'list-1', // Default to first list, would be smarter in real app
        name: item.name.charAt(0).toUpperCase() + item.name.slice(1),
        quantity: item.quantity,
        category,
        status: 'NEEDED' as ShoppingStatus,
        addedAt: new Date(),
      };
    });

    setItems(prev => [...prev, ...addedItems]);
    setLists(prev => prev.map(l =>
      l.id === 'list-1' ? { ...l, itemCount: l.itemCount + addedItems.length } : l
    ));
    setIsSubmitting(false);
  }, []);

  const handleToggleAutoReorder = useCallback((itemId: string) => {
    setAutoReorder(prev => prev.map(item =>
      item.id === itemId ? { ...item, enabled: !item.enabled } : item
    ));
  }, []);

  const handleAddLowStockToList = useCallback((invId: string) => {
    const invItem = inventory.find(i => i.id === invId);
    if (!invItem) return;

    const newItem: ShoppingItem = {
      id: `item-inv-${Date.now()}`,
      listId: 'list-1',
      name: invItem.name,
      quantity: `${invItem.minLevel * 2 - invItem.currentLevel} ${invItem.unit}`,
      category: invItem.category,
      status: 'NEEDED',
      addedAt: new Date(),
    };

    setItems(prev => [...prev, newItem]);
    setInventory(prev => prev.map(i =>
      i.id === invId ? { ...i, onShoppingList: true } : i
    ));
    setLists(prev => prev.map(l =>
      l.id === 'list-1' ? { ...l, itemCount: l.itemCount + 1 } : l
    ));
  }, [inventory]);

  // Filter inventory by search
  const filteredInventory = useMemo(() => {
    if (!searchQuery) return inventory;
    return inventory.filter(i =>
      i.name.toLowerCase().includes(searchQuery.toLowerCase())
    );
  }, [inventory, searchQuery]);

  return (
    <div className="pb-32 lg:pb-8 max-w-4xl mx-auto">
      {/* Header */}
      <div className="mb-6">
        <h1 className="text-2xl lg:text-3xl font-bold text-warm-900">Shopping</h1>
        <p className="text-warm-500 mt-1">Add items and {HOUSING_MANAGER.name} handles procurement</p>
      </div>

      {/* View Mode Tabs */}
      <div className="flex bg-warm-100 rounded-lg p-1 mb-6">
        <button
          onClick={() => setViewMode('shopping')}
          className={`flex-1 flex items-center justify-center gap-2 px-4 py-2 rounded-md text-sm font-medium transition-colors ${
            viewMode === 'shopping'
              ? 'bg-white text-warm-900 shadow-sm'
              : 'text-warm-600 hover:text-warm-900'
          }`}
        >
          <ShoppingCart className="w-4 h-4" />
          Shopping
        </button>
        <button
          onClick={() => setViewMode('inventory')}
          className={`flex-1 flex items-center justify-center gap-2 px-4 py-2 rounded-md text-sm font-medium transition-colors relative ${
            viewMode === 'inventory'
              ? 'bg-white text-warm-900 shadow-sm'
              : 'text-warm-600 hover:text-warm-900'
          }`}
        >
          <Package className="w-4 h-4" />
          Inventory
          {lowStockItems.length > 0 && (
            <span className="absolute -top-1 -right-1 w-5 h-5 bg-amber-500 text-white text-xs rounded-full flex items-center justify-center">
              {lowStockItems.length}
            </span>
          )}
        </button>
        <button
          onClick={() => setViewMode('auto-reorder')}
          className={`flex-1 flex items-center justify-center gap-2 px-4 py-2 rounded-md text-sm font-medium transition-colors ${
            viewMode === 'auto-reorder'
              ? 'bg-white text-warm-900 shadow-sm'
              : 'text-warm-600 hover:text-warm-900'
          }`}
        >
          <RefreshCw className="w-4 h-4" />
          Auto-Order
        </button>
      </div>

      {viewMode === 'shopping' && !selectedList && (
        <>
          {/* Quick Add Input */}
          <QuickAddInput onAdd={handleAddItems} isSubmitting={isSubmitting} />

          {/* Manager Summary */}
          {totalItemsInProgress > 0 && (
            <div className="mt-6">
              <ManagerSummary
                totalItems={totalItemsInProgress}
                listsInProgress={listsInProgress}
              />
            </div>
          )}

          {/* Shopping Lists Status */}
          <div className="mt-6">
            <h2 className="text-lg font-semibold text-warm-900 mb-4">Your Lists</h2>
            <div className="space-y-3">
              {lists.map(list => (
                <ListStatusCard
                  key={list.id}
                  list={list}
                  onClick={() => setSelectedListId(list.id)}
                  isActive={false}
                />
              ))}
            </div>
          </div>
        </>
      )}

      {viewMode === 'shopping' && selectedList && (
        <ListDetailView
          list={selectedList}
          items={selectedListItems}
          onBack={() => setSelectedListId(null)}
        />
      )}

      {viewMode === 'inventory' && (
        <>
          {/* Search */}
          <div className="relative mb-4">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-warm-400" />
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="Search inventory..."
              className="w-full pl-10 pr-4 py-2.5 border border-warm-300 rounded-lg focus:ring-2 focus:ring-emerald-500 focus:border-transparent bg-white"
            />
          </div>

          {/* Low Stock Alert */}
          {lowStockItems.length > 0 && (
            <div className="bg-amber-50 border border-amber-200 rounded-xl p-4 mb-4">
              <div className="flex items-start gap-3">
                <AlertTriangle className="w-5 h-5 text-amber-600 flex-shrink-0 mt-0.5" />
                <div>
                  <h3 className="font-medium text-amber-800">Low Stock Alert</h3>
                  <p className="text-sm text-amber-700 mt-1">
                    {lowStockItems.length} items are running low
                  </p>
                </div>
              </div>
            </div>
          )}

          {/* Inventory List */}
          <div className="bg-white rounded-xl border border-warm-200 overflow-hidden">
            <div className="p-4 border-b border-warm-200 flex items-center justify-between">
              <h2 className="font-semibold text-warm-900">Household Inventory</h2>
              <span className="text-sm text-warm-500">{inventory.length} items tracked</span>
            </div>
            <div className="divide-y divide-warm-100">
              {filteredInventory.map(item => (
                <InventoryLevelCard
                  key={item.id}
                  item={item}
                  onAddToList={() => handleAddLowStockToList(item.id)}
                />
              ))}
            </div>
          </div>
        </>
      )}

      {viewMode === 'auto-reorder' && (
        <>
          {/* Info Card */}
          <div className="bg-blue-50 border border-blue-200 rounded-xl p-4 mb-6">
            <div className="flex items-start gap-3">
              <RefreshCw className="w-5 h-5 text-blue-600 flex-shrink-0 mt-0.5" />
              <div>
                <h3 className="font-medium text-blue-800">Auto-Reorder</h3>
                <p className="text-sm text-blue-700 mt-1">
                  Items below will be automatically added to your shopping list when due.
                  {HOUSING_MANAGER.name} will handle procurement.
                </p>
              </div>
            </div>
          </div>

          {/* Auto-Reorder Items */}
          <div className="space-y-3">
            {autoReorder.map(item => (
              <AutoReorderCard
                key={item.id}
                item={item}
                onToggle={() => handleToggleAutoReorder(item.id)}
              />
            ))}
          </div>

          {/* Add New Auto-Reorder */}
          <button className="w-full mt-4 flex items-center justify-center gap-2 p-4 border-2 border-dashed border-warm-300 rounded-xl text-warm-600 hover:border-emerald-500 hover:text-emerald-600 transition-colors">
            <Plus className="w-5 h-5" />
            Add auto-reorder item
          </button>
        </>
      )}

      {/* Delivered Toast */}
      {showDeliveredToast && (
        <DeliveredToast
          list={showDeliveredToast}
          onDismiss={() => setShowDeliveredToast(null)}
        />
      )}
    </div>
  );
}

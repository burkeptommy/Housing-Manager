'use client';

import { useState, useMemo, useCallback, useEffect, useRef } from 'react';
import {
  ShoppingCart,
  Package,
  Plus,
  Search,
  Check,
  Pencil,
  Trash2,
  Star,
  ChevronRight,
  X,
  Send,
  Clock,
  Truck,
  ScanBarcode,
  GripVertical,
  AlertTriangle,
  CheckCircle2,
  ShoppingBag,
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
  MessageCircle,
  Calendar,
  ToggleLeft,
  ToggleRight,
  BoxIcon,
  ListChecks,
  Archive,
  RefreshCw,
} from 'lucide-react';
import { getApiClient } from '@/lib/api';
import { useAuth } from '@/contexts/auth-context';

// Types
type ListType = 'groceries' | 'costco' | 'hardware' | 'party' | 'custom';
type ItemCategory = 'produce' | 'dairy' | 'meat' | 'bakery' | 'beverages' | 'pantry' | 'frozen' | 'household' | 'health' | 'baby' | 'pet' | 'other';
type OrderStatus = 'pending' | 'processing' | 'in_transit' | 'delivered';
type ViewMode = 'lists' | 'inventory';

interface ShoppingList {
  id: string;
  name: string;
  type: ListType;
  icon: typeof ShoppingCart;
  itemCount: number;
  pendingOrder?: {
    orderId: string;
    status: OrderStatus;
    vendor: string;
    eta?: string;
  };
}

interface ShoppingItem {
  id: string;
  listId: string;
  name: string;
  quantity: string;
  category: ItemCategory;
  checked: boolean;
  starred: boolean;
  notes?: string;
  addedAt: Date;
}

interface InventoryItem {
  id: string;
  name: string;
  category: ItemCategory;
  currentQty: number;
  targetQty: number;
  unit: string;
  lastRestocked?: Date;
  lowStock: boolean;
  location?: string;
}

// Category configuration
const CATEGORIES: Record<ItemCategory, { label: string; icon: typeof Apple; color: string }> = {
  produce: { label: 'Produce', icon: Apple, color: 'text-green-600 bg-green-50' },
  dairy: { label: 'Dairy', icon: Milk, color: 'text-blue-600 bg-blue-50' },
  meat: { label: 'Meat & Seafood', icon: Beef, color: 'text-red-600 bg-red-50' },
  bakery: { label: 'Bakery', icon: Croissant, color: 'text-amber-600 bg-amber-50' },
  beverages: { label: 'Beverages', icon: Wine, color: 'text-purple-600 bg-purple-50' },
  pantry: { label: 'Pantry', icon: BoxIcon, color: 'text-orange-600 bg-orange-50' },
  frozen: { label: 'Frozen', icon: Snowflake, color: 'text-cyan-600 bg-cyan-50' },
  household: { label: 'Household', icon: Home, color: 'text-slate-600 bg-slate-50' },
  health: { label: 'Health & Beauty', icon: Pill, color: 'text-pink-600 bg-pink-50' },
  baby: { label: 'Baby', icon: Baby, color: 'text-sky-600 bg-sky-50' },
  pet: { label: 'Pet Supplies', icon: Dog, color: 'text-yellow-600 bg-yellow-50' },
  other: { label: 'Other', icon: Sparkles, color: 'text-gray-600 bg-gray-50' },
};

// Auto-categorization keywords
const CATEGORY_KEYWORDS: Record<string, ItemCategory> = {
  // Produce
  apple: 'produce', banana: 'produce', avocado: 'produce', lettuce: 'produce', tomato: 'produce',
  onion: 'produce', potato: 'produce', carrot: 'produce', broccoli: 'produce', spinach: 'produce',
  orange: 'produce', lemon: 'produce', lime: 'produce', grape: 'produce', strawberry: 'produce',
  // Dairy
  milk: 'dairy', cheese: 'dairy', yogurt: 'dairy', butter: 'dairy', cream: 'dairy', eggs: 'dairy',
  // Meat
  chicken: 'meat', beef: 'meat', pork: 'meat', fish: 'meat', salmon: 'meat', shrimp: 'meat', bacon: 'meat',
  // Bakery
  bread: 'bakery', bagel: 'bakery', croissant: 'bakery', muffin: 'bakery', cake: 'bakery',
  // Beverages
  water: 'beverages', juice: 'beverages', soda: 'beverages', wine: 'beverages', beer: 'beverages', coffee: 'beverages', tea: 'beverages',
  // Pantry
  rice: 'pantry', pasta: 'pantry', cereal: 'pantry', flour: 'pantry', sugar: 'pantry', oil: 'pantry', sauce: 'pantry',
  // Frozen
  ice: 'frozen', frozen: 'frozen', pizza: 'frozen',
  // Household
  paper: 'household', towel: 'household', tissue: 'household', detergent: 'household', soap: 'household',
  battery: 'household', batteries: 'household', lightbulb: 'household', trash: 'household', bag: 'household',
  filter: 'household', cleaner: 'household', sponge: 'household',
  // Health
  vitamin: 'health', medicine: 'health', bandaid: 'health', shampoo: 'health', toothpaste: 'health',
  // Baby
  diaper: 'baby', formula: 'baby', wipes: 'baby',
  // Pet
  dog: 'pet', cat: 'pet', pet: 'pet', kibble: 'pet', litter: 'pet',
};

// Mock data (fallback when API is unavailable)
const MOCK_LISTS: ShoppingList[] = [
  {
    id: 'list-1',
    name: 'Weekly Groceries',
    type: 'groceries',
    icon: ShoppingCart,
    itemCount: 12,
    pendingOrder: {
      orderId: 'ORD-1234',
      status: 'in_transit',
      vendor: 'Whole Foods',
      eta: 'Today, 5:00 PM',
    },
  },
  {
    id: 'list-2',
    name: 'Costco Run',
    type: 'costco',
    icon: Store,
    itemCount: 6,
  },
  {
    id: 'list-3',
    name: 'Hardware Store',
    type: 'hardware',
    icon: Wrench,
    itemCount: 3,
  },
  {
    id: 'list-4',
    name: 'Holiday Party',
    type: 'party',
    icon: Sparkles,
    itemCount: 8,
  },
];

const MOCK_ITEMS: ShoppingItem[] = [
  // Weekly Groceries
  { id: 'item-1', listId: 'list-1', name: 'Organic Whole Milk', quantity: '1 Gal', category: 'dairy', checked: false, starred: true, addedAt: new Date() },
  { id: 'item-2', listId: 'list-1', name: 'Free-Range Eggs', quantity: '1 Dozen', category: 'dairy', checked: false, starred: false, addedAt: new Date() },
  { id: 'item-3', listId: 'list-1', name: 'Avocados', quantity: '4', category: 'produce', checked: false, starred: true, addedAt: new Date() },
  { id: 'item-4', listId: 'list-1', name: 'Bananas', quantity: '1 Bunch', category: 'produce', checked: true, starred: false, addedAt: new Date() },
  { id: 'item-5', listId: 'list-1', name: 'Sourdough Bread', quantity: '1 Loaf', category: 'bakery', checked: false, starred: false, addedAt: new Date() },
  { id: 'item-6', listId: 'list-1', name: 'Sparkling Water', quantity: '12 Pack', category: 'beverages', checked: false, starred: false, addedAt: new Date() },
  { id: 'item-7', listId: 'list-1', name: 'Greek Yogurt', quantity: '32 oz', category: 'dairy', checked: true, starred: false, addedAt: new Date() },
  { id: 'item-8', listId: 'list-1', name: 'Chicken Breast', quantity: '2 lbs', category: 'meat', checked: false, starred: false, addedAt: new Date() },
  { id: 'item-9', listId: 'list-1', name: 'Paper Towels', quantity: '6 Roll', category: 'household', checked: false, starred: false, addedAt: new Date() },
  { id: 'item-10', listId: 'list-1', name: 'AA Batteries', quantity: '8 Pack', category: 'household', checked: false, starred: true, addedAt: new Date() },
  { id: 'item-11', listId: 'list-1', name: 'Olive Oil', quantity: '1 Bottle', category: 'pantry', checked: true, starred: false, addedAt: new Date() },
  { id: 'item-12', listId: 'list-1', name: 'Fresh Salmon', quantity: '1 lb', category: 'meat', checked: false, starred: false, addedAt: new Date() },
  // Costco
  { id: 'item-20', listId: 'list-2', name: 'Toilet Paper', quantity: '30 Pack', category: 'household', checked: false, starred: true, addedAt: new Date() },
  { id: 'item-21', listId: 'list-2', name: 'Kirkland Water', quantity: '40 Pack', category: 'beverages', checked: false, starred: false, addedAt: new Date() },
  { id: 'item-22', listId: 'list-2', name: 'Rotisserie Chicken', quantity: '1', category: 'meat', checked: false, starred: false, addedAt: new Date() },
  { id: 'item-23', listId: 'list-2', name: 'Mixed Nuts', quantity: '2.5 lb', category: 'pantry', checked: false, starred: false, addedAt: new Date() },
  { id: 'item-24', listId: 'list-2', name: 'Laundry Detergent', quantity: '1 Tub', category: 'household', checked: false, starred: false, addedAt: new Date() },
  { id: 'item-25', listId: 'list-2', name: 'Dog Food', quantity: '40 lb', category: 'pet', checked: false, starred: true, addedAt: new Date() },
  // Hardware
  { id: 'item-30', listId: 'list-3', name: 'HVAC Filters (20x25)', quantity: '4 Pack', category: 'household', checked: false, starred: true, addedAt: new Date() },
  { id: 'item-31', listId: 'list-3', name: 'LED Bulbs (60W)', quantity: '8 Pack', category: 'household', checked: false, starred: false, addedAt: new Date() },
  { id: 'item-32', listId: 'list-3', name: 'Smoke Detector Batteries', quantity: '6', category: 'household', checked: false, starred: true, addedAt: new Date() },
  // Party
  { id: 'item-40', listId: 'list-4', name: 'Champagne', quantity: '6 Bottles', category: 'beverages', checked: false, starred: true, addedAt: new Date() },
  { id: 'item-41', listId: 'list-4', name: 'Cheese Platter', quantity: '1', category: 'dairy', checked: false, starred: false, addedAt: new Date() },
  { id: 'item-42', listId: 'list-4', name: 'Crackers Assortment', quantity: '3 Boxes', category: 'pantry', checked: false, starred: false, addedAt: new Date() },
  { id: 'item-43', listId: 'list-4', name: 'Shrimp Cocktail', quantity: '2 lbs', category: 'meat', checked: false, starred: false, addedAt: new Date() },
  { id: 'item-44', listId: 'list-4', name: 'Sparkling Cider', quantity: '4 Bottles', category: 'beverages', checked: false, starred: false, addedAt: new Date() },
  { id: 'item-45', listId: 'list-4', name: 'Napkins (Festive)', quantity: '100 Pack', category: 'household', checked: false, starred: false, addedAt: new Date() },
  { id: 'item-46', listId: 'list-4', name: 'Ice', quantity: '20 lbs', category: 'frozen', checked: false, starred: false, addedAt: new Date() },
  { id: 'item-47', listId: 'list-4', name: 'Fresh Flowers', quantity: '2 Bouquets', category: 'other', checked: false, starred: false, addedAt: new Date() },
];

const MOCK_INVENTORY: InventoryItem[] = [
  { id: 'inv-1', name: 'Toilet Paper', category: 'household', currentQty: 4, targetQty: 24, unit: 'rolls', lowStock: true, location: 'Hall Closet' },
  { id: 'inv-2', name: 'Paper Towels', category: 'household', currentQty: 8, targetQty: 12, unit: 'rolls', lowStock: false, location: 'Kitchen Pantry' },
  { id: 'inv-3', name: 'AA Batteries', category: 'household', currentQty: 2, targetQty: 16, unit: 'count', lowStock: true, location: 'Utility Drawer' },
  { id: 'inv-4', name: 'AAA Batteries', category: 'household', currentQty: 8, targetQty: 12, unit: 'count', lowStock: false, location: 'Utility Drawer' },
  { id: 'inv-5', name: 'HVAC Filters (20x25)', category: 'household', currentQty: 1, targetQty: 4, unit: 'filters', lowStock: true, location: 'Garage' },
  { id: 'inv-6', name: 'LED Bulbs (60W)', category: 'household', currentQty: 6, targetQty: 8, unit: 'bulbs', lowStock: false, location: 'Garage' },
  { id: 'inv-7', name: 'Dish Soap', category: 'household', currentQty: 3, targetQty: 4, unit: 'bottles', lowStock: false, location: 'Under Sink' },
  { id: 'inv-8', name: 'Laundry Detergent', category: 'household', currentQty: 1, targetQty: 2, unit: 'pods tub', lowStock: true, location: 'Laundry Room' },
  { id: 'inv-9', name: 'Hand Soap Refill', category: 'health', currentQty: 2, targetQty: 4, unit: 'bottles', lowStock: false, location: 'Hall Closet' },
  { id: 'inv-10', name: 'Toothpaste', category: 'health', currentQty: 1, targetQty: 4, unit: 'tubes', lowStock: true, location: 'Master Bath' },
  { id: 'inv-11', name: 'Shampoo', category: 'health', currentQty: 2, targetQty: 3, unit: 'bottles', lowStock: false, location: 'Master Bath' },
  { id: 'inv-12', name: 'Dog Food', category: 'pet', currentQty: 15, targetQty: 40, unit: 'lbs', lowStock: true, location: 'Pantry' },
  { id: 'inv-13', name: 'Dog Treats', category: 'pet', currentQty: 2, targetQty: 3, unit: 'bags', lowStock: false, location: 'Pantry' },
  { id: 'inv-14', name: 'Trash Bags (13 Gal)', category: 'household', currentQty: 45, targetQty: 100, unit: 'bags', lowStock: false, location: 'Under Sink' },
  { id: 'inv-15', name: 'Ziploc Bags (Gallon)', category: 'household', currentQty: 20, targetQty: 50, unit: 'bags', lowStock: false, location: 'Kitchen Drawer' },
];

// API-to-UI Mapping Functions
function mapApiListToUi(apiList: Record<string, unknown>): ShoppingList {
  const listType = String(apiList.type || 'custom').toLowerCase() as ListType;
  const iconMap: Record<string, typeof ShoppingCart> = {
    groceries: ShoppingCart,
    costco: Store,
    hardware: Wrench,
    party: Sparkles,
    custom: ListChecks,
  };

  return {
    id: String(apiList.id || `list-${Date.now()}`),
    name: String(apiList.name || 'Unnamed List'),
    type: listType,
    icon: iconMap[listType] || ShoppingCart,
    itemCount: Number(apiList.itemCount || (Array.isArray(apiList.items) ? apiList.items.length : 0)),
    pendingOrder: apiList.pendingOrder
      ? {
          orderId: String((apiList.pendingOrder as Record<string, unknown>).orderId || ''),
          status: String((apiList.pendingOrder as Record<string, unknown>).status || 'pending') as 'pending' | 'processing' | 'in_transit' | 'delivered',
          vendor: String((apiList.pendingOrder as Record<string, unknown>).vendor || ''),
          eta: (apiList.pendingOrder as Record<string, unknown>).eta
            ? String((apiList.pendingOrder as Record<string, unknown>).eta)
            : undefined,
        }
      : undefined,
  };
}

function mapApiItemToUi(apiItem: Record<string, unknown>, listId?: string): ShoppingItem {
  const category = String(apiItem.category || 'other').toLowerCase() as ItemCategory;
  return {
    id: String(apiItem.id || `item-${Date.now()}`),
    listId: String(apiItem.listId || listId || 'list-1'),
    name: String(apiItem.name || 'Unknown Item'),
    quantity: String(apiItem.quantity || '1'),
    category: Object.keys(CATEGORIES).includes(category) ? category : 'other',
    checked: Boolean(apiItem.checked || apiItem.isChecked || false),
    starred: Boolean(apiItem.starred || apiItem.isStarred || apiItem.priority === 'high'),
    notes: apiItem.notes ? String(apiItem.notes) : undefined,
    addedAt: apiItem.addedAt ? new Date(String(apiItem.addedAt)) : new Date(),
  };
}

function mapApiInventoryToUi(apiInv: Record<string, unknown>): InventoryItem {
  const category = String(apiInv.category || 'household').toLowerCase() as ItemCategory;
  const currentQty = Number(apiInv.currentQty || apiInv.quantity || 0);
  const targetQty = Number(apiInv.targetQty || apiInv.target || currentQty * 2 || 10);
  const lowStock = apiInv.lowStock !== undefined
    ? Boolean(apiInv.lowStock)
    : currentQty < targetQty * 0.25;

  return {
    id: String(apiInv.id || `inv-${Date.now()}`),
    name: String(apiInv.name || 'Unknown Item'),
    category: Object.keys(CATEGORIES).includes(category) ? category : 'household',
    currentQty,
    targetQty,
    unit: String(apiInv.unit || 'count'),
    lastRestocked: apiInv.lastRestocked ? new Date(String(apiInv.lastRestocked)) : undefined,
    lowStock,
    location: apiInv.location ? String(apiInv.location) : undefined,
  };
}

// Export mapping functions for use in other components
export { mapApiListToUi, mapApiItemToUi, mapApiInventoryToUi };

export default function InventoryPage() {
  // Auth context for household
  const { currentHousehold } = useAuth();

  // State - initialize with mocks (hybrid pattern)
  const [viewMode, setViewMode] = useState<ViewMode>('lists');
  const [lists, setLists] = useState<ShoppingList[]>(MOCK_LISTS);
  const [items, setItems] = useState<ShoppingItem[]>(MOCK_ITEMS);
  const [inventory, setInventory] = useState<InventoryItem[]>(MOCK_INVENTORY);
  const [activeListId, setActiveListId] = useState<string>('list-1');
  const [searchQuery, setSearchQuery] = useState('');
  const [newItemInput, setNewItemInput] = useState('');
  const [showOrderModal, setShowOrderModal] = useState(false);
  const [showAddItemModal, setShowAddItemModal] = useState(false);
  const [editingItem, setEditingItem] = useState<ShoppingItem | null>(null);
  const [showInventoryModal, setShowInventoryModal] = useState(false);
  const [editingInventory, setEditingInventory] = useState<InventoryItem | null>(null);
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  const [_isLoading, setIsLoading] = useState(true);

  // Order form state
  const [orderVendor, setOrderVendor] = useState('whole_foods');
  const [allowSubstitutions, setAllowSubstitutions] = useState(true);
  const [deliveryDate, setDeliveryDate] = useState('');
  const [deliveryTime, setDeliveryTime] = useState('');
  const [orderNotes, setOrderNotes] = useState('');

  // Refs for debounced API calls
  const pendingCheckUpdates = useRef<Record<string, NodeJS.Timeout>>({});
  const pendingInventoryUpdates = useRef<Record<string, NodeJS.Timeout>>({});
  const DEBOUNCE_MS = 500;

  // Hybrid Data Fetching - load from API, fallback to mocks
  // Note: Shopping list and inventory API endpoints are planned but not yet implemented
  // The hybrid pattern allows UI to work with mocks until APIs are available
  const loadInventoryData = useCallback(async () => {
    if (!currentHousehold?.id) {
      setIsLoading(false);
      return;
    }

    try {
      // Type for future API methods (not yet in ApiClient)
      type FutureApiClient = {
        getHouseholdShoppingLists?: (id: string) => Promise<unknown[]>;
        getHouseholdShoppingItems?: (id: string) => Promise<unknown[]>;
        getHouseholdInventory?: (id: string) => Promise<unknown[]>;
      };

      const api = getApiClient() as unknown as FutureApiClient;

      // Fetch all data in parallel with Promise.allSettled
      const [listsResult, itemsResult, inventoryResult] = await Promise.allSettled([
        api.getHouseholdShoppingLists?.(currentHousehold.id) ?? Promise.resolve([]),
        api.getHouseholdShoppingItems?.(currentHousehold.id) ?? Promise.resolve([]),
        api.getHouseholdInventory?.(currentHousehold.id) ?? Promise.resolve([]),
      ]);

      // Process shopping lists
      if (listsResult.status === 'fulfilled') {
        const listsData = listsResult.value;
        if (Array.isArray(listsData) && listsData.length > 0) {
          setLists(listsData.map((l) => mapApiListToUi(l as unknown as Record<string, unknown>)));
        }
      } else {
        console.warn('Failed to fetch shopping lists:', listsResult.reason);
      }

      // Process shopping items
      if (itemsResult.status === 'fulfilled') {
        const itemsData = itemsResult.value;
        if (Array.isArray(itemsData) && itemsData.length > 0) {
          setItems(itemsData.map((i) => mapApiItemToUi(i as unknown as Record<string, unknown>)));
        }
      } else {
        console.warn('Failed to fetch shopping items:', itemsResult.reason);
      }

      // Process inventory
      if (inventoryResult.status === 'fulfilled') {
        const inventoryData = inventoryResult.value;
        if (Array.isArray(inventoryData) && inventoryData.length > 0) {
          setInventory(inventoryData.map((inv) => mapApiInventoryToUi(inv as unknown as Record<string, unknown>)));
        }
      } else {
        console.warn('Failed to fetch inventory:', inventoryResult.reason);
      }
    } catch (error) {
      console.error('Error loading inventory data:', error);
      // Keep mock data on failure - already initialized with mocks
    } finally {
      setIsLoading(false);
    }
  }, [currentHousehold?.id]);

  // Load data on mount and when household changes
  useEffect(() => {
    loadInventoryData();
  }, [loadInventoryData]);

  // Cleanup pending timeouts on unmount
  useEffect(() => {
    return () => {
      Object.values(pendingCheckUpdates.current).forEach(clearTimeout);
      Object.values(pendingInventoryUpdates.current).forEach(clearTimeout);
    };
  }, []);

  // Active list
  const activeList = useMemo(() => lists.find(l => l.id === activeListId), [lists, activeListId]);

  // Filtered items for active list
  const activeItems = useMemo(() => {
    let filtered = items.filter(i => i.listId === activeListId);
    if (searchQuery) {
      filtered = filtered.filter(i =>
        i.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
        i.category.toLowerCase().includes(searchQuery.toLowerCase())
      );
    }
    // Sort: starred first, then unchecked, then checked
    return filtered.sort((a, b) => {
      if (a.starred !== b.starred) return b.starred ? 1 : -1;
      if (a.checked !== b.checked) return a.checked ? 1 : -1;
      return 0;
    });
  }, [items, activeListId, searchQuery]);

  // Group items by category
  const groupedItems = useMemo(() => {
    const groups: Record<ItemCategory, ShoppingItem[]> = {} as Record<ItemCategory, ShoppingItem[]>;
    activeItems.forEach(item => {
      if (!groups[item.category]) groups[item.category] = [];
      groups[item.category].push(item);
    });
    return groups;
  }, [activeItems]);

  // Filtered inventory
  const filteredInventory = useMemo(() => {
    let filtered = inventory;
    if (searchQuery) {
      filtered = filtered.filter(i =>
        i.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
        i.category.toLowerCase().includes(searchQuery.toLowerCase()) ||
        i.location?.toLowerCase().includes(searchQuery.toLowerCase())
      );
    }
    return filtered.sort((a, b) => {
      // Low stock first
      if (a.lowStock !== b.lowStock) return a.lowStock ? -1 : 1;
      return a.name.localeCompare(b.name);
    });
  }, [inventory, searchQuery]);

  // Low stock count
  const lowStockCount = useMemo(() => inventory.filter(i => i.lowStock).length, [inventory]);

  // Auto-categorize item
  const categorizeItem = useCallback((name: string): ItemCategory => {
    const lowerName = name.toLowerCase();
    for (const [keyword, category] of Object.entries(CATEGORY_KEYWORDS)) {
      if (lowerName.includes(keyword)) return category;
    }
    return 'other';
  }, []);

  // Parse NLP input (splits by comma, "and", etc.)
  const parseItemInput = useCallback((input: string): { name: string; quantity: string }[] => {
    // Split by comma, "and", "&"
    const parts = input.split(/,|\band\b|&/i).map(p => p.trim()).filter(p => p.length > 0);
    return parts.map(part => {
      // Try to extract quantity (e.g., "2 gallons of milk" -> qty: "2 gallons", name: "milk")
      const qtyMatch = part.match(/^(\d+\s*(?:lb|lbs|oz|gal|gallons?|pack|dozen|count|rolls?|bottles?)?)\s+(?:of\s+)?(.+)$/i);
      if (qtyMatch && qtyMatch[1] && qtyMatch[2]) {
        return { quantity: qtyMatch[1], name: qtyMatch[2] };
      }
      // Check for quantity at end (e.g., "milk 2 gallons")
      const qtyEndMatch = part.match(/^(.+?)\s+(\d+\s*(?:lb|lbs|oz|gal|gallons?|pack|dozen|count|rolls?|bottles?)?)$/i);
      if (qtyEndMatch && qtyEndMatch[1] && qtyEndMatch[2]) {
        return { quantity: qtyEndMatch[2], name: qtyEndMatch[1] };
      }
      return { quantity: '1', name: part };
    });
  }, []);

  // Add items from input - with NLP parsing and optimistic API sync
  const handleAddItems = useCallback(async () => {
    if (!newItemInput.trim()) return;

    const parsedItems = parseItemInput(newItemInput);
    const timestamp = Date.now();

    // Create optimistic items with temporary IDs
    const newItems: ShoppingItem[] = parsedItems.map((parsed, idx) => ({
      id: `item-temp-${timestamp}-${idx}`,
      listId: activeListId,
      name: parsed.name.charAt(0).toUpperCase() + parsed.name.slice(1),
      quantity: parsed.quantity,
      category: categorizeItem(parsed.name),
      checked: false,
      starred: false,
      addedAt: new Date(),
    }));

    // Extract temp IDs for tracking
    const tempIds = newItems.map(item => item.id);

    // Optimistic update - add to UI immediately
    setItems(prev => [...prev, ...newItems]);
    setNewItemInput('');

    // Update list count optimistically
    setLists(prev => prev.map(l =>
      l.id === activeListId ? { ...l, itemCount: l.itemCount + newItems.length } : l
    ));

    // Sync with API in background (API endpoints not yet implemented)
    if (currentHousehold?.id) {
      try {
        type FutureApiClient = {
          createShoppingItem?: (householdId: string, item: Record<string, unknown>) => Promise<unknown>;
        };
        const api = getApiClient() as unknown as FutureApiClient;
        const apiItems = await Promise.all(
          newItems.map(item =>
            api.createShoppingItem?.(currentHousehold.id, {
              listId: item.listId,
              name: item.name,
              quantity: item.quantity,
              category: item.category,
            }) ?? Promise.resolve(null)
          )
        );

        // Replace temp IDs with real IDs from API
        setItems(prev => prev.map(item => {
          const tempIndex = tempIds.indexOf(item.id);
          if (tempIndex >= 0 && apiItems[tempIndex]) {
            const apiItem = apiItems[tempIndex] as Record<string, unknown>;
            return { ...item, id: String(apiItem.id || item.id) };
          }
          return item;
        }));
      } catch (error) {
        console.error('Failed to sync new items to API:', error);
        // Items remain in UI with temp IDs - will sync on next load
      }
    }
  }, [newItemInput, activeListId, parseItemInput, categorizeItem, currentHousehold?.id]);

  // Toggle item checked - with debounced API sync
  const toggleItemChecked = useCallback((itemId: string) => {
    // Optimistic update - toggle immediately in UI
    setItems(prev => prev.map(item =>
      item.id === itemId ? { ...item, checked: !item.checked } : item
    ));

    // Clear any pending timeout for this item
    if (pendingCheckUpdates.current[itemId]) {
      clearTimeout(pendingCheckUpdates.current[itemId]);
    }

    // Debounced API call (API endpoints not yet implemented)
    pendingCheckUpdates.current[itemId] = setTimeout(async () => {
      try {
        type FutureApiClient = {
          updateShoppingItem?: (householdId: string, itemId: string, data: Record<string, unknown>) => Promise<unknown>;
        };
        const api = getApiClient() as unknown as FutureApiClient;
        const item = items.find(i => i.id === itemId);
        if (item && currentHousehold?.id) {
          // Call API to persist the change
          await api.updateShoppingItem?.(currentHousehold.id, itemId, {
            checked: !item.checked,
          });
        }
      } catch (err: unknown) {
        console.error('Failed to sync item check status:', err);
        // Revert on failure
        setItems(prev => prev.map(item =>
          item.id === itemId ? { ...item, checked: !item.checked } : item
        ));
      } finally {
        delete pendingCheckUpdates.current[itemId];
      }
    }, DEBOUNCE_MS);
  }, [items, currentHousehold?.id]);

  // Toggle item starred - with optimistic API sync
  const toggleItemStarred = useCallback((itemId: string) => {
    // Optimistic update
    setItems(prev => prev.map(item =>
      item.id === itemId ? { ...item, starred: !item.starred } : item
    ));

    // Sync to API (no debounce needed for star - less frequent action)
    // API endpoints not yet implemented
    if (currentHousehold?.id) {
      const item = items.find(i => i.id === itemId);
      if (item) {
        type FutureApiClient = {
          updateShoppingItem?: (householdId: string, itemId: string, data: Record<string, unknown>) => Promise<unknown>;
        };
        const api = getApiClient() as unknown as FutureApiClient;
        api.updateShoppingItem?.(currentHousehold.id, itemId, {
          starred: !item.starred,
        })?.catch((err: unknown) => {
          console.error('Failed to sync star status:', err);
          // Revert on failure
          setItems(prev => prev.map(i =>
            i.id === itemId ? { ...i, starred: !i.starred } : i
          ));
        });
      }
    }
  }, [items, currentHousehold?.id]);

  // Delete item - with optimistic API sync
  const deleteItem = useCallback((itemId: string) => {
    // Store item for potential rollback
    const deletedItem = items.find(i => i.id === itemId);

    // Optimistic delete
    setItems(prev => prev.filter(item => item.id !== itemId));
    setLists(prev => prev.map(l =>
      l.id === activeListId ? { ...l, itemCount: Math.max(0, l.itemCount - 1) } : l
    ));

    // Sync to API (API endpoints not yet implemented)
    if (currentHousehold?.id && deletedItem) {
      type FutureApiClient = {
        deleteShoppingItem?: (householdId: string, itemId: string) => Promise<unknown>;
      };
      const api = getApiClient() as unknown as FutureApiClient;
      api.deleteShoppingItem?.(currentHousehold.id, itemId)?.catch((err: unknown) => {
        console.error('Failed to delete item from API:', err);
        // Revert on failure
        if (deletedItem) {
          setItems(prev => [...prev, deletedItem]);
          setLists(prev => prev.map(l =>
            l.id === activeListId ? { ...l, itemCount: l.itemCount + 1 } : l
          ));
        }
      });
    }
  }, [activeListId, items, currentHousehold?.id]);

  // Move item to inventory - with optimistic API sync
  const moveToInventory = useCallback((item: ShoppingItem) => {
    const tempId = `inv-temp-${Date.now()}`;
    const newInventoryItem: InventoryItem = {
      id: tempId,
      name: item.name,
      category: item.category,
      currentQty: parseInt(item.quantity) || 1,
      targetQty: (parseInt(item.quantity) || 1) * 2,
      unit: 'count',
      lowStock: false,
      location: 'To Be Assigned',
    };

    // Optimistic update
    setInventory(prev => [...prev, newInventoryItem]);
    deleteItem(item.id);

    // Sync to API (API endpoints not yet implemented)
    if (currentHousehold?.id) {
      type FutureApiClient = {
        createInventoryItem?: (householdId: string, item: Record<string, unknown>) => Promise<unknown>;
      };
      const api = getApiClient() as unknown as FutureApiClient;
      api.createInventoryItem?.(currentHousehold.id, {
        name: newInventoryItem.name,
        category: newInventoryItem.category,
        currentQty: newInventoryItem.currentQty,
        targetQty: newInventoryItem.targetQty,
        unit: newInventoryItem.unit,
        location: newInventoryItem.location,
      })?.then((response: unknown) => {
        // Replace temp ID with real ID
        if (response) {
          const apiItem = response as Record<string, unknown>;
          setInventory(prev => prev.map(inv =>
            inv.id === tempId ? { ...inv, id: String(apiItem.id || inv.id) } : inv
          ));
        }
      }).catch((err: unknown) => {
        console.error('Failed to create inventory item:', err);
        // Keep item in UI with temp ID - will sync on next load
      });
    }
  }, [deleteItem, currentHousehold?.id]);

  // Add inventory item to shopping list - with optimistic API sync
  const addToShoppingList = useCallback((invItem: InventoryItem) => {
    const tempId = `item-from-inv-${Date.now()}`;
    const newItem: ShoppingItem = {
      id: tempId,
      listId: activeListId,
      name: invItem.name,
      quantity: `${invItem.targetQty - invItem.currentQty} ${invItem.unit}`,
      category: invItem.category,
      checked: false,
      starred: true,
      addedAt: new Date(),
    };

    // Optimistic update
    setItems(prev => [...prev, newItem]);
    setLists(prev => prev.map(l =>
      l.id === activeListId ? { ...l, itemCount: l.itemCount + 1 } : l
    ));

    // Sync to API (API endpoints not yet implemented)
    if (currentHousehold?.id) {
      type FutureApiClient = {
        createShoppingItem?: (householdId: string, item: Record<string, unknown>) => Promise<unknown>;
      };
      const api = getApiClient() as unknown as FutureApiClient;
      api.createShoppingItem?.(currentHousehold.id, {
        listId: newItem.listId,
        name: newItem.name,
        quantity: newItem.quantity,
        category: newItem.category,
        starred: true,
      })?.then((response: unknown) => {
        if (response) {
          const apiItem = response as Record<string, unknown>;
          setItems(prev => prev.map(item =>
            item.id === tempId ? { ...item, id: String(apiItem.id || item.id) } : item
          ));
        }
      }).catch((err: unknown) => {
        console.error('Failed to add item to shopping list:', err);
        // Keep item in UI with temp ID
      });
    }
  }, [activeListId, currentHousehold?.id]);

  // Update inventory quantity - with debounced API sync for rapid +/- clicks
  const updateInventoryQty = useCallback((invId: string, newQty: number) => {
    // Optimistic update
    setInventory(prev => prev.map(inv => {
      if (inv.id !== invId) return inv;
      const lowStock = newQty < inv.targetQty * 0.25;
      return { ...inv, currentQty: newQty, lowStock };
    }));

    // Clear any pending timeout for this inventory item
    if (pendingInventoryUpdates.current[invId]) {
      clearTimeout(pendingInventoryUpdates.current[invId]);
    }

    // Debounced API call - waits for user to stop clicking +/-
    // API endpoints not yet implemented
    pendingInventoryUpdates.current[invId] = setTimeout(async () => {
      try {
        if (currentHousehold?.id) {
          type FutureApiClient = {
            updateInventoryItem?: (householdId: string, invId: string, data: Record<string, unknown>) => Promise<unknown>;
          };
          const api = getApiClient() as unknown as FutureApiClient;
          await api.updateInventoryItem?.(currentHousehold.id, invId, {
            currentQty: newQty,
          });
        }
      } catch (err: unknown) {
        console.error('Failed to sync inventory quantity:', err);
        // Note: We don't revert here as the user has likely clicked multiple times
        // The next load will sync the correct value from the server
      } finally {
        delete pendingInventoryUpdates.current[invId];
      }
    }, DEBOUNCE_MS);
  }, [currentHousehold?.id]);

  // Submit order
  const handleSubmitOrder = useCallback(() => {
    // Update list with pending order
    setLists(prev => prev.map(l =>
      l.id === activeListId ? {
        ...l,
        pendingOrder: {
          orderId: `ORD-${Date.now().toString().slice(-4)}`,
          status: 'pending',
          vendor: orderVendor === 'whole_foods' ? 'Whole Foods' :
                  orderVendor === 'instacart' ? 'Instacart' : 'Local Courier',
          eta: deliveryDate && deliveryTime ? `${deliveryDate} at ${deliveryTime}` : 'Processing',
        }
      } : l
    ));
    setShowOrderModal(false);
    // Reset form
    setOrderVendor('whole_foods');
    setAllowSubstitutions(true);
    setDeliveryDate('');
    setDeliveryTime('');
    setOrderNotes('');
  }, [activeListId, orderVendor, deliveryDate, deliveryTime]);

  // Order status badge
  const getOrderStatusBadge = (status: OrderStatus) => {
    switch (status) {
      case 'pending':
        return <span className="inline-flex items-center gap-1 px-2 py-1 rounded-full text-xs font-medium bg-amber-100 text-amber-700"><Clock className="w-3 h-3" /> Pending</span>;
      case 'processing':
        return <span className="inline-flex items-center gap-1 px-2 py-1 rounded-full text-xs font-medium bg-blue-100 text-blue-700"><RefreshCw className="w-3 h-3 animate-spin" /> Processing</span>;
      case 'in_transit':
        return <span className="inline-flex items-center gap-1 px-2 py-1 rounded-full text-xs font-medium bg-emerald-100 text-emerald-700"><Truck className="w-3 h-3" /> In Transit</span>;
      case 'delivered':
        return <span className="inline-flex items-center gap-1 px-2 py-1 rounded-full text-xs font-medium bg-green-100 text-green-700"><CheckCircle2 className="w-3 h-3" /> Delivered</span>;
    }
  };

  return (
    <div className="min-h-screen bg-slate-50">
      {/* Header */}
      <div className="bg-white border-b border-slate-200 sticky top-0 z-30">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4">
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-2xl font-bold text-slate-900">Inventory</h1>
              <p className="text-sm text-slate-500 mt-0.5">Shopping & Procurement</p>
            </div>

            {/* View Mode Toggle (Mobile) */}
            <div className="flex md:hidden bg-slate-100 rounded-lg p-1">
              <button
                onClick={() => setViewMode('lists')}
                className={`px-4 py-2 rounded-md text-sm font-medium transition-colors ${
                  viewMode === 'lists'
                    ? 'bg-white text-slate-900 shadow-sm'
                    : 'text-slate-600'
                }`}
              >
                <ListChecks className="w-4 h-4" />
              </button>
              <button
                onClick={() => setViewMode('inventory')}
                className={`px-4 py-2 rounded-md text-sm font-medium transition-colors relative ${
                  viewMode === 'inventory'
                    ? 'bg-white text-slate-900 shadow-sm'
                    : 'text-slate-600'
                }`}
              >
                <Archive className="w-4 h-4" />
                {lowStockCount > 0 && (
                  <span className="absolute -top-1 -right-1 w-4 h-4 bg-red-500 text-white text-xs rounded-full flex items-center justify-center">
                    {lowStockCount}
                  </span>
                )}
              </button>
            </div>
          </div>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
        <div className="flex flex-col md:flex-row gap-6">
          {/* Left Sidebar - Lists (Desktop) or shown when viewMode === 'lists' on mobile */}
          <div className={`${viewMode === 'lists' ? 'block' : 'hidden'} md:block md:w-80 flex-shrink-0`}>
            <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-4">
              <div className="flex items-center justify-between mb-4">
                <h2 className="font-semibold text-slate-900">Shopping Lists</h2>
                <button className="p-2 hover:bg-slate-100 rounded-lg transition-colors text-emerald-600">
                  <Plus className="w-5 h-5" />
                </button>
              </div>

              <div className="space-y-2">
                {lists.map(list => {
                  const ListIcon = list.icon;
                  return (
                    <button
                      key={list.id}
                      onClick={() => {
                        setActiveListId(list.id);
                        setViewMode('lists');
                      }}
                      className={`w-full flex items-center gap-3 p-3 rounded-lg transition-colors text-left ${
                        activeListId === list.id
                          ? 'bg-emerald-50 text-emerald-700 border border-emerald-200'
                          : 'hover:bg-slate-50 text-slate-700'
                      }`}
                    >
                      <ListIcon className="w-5 h-5 flex-shrink-0" />
                      <div className="flex-1 min-w-0">
                        <div className="font-medium truncate">{list.name}</div>
                        <div className="text-xs text-slate-500">{list.itemCount} items</div>
                      </div>
                      {list.pendingOrder && (
                        <div className="flex-shrink-0">
                          {getOrderStatusBadge(list.pendingOrder.status)}
                        </div>
                      )}
                      <ChevronRight className="w-4 h-4 flex-shrink-0 text-slate-400" />
                    </button>
                  );
                })}
              </div>

              {/* Inventory Section in Sidebar */}
              <div className="mt-6 pt-4 border-t border-slate-200">
                <button
                  onClick={() => setViewMode('inventory')}
                  className={`w-full flex items-center gap-3 p-3 rounded-lg transition-colors text-left ${
                    viewMode === 'inventory'
                      ? 'bg-emerald-50 text-emerald-700 border border-emerald-200'
                      : 'hover:bg-slate-50 text-slate-700'
                  }`}
                >
                  <Package className="w-5 h-5 flex-shrink-0" />
                  <div className="flex-1 min-w-0">
                    <div className="font-medium">Household Inventory</div>
                    <div className="text-xs text-slate-500">{inventory.length} items tracked</div>
                  </div>
                  {lowStockCount > 0 && (
                    <span className="flex-shrink-0 px-2 py-0.5 bg-red-100 text-red-700 text-xs font-medium rounded-full">
                      {lowStockCount} low
                    </span>
                  )}
                </button>
              </div>
            </div>
          </div>

          {/* Main Content Area */}
          <div className="flex-1">
            {viewMode === 'lists' ? (
              <>
                {/* Active List Header */}
                {activeList && (
                  <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-4 mb-4">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-3">
                        {(() => {
                          const ListIcon = activeList.icon;
                          return <ListIcon className="w-6 h-6 text-emerald-600" />;
                        })()}
                        <div>
                          <h2 className="font-semibold text-slate-900">{activeList.name}</h2>
                          <p className="text-sm text-slate-500">
                            {activeItems.filter(i => !i.checked).length} remaining, {activeItems.filter(i => i.checked).length} checked off
                          </p>
                        </div>
                      </div>

                      {activeList.pendingOrder ? (
                        <div className="flex items-center gap-3">
                          {getOrderStatusBadge(activeList.pendingOrder.status)}
                          <div className="text-right">
                            <div className="text-xs text-slate-500">Order #{activeList.pendingOrder.orderId}</div>
                            <div className="text-sm font-medium text-slate-700">{activeList.pendingOrder.eta}</div>
                          </div>
                        </div>
                      ) : (
                        <button
                          onClick={() => setShowOrderModal(true)}
                          className="flex items-center gap-2 px-4 py-2 bg-emerald-600 text-white rounded-lg hover:bg-emerald-700 transition-colors font-medium shadow-sm"
                        >
                          <Send className="w-4 h-4" />
                          <span className="hidden sm:inline">Send to Manager</span>
                        </button>
                      )}
                    </div>
                  </div>
                )}

                {/* Smart Input */}
                <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-4 mb-4">
                  <div className="flex gap-3">
                    <div className="flex-1 relative">
                      <input
                        type="text"
                        value={newItemInput}
                        onChange={(e) => setNewItemInput(e.target.value)}
                        onKeyDown={(e) => e.key === 'Enter' && handleAddItems()}
                        placeholder="Add items... (e.g., Milk, Eggs, and AA Batteries)"
                        className="w-full px-4 py-3 pr-12 border border-slate-300 rounded-lg focus:ring-2 focus:ring-emerald-600 focus:border-transparent text-slate-800 placeholder:text-slate-400"
                      />
                      <button className="absolute right-3 top-1/2 -translate-y-1/2 p-1.5 hover:bg-slate-100 rounded-lg transition-colors text-slate-400 hover:text-slate-600">
                        <ScanBarcode className="w-5 h-5" />
                      </button>
                    </div>
                    <button
                      onClick={handleAddItems}
                      disabled={!newItemInput.trim()}
                      className="px-4 py-3 bg-emerald-600 text-white rounded-lg hover:bg-emerald-700 transition-colors font-medium shadow-sm disabled:opacity-50 disabled:cursor-not-allowed"
                    >
                      <Plus className="w-5 h-5" />
                    </button>
                  </div>
                  <p className="text-xs text-slate-500 mt-2">
                    Tip: Separate items with commas or &quot;and&quot; to add multiple at once
                  </p>
                </div>

                {/* Search */}
                <div className="relative mb-4">
                  <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-slate-400" />
                  <input
                    type="text"
                    value={searchQuery}
                    onChange={(e) => setSearchQuery(e.target.value)}
                    placeholder="Search items..."
                    className="w-full pl-10 pr-4 py-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-emerald-600 focus:border-transparent bg-white text-slate-800"
                  />
                </div>

                {/* Items by Category */}
                {activeItems.length === 0 ? (
                  <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-12 text-center">
                    <ShoppingBag className="w-16 h-16 text-slate-300 mx-auto mb-4" />
                    <h3 className="text-lg font-medium text-slate-700 mb-2">Your list is empty</h3>
                    <p className="text-slate-500">Start typing or scan a barcode to add items</p>
                  </div>
                ) : (
                  <div className="space-y-4">
                    {Object.entries(groupedItems).map(([category, categoryItems]) => {
                      const catConfig = CATEGORIES[category as ItemCategory];
                      const CatIcon = catConfig.icon;
                      return (
                        <div key={category} className="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
                          {/* Category Header */}
                          <div className={`flex items-center gap-2 px-4 py-2.5 ${catConfig.color} border-b border-slate-100`}>
                            <GripVertical className="w-4 h-4 text-slate-400 cursor-grab" />
                            <CatIcon className="w-4 h-4" />
                            <span className="font-medium text-sm">{catConfig.label}</span>
                            <span className="text-xs opacity-60">({categoryItems.length})</span>
                          </div>

                          {/* Items */}
                          <div className="divide-y divide-slate-100">
                            {categoryItems.map(item => (
                              <div
                                key={item.id}
                                className={`flex items-center gap-3 px-4 py-3 transition-colors ${
                                  item.checked ? 'bg-slate-50 opacity-60' : 'hover:bg-slate-50'
                                }`}
                              >
                                {/* Checkbox */}
                                <button
                                  onClick={() => toggleItemChecked(item.id)}
                                  className={`w-6 h-6 rounded-full border-2 flex items-center justify-center flex-shrink-0 transition-colors ${
                                    item.checked
                                      ? 'bg-emerald-600 border-emerald-600 text-white'
                                      : 'border-slate-300 hover:border-emerald-500'
                                  }`}
                                >
                                  {item.checked && <Check className="w-4 h-4" />}
                                </button>

                                {/* Item Details */}
                                <div className="flex-1 min-w-0">
                                  <div className={`font-medium ${item.checked ? 'line-through text-slate-500' : 'text-slate-800'}`}>
                                    {item.name}
                                  </div>
                                  <div className="text-sm text-slate-500">{item.quantity}</div>
                                </div>

                                {/* Star */}
                                <button
                                  onClick={() => toggleItemStarred(item.id)}
                                  className={`p-1.5 rounded-lg transition-colors ${
                                    item.starred
                                      ? 'text-amber-500 hover:bg-amber-50'
                                      : 'text-slate-300 hover:text-amber-500 hover:bg-slate-100'
                                  }`}
                                >
                                  <Star className={`w-5 h-5 ${item.starred ? 'fill-current' : ''}`} />
                                </button>

                                {/* Edit */}
                                <button
                                  onClick={() => setEditingItem(item)}
                                  className="p-1.5 hover:bg-slate-100 rounded-lg transition-colors text-slate-400 hover:text-slate-600"
                                >
                                  <Pencil className="w-4 h-4" />
                                </button>

                                {/* Move to Inventory */}
                                <button
                                  onClick={() => moveToInventory(item)}
                                  className="p-1.5 hover:bg-emerald-50 rounded-lg transition-colors text-slate-400 hover:text-emerald-600"
                                  title="Move to Inventory"
                                >
                                  <BoxIcon className="w-4 h-4" />
                                </button>

                                {/* Delete */}
                                <button
                                  onClick={() => deleteItem(item.id)}
                                  className="p-1.5 hover:bg-red-50 rounded-lg transition-colors text-slate-400 hover:text-red-600"
                                >
                                  <Trash2 className="w-4 h-4" />
                                </button>
                              </div>
                            ))}
                          </div>
                        </div>
                      );
                    })}
                  </div>
                )}
              </>
            ) : (
              /* Inventory View */
              <>
                <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-4 mb-4">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-3">
                      <Package className="w-6 h-6 text-emerald-600" />
                      <div>
                        <h2 className="font-semibold text-slate-900">Household Inventory</h2>
                        <p className="text-sm text-slate-500">
                          {inventory.length} items tracked, {lowStockCount} low stock
                        </p>
                      </div>
                    </div>
                    <button
                      onClick={() => {
                        setEditingInventory(null);
                        setShowInventoryModal(true);
                      }}
                      className="flex items-center gap-2 px-4 py-2 bg-emerald-600 text-white rounded-lg hover:bg-emerald-700 transition-colors font-medium shadow-sm"
                    >
                      <Plus className="w-4 h-4" />
                      <span className="hidden sm:inline">Add Item</span>
                    </button>
                  </div>
                </div>

                {/* Low Stock Alert */}
                {lowStockCount > 0 && (
                  <div className="bg-amber-50 border border-amber-200 rounded-xl p-4 mb-4 flex items-start gap-3">
                    <AlertTriangle className="w-5 h-5 text-amber-600 flex-shrink-0 mt-0.5" />
                    <div>
                      <h3 className="font-medium text-amber-800">Low Stock Alert</h3>
                      <p className="text-sm text-amber-700 mt-1">
                        {lowStockCount} items are running low and should be restocked soon.
                      </p>
                    </div>
                  </div>
                )}

                {/* Search */}
                <div className="relative mb-4">
                  <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-slate-400" />
                  <input
                    type="text"
                    value={searchQuery}
                    onChange={(e) => setSearchQuery(e.target.value)}
                    placeholder="Search inventory..."
                    className="w-full pl-10 pr-4 py-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-emerald-600 focus:border-transparent bg-white text-slate-800"
                  />
                </div>

                {/* Inventory Grid */}
                <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
                  {filteredInventory.map(item => {
                    const catConfig = CATEGORIES[item.category];
                    const CatIcon = catConfig.icon;
                    const stockPercent = Math.round((item.currentQty / item.targetQty) * 100);

                    return (
                      <div
                        key={item.id}
                        className={`bg-white rounded-xl shadow-sm border p-4 ${
                          item.lowStock ? 'border-amber-300 bg-amber-50/30' : 'border-slate-200'
                        }`}
                      >
                        <div className="flex items-start justify-between mb-3">
                          <div className="flex items-center gap-2">
                            <div className={`p-2 rounded-lg ${catConfig.color}`}>
                              <CatIcon className="w-4 h-4" />
                            </div>
                            <div>
                              <h3 className="font-medium text-slate-900">{item.name}</h3>
                              {item.location && (
                                <p className="text-xs text-slate-500">{item.location}</p>
                              )}
                            </div>
                          </div>
                          {item.lowStock && (
                            <AlertTriangle className="w-5 h-5 text-amber-500" />
                          )}
                        </div>

                        {/* Stock Level Bar */}
                        <div className="mb-3">
                          <div className="flex items-center justify-between text-sm mb-1">
                            <span className="text-slate-600">{item.currentQty} / {item.targetQty} {item.unit}</span>
                            <span className={`font-medium ${stockPercent < 25 ? 'text-red-600' : stockPercent < 50 ? 'text-amber-600' : 'text-emerald-600'}`}>
                              {stockPercent}%
                            </span>
                          </div>
                          <div className="w-full h-2 bg-slate-200 rounded-full overflow-hidden">
                            <div
                              className={`h-full rounded-full transition-all ${
                                stockPercent < 25 ? 'bg-red-500' : stockPercent < 50 ? 'bg-amber-500' : 'bg-emerald-500'
                              }`}
                              style={{ width: `${Math.min(100, stockPercent)}%` }}
                            />
                          </div>
                        </div>

                        {/* Quick Actions */}
                        <div className="flex items-center gap-2">
                          <div className="flex items-center bg-slate-100 rounded-lg">
                            <button
                              onClick={() => updateInventoryQty(item.id, Math.max(0, item.currentQty - 1))}
                              className="px-3 py-1.5 text-slate-600 hover:bg-slate-200 rounded-l-lg transition-colors"
                            >
                              −
                            </button>
                            <span className="px-3 py-1.5 font-medium text-slate-800">{item.currentQty}</span>
                            <button
                              onClick={() => updateInventoryQty(item.id, item.currentQty + 1)}
                              className="px-3 py-1.5 text-slate-600 hover:bg-slate-200 rounded-r-lg transition-colors"
                            >
                              +
                            </button>
                          </div>

                          {item.lowStock && (
                            <button
                              onClick={() => addToShoppingList(item)}
                              className="flex-1 flex items-center justify-center gap-1.5 px-3 py-1.5 bg-emerald-600 text-white rounded-lg hover:bg-emerald-700 transition-colors text-sm font-medium"
                            >
                              <ShoppingCart className="w-4 h-4" />
                              Add to List
                            </button>
                          )}
                        </div>
                      </div>
                    );
                  })}
                </div>
              </>
            )}
          </div>
        </div>
      </div>

      {/* Order Modal */}
      {showOrderModal && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-xl shadow-xl max-w-lg w-full max-h-[90vh] overflow-y-auto">
            <div className="p-6 border-b border-slate-200">
              <div className="flex items-center justify-between">
                <h2 className="text-xl font-bold text-slate-900">Send to Manager</h2>
                <button
                  onClick={() => setShowOrderModal(false)}
                  className="p-2 hover:bg-slate-100 rounded-lg transition-colors"
                >
                  <X className="w-5 h-5 text-slate-500" />
                </button>
              </div>
              <p className="text-sm text-slate-500 mt-1">
                Your Home Manager will fulfill this order for you
              </p>
            </div>

            <div className="p-6 space-y-5">
              {/* Vendor Selection */}
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-2">
                  Preferred Vendor
                </label>
                <div className="grid grid-cols-3 gap-3">
                  {[
                    { id: 'whole_foods', name: 'Whole Foods', icon: Store },
                    { id: 'instacart', name: 'Instacart', icon: ShoppingCart },
                    { id: 'courier', name: 'Local Courier', icon: Truck },
                  ].map(vendor => {
                    const VendorIcon = vendor.icon;
                    return (
                      <button
                        key={vendor.id}
                        onClick={() => setOrderVendor(vendor.id)}
                        className={`p-3 rounded-lg border-2 transition-colors text-center ${
                          orderVendor === vendor.id
                            ? 'border-emerald-600 bg-emerald-50'
                            : 'border-slate-200 hover:border-slate-300'
                        }`}
                      >
                        <VendorIcon className={`w-6 h-6 mx-auto mb-1 ${orderVendor === vendor.id ? 'text-emerald-600' : 'text-slate-500'}`} />
                        <div className={`text-sm font-medium ${orderVendor === vendor.id ? 'text-emerald-700' : 'text-slate-700'}`}>
                          {vendor.name}
                        </div>
                      </button>
                    );
                  })}
                </div>
              </div>

              {/* Delivery Window */}
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-2">
                  <Calendar className="w-4 h-4 inline mr-1" />
                  Delivery Window
                </label>
                <div className="grid grid-cols-2 gap-3">
                  <input
                    type="date"
                    value={deliveryDate}
                    onChange={(e) => setDeliveryDate(e.target.value)}
                    className="px-4 py-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-emerald-600 focus:border-transparent"
                  />
                  <input
                    type="time"
                    value={deliveryTime}
                    onChange={(e) => setDeliveryTime(e.target.value)}
                    className="px-4 py-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-emerald-600 focus:border-transparent"
                  />
                </div>
              </div>

              {/* Substitutions Toggle */}
              <div className="flex items-center justify-between">
                <div>
                  <div className="font-medium text-slate-800">Allow Substitutions</div>
                  <div className="text-sm text-slate-500">If an item is unavailable, allow similar alternatives</div>
                </div>
                <button
                  onClick={() => setAllowSubstitutions(!allowSubstitutions)}
                  className="text-emerald-600"
                >
                  {allowSubstitutions ? (
                    <ToggleRight className="w-10 h-10" />
                  ) : (
                    <ToggleLeft className="w-10 h-10 text-slate-400" />
                  )}
                </button>
              </div>

              {/* Notes */}
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-2">
                  <MessageCircle className="w-4 h-4 inline mr-1" />
                  Special Instructions
                </label>
                <textarea
                  value={orderNotes}
                  onChange={(e) => setOrderNotes(e.target.value)}
                  placeholder="e.g., Please get green bananas, prefer organic if available..."
                  rows={3}
                  className="w-full px-4 py-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-emerald-600 focus:border-transparent resize-none"
                />
              </div>

              {/* Order Summary */}
              <div className="bg-slate-50 rounded-lg p-4">
                <h3 className="font-medium text-slate-800 mb-2">Order Summary</h3>
                <div className="text-sm text-slate-600 space-y-1">
                  <div className="flex justify-between">
                    <span>Items</span>
                    <span>{activeItems.filter(i => !i.checked).length} items</span>
                  </div>
                  <div className="flex justify-between">
                    <span>Priority Items</span>
                    <span>{activeItems.filter(i => i.starred && !i.checked).length} starred</span>
                  </div>
                </div>
              </div>
            </div>

            <div className="p-6 border-t border-slate-200 bg-slate-50 rounded-b-xl">
              <div className="flex gap-3">
                <button
                  onClick={() => setShowOrderModal(false)}
                  className="flex-1 px-4 py-2.5 border border-slate-300 rounded-lg hover:bg-slate-100 transition-colors font-medium text-slate-700"
                >
                  Cancel
                </button>
                <button
                  onClick={handleSubmitOrder}
                  className="flex-1 flex items-center justify-center gap-2 px-4 py-2.5 bg-emerald-600 text-white rounded-lg hover:bg-emerald-700 transition-colors font-medium shadow-sm"
                >
                  <Send className="w-4 h-4" />
                  Send Order
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Edit Item Modal */}
      {editingItem && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-xl shadow-xl max-w-md w-full">
            <div className="p-6 border-b border-slate-200">
              <div className="flex items-center justify-between">
                <h2 className="text-xl font-bold text-slate-900">Edit Item</h2>
                <button
                  onClick={() => setEditingItem(null)}
                  className="p-2 hover:bg-slate-100 rounded-lg transition-colors"
                >
                  <X className="w-5 h-5 text-slate-500" />
                </button>
              </div>
            </div>

            <div className="p-6 space-y-4">
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Item Name</label>
                <input
                  type="text"
                  value={editingItem.name}
                  onChange={(e) => setEditingItem({ ...editingItem, name: e.target.value })}
                  className="w-full px-4 py-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-emerald-600 focus:border-transparent"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Quantity</label>
                <input
                  type="text"
                  value={editingItem.quantity}
                  onChange={(e) => setEditingItem({ ...editingItem, quantity: e.target.value })}
                  className="w-full px-4 py-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-emerald-600 focus:border-transparent"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Category</label>
                <select
                  value={editingItem.category}
                  onChange={(e) => setEditingItem({ ...editingItem, category: e.target.value as ItemCategory })}
                  className="w-full px-4 py-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-emerald-600 focus:border-transparent"
                >
                  {Object.entries(CATEGORIES).map(([key, cat]) => (
                    <option key={key} value={key}>{cat.label}</option>
                  ))}
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Notes (optional)</label>
                <textarea
                  value={editingItem.notes || ''}
                  onChange={(e) => setEditingItem({ ...editingItem, notes: e.target.value })}
                  placeholder="Any special notes..."
                  rows={2}
                  className="w-full px-4 py-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-emerald-600 focus:border-transparent resize-none"
                />
              </div>
            </div>

            <div className="p-6 border-t border-slate-200 bg-slate-50 rounded-b-xl">
              <div className="flex gap-3">
                <button
                  onClick={() => setEditingItem(null)}
                  className="flex-1 px-4 py-2.5 border border-slate-300 rounded-lg hover:bg-slate-100 transition-colors font-medium text-slate-700"
                >
                  Cancel
                </button>
                <button
                  onClick={() => {
                    setItems(prev => prev.map(i => i.id === editingItem.id ? editingItem : i));
                    setEditingItem(null);
                  }}
                  className="flex-1 px-4 py-2.5 bg-emerald-600 text-white rounded-lg hover:bg-emerald-700 transition-colors font-medium shadow-sm"
                >
                  Save Changes
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Add/Edit Inventory Modal */}
      {showInventoryModal && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-xl shadow-xl max-w-md w-full">
            <div className="p-6 border-b border-slate-200">
              <div className="flex items-center justify-between">
                <h2 className="text-xl font-bold text-slate-900">
                  {editingInventory ? 'Edit Inventory Item' : 'Add to Inventory'}
                </h2>
                <button
                  onClick={() => {
                    setShowInventoryModal(false);
                    setEditingInventory(null);
                  }}
                  className="p-2 hover:bg-slate-100 rounded-lg transition-colors"
                >
                  <X className="w-5 h-5 text-slate-500" />
                </button>
              </div>
            </div>

            <div className="p-6 space-y-4">
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Item Name</label>
                <input
                  type="text"
                  placeholder="e.g., Paper Towels"
                  className="w-full px-4 py-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-emerald-600 focus:border-transparent"
                />
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">Current Qty</label>
                  <input
                    type="number"
                    min="0"
                    placeholder="0"
                    className="w-full px-4 py-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-emerald-600 focus:border-transparent"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">Target Qty</label>
                  <input
                    type="number"
                    min="1"
                    placeholder="12"
                    className="w-full px-4 py-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-emerald-600 focus:border-transparent"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">Unit</label>
                  <select className="w-full px-4 py-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-emerald-600 focus:border-transparent">
                    <option value="count">Count</option>
                    <option value="rolls">Rolls</option>
                    <option value="bottles">Bottles</option>
                    <option value="bags">Bags</option>
                    <option value="boxes">Boxes</option>
                    <option value="lbs">Lbs</option>
                    <option value="oz">Oz</option>
                  </select>
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">Category</label>
                  <select className="w-full px-4 py-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-emerald-600 focus:border-transparent">
                    {Object.entries(CATEGORIES).map(([key, cat]) => (
                      <option key={key} value={key}>{cat.label}</option>
                    ))}
                  </select>
                </div>
              </div>

              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Location</label>
                <input
                  type="text"
                  placeholder="e.g., Hall Closet, Garage, Kitchen Pantry"
                  className="w-full px-4 py-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-emerald-600 focus:border-transparent"
                />
              </div>
            </div>

            <div className="p-6 border-t border-slate-200 bg-slate-50 rounded-b-xl">
              <div className="flex gap-3">
                <button
                  onClick={() => {
                    setShowInventoryModal(false);
                    setEditingInventory(null);
                  }}
                  className="flex-1 px-4 py-2.5 border border-slate-300 rounded-lg hover:bg-slate-100 transition-colors font-medium text-slate-700"
                >
                  Cancel
                </button>
                <button
                  onClick={() => {
                    setShowInventoryModal(false);
                    setEditingInventory(null);
                  }}
                  className="flex-1 px-4 py-2.5 bg-emerald-600 text-white rounded-lg hover:bg-emerald-700 transition-colors font-medium shadow-sm"
                >
                  {editingInventory ? 'Save Changes' : 'Add Item'}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Mobile FAB - positioned above the global chat FAB */}
      <button
        onClick={() => setShowAddItemModal(true)}
        className="fixed bottom-36 right-4 lg:hidden w-12 h-12 bg-emerald-600 text-white rounded-full shadow-lg hover:bg-emerald-700 transition-colors flex items-center justify-center z-40"
      >
        <Plus className="w-5 h-5" />
      </button>

      {/* Quick Add Modal (Mobile) */}
      {showAddItemModal && (
        <div className="fixed inset-0 bg-black/50 flex items-end justify-center z-50 md:hidden">
          <div className="bg-white rounded-t-xl w-full max-h-[80vh] overflow-y-auto animate-slide-up">
            <div className="p-4 border-b border-slate-200 sticky top-0 bg-white">
              <div className="flex items-center justify-between">
                <h2 className="text-lg font-bold text-slate-900">Quick Add</h2>
                <button
                  onClick={() => setShowAddItemModal(false)}
                  className="p-2 hover:bg-slate-100 rounded-lg transition-colors"
                >
                  <X className="w-5 h-5 text-slate-500" />
                </button>
              </div>
            </div>

            <div className="p-4 space-y-4">
              <div>
                <input
                  type="text"
                  value={newItemInput}
                  onChange={(e) => setNewItemInput(e.target.value)}
                  placeholder="What do you need? (e.g., Milk, Eggs, Bread)"
                  autoFocus
                  className="w-full px-4 py-3 border border-slate-300 rounded-lg focus:ring-2 focus:ring-emerald-600 focus:border-transparent text-lg"
                />
              </div>

              <div className="flex gap-2">
                <button className="flex-1 flex items-center justify-center gap-2 px-4 py-3 border border-slate-300 rounded-lg hover:bg-slate-100 transition-colors text-slate-700">
                  <ScanBarcode className="w-5 h-5" />
                  Scan
                </button>
                <button
                  onClick={() => {
                    handleAddItems();
                    setShowAddItemModal(false);
                  }}
                  disabled={!newItemInput.trim()}
                  className="flex-1 flex items-center justify-center gap-2 px-4 py-3 bg-emerald-600 text-white rounded-lg hover:bg-emerald-700 transition-colors font-medium disabled:opacity-50"
                >
                  <Plus className="w-5 h-5" />
                  Add
                </button>
              </div>

              {/* Quick select list */}
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-2">Add to list:</label>
                <div className="flex flex-wrap gap-2">
                  {lists.map(list => (
                    <button
                      key={list.id}
                      onClick={() => setActiveListId(list.id)}
                      className={`px-3 py-1.5 rounded-full text-sm font-medium transition-colors ${
                        activeListId === list.id
                          ? 'bg-emerald-600 text-white'
                          : 'bg-slate-100 text-slate-700 hover:bg-slate-200'
                      }`}
                    >
                      {list.name}
                    </button>
                  ))}
                </div>
              </div>
            </div>
          </div>
        </div>
      )}

      <style jsx>{`
        @keyframes slide-up {
          from {
            transform: translateY(100%);
          }
          to {
            transform: translateY(0);
          }
        }
        .animate-slide-up {
          animation: slide-up 0.3s ease-out;
        }
      `}</style>
    </div>
  );
}

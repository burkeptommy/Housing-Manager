export interface BudgetCategoryDef {
  id: string;
  name: string;
  icon: string;
}

export interface BudgetGroupDef {
  name: string;
  icon: string;
  color: string;
  type?: 'INCOME';
  categories: BudgetCategoryDef[];
}

export const BUDGET_CATEGORY_GROUPS: Record<string, BudgetGroupDef> = {
  HOUSING: {
    name: 'Housing',
    icon: 'home',
    color: '#7D8E74',
    categories: [
      { id: 'mortgage', name: 'Mortgage/Rent', icon: 'business' },
      { id: 'property_tax', name: 'Property Tax', icon: 'document' },
      { id: 'home_insurance', name: 'Home Insurance', icon: 'shield' },
      { id: 'hoa', name: 'HOA Fees', icon: 'people' },
      { id: 'home_improvement', name: 'Home Improvement', icon: 'construct' },
      { id: 'home_maintenance', name: 'Home Maintenance', icon: 'hammer' },
      { id: 'home_services', name: 'Home Services', icon: 'sparkles' },
    ],
  },
  UTILITIES: {
    name: 'Bills & Utilities',
    icon: 'flash',
    color: '#486581',
    categories: [
      { id: 'electric', name: 'Electric', icon: 'flash' },
      { id: 'gas', name: 'Gas', icon: 'flame' },
      { id: 'water', name: 'Water & Sewer', icon: 'water' },
      { id: 'garbage', name: 'Garbage', icon: 'trash' },
      { id: 'internet', name: 'Internet & Cable', icon: 'wifi' },
      { id: 'phone', name: 'Phone', icon: 'phone-portrait' },
      { id: 'security', name: 'Security System', icon: 'shield-checkmark' },
    ],
  },
  FOOD: {
    name: 'Food & Dining',
    icon: 'restaurant',
    color: '#c4a574',
    categories: [
      { id: 'groceries', name: 'Groceries', icon: 'cart' },
      { id: 'restaurants', name: 'Restaurants & Bars', icon: 'restaurant' },
      { id: 'coffee', name: 'Coffee Shops', icon: 'cafe' },
      { id: 'food_delivery', name: 'Food Delivery', icon: 'bicycle' },
    ],
  },
  TRANSPORTATION: {
    name: 'Auto & Transport',
    icon: 'car',
    color: '#334e68',
    categories: [
      { id: 'auto_payment', name: 'Auto Payment', icon: 'car' },
      { id: 'auto_insurance', name: 'Auto Insurance', icon: 'shield' },
      { id: 'gas_fuel', name: 'Gas & Fuel', icon: 'speedometer' },
      { id: 'auto_maintenance', name: 'Auto Maintenance', icon: 'build' },
      { id: 'parking', name: 'Parking & Tolls', icon: 'location' },
      { id: 'rideshare', name: 'Taxi & Ride Shares', icon: 'car-sport' },
      { id: 'public_transit', name: 'Public Transit', icon: 'train' },
    ],
  },
  HEALTH: {
    name: 'Health & Wellness',
    icon: 'heart',
    color: '#e57373',
    categories: [
      { id: 'medical', name: 'Medical', icon: 'medkit' },
      { id: 'dental', name: 'Dental', icon: 'happy' },
      { id: 'vision', name: 'Vision', icon: 'eye' },
      { id: 'pharmacy', name: 'Pharmacy', icon: 'medical' },
      { id: 'fitness', name: 'Fitness & Gym', icon: 'barbell' },
      { id: 'health_insurance', name: 'Health Insurance', icon: 'shield' },
    ],
  },
  CHILDREN: {
    name: 'Children',
    icon: 'people',
    color: '#81c784',
    categories: [
      { id: 'childcare', name: 'Child Care', icon: 'person' },
      { id: 'tuition', name: 'Tuition', icon: 'school' },
      { id: 'activities', name: 'Activities & Sports', icon: 'football' },
      { id: 'child_supplies', name: 'Kids Supplies', icon: 'bag' },
      { id: 'summer_camp', name: 'Summer Camp', icon: 'sunny' },
    ],
  },
  PETS: {
    name: 'Pets',
    icon: 'paw',
    color: '#a1887f',
    categories: [
      { id: 'pet_food', name: 'Pet Food & Supplies', icon: 'nutrition' },
      { id: 'vet', name: 'Veterinary', icon: 'medkit' },
      { id: 'pet_grooming', name: 'Grooming', icon: 'cut' },
      { id: 'pet_boarding', name: 'Boarding & Daycare', icon: 'home' },
    ],
  },
  SHOPPING: {
    name: 'Shopping',
    icon: 'bag',
    color: '#9575cd',
    categories: [
      { id: 'clothing', name: 'Clothing', icon: 'shirt' },
      { id: 'electronics', name: 'Electronics', icon: 'laptop' },
      { id: 'furniture', name: 'Furniture & Housewares', icon: 'bed' },
      { id: 'general_shopping', name: 'General Shopping', icon: 'bag' },
    ],
  },
  LIFESTYLE: {
    name: 'Travel & Lifestyle',
    icon: 'airplane',
    color: '#4fc3f7',
    categories: [
      { id: 'travel', name: 'Travel & Vacation', icon: 'airplane' },
      { id: 'entertainment', name: 'Entertainment', icon: 'film' },
      { id: 'subscriptions', name: 'Subscriptions', icon: 'tv' },
      { id: 'hobbies', name: 'Hobbies', icon: 'game-controller' },
      { id: 'personal_care', name: 'Personal Care', icon: 'cut' },
    ],
  },
  FINANCIAL: {
    name: 'Financial & Legal',
    icon: 'wallet',
    color: '#ffd54f',
    categories: [
      { id: 'savings', name: 'Savings', icon: 'trending-up' },
      { id: 'investments', name: 'Investments', icon: 'stats-chart' },
      { id: 'loans', name: 'Loan Repayment', icon: 'cash' },
      { id: 'fees', name: 'Bank Fees', icon: 'card' },
      { id: 'taxes', name: 'Taxes', icon: 'document-text' },
      { id: 'life_insurance', name: 'Life Insurance', icon: 'shield' },
    ],
  },
  GIVING: {
    name: 'Gifts & Donations',
    icon: 'gift',
    color: '#f48fb1',
    categories: [
      { id: 'charity', name: 'Charity', icon: 'heart' },
      { id: 'gifts', name: 'Gifts', icon: 'gift' },
    ],
  },
  INCOME: {
    name: 'Income',
    icon: 'trending-up',
    color: '#66bb6a',
    type: 'INCOME',
    categories: [
      { id: 'salary', name: 'Salary', icon: 'briefcase' },
      { id: 'bonus', name: 'Bonus', icon: 'star' },
      { id: 'freelance', name: 'Freelance', icon: 'laptop' },
      { id: 'rental_income', name: 'Rental Income', icon: 'home' },
      { id: 'investments_income', name: 'Investment Returns', icon: 'trending-up' },
      { id: 'other_income', name: 'Other Income', icon: 'cash' },
    ],
  },
  OTHER: {
    name: 'Other',
    icon: 'ellipsis-horizontal',
    color: '#90a4ae',
    categories: [
      { id: 'uncategorized', name: 'Uncategorized', icon: 'help' },
      { id: 'cash', name: 'Cash & ATM', icon: 'cash' },
      { id: 'transfer', name: 'Transfer', icon: 'swap-horizontal' },
    ],
  },
};

export const BUDGET_BENCHMARKS: Record<string, { recommended: number; max: number; label: string }> = {
  HOUSING: { recommended: 0.28, max: 0.35, label: '28-35%' },
  UTILITIES: { recommended: 0.05, max: 0.10, label: '5-10%' },
  FOOD: { recommended: 0.10, max: 0.15, label: '10-15%' },
  TRANSPORTATION: { recommended: 0.10, max: 0.15, label: '10-15%' },
  HEALTH: { recommended: 0.05, max: 0.10, label: '5-10%' },
  CHILDREN: { recommended: 0.10, max: 0.20, label: '10-20%' },
  SHOPPING: { recommended: 0.05, max: 0.10, label: '5-10%' },
  LIFESTYLE: { recommended: 0.05, max: 0.10, label: '5-10%' },
  FINANCIAL: { recommended: 0.15, max: 0.20, label: '15-20% (savings)' },
};

// Build a flat lookup: categoryId -> { groupId, name, color, icon }
export function getCategoryInfo(categoryId: string): {
  groupId: string;
  groupName: string;
  name: string;
  color: string;
  icon: string;
} | null {
  for (const [groupId, group] of Object.entries(BUDGET_CATEGORY_GROUPS)) {
    const cat = group.categories.find((c) => c.id === categoryId);
    if (cat) {
      return {
        groupId,
        groupName: group.name,
        name: cat.name,
        color: group.color,
        icon: cat.icon,
      };
    }
  }
  return null;
}

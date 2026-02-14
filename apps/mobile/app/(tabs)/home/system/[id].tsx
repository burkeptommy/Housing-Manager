import React, { useState, useEffect, useCallback } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  RefreshControl,
} from 'react-native';
import { useRouter, useLocalSearchParams, useFocusEffect } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { useAuth } from '../../../../src/contexts/auth-context';
import { Card, LoadingSpinner, ScreenContainer, Badge } from '../../../../src/components';
import { colors, typography, spacing, borderRadius } from '../../../../src/lib/theme';
import { API_BASE_URL } from '../../../../src/lib/api';
import { getIdToken } from '../../../../src/lib/firebase';

// =============================================================================
// TYPES
// =============================================================================

interface HomeSystem {
  id: string;
  name: string;
  type: string;
  brand?: string;
  model?: string;
  modelNumber?: string;
  serialNumber?: string;
  installedDate?: string;
  warrantyExpires?: string;
  condition?: string;
  location?: string;
  notes?: string;
  maintenanceResearch?: {
    expectedLifespan?: string;
    annualBudget?: number;
    maintenanceSchedule?: {
      frequency: string;
      tasks: string[];
    }[];
    efficiencyTips?: string[];
    warningSignsOfFailure?: string[];
  };
}

interface MaintenanceTask {
  id: string;
  title: string;
  dueDate?: string;
  status: string;
  priority?: string;
  estimatedCost?: number;
}

interface Vendor {
  id: string;
  displayName: string;
  category: string;
  phone?: string;
  email?: string;
}

interface Document {
  id: string;
  name: string;
  type: string;
  uploadedAt: string;
}

interface ServiceHistory {
  id: string;
  title: string;
  completedAt: string;
  cost?: number;
  vendorName?: string;
  notes?: string;
}

// =============================================================================
// HELPER FUNCTIONS
// =============================================================================

const getSystemIcon = (type: string): string => {
  const iconMap: Record<string, string> = {
    FURNACE: 'flame-outline',
    AIR_CONDITIONER: 'snow-outline',
    HEAT_PUMP: 'thermometer-outline',
    BOILER: 'water-outline',
    THERMOSTAT: 'thermometer-outline',
    MINI_SPLIT: 'thermometer-outline',
    OIL_TANK: 'water-outline',
    PROPANE_TANK: 'flame-outline',
    WATER_HEATER: 'water-outline',
    WATER_SOFTENER: 'water-outline',
    WELL_PUMP: 'water-outline',
    SUMP_PUMP: 'water-outline',
    ELECTRICAL_PANEL: 'flash-outline',
    GENERATOR: 'flash-outline',
    SOLAR_PANELS: 'sunny-outline',
    EV_CHARGER: 'car-outline',
    REFRIGERATOR: 'cube-outline',
    DISHWASHER: 'water-outline',
    OVEN_RANGE: 'flame-outline',
    ROOF: 'home-outline',
    GUTTERS: 'water-outline',
    GARAGE_DOOR: 'car-outline',
    WASHER: 'water-outline',
    DRYER: 'flame-outline',
    POOL: 'water-outline',
    HOT_TUB: 'water-outline',
  };
  return iconMap[type] || 'construct-outline';
};

const getConditionVariant = (condition?: string): 'success' | 'warning' | 'error' | 'default' => {
  switch (condition?.toUpperCase()) {
    case 'EXCELLENT':
    case 'GOOD':
      return 'success';
    case 'FAIR':
      return 'warning';
    case 'POOR':
    case 'CRITICAL':
      return 'error';
    default:
      return 'default';
  }
};

const formatCurrency = (amount: number): string => {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  }).format(amount);
};

const formatDate = (dateString?: string): string => {
  if (!dateString) return '—';
  return new Date(dateString).toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
  });
};

// =============================================================================
// SYSTEM DETAIL SCREEN
// =============================================================================

export default function SystemDetailScreen() {
  const router = useRouter();
  const { id } = useLocalSearchParams<{ id: string }>();
  const { householdInfo } = useAuth();

  const [isLoading, setIsLoading] = useState(true);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [system, setSystem] = useState<HomeSystem | null>(null);
  const [tasks, setTasks] = useState<MaintenanceTask[]>([]);
  const [vendors, setVendors] = useState<Vendor[]>([]);
  const [documents, setDocuments] = useState<Document[]>([]);
  const [serviceHistory, setServiceHistory] = useState<ServiceHistory[]>([]);

  // =============================================================================
  // DATA FETCHING
  // =============================================================================

  const fetchSystemData = useCallback(async () => {
    if (!householdInfo?.id || !id) {
      setIsLoading(false);
      return;
    }

    try {
      const token = await getIdToken(true);
      if (!token) {
        setIsLoading(false);
        return;
      }

      const headers = {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
      };

      // Fetch system details
      const systemRes = await fetch(
        `${API_BASE_URL}/home/${householdInfo.id}/systems/${id}`,
        { headers }
      );

      if (systemRes.ok) {
        const data = await systemRes.json();
        setSystem(data.system);
        setTasks(data.tasks || []);
        setVendors(data.vendors || []);
        setDocuments(data.documents || []);
        setServiceHistory(data.serviceHistory || []);
      }
    } catch (err) {
      console.error('Error fetching system data:', err);
    } finally {
      setIsLoading(false);
      setIsRefreshing(false);
    }
  }, [householdInfo?.id, id]);

  useEffect(() => {
    fetchSystemData();
  }, [fetchSystemData]);

  useFocusEffect(
    useCallback(() => {
      if (!isLoading) {
        fetchSystemData();
      }
    }, [fetchSystemData, isLoading])
  );

  const handleRefresh = () => {
    setIsRefreshing(true);
    fetchSystemData();
  };

  // =============================================================================
  // RENDER
  // =============================================================================

  if (isLoading) {
    return (
      <ScreenContainer title="System" onBackPress={() => router.back()}>
        <View style={styles.loadingContainer}>
          <LoadingSpinner message="Loading..." />
        </View>
      </ScreenContainer>
    );
  }

  if (!system) {
    return (
      <ScreenContainer title="System" onBackPress={() => router.back()}>
        <View style={styles.errorContainer}>
          <Ionicons name="alert-circle-outline" size={48} color={colors.haven.purple[300]} />
          <Text style={styles.errorText}>System not found</Text>
        </View>
      </ScreenContainer>
    );
  }

  return (
    <ScreenContainer title={system.name} onBackPress={() => router.back()}>
      <ScrollView
        refreshControl={
          <RefreshControl refreshing={isRefreshing} onRefresh={handleRefresh} />
        }
      >
        {/* System Header */}
        <View style={styles.header}>
          <View style={styles.iconContainer}>
            <Ionicons
              name={getSystemIcon(system.type) as any}
              size={32}
              color={colors.haven.purple[500]}
            />
          </View>
          <Text style={styles.systemName}>{system.name}</Text>
          <Text style={styles.systemType}>{system.type.replace(/_/g, ' ')}</Text>
          {system.condition && (
            <Badge
              label={system.condition}
              variant={getConditionVariant(system.condition)}
            />
          )}
        </View>

        {/* Details Card */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Details</Text>
          <Card style={styles.detailsCard}>
            {system.brand && <DetailRow label="Brand" value={system.brand} />}
            {system.model && <DetailRow label="Model" value={system.model} />}
            {system.modelNumber && <DetailRow label="Model Number" value={system.modelNumber} />}
            {system.serialNumber && <DetailRow label="Serial Number" value={system.serialNumber} />}
            <DetailRow label="Installed" value={formatDate(system.installedDate)} />
            {system.warrantyExpires && (
              <DetailRow label="Warranty Expires" value={formatDate(system.warrantyExpires)} />
            )}
            {system.location && <DetailRow label="Location" value={system.location} />}
            {system.maintenanceResearch?.expectedLifespan && (
              <DetailRow label="Expected Lifespan" value={system.maintenanceResearch.expectedLifespan} />
            )}
          </Card>
        </View>

        {/* Maintenance Schedule */}
        <View style={styles.section}>
          <View style={styles.sectionHeader}>
            <Text style={styles.sectionTitle}>Maintenance Schedule</Text>
            {tasks.length > 0 && (
              <TouchableOpacity onPress={() => router.push('/(tabs)/maintenance' as any)}>
                <Text style={styles.sectionAction}>View All</Text>
              </TouchableOpacity>
            )}
          </View>
          {tasks.length > 0 ? (
            <Card style={styles.tasksCard}>
              {tasks.slice(0, 5).map((task, index) => (
                <TouchableOpacity
                  key={task.id}
                  style={[
                    styles.taskRow,
                    index < Math.min(tasks.length, 5) - 1 && styles.taskRowBorder,
                  ]}
                  onPress={() => router.push(`/(tabs)/maintenance/${task.id}` as any)}
                >
                  <View style={styles.taskInfo}>
                    <Text style={styles.taskTitle}>{task.title}</Text>
                    <Text style={styles.taskDue}>
                      {task.dueDate ? `Due ${formatDate(task.dueDate)}` : 'No due date'}
                    </Text>
                  </View>
                  <Badge
                    label={task.status}
                    variant={task.status === 'OVERDUE' ? 'error' : task.status === 'COMPLETED' ? 'success' : 'default'}
                    size="sm"
                  />
                </TouchableOpacity>
              ))}
            </Card>
          ) : (
            <Card style={styles.emptyCard}>
              <Ionicons name="calendar-outline" size={24} color={colors.haven.purple[300]} />
              <Text style={styles.emptyText}>No maintenance tasks scheduled</Text>
            </Card>
          )}
        </View>

        {/* Annual Budget */}
        {system.maintenanceResearch?.annualBudget && (
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Annual Maintenance Budget</Text>
            <Card style={styles.budgetCard}>
              <View style={styles.budgetRow}>
                <Text style={styles.budgetLabel}>Estimated Annual Cost</Text>
                <Text style={styles.budgetValue}>
                  {formatCurrency(system.maintenanceResearch.annualBudget)}
                </Text>
              </View>
            </Card>
          </View>
        )}

        {/* Service Providers */}
        <View style={styles.section}>
          <View style={styles.sectionHeader}>
            <Text style={styles.sectionTitle}>Service Providers</Text>
          </View>
          {vendors.length > 0 ? (
            vendors.map(vendor => (
              <TouchableOpacity
                key={vendor.id}
                onPress={() => router.push(`/(tabs)/manager/vendors/${vendor.id}` as any)}
              >
                <Card style={styles.vendorCard}>
                  <View style={styles.vendorInfo}>
                    <Text style={styles.vendorName}>{vendor.displayName}</Text>
                    <Text style={styles.vendorCategory}>{vendor.category}</Text>
                  </View>
                  <Ionicons name="chevron-forward" size={20} color={colors.text.tertiary} />
                </Card>
              </TouchableOpacity>
            ))
          ) : (
            <Card style={styles.emptyCard}>
              <TouchableOpacity
                style={styles.addVendorButton}
                onPress={() => router.push('/(tabs)/manager/vendors' as any)}
              >
                <Ionicons name="add-circle-outline" size={20} color={colors.haven.purple[600]} />
                <Text style={styles.addVendorText}>Add a service provider for this system</Text>
              </TouchableOpacity>
            </Card>
          )}
        </View>

        {/* Documents */}
        <View style={styles.section}>
          <View style={styles.sectionHeader}>
            <Text style={styles.sectionTitle}>Documents</Text>
          </View>
          {documents.length > 0 ? (
            documents.map(doc => (
              <Card key={doc.id} style={styles.documentCard}>
                <View style={styles.documentIcon}>
                  <Ionicons
                    name={doc.type === 'PDF' ? 'document-text-outline' : 'image-outline'}
                    size={20}
                    color={colors.haven.purple[500]}
                  />
                </View>
                <View style={styles.documentInfo}>
                  <Text style={styles.documentName}>{doc.name}</Text>
                  <Text style={styles.documentDate}>{formatDate(doc.uploadedAt)}</Text>
                </View>
              </Card>
            ))
          ) : (
            <Card style={styles.emptyCard}>
              <TouchableOpacity
                style={styles.addVendorButton}
                onPress={() => router.push('/(tabs)/settings/vault' as any)}
              >
                <Ionicons name="cloud-upload-outline" size={20} color={colors.haven.purple[600]} />
                <Text style={styles.addVendorText}>Upload manual, warranty, or receipt</Text>
              </TouchableOpacity>
            </Card>
          )}
        </View>

        {/* Service History */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Service History</Text>
          {serviceHistory.length > 0 ? (
            serviceHistory.map(history => (
              <Card key={history.id} style={styles.historyCard}>
                <View style={styles.historyHeader}>
                  <Text style={styles.historyTitle}>{history.title}</Text>
                  {history.cost && (
                    <Text style={styles.historyCost}>{formatCurrency(history.cost)}</Text>
                  )}
                </View>
                <Text style={styles.historyMeta}>
                  {formatDate(history.completedAt)}
                  {history.vendorName && ` • ${history.vendorName}`}
                </Text>
                {history.notes && <Text style={styles.historyNotes}>{history.notes}</Text>}
              </Card>
            ))
          ) : (
            <Card style={styles.emptyCard}>
              <Ionicons name="time-outline" size={24} color={colors.haven.purple[300]} />
              <Text style={styles.emptyText}>No service history yet</Text>
            </Card>
          )}
        </View>

        {/* Tips & Recommendations */}
        {system.maintenanceResearch?.efficiencyTips && system.maintenanceResearch.efficiencyTips.length > 0 && (
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Tips & Recommendations</Text>
            <Card style={styles.tipsCard}>
              {system.maintenanceResearch.efficiencyTips.map((tip, index) => (
                <View key={index} style={styles.tipRow}>
                  <Ionicons name="bulb-outline" size={16} color={colors.haven.purple[500]} />
                  <Text style={styles.tipText}>{tip}</Text>
                </View>
              ))}
            </Card>
          </View>
        )}

        {/* Warning Signs */}
        {system.maintenanceResearch?.warningSignsOfFailure && system.maintenanceResearch.warningSignsOfFailure.length > 0 && (
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Warning Signs</Text>
            <Card style={styles.warningsCard}>
              {system.maintenanceResearch.warningSignsOfFailure.map((warning, index) => (
                <View key={index} style={styles.warningRow}>
                  <Ionicons name="warning-outline" size={16} color={colors.status.warning} />
                  <Text style={styles.warningText}>{warning}</Text>
                </View>
              ))}
            </Card>
          </View>
        )}

        {/* Notes */}
        {system.notes && (
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Notes</Text>
            <Card style={styles.notesCard}>
              <Text style={styles.notesText}>{system.notes}</Text>
            </Card>
          </View>
        )}

        {/* Quick Actions */}
        <View style={styles.quickActionsSection}>
          <TouchableOpacity
            style={styles.coralActionButton}
            onPress={() => {
              const prompt = `I need to schedule service for my ${system.name}${system.brand ? ` (${system.brand})` : ''}. Can you help me find a vendor and get this scheduled?`;
              router.push({
                pathname: '/(tabs)/manager/chat',
                params: { prefillMessage: prompt },
              });
            }}
          >
            <Ionicons name="calendar-outline" size={20} color={colors.white} />
            <Text style={styles.coralActionText}>Schedule Service</Text>
          </TouchableOpacity>
        </View>

        {/* Spacer */}
        <View style={{ height: spacing[6] }} />
      </ScrollView>
    </ScreenContainer>
  );
}

// =============================================================================
// HELPER COMPONENTS
// =============================================================================

function DetailRow({ label, value }: { label: string; value?: string }) {
  return (
    <View style={styles.detailRow}>
      <Text style={styles.detailLabel}>{label}</Text>
      <Text style={styles.detailValue}>{value || '—'}</Text>
    </View>
  );
}

// =============================================================================
// STYLES
// =============================================================================

const styles = StyleSheet.create({
  loadingContainer: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  errorContainer: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    padding: spacing[6],
  },
  errorText: {
    fontSize: typography.fontSizes.base,
    color: colors.text.secondary,
    marginTop: spacing[3],
  },
  header: {
    alignItems: 'center',
    paddingVertical: spacing[4],
    paddingHorizontal: spacing[4],
    backgroundColor: colors.white,
    borderBottomWidth: 1,
    borderBottomColor: colors.border.light,
  },
  iconContainer: {
    width: 56,
    height: 56,
    borderRadius: 28,
    backgroundColor: colors.haven.purple[50],
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: spacing[2],
  },
  systemName: {
    fontSize: typography.fontSizes.xl,
    fontWeight: typography.fontWeights.bold,
    color: colors.text.primary,
    textAlign: 'center',
  },
  systemType: {
    fontSize: typography.fontSizes.base,
    color: colors.text.secondary,
    marginTop: spacing[1],
    marginBottom: spacing[2],
    textTransform: 'capitalize',
  },
  section: {
    padding: spacing[4],
  },
  sectionHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: spacing[3],
  },
  sectionTitle: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
    marginBottom: spacing[3],
  },
  sectionAction: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.purple[600],
    fontWeight: typography.fontWeights.medium,
  },
  detailsCard: {
    padding: spacing[4],
  },
  detailRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    paddingVertical: spacing[2],
    borderBottomWidth: 1,
    borderBottomColor: colors.border.light,
  },
  detailLabel: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
  },
  detailValue: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.primary,
    maxWidth: '60%',
    textAlign: 'right',
  },
  tasksCard: {
    padding: spacing[2],
  },
  taskRow: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: spacing[3],
  },
  taskRowBorder: {
    borderBottomWidth: 1,
    borderBottomColor: colors.border.light,
  },
  taskInfo: {
    flex: 1,
  },
  taskTitle: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.primary,
  },
  taskDue: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
    marginTop: spacing[0.5],
  },
  budgetCard: {
    padding: spacing[4],
  },
  budgetRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  budgetLabel: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
  },
  budgetValue: {
    fontSize: typography.fontSizes.xl,
    fontWeight: typography.fontWeights.bold,
    color: colors.haven.purple[600],
  },
  vendorCard: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: spacing[4],
    marginBottom: spacing[2],
  },
  vendorInfo: {
    flex: 1,
  },
  vendorName: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.primary,
  },
  vendorCategory: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    textTransform: 'capitalize',
  },
  documentCard: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: spacing[4],
    marginBottom: spacing[2],
  },
  documentIcon: {
    width: 36,
    height: 36,
    borderRadius: borderRadius.md,
    backgroundColor: colors.haven.purple[50],
    alignItems: 'center',
    justifyContent: 'center',
  },
  documentInfo: {
    flex: 1,
    marginLeft: spacing[3],
  },
  documentName: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.primary,
  },
  documentDate: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
  },
  historyCard: {
    padding: spacing[4],
    marginBottom: spacing[2],
  },
  historyHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
  },
  historyTitle: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.primary,
    flex: 1,
  },
  historyCost: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
  },
  historyMeta: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    marginTop: spacing[1],
  },
  historyNotes: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.tertiary,
    marginTop: spacing[2],
  },
  tipsCard: {
    padding: spacing[4],
  },
  tipRow: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    marginBottom: spacing[3],
    gap: spacing[2],
  },
  tipText: {
    flex: 1,
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    lineHeight: 20,
  },
  warningsCard: {
    padding: spacing[4],
    backgroundColor: colors.status.warningLight,
  },
  warningRow: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    marginBottom: spacing[3],
    gap: spacing[2],
  },
  warningText: {
    flex: 1,
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    lineHeight: 20,
  },
  notesCard: {
    padding: spacing[4],
  },
  notesText: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    lineHeight: 20,
  },
  emptyCard: {
    alignItems: 'center',
    padding: spacing[6],
  },
  emptyText: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.tertiary,
    marginTop: spacing[2],
  },
  addVendorButton: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[2],
  },
  addVendorText: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.purple[600],
    fontWeight: typography.fontWeights.medium,
  },
  quickActionsSection: {
    paddingHorizontal: spacing[4],
    marginTop: spacing[4],
  },
  coralActionButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: spacing[2],
    backgroundColor: colors.haven.coral[500],
    paddingVertical: spacing[4],
    borderRadius: borderRadius.xl,
    shadowColor: colors.haven.coral[500],
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.2,
    shadowRadius: 8,
    elevation: 4,
  },
  coralActionText: {
    fontSize: typography.fontSizes.base,
    fontFamily: 'Nunito_600SemiBold',
    color: colors.white,
  },
});

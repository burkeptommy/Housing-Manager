import { useEffect, useState, useCallback } from 'react';
import {
  View,
  Text,
  ScrollView,
  StyleSheet,
  RefreshControl,
  TouchableOpacity,
  ActivityIndicator,
  Modal,
  TextInput,
  Alert,
  KeyboardAvoidingView,
  Platform,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Stack, useRouter } from 'expo-router';
import { useAuth } from '../src/contexts/auth-context';
import { getApiClient } from '../src/lib/api';
import { colors, spacing, typography, borderRadius, shadows } from '../src/lib/theme';
import type { WorkOrder, WorkOrderStatus, MaintenanceTask, HouseholdVendor, CreateWorkOrderRequest } from '@haven/core';

const STATUS_COLORS: Record<WorkOrderStatus, string> = {
  DRAFT: colors.slate[400],
  REQUESTED: colors.info,
  SCHEDULED: colors.haven.purple[400],
  IN_PROGRESS: colors.warning,
  COMPLETED: colors.success,
  CANCELLED: colors.error,
};

function formatDate(date: string | null | undefined): string {
  if (!date) return '-';
  return new Date(date).toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
  });
}

function formatDateTime(date: string | null | undefined): string {
  if (!date) return '-';
  return new Date(date).toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
    hour: 'numeric',
    minute: '2-digit',
  });
}

export default function WorkOrdersScreen() {
  const router = useRouter();
  const { currentHousehold } = useAuth();
  const [workOrders, setWorkOrders] = useState<WorkOrder[]>([]);
  const [maintenanceTasks, setMaintenanceTasks] = useState<MaintenanceTask[]>([]);
  const [vendors, setVendors] = useState<HouseholdVendor[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [selectedOrder, setSelectedOrder] = useState<WorkOrder | null>(null);

  const api = getApiClient();

  const fetchData = useCallback(async () => {
    if (!currentHousehold) return;

    try {
      const [ordersData, tasksData, vendorsData] = await Promise.all([
        api.getWorkOrders(currentHousehold.id),
        api.getMaintenanceTasks(currentHousehold.id).catch(() => []),
        api.getHouseholdVendors(currentHousehold.id).catch(() => []),
      ]);
      setWorkOrders(ordersData);
      setMaintenanceTasks(tasksData);
      setVendors(vendorsData);
    } catch (error) {
      console.error('Failed to fetch work orders:', error);
    } finally {
      setIsLoading(false);
    }
  }, [api, currentHousehold]);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  const onRefresh = useCallback(async () => {
    setRefreshing(true);
    await fetchData();
    setRefreshing(false);
  }, [fetchData]);

  if (isLoading) {
    return (
      <>
        <Stack.Screen options={{ title: 'Work Orders' }} />
        <SafeAreaView style={styles.loadingContainer} edges={['bottom']}>
          <ActivityIndicator size="large" color={colors.haven.purple[600]} />
        </SafeAreaView>
      </>
    );
  }

  return (
    <>
      <Stack.Screen options={{ title: 'Work Orders' }} />
      <SafeAreaView style={styles.container} edges={['bottom']}>
        <ScrollView
          contentContainerStyle={styles.scrollContent}
          refreshControl={
            <RefreshControl
              refreshing={refreshing}
              onRefresh={onRefresh}
              tintColor={colors.haven.purple[600]}
            />
          }
        >
          {/* Header */}
          <View style={styles.header}>
            <View>
              <Text style={styles.headerTitle}>Work Orders</Text>
              <Text style={styles.headerSubtitle}>
                Request and track vendor visits
              </Text>
            </View>
            <TouchableOpacity
              style={styles.createButton}
              onPress={() => setShowCreateModal(true)}
            >
              <Text style={styles.createButtonText}>+ New</Text>
            </TouchableOpacity>
          </View>

          {/* Work Orders List */}
          {workOrders.length === 0 ? (
            <View style={styles.emptyCard}>
              <Text style={styles.emptyEmoji}>📋</Text>
              <Text style={styles.emptyText}>No work orders yet</Text>
              <TouchableOpacity
                style={styles.emptyButton}
                onPress={() => setShowCreateModal(true)}
              >
                <Text style={styles.emptyButtonText}>Create your first work order</Text>
              </TouchableOpacity>
            </View>
          ) : (
            workOrders.map((order) => (
              <TouchableOpacity
                key={order.id}
                style={styles.orderCard}
                onPress={() => setSelectedOrder(order)}
              >
                <View style={styles.orderHeader}>
                  <Text style={styles.orderTitle}>{order.title}</Text>
                  <View
                    style={[
                      styles.statusBadge,
                      { backgroundColor: STATUS_COLORS[order.status] + '20' },
                    ]}
                  >
                    <Text
                      style={[
                        styles.statusText,
                        { color: STATUS_COLORS[order.status] },
                      ]}
                    >
                      {order.status.replace('_', ' ')}
                    </Text>
                  </View>
                </View>

                {order.description && (
                  <Text style={styles.orderDescription} numberOfLines={2}>
                    {order.description}
                  </Text>
                )}

                <View style={styles.orderMeta}>
                  {order.vendor && (
                    <View style={styles.metaItem}>
                      <Text style={styles.metaIcon}>🏢</Text>
                      <Text style={styles.metaText}>{order.vendor.displayName}</Text>
                    </View>
                  )}
                  {order.scheduledStart ? (
                    <View style={styles.metaItem}>
                      <Text style={styles.metaIcon}>📅</Text>
                      <Text style={styles.metaText}>
                        {formatDateTime(order.scheduledStart)}
                      </Text>
                    </View>
                  ) : order.preferredDate ? (
                    <View style={styles.metaItem}>
                      <Text style={styles.metaIcon}>📅</Text>
                      <Text style={[styles.metaText, styles.metaTextMuted]}>
                        Preferred: {formatDate(order.preferredDate)}
                      </Text>
                    </View>
                  ) : null}
                  {order.estimatedCost && (
                    <View style={styles.metaItem}>
                      <Text style={styles.metaIcon}>💰</Text>
                      <Text style={styles.metaText}>
                        ${Number(order.estimatedCost).toFixed(2)}
                      </Text>
                    </View>
                  )}
                </View>
              </TouchableOpacity>
            ))
          )}
        </ScrollView>

        {/* Create Work Order Modal */}
        <CreateWorkOrderModal
          visible={showCreateModal}
          onClose={() => setShowCreateModal(false)}
          onSuccess={() => {
            setShowCreateModal(false);
            fetchData();
          }}
          householdId={currentHousehold?.id || ''}
          maintenanceTasks={maintenanceTasks}
          vendors={vendors}
        />

        {/* Order Detail Modal */}
        {selectedOrder && (
          <OrderDetailModal
            order={selectedOrder}
            onClose={() => setSelectedOrder(null)}
          />
        )}
      </SafeAreaView>
    </>
  );
}

// Create Work Order Modal
function CreateWorkOrderModal({
  visible,
  onClose,
  onSuccess,
  householdId,
  maintenanceTasks,
  vendors,
}: {
  visible: boolean;
  onClose: () => void;
  onSuccess: () => void;
  householdId: string;
  maintenanceTasks: MaintenanceTask[];
  vendors: HouseholdVendor[];
}) {
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [selectedTaskId, setSelectedTaskId] = useState<string | null>(null);
  const [selectedVendorId, setSelectedVendorId] = useState<string | null>(null);
  const [preferredDate, setPreferredDate] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);

  const api = getApiClient();

  // Auto-fill from task when selected
  useEffect(() => {
    if (selectedTaskId) {
      const task = maintenanceTasks.find((t) => t.id === selectedTaskId);
      if (task) {
        setTitle(task.title);
        if (task.description) setDescription(task.description);
        if (task.assignedVendorId) setSelectedVendorId(task.assignedVendorId);
      }
    }
  }, [selectedTaskId, maintenanceTasks]);

  const handleSubmit = async () => {
    if (!title.trim()) {
      Alert.alert('Error', 'Please enter a title');
      return;
    }

    setIsSubmitting(true);
    try {
      const data: CreateWorkOrderRequest = {
        title: title.trim(),
        description: description.trim() || undefined,
        maintenanceTaskId: selectedTaskId || undefined,
        vendorId: selectedVendorId || undefined,
        preferredDate: preferredDate || undefined,
      };

      await api.createWorkOrder({ ...data, householdId });
      Alert.alert('Success', 'Work order created successfully');

      // Reset form
      setTitle('');
      setDescription('');
      setSelectedTaskId(null);
      setSelectedVendorId(null);
      setPreferredDate('');

      onSuccess();
    } catch (error: any) {
      Alert.alert('Error', error.message || 'Failed to create work order');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleClose = () => {
    setTitle('');
    setDescription('');
    setSelectedTaskId(null);
    setSelectedVendorId(null);
    setPreferredDate('');
    onClose();
  };

  return (
    <Modal visible={visible} animationType="slide" presentationStyle="pageSheet">
      <SafeAreaView style={styles.modalContainer}>
        <KeyboardAvoidingView
          behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
          style={styles.modalKeyboard}
        >
          {/* Modal Header */}
          <View style={styles.modalHeader}>
            <TouchableOpacity onPress={handleClose}>
              <Text style={styles.modalCancel}>Cancel</Text>
            </TouchableOpacity>
            <Text style={styles.modalTitle}>Request Vendor Visit</Text>
            <TouchableOpacity onPress={handleSubmit} disabled={isSubmitting}>
              {isSubmitting ? (
                <ActivityIndicator size="small" color={colors.haven.purple[600]} />
              ) : (
                <Text style={styles.modalSubmit}>Submit</Text>
              )}
            </TouchableOpacity>
          </View>

          <ScrollView style={styles.modalContent} keyboardShouldPersistTaps="handled">
            {/* Link to Task */}
            {maintenanceTasks.length > 0 && (
              <View style={styles.inputGroup}>
                <Text style={styles.label}>Link to Maintenance Task</Text>
                <ScrollView
                  horizontal
                  showsHorizontalScrollIndicator={false}
                  contentContainerStyle={styles.chipList}
                >
                  {maintenanceTasks.map((task) => (
                    <TouchableOpacity
                      key={task.id}
                      style={[
                        styles.chip,
                        selectedTaskId === task.id && styles.chipActive,
                      ]}
                      onPress={() =>
                        setSelectedTaskId(selectedTaskId === task.id ? null : task.id)
                      }
                    >
                      <Text
                        style={[
                          styles.chipText,
                          selectedTaskId === task.id && styles.chipTextActive,
                        ]}
                        numberOfLines={1}
                      >
                        {task.title}
                      </Text>
                    </TouchableOpacity>
                  ))}
                </ScrollView>
              </View>
            )}

            {/* Title */}
            <View style={styles.inputGroup}>
              <Text style={styles.label}>Title *</Text>
              <TextInput
                style={styles.input}
                placeholder="e.g., HVAC Maintenance Visit"
                placeholderTextColor={colors.slate[400]}
                value={title}
                onChangeText={setTitle}
              />
            </View>

            {/* Description */}
            <View style={styles.inputGroup}>
              <Text style={styles.label}>Description</Text>
              <TextInput
                style={[styles.input, styles.textArea]}
                placeholder="Additional details for the vendor..."
                placeholderTextColor={colors.slate[400]}
                value={description}
                onChangeText={setDescription}
                multiline
                numberOfLines={3}
                textAlignVertical="top"
              />
            </View>

            {/* Vendor Selection */}
            {vendors.length > 0 && (
              <View style={styles.inputGroup}>
                <Text style={styles.label}>Preferred Vendor</Text>
                <ScrollView
                  horizontal
                  showsHorizontalScrollIndicator={false}
                  contentContainerStyle={styles.chipList}
                >
                  <TouchableOpacity
                    style={[styles.chip, !selectedVendorId && styles.chipActive]}
                    onPress={() => setSelectedVendorId(null)}
                  >
                    <Text
                      style={[styles.chipText, !selectedVendorId && styles.chipTextActive]}
                    >
                      Haven finds
                    </Text>
                  </TouchableOpacity>
                  {vendors.map((vendor) => (
                    <TouchableOpacity
                      key={vendor.id}
                      style={[
                        styles.chip,
                        selectedVendorId === vendor.id && styles.chipActive,
                      ]}
                      onPress={() => setSelectedVendorId(vendor.id)}
                    >
                      <Text
                        style={[
                          styles.chipText,
                          selectedVendorId === vendor.id && styles.chipTextActive,
                        ]}
                        numberOfLines={1}
                      >
                        {vendor.displayName}
                      </Text>
                    </TouchableOpacity>
                  ))}
                </ScrollView>
              </View>
            )}

            {/* Preferred Date */}
            <View style={styles.inputGroup}>
              <Text style={styles.label}>Preferred Date (Optional)</Text>
              <TextInput
                style={styles.input}
                placeholder="YYYY-MM-DD"
                placeholderTextColor={colors.slate[400]}
                value={preferredDate}
                onChangeText={setPreferredDate}
              />
            </View>
          </ScrollView>
        </KeyboardAvoidingView>
      </SafeAreaView>
    </Modal>
  );
}

// Order Detail Modal
function OrderDetailModal({
  order,
  onClose,
}: {
  order: WorkOrder;
  onClose: () => void;
}) {
  return (
    <Modal visible animationType="slide" presentationStyle="pageSheet">
      <SafeAreaView style={styles.modalContainer}>
        {/* Modal Header */}
        <View style={styles.modalHeader}>
          <TouchableOpacity onPress={onClose}>
            <Text style={styles.modalCancel}>Close</Text>
          </TouchableOpacity>
          <Text style={styles.modalTitle}>Work Order</Text>
          <View style={{ width: 50 }} />
        </View>

        <ScrollView style={styles.modalContent}>
          <View style={styles.detailCard}>
            <View style={styles.detailHeader}>
              <Text style={styles.detailTitle}>{order.title}</Text>
              <View
                style={[
                  styles.statusBadge,
                  { backgroundColor: STATUS_COLORS[order.status] + '20' },
                ]}
              >
                <Text
                  style={[styles.statusText, { color: STATUS_COLORS[order.status] }]}
                >
                  {order.status.replace('_', ' ')}
                </Text>
              </View>
            </View>

            {order.description && (
              <Text style={styles.detailDescription}>{order.description}</Text>
            )}

            <View style={styles.detailDivider} />

            {order.vendor && (
              <View style={styles.detailRow}>
                <Text style={styles.detailLabel}>Vendor</Text>
                <Text style={styles.detailValue}>{order.vendor.displayName}</Text>
              </View>
            )}

            {order.scheduledStart && (
              <View style={styles.detailRow}>
                <Text style={styles.detailLabel}>Scheduled</Text>
                <Text style={styles.detailValue}>
                  {formatDateTime(order.scheduledStart)}
                  {order.scheduledEnd && ` - ${new Date(order.scheduledEnd).toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' })}`}
                </Text>
              </View>
            )}

            {order.preferredDate && !order.scheduledStart && (
              <View style={styles.detailRow}>
                <Text style={styles.detailLabel}>Preferred Date</Text>
                <Text style={styles.detailValue}>
                  {formatDate(order.preferredDate)}
                  {order.preferredTimeWindowStart && order.preferredTimeWindowEnd && (
                    ` (${order.preferredTimeWindowStart} - ${order.preferredTimeWindowEnd})`
                  )}
                </Text>
              </View>
            )}

            {order.maintenanceTask && (
              <View style={styles.detailRow}>
                <Text style={styles.detailLabel}>Linked Task</Text>
                <Text style={styles.detailValue}>{order.maintenanceTask.title}</Text>
              </View>
            )}

            {order.estimatedCost !== null && order.estimatedCost !== undefined && (
              <View style={styles.detailRow}>
                <Text style={styles.detailLabel}>Estimated Cost</Text>
                <Text style={styles.detailValue}>
                  ${Number(order.estimatedCost).toFixed(2)}
                </Text>
              </View>
            )}

            {order.actualCost !== null && order.actualCost !== undefined && (
              <View style={styles.detailRow}>
                <Text style={styles.detailLabel}>Actual Cost</Text>
                <Text style={styles.detailValue}>
                  ${Number(order.actualCost).toFixed(2)}
                </Text>
              </View>
            )}

            {order.completedAt && (
              <View style={styles.detailRow}>
                <Text style={styles.detailLabel}>Completed</Text>
                <Text style={styles.detailValue}>
                  {formatDateTime(order.completedAt)}
                </Text>
              </View>
            )}

            <View style={styles.detailRow}>
              <Text style={styles.detailLabel}>Created</Text>
              <Text style={styles.detailValue}>{formatDate(order.createdAt)}</Text>
            </View>
          </View>
        </ScrollView>
      </SafeAreaView>
    </Modal>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.slate[50],
  },
  loadingContainer: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: colors.slate[50],
  },
  scrollContent: {
    padding: spacing[4],
  },
  // Header
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: spacing[4],
  },
  headerTitle: {
    fontSize: typography.fontSizes.xl,
    fontWeight: typography.fontWeights.bold,
    color: colors.slate[900],
  },
  headerSubtitle: {
    fontSize: typography.fontSizes.sm,
    color: colors.slate[500],
    marginTop: 2,
  },
  createButton: {
    backgroundColor: colors.haven.purple[600],
    paddingHorizontal: spacing[4],
    paddingVertical: spacing[2],
    borderRadius: borderRadius.lg,
  },
  createButtonText: {
    color: colors.white,
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
  },
  // Empty state
  emptyCard: {
    backgroundColor: colors.white,
    borderRadius: borderRadius.xl,
    padding: spacing[8],
    alignItems: 'center',
    ...shadows.sm,
  },
  emptyEmoji: {
    fontSize: 48,
    marginBottom: spacing[3],
  },
  emptyText: {
    fontSize: typography.fontSizes.base,
    color: colors.slate[500],
    marginBottom: spacing[4],
  },
  emptyButton: {
    backgroundColor: colors.haven.purple[600],
    paddingHorizontal: spacing[5],
    paddingVertical: spacing[3],
    borderRadius: borderRadius.lg,
  },
  emptyButtonText: {
    color: colors.white,
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
  },
  // Order Card
  orderCard: {
    backgroundColor: colors.white,
    borderRadius: borderRadius.xl,
    padding: spacing[4],
    marginBottom: spacing[3],
    ...shadows.sm,
  },
  orderHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    marginBottom: spacing[2],
  },
  orderTitle: {
    flex: 1,
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.slate[900],
    marginRight: spacing[2],
  },
  statusBadge: {
    paddingHorizontal: spacing[2],
    paddingVertical: 2,
    borderRadius: borderRadius.full,
  },
  statusText: {
    fontSize: typography.fontSizes.xs,
    fontWeight: typography.fontWeights.semibold,
  },
  orderDescription: {
    fontSize: typography.fontSizes.sm,
    color: colors.slate[500],
    marginBottom: spacing[3],
  },
  orderMeta: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: spacing[3],
  },
  metaItem: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  metaIcon: {
    fontSize: 14,
    marginRight: spacing[1],
  },
  metaText: {
    fontSize: typography.fontSizes.sm,
    color: colors.slate[600],
  },
  metaTextMuted: {
    color: colors.slate[400],
  },
  // Modal
  modalContainer: {
    flex: 1,
    backgroundColor: colors.white,
  },
  modalKeyboard: {
    flex: 1,
  },
  modalHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: spacing[4],
    paddingVertical: spacing[3],
    borderBottomWidth: 1,
    borderBottomColor: colors.slate[200],
  },
  modalCancel: {
    fontSize: typography.fontSizes.base,
    color: colors.slate[500],
  },
  modalTitle: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.semibold,
    color: colors.slate[900],
  },
  modalSubmit: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.haven.purple[600],
  },
  modalContent: {
    flex: 1,
    padding: spacing[4],
  },
  // Form
  inputGroup: {
    marginBottom: spacing[5],
  },
  label: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.slate[700],
    marginBottom: spacing[2],
  },
  input: {
    backgroundColor: colors.slate[50],
    borderWidth: 1,
    borderColor: colors.slate[200],
    borderRadius: borderRadius.lg,
    padding: spacing[4],
    fontSize: typography.fontSizes.base,
    color: colors.slate[900],
  },
  textArea: {
    minHeight: 80,
    paddingTop: spacing[3],
  },
  chipList: {
    flexDirection: 'row',
    gap: spacing[2],
  },
  chip: {
    paddingHorizontal: spacing[4],
    paddingVertical: spacing[2],
    borderRadius: borderRadius.full,
    borderWidth: 1,
    borderColor: colors.slate[200],
    backgroundColor: colors.white,
  },
  chipActive: {
    borderColor: colors.haven.purple[600],
    backgroundColor: colors.haven.purple[50],
  },
  chipText: {
    fontSize: typography.fontSizes.sm,
    color: colors.slate[600],
    maxWidth: 150,
  },
  chipTextActive: {
    color: colors.haven.purple[700],
    fontWeight: typography.fontWeights.medium,
  },
  // Detail Modal
  detailCard: {
    backgroundColor: colors.slate[50],
    borderRadius: borderRadius.xl,
    padding: spacing[4],
  },
  detailHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    marginBottom: spacing[3],
  },
  detailTitle: {
    flex: 1,
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.semibold,
    color: colors.slate[900],
    marginRight: spacing[2],
  },
  detailDescription: {
    fontSize: typography.fontSizes.base,
    color: colors.slate[600],
    lineHeight: 22,
  },
  detailDivider: {
    height: 1,
    backgroundColor: colors.slate[200],
    marginVertical: spacing[4],
  },
  detailRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    paddingVertical: spacing[2],
  },
  detailLabel: {
    fontSize: typography.fontSizes.sm,
    color: colors.slate[500],
  },
  detailValue: {
    fontSize: typography.fontSizes.sm,
    color: colors.slate[900],
    fontWeight: typography.fontWeights.medium,
    textAlign: 'right',
    flex: 1,
    marginLeft: spacing[4],
  },
});

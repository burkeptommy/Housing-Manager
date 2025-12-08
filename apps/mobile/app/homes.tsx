import { StyleSheet, Text, View, FlatList } from 'react-native';

interface Home {
  id: string;
  name: string;
  address: string;
}

const mockHomes: Home[] = [
  { id: '1', name: 'Main House', address: '123 Main Street' },
  { id: '2', name: 'Beach House', address: '456 Ocean Drive' },
];

export default function HomesScreen() {
  return (
    <View style={styles.container}>
      <FlatList
        data={mockHomes}
        keyExtractor={(item) => item.id}
        renderItem={({ item }) => (
          <View style={styles.homeCard}>
            <Text style={styles.homeName}>{item.name}</Text>
            <Text style={styles.homeAddress}>{item.address}</Text>
          </View>
        )}
        ListEmptyComponent={
          <Text style={styles.emptyText}>No homes added yet</Text>
        }
        contentContainerStyle={styles.listContent}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5f5',
  },
  listContent: {
    padding: 16,
    gap: 12,
  },
  homeCard: {
    backgroundColor: '#ffffff',
    borderRadius: 12,
    padding: 16,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.1,
    shadowRadius: 2,
    elevation: 2,
  },
  homeName: {
    fontSize: 18,
    fontWeight: '600',
    color: '#1f2937',
  },
  homeAddress: {
    fontSize: 14,
    color: '#6b7280',
    marginTop: 4,
  },
  emptyText: {
    textAlign: 'center',
    color: '#6b7280',
    fontSize: 16,
    marginTop: 40,
  },
});

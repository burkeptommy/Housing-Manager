import { Link } from 'expo-router';
import { StyleSheet, Text, View, Pressable } from 'react-native';

export default function HomeScreen() {
  return (
    <View style={styles.container}>
      <Text style={styles.title}>Welcome to Haven</Text>
      <Text style={styles.subtitle}>Your home management companion</Text>

      <View style={styles.cardContainer}>
        <Link href="/homes" asChild>
          <Pressable style={styles.card}>
            <Text style={styles.cardTitle}>My Homes</Text>
            <Text style={styles.cardDescription}>
              Manage all your properties
            </Text>
          </Pressable>
        </Link>

        <Link href="/tasks" asChild>
          <Pressable style={styles.card}>
            <Text style={styles.cardTitle}>Tasks</Text>
            <Text style={styles.cardDescription}>
              Track maintenance and improvements
            </Text>
          </Pressable>
        </Link>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5f5',
    padding: 20,
  },
  title: {
    fontSize: 32,
    fontWeight: 'bold',
    color: '#1f2937',
    textAlign: 'center',
    marginTop: 40,
  },
  subtitle: {
    fontSize: 18,
    color: '#6b7280',
    textAlign: 'center',
    marginTop: 8,
    marginBottom: 40,
  },
  cardContainer: {
    gap: 16,
  },
  card: {
    backgroundColor: '#ffffff',
    borderRadius: 12,
    padding: 20,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  cardTitle: {
    fontSize: 20,
    fontWeight: '600',
    color: '#1f2937',
    marginBottom: 4,
  },
  cardDescription: {
    fontSize: 14,
    color: '#6b7280',
  },
});

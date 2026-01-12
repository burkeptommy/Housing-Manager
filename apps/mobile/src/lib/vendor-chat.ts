import { API_BASE_URL } from './api';
import { getIdToken } from './firebase';

export interface VendorMessage {
  id: string;
  householdVendorId: string;
  direction: 'outgoing' | 'incoming';
  content: string;
  status: 'sent' | 'delivered' | 'read';
  createdAt: string;
}

export async function getVendorMessages(
  householdVendorId: string,
  householdId: string
): Promise<VendorMessage[]> {
  try {
    const token = await getIdToken(true);
    const response = await fetch(
      `${API_BASE_URL}/vendors/${householdVendorId}/messages?householdId=${householdId}`,
      {
        headers: { Authorization: `Bearer ${token}` },
      }
    );
    if (!response.ok) return [];
    return response.json();
  } catch (error) {
    console.error('Error fetching vendor messages:', error);
    return [];
  }
}

export async function sendVendorMessage(
  householdVendorId: string,
  householdId: string,
  content: string
): Promise<VendorMessage | null> {
  try {
    const token = await getIdToken(true);
    const response = await fetch(
      `${API_BASE_URL}/vendors/${householdVendorId}/messages?householdId=${householdId}`,
      {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ content }),
      }
    );
    if (!response.ok) {
      throw new Error('Failed to send message');
    }
    return response.json();
  } catch (error) {
    console.error('Error sending vendor message:', error);
    return null;
  }
}

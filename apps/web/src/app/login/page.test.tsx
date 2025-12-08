import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { describe, expect, it, vi, beforeEach } from 'vitest';

// Mock next/navigation
vi.mock('next/navigation', () => ({
  useRouter: () => ({
    push: vi.fn(),
    replace: vi.fn(),
  }),
  usePathname: () => '/login',
}));

// Mock the auth context
const mockLogin = vi.fn();
const mockAuthContext = {
  user: null,
  households: [],
  currentHousehold: null,
  isLoading: false,
  isAuthenticated: false,
  needsOnboarding: false,
  login: mockLogin,
  register: vi.fn(),
  logout: vi.fn(),
  selectHousehold: vi.fn(),
  refreshHouseholds: vi.fn(),
  refreshCurrentHousehold: vi.fn(),
  completeOnboarding: vi.fn(),
};

vi.mock('@/contexts/auth-context', () => ({
  useAuth: () => mockAuthContext,
  AuthProvider: ({ children }: { children: React.ReactNode }) => children,
}));

import LoginPage from './page';

describe('LoginPage', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mockAuthContext.isLoading = false;
  });

  it('renders login form', () => {
    render(<LoginPage />);

    expect(screen.getByText('Welcome back')).toBeDefined();
    expect(screen.getByLabelText(/email/i)).toBeDefined();
    expect(screen.getByLabelText(/password/i)).toBeDefined();
    expect(screen.getByRole('button', { name: /sign in/i })).toBeDefined();
  });

  it('renders link to register page', () => {
    render(<LoginPage />);

    const registerLink = screen.getByText('Create one');
    expect(registerLink).toBeDefined();
    expect(registerLink.getAttribute('href')).toBe('/register');
  });

  it('shows loading spinner when auth is loading', () => {
    mockAuthContext.isLoading = true;
    render(<LoginPage />);

    // Should not show the form when loading
    expect(screen.queryByText('Welcome back')).toBeNull();
  });

  it('updates input fields when user types', () => {
    mockAuthContext.isLoading = false;
    render(<LoginPage />);

    const emailInput = screen.getByLabelText(/email/i) as HTMLInputElement;
    const passwordInput = screen.getByLabelText(/password/i) as HTMLInputElement;

    fireEvent.change(emailInput, { target: { value: 'test@example.com' } });
    fireEvent.change(passwordInput, { target: { value: 'password123' } });

    expect(emailInput.value).toBe('test@example.com');
    expect(passwordInput.value).toBe('password123');
  });

  it('calls login function on form submit', async () => {
    mockLogin.mockResolvedValue(undefined);
    render(<LoginPage />);

    const emailInput = screen.getByLabelText(/email/i);
    const passwordInput = screen.getByLabelText(/password/i);
    const submitButton = screen.getByRole('button', { name: /sign in/i });

    fireEvent.change(emailInput, { target: { value: 'test@example.com' } });
    fireEvent.change(passwordInput, { target: { value: 'password123' } });
    fireEvent.click(submitButton);

    await waitFor(() => {
      expect(mockLogin).toHaveBeenCalledWith({
        email: 'test@example.com',
        password: 'password123',
      });
    });
  });

  it('displays error message on login failure', async () => {
    mockLogin.mockRejectedValue({ message: 'Invalid credentials' });
    render(<LoginPage />);

    const emailInput = screen.getByLabelText(/email/i);
    const passwordInput = screen.getByLabelText(/password/i);
    const submitButton = screen.getByRole('button', { name: /sign in/i });

    fireEvent.change(emailInput, { target: { value: 'test@example.com' } });
    fireEvent.change(passwordInput, { target: { value: 'wrongpassword' } });
    fireEvent.click(submitButton);

    await waitFor(() => {
      expect(screen.getByText('Invalid credentials')).toBeDefined();
    });
  });

  it('shows loading state during submission', async () => {
    // Make login hang indefinitely
    mockLogin.mockImplementation(() => new Promise(() => {}));
    render(<LoginPage />);

    const emailInput = screen.getByLabelText(/email/i);
    const passwordInput = screen.getByLabelText(/password/i);
    const submitButton = screen.getByRole('button', { name: /sign in/i });

    fireEvent.change(emailInput, { target: { value: 'test@example.com' } });
    fireEvent.change(passwordInput, { target: { value: 'password123' } });
    fireEvent.click(submitButton);

    await waitFor(() => {
      expect(screen.getByText('Signing in...')).toBeDefined();
    });
  });
});

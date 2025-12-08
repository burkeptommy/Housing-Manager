import { render, screen } from '@testing-library/react';
import { describe, expect, it } from 'vitest';

import Home from './page';

describe('Home', () => {
  it('renders the main heading', () => {
    render(<Home />);
    expect(screen.getByText('Haven Home Manager')).toBeDefined();
  });

  it('renders all feature cards', () => {
    render(<Home />);
    expect(screen.getByText('Your Homes')).toBeDefined();
    expect(screen.getByText('Tasks')).toBeDefined();
    expect(screen.getByText('Rooms')).toBeDefined();
    expect(screen.getByText('Settings')).toBeDefined();
  });
});

import { Injectable } from '@nestjs/common';
import * as h3 from 'h3-js';

@Injectable()
export class H3Service {
  // H3 Resolution 8 = ~460m hexagon edge length
  // Good balance between privacy (not too granular) and relevance (meaningful "neighbor" concept)
  private readonly DEFAULT_RESOLUTION = 8;

  /**
   * Convert latitude/longitude to H3 index
   */
  getH3Index(lat: number, lng: number, resolution?: number): string {
    return h3.latLngToCell(lat, lng, resolution ?? this.DEFAULT_RESOLUTION);
  }

  /**
   * Get neighboring H3 cells within a given number of rings
   * @param h3Index - The center H3 cell
   * @param rings - Number of rings around the center (default: 1)
   * @returns Array of H3 indexes including the center cell
   */
  getNeighborCells(h3Index: string, rings: number = 1): string[] {
    return h3.gridDisk(h3Index, rings);
  }

  /**
   * Check if two H3 indexes are neighbors (within 1 ring)
   */
  areNeighbors(h3Index1: string, h3Index2: string): boolean {
    if (h3Index1 === h3Index2) return true;
    const neighbors = this.getNeighborCells(h3Index1, 1);
    return neighbors.includes(h3Index2);
  }

  /**
   * Get the center coordinates of an H3 cell
   */
  getCellCenter(h3Index: string): { lat: number; lng: number } {
    const [lat, lng] = h3.cellToLatLng(h3Index);
    return { lat, lng };
  }

  /**
   * Get the boundary polygon of an H3 cell (for map display)
   */
  getCellBoundary(h3Index: string): Array<{ lat: number; lng: number }> {
    const boundary = h3.cellToBoundary(h3Index);
    return boundary.map(([lat, lng]) => ({ lat, lng }));
  }

  /**
   * Check if an H3 index is valid
   */
  isValidH3Index(h3Index: string): boolean {
    return h3.isValidCell(h3Index);
  }

  /**
   * Get the resolution of an H3 index
   */
  getResolution(h3Index: string): number {
    return h3.getResolution(h3Index);
  }

  /**
   * Get approximate area of H3 cell in square kilometers
   */
  getCellAreaKm2(h3Index: string): number {
    return h3.cellArea(h3Index, 'km2');
  }
}

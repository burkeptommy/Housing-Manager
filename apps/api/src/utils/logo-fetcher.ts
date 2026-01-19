/**
 * Utility for auto-fetching company logos from website domains
 * Uses Clearbit Logo API (free, no API key required)
 */

/**
 * Extract domain from a URL
 */
export function extractDomain(url: string): string | null {
  try {
    // Add protocol if missing
    let urlWithProtocol = url;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      urlWithProtocol = `https://${url}`;
    }

    const parsedUrl = new URL(urlWithProtocol);
    return parsedUrl.hostname.replace(/^www\./, '');
  } catch {
    return null;
  }
}

/**
 * Get logo URL from Clearbit for a given domain
 * Clearbit's Logo API is free and doesn't require authentication
 * Returns a logo URL or null if the domain is invalid
 */
export function getClearbitLogoUrl(domain: string, size: number = 128): string {
  // Clearbit Logo API - free, high quality company logos
  return `https://logo.clearbit.com/${domain}?size=${size}`;
}

/**
 * Get logo URL from a website URL
 * @param websiteUrl - The website URL (e.g., "https://www.eversource.com" or "eversource.com")
 * @returns Logo URL or null if domain couldn't be extracted
 */
export function getLogoUrlFromWebsite(websiteUrl: string | null | undefined): string | null {
  if (!websiteUrl) {
    return null;
  }

  const domain = extractDomain(websiteUrl);
  if (!domain) {
    return null;
  }

  return getClearbitLogoUrl(domain);
}

/**
 * Validate if a logo URL returns a valid image
 * This is an optional step to verify the logo exists before saving
 */
export async function validateLogoUrl(logoUrl: string): Promise<boolean> {
  try {
    const response = await fetch(logoUrl, { method: 'HEAD' });
    const contentType = response.headers.get('content-type');
    return response.ok && (contentType?.startsWith('image/') ?? false);
  } catch {
    return false;
  }
}

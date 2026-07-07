// base64.ts
//
// Shared chunked ArrayBuffer→base64 encoder. July 2026 (audit F19):
// `btoa(String.fromCharCode(...new Uint8Array(buffer)))` spreads millions of
// args on multi-MB scanned PDFs and throws RangeError (max call-stack) → 500.
// receive-email already chunked its encoder; process-invoice never did, so
// email-forwarded PDF invoices 500'd. This is the one shared implementation.

const CHUNK_SIZE = 8192;

/** Encode an ArrayBuffer to a base64 string without blowing the call stack. */
export function arrayBufferToBase64(buffer: ArrayBuffer): string {
  const bytes = new Uint8Array(buffer);
  let result = "";
  for (let i = 0; i < bytes.length; i += CHUNK_SIZE) {
    const chunk = bytes.subarray(i, Math.min(i + CHUNK_SIZE, bytes.length));
    result += String.fromCharCode(...chunk);
  }
  return btoa(result);
}

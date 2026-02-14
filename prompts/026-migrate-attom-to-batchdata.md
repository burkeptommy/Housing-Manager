# Prompt 026: Migrate Property Enrichment from ATTOM to BatchData

## Context
Haven uses property data enrichment during onboarding to auto-populate home details (beds, baths, sqft, year built, heating, etc.) when a user enters their address. We're currently using ATTOM Data which costs ~$200/mo and requires sales calls for API access. We're migrating to **BatchData** which is $0.01/call with no subscription.

## Objective
Replace ATTOM API integration with BatchData in the property lookup service. The frontend (web + mobile) already calls our NestJS API at `/property/lookup` — we just need to swap the backend provider.

## BatchData API Details

### Authentication
- **API Key**: `cbusvwK7bF2ldPQymOClQGjvbdOIJ5hnX3HqqQmt`
- **Header**: `Authorization: Bearer cbusvwK7bF2ldPQymOClQGjvbdOIJ5hnX3HqqQmt`

### Property Lookup Endpoint
- **URL**: `POST https://api.batchdata.com/api/v1/property/lookup`
- **Content-Type**: `application/json`

### Request Format
```json
{
  "requests": [
    {
      "address": {
        "street": "38 Bedford Road",
        "city": "Greenwich",
        "state": "CT",
        "zip": "06831"
      }
    }
  ]
}
```

### Important: Discover Response Schema
BatchData returns 700+ attributes. **Before writing the mapping code**, make an actual test call to discover the exact response structure:

```bash
curl -X POST https://api.batchdata.com/api/v1/property/lookup \
  -H "Authorization: Bearer cbusvwK7bF2ldPQymOClQGjvbdOIJ5hnX3HqqQmt" \
  -H "Content-Type: application/json" \
  -d '{
    "requests": [
      {
        "address": {
          "street": "38 Bedford Road",
          "city": "Greenwich",
          "state": "CT",
          "zip": "06831"
        }
      }
    ]
  }'
```

Use this real response to build the field mapping. Log the full response to understand the structure.

## Files to Modify

### 1. `apps/api/src/property/property.service.ts` (PRIMARY)
This is the core file. Currently:
- Uses `ATTOM_API_KEY` env var
- Calls `https://api.gateway.attomdata.com/propertyapi/v1.0.0/property/expandedprofile`
- Has `parseAttomProperty()` method mapping ATTOM fields → `PropertyDetails` interface

**Changes needed:**
- Replace `attomApiKey` with `batchDataApiKey` (hardcode or use env var `BATCHDATA_API_KEY`)
- Change `baseUrl` to `https://api.batchdata.com/api/v1`
- Update `lookupByAddress()` to use BatchData POST format with `requests` array
- Update auth header from `APIKey` to `Authorization: Bearer {key}`
- Replace `parseAttomProperty()` with `parseBatchDataProperty()` mapping BatchData fields → same `PropertyDetails` interface
- Keep the `PropertyDetails` interface and `PropertyLookupResult` interface unchanged — the frontend depends on them

**The `PropertyDetails` interface that must be maintained:**
```typescript
interface PropertyDetails {
  bedrooms: number | null;
  bathrooms: number | null;
  bathsFull: number | null;
  bathsHalf: number | null;
  squareFeet: number | null;
  lotSizeSquareFeet: number | null;
  lotSizeAcres: number | null;
  yearBuilt: number | null;
  propertyType: string | null;
  propertySubType: string | null;
  stories: number | null;
  constructionType: string | null;
  foundationType: string | null;
  roofType: string | null;
  roofMaterial: string | null;
  exteriorWalls: string | null;
  heatingType: string | null;
  heatingFuel: string | null;
  coolingType: string | null;
  waterType: string | null;
  sewerType: string | null;
  fireplaces: number | null;
  garage: string | null;
  garageSpaces: number | null;
  pool: boolean | null;
  poolType: string | null;
  totalRooms: number | null;
  basementType: string | null;
  assessedValue: number | null;
  marketValue: number | null;
  taxAmount: number | null;
  lastSalePrice: number | null;
  lastSaleDate: string | null;
  verifiedAddress: string | null;
  latitude: number | null;
  longitude: number | null;
}
```

### 2. `apps/api/src/property/property-enrichment.service.ts`
- Rename `enrichHouseholdFromAttom()` → `enrichHouseholdFromPropertyData()` (or keep old name for now with a TODO)
- The field mapping inside this method references ATTOM's nested structure (`property.building.rooms.beds`, `property.lot.lotSize1`, etc.)
- Update these to match whatever BatchData returns
- OR better: since `property.service.ts` already maps to `PropertyDetails`, have the enrichment service accept `PropertyDetails` instead of raw API data

### 3. `apps/api/src/property/property.controller.ts`
- No changes needed if the service interface stays the same
- Just verify the `/lookup` endpoint still works

### 4. Environment Variables
- Add `BATCHDATA_API_KEY=cbusvwK7bF2ldPQymOClQGjvbdOIJ5hnX3HqqQmt` to:
  - `apps/api/.env` (local dev)
  - Production env (Google Cloud Run) — note this for Tom to do manually
- Remove or comment out `ATTOM_API_KEY` references
- Update `apps/api/src/property/property.module.ts` if needed (likely no changes)

### 5. Comments/References Cleanup
Search and update any "ATTOM" references in comments:
- `apps/mobile/app/(onboarding)/confirm-property.tsx` — has comment "Fetch property details from ATTOM via API"
- Any other files mentioning ATTOM

## Implementation Steps

1. **Make a test call** to BatchData using the curl command above. Save the full JSON response to understand the schema.

2. **Update `property.service.ts`**:
   - Change API URL and auth
   - Build `parseBatchDataProperty()` based on actual response schema
   - Map all available fields to the existing `PropertyDetails` interface
   - For any fields BatchData doesn't provide, return `null`

3. **Update `property-enrichment.service.ts`**:
   - Refactor to accept `PropertyDetails` instead of raw API data
   - OR update the raw data field paths to match BatchData's response

4. **Add env var** to `.env`

5. **Test end-to-end**:
   - Start API locally: `cd apps/api && pnpm dev`
   - Test the lookup endpoint:
     ```bash
     curl "http://localhost:4000/api/property/lookup?street=38+Bedford+Road&city=Greenwich&state=CT&zip=06831" \
       -H "Authorization: Bearer <firebase-token>"
     ```
   - Verify response matches `PropertyDetails` interface
   - Test with a property that might NOT be found (graceful fallback)

6. **Clean up ATTOM references** in comments across the codebase

## Important Notes

- **Do NOT change the `PropertyDetails` interface or `PropertyLookupResult` interface** — the web and mobile frontends depend on them
- **Do NOT change the `/property/lookup` endpoint signature** — same query params (street, city, state, zip)
- If BatchData provides MORE data than ATTOM did (e.g., foundation type, roof material that ATTOM returned null for), map those too — more data is better
- BatchData may return data in a different structure. Use the test call response to build accurate mappings.
- The `PropertyDetails.lotSizeAcres` field: ATTOM provided this directly. If BatchData only gives sq ft, convert: `acres = sqft / 43560`
- Log the raw BatchData response at `debug` level for troubleshooting

## Production Deployment
After local testing passes, deploy the BATCHDATA_API_KEY to Google Cloud Run production environment:

```bash
# Set the env var on Cloud Run (api service)
gcloud run services update haven-api \
  --region=us-east1 \
  --update-env-vars="BATCHDATA_API_KEY=cbusvwK7bF2ldPQymOClQGjvbdOIJ5hnX3HqqQmt"
```

Verify the correct service name and region by checking existing config:
```bash
gcloud run services list
```

Also remove the old ATTOM_API_KEY env var from Cloud Run if it exists:
```bash
gcloud run services update haven-api \
  --region=us-east1 \
  --remove-env-vars="ATTOM_API_KEY"
```

## Verification Checklist
- [ ] BatchData API call works with the provided API key
- [ ] `PropertyDetails` response matches existing interface
- [ ] Morrison property (38 Bedford Road, Greenwich CT) returns enriched data
- [ ] Property not found returns `{ success: false, data: null }` gracefully
- [ ] No ATTOM references remain in active code (comments updated)
- [ ] `BATCHDATA_API_KEY` env var added to `.env`
- [ ] API builds without errors: `cd apps/api && pnpm build`
- [ ] Checklist generation still works (uses PropertyDetails)

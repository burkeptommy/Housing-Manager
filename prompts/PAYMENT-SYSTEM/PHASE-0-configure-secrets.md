# PHASE 0: Configure API Keys & Secrets

## OVERVIEW
Add all required API keys to Google Secret Manager and update the deployment configuration.

---

## STEP 1: Add Plaid Secrets to Google Secret Manager

Run these commands:

```bash
# Add Plaid Client ID
echo -n "<YOUR_PLAID_CLIENT_ID>" | gcloud secrets create PLAID_CLIENT_ID --data-file=- --project=home-manager-480616

# Add Plaid Secret
echo -n "<YOUR_PLAID_SECRET>" | gcloud secrets create PLAID_SECRET --data-file=- --project=home-manager-480616
```

If secrets already exist, update them instead:
```bash
echo -n "<YOUR_PLAID_CLIENT_ID>" | gcloud secrets versions add PLAID_CLIENT_ID --data-file=- --project=home-manager-480616
echo -n "<YOUR_PLAID_SECRET>" | gcloud secrets versions add PLAID_SECRET --data-file=- --project=home-manager-480616
```

---

## STEP 2: Update cloudbuild-api.yaml

Edit `/Users/tomburke/Projects/Housing-Manager/cloudbuild-api.yaml`

Find the `--set-secrets` line and add the Plaid secrets:

```yaml
- '--set-secrets'
- 'JWT_SECRET=JWT_SECRET:latest,DATABASE_URL=DATABASE_URL:latest,STRIPE_SECRET_KEY=STRIPE_SECRET_KEY:latest,STRIPE_PUBLISHABLE_KEY=STRIPE_PUBLISHABLE_KEY:latest,OPENAI_API_KEY=OPENAI_API_KEY:latest,SENDGRID_API_KEY=SENDGRID_API_KEY:latest,FIREBASE_SERVICE_ACCOUNT=FIREBASE_SERVICE_ACCOUNT:latest,MAPS_KEY=MAPS_KEY:latest,ATTOM_API_KEY=ATTOM_API_KEY:latest,ANTHROPIC_API_KEY=ANTHROPIC_API_KEY:latest,PLAID_CLIENT_ID=PLAID_CLIENT_ID:latest,PLAID_SECRET=PLAID_SECRET:latest'
```

---

## STEP 3: Update Local .env File

Edit `/Users/tomburke/Projects/Housing-Manager/apps/api/.env` and add/update:

```env
# Plaid (Sandbox)
PLAID_ENV=sandbox
PLAID_CLIENT_ID=<your_plaid_client_id>
PLAID_SECRET=<your_plaid_secret>

# Stripe (Sandbox)
STRIPE_SECRET_KEY=<your_stripe_secret_key>
STRIPE_PUBLISHABLE_KEY=<your_stripe_publishable_key>

# Checkbook.io (should already exist, verify these are present)
CHECKBOOK_API_KEY=your_checkbook_key
CHECKBOOK_API_SECRET=your_checkbook_secret
CHECKBOOK_TEST_MODE=true
```

---

## STEP 4: Verify Configuration

Test that the API can read the keys:

```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/api
pnpm dev
```

Check the logs - you should NOT see errors about missing PLAID_CLIENT_ID or PLAID_SECRET.

---

## VERIFICATION CHECKLIST

- [ ] Plaid secrets added to Google Secret Manager
- [ ] cloudbuild-api.yaml updated with new secrets
- [ ] Local .env file has all keys
- [ ] API starts without configuration errors

---

## NEXT STEP

Once verified, proceed to PHASE-1-stripe-issuing.md

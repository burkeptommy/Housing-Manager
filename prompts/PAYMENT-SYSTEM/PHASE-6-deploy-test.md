# PHASE 6: Deploy & Test Payment System

## OVERVIEW
Deploy all payment system changes to production and test end-to-end.

---

## STEP 1: Run All Migrations

```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/api

# Generate Prisma client
pnpm prisma generate

# Check migration status
pnpm prisma migrate status

# Run migrations (this will add all payment system tables)
pnpm prisma migrate deploy
```

---

## STEP 2: Build and Verify Locally

```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/api

# Build to check for TypeScript errors
pnpm build

# If errors, fix them before deploying
```

---

## STEP 3: Test Locally with Sandbox Keys

```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/api

# Make sure .env has sandbox keys:
# PLAID_ENV=sandbox
# PLAID_CLIENT_ID=6951feb3168aa50020a8b7f3
# PLAID_SECRET=d29c10fb56ddcf610a0762f581af56
# STRIPE_SECRET_KEY=sk_test_...
# CHECKBOOK_TEST_MODE=true

pnpm dev
```

Test each endpoint:

```bash
# 1. Create Haven Card
curl -X POST http://localhost:4000/api/payments/card/create \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json"

# 2. Get Card Status
curl http://localhost:4000/api/payments/card \
  -H "Authorization: Bearer YOUR_TOKEN"

# 3. Create a Test Bill
curl -X POST http://localhost:4000/api/payments/bills \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Electric Bill",
    "category": "utility",
    "amount": 150.00,
    "frequency": "monthly",
    "dueDay": 15,
    "paymentMethod": "card",
    "autopayEnabled": true
  }'

# 4. Get Bills
curl http://localhost:4000/api/payments/bills \
  -H "Authorization: Bearer YOUR_TOKEN"

# 5. Get Dashboard
curl http://localhost:4000/api/payments/dashboard \
  -H "Authorization: Bearer YOUR_TOKEN"

# 6. Get Upcoming Bills
curl http://localhost:4000/api/payments/bills/upcoming?days=30 \
  -H "Authorization: Bearer YOUR_TOKEN"

# 7. Test Payment Execution (will simulate in sandbox)
curl -X POST http://localhost:4000/api/payments/bills/BILL_ID/pay \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json"

# 8. Get Payment History
curl http://localhost:4000/api/payments/dashboard/history \
  -H "Authorization: Bearer YOUR_TOKEN"

# 9. Test Orchestration Trigger (use your CRON_SECRET)
curl -X POST http://localhost:4000/api/internal/payments/process \
  -H "x-cron-secret: YOUR_CRON_SECRET"
```

---

## STEP 4: Deploy to Cloud Run

```bash
cd /Users/tomburke/Projects/Housing-Manager

# Deploy API
gcloud builds submit --config=cloudbuild-api.yaml --project=home-manager-480616

# Watch the build
# It should complete successfully with all payment modules included
```

---

## STEP 5: Run Production Migrations

```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/api

# Connect to production database and run migrations
# Make sure DATABASE_URL points to production
pnpm prisma migrate deploy
```

---

## STEP 6: Verify Production Deployment

Test the production endpoints:

```bash
# Replace with your production API URL
API_URL=https://haven-api-XXXXX.us-east1.run.app/api

# 1. Health check
curl $API_URL/health

# 2. Get dashboard (with auth)
curl $API_URL/payments/dashboard \
  -H "Authorization: Bearer YOUR_PRODUCTION_TOKEN"

# 3. Get bills
curl $API_URL/payments/bills \
  -H "Authorization: Bearer YOUR_PRODUCTION_TOKEN"
```

---

## STEP 7: Test Mobile App Integration

If updating the mobile app to use new endpoints:

1. Update mobile API calls to use new endpoints
2. Test in simulator:
```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/mobile
npx expo start --clear --ios
```

3. Verify:
- [ ] Dashboard loads with bill summary
- [ ] Bills list displays
- [ ] Can create new bill via Alfred
- [ ] Payment history shows
- [ ] Approval flow works

---

## STEP 8: Set Up Cloud Scheduler (Optional)

To automatically process bills daily:

```bash
# Create a Cloud Scheduler job to call the orchestration endpoint
gcloud scheduler jobs create http haven-payment-processor \
  --location=us-east1 \
  --schedule="0 6 * * *" \
  --uri="https://haven-api-XXXXX.us-east1.run.app/api/internal/payments/process" \
  --http-method=POST \
  --headers="x-cron-secret=YOUR_CRON_SECRET" \
  --time-zone="America/New_York" \
  --project=home-manager-480616
```

---

## API Endpoints Summary

### Card Management
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/payments/card/create` | Create household card |
| GET | `/payments/card` | Get card status |
| POST | `/payments/card/freeze` | Freeze card |
| POST | `/payments/card/unfreeze` | Unfreeze card |
| POST | `/payments/card/link-funding/:plaidAccountId` | Link bank account |

### Bill Management
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/payments/bills` | Create new bill |
| GET | `/payments/bills` | Get all bills |
| GET | `/payments/bills/upcoming` | Get upcoming bills |
| GET | `/payments/bills/summary` | Get bill summary |
| PUT | `/payments/bills/:id` | Update bill |
| POST | `/payments/bills/:id/toggle-autopay` | Toggle autopay |
| DELETE | `/payments/bills/:id` | Cancel bill |
| POST | `/payments/bills/:id/pay` | Pay bill now |
| GET | `/payments/bills/:id/payments` | Get payment history for bill |
| POST | `/payments/bills/from-detected/:id` | Create from detected bill |

### Approvals
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/payments/approvals` | Get pending approvals |
| POST | `/payments/approvals/:id/approve` | Approve payment |
| POST | `/payments/approvals/:id/deny` | Deny payment |

### Dashboard
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/payments/dashboard` | Main dashboard |
| GET | `/payments/dashboard/bills` | All bills detailed |
| GET | `/payments/dashboard/history` | Payment history |
| GET | `/payments/dashboard/monthly` | Monthly breakdown |
| GET | `/payments/dashboard/annual` | Annual summary |
| GET | `/payments/dashboard/detected` | Detected bills |

### Internal
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/internal/payments/process` | Trigger payment processing |
| GET | `/internal/payments/status` | Check orchestration status |

---

## VERIFICATION CHECKLIST

### Local Testing
- [ ] Card creation works (test mode)
- [ ] Bill creation works
- [ ] Bill listing works
- [ ] Dashboard returns data
- [ ] Payment execution works (simulated)
- [ ] Approval flow works
- [ ] Orchestration trigger works

### Production Deployment
- [ ] Cloud Build succeeds
- [ ] Migrations run successfully
- [ ] API endpoints respond
- [ ] Auth works with production tokens
- [ ] Dashboard returns real data

### Integration
- [ ] Mobile app can fetch dashboard
- [ ] Mobile app can create bills
- [ ] Alfred tools execute successfully

---

## Troubleshooting

### Build Errors
```bash
# Check TypeScript errors
cd /Users/tomburke/Projects/Housing-Manager/apps/api
npx tsc --noEmit
```

### Database Issues
```bash
# Reset migrations if needed (CAREFUL - loses data)
pnpm prisma migrate reset

# Or just regenerate client
pnpm prisma generate
```

### API Not Responding
```bash
# Check Cloud Run logs
gcloud run services logs read haven-api --region=us-east1 --project=home-manager-480616
```

### Plaid Issues
- Make sure `PLAID_ENV=sandbox` in production for testing
- Use test credentials: `user_good` / `pass_good`

---

## SUCCESS!

If all checks pass, the payment system is live!

Users can now:
1. ✅ Create bills via Alfred conversation
2. ✅ See bill dashboard with upcoming payments
3. ✅ Autopay bills via card or check
4. ✅ Approve high-value payments
5. ✅ View payment history
6. ✅ Request Haven team to negotiate/dispute bills

---

## Post-Deployment Tasks

1. **Monitor** - Watch logs for any errors
2. **Test with real account** - Connect a real bank in sandbox mode
3. **Create demo bills** - Seed some test bills for demos
4. **Document** - Update API documentation if needed

# GDPR Technical Reference

Source: EU General Data Protection Regulation (GDPR) 2016/679 — Articles 5, 17, 20, 25, and 32

Scope: Code-level controls for applications handling personal data of EU/EEA residents.

---

## Article 5 — Data Processing Principles

### 5(1)(a) — Lawfulness, Fairness, Transparency

Collect personal data only with a valid lawful basis. Common lawful bases:

| Basis | When to use | Code implication |
|---|---|---|
| **Consent** | Marketing, analytics, non-essential processing | Must record consent: what, when, who, version |
| **Contract** | Data needed to fulfill a contract | No consent record needed — document in privacy policy |
| **Legitimate interest** | Fraud prevention, security | Requires LIA (Legitimate Interest Assessment) — not a code control |
| **Legal obligation** | Tax records, regulatory reporting | No consent needed — document retention period |

**Consent schema:**

```sql
CREATE TABLE consents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id),
  purpose VARCHAR(100) NOT NULL,        -- 'marketing_email', 'analytics', 'profiling'
  lawful_basis VARCHAR(50) NOT NULL,    -- 'consent', 'contract', 'legitimate_interest'
  granted BOOLEAN NOT NULL,
  granted_at TIMESTAMP WITH TIME ZONE,
  withdrawn_at TIMESTAMP WITH TIME ZONE,
  consent_version VARCHAR(20) NOT NULL, -- e.g., '2026-01-15' (date of privacy policy)
  ip_address INET,
  user_agent TEXT
);
-- Index for fast lookup of current consent state:
CREATE INDEX idx_consents_user_purpose ON consents(user_id, purpose);
```

### 5(1)(c) — Data Minimization

Collect only what is necessary for the stated purpose:

```typescript
// BAD: collecting DOB when only age verification is needed
interface UserRegistration {
  email: string
  dateOfBirth: string  // storing full DOB to verify age ≥ 18
}

// GOOD: collect only the derived fact needed
interface UserRegistration {
  email: string
  isOver18: boolean  // confirmed by user — store confirmation, not DOB
}
```

### 5(1)(e) — Storage Limitation

Data must not be kept longer than necessary. Implement automated deletion:

```sql
-- Pattern: add retention metadata to personal data tables
ALTER TABLE users ADD COLUMN data_retention_until DATE;
ALTER TABLE users ADD COLUMN data_retention_basis VARCHAR(100);

-- Scheduled job: delete or anonymize records past retention date
DELETE FROM users
WHERE data_retention_until < CURRENT_DATE
  AND data_retention_basis = 'consent'
  AND consent_withdrawn = true;
```

---

## Article 17 — Right to Erasure ("Right to Be Forgotten")

Users can request deletion of their personal data when the lawful basis no longer applies.

### Erasure Endpoint Pattern

```typescript
// GDPR erasure endpoint
app.delete('/account', requireAuth, async (req, res) => {
  const userId = req.user.id

  await db.transaction(async (trx) => {
    // 1. Anonymize fields that must be retained for legal/financial records
    await trx('orders').where({ user_id: userId }).update({
      customer_name: '[DELETED]',
      customer_email: '[DELETED]',
      customer_address: '[DELETED]'
      // order total, date, product IDs retained for accounting (legal obligation basis)
    })

    // 2. Delete personal profile data
    await trx('user_profiles').where({ user_id: userId }).delete()
    await trx('consents').where({ user_id: userId }).delete()
    await trx('sessions').where({ user_id: userId }).delete()

    // 3. Mark user as deleted (soft delete — audit trail of deletion event)
    await trx('users').where({ id: userId }).update({
      email: `deleted-${userId}@deleted.invalid`, // unique to avoid constraint violations
      deleted_at: new Date(),
      deletion_reason: 'user_requested_erasure'
    })
  })

  // 4. Trigger downstream deletion (message queue event)
  await eventBus.publish('user.erasure_requested', { userId })

  res.json({ message: 'Your account and personal data have been deleted.' })
})
```

### What cannot be erased (legitimate retention exceptions)

| Data type | Retention basis | Typical period |
|---|---|---|
| Financial transaction amounts | Legal obligation (tax) | 7 years |
| Order fulfillment records (anonymized) | Legal obligation | 6 years |
| Security audit logs (anonymized) | Legitimate interest | 12 months |

---

## Article 20 — Right to Data Portability

Users can request an export of their personal data in a machine-readable format (JSON or CSV).

```typescript
// Data export endpoint
app.get('/account/export', requireAuth, async (req, res) => {
  const userId = req.user.id

  const [profile, orders, consents, preferences] = await Promise.all([
    db('users').where({ id: userId }).first(),
    db('orders').where({ user_id: userId }),
    db('consents').where({ user_id: userId }),
    db('user_preferences').where({ user_id: userId })
  ])

  const export_data = {
    exported_at: new Date().toISOString(),
    profile: {
      email: profile.email,
      name: profile.full_name,
      created_at: profile.created_at
    },
    orders: orders.map(o => ({ id: o.id, placed_at: o.placed_at, total: o.total })),
    consents: consents.map(c => ({ purpose: c.purpose, granted: c.granted, at: c.granted_at })),
    preferences
  }

  res.setHeader('Content-Disposition', 'attachment; filename="my-data.json"')
  res.json(export_data)
})
```

---

## Article 25 — Privacy by Design and Default

### Default settings must be privacy-preserving

```typescript
// BAD: opt-out model (user must disable tracking)
const newUserDefaults = {
  marketingEmails: true,    // user must unsubscribe
  analyticsTracking: true,  // user must opt out
  profilePublic: true       // user must make private
}

// GOOD: opt-in model (user must actively enable non-essential processing)
const newUserDefaults = {
  marketingEmails: false,   // user must subscribe
  analyticsTracking: false, // user must opt in
  profilePublic: false      // user must make public
}
```

### Privacy-by-default API design

```typescript
// API response must not return personal data fields by default
// BAD: returns all fields including personal data
GET /users/:id → { id, email, name, phone, address, dob, ssn, ... }

// GOOD: public endpoint returns only public fields
GET /users/:id → { id, displayName, joinedDate }
// Authenticated owner endpoint returns full profile
GET /account/me → { id, email, name, phone, address }
```

---

## Article 32 — Security of Processing

```typescript
// Pseudonymization: replace direct identifiers with tokens
// BAD: store email in analytics events
analyticsEvent({ event: 'purchase', user_email: user.email, amount: 99.99 })

// GOOD: use a pseudonym (one-way hash of email with site-specific salt)
const pseudoId = crypto.createHmac('sha256', ANALYTICS_SALT).update(user.email).digest('hex')
analyticsEvent({ event: 'purchase', user_pseudo_id: pseudoId, amount: 99.99 })
```

---

## GDPR Code Checklist

| Article | Control | Code Verifiable? |
|---|---|---|
| 5(1)(a) | Consent recorded with purpose, version, timestamp | Yes — check consents table schema |
| 5(1)(c) | Only necessary fields collected | Yes — review data models |
| 5(1)(e) | Data retention policy implemented with automated deletion | Yes — check for scheduled jobs |
| 17 | Right-to-erasure endpoint exists | Yes — check for DELETE /account or equivalent |
| 17 | Erasure cascades to all personal data tables | Yes — trace the erasure handler |
| 17 | Financial data anonymized (not deleted) on erasure | Yes — check erasure handler for anonymization |
| 20 | Data export endpoint exists (JSON/CSV) | Yes — check for GET /account/export or equivalent |
| 25 | New accounts default to privacy-preserving settings | Yes — check default values |
| 25 | APIs return minimum necessary data by default | Yes — review response schemas |
| 32 | Personal data pseudonymized in analytics | Yes — grep analytics events for PII fields |
| 32 | Encryption in transit (TLS 1.2+) | Partial — verify TLS config at infra level |

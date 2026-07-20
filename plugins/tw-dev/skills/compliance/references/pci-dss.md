# PCI DSS v4.0 Technical Reference

Source: PCI DSS v4.0 (March 2022) — Requirements 3 (Protect Cardholder Data) and 6 (Develop and Maintain Secure Systems)

Scope: Code-level controls. Network segmentation, physical security, and organizational requirements are out of scope for this reference.

---

## Requirement 3 — Protect Stored Cardholder Data

### 3.2 — Storage Minimization

**What must NEVER be stored after authorization (even encrypted):**
- Full magnetic stripe data (Track 1 / Track 2)
- CAV2 / CVC2 / CVV2 / CID (the 3-4 digit security code)
- PIN / PIN block

**What may be stored (with protection):**
- PAN (Primary Account Number) — must be masked or tokenized
- Cardholder name
- Service code
- Expiration date

```typescript
// BAD: storing CVV — this is a PCI DSS violation regardless of encryption
interface PaymentMethod {
  pan: string
  cvv: string  // NEVER store this
  expiryMonth: number
  expiryYear: number
}

// GOOD: store only the token from the payment processor
interface PaymentMethod {
  processorToken: string  // e.g., Stripe PaymentMethod ID
  lastFour: string        // for display only
  expiryMonth: number
  expiryYear: number
  cardBrand: 'visa' | 'mastercard' | 'amex'
}
```

### 3.3 — PAN Display Masking

When displaying PANs, show maximum of first 6 and last 4 digits:

```typescript
const maskPAN = (pan: string): string => {
  const cleaned = pan.replace(/\s/g, '')
  if (cleaned.length < 10) return '*'.repeat(cleaned.length)
  return cleaned.slice(0, 6) + '*'.repeat(cleaned.length - 10) + cleaned.slice(-4)
}
// "4111111111111111" → "411111******1111"
```

### 3.5 — Tokenization (Preferred Pattern)

Use your payment processor's tokenization — never process raw PANs in your application:

```typescript
// GOOD: Stripe Elements — PAN never touches your server
// In browser: Stripe.js handles PAN collection and tokenizes it
const { error, paymentMethod } = await stripe.createPaymentMethod({
  type: 'card',
  card: cardElement  // PAN collected in Stripe-hosted iframe
})
// Your server receives only paymentMethod.id (a token)
await fetch('/api/checkout', {
  body: JSON.stringify({ paymentMethodId: paymentMethod.id, amount: 1000 })
})
```

---

## Requirement 6 — Secure Software Development

### 6.2 — Bespoke Software Security

**Input validation:**

```typescript
// Validate all inputs at the boundary
const validateCheckoutRequest = (body: unknown): CheckoutRequest => {
  const schema = z.object({
    paymentMethodId: z.string().regex(/^pm_[a-zA-Z0-9]+$/, 'Invalid payment method ID'),
    amount: z.number().int().positive().max(100000), // max $1000.00 in cents
    currency: z.enum(['usd', 'eur', 'gbp']),
    orderId: z.string().uuid()
  })
  return schema.parse(body)  // throws ZodError on invalid input
}
```

**SQL injection prevention:**

```typescript
// BAD: string concatenation
const query = `SELECT * FROM orders WHERE user_id = '${userId}'`

// GOOD: parameterized queries
const order = await db.query('SELECT * FROM orders WHERE user_id = $1', [userId])
```

**Error handling — never expose card data in errors:**

```typescript
// BAD: exposes PAN in error log
catch (err) {
  logger.error(`Payment failed for card ${cardNumber}: ${err.message}`)
}

// GOOD: log only the token reference
catch (err) {
  logger.error({ paymentMethodId, orderId, error: err.message }, 'Payment processing failed')
}
```

### 6.3 — Dependency Vulnerability Management

```bash
# Run before every release (or in CI):
npm audit --audit-level=high       # Node.js
pip-audit                          # Python
./mvnw dependency:check            # Java (OWASP dependency-check)
govulncheck ./...                  # Go
cargo audit                        # Rust
```

Add to CI pipeline — block merge on HIGH or CRITICAL vulnerabilities.

### 6.4 — Web Application Firewall (WAF)

If your application has a public-facing payment page, a WAF is required. This is an infrastructure control, but verify the configuration:
- Block OWASP Top 10 injection patterns
- Block card scraping patterns
- Rate limit checkout endpoints

---

## What Must NEVER Appear in Logs

```typescript
// Audit your logging statements for these patterns:
const FORBIDDEN_IN_LOGS = [
  /\bpan\b/i,
  /\bcvv\b/i,
  /\bcvc\b/i,
  /\bcard.number\b/i,
  /\bcredit.card\b/i,
  /[3-6]\d{3}[\s-]?\d{4}[\s-]?\d{4}[\s-]?\d{4}/,  // PAN pattern
]
// Grep your codebase: grep -rn "console.log\|logger\." src/ | grep -i "card\|pan\|cvv"
```

---

## PCI DSS Code Checklist

| Requirement | Control | Code Verifiable? |
|---|---|---|
| 3.2 | CVV/track data never stored | Yes — grep for cvv, cvc, track fields in DB schema |
| 3.3 | PAN masked in display (first 6 + last 4) | Yes — check display functions |
| 3.5 | PAN tokenized (not stored) | Yes — grep for raw card storage |
| 6.2 | All inputs validated at API boundary | Yes — check request validation |
| 6.2 | SQL injection prevented (parameterized queries) | Yes — grep for string concatenation in queries |
| 6.2 | PAN/CVV absent from logs | Yes — grep log statements |
| 6.2 | Errors don't expose card data | Yes — check error handlers |
| 6.3 | Dependencies scanned for vulnerabilities | Yes — check CI pipeline for npm audit / pip-audit |
| 6.4 | WAF in place for payment pages | Manual — infrastructure-level |
| 6.5 | TLS 1.2+ on all payment endpoints | Partial — verify TLS config |

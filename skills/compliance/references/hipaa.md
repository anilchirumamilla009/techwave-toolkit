# HIPAA Technical Safeguards Reference

Source: 45 CFR Part 164, Subpart C (Security Rule — Technical Safeguards)

---

## 164.312(a)(1) — Access Control

**Requirement**: Implement technical policies and procedures that allow only authorized persons to access ePHI.

### Code Controls

**Unique user identification (Required):**
- Every user must have a unique identifier — never allow shared accounts
- Never use generic accounts (`admin`, `test`, `service`) to access ePHI data

```python
# Pattern: enforce unique user IDs on all ePHI data access
class PHIAccessLog(Base):
    id: UUID = Column(UUID, primary_key=True, default=uuid4)
    user_id: UUID = Column(UUID, nullable=False)  # NEVER NULL — no anonymous ePHI access
    action: str = Column(String, nullable=False)
    resource_type: str = Column(String, nullable=False)
    resource_id: UUID = Column(UUID, nullable=False)
    timestamp: datetime = Column(DateTime, nullable=False, default=datetime.utcnow)
    ip_address: str = Column(String)
```

**Automatic logoff (Addressable):**
- Sessions must expire after inactivity (recommended: 15 minutes for clinical staff)
- Implement server-side session invalidation (not just cookie expiry)

**Encryption and decryption (Addressable):**
- ePHI at rest: AES-256 encryption for database fields containing PHI
- Never store PHI in logs, error messages, or analytics events

```typescript
// Pattern: PHI field encryption using application-layer encryption
import { createCipheriv, createDecipheriv, randomBytes } from 'crypto'

const encryptPHI = (plaintext: string, key: Buffer): string => {
  const iv = randomBytes(16)
  const cipher = createCipheriv('aes-256-gcm', key, iv)
  const encrypted = Buffer.concat([cipher.update(plaintext, 'utf8'), cipher.final()])
  const tag = cipher.getAuthTag()
  return `${iv.toString('hex')}:${tag.toString('hex')}:${encrypted.toString('hex')}`
}
```

---

## 164.312(b) — Audit Controls

**Requirement**: Implement hardware, software, and/or procedural mechanisms to record and examine activity in systems that contain or use ePHI.

### Code Controls

**What must be logged:**
- Every read access to ePHI records (not just writes)
- User identity, timestamp, action, resource ID, outcome
- Failed access attempts
- System-level events (login, logout, password changes)

**What must NOT be in logs:**
- PHI field values (name, SSN, DOB, diagnosis, medication)
- Passwords or authentication tokens
- Full credit card numbers

```typescript
// Pattern: structured audit log without PHI values
interface AuditEvent {
  eventId: string        // UUID
  userId: string         // required — who performed the action
  action: 'READ' | 'CREATE' | 'UPDATE' | 'DELETE' | 'EXPORT'
  resourceType: string   // e.g., 'Patient', 'Encounter', 'Prescription'
  resourceId: string     // ID only — never the PHI content
  outcome: 'SUCCESS' | 'FAILURE' | 'PARTIAL'
  timestamp: string      // ISO 8601 UTC
  ipAddress: string
  userAgent?: string
}

// BAD: logs PHI
logger.info(`User ${userId} accessed patient ${patient.name} (SSN: ${patient.ssn})`)

// GOOD: logs access event without PHI
auditLogger.log({ action: 'READ', resourceType: 'Patient', resourceId: patient.id, outcome: 'SUCCESS' })
```

**Audit log retention:** Minimum 6 years per HIPAA (longer if state law requires).

---

## 164.312(c)(1) — Integrity Controls

**Requirement**: Implement policies and procedures to protect ePHI from improper alteration or destruction.

### Code Controls

- Use database transactions for all ePHI modifications
- Implement soft deletes (mark as deleted, never physically destroy ePHI prematurely)
- Store a hash/checksum of critical ePHI records to detect tampering

```sql
-- Pattern: soft delete on PHI tables
ALTER TABLE patients ADD COLUMN deleted_at TIMESTAMP;
ALTER TABLE patients ADD COLUMN deletion_reason TEXT;
-- Physical deletion only after retention period expires (controlled process)
```

---

## 164.312(d) — Authentication Controls

**Requirement**: Implement procedures to verify that a person seeking access is who they claim.

### Code Controls

**Password requirements (minimum):**
- Minimum 8 characters (12+ recommended)
- bcrypt with cost factor ≥ 12 (or Argon2id)
- Never store plaintext or MD5/SHA1 hashed passwords

**Multi-factor authentication:**
- Required for remote access to systems containing ePHI
- Required for privileged accounts

```python
# Pattern: password hashing with bcrypt
import bcrypt

def hash_password(plain: str) -> str:
    return bcrypt.hashpw(plain.encode(), bcrypt.gensalt(rounds=12)).decode()

def verify_password(plain: str, hashed: str) -> bool:
    return bcrypt.checkpw(plain.encode(), hashed.encode())
```

---

## 164.312(e)(1) — Transmission Security

**Requirement**: Implement technical security measures to guard against unauthorized access to ePHI transmitted over a network.

### Code Controls

- **TLS 1.2+ required** for all ePHI transmission; TLS 1.3 preferred
- Never transmit ePHI over HTTP (unencrypted)
- Certificate pinning for mobile apps accessing ePHI
- HTTPS `Strict-Transport-Security` header (HSTS) on all services

```typescript
// Pattern: enforce HTTPS with HSTS
app.use((req, res, next) => {
  if (req.header('x-forwarded-proto') !== 'https' && process.env.NODE_ENV === 'production') {
    return res.redirect(301, `https://${req.headers.host}${req.url}`)
  }
  res.setHeader('Strict-Transport-Security', 'max-age=31536000; includeSubDomains')
  next()
})
```

---

## HIPAA Compliance Checklist

| Control | Category | Code Verifiable? |
|---|---|---|
| Unique user IDs for all ePHI access | Access Control | Yes — check for nullable user_id in access log |
| Session timeout (≤ 15 min inactivity) | Access Control | Yes — check session config |
| ePHI encrypted at rest (AES-256) | Encryption | Partial — DB encryption is infrastructure-level |
| ePHI encrypted in transit (TLS 1.2+) | Transmission | Partial — verify TLS config at infra level |
| PHI absent from application logs | Audit | Yes — grep logs for PHI field names |
| Audit log captures all ePHI access | Audit | Yes — check audit log schema and call sites |
| Audit logs retained 6+ years | Audit | Manual — verify retention policy |
| Soft deletes on PHI tables | Integrity | Yes — check for deleted_at pattern |
| Passwords hashed with bcrypt/Argon2 | Authentication | Yes — grep for hash function |
| MFA enforced for remote access | Authentication | Manual — verify IdP configuration |
| Minimum necessary API design | Access Control | Yes — check that APIs return only needed PHI fields |

---

## Minimum Necessary Principle

APIs that return ePHI must return only the fields necessary for the specific use case:

```typescript
// BAD: returns full patient record to a scheduler who only needs name + appointment time
GET /patients/:id → { id, name, dob, ssn, diagnoses, medications, ... }

// GOOD: role-scoped response
GET /patients/:id → { id, name } // for scheduler role
GET /patients/:id → { id, name, dob, diagnoses, medications } // for clinician role
// Implement using field-level RBAC or separate endpoints per role
```

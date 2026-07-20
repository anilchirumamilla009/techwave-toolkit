# SOC 2 Technical Reference

Source: AICPA Trust Services Criteria 2017 (with 2022 points of focus)

Scope: Code-level controls for Trust Services Criteria CC6 (Logical and Physical Access), CC7 (System Operations), and CC8 (Change Management). Most relevant for SaaS companies seeking SOC 2 Type II certification.

---

## CC6 — Logical and Physical Access Controls

### CC6.1 — Logical Access Security Software

**Implement access control that enforces least privilege:**

```typescript
// Pattern: Role-Based Access Control (RBAC)
enum Role {
  VIEWER = 'viewer',
  EDITOR = 'editor',
  ADMIN = 'admin',
  SUPER_ADMIN = 'super_admin'
}

const permissions: Record<Role, string[]> = {
  [Role.VIEWER]: ['resource:read'],
  [Role.EDITOR]: ['resource:read', 'resource:write'],
  [Role.ADMIN]: ['resource:read', 'resource:write', 'resource:delete', 'user:manage'],
  [Role.SUPER_ADMIN]: ['*']
}

const hasPermission = (userRole: Role, action: string): boolean => {
  const userPerms = permissions[userRole]
  return userPerms.includes('*') || userPerms.includes(action)
}

// Middleware: enforce on every route
const requirePermission = (action: string) => (req, res, next) => {
  if (!hasPermission(req.user.role, action)) {
    return res.status(403).json({ error: 'Insufficient permissions' })
  }
  next()
}
```

**Privileged access management:**
- Admin actions must be logged with full context
- Admin accounts require MFA
- Temporary elevated access should have an expiration

```sql
-- Track all privileged operations
CREATE TABLE admin_audit_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_user_id UUID NOT NULL,
  action VARCHAR(255) NOT NULL,
  target_resource_type VARCHAR(100),
  target_resource_id UUID,
  before_state JSONB,
  after_state JSONB,
  justification TEXT,
  ip_address INET,
  timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### CC6.2 — Prior to Issuing System Credentials

Authentication implementation requirements:

```typescript
// Password policy enforcement
const validatePassword = (password: string): { valid: boolean; errors: string[] } => {
  const errors: string[] = []
  if (password.length < 12) errors.push('Minimum 12 characters')
  if (!/[A-Z]/.test(password)) errors.push('At least one uppercase letter')
  if (!/[a-z]/.test(password)) errors.push('At least one lowercase letter')
  if (!/[0-9]/.test(password)) errors.push('At least one number')
  if (!/[^A-Za-z0-9]/.test(password)) errors.push('At least one special character')
  return { valid: errors.length === 0, errors }
}

// Token management: short-lived access tokens, long-lived refresh tokens
const ACCESS_TOKEN_EXPIRY = '15m'
const REFRESH_TOKEN_EXPIRY = '7d'
```

### CC6.3 — Access Revocation

Access must be revoked promptly when no longer authorized (employee offboarding, role change):

```typescript
// Immediate session invalidation on access revocation
const revokeUserAccess = async (userId: string, reason: string) => {
  await db.transaction(async (trx) => {
    // 1. Invalidate all active sessions
    await trx('sessions').where({ user_id: userId }).update({
      revoked_at: new Date(),
      revocation_reason: reason
    })

    // 2. Revoke all API keys
    await trx('api_keys').where({ user_id: userId, revoked: false }).update({
      revoked: true,
      revoked_at: new Date(),
      revocation_reason: reason
    })

    // 3. Log the revocation event
    await trx('admin_audit_log').insert({
      action: 'ACCESS_REVOKED',
      target_resource_type: 'User',
      target_resource_id: userId,
      justification: reason
    })
  })
}
```

---

## CC7 — System Operations

### CC7.2 — Monitoring of System Components

**Required monitoring implementation:**

```typescript
// Structured logging for operational visibility
interface OperationalLog {
  level: 'debug' | 'info' | 'warn' | 'error' | 'critical'
  service: string
  operation: string
  durationMs?: number
  userId?: string
  requestId: string
  timestamp: string
  error?: { message: string; code: string; stack?: string }
}

// Log all unhandled errors with context
process.on('unhandledRejection', (reason) => {
  logger.critical({ reason, type: 'unhandledRejection' }, 'Unhandled promise rejection')
  // Alert on-call — this should never happen in production
})
```

**Availability monitoring checklist:**
- Health check endpoint: `GET /health` returns service status and dependency status
- Readiness check: `GET /ready` — confirms DB, cache, and queue connections are healthy
- Metrics: request rate, error rate, latency (p50, p95, p99)

```typescript
// Pattern: health check endpoint
app.get('/health', async (req, res) => {
  const checks = await Promise.allSettled([
    db.raw('SELECT 1'),           // database
    redis.ping(),                 // cache
    checkMessageQueueConnection() // queue
  ])

  const healthy = checks.every(c => c.status === 'fulfilled')
  res.status(healthy ? 200 : 503).json({
    status: healthy ? 'healthy' : 'degraded',
    checks: {
      database: checks[0].status,
      cache: checks[1].status,
      queue: checks[2].status
    },
    timestamp: new Date().toISOString()
  })
})
```

### CC7.4 — Incident Response

**Error handling and incident classification:**

```typescript
// Classify errors by severity for incident routing
class AppError extends Error {
  constructor(
    message: string,
    public readonly code: string,
    public readonly severity: 'low' | 'medium' | 'high' | 'critical',
    public readonly httpStatus: number = 500
  ) {
    super(message)
  }
}

// Critical errors trigger immediate alerts (PagerDuty / OpsGenie)
// High errors create tickets within 1 hour
// Medium/low errors are batched for next review
```

---

## CC8 — Change Management

### CC8.1 — Change Authorization and Documentation

For SOC 2, all production changes must be authorized, tested, and documented. Code controls:

```yaml
# Pattern: branch protection rules (GitHub example, document in repo settings)
# Every merge to main must:
# 1. Pass all CI checks (tests + security scan)
# 2. Have at least 1 approving review
# 3. Be merged via PR (no direct pushes)
# 4. Have a meaningful PR title and description

# Enforce via .github/CODEOWNERS and branch protection settings
```

**Secrets rotation:** Secrets must be rotatable without downtime:

```typescript
// Pattern: versioned secrets — support multiple active key versions during rotation
const getEncryptionKey = (version: string = 'current'): Buffer => {
  const key = process.env[`ENCRYPTION_KEY_${version.toUpperCase()}`]
  if (!key) throw new Error(`Encryption key version ${version} not found`)
  return Buffer.from(key, 'base64')
}

// During rotation: support both 'current' and 'previous' keys
// 1. Deploy new key as 'previous', promote old 'current' to 'previous'
// 2. Old records can still be read with 'previous' key
// 3. Re-encrypt records with 'current' key over time
// 4. Remove 'previous' key once no records reference it
```

---

## SOC 2 Code Checklist

| Criteria | Control | Code Verifiable? |
|---|---|---|
| CC6.1 | RBAC implemented with least-privilege defaults | Yes — check roles/permissions mapping |
| CC6.1 | Privileged actions logged with context | Yes — check admin_audit_log schema |
| CC6.2 | Password policy enforced (min 12 chars, complexity) | Yes — check validation |
| CC6.2 | Passwords hashed with bcrypt/Argon2 (not MD5/SHA1) | Yes — grep hash functions |
| CC6.2 | Short-lived access tokens (≤ 1 hour) | Yes — check JWT expiry config |
| CC6.3 | User access revocable with immediate session invalidation | Yes — check revocation flow |
| CC6.3 | API keys revocable | Yes — check API key revocation |
| CC7.2 | Health/readiness endpoints exist | Yes — grep for /health routes |
| CC7.2 | Structured logging with request IDs | Yes — check log format |
| CC7.2 | Unhandled errors logged and alerted | Yes — check error handlers |
| CC7.4 | Errors classified by severity | Yes — check error classification |
| CC8.1 | Secrets externalized (not in code) | Yes — grep for hardcoded secrets |
| CC8.1 | Secrets rotatable without downtime | Yes — check key versioning pattern |

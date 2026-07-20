# Diagram Formats Reference

All diagrams use Mermaid syntax. Mermaid renders natively in GitHub, GitLab, Notion, Obsidian, and most documentation tools.

---

## C4 Context Diagram (System-level, external actors)

Shows: the system, its users, and external systems it depends on. Use this for executive/stakeholder communication.

```mermaid
C4Context
  title System Context: [System Name]

  Person(user, "End User", "Uses the system via web browser")
  Person(admin, "Admin", "Manages configuration")

  System(system, "[System Name]", "The system being designed")

  System_Ext(emailService, "Email Service", "Sends transactional emails (SendGrid)")
  System_Ext(paymentGateway, "Payment Gateway", "Processes payments (Stripe)")
  System_Ext(identityProvider, "Identity Provider", "SSO authentication (Okta)")

  Rel(user, system, "Uses", "HTTPS")
  Rel(admin, system, "Configures", "HTTPS")
  Rel(system, emailService, "Sends emails via", "SMTP/API")
  Rel(system, paymentGateway, "Processes payments via", "HTTPS/REST")
  Rel(system, identityProvider, "Authenticates users via", "SAML 2.0")
```

---

## C4 Container Diagram (Service-level, deployment units)

Shows: the services/containers that make up the system. Use for engineering team communication.

```mermaid
C4Container
  title Container Diagram: [System Name]

  Person(user, "User", "Web browser")

  Container_Boundary(system, "[System Name]") {
    Container(webApp, "Web Application", "React + TypeScript", "Single-page app served from CDN")
    Container(apiGateway, "API Gateway", "Kong / AWS API GW", "Routes and authenticates requests")
    Container(userService, "User Service", "Node.js + Express", "Manages user accounts and authentication")
    Container(orderService, "Order Service", "Python + FastAPI", "Processes and tracks orders")
    ContainerDb(userDb, "User DB", "PostgreSQL", "Stores user accounts and sessions")
    ContainerDb(orderDb, "Order DB", "PostgreSQL", "Stores order data")
    Container(messageQueue, "Message Queue", "RabbitMQ", "Async event bus between services")
    Container(cache, "Cache", "Redis", "Session store and query cache")
  }

  System_Ext(stripe, "Stripe", "Payment processing")
  System_Ext(sendgrid, "SendGrid", "Email delivery")

  Rel(user, webApp, "Uses", "HTTPS")
  Rel(webApp, apiGateway, "API calls", "HTTPS/REST")
  Rel(apiGateway, userService, "Routes to", "HTTP")
  Rel(apiGateway, orderService, "Routes to", "HTTP")
  Rel(userService, userDb, "Reads/writes", "PostgreSQL")
  Rel(userService, cache, "Sessions", "Redis")
  Rel(orderService, orderDb, "Reads/writes", "PostgreSQL")
  Rel(orderService, messageQueue, "Publishes events", "AMQP")
  Rel(orderService, stripe, "Payment API", "HTTPS")
  Rel(userService, sendgrid, "Sends emails", "HTTPS")
```

---

## Sequence Diagram (Request flow, API interactions)

```mermaid
sequenceDiagram
  actor User
  participant Browser
  participant API as API Gateway
  participant Auth as Auth Service
  participant DB as Database

  User->>Browser: Enter credentials and click Login
  Browser->>API: POST /auth/login {email, password}
  API->>Auth: Validate credentials
  Auth->>DB: SELECT user WHERE email = ?
  DB-->>Auth: User record
  Auth->>Auth: bcrypt.compare(password, hash)
  alt Valid credentials
    Auth-->>API: {userId, token}
    API-->>Browser: 200 OK {accessToken, refreshToken}
    Browser->>Browser: Store token in memory (not localStorage)
    Browser-->>User: Redirect to dashboard
  else Invalid credentials
    Auth-->>API: AuthError
    API-->>Browser: 401 Unauthorized
    Browser-->>User: "Incorrect email or password"
  end
```

---

## ER Diagram (Data model)

```mermaid
erDiagram
  USER {
    uuid id PK
    string email UK
    string password_hash
    string first_name
    string last_name
    timestamp created_at
    timestamp updated_at
  }

  ORDER {
    uuid id PK
    uuid user_id FK
    string status
    decimal total_amount
    string currency
    timestamp placed_at
    timestamp fulfilled_at
  }

  ORDER_ITEM {
    uuid id PK
    uuid order_id FK
    uuid product_id FK
    int quantity
    decimal unit_price
  }

  PRODUCT {
    uuid id PK
    string name
    string sku UK
    decimal price
    int stock_quantity
  }

  USER ||--o{ ORDER : "places"
  ORDER ||--|{ ORDER_ITEM : "contains"
  PRODUCT ||--o{ ORDER_ITEM : "appears in"
```

---

## Flowchart (Decision flows, processes)

```mermaid
flowchart TD
  A([User submits order]) --> B{User authenticated?}
  B -- No --> C[Return 401]
  B -- Yes --> D{Items in stock?}
  D -- No --> E[Return 422 Out of Stock]
  D -- Yes --> F[Reserve inventory]
  F --> G{Payment provider available?}
  G -- No --> H[Release reservation\nReturn 503]
  G -- Yes --> I[Process payment]
  I --> J{Payment successful?}
  J -- No --> K[Release reservation\nReturn 402]
  J -- Yes --> L[Create order record]
  L --> M[Publish OrderPlaced event]
  M --> N([Return 201 Order Created])
```

---

## Class Diagram (Domain model, OOP design)

```mermaid
classDiagram
  class UserService {
    +createUser(dto: CreateUserDTO) User
    +findById(id: string) User
    +updateUser(id: string, dto: UpdateUserDTO) User
    +deleteUser(id: string) void
    -validateEmail(email: string) boolean
    -hashPassword(password: string) string
  }

  class User {
    +id: string
    +email: string
    -passwordHash: string
    +firstName: string
    +lastName: string
    +createdAt: Date
    +verifyPassword(password: string) boolean
    +toPublicProfile() PublicUser
  }

  class UserRepository {
    <<interface>>
    +save(user: User) User
    +findById(id: string) User
    +findByEmail(email: string) User
    +delete(id: string) void
  }

  class PostgresUserRepository {
    -db: DatabaseConnection
    +save(user: User) User
    +findById(id: string) User
    +findByEmail(email: string) User
    +delete(id: string) void
  }

  UserService --> UserRepository : depends on
  PostgresUserRepository ..|> UserRepository : implements
  UserService ..> User : creates/returns
```

---

## State Diagram (Lifecycle, status transitions)

```mermaid
stateDiagram-v2
  [*] --> Pending: Order placed

  Pending --> Processing: Payment confirmed
  Pending --> Cancelled: User cancels\nor payment fails

  Processing --> Shipped: Fulfillment picks items
  Processing --> Cancelled: Item out of stock

  Shipped --> Delivered: Carrier confirms delivery
  Shipped --> ReturnRequested: User initiates return

  ReturnRequested --> Returned: Return received
  Returned --> Refunded: Refund processed

  Delivered --> [*]
  Cancelled --> [*]
  Refunded --> [*]
```

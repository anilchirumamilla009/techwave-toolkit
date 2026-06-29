# BDD Patterns Reference

Idiomatic Given/When/Then patterns organized by domain. Use these as starting points — adapt to the specific feature.

---

## Authentication & Authorization

```gherkin
# Successful login
Given the user has a registered account with email "user@example.com"
When the user submits valid credentials
Then the user is redirected to the dashboard
And an authenticated session is created

# Failed login
Given an unregistered email address
When the user attempts to log in
Then the login form shows "Incorrect email or password"
And no session is created

# Account lockout
Given the user has failed to log in 4 times
When the user fails a fifth login attempt
Then the account is locked for 30 minutes
And an email notification is sent to the registered address

# Authorization — access denied
Given the user has a "viewer" role
When the user attempts to delete a resource
Then a 403 Forbidden response is returned
And the resource remains unchanged

# Session expiry
Given the user has been inactive for 30 minutes
When the user navigates to any authenticated page
Then the user is redirected to the login page
And a message says "Your session has expired"
```

---

## CRUD Operations

```gherkin
# Create (happy path)
Given the user is authenticated as an admin
When the user submits a valid creation form
Then a new record is created with the provided data
And the user sees a success confirmation

# Create (validation error)
Given a required field is left blank
When the user submits the form
Then the form is not submitted
And an inline error message identifies the missing field

# Read (found)
Given a resource with ID "abc-123" exists
When the user requests GET /resources/abc-123
Then a 200 response is returned with the resource data

# Read (not found)
Given no resource with ID "xyz-999" exists
When the user requests GET /resources/xyz-999
Then a 404 response is returned
And the response body contains an error code

# Update (optimistic lock conflict)
Given two users opened the same record simultaneously
When both users save changes
Then the second save returns a 409 Conflict response
And the first user's changes are preserved

# Delete (soft delete)
Given the user has permission to delete
When the user confirms deletion
Then the record is marked as deleted (not removed from the database)
And the record no longer appears in list views

# Delete (cascade)
Given a parent record has 3 child records
When the parent is deleted
Then all 3 child records are also deleted
And a confirmation lists the cascade count before proceeding
```

---

## Search & Filtering

```gherkin
# Empty query
Given the search field is empty
When the user submits a search
Then all records are returned (unpaginated or paginated by default)

# Partial match
Given records with names "Alpha", "Alpha Beta", "Gamma"
When the user searches for "Alpha"
Then results show "Alpha" and "Alpha Beta"
And "Gamma" is not shown

# No results
Given no records match "zzz_nonexistent"
When the user searches for "zzz_nonexistent"
Then an empty state message is shown
And no error is thrown

# Filter combination
Given a list with items in categories "A" and "B"
When the user filters by category "A" and date range "this month"
Then only category "A" items created this month are shown
```

---

## Forms & Validation

```gherkin
# Required field
Given a form with a required "email" field
When the user submits with the email field blank
Then the form shows "Email is required" near the field
And the form is not submitted to the server

# Format validation
Given the email field contains "not-an-email"
When the user submits the form
Then the form shows "Please enter a valid email address"

# Max length
Given a text field with a 255-character limit
When the user pastes text exceeding 255 characters
Then the input is truncated at 255 characters
And a character counter shows the limit

# Duplicate detection
Given a username "johndoe" already exists
When a new user registers with username "johndoe"
Then a 422 response is returned with error "Username is already taken"
And the existing account is not affected
```

---

## File Upload

```gherkin
# Valid upload
Given an allowed file type (PDF, max 10MB)
When the user selects and uploads the file
Then the file is stored and a download link is available
And the file appears in the user's document list

# Invalid file type
Given the user selects a .exe file
When the user attempts to upload
Then the upload is rejected with "File type not supported"
And no file is stored on the server

# File size exceeded
Given the user selects a 25MB PDF (limit is 10MB)
When the user attempts to upload
Then the upload is rejected with "File exceeds the 10MB limit"
```

---

## Notifications & Messaging

```gherkin
# Email notification sent
Given an event that triggers a notification (e.g., order placed)
When the event occurs
Then an email is sent to the registered address within 60 seconds
And the email contains the relevant event details

# In-app notification
Given the user receives a message while online
When the message arrives
Then an unread badge appears in the notification bell
And clicking the bell opens the notification with the message

# Notification preferences respected
Given the user has disabled email notifications
When an event that would trigger an email occurs
Then no email is sent
And an in-app notification is still created (if enabled)
```

---

## Payments

```gherkin
# Successful payment
Given a valid card with sufficient funds
When the user completes checkout
Then a payment is processed and a confirmation number is returned
And a receipt is emailed to the user

# Declined card
Given a card with insufficient funds
When the user attempts checkout
Then a 402 Payment Required response is returned
And the error message says "Your payment was declined. Please try another card."
And no order is created

# Idempotent retry
Given a payment request that timed out after submission
When the same idempotency key is reused to retry
Then only one charge is made
And the original confirmation number is returned
```

---

## API Consumers

```gherkin
# Rate limiting
Given an API client that has made 1000 requests in 60 seconds (limit: 1000/min)
When the client makes the 1001st request
Then a 429 Too Many Requests response is returned
And a "Retry-After" header indicates when to retry

# Versioning
Given an API endpoint at /v1/users
When a breaking change is introduced in /v2/users
Then /v1/users continues to work unchanged
And the deprecation header is set on /v1 responses

# Pagination
Given a collection of 500 records
When the client requests GET /items?page=1&limit=20
Then 20 records are returned
And the response includes total_count, next_page_url, and has_more fields
```

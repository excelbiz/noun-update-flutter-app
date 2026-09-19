# NOUN Update Mobile API Contract (v1)

Base URL: `https://nounupdate.com/api/v1`

All responses use JSON. Authenticated calls require `Authorization: Bearer <access-token>`. Every mutating request should accept an `Idempotency-Key` header.

## Core endpoints

| Method | Route | Purpose |
| --- | --- | --- |
| POST | `/auth/login` | Authenticate with email and password. |
| POST | `/auth/refresh` | Rotate a refresh token and return a new access token. |
| POST | `/auth/logout` | Revoke the current refresh token/device session. |
| GET | `/app/bootstrap` | Return profile, dashboard, alerts, saved count and feature flags in one low-data response. |
| GET | `/search?q=` | Unified tools, course, programme, article and document search. |
| GET | `/courses/{code}` | Course identity, resources, exam intelligence and progress. |
| GET | `/courses/{code}/study-mode` | Current learning path and resumable session. |
| POST | `/courses/{code}/study-progress` | Save unit/question/mock progress. |
| GET | `/wallet` | Balance, premium state and recent transactions. |
| POST | `/wallet/fund` | Create a server-side Paystack transaction and return an authorisation URL/reference. |
| GET | `/wallet/fund/{reference}` | Return verified transaction status. |
| GET | `/saved` | Paginated bookmarks/download metadata. |
| POST | `/saved/{resourceId}` | Save a resource. |
| DELETE | `/saved/{resourceId}` | Remove a saved resource. |
| GET | `/alerts` | Personalised academic and account alerts. |
| POST | `/devices` | Register OneSignal subscription/device metadata. |
| PATCH | `/notification-preferences` | Update programme/level/course alert choices. |

## Bootstrap response shape

```json
{
  "data": {
    "profile": {
      "id": "42",
      "name": "Success Chinedu",
      "programme": "B.Sc Accounting",
      "level": "200",
      "semester": "2026_2",
      "premium": true
    },
    "dashboard": {
      "readiness_percent": 72,
      "next_exam": {"course_code": "ACC210", "days": 14},
      "recommendation": "Study ACC214 Unit 3 for 30 minutes",
      "courses": []
    },
    "wallet": {"balance_kobo": 1245000, "currency": "NGN"},
    "unread_alerts": 3,
    "saved_count": 12,
    "feature_flags": {"community": false, "ai_tutor": true}
  }
}
```

## Error shape

```json
{
  "error": {
    "code": "PREMIUM_REQUIRED",
    "message": "Upgrade to access this resource.",
    "request_id": "req_..."
  }
}
```

Recommended status codes: `400` invalid request, `401` expired/missing token, `403` entitlement failure, `404` missing resource, `409` idempotency conflict, `422` validation error and `429` rate limit.


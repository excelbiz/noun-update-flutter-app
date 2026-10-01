# Implemented mobile API

Base: https://nounupdate.com/api/v1
Responses: `{"data": ...}` or `{"error":{"code":"...","message":"...","request_id":"..."}}`.
Bearer tokens are required except for health, services, posts, calendar, catalogue and download-ticket redemption. Download tickets are private, single use and expire after two minutes.

| Method | Path | Behaviour |
|---|---|---|
| GET | `/health` | Checks core wallet/app tables |
| GET | `/services` | Full grouped directory, enabled flags, native/web mode |
| GET | `/posts/{category}?page=1` | Published news, guides, scholarships, career or blog; 20 items/page |
| GET | `/posts/{category}/{id}` | Article text, image and original URL |
| GET | `/calendar` | Existing published academic calendar |
| GET | `/exam-summaries?q=ACC&page=1` | Exam Summary catalogue; no private storage paths |
| POST | `/auth/login` | Existing Course Summary email/password; returns access and refresh tokens |
| POST | `/auth/refresh` | Rotates refresh/access tokens |
| POST | `/auth/logout` | Revokes current session |
| GET | `/app/bootstrap` | Profile, actual balance, service directory; anonymous access supported |
| GET | `/wallet` | Shared balance in integer kobo and recent ledger entries |
| POST | `/wallet/fund` | `amount_kobo` integer; `Idempotency-Key` required; returns Paystack URL/reference |
| POST | `/wallet/fund/{reference}/verify` | Checks ownership, then verifies server-side and credits once |
| POST | `/exam-summaries/quote` | `file_ids` array; returns server-side ten-minute quote and service charge |
| POST | `/exam-summaries/purchase` | `quote_id`; `Idempotency-Key` required; atomic shared-wallet debit/order |
| GET | `/orders` | Current user's most recent 100 wallet orders |
| GET | `/orders/{id}` | Owned order with download item IDs |
| POST | `/downloads/{itemId}` | Returns a two-minute one-use download link |
| GET | `/download?ticket=...` | Redeems ticket and streams purchased file |

Tokens are never accepted in URL parameters. Request keys must contain 16–96 letters, digits, underscores or hyphens. Quote confirmation must be shown to the student before posting a purchase. Backend errors must not be replaced with demo balances, academic results or successful orders.

This document describes implemented endpoints. The older `api_contract.md` remains an earlier product blueprint; its unimplemented routes are not claimed live.

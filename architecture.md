# SeatBite Architecture Decisions

## Tenant model
Each theater is a tenant. Every tenant-owned row carries `theater_id`. Access is controlled by `theater_members` plus PostgreSQL RLS.

## Payment model
Theater customer payments must be processed using the theater's approved merchant/gateway arrangement and settle to that theater's nominated bank account. SeatBite subscription billing is separate. Do not route food proceeds through a SeatBite personal account.

## PhonePe integration gate
Before implementing live API calls, confirm with PhonePe in writing:
1. Theater merchant eligibility for PG/API access.
2. Whether a software platform may initiate transactions for multiple independent merchants.
3. Credential issuance, webhook setup, refund permissions, settlement configuration and platform/partner requirements.

Implement a provider adapter only after the approved integration flow is known. Use sandbox first. Verify webhooks server-side and query transaction status before confirming an order.

## QR security
QR tokens should be high-entropy random values. Store only a hash in `qr_codes`. Resolve the token server-side, validate that the QR is active, and never accept a client-submitted theater/seat mapping as authoritative.

## Order integrity
Prices and totals are computed on the server from active menu records. Use an idempotency key to prevent duplicate orders. Use integer paise, not floating point rupees.

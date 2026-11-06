# SeatBite Production Starter

Multi-theater QR food ordering SaaS starter (Telugu, English, Hindi).

## Current scope
- Next.js App Router + TypeScript scaffold
- Supabase SQL migration with tenant-aware tables and RLS policies
- Locale dictionary starter for `en`, `te`, `hi`
- Payment integration boundary only: no live PhonePe credentials or payment collection included

## Setup
1. Create a Supabase project.
2. In Supabase SQL Editor, run `supabase/migrations/0001_initial_schema.sql`.
3. Copy `.env.example` to `.env.local` and add your Supabase project URL and anon key.
4. Run `npm install`, then `npm run dev`.

## Security notes
- Never expose the Supabase service-role key or PhonePe secrets to browser code.
- Public customer ordering must use server-side order creation and server-verified payment status.
- The SQL policies restrict theater data by membership. Review policies with a security professional before production.
- Do not enable live payments until PhonePe confirms the merchant/platform integration arrangement for each theater.

## Planned route areas
- `/[locale]/order/[qrToken]` customer ordering
- `/[locale]/track/[orderId]` order tracking
- `/kitchen` kitchen operations
- `/owner` theater owner dashboard
- `/admin` SeatBite platform administration

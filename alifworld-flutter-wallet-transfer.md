# Alifworld Flutter — Wallet-to-wallet transfer (customer + seller apps)

Customer- and seller-app API guide for transferring money Main wallet to
Main wallet, between any two participants. Verified against the codebase
on 2026-11-20 (dev head `fd4fce5`). Base URL:
`https://dev.alifworld.com.bd/api/v1`
(prod: `https://alifworld.com.bd/api/v1`).

## 0. What it is

- **Main wallet only.** The sender's `customer_main` (customer app) or
  `seller_main` (seller app) is debited; the recipient receives into
  their Main wallet. No other wallet kind can send or receive.
- **All four directions work** — customer → customer, customer → seller,
  seller → customer, seller → seller. The sender never picks a side:
  the recipient side is derived from the recipient's profile (an
  approved seller receives into `seller_main`, everyone else into
  `customer_main`), and the sender side comes from which app sends it.
- **No fee.** The recipient receives the full amount.
- **PIN-gated, idempotent.** Every transfer needs the sender's wallet
  PIN and a fresh `Idempotency-Key` header — a retry with the same key
  returns the original transfer instead of sending twice.

## 1. Ground rules (read first)

- **Auth:** customer endpoints need the customer session, seller
  endpoints need the seller session (Bearer token from `POST
  /auth/token` — see the auth doc). A 401 means "signed out". Note:
  `requireCustomer` rejects approved sellers — a seller account cannot
  use the customer transfer endpoints (403 `WRONG_ACCOUNT_TYPE`), and
  vice versa for the seller endpoints.
- **Envelope:** every response is `{ "data": { ... } }`. Errors are
  `{ "error": { "code": "...", "message": "..." } }` with the HTTP
  status. Always read `error.code` — the message is display text, the
  code is the contract.
- **Money is minor units:** 100 minor = ৳1. Format with the currency
  symbol ৳, never the text "BDT".
- **Rate limits:** transfers are on the `write` tier (60/min per user);
  lookup is on the `read` tier. Hitting it returns 429 `RATE_LIMITED`.
  Do not retry in a loop.
- **Phone matching is spelling-aware:** the lookup and the transfer
  accept any phone spelling (`01…`, `8801…`, national digits) — the
  server tries every form and takes the oldest matching account.

## 2. The flow (build this)

1. **Find account** — the sender enters a phone number; call lookup
   (§3) and show the returned account card (name, masked phone, side,
   Main balance) so the sender verifies the recipient before sending.
   A lookup miss is 404 `RECIPIENT_NOT_FOUND` — show "no account for
   this phone number", do not proceed.
2. **Enter amount** — positive, and no more than the sender's Main
   balance. Over the balance fails at send time with 409
   `INSUFFICIENT_BALANCE` and nothing moves.
3. **Wallet PIN** — open the same PIN sheet the checkout uses
   (enter-PIN, or set-PIN if none exists — see the order-flow doc §6).
   The PIN is asked every time. Never store it, never auto-fill it,
   never log it, never put it in a URL.
4. **Send** — `POST` the transfer (§4) with a **fresh**
   `Idempotency-Key` header (new UUID per transfer attempt).
5. **Show the result** — the response carries both balances after the
   move plus the recipient card. Both sides see the transfer in their
   Transaction History (§5).

## 3. Lookup — `GET /api/v1/wallet-transfers/lookup?phone=` (customer)

Seller mirror: `GET /api/v1/seller/wallet-transfers/lookup?phone=`
(same shape, seller session).

```json
GET /api/v1/wallet-transfers/lookup?phone=01700000000
→ 200 { "data": {
  "name": "Mohan B.",
  "maskedPhone": "017*****000",
  "side": "customer",
  "toKind": "customer_main",
  "toBalanceMinor": 152500
} }
```

- `name` — first name + last initial (`"Mohan B."`), never a full
  name. `maskedPhone` is masked (first 3 digits, stars, last 3) — the
  raw phone is never returned, and the response never contains the
  recipient's user id. It is `null` when the account has no usable
  phone — show the name only then.
- `side` — `"customer" | "seller"`, the side that receives the money.
- `toKind` — the receiving Main wallet: `"customer_main"` or
  `"seller_main"`.
- `toBalanceMinor` — the recipient's current Main balance (minor
  units). Show it on the confirmation card so the sender sees the
  account is live.
- Errors: 400 `VALIDATION_ERROR` (no phone given), 404
  `RECIPIENT_NOT_FOUND` (no account for that phone).

## 4. Send — `POST /api/v1/wallet-transfers` (customer)

Seller mirror: `POST /api/v1/seller/wallet-transfers` (same body,
seller session; debits the seller's `seller_main`).

```json
POST /api/v1/wallet-transfers
Idempotency-Key: 9f1c2a3b-0000-4000-8000-000000000001
{
  "recipientPhone": "01700000000",
  "amountMinor": 50000,
  "walletPin": "123456"
}
→ 201 { "data": {
  "id": "cm...",
  "fromKind": "customer_main",
  "toKind": "customer_main",
  "amountMinor": 50000,
  "toBalanceMinor": 202500,
  "fromBalanceMinor": 48000,
  "createdAt": "2026-11-20T00:00:00.000Z",
  "recipient": {
    "name": "Mohan B.",
    "maskedPhone": "017*****000",
    "side": "customer",
    "toKind": "customer_main"
  }
} }
```

- `recipientPhone` — any spelling; the server resolves it the same
  way as lookup.
- `amountMinor` — integer, positive. Zero or negative fails with 400
  `VALIDATION_ERROR`.
- `walletPin` — required. Missing → 400 `WALLET_PIN_REQUIRED`; no PIN
  set → 400 `WALLET_PIN_NOT_SET`; wrong PIN → 401
  `WALLET_PIN_INVALID`; 5 wrong attempts → 423 `WALLET_PIN_LOCKED`
  (30 min). See the order-flow doc §2 for the whole PIN family.
- **`Idempotency-Key` header is required** — missing it fails with
  400 `VALIDATION_ERROR` before anything moves. Mint a fresh UUID per
  transfer attempt:
  - Same key + same body after a failure → the server replays the
    original transfer (safe retry, e.g. after a network drop).
  - Same key + **different body** → 422 `IDEMPOTENCY_KEY_REUSED`.
  - This matters for the PIN flow: a send attempt without a PIN fails
    with `WALLET_PIN_REQUIRED`; retrying **with `walletPin` added
    changes the body**, so you **must mint a fresh key** for the retry
    or the server answers 422.
- The transfer is one database transaction: the sender debit and the
  recipient credit either both land or neither does. A concurrent
  spend that empties the sender's wallet between the preview and the
  send fails with 409 `INSUFFICIENT_BALANCE` and no transfer row is
  created.
- The response is the transfer row: `fromBalanceMinor` /
  `toBalanceMinor` are the two Main balances **after** the move.
  `recipient` repeats the lookup card (null only if the account
  vanished mid-flight — treat as an error and show the transfer id).

## 5. History — how it shows in Transaction History

Both sides see the transfer in their wallet history feed
(`GET /api/v1/wallets/transactions` — see the transactions guide):

- Sender row: reason `wallet_transfer_out`, amount negative.
- Recipient row: reason `wallet_transfer_in`, amount positive.
- The history rows carry `referenceType: "wallet_transfer"` and the
  transfer id as the reference — do not treat the row id as the
  transfer id.
- The transfer itself is never a balance: show it as a movement row
  with the counterparty's name + masked phone, never as income/expense
  totals of their own.

## 6. Error catalog

| Code | HTTP | When | App behavior |
|---|---|---|---|
| `VALIDATION_ERROR` | 400 | Missing `Idempotency-Key` header, non-positive amount, or no phone on lookup | Show the field error; mint a key / fix the input |
| `RECIPIENT_NOT_FOUND` | 404 | No account for the phone (lookup or send) | "No account for this phone number" — do not proceed |
| `SELF_TRANSFER` | 400 | Recipient is the sender | "You can't transfer money to yourself" |
| `WALLET_PIN_REQUIRED` | 400 | Send without a PIN | Open enter-PIN sheet, retry with a **fresh** key |
| `WALLET_PIN_NOT_SET` | 400 | Sender has no PIN | Open set-PIN sheet, retry with a fresh key |
| `WALLET_PIN_INVALID` | 401 | Wrong PIN | Keep sheet open, show attempts left |
| `WALLET_PIN_LOCKED` | 423 | 5 wrong attempts | Locked state + Reset PIN (see order-flow doc §4) |
| `WALLET_PIN_INVALID_FORMAT` | 400 | PIN not 6 digits | Validate client-side first |
| `INSUFFICIENT_BALANCE` | 409 | Amount over the sender's Main balance | Show "insufficient balance"; nothing moved |
| `IDEMPOTENCY_KEY_REUSED` | 422 | Same key, different body | Mint a fresh key and retry (§4) |
| `RATE_LIMITED` | 429 | Too many writes | Back off, show "try again in a moment" |
| `WRONG_ACCOUNT_TYPE` | 403 | Seller on a customer endpoint (or customer on a seller endpoint) | Signed in on the wrong side — sign in as the right account |

## 7. Build checklist

1. Phone input + Find account → lookup card (name, masked phone,
   side, Main balance) with a Change action.
2. Amount input with inline errors (positive, ≤ sender Main balance).
   Show "No fee" — the recipient gets the full amount.
3. PIN status check on Send; PIN sheet (enter / set / locked / reset).
4. Send with `walletPin` + fresh `Idempotency-Key`; handle 201 and the
   error catalog (§6).
5. Success state shows the recipient card + both balances after the
   move; link to Transaction History.

## 8. Must-not-break

- Never send without `walletPin` — the server will 400 and nothing
  moves.
- A PIN retry after a failure needs a **fresh** `Idempotency-Key`
  (the body changed) — reusing the key gives 422.
- The PIN is asked **every** time money moves. Never store it, never
  auto-fill it, never log it, never put it in a URL.
- Never expose the recipient's raw phone or user id — show only
  `name` + `maskedPhone` from the lookup response.
- Never let the sender pick the recipient side — it is derived from
  the recipient's profile. An approved seller receives into
  `seller_main`; everyone else into `customer_main`.
- Never send `walletKinds` or any wallet selection — the transfer is
  Main-wallet only, fixed per app.
- A lookup miss (404) is not a "create account" prompt — the
  recipient must already have an Alifworld account.

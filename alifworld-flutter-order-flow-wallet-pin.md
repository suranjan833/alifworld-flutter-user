# Alifworld Flutter — Order flow & wallet PIN (customer app)

Customer-app API guide for placing an order, with the wallet PIN as the
main subject. Verified against the codebase on 2026-11-13 (dev head
`2766150`). Base URL: `https://dev.alifworld.com.bd/api/v1`
(prod: `https://alifworld.com.bd/api/v1`).

## 🆕 What's new — 2026-11-19

- **Wallet payment now requires a funded wallet selection.** Sending
  `walletKinds: []`, or selecting only wallets with zero usable balance,
  now fails place with **400 `WALLET_INSUFFICIENT`** — before this, the
  order placed with zero debited and the whole total on COD. Omit
  `walletKinds` for the smart default (Main first, then Shopping when
  Main doesn't cover); never send an empty array. See §5.6, §7, §8. 🆕

## 🆕 What's new — 2026-11-19 (wallet auto-select fix)

- **Auto-select stacking fixed.** The smart default previously stopped
  at the first empty wallet: Main ৳0 + Shopping funded placed with zero
  debited (the whole order on COD). Now an empty wallet is skipped and
  stacking continues to the next wallet — a single wallet covering the
  payable portion wins, otherwise wallets stack in priority order until
  covered, the rest on COD. See §7. 🆕
- **Wallet method is offered only when some wallet has usable balance.**
  The web checkout greys out the wallet method when no wallet can pay
  anything on the order (and keeps the server `WALLET_INSUFFICIENT`
  guard as a backstop). Mirror that in the app: hide or disable the
  wallet method when the total usable is 0. 🆕

## 🆕 What's new — 2026-11-20 (online gateways removed)

- **bKash, Nagad, SSLCommerz and aamarPay are gone — checkout is COD +
  wallet only.** The gateway modules, the `GET /api/v1/payments/gateways`
  endpoint, the admin gateway config, and the webhook route are all
  deleted; the database tables `PaymentGatewayConfig` and
  `PaymentWebhookEvent` are dropped. Do not fetch gateways, do not offer
  any online method, do not open any authorization URL. See §5.3, §5.6,
  §5.7, §8. 🆕
- **`paymentMethod` is now `"cod" | "wallet"` only** (quote + place).
  Sending `bkash` / `nagad` fails validation. 🆕
- **`remainderMethod` is always `"cod"`** — the only remainder method.
  Sending anything else fails with 400 `VALIDATION_ERROR`. 🆕
- **No `returnUrl`, no `redirectUrl`.** Place no longer accepts
  `returnUrl` and never returns `redirectUrl`; `paymentFailed` is
  always `false`. Go straight to the success screen from the placed
  batch id. §5.7 is deleted. 🆕
- **Geo withdrawals are bank-only** (not in this doc — see the
  manual-payments guide if it touches the geo portal). 🆕

## 0. Ground rules (read first)

- **Auth:** customer endpoints need the customer session — Bearer token
  from `POST /auth/token` (see the auth doc). A 401 on a session endpoint
  means "signed out". Note: `requireCustomer` rejects approved sellers —
  a seller account cannot place customer orders (403 `WRONG_ACCOUNT_TYPE`).
- **Envelope:** every response is `{ "data": { ... } }`. Errors are
  `{ "error": { "code": "...", "message": "..." } }` with the HTTP status.
  Always read `error.code` — the message is display text, the code is
  the contract.
- **Money is minor units:** 100 minor = ৳1. Format with the currency
  symbol ৳, never the text "BDT".
- **Rate limits:** checkout writes are on the `write` tier — 60/min per
  user. Hitting it returns 429 `RATE_LIMITED`. Do not retry in a loop.
- **Price = MRP − discount.** Points never cut the price (see the points
  guide). Points are earned on the order, never spent by it.

## 1. The error you hit — what `WALLET_PIN_REQUIRED` means

```json
POST /api/v1/checkout/place
{"addressId": "...", "paymentMethod": "wallet",
 "walletKinds": ["customer_main", "customer_shopping"],
 "remainderMethod": "cod"}
→ 400 {"error": {"code": "WALLET_PIN_REQUIRED",
                 "message": "Enter your wallet PIN to continue."}}
```

This is **not a bug and not a server error** — it is the wallet PIN gate
working as designed. Any order that pays with wallet money must carry
the buyer's 6-digit wallet PIN in the place request (`walletPin` field).
The request above sent no `walletPin`, so the server refused before
touching the cart, the wallets, or any order row. Nothing was charged
and no order was created — retrying correctly (with the PIN, §6) is safe.

The short version: before placing a wallet order, open the PIN sheet
(§6), get the PIN, and send it as `walletPin` in the same place body.
If the buyer has never set a PIN, the sheet offers the set-PIN flow
first (§3).

## 2. The wallet PIN model

- **What it is:** a 6-digit numeric PIN, scrypt-hashed on the server like
  a password. It is never stored or logged in clear, and the API never
  returns it.
- **What it protects:** every internal wallet deduct/transfer —
  checkout wallet payment, redeem, withdraw requests, seller settlement,
  Total Sales transfers, Advanced Shopping withdrawals, lottery ticket
  purchases, seller payout requests. One PIN covers all of them.
- **First gated action → set it.** When the buyer has no PIN yet, the
  first wallet action opens a **set-PIN** sheet (enter the new PIN twice).
  After it is set, every later wallet action opens an **enter-PIN** sheet.
- **Wrong PIN:** 5 wrong attempts lock PIN entry for **30 minutes**.
  A malformed PIN (not exactly 6 digits) fails immediately **without**
  consuming an attempt — validate the format client-side before sending.
  A correct PIN resets the failure counter to 0.
- **Locked or forgotten → reset by OTP** (§4). There is no way to read
  or recover the current PIN — only to set a new one after proving
  ownership of the phone/email on file.

### 2.1 Error codes (the whole family)

| Code | HTTP | Meaning | App behavior |
|---|---|---|---|
| `WALLET_PIN_NOT_SET` | 400 | Buyer has no PIN yet | Open the **set-PIN** sheet, then retry the action with the new PIN |
| `WALLET_PIN_REQUIRED` | 400 | PIN is set but none was sent | Open the **enter-PIN** sheet, then retry with the PIN |
| `WALLET_PIN_INVALID` | 401 | Wrong PIN; message says attempts left, e.g. "Wrong wallet PIN. 3 attempt(s) left." | Keep the sheet open, show the message, let them retry |
| `WALLET_PIN_LOCKED` | 423 | 5 wrong attempts — locked 30 min | Close the enter sheet; show the lock message + a **Reset PIN** button (§4) |
| `WALLET_PIN_INVALID_FORMAT` | 400 | PIN is not exactly 6 digits | Client-side validation should prevent this; show "Enter a 6-digit PIN" |

All five codes start with `WALLET_PIN_` — treat any `error.code`
starting with that prefix as "keep the PIN sheet open and show the
message". Any other error code from the action means the action itself
failed: close the sheet and show the error on the underlying screen.

## 3. PIN status, set & change

### 3.1 `GET /api/v1/account/wallet-pin` (session)

```json
{ "set": true, "lockedUntil": null }
```

- `set` — whether the buyer has a PIN. `false` → show the set-PIN
  sheet, never the enter-PIN sheet.
- `lockedUntil` — ISO timestamp, or `null`. When set and in the future,
  PIN entry is locked: show the lock state with the unlock time and a
  Reset PIN button; do not accept PIN input.
- **Call this when the PIN sheet opens** (the web does exactly this) and
  again after a lock, so the sheet always shows the right mode. It is
  cheap and safe to call before every wallet action.

### 3.2 `POST /api/v1/account/wallet-pin` — set (first time) or change

```json
// First set (no PIN exists yet):
{ "pin": "123456" }
// Change (PIN already exists):
{ "pin": "654321", "currentPin": "123456" }
→ { "set": true }
```

- First-time set needs only `pin`. Changing an existing PIN requires
  `currentPin` — without it the server returns `WALLET_PIN_REQUIRED`.
- `pin` must be exactly 6 digits (`WALLET_PIN_INVALID_FORMAT` otherwise).
- The app's set sheet must ask for the new PIN **twice** and check they
  match client-side before sending ("PINs do not match" otherwise).
- After a successful set/change, **immediately run the pending action
  with the new PIN** — do not make the buyer type it again. (The web's
  PIN sheet does this: set → run the original action with the new PIN.)

## 4. PIN reset (forgotten / locked) — OTP flow

Two calls. No body on the first, codes + new PIN on the second.

### 4.1 `POST /api/v1/account/wallet-pin/reset-request` (session, no body)

```json
→ { "mobileSent": true, "emailSent": true }
// In dev mode only, the codes may also be returned:
// { "mobileSent": true, "emailSent": true, "devCode": "123456", "emailDevCode": "654321" }
```

- Sends a 6-digit OTP to the mobile (`wallet_pin_reset` purpose) and,
  when an email is on file, a second OTP to the email. **Both codes are
  required to reset** when both channels are on file; mobile only when
  no email is on file.
- `devCode` / `emailDevCode` appear only when the server runs in dev
  mode — never rely on them in production, and never ship them in a
  release build.
- If neither channel exists on file → 400 `NO_CONTACT`.

### 4.2 `POST /api/v1/account/wallet-pin/reset-confirm` (session)

```json
{ "mobileCode": "123456", "emailCode": "654321", "newPin": "112233" }
→ { "set": true }
```

- Each code is required exactly when its channel is on file (missing →
  400 `OTP_REQUIRED`; wrong/expired → 400 `OTP_INVALID`).
- `newPin` must be exactly 6 digits.
- On success the PIN is replaced and the lock (if any) is cleared.
  **Immediately run the pending action with the new PIN** — same as §3.2.

## 5. The full order flow

### 5.1 Step 1 — Cart

`GET /api/v1/cart` (customer session). Each line carries `productId`,
`variantId`, `qty`, `unitPriceMinor`, `lineTotalMinor`, `linePoints`,
`pointsPerUnit`, `stockQty`, `openBoxDelivery`, and the product
(`name`, `slug`, `shopName`). The cart is per user, one cart only.
Cart writes (add/update/remove) are separate endpoints; an empty cart
at place time fails with `CART_EMPTY`.

### 5.2 Step 2 — Delivery address

`GET /api/v1/account/addresses` (customer session) → `{ addresses: [{
id, label, fullName, phone, addressLine, division, district, upazila,
union, area, postalCode, isDefault }] }`. The buyer picks one (default
pre-selected). **Place requires `addressId`** — quote does not (it can
price before an address is picked). If the buyer has no address, send
them to add one first; there is no guest checkout.

### 5.3 Step 3 — Payment methods 🆕

Two methods, nothing to fetch — **do not call any gateways endpoint**
(it no longer exists):

- **`cod`** — Cash on Delivery. The default method.
- **`wallet`** — Pay from Wallet (Main + Shopping, §5.4). Offer it only
  when some wallet has usable balance (see the 2026-11-19 note above);
  the server still refuses a wallet order with no funded wallet
  (400 `WALLET_INSUFFICIENT`).

A wallet remainder is always paid with COD — there is no remainder
picker. 🆕

### 5.4 Step 4 — Wallets & caps

`GET /api/v1/wallets` (customer session) → the 10 customer wallets with
balances, plus `walletMaxPercent` and `walletCaps`
`{ customer_main, customer_shopping }` (per-wallet caps, % of the order
total — Main default 100, Shopping default 62, admin-controlled).

- **Only Main and Shopping pay at checkout.** Advanced Shopping never
  pays, even with a balance.
- The buyer may pick wallet kinds explicitly, or leave the smart default
  (Main first, then Shopping). The server re-derives the authoritative
  split from **fresh balances** at place time — the client's selection
  is a preference, not the final debit.

### 5.5 Step 5 — Quote

`POST /api/v1/checkout/quote` (customer session):

```json
{
  "addressId": "cmvzjxo2h0000pzkyumqml17m",
  "couponCode": "SAVE10",
  "sellerCoupons": { "<sellerId>": "SELLER5" },
  "paymentMethod": "wallet",
  "walletKinds": ["customer_main", "customer_shopping"]
}
```

- `paymentMethod`: `"cod" | "wallet"` 🆕 (online methods removed).
- `addressId` optional here (price shows before an address is picked);
  `couponCode` / `sellerCoupons` optional.
- `walletKinds` optional — omit for the smart default.
- Response (no `_validated` field — it is stripped server-side):

```json
{
  "lines": [ "...per cart line, with seller + price + points..." ],
  "subOrders": [
    { "sellerId": "...", "subtotalMinor": 159000, "discountMinor": 0,
      "shippingMinor": 0, "taxMinor": 0, "totalMinor": 159000,
      "items": [ "..." ] }
  ],
  "addressId": "cmvzjxo2h0000pzkyumqml17m",
  "subtotalMinor": 159000,
  "platformDiscountMinor": 0,
  "sellerDiscountMinor": 0,
  "discountMinor": 0,
  "shippingMinor": 0,
  "taxMinor": 0,
  "totalMinor": 159000,
  "couponCode": "SAVE10",
  "couponFreeShipping": false,
  "paymentMethod": "wallet",
  "taxName": null,
  "taxRatePercent": 0
}
```

- One `subOrders` entry per seller — the order splits per seller at
  place time (§5.6). Shipping and tax are 0 in practice today.
- The quote does **not** return the wallet split. Compute the preview
  client-side with the same rules the server uses (§7) from the wallets
  (§5.4) and the caps. Re-quote whenever the address, coupon, payment
  method or wallet selection changes.
- Total points for the order (the "You earn" line) is computed
  client-side from the cart lines: `Σ pointsPerUnit × qty`.

### 5.6 Step 6 — Place

`POST /api/v1/checkout/place` (customer session). Body = the quote
fields **plus** the place-only fields:

```json
{
  "addressId": "cmvzjxo2h0000pzkyumqml17m",
  "couponCode": "SAVE10",
  "paymentMethod": "wallet",
  "walletKinds": ["customer_main", "customer_shopping"],
  "remainderMethod": "cod",
  "walletPin": "123456"
}
```

- `addressId` — **required** at place time.
- `walletKinds` — 🆕 the wallets to pay from. **Omit it for the smart
  default** (Main first, then Shopping when Main doesn't cover the
  payable portion). **Never send an empty array** — `walletKinds: []`
  now fails place with 400 `WALLET_INSUFFICIENT`, as does selecting
  only wallets with zero usable balance. At least one selected wallet
  must have positive usable balance (balance > 0 and its cap > 0).
  The web picker enforces the same rule client-side (it won't let the
  buyer deselect the last funded wallet) and the server enforces it
  from fresh balances, so a balance that went empty after the preview
  still fails safely at place time instead of placing with zero debited.
- `remainderMethod` — 🆕 always `"cod"` — the only remainder method.
  Send it explicitly whenever the wallet does not cover the full
  total; anything else fails with 400 `VALIDATION_ERROR`. When the
  wallet covers everything, the remainder is 0 and the field is unused.
- `walletPin` — **required when `paymentMethod` is `"wallet"`**, even
  when the wallet covers only part of the total. Omit it for `cod`
  orders (no PIN is needed then). See §6 for how to collect it.
- **Idempotency-Key header — send one, fresh per attempt.** Pass a new
  UUID in the `Idempotency-Key` header with every place attempt. The
  server fingerprints `method + path + body` under that key:
  - Same key + same body after a failure → the server re-runs the
    handler (safe retry, e.g. after a network drop).
  - Same key + **different body** → 422 `IDEMPOTENCY_KEY_REUSED`.
  - This matters for the PIN flow: a place attempt without a PIN fails
    with `WALLET_PIN_REQUIRED`; retrying **with `walletPin` added
    changes the body**, so you **must mint a fresh key** for the retry
    or the server answers 422. (If you send no key at all, there is no
    idempotency protection — a double-tap can double-place. The cart is
    cleared on success, so the second attempt fails with `CART_EMPTY`,
    but do not rely on that: disable the button while placing **and**
    send the key.)
- **Rate limit:** 60/min per user on this endpoint (`write` tier).
- **Success → 201:**

```json
{
  "batch": {
    "id": "...",
    "batchNumber": "BATCH-...",
    "paymentStatus": "paid",
    "paymentMethod": "wallet",
    "totalMinor": 159000
  },
  "orders": [
    { "id": "...", "orderNumber": "ORD-...", "sellerId": "...", "totalMinor": 159000 }
  ],
  "paymentFailed": false
}
```

- One checkout creates one `OrderBatch` (`BATCH-…`, the payment
  container) plus **one standalone `Order` per seller** (`ORD-…`, each
  with its own lifecycle, delivery OTP and timeline). Show the order
  numbers from `orders[]`, not the batch number, on the confirmation
  screen.
- `paymentStatus`: `paid` (wallet covered), `cod_pending`
  (COD remainder or pure COD), `partially_paid` in practice.
- The cart is cleared inside the same transaction — a second place
  with the same cart fails with `CART_EMPTY`.
- `paymentFailed` is always `false` now — there is no online payment
  step that could fail to start. Go straight to the success screen
  from the placed batch id. 🆕

### 5.7 ~~Step 7 — Online payment (bKash / Nagad remainder only)~~ — REMOVED 🆕

Online gateways are gone (2026-11-20): no `redirectUrl`, no
`returnUrl`, no authorization page to open. This step no longer
exists — place returns the batch and the app goes straight to §5.8.

### 5.8 Step 8 — Success screen

`GET /api/v1/checkout/batches/[id]` (customer session):

```json
{
  "batch": {
    "id": "...",
    "batchNumber": "BATCH-...",
    "paymentMethod": "wallet",
    "paymentStatus": "paid",
    "totalMinor": 159000,
    "orders": [
      { "id": "...", "orderNumber": "ORD-...", "status": "pending",
        "totalMinor": 159000, "shopName": "Biswas Stores" }
    ]
  }
}
```

- Show: order number(s) per seller, totals, payment method, and the
  "You earn X points" line (from the placed order's points — same
  `Σ pointsPerUnit × qty` as the quote; points post after delivery, once
  the return window closes).
- If the batch fetch 404s (e.g. a stale link), go to the orders list.

### 5.9 Step 9 — Orders & tracking

- `GET /api/v1/account/orders` — order list (cursor-paged), each with
  `points: { status, points, returnWindowEndsAt }` (`pending` / `posted`
  / `null` — see the points guide).
- `GET /api/v1/account/orders/[id]` — order detail: items (with
  `pointsPerUnit`), payment bill (MRP, discount, subtotal, coupon,
  shipping, tax, total, prepaid from wallet, Paid, Due with the
  remainder method), timeline, delivery OTP while in transit, return
  actions. Statuses: `pending → confirmed → packed → handed_over →
  out_for_delivery → delivered` (plus `cancelled` / `refunded`).
- Delivered COD is paid: a delivered order whose due method is COD
  shows Paid (Cash on delivery) with Due ৳0.

## 6. The wallet PIN flow in checkout (build this)

Recommended sequence — the web does exactly this, and it means the
buyer never sees a raw 400:

```
Tap "Place order" (paymentMethod == "wallet")
  → GET /api/v1/account/wallet-pin
      → set == false  → show SET-PIN sheet (new PIN twice)
      → set == true, lockedUntil in future → show LOCKED state + Reset PIN
      → set == true   → show ENTER-PIN sheet (6-digit field)
  → buyer submits PIN
      → POST /api/v1/checkout/place { ...same body..., walletPin: pin }
         with a FRESH Idempotency-Key
      → 201 → close sheet → success screen (§5.8)
      → 4xx WALLET_PIN_* → keep sheet open, show server message (§2.1)
      → 423 WALLET_PIN_LOCKED → switch sheet to LOCKED + Reset PIN
      → any other error → close sheet, show error on checkout
  → "Forgot PIN?" in the sheet → reset flow (§4) → on success, place
     the order with the new PIN immediately (no re-typing)
```

Rules that matter:

1. **Check status before placing.** Do not call place without a PIN and
   rely on the 400 — the pre-check is what keeps the experience clean.
   (The 400 is still the safety net: if place returns
   `WALLET_PIN_REQUIRED` or `WALLET_PIN_NOT_SET` anyway — e.g. the PIN
   was changed on another device — open the sheet and retry.)
2. **Fresh idempotency key on the PIN retry.** Adding `walletPin` changes
   the request body, so the retry needs a new key (§5.6) or the server
   answers 422 `IDEMPOTENCY_KEY_REUSED`.
3. **Keep the sheet open on PIN errors.** Only `WALLET_PIN_*` codes keep
   it open. A wrong PIN shows the attempts-left message from the server
   — do not invent your own count.
4. **After set / reset, run the order immediately** with the new PIN.
   The buyer must not have to type the PIN they just created.
5. **The PIN is per action, not per session.** A PIN entered for one
   order does not authorize the next order — ask again every time wallet
   money moves. Never cache, store or auto-fill the PIN.
6. **Never put the PIN in a URL, a log, or analytics.** It travels only
   in the JSON body of the place request (HTTPS), exactly once per
   attempt. Clear the field from memory as soon as the request is sent.

## 7. The wallet split (what the preview shows)

Only Main + Shopping pay, with per-wallet caps from `GET /api/v1/wallets`
(`walletCaps`, % of the **order total** — Main default 100, Shopping
default 62). The split, in order:

- Ordered kinds = the buyer's explicit `walletKinds`, or the default
  priority `[customer_main, customer_shopping]`.
- Payable portion = `min(total, Σ cap amounts)`, where a kind's cap
  amount is `pct% of the order total` — the cap is a % of the order
  total, **not** of the wallet balance.
- Take from each kind in order: `min(balance, cap amount, remaining
  portion)`. Skip a kind when its take is 0.
- 🆕 **An empty wallet is skipped, never a stop.** Main ৳0 + Shopping
  ৳930 on a ৳2,299 order uses Shopping ৳930 and leaves ৳1,369 on COD —
  the stack no longer halts at the first empty wallet.
- Smart default: when one wallet's cap **and** balance cover the whole
  payable portion, use that wallet alone (Main at 100% covers a whole
  order by itself).
- The rest is the remainder, paid by `remainderMethod` (COD default).
- 🆕 **A wallet order must debit at least one wallet.** If the
  selection is empty, or every selected wallet is empty, place fails
  with 400 `WALLET_INSUFFICIENT` and no order is created — the order
  never places with zero debited and the whole total on COD.
- **The server re-derives this from fresh balances at place time.** A
  concurrent spend can shrink a debit; the preview is a preview. Show
  the final split from the placed batch (wallet payment rows) on the
  success screen, not the preview numbers.

## 8. Error catalog — place & quote

| Code | HTTP | When | App behavior |
|---|---|---|---|
| `WALLET_PIN_REQUIRED` | 400 | Wallet order, no PIN sent | §6 — open enter-PIN sheet, retry with fresh key |
| `WALLET_PIN_NOT_SET` | 400 | Wallet order, buyer has no PIN | §6 — open set-PIN sheet, retry with fresh key |
| `WALLET_PIN_INVALID` | 401 | Wrong PIN | Keep sheet open, show attempts left |
| `WALLET_PIN_LOCKED` | 423 | 5 wrong attempts | Locked state + Reset PIN (§4) |
| `WALLET_PIN_INVALID_FORMAT` | 400 | PIN not 6 digits | Validate client-side first |
| `WALLET_INSUFFICIENT` | 400 | 🆕 Wallet order, no selected wallet has usable balance (empty `walletKinds`, or all selected wallets empty) | Show "select a wallet with balance" on the wallet picker; do not retry the same body — change the selection or the payment method |
| `CART_EMPTY` | 400 | Cart empty at place time (incl. double-submit) | Show "cart is empty", go to cart |
| `VALIDATION_ERROR` | 400 | 🆕 `paymentMethod` is not `cod`/`wallet`, or `remainderMethod` is not `cod` (online methods removed 2026-11-20) | Send only `cod` / `wallet`; remainder always `cod` |
| `VARIANT_NOT_AVAILABLE` | 400 | A variant went out of stock / inactive | Re-quote; remove or replace the line |
| `IDEMPOTENCY_KEY_REUSED` | 422 | Same key, different body | Mint a fresh key and retry (§5.6) |
| `RATE_LIMITED` | 429 | Too many writes (60/min) | Back off, show "try again in a moment" |
| `WRONG_ACCOUNT_TYPE` | 403 | Seller account on a customer endpoint | Signed in as a seller — sign in as a customer |
| `OTP_REQUIRED` / `OTP_INVALID` | 400 | PIN reset codes missing / wrong | §4 — re-enter codes, or request new ones |

## 9. The same PIN sheet everywhere else

Reuse the §6 sheet (status check → enter / set / locked / reset) for
every wallet deduct, with only the `run` action changing:

| Action | Endpoint | PIN field |
|---|---|---|
| Checkout wallet payment | `POST /api/v1/checkout/place` | `walletPin` in body |
| Redeem bonus wallets | `POST /api/v1/wallets/redeem` | `walletPin` in body |
| Withdraw request | `POST /api/v1/wallets/withdraw` (see wallets doc) | `walletPin` in body |
| Lottery ticket buy | `POST /api/v1/lotteries/[id]/tickets` | `walletPin` in body |
| Advanced Shopping withdraw | (see wallets doc) | `walletPin` in body |

One sheet, one status check, one reset flow — do not build a second PIN
UI per feature. The seller app has its own PIN-gated actions (Total
Sales transfer, seller payouts, settlement) on the same
`GET /api/v1/account/wallet-pin` status endpoint, since the PIN belongs
to the signed-in user, not to a role.

## 10. Build checklist

1. Payment methods (COD / wallet) + addresses + wallets on the checkout screen (§5.2–5.4). 🆕
2. Quote on every change; show the wallet preview split + "You earn"
   points (§5.5, §7).
3. PIN status check on "Place order" (wallet method only) (§3.1, §6).
4. PIN sheet: enter / set / locked / reset-confirm modes (§2–§4, §6).
5. Place with `walletPin` + fresh `Idempotency-Key`; handle 201 (§5.6).
6. Success screen from the stored batch id (§5.8).
7. Orders list + detail (§5.9).
8. Reuse the sheet for redeem / withdraw / lottery (§9).

## 11. Must-not-break

- Never send a wallet place request without `walletPin` when
  `paymentMethod` is `"wallet"` — the server will 400 and nothing is
  ordered.
- A PIN retry after a failure needs a **fresh** `Idempotency-Key`
  (the body changed) — reusing the key gives 422.
- The PIN is asked **every** time wallet money moves. Never store it,
  never auto-fill it, never log it, never put it in a URL.
- The wallet split preview is computed from fresh balances server-side
  at place time — never treat the preview as the final debit.
- `remainderMethod` is always `"cod"` — never `"wallet"`, never an
  online method. 🆕
- A 400 `WALLET_PIN_*` means "show the sheet", not "show a generic
  error page" — the order is not placed yet and the cart is untouched.
- COD orders without wallet money need **no** PIN —
  do not open the sheet for them. 🆕

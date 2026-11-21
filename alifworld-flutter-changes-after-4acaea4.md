# Alifworld Flutter — Changes after the referral preview (4acaea4)

What the backend changed **after** commit `4acaea4` (referrer preview on the
registration step, 2026-11-21) up to dev head `1330bdf`. Only changes that
affect the Flutter app are in this file — admin-panel and web-storefront-only
changes since then need no app work. Nothing older than `4acaea4` is in here;
the app already has all of that.

Base URL: `https://dev.alifworld.com.bd/api/v1`
(prod: `https://alifworld.com.bd/api/v1`). Both changes below are on dev,
not deployed yet — they land with the next deploy.

---

## 1. Seller-hidden products now actually hide (2026-11-21, dev `3c23d8f`)

### What changed

- A seller can hide a whole product (all its variants) or one variant only.
- **Hidden products vanish from every listing** — shop, search, category,
  brand and seller-shop. Hidden variants vanish from those listings and
  from the PDP variant picker: `variants[]` contains active variants only.
  If a product has no active variants left, there is no picker and no buy
  box — details only.
- **The detail page still loads from a direct link.**
  `GET /api/v1/catalog/products/[slug]` returns a hidden product with
  `200` and `isVisible: false` instead of 404 — a past buyer can still see
  what they bought. It still 404s non-live products and debt-hidden
  sellers. Reviews and share links work the same way.
- **Hidden means not purchasable.** Cart add/set, wishlist add and
  checkout (quote/place) all refuse a hidden product with
  `400 PRODUCT_NOT_AVAILABLE` ("This product is not available right
  now.").
- **A hidden line disappears from the cart and wishlist views.**
  `GET /api/v1/cart` and `GET /api/v1/wishlist` no longer return a line
  for a product the seller hid after it was added. The row stays saved
  server-side, so it comes back if the seller shows the product again.
  Hiding one variant removes only that variant's entry — the product's
  other variants stay in the cart/wishlist.

### To do now

- [ ] **PDP: drive off `isVisible`, never treat `isVisible: false` as a
      404.** Show gallery, price, points badge, breakdown, variant
      details and reviews as normal. The variant picker stays usable for
      browsing (switching variants updates gallery/price/details), but
      the quantity stepper and Add to cart are disabled with a
      "not available right now" note. Never call `POST /api/v1/cart`
      for it.
- [ ] **Hide the wishlist heart on a hidden product's page.** Do not
      offer to wishlist it — the server returns the same 400 on
      `POST /api/v1/wishlist`.
- [ ] **Handle `400 PRODUCT_NOT_AVAILABLE`** on cart add/set, wishlist
      add and quote/place: show "not available right now" inline. Do
      not re-add the line, do not retry.
- [ ] **Cart / wishlist: a line can disappear between loads.**
      If a line the app showed before is gone from `GET /api/v1/cart`
      or `GET /api/v1/wishlist`, that is the seller hiding it — not a
      sync error and not a reason to re-add it. Render what the server
      returns; if you cache listings, refresh them, so a hidden product
      does not linger from a stale cache.
- [ ] **Variant picker: no client filtering needed.** `variants[]`
      already contains active variants only.

---

## 2. Withdrawals: amount held at submit, refunded on reject (2026-11-21, dev `1330bdf`)

### What changed

- **Submit deducts immediately.** The full `amountMinor` leaves the
  user's Main wallet in the same request that creates the withdrawal —
  it is held while the request is `pending`, so the user cannot spend it
  meanwhile. The fee leg (flat + %, default 0, never shown when 0) goes
  to the platform wallet at the same time.
- **A short balance fails at submit.** `INSUFFICIENT_BALANCE` on
  withdrawal submit is now **`409`** (was `400`). No request is created.
- **Approval moves no money and can never fail for balance.** The admin
  only sends the payment and marks it paid (admin-side, no app call).
- **Rejection refunds in full, at once.** The amount goes back to Main
  and the fee is reversed. The withdrawal becomes `rejected` with a
  `rejectReason`.
- **Transaction History rows changed for withdrawals.** A pending
  withdrawal is now a **real debit row** (Shape A): the ledger debit,
  enriched with the `manual` block (`status: "pending"`), with a real
  `balanceAfterMinor` — not a request-only row. A rejected withdrawal
  shows as that debit row (status `rejected`) **plus a separate refund
  credit row** (`reason: "manual_withdraw_refund"`, also enriched with
  the `manual` block, status `rejected`). Shape B (request-only row,
  `balanceAfterMinor: null`) now covers pending/rejected **deposits**
  only, plus legacy withdrawals submitted before this change.
- Same rules apply to **seller withdrawals** — if the seller app has a
  withdraw flow, it behaves identically.

### To do now

- [ ] **Refresh the Main balance immediately after a `201` withdrawal
      submit.** It has already dropped by the full amount — do not wait
      for approval.
- [ ] **Update the error mapping:** `INSUFFICIENT_BALANCE` on
      withdrawal submit is now `409`, not `400`. If the app keys on the
      error code only, no change is needed; if it keys on the HTTP
      status, update it.
- [ ] **Withdraw sheet: tell the user in plain words** that the amount
      leaves Main as soon as they submit, and is refunded in full if the
      admin rejects. (The web sheet does this.)
- [ ] **History: render a pending withdrawal as a normal debit row**
      with a Pending chip and a real balance-after. Do **not** exclude
      it from totals, do **not** render balance-after as "—".
- [ ] **History: a rejected withdrawal is two rows** — the debit plus
      the refund credit (`reason: "manual_withdraw_refund"`). Both are
      real movements and both count in totals.
- [ ] **When a withdrawal's status becomes `rejected`** (list refresh),
      refresh the balance too — the refund has landed.
- [ ] **Seller app:** apply the same rules to the seller withdraw flow.

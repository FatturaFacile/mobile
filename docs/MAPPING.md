# Mobile ↔ web-api ↔ web-frontend Mapping Report

Source of truth: `web-api/routes/api.php` (≈468 route declarations, prefix `/api/v1`), `web-api/config/mobile.php`,
`web-frontend/src/app/features` (91 feature folders), `web-frontend/src/styles/_generated-tokens.scss`.

## 1. Transport contract

| Concern | Contract |
| :--- | :--- |
| Auth | OAuth2 code + PKCE S256: `POST /mobile/auth/pkce/authorize` (email, password, code_challenge) → `POST /mobile/auth/pkce/token` → Sanctum Bearer. 2FA: `POST /auth/two-factor-challenge`. |
| Device | `POST /mobile/devices` (register), `PUT /mobile/devices/current/{push-token,biometric}`, `POST /mobile/devices/current/wipe-ack`, manifest GET/PUT, `DELETE /mobile/devices/{id}` |
| Tenant | `X-Tenant-Id: <uuid>` header (middleware group `auth:sanctum, mobile.device, tenant, locale`) |
| Locale | `X-Language-Code` and `Accept-Language` (`it`, `en`, `de`, `fr`) |
| Idempotency | `Idempotency-Key` header on writes (platform `EnforceIdempotency`) — the outbox uses the queue row UUID |
| Envelope | `{success, message, data, meta}`; errors are problem+json / `ApiErrorResponse` / `ApiValidationErrorResponse` (422) |
| Hydration | `GET /mobile/bootstrap` (profile, workspaces, badges, sync plan) |
| Delta sync | `GET /mobile/sync` (allowed entities, `page_size`) · `GET /mobile/sync/{entity}?updated_since&cursor&limit` → `{data, deleted[], next_cursor, server_time, has_more}` |
| i18n | `GET /translations/{locale}` (public, merged global + tenant) → `{locale, translations{key:value}}`; lookups `GET /lookups/{category_code}` |
| Health | `GET /health/ready` |

## 2. Offline-syncable entities (server whitelist, `config/mobile.php`)

| Entity | Scope | SQLite table |
| :--- | :--- | :--- |
| products | public | `products` |
| warehouses | public | `warehouses` |
| contacts | policy `viewAny` | `contacts` |
| work_orders | policy | `work_orders` |
| appointments | policy | `appointments` |
| expenses | own (`user_id`) | `expenses` |
| time_entries | own | `time_entries` |
| work_sites | public | `work_sites` |
| employee_shifts | own | `employee_shifts` |
| payslip_documents | own | `payslip_documents` |

Every table carries: `id`, `tenant_id`, `payload` (JSON), `sync_status`, `local_updated_at`, `server_updated_at`,
`created_at`, `updated_at`, `deleted_at`, `created_by`, `updated_by`. Infrastructure tables: `sync_queue`, `sync_cursors`,
`translations`, `kv_settings`.

## 3. Mobile-specific REST endpoints (`/mobile/*`)

approvals inbox/decision · work-sites CRUD · shifts index/store/destroy · payslips index/download/read-receipt ·
receipts/parse (OCR) · devices admin.

## 4. Module coverage plan (web-frontend feature → mobile feature)

Phase 1 (contract exists, in progress): auth, tenant switcher, bootstrap, sync engine, i18n, **wms**, contacts/CRM,
products/catalog, work orders / field-service, appointments, expenses, HR time-attendance & shifts, payslips, approvals.

Phase 2 (REST modules without a mobile delta feed — need paged online reads + outbox writes): sales (quotes, orders,
DDT), invoicing (+ SDI status, Swiss QR-bill, PDF), purchases/procurement, accounting/VAT, treasury, inventory/stock,
dashboard KPIs, reports/analytics, settings/RBAC.

Phase 3 (vertical modules, ~60 folders: manufacturing, logistics, fleet, hospitality, childcare, …): added
on demand, one feature folder each, same layering.

## 5. Theme tokens

Already generated into `lib/design/ff_tokens.dart` from `web-frontend` (`FfColors` ThemeExtension, light + dark).
Never hand-edit; resync with `pnpm tokens:sync` in web-frontend.

## 6. Gaps found (need a backend decision before the mobile can reach 100 % parity)

1. Only 10 entities have delta feeds; invoices, orders, quotes, stock are not offline-syncable server-side.
2. The web SPA authenticates with session cookies, not Bearer — mobile must use the PKCE path above.
3. Translations are flat `key → value` maps; no versioning/ETag, so the app refetches per launch and keeps the last copy.

## 8. Analytical cost accounting (Mod 018)

Offline read models and queue in the generic entity store (`analytical_snapshot`, `analytical_operation`); workspace module `analytical_accounting` (executive).

| Use | Endpoint |
| --- | --- |
| Center tree | `GET /analytical/centers/tree` |
| Apportionment history | `GET /analytical/runs` |
| Contribution margin statement | `GET /analytical/reports/contribution-margin` |
| Direct versus apportioned | `GET /analytical/reports/direct-vs-apportioned` |
| Manual analytical entry (queued offline) | `POST /analytical/entries` |
4. Field Service (`/api/v1/fsm`, Mod 17, #196/#202): the offline-bundle does not carry the contract coverage rules
   (`coverage_type`, `status`) of a work order, only `service_contract_id`. The app reads `service_contract: {id,
   coverage_type, status}` (or flat `contract_coverage_type` / `contract_status`) when the API adds it and otherwise assumes
   the server defaults (`parts_and_labor`, active), flagging the covered/chargeable indicator as an estimate.
5. Field Service photos: uploaded through `POST /fsm/work-orders/{id}/photos` (see section 7); the legacy
   `photos.*.path` string reference still travels in the report payload next to the new `photo_ids`.

## 7. Field Service (`lib/features/field_service`)

| Purpose | Call |
| --- | --- |
| Delta bundle (work orders, customers, equipment + history, checklist templates, van stock) | `GET /fsm/technicians/{id}/offline-bundle?since=<server_time>` |
| Offline outbox, one batch of up to 200 operations in queue order | `POST /fsm/mobile-sync` `{operations:[{client_uuid, type, work_order_id, payload}]}` |

Operation types: `status_transition` (`{status: en_route|on_site, at}`), `part_consumption` (`{product_id, quantity, unit_price,
lot_number?, lot_or_serial_id?}`), `service_report` (the `SignServiceReportRules` payload with `signature_svg`, `signed_at`,
checklist, `labor_hours`, `travel_hours`, `travel_km`, `apply_callout_fee`, photos, GPS, `locale`). Results per operation:
`applied`, `duplicate` (same `client_uuid` already applied) or `rejected` (field `errors`, kept as a conflict). Local tables
(`fsm_*`) are created on first use with plain SQL, so no Drift codegen or schema bump is involved (new `fsm_photos` columns
`stage`, `caption`, `server_id` are added with `ALTER TABLE` when missing).

Photos: `POST /fsm/work-orders/{id}/photos` (multipart: `photo` file, `client_uuid` required, optional `stage`
`before|during|after`, `caption`, `captured_at` ISO) answers `{data:{id, work_order_id, path, stage, caption, captured_at,
url}}`, 201 the first time and 200 for a replayed `client_uuid`; `GET` on the same path lists them. Each photo taken is an
outbox operation `photo_upload` whose `client_uuid` is the photo id, resent unchanged on every retry. It is not part of
`mobile-sync`: the outbox sends it alone, in its queue position, reading the file from the local path at send time, so the
photos of a work order are stored before its `service_report`, whose payload then gets `photo_ids` (server ids of the photos
uploaded so far). Missing file, 413, 422, 403, 404 -> conflict (retry or discard, discard drops the photo); offline and 401
stop the flush; 5xx/429 back off and hold back later operations. A photo already on the server cannot be removed from the
phone. Per photo the screen shows queued / uploaded / failed.

## 8. Accounts Receivable and Credit Management (`lib/features/receivables`, Mod 013)

Base `/invoicing/receivables` (Dio base URL already carries `/api/v1`). Amounts are decimal strings, held as `Money` (integer
cents); aging buckets always come from the `buckets` array of the answer.

| Purpose | Call |
| --- | --- |
| Overview (KPIs, aging, blocked customers) | `GET /dashboard?currency=` |
| Aging of all customers or one | `GET /aging?customer_id=&currency=` |
| Open items of a customer (paginated, all pages read) | `GET /items?customer_id=&open_only=1&per_page=100&page=` |
| One item with its allocations | `GET /items/{id}` |
| Credit position, risk, unreconciled payments, limit history | `GET /customers/{id}/credit`, `/risk`, `/unreconciled-payments`, `/credit-limits` |
| DSO and bad debt provision | `GET /dso`, `GET /provision` |
| Customer statement (JSON, PDF, XLSX) | `GET /customers/{id}/statement`, `/statement/pdf`, `/statement/xlsx` |
| Book payment, credit note, write-off, discount | `POST /allocations` `{allocations:[{receivable_item_id, type, amount, value_date, source_id?, reference?, notes?}]}` |
| Reverse an allocation | `POST /allocations/{id}/reverse` |
| Dispute or lift | `POST /items/{id}/dispute` `{disputed, reason?}` |

Reads are cached as JSON in the shared `entity_records` table (entities `receivables_snapshot`, `receivable_items`), so no
Drift codegen or schema bump is involved. The three writes go through the outbox (entities `receivable_allocations`,
`receivable_reversals`, `receivable_disputes`, all terminal: 422/403 parks the row as rejected); the queue row UUID is the
`Idempotency-Key`, an identical request still waiting is not queued twice, and the cached item is updated at once. Credit
limits and overrides are read-only on the phone.

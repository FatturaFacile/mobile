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
5. Field Service photos: `photos.*.path` of the service report is a string reference; no upload endpoint exists yet, so the
   JPEG stays on the phone (`fsm_photos`) and only the reference travels with the report.

## 7. Field Service (`lib/features/field_service`)

| Purpose | Call |
| --- | --- |
| Delta bundle (work orders, customers, equipment + history, checklist templates, van stock) | `GET /fsm/technicians/{id}/offline-bundle?since=<server_time>` |
| Offline outbox, one batch of up to 200 operations in queue order | `POST /fsm/mobile-sync` `{operations:[{client_uuid, type, work_order_id, payload}]}` |

Operation types: `status_transition` (`{status: en_route|on_site, at}`), `part_consumption` (`{product_id, quantity, unit_price,
lot_number?, lot_or_serial_id?}`), `service_report` (the `SignServiceReportRules` payload with `signature_svg`, `signed_at`,
checklist, `labor_hours`, `travel_hours`, `travel_km`, `apply_callout_fee`, photos, GPS, `locale`). Results per operation:
`applied`, `duplicate` (same `client_uuid` already applied) or `rejected` (field `errors`, kept as a conflict). Local tables
(`fsm_*`) are created on first use with plain SQL, so no Drift codegen or schema bump is involved.

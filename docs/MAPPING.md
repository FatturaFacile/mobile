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

## 8. Project portfolio and WBS (`lib/features/project_portfolio`, Mod 078, #187)

Offline-first on the generic entity store (no Drift table, no schema bump). Sync entities, pulled with the usual delta
`GET /mobile/sync/{entity}` (`projects`, `wbs_nodes`, `task_dependencies`, `project_baselines`); JSON keys are snake_case
and decimals travel as strings. Enum values are read tolerantly (`on_hold` = `onHold`).

| Entity | Writes from the device (outbox, client UUID v7 as `id`, `Idempotency-Key` per row) |
| --- | --- |
| `projects` | `PUT /projects/{id}` with the changed fields among `name`, `status`, `cup_code`, `cig_code` |
| `wbs_nodes` | `POST /projects/{projectId}/wbs-nodes`, `PUT /projects/wbs-nodes/{id}`, `DELETE /projects/wbs-nodes/{id}` |
| `task_dependencies` | `POST /projects/{projectId}/dependencies`, `DELETE /projects/task-dependencies/{id}` |
| `project_baselines` | `POST /projects/{projectId}/baselines` `{baseline_number, name, captured_at, snapshot_json}` |

Shapes: `Project` (`project_code`, `project_type` client_billable|internal_r_and_d|capex_investment, `billing_model`
time_and_materials|fixed_price|sal_progress|retainer, `status` planning|active|on_hold|completed|cancelled, `cup_code`,
`cig_code`, rolled-up `planned_hours`, `actual_hours`, `planned_cost`, `actual_cost`, `planned_revenue`,
`percent_complete`), `WbsNode` (`parent_node_id`, `wbs_code`, `node_type` phase|deliverable|work_package|milestone, figures,
`start_date`, `end_date`, `percent_complete`, `sort_order`, `early_*`, `late_*`, `total_float_days`, `free_float_days`,
`is_critical`), `TaskDependency` (`predecessor_node_id`, `successor_node_id`, `dependency_type` fs|ss|ff|sf, `lag_days`),
`ProjectBaseline` (`baseline_number`, `name`, `captured_at`, `snapshot_json` = `{"nodes":[{id, wbs_code, title,
start_date, end_date, planned_hours, planned_cost, planned_revenue}]}`).

The device recomputes what it shows from the local records, so edits made offline are consistent at once and the server
values win again on the next pull: summary nodes show the sum of their children (progress weighted by planned hours, dates
spanning the children), and the schedule runs CPM on the leaf nodes (FS/SS/FF/SF with lag or lead in days, planned start
as "start no earlier than", milestones with no duration). A dependency that would close a loop, or duplicate a link, is
refused before it is queued. CUP (15) and CIG (10) are checked as upper-case alphanumeric before saving; the server remains
the authority. Kanban columns derive from progress (0 / 1-99 / 100). The module key in the bootstrap payload is
`project_portfolio`.
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

## 9. Supplier rebates and blanket agreements (Mod 049, `lib/features/supplier_rebates`)

Module keys `supplier_rebates` / `rebates` (web-api `module.access:rebates`). Monitoring and the light workflow only: proposing a
settlement and executing the open-item set-off stay on web and desktop. Offline copies live in the generic entity store
(`rebate_agreements`, `rebate_progress`, `rebate_runs`, `rebate_proposals`, `rebate_contracts`, `rebate_balances`), so there is
no Drift schema of its own; the tier position is always recomputed on the phone by `TierProgressCalculator` (a port of the
backend `RebateTierCalculator`, exact decimals with the backend scale of 10) from the cached tiers and the last known volume.

| Use | Endpoint |
| --- | --- |
| Purchase agreements (tiers, `open_rebate`) | `GET /rebates/agreements?direction=purchase`, `GET /rebates/agreements/{id}` (adds contributions) |
| Live progress | `GET /rebates/agreements/{id}/progress` |
| Accrual runs with invoice lines | `GET /rebates/agreements/{id}/accrual-runs` |
| Settlement proposals | `GET /rebates/settlement-proposals?agreement_id`, `GET /rebates/settlement-proposals/{id}` |
| Workflow (outbox entity `rebate_proposal_actions`, body `{version}`) | `POST /rebates/settlement-proposals/{id}/submit\|approve\|cancel` |
| Blanket agreements | `GET /procurement/contracts`, `GET /procurement/contracts/{id}/balance` |

A 403/409/422 on a queued action parks it as rejected (retry or dismiss); a repeated tap on the same queued action adds nothing.
Strings: `presentation/supplier_rebates_strings.dart` (it, en, de, fr; a region tag such as `de-CH` selects its language), texts
from the web-api `SupplierRebatesFrontendTranslations` seeder.

## 6. Purchase orders and dropshipment (Mod 046) — `lib/features/purchase_orders/`

REST under `/api/v1/procurement` (no delta feed: cached reads in the generic `entity_records` store, writes through the
outbox, so no Drift schema change). Rights: module key `purchase_orders` / `procurement_orders`.

| Use | Endpoint | Offline |
| --- | --- | --- |
| Order list / detail | `GET purchase-orders`, `GET purchase-orders/{id}` | cached (`po_orders`) |
| Overdue radar | `GET purchase-orders/overdue` | cached (`po_overdue`); also derived locally from the cached dates |
| Supplier confirmation | `POST purchase-orders/{id}/confirmations` (+ `GET`) | outbox `po_confirmations`, order turns `confirmed` locally |
| Reminders | `POST purchase-orders/{id}/reminders` (+ `GET`) | outbox `po_reminders`, counter bumped locally |
| Dropshipments | `GET dropshipments`, `GET dropshipments/{id}` | cached (`po_dropships`) |
| Delivery notice | `POST dropshipments/{id}/deliveries` | outbox `po_dropship_deliveries` |
| Pricing preview | `POST purchase-orders/pricing-preview` | falls back to `PoPricing` (same arithmetic) |

The three outbox entities are terminal (`SyncEngine.defaultTerminalEntities`): a 422/403 parks the row as rejected.
Strings live in `purchase_order_strings.dart` (it/de/fr/en tables, parity enforced by a test), like `supplier_rebates`.

## 10. Italian VAT registers, LIPE, annual VAT and CU (Mod 029, `lib/features/italian_vat`)

Module keys `italian_vat` / `vat_registers` / `vat_compliance` (web-api routes sit behind `module.access:ledger`). Reads are cached as JSON
in the generic `entity_records` store (`vat_registers`, `vat_settlements`, `vat_annual`, `vat_certificates`, `vat_intent_letters`), so
there is no Drift schema change. The three writes go through the outbox (entities `vat_intent_letters`, `vat_lipe_requests`,
`vat_cu_requests`, all terminal: 422/403 parks the row as rejected, retry or dismiss); the queue row UUID is the `Idempotency-Key`,
an identical request still waiting is not queued twice. Files (register CSV, LIPE XML, settlement PDF, CU PDF, CU telematic file) are
online-only downloads handed to the system share sheet. Amounts are decimal strings held as `Amount4` (integer ten-thousandths).

| Use | Endpoint | Status in web-api |
| --- | --- | --- |
| Register of a period | `GET /general-ledger/vat-registers/{sales\|purchases\|receipts\|third-party-goods}?from&to` (`&format=csv`) | `sales`/`purchases` exist (lines + `totals`); the rest is the Mod 029 extension |
| Register extras | answer `meta`: `currency`, `sectionals[{code,label,last_protocol}]`, `lock{definitive,locked_at,last_protocol,stamp_duty_pages}`, `pro_rata_percent`, `ventilation{enabled,purchase_basis[{vat_rate,amount}]}`; line extras `sectional`, `deductible_vat`, `non_deductible_vat` | extension |
| Letters of intent | `GET /vat/intent-letters`; `POST /vat/intent-letters` `{customer_id?, customer_name, protocol, kind, authorized_amount, valid_from, valid_to, received_on, currency}` | extension |
| Letter shape | `id, customer_name, protocol` (`17 digits-6 digits`), `kind` single_operation\|up_to_amount\|period, `status` active\|exhausted\|expired\|revoked, `valid_from/to`, `authorized_amount`, `consumed_amount` | extension |
| Periodic settlements | `GET /vat/settlements`, `GET /vat/settlements/{id}` (`VatSettlementResource`) | exists |
| LIPE file and ledger reconciliation | settlement detail adds `lipe{generated_at,xsd_valid,xsd_errors[],signature_status unsigned\|signed\|invalid,protocol}` and `reconciliation{erario_balance}` | extension |
| Generate LIPE (outbox) | `POST /vat/settlements/{id}/lipe` | extension |
| LIPE XML / settlement PDF | `GET /vat/settlements/{id}/export-xml`, `/export-pdf` | exists |
| Annual summary | `GET /vat/annual-returns/{year}` → `{output_vat_amount,input_vat_amount,balance,paid_amount,credit_carried_forward,erario_balance}`; a 404 is fine, the phone sums the cached settlements instead | extension |
| Certificazioni Uniche | `GET /general-ledger/withholding-certificates?year=` (`recipient_name, recipient_kind professional\|agent, tax_code, vat_number, causale, gross_amount, taxable_amount, withheld_amount, f24_paid_amount, f24_paid_on, f24_tribute_code, pdf_available`) | extension |
| CU files | `GET /general-ledger/withholding-certificates/{id}/pdf`, `GET /general-ledger/withholding-certificates/telematic-file?year=` | extension |
| Generate CU (outbox) | `POST /general-ledger/withholding-certificates/generate` `{year}` | extension |

Computed on the phone, so it works offline and mirrors the server rules: the pro-rata split of the input VAT (`ProRata`, the yearly
percentage rounded up to the next unit), the ventilation of the retail receipts (`Ventilation`: gross split by purchases per rate, then
scorporated, the last rate absorbing the rounding), the plafond control of art. 8 c. 1 lett. c DPR 633/1972 (`PlafondGuard`: blocks when the
invoice exceeds the remaining plafond, the letter is outside its validity, revoked or without the 17+6 digit AdE protocol; warns from
90% used), the Erario c/IVA reconciliation (ledger movement minus the settlement's output-minus-input VAT, tolerance one cent) and the
annual summary (server figures win field by field). The server stays the authority: the extension endpoints above are the contract the
phone expects and must be matched by web-api (the sales/purchases register and the settlements already exist).
Strings: `presentation/italian_vat_strings.dart` (it, en, de, fr tables; `it-CH`/`it-IT` use `it`, `de-CH` `de`, `fr-CH` `fr`).

## 11. Swiss VAT / MWST / IVA / TVA (Mod 024, `lib/features/swiss_vat`)

Module keys `swiss_vat` / `swiss_mwst` (web-api `module.access:swiss_vat`). Offline snapshots live in the generic
`entity_records` store (`swiss_vat_config`, `swiss_vat_tax_codes`, `swiss_vat_returns`, `swiss_vat_bezugsteuer`,
`swiss_vat_adjustments`); queued mutations use `SyncEngine` terminal entities (`swiss_vat_bezugsteuer_requests`,
`swiss_vat_adjustment_requests`, `swiss_vat_return_requests`).

| Use | Endpoint |
| --- | --- |
| Company VAT regime config | `GET /swiss-vat/config`, `PUT /swiss-vat/config` |
| Tax codes catalog | `GET /swiss-vat/tax-codes`, `GET /swiss-vat/sss-sectors` |
| Periodic returns & calculate | `GET /swiss-vat/returns`, `POST /swiss-vat/returns/calculate` |
| AFC box schedule & quadratura | `GET /swiss-vat/returns/{id}/reconciliation` |
| SuisseTax XSD validate & XML export/share | `POST /swiss-vat/returns/{id}/validate`, `POST /swiss-vat/returns/{id}/export-xml`, `GET /swiss-vat/exports/{id}/download` |
| Bezugsteuer (Art. 45 LIVA) | `GET /swiss-vat/bezugsteuer`, `POST /swiss-vat/bezugsteuer`, `POST /swiss-vat/bezugsteuer/{id}/confirm\|exclude` |
| Input tax adjustments (Art. 30-33 LIVA) | `GET /swiss-vat/adjustments`, `POST /swiss-vat/adjustments`, `POST /swiss-vat/adjustments/{id}/approve` |

Strings: `presentation/swiss_vat_strings.dart` (`it-CH`, `it-IT`, `de-CH`, `fr-CH`, `en`).


# Postman collection

`HCM-2.1-seed.postman_collection.json` seeds a freshly installed HCM 2.1
environment: a user, a boundary search, three project types, a facility,
and bulk project-resource and project-staff creation.

## Before you run it

Set these collection variables. None of them ship with a value.

| variable | what to set |
|---|---|
| `host` | your environment's base URL |
| `password` | the password for the user the collection authenticates as |
| `tenantId` | defaults to `mz`; change it to your tenant |

The credentials are deliberately empty. Do not commit a filled-in copy.

## Product variables need your environment's codes

The `productID*` and `ProductVariantId*` variables still carry codes from an
older dataset and do not match the codes in `seed-data/2.1/22-demo-products-mz.sql`.
Set them from your own environment before running "Project Resource Bulk Create"
or "Project Staff Bulk Create".

For the bundled seed data, three of them map directly:

| variable | product | code in the bundled seed |
|---|---|---|
| `productIDSP` | SP | `P-2026-07-06-001170` |
| `productIDAQ` | AQ | `P-2026-07-06-001172` |
| `productBednet` | Bednet | `P-2026-07-27-001758` |

The IRS variants (Sumishield, Fludora, Deltamethrin, Acetellic, Bendiocarb)
have no counterpart in the bundled seed data at all. Either load those products
into your environment first, or skip the IRS requests.

Verify against your own environment rather than trusting this table. The product
codes above were read from the seed file in this repository, not from a running
system.

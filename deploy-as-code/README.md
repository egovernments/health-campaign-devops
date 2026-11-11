# deploy-as-code

The Go installer that drives a DIGIT / HCM deployment from this repository.

> This directory previously carried the Helm common-library documentation by
> mistake. That chart is not here. It lives at
> [`config-as-code/helm/charts/common`](../config-as-code/helm/charts/common),
> and its own README is
> [`config-as-code/helm/charts/common/README.md`](../config-as-code/helm/charts/common/README.md).

## Layout

| path | what it is |
|---|---|
| `deployer/full_installer.go` | interactive installer: pick infra type, product, version and modules |
| `deployer/standalone_installer.go` | same selection flow, for an existing cluster |
| `deployer/digit_installer.go` | non-interactive installer used by CI |
| `deployer/main.go` | cobra entry point |
| `deployer/pkg/`, `deployer/internal/`, `deployer/configs/` | supporting packages |

Each installer file declares its own `package main` and its own `func main()`.
They are run individually with `go run <file>.go`, not built together. `go build ./...`
across the whole directory fails with duplicate-symbol errors, and that is expected.

## Release charts

All three installers read release charts from
`config-as-code/product-release-charts/<Product>/dependancy_chart-<product>-<version>.yaml`.

The interactive installers list that directory and offer every version they find.
`digit_installer.go` does not: it hardcodes `health-demo-v2.1`. Changing the version
CI installs means editing that string.

Charts currently available for Health: v1.0 and v1.2 through v1.8, v2.0, v2.1,
plus `health-qa-v1.0` and `health-v1.0`.

## Running it

```bash
cd deploy-as-code/deployer
go run full_installer.go
```

Install the prerequisites first with
[`infra-as-code/terraform/scripts/install_dependencies_ubuntu.sh`](../infra-as-code/terraform/scripts/install_dependencies_ubuntu.sh)
or the `_mac` equivalent. They install kubectl, helm, terraform, awscli,
aws-iam-authenticator and k9s.

## Module selection

A release chart groups services into modules. The interactive installers offer only
modules whose name contains `m_`, so `m_health`, `m_pgr`, `m_hcmconsole` and
`m_hcm_microplanning` are selectable while `backbone`, `core`, `business` and
`frontend` are pulled in as dependencies. Dependencies are matched by exact name.

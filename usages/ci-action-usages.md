# CI-Action Usage Graph

This graph shows which repositories are using files from the ci-action repository.

```mermaid
graph LR
    F1[".github/workflows/ci-extrachecks.yml"]
    F2["NOT_USED"]
    F2 --> F1
    F3[".github/workflows/ci.yml"]
    F2["NOT_USED"]
    F2 --> F3
    F4[".github/workflows/ci_rebuild_bp3.yml"]
    F5["airs-scheme/.github/workflows/short_go.yml"]
    F5 --> F4
    F6[".github/workflows/ci_reuse.yml"]
    F7["airc-backoffice2/.github/workflows/ci.yml"]
    F7 --> F6
    F8["web-portals/.github/workflows/ci.yml"]
    F8 --> F6
    F9["web-portals/.github/workflows/ci_payment.yml"]
    F9 --> F6
    F10["web-portals/.github/workflows/ci_reseller.yml"]
    F10 --> F6
    F11[".github/workflows/ci_reuse_go.yml"]
    F12["voedger/.github/workflows/ci-full.yml"]
    F12 --> F11
    F13["voedger/.github/workflows/ci-pkg-cmd.yml"]
    F13 --> F11
    F14[".github/workflows/ci_reuse_go_cas.yml"]
    F15["airs-bp3/.github/workflows/ci.yml"]
    F15 --> F14
    F16[".github/workflows/ci_reuse_go_norebuild.yml"]
    F17["airc-ticket-layouts/.github/workflows/short_go.yml"]
    F17 --> F16
    F18[".github/workflows/ci_reuse_go_pr.yml"]
    F19["voedger/.github/workflows/ci-pkg-cmd_pr.yml"]
    F19 --> F18
    F20[".github/workflows/cp.yml"]
    F21["airs-bp3/.github/workflows/cp.yml"]
    F21 --> F20
    F22["airc-backoffice2/.github/workflows/cp.yml"]
    F22 --> F20
    F23["airc-backoffice2/.github/workflows/cronecprelease.yml"]
    F23 --> F20
    F24["web-portals/.github/workflows/cp.yml"]
    F24 --> F20
    F25["web-portals/.github/workflows/cronecprelease.yml"]
    F25 --> F20
    F26["voedger/.github/workflows/cp.yml"]
    F26 --> F20
    F27[".github/workflows/create_issue.yml"]
    F28["airs-bp3/.github/workflows/nightly_tests.yml"]
    F28 --> F27
    F12["voedger/.github/workflows/ci-full.yml"]
    F12 --> F27
    F29["voedger/.github/workflows/ci_amazon.yml"]
    F29 --> F27
    F30["voedger/.github/workflows/ci_cas.yml"]
    F30 --> F27
    F31[".github/workflows/rc.yml"]
    F32["airs-bp3/.github/workflows/rc.yml"]
    F32 --> F31
    F33["airc-backoffice2/.github/workflows/rc.yml"]
    F33 --> F31
    F34["web-portals/.github/workflows/rc.yml"]
    F34 --> F31
    F35["action.yml"]
    F36["airs-template-implementation/.github/workflows/go.yml"]
    F36 --> F35
    F37["dynobuffers/.github/workflows/go.yml"]
    F37 --> F35
    F38["ci-action/.github/workflows/ci_reuse.yml"]
    F38 --> F35
    F39["ci-action/.github/workflows/ci_reuse_go.yml"]
    F39 --> F35
    F40["ci-action/.github/workflows/ci_reuse_go_cas.yml"]
    F40 --> F35
    F41["ci-action/.github/workflows/ci_reuse_go_norebuild.yml"]
    F41 --> F35
    F42["ci-action/.github/workflows/ci_reuse_go_pr.yml"]
    F42 --> F35
    F28["airs-bp3/.github/workflows/nightly_tests.yml"]
    F28 --> F35
    F43["airs-bp3/.github/workflows/update_voedger.yml"]
    F43 --> F35
    F44["scripts/add-issue-commit.sh"]
    F45["ci-action/.github/workflows/cp.yml"]
    F45 --> F44
    F45["ci-action/.github/workflows/cp.yml"]
    F45 --> F44
    F46["ci-action/.github/workflows/rc.yml"]
    F46 --> F44
    F46["ci-action/.github/workflows/rc.yml"]
    F46 --> F44
    F47["scripts/cancelworkflow.sh"]
    F42["ci-action/.github/workflows/ci_reuse_go_pr.yml"]
    F42 --> F47
    F48["scripts/checkPR.sh"]
    F38["ci-action/.github/workflows/ci_reuse.yml"]
    F38 --> F48
    F39["ci-action/.github/workflows/ci_reuse_go.yml"]
    F39 --> F48
    F40["ci-action/.github/workflows/ci_reuse_go_cas.yml"]
    F40 --> F48
    F41["ci-action/.github/workflows/ci_reuse_go_norebuild.yml"]
    F41 --> F48
    F42["ci-action/.github/workflows/ci_reuse_go_pr.yml"]
    F42 --> F48
    F49["scripts/check_copyright.sh"]
    F39["ci-action/.github/workflows/ci_reuse_go.yml"]
    F39 --> F49
    F40["ci-action/.github/workflows/ci_reuse_go_cas.yml"]
    F40 --> F49
    F41["ci-action/.github/workflows/ci_reuse_go_norebuild.yml"]
    F41 --> F49
    F42["ci-action/.github/workflows/ci_reuse_go_pr.yml"]
    F42 --> F49
    F50["scripts/close-issue.sh"]
    F45["ci-action/.github/workflows/cp.yml"]
    F45 --> F50
    F46["ci-action/.github/workflows/rc.yml"]
    F46 --> F50
    F51["airs-bp3/.github/workflows/close_cprelease.yml"]
    F51 --> F50
    F52["scripts/cp.sh"]
    F45["ci-action/.github/workflows/cp.yml"]
    F45 --> F52
    F53["scripts/createissue.sh"]
    F54["ci-action/.github/workflows/create_issue.yml"]
    F54 --> F53
    F55["scripts/deleteDockerImages.sh"]
    F56["airs-bp3/.github/workflows/cd_go.yml"]
    F56 --> F55
    F57["airs-bp3/.github/workflows/cdd_go.yml"]
    F57 --> F55
    F58["airc-backoffice2/.github/workflows/cd.yml"]
    F58 --> F55
    F59["airc-backoffice2/.github/workflows/cdd.yml"]
    F59 --> F55
    F60["web-portals/.github/workflows/cd-payment.yml"]
    F60 --> F55
    F61["web-portals/.github/workflows/cd-reseller.yml"]
    F61 --> F55
    F62["web-portals/.github/workflows/cdd-payment.yml"]
    F62 --> F55
    F63["web-portals/.github/workflows/cdd-reseller.yml"]
    F63 --> F55
    F64["airc-web-pos/.github/workflows/cd.yml"]
    F64 --> F55
    F65["scripts/domergepr.sh"]
    F66["voedger/.github/workflows/merge.yml"]
    F66 --> F65
    F67["scripts/execgovuln.sh"]
    F68["voedger/.github/workflows/ci-vulncheck.yml"]
    F68 --> F67
    F69["scripts/gbash.sh"]
    F39["ci-action/.github/workflows/ci_reuse_go.yml"]
    F39 --> F69
    F40["ci-action/.github/workflows/ci_reuse_go_cas.yml"]
    F40 --> F69
    F41["ci-action/.github/workflows/ci_reuse_go_norebuild.yml"]
    F41 --> F69
    F42["ci-action/.github/workflows/ci_reuse_go_pr.yml"]
    F42 --> F69
    F70["scripts/git-release.sh"]
    F2["NOT_USED"]
    F2 --> F70
    F71["scripts/large-file-hook.sh"]
    F2["NOT_USED"]
    F2 --> F71
    F72["scripts/linkmilestone.sh"]
    F73["voedger/.github/workflows/linkIssue.yml"]
    F73 --> F72
    F74["scripts/pre-commit-hook.sh"]
    F2["NOT_USED"]
    F2 --> F74
    F75["scripts/rc.sh"]
    F46["ci-action/.github/workflows/rc.yml"]
    F46 --> F75
    F76["scripts/rebuild-schemas-bp3.sh"]
    F77["airs-bp3/.github/workflows/update_baseline_schemas.yml"]
    F77 --> F76
    F78["scripts/rebuild-test-bp3.sh"]
    F79["ci-action/.github/workflows/ci_rebuild_bp3.yml"]
    F79 --> F78
    F80["scripts/test_subfolders.sh"]
    F39["ci-action/.github/workflows/ci_reuse_go.yml"]
    F39 --> F80
    F42["ci-action/.github/workflows/ci_reuse_go_pr.yml"]
    F42 --> F80
    F81["scripts/test_subfolders_full.sh"]
    F39["ci-action/.github/workflows/ci_reuse_go.yml"]
    F39 --> F81
    F82["scripts/unlinkmilestone.sh"]
    F83["voedger/.github/workflows/unlinkIssue.yml"]
    F83 --> F82
    F84["scripts/update-bp3-voedger.sh"]
    F43["airs-bp3/.github/workflows/update_voedger.yml"]
    F43 --> F84
    F85["scripts/updateConfig.sh"]
    F86["airs-bp3/.github/workflows/update_config_sync.yml"]
    F86 --> F85
    F59["airc-backoffice2/.github/workflows/cdd.yml"]
    F59 --> F85
    F62["web-portals/.github/workflows/cdd-payment.yml"]
    F62 --> F85
    F63["web-portals/.github/workflows/cdd-reseller.yml"]
    F63 --> F85
    F64["airc-web-pos/.github/workflows/cd.yml"]
    F64 --> F85
    F87["scripts/updateConfigDummy.sh"]
    F2["NOT_USED"]
    F2 --> F87
    F88["scripts/vulncheck.sh"]
    F2["NOT_USED"]
    F2 --> F88
```

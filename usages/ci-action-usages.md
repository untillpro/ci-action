# CI-Action Usage Graph

This graph shows which repositories are using files from the ci-action repository.

```mermaid
graph LR
    F1[".github/workflows/ci-extrachecks.yml"]
    F2[".github/workflows/ci.yml"]
    F3[".github/workflows/ci_rebuild_bp3.yml"]
    F4[".github/workflows/ci_reuse.yml"]
    F5[".github/workflows/ci_reuse_go.yml"]
    F6[".github/workflows/ci_reuse_go_cas.yml"]
    F7[".github/workflows/ci_reuse_go_norebuild.yml"]
    F8[".github/workflows/ci_reuse_go_pr.yml"]
    F9[".github/workflows/cp.yml"]
    F10[".github/workflows/create_issue.yml"]
    F11[".github/workflows/rc.yml"]
    F12["action.yml"]
    F13["scripts/add-issue-commit.sh"]
    F14["scripts/cancelworkflow.sh"]
    F15["scripts/checkPR.sh"]
    F16["scripts/check_copyright.sh"]
    F17["scripts/close-issue.sh"]
    F18["scripts/cp.sh"]
    F19["scripts/createissue.sh"]
    F20["scripts/deleteDockerImages.sh"]
    F21["scripts/domergepr.sh"]
    F22["scripts/execgovuln.sh"]
    F23["scripts/gbash.sh"]
    F24["scripts/git-release.sh"]
    F25["scripts/large-file-hook.sh"]
    F26["scripts/linkmilestone.sh"]
    F27["scripts/pre-commit-hook.sh"]
    F28["scripts/rc.sh"]
    F29["scripts/rebuild-schemas-bp3.sh"]
    F30["scripts/rebuild-test-bp3.sh"]
    F31["scripts/test_subfolders.sh"]
    F32["scripts/test_subfolders_full.sh"]
    F33["scripts/unlinkmilestone.sh"]
    F34["scripts/update-bp3-voedger.sh"]
    F35["scripts/updateConfig.sh"]
    F36["scripts/updateConfigDummy.sh"]
    F37["scripts/vulncheck.sh"]
    subgraph SG1["airs-template-implementation"]
        F38[".github/workflows/go.yml"]
    end
    subgraph SG2["dynobuffers"]
        F39[".github/workflows/go.yml"]
    end
    subgraph SG3["airs-scheme"]
        F40[".github/workflows/short_go.yml"]
    end
    subgraph SG4["ci-action"]
        F41[".github/workflows/ci_rebuild_bp3.yml"]
        F42[".github/workflows/ci_reuse.yml"]
        F43[".github/workflows/ci_reuse_go.yml"]
        F44[".github/workflows/ci_reuse_go_cas.yml"]
        F45[".github/workflows/ci_reuse_go_norebuild.yml"]
        F46[".github/workflows/ci_reuse_go_pr.yml"]
        F47[".github/workflows/cp.yml"]
        F48[".github/workflows/create_issue.yml"]
        F49[".github/workflows/rc.yml"]
    end
    subgraph SG5["airc-ticket-layouts"]
        F50[".github/workflows/short_go.yml"]
    end
    subgraph SG6["airc-web-pos"]
        F51[".github/workflows/cd.yml"]
    end
    subgraph SG7["airs-bp3"]
        F52[".github/workflows/cd_go.yml"]
        F53[".github/workflows/cdd_go.yml"]
        F54[".github/workflows/ci.yml"]
        F55[".github/workflows/close_cprelease.yml"]
        F56[".github/workflows/cp.yml"]
        F57[".github/workflows/nightly_tests.yml"]
        F58[".github/workflows/rc.yml"]
        F59[".github/workflows/update_baseline_schemas.yml"]
        F60[".github/workflows/update_config_sync.yml"]
        F61[".github/workflows/update_voedger.yml"]
    end
    subgraph SG8["airc-backoffice2"]
        F62[".github/workflows/cd.yml"]
        F63[".github/workflows/cdd.yml"]
        F64[".github/workflows/ci.yml"]
        F65[".github/workflows/cp.yml"]
        F66[".github/workflows/cronecprelease.yml"]
        F67[".github/workflows/rc.yml"]
    end
    subgraph SG9["web-portals"]
        F68[".github/workflows/cd-payment.yml"]
        F69[".github/workflows/cd-reseller.yml"]
        F70[".github/workflows/cdd-payment.yml"]
        F71[".github/workflows/cdd-reseller.yml"]
        F72[".github/workflows/ci.yml"]
        F73[".github/workflows/ci_payment.yml"]
        F74[".github/workflows/ci_reseller.yml"]
        F75[".github/workflows/cp.yml"]
        F76[".github/workflows/cronecprelease.yml"]
        F77[".github/workflows/rc.yml"]
    end
    subgraph SG10["voedger"]
        F78[".github/workflows/ci-full.yml"]
        F79[".github/workflows/ci-pkg-cmd.yml"]
        F80[".github/workflows/ci-pkg-cmd_pr.yml"]
        F81[".github/workflows/ci-vulncheck.yml"]
        F82[".github/workflows/ci_amazon.yml"]
        F83[".github/workflows/ci_cas.yml"]
        F84[".github/workflows/cp.yml"]
        F85[".github/workflows/linkIssue.yml"]
        F86[".github/workflows/merge.yml"]
        F87[".github/workflows/unlinkIssue.yml"]
    end
    F88["NOT_USED"]
    F88 --> F1
    F88["NOT_USED"]
    F88 --> F2
    F40 --> F3
    F64 --> F4
    F72 --> F4
    F73 --> F4
    F74 --> F4
    F78 --> F5
    F79 --> F5
    F54 --> F6
    F50 --> F7
    F80 --> F8
    F56 --> F9
    F65 --> F9
    F66 --> F9
    F75 --> F9
    F76 --> F9
    F84 --> F9
    F57 --> F10
    F78 --> F10
    F82 --> F10
    F83 --> F10
    F58 --> F11
    F67 --> F11
    F77 --> F11
    F38 --> F12
    F39 --> F12
    F42 --> F12
    F43 --> F12
    F44 --> F12
    F45 --> F12
    F46 --> F12
    F57 --> F12
    F61 --> F12
    F47 --> F13
    F47 --> F13
    F49 --> F13
    F49 --> F13
    F46 --> F14
    F42 --> F15
    F43 --> F15
    F44 --> F15
    F45 --> F15
    F46 --> F15
    F43 --> F16
    F44 --> F16
    F45 --> F16
    F46 --> F16
    F47 --> F17
    F49 --> F17
    F55 --> F17
    F47 --> F18
    F48 --> F19
    F52 --> F20
    F53 --> F20
    F62 --> F20
    F63 --> F20
    F68 --> F20
    F69 --> F20
    F70 --> F20
    F71 --> F20
    F51 --> F20
    F86 --> F21
    F81 --> F22
    F43 --> F23
    F44 --> F23
    F45 --> F23
    F46 --> F23
    F88["NOT_USED"]
    F88 --> F24
    F88["NOT_USED"]
    F88 --> F25
    F85 --> F26
    F88["NOT_USED"]
    F88 --> F27
    F49 --> F28
    F59 --> F29
    F41 --> F30
    F43 --> F31
    F46 --> F31
    F43 --> F32
    F87 --> F33
    F61 --> F34
    F60 --> F35
    F63 --> F35
    F70 --> F35
    F71 --> F35
    F51 --> F35
    F88["NOT_USED"]
    F88 --> F36
    F88["NOT_USED"]
    F88 --> F37
```

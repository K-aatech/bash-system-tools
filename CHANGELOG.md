# Changelog

## [1.7.3](https://github.com/K-aatech/bash-system-tools/compare/v1.7.2...v1.7.3) (2026-02-13)


### Bug Fixes

* **release:** enforce PR title pattern for squash workflow ([#59](https://github.com/K-aatech/bash-system-tools/issues/59)) ([e0070b9](https://github.com/K-aatech/bash-system-tools/commit/e0070b9338dfd798b63998ebed93aace25f0cf9d))

## [1.7.2](https://github.com/K-aatech/bash-system-tools/compare/v1.7.1...v1.7.2) (2026-02-12)


### Bug Fixes

* **ci:** correct release-please changelog config and prevent duplicate lint runs on main push ([#52](https://github.com/K-aatech/bash-system-tools/issues/52)) ([4676c1b](https://github.com/K-aatech/bash-system-tools/commit/4676c1b694e1db8feb32c6c24f101584491daf38))

## [1.7.1](https://github.com/K-aatech/bash-system-tools/compare/v1.7.0...v1.7.1) (2026-02-12)


### Bug Fixes

* align release-please generator and lint gate ([#43](https://github.com/K-aatech/bash-system-tools/issues/43)) ([c7f59f8](https://github.com/K-aatech/bash-system-tools/commit/c7f59f8664e8046aa636a64c096402d668cd307f))
* **ci:** migrate lint workflow to pull_request_target for bot compatibility ([#46](https://github.com/K-aatech/bash-system-tools/issues/46)) ([95121a5](https://github.com/K-aatech/bash-system-tools/commit/95121a5ebffd771a9829c3e083b89632adaba7a0))
* **ci:** use PAT for release-please to enable required status checks ([#49](https://github.com/K-aatech/bash-system-tools/issues/49)) ([8b472ea](https://github.com/K-aatech/bash-system-tools/commit/8b472ea05d42447875d53a82db5c19850d6c4d94))
* final adjustment to linter reporting ([#37](https://github.com/K-aatech/bash-system-tools/issues/37)) ([9858b58](https://github.com/K-aatech/bash-system-tools/commit/9858b5842b11b268d49a7d85e4c58b645f7281b1))
* generalize lint workflow trigger ([#45](https://github.com/K-aatech/bash-system-tools/issues/45)) ([93b9916](https://github.com/K-aatech/bash-system-tools/commit/93b991604ebd885342e3b673d8c03b88501d2256))
* restore release-please legacy mode ([#44](https://github.com/K-aatech/bash-system-tools/issues/44)) ([d7f5117](https://github.com/K-aatech/bash-system-tools/commit/d7f5117e5560e66a3939ead169e134bedc44a60a))
* test release pipeline after trunk migration ([#41](https://github.com/K-aatech/bash-system-tools/issues/41)) ([a1dbcaa](https://github.com/K-aatech/bash-system-tools/commit/a1dbcaadbd9180f1ed6ce2c69ce0a093e506e0b0))
* update badges filters and minor style corrections. ([#35](https://github.com/K-aatech/bash-system-tools/issues/35)) ([12f468c](https://github.com/K-aatech/bash-system-tools/commit/12f468c50d156f321239e4abc4bd959d5cbe5170))

## [1.7.0](https://github.com/K-aatech/bash-system-tools/compare/v1.7.0-rc.2...v1.7.0) (2026-02-11)


### 🚀 Features

* implement release-please and update repository architecture (https://github.com/K-aatech/bash-system-tools/issues/22) ([5982fad](https://github.com/K-aatech/bash-system-tools/commit/5982fad2cbf83400abb47c7f6fdf6172b352b6fa))
* promote release candidate to stable v1.7.0 ([#27](https://github.com/K-aatech/bash-system-tools/issues/27)) ([620e9aa](https://github.com/K-aatech/bash-system-tools/commit/620e9aa395cb6b5e30d0a601080acaf478dae5f6))

### 🐛 Bug Fixes

* fix status check blockage by making linter job always-run  ([16d7c45](https://github.com/K-aatech/bash-system-tools/commit/16d7c451cc3c3396f787d3c6c9538d0d25ece5d6))

### ⚙️ CI/CD & Infra

* ci: refine linter triggers and implement RC automation ([#25](https://github.com/K-aatech/bash-system-tools/pull/25) ([756e084](https://github.com/K-aatech/bash-system-tools/commit/756e0848c8b1b005dffa74118e4e504e341bbd0d))

### Miscellaneous Chores

* prepare v1.7.0 stable release ([#34](https://github.com/K-aatech/bash-system-tools/issues/34)) ([72c906e](https://github.com/K-aatech/bash-system-tools/commit/72c906e8bda5d2cb6b922801a7e1bd29904b89d4))

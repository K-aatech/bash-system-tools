# Changelog

## [1.7.4](https://github.com/K-aatech/bash-system-tools/compare/v1.7.3...v1.7.4) (2026-02-14)


### 🐛 Bug Fixes

* **ci:** 🔒️ update changed-files to v47 for security remediation ([#73](https://github.com/K-aatech/bash-system-tools/issues/73)) ([1ea781a](https://github.com/K-aatech/bash-system-tools/commit/1ea781a4a907d5b3a8f66b5951b0ce5e4ca2d3f0))


### ⚙️ CI/CD & Infra

* **deps:** ➕ enable Dependabot for GitHub Actions updates ([#67](https://github.com/K-aatech/bash-system-tools/issues/67)) ([8814704](https://github.com/K-aatech/bash-system-tools/commit/8814704d2909cbe62a837c41d43521e498d4cd3b))


### 📚 Documentation

* 📝 align repository documentation with trunk-based governance model ([#84](https://github.com/K-aatech/bash-system-tools/issues/84)) ([3928bf3](https://github.com/K-aatech/bash-system-tools/commit/3928bf381f3ff50820bb85dfba717ea9820e7322))
* **audit:** 📝 update engineering manual for sys-audit-check.sh ([#86](https://github.com/K-aatech/bash-system-tools/issues/86)) ([df056d8](https://github.com/K-aatech/bash-system-tools/commit/df056d8517d8ff11acea2596e42c8c17f4b68bef))
* **security:** 📝 add SECURITY.md with repository security policy ([#82](https://github.com/K-aatech/bash-system-tools/issues/82)) ([d427e5c](https://github.com/K-aatech/bash-system-tools/commit/d427e5c07d37bb2781be340f5f90cbee61df7f1f))


### 🧹 Maintenance

* **ci:** ♻️ refactor shellcheck to run only on changed scripts without external action ([#80](https://github.com/K-aatech/bash-system-tools/issues/80)) ([1c01561](https://github.com/K-aatech/bash-system-tools/commit/1c015613af4a377a8d50238dafc68deff050c6fc))
* **ci:** 👷 harden release-please workflow (add concurrency and timeout) ([#81](https://github.com/K-aatech/bash-system-tools/issues/81)) ([b74d090](https://github.com/K-aatech/bash-system-tools/commit/b74d0902710348597e0adf91949f3fd86d236c10))
* **ci:** 📌 harden commitlint workflow (pin deps, add concurrency and timeout) ([#79](https://github.com/K-aatech/bash-system-tools/issues/79)) ([b988f28](https://github.com/K-aatech/bash-system-tools/commit/b988f28198d31215d259b9d3a0e02ffa01141484))
* **ci:** 📌 pin actions/checkout to v6.0.2 for reproducible builds ([#74](https://github.com/K-aatech/bash-system-tools/issues/74)) ([7840d57](https://github.com/K-aatech/bash-system-tools/commit/7840d578d9548dcbd54f4de7a640fac8625eedf7))
* **ci:** 📌 pin actions/setup-node to v6.2.0 ([#75](https://github.com/K-aatech/bash-system-tools/issues/75)) ([042f328](https://github.com/K-aatech/bash-system-tools/commit/042f328052e3c3f68ade499e2d0353fbda0a93a2))
* **ci:** 📌 pin GitHub Actions to commit SHA for supply-chain hardening ([#83](https://github.com/K-aatech/bash-system-tools/issues/83)) ([a630e68](https://github.com/K-aatech/bash-system-tools/commit/a630e6823d8ecd0ec2ad39594bb975d677557511))
* **ci:** 📌 pin release-please-action to v4.4.0 ([#76](https://github.com/K-aatech/bash-system-tools/issues/76)) ([85a15cf](https://github.com/K-aatech/bash-system-tools/commit/85a15cf9d1383ab983e68299b3bbc3f1481ff7da))
* **deps:** bump actions/checkout from 4 to 6 ([#70](https://github.com/K-aatech/bash-system-tools/issues/70)) ([4fa8dc7](https://github.com/K-aatech/bash-system-tools/commit/4fa8dc7d1ac59d1f4eb0c6040eb0c2f77323bad1))
* **deps:** configure dependabot weekly schedule (patch tuesday) ([#78](https://github.com/K-aatech/bash-system-tools/issues/78)) ([c137310](https://github.com/K-aatech/bash-system-tools/commit/c137310a6049187dbf8c77bccb138620ed06e8d3))
* enforce executable script policy with hook and CI validation ([#85](https://github.com/K-aatech/bash-system-tools/issues/85)) ([26a62dc](https://github.com/K-aatech/bash-system-tools/commit/26a62dca8453915f5881385558748dd4cdbaa522))
* **governance:** add CODEOWNERS for repository oversight ([#66](https://github.com/K-aatech/bash-system-tools/issues/66)) ([4acc2f3](https://github.com/K-aatech/bash-system-tools/commit/4acc2f327b67a6519feab2e1b77ac435faa134c5))
* **release:** 📝 include chore in changelog sections ([#77](https://github.com/K-aatech/bash-system-tools/issues/77)) ([ae63548](https://github.com/K-aatech/bash-system-tools/commit/ae63548520224faa53c4092972490fc2037bdff4))

## [1.7.3](https://github.com/K-aatech/bash-system-tools/compare/v1.7.2...v1.7.3) (2026-02-13)


### 🐛 Bug Fixes

* **ci:** 🐛 align release-please workflow with oficial documentation ([#63](https://github.com/K-aatech/bash-system-tools/issues/63)) ([20b2aab](https://github.com/K-aatech/bash-system-tools/commit/20b2aab124891e7c92d9c03dcc2535a57375fb06))
* **ci:** 🐛 fix component mapping for release-please v4 manifest ([#64](https://github.com/K-aatech/bash-system-tools/issues/64)) ([5f956df](https://github.com/K-aatech/bash-system-tools/commit/5f956dfa8a470dd12e4fbc367382e10bfeb3c0fd))
* **release:** enforce PR title pattern for squash workflow ([#59](https://github.com/K-aatech/bash-system-tools/issues/59)) ([e0070b9](https://github.com/K-aatech/bash-system-tools/commit/e0070b9338dfd798b63998ebed93aace25f0cf9d))
* **release:** migrate to manifest strategy to enable custom changelog sections ([#61](https://github.com/K-aatech/bash-system-tools/issues/61)) ([8d9eabb](https://github.com/K-aatech/bash-system-tools/commit/8d9eabbca856b7e2e89d23b77a9bad70a3760b1e))


### ⚙️ CI/CD & Infra

* enforce conventional commits with commitlint on pull requests ([#54](https://github.com/K-aatech/bash-system-tools/issues/54)) ([f7e8846](https://github.com/K-aatech/bash-system-tools/commit/f7e8846054564189d51060579552249253b51229))
* **workflows:** upgrade to Node 24 LTS and validate PR title ([#58](https://github.com/K-aatech/bash-system-tools/issues/58)) ([caa3a8e](https://github.com/K-aatech/bash-system-tools/commit/caa3a8e9549aa63c731696cbf7ae79d17f03fbe6))


### 📚 Documentation

* define formal semantic versioning and release governance policy ([#55](https://github.com/K-aatech/bash-system-tools/issues/55)) ([2bad52e](https://github.com/K-aatech/bash-system-tools/commit/2bad52e80a750ba3ecc0b0d4c182f8d36d3d1f17))
* **governance:** document squash-only and commit enforcement policy ([#62](https://github.com/K-aatech/bash-system-tools/issues/62)) ([bd72db1](https://github.com/K-aatech/bash-system-tools/commit/bd72db1af345c3d2817ea590435581365c1dec60))
* **versioning:** align README with release workflow and update VSCode recommendations ([#57](https://github.com/K-aatech/bash-system-tools/issues/57)) ([3d652bc](https://github.com/K-aatech/bash-system-tools/commit/3d652bc22e88f6db72616a3178c70256dcbccb6e))

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

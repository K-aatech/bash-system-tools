module.exports = {
    extends: ["@commitlint/config-conventional"],
    rules: {
        "type-enum": [
            2,
            "always",
            [
                "feat",
                "fix",
                "docs",
                "style",
                "refactor",
                "perf",
                "test",
                "build",
                "ci",
                "chore",
                "revert",
            ],
        ],
        "scope-enum": [
            1,
            "always",
            [
                "audit", // docs/governance-baseline.md
                "hardening", // hardening/
                "maintenance", // maintenance/
                "scripts", // scripts/
                "lib", // lib/
                "docs", // docs/
                "setup", //setup-checklist / env
                "governance", // Policies, processes, and guidelines related to project governance
                "ci", // CI/CD pipelines and infrastructure
                "tests", // Test-related changes, including test cases, test frameworks, and test infrastructure
            ],
        ],
        "scope-case": [2, "always", "lower-case"],
        "subject-case": [0],
    },
};

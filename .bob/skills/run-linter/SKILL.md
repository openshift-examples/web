---
name: run-linter
description: Use when the user wants to run the linter, pre-commit checks, or markdownlint/yamllint on this project. Covers the requirement to stage/commit changes first.
---

# Run Linter / Pre-commit Checks

This project uses `./run-local-pre-commit.sh` to execute markdownlint and yamllint via pre-commit.

## Important constraint

**All changes must be committed (or at least staged) before running the linter.**
Pre-commit hooks in this project operate on committed/staged content.
Uncommitted file changes will not be picked up correctly.

## Steps

1. Stage or commit all relevant changes:

   ```shell
   git add .
   git commit -m "wip: changes before lint check"
   ```

   (Or use `git add .` alone if you want to keep them as staged rather than committed.)

2. Run the linter:

   ```shell
   ./run-local-pre-commit.sh
   ```

3. If lint errors are reported, fix them, stage/commit the fixes, and re-run step 2 until clean.

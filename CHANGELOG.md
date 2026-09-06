# Changelog

All notable architecture/build baseline changes are recorded here.

## 0.0.0-phase-a - 2026-09-06

- Created Godot 4.7.2-stable project skeleton.
- Established layered repository boundaries for application, simulation domain, persistence, content, presentation, tooling/tests, and assets.
- Added minimal launch shell that does not own simulation state.
- Added stock-Godot headless smoke-test runner with machine-readable diagnostics and exit codes.
- Added domain dependency guard, bootstrap contract tests, repository contract test, and headless boot probe.
- Added repository/build hygiene, governing-document manifest, and Git baseline.

# tzf2 verification report

Measured on 2026-09-11 on this machine. Ruby 3.4.4, arm64 Darwin, rustc 1.98.1. Other Ruby and OS combinations are configured in CI and were not run here.

## Predicate

A local `tzf2` gem that looks up IANA timezones from WGS84 coordinates with tzf-rs 2.0, embeds current ocean-inclusive data, validates coordinates, and does not use the network after compile.

**VERIFIED** on this machine for the checks below. **INCONCLUSIVE** for Linux and for Ruby 3.2 / 3.3 until GitHub Actions finishes.

## Verification

| Check | Result | Evidence |
| --- | --- | --- |
| Native extension compiles | pass | `bundle exec rake compile` |
| Specs | pass | `bundle exec rake spec` |
| Differential vs baseline | pass | `bundle exec ruby bin/differential` prints `no differential changes` |
| `require "tzf"` drop-in | pass | `TZF.tz_name(40.7128, -74.0060)` returns `America/New_York` |
| Engine version | pass | `TZF.engine_version` is `2.0.0`, matches `Cargo.lock` |
| Data version | pass | `TZF.data_version` is `2026c` |
| Ocean coverage | pass | Point Nemo `Etc/GMT+8`, equator `Etc/GMT`, mid-Atlantic `Etc/GMT+2` |
| Shared border | pass | `44.04, 87.416` returns `Asia/Shanghai` and `Asia/Urumqi` |
| Coordinate order | pass | swapped arguments do not return `America/New_York` |
| Invalid input | pass | non-numeric, NaN, Inf, and out-of-range raise `InvalidCoordinatesError` |
| Concurrency | pass | 32 and 40-thread mixed land/ocean lookups |
| RubyGems push guard | pass | `allowed_push_host` is `do-not-publish.invalid` |

Not published to RubyGems.

## Supported artifacts

- Source gem `tzf2` 0.1.0
- Native crate `ext/tzf2` linked against tzf-rs 2.0.0 and tzf-dist `0.0.2026-c-tzb1`
- `spec/fixtures/locations.yml` cities, ocean, polar, and antimeridian points
- `spec/fixtures/differential_baseline.json` (those points plus a 10-degree global grid)
- GitHub Actions matrix in `.github/workflows/ci.yml`

## Measured characteristics

From `bundle exec ruby bin/measure` on this machine:

| Metric | Value |
| --- | --- |
| Init plus first query | 14.37 ms |
| Steady-state query | 684 ns per call, mixed land and ocean points |
| RSS increase after load | 41,536 KB |
| Compiled `tzf2.bundle` | 4,632,984 bytes |
| Source `.gem` | 19,456 bytes |
| Timezone names | 444 |

The source gem is small because the `.tzb` dataset is pulled from crates.io when the extension compiles. Runtime lookup does not open a socket.

tzf-rs documents DefaultFinder open at about 13 ms and about 44 MiB RSS on an M3 Max. This run is in that band.

## Remaining risks

- Lite boundary data can disagree with full-precision polygons inside about 111 m of a border.
- First install needs network access to RubyGems and crates.io. Later lookups do not.
- Platform gems are not built. Each host compiles Rust at install time and needs clang plus Rust 1.88 or newer.
- Windows is not in CI.
- `TZF.engine_version` is a constant kept in sync by a Cargo.lock test, not read from the crate at compile time.
- Linux and Ruby 3.2 / 3.3 are not verified on this machine.
- Replacing HarlemSquirrel `tzf` can still change answers near simplified borders. A 10-degree grid was not compared to the old gem.

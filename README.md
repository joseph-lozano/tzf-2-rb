# tzf2

Offline latitude and longitude to IANA timezone lookup for Ruby. The gem wraps [tzf-rs](https://github.com/ringsaturn/tzf-rs) 2.0 and embeds current ocean-inclusive boundary data from [tzf-dist](https://github.com/ringsaturn/tzf-dist). Lookups do not use the network.

This gem is a drop-in successor to [`tzf`](https://github.com/HarlemSquirrel/tzf-rb) for Rails apps that already call `TZF.tz_name(lat, lng)`. The published gem name is `tzf2` so it does not collide with HarlemSquirrel's gem.

## Install

You need Ruby 3.2 or newer (including 4.0).

Precompiled native gems ship for `x86_64-linux`, `aarch64-linux`, `x86_64-darwin`, and `arm64-darwin`. Other platforms compile from source and need clang plus Rust 1.88 or newer.

```ruby
# Gemfile
gem "tzf2"
```

Then run:

```bash
bundle install
```

`require "tzf2"` and `require "tzf"` both load the `TZF` module.

## Usage

Arguments are latitude first, then longitude. That matches the existing `tzf` gem. It is the opposite of the Rust and Python APIs.

```ruby
require "tzf2"

TZF.tz_name(40.7477, -73.9935)
# => "America/New_York"

TZF.tz_names(44.04, 87.416)
# => ["Asia/Shanghai", "Asia/Urumqi"]

TZF.data_version
# => "2026c"

TZF.engine_version
# => "2.0.0"
```

`tz_name` returns one IANA identifier. `tz_names` returns every match, sorted, which matters on shared borders.

Invalid coordinates raise `TZF::InvalidCoordinatesError`.

```ruby
TZF.tz_name(91, 0)
# TZF::InvalidCoordinatesError: latitude 91.0 is outside -90..90
```

A valid point with no covering polygon raises `TZF::UncoveredCoordinateError`. Rescue that in the application if you need a fallback. This gem does not guess a neighbor zone.

```ruby
TZF.tz_name(-54.1, -36.1)
# TZF::UncoveredCoordinateError: no timezone covers latitude -54.1, longitude -36.1
```

`raw_tz_name` and `raw_tz_names` return the engine result without raising (`""` / `[]` on a miss).

## Global coverage

The embedded dataset is timezone-boundary-builder `timezones-with-oceans` as packaged by tzf-dist release `2026c`. That product includes land zones, territorial waters, polar regions, and open-ocean `Etc/GMT*` zones. It does not tile the sphere without gaps.

Lite simplification and a few source/encoding slivers leave hairline holes. A 10-degree grid is fully covered in `spec/fixtures/differential_baseline.json`. A 0.1-degree walk is not. Full-precision `tzf-dist` data closes some lite holes and still misses others.

This gem returns `UncoveredCoordinateError` on those points. It does not snap to a neighbor.

This release reports 444 timezone names.

The default dataset is the lite `.tzb` file. Simplified boundaries stay within about 111 m of the full-precision border. See the [tzf-rs accuracy notes](https://github.com/ringsaturn/tzf-rs#accuracy).

## Ocean timezone semantics

Open ocean uses POSIX-signed `Etc/GMT*` identifiers.

- `Etc/GMT+8` is UTC-08:00.
- `Etc/GMT-5` is UTC+05:00.

Point Nemo (`-48.876667, -123.393333`) returns `Etc/GMT+8`. Coastal points inside territorial waters keep the land zone.

## Data provenance

| Layer | Source | License |
| --- | --- | --- |
| Ruby and Rust wrapper | this repository | MIT, see `LICENSE` |
| Lookup engine | [tzf-rs](https://github.com/ringsaturn/tzf-rs) 2.0.0 | MIT |
| Packed `.tzb` data | [tzf-dist](https://github.com/ringsaturn/tzf-dist) `2026c` | ODbL, see `LICENSE_DATA` |
| Original boundaries | [timezone-boundary-builder](https://github.com/evansiroky/timezone-boundary-builder) | ODbL |

The original database is built from OpenStreetMap. `NOTICE` names both upstreams.

## Version reporting

- `TZF::VERSION` is this gem.
- `TZF.engine_version` is the compiled `tzf-rs` crate.
- `TZF.data_version` is the tzf-dist / timezone-boundary-builder release inside the binary.

Pin all three when you record a production lookup result.

## Upgrades

1. Bump `tzf-rs` in `ext/tzf2/Cargo.toml`.
2. Run `cargo update -p tzf-rs` and `bundle exec rake compile`.
3. Run `bundle exec rake spec`.
4. Run `bundle exec ruby bin/differential`.
5. If the report lists timezone-id, timezone-names, UTC-offset, newly covered, or uncovered points, decide whether the new data is intended.
6. To accept the new table, run `bundle exec rake differential:write` and update `spec/fixtures/locations.yml`.
7. Set `TZF.engine_version` in `ext/tzf2/src/lib.rs` to the new crate version.

## Testing

```bash
bin/setup
bundle exec rake
bundle exec rake differential
```

Specs cover major cities, ocean zones including Point Nemo, polar and antimeridian points, shared borders, latitude/longitude order, invalid input, and thread safety.

A 10-degree world grid and a 0.1-degree world grid are looked up in a standalone Rust binary (`crates/grid_parity`) and again through `TZF.raw_tz_name` / `TZF.raw_tz_names`. The answers must match, including empty engine results. That checks the Ruby wrapper against tzf-rs, not against a pinned Ruby table.

The differential suite compares the current engine to `spec/fixtures/differential_baseline.json`. It reports timezone-id changes, all-match list changes, UTC-offset changes at `2026-01-15T12:00:00Z`, and points that gained or lost coverage.

## Rollback

Keep the previous `tzf2` git SHA in the Gemfile if a data upgrade changes production answers.

```ruby
gem "tzf2", github: "joseph-lozano/tzf-2-rb", ref: "<known-good-sha>"
```

To go back to HarlemSquirrel's gem, restore `gem "tzf"` and `require "tzf"`. The call shape is the same. Answers can differ because that gem still tracks tzf-rs 1.x.

## Supported platforms

CI compiles and tests Ruby 3.2, 3.3, 3.4, and 4.0 on Ubuntu, plus Ruby 3.4 on `ubuntu-24.04-arm`.

Release builds precompiled gems for Linux x86_64, Linux ARM64, Intel Mac, and Apple Silicon. Windows is not supported.

## License

MIT for the wrapper. ODbL for the embedded boundary database. See `LICENSE`, `LICENSE_DATA`, and `NOTICE`.

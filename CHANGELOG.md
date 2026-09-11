# Changelog

## 0.0.1

First release. Wraps tzf-rs 2.0.0 with tzf-dist `2026c` ocean-inclusive data.

Public API:

- `TZF.tz_name(latitude, longitude)`
- `TZF.tz_names(latitude, longitude)`
- `TZF.data_version`
- `TZF.engine_version`

In-range points with no covering polygon raise `TZF::UncoveredCoordinateError`. The gem does not invent a fallback zone.

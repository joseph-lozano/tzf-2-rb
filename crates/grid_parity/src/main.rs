use serde::Serialize;
use std::io::{BufWriter, Write};
use tzf_rs::DefaultFinder;

const DEFAULT_STEP_DEG: f64 = 10.0;
const MILLIDEGREES: i32 = 1000;

#[derive(Serialize)]
struct Point {
    lat: f64,
    lng: f64,
    tz_name: String,
    tz_names: Vec<String>,
}

fn main() {
    let mut args = std::env::args().skip(1);
    let step_deg = args
        .next()
        .map(|value| value.parse::<f64>().expect("grid step must be a number"))
        .unwrap_or(DEFAULT_STEP_DEG);
    let ndjson = args.any(|arg| arg == "--ndjson");
    let step_md = ((step_deg * f64::from(MILLIDEGREES)).round()) as i32;
    if step_md <= 0 {
        panic!("grid step must be positive");
    }

    let finder = DefaultFinder::new();
    let min_lat = -90 * MILLIDEGREES;
    let max_lat = 90 * MILLIDEGREES;
    let min_lng = -180 * MILLIDEGREES;
    let max_lng = 180 * MILLIDEGREES;

    if ndjson {
        let mut out = BufWriter::new(std::io::stdout());
        let mut lat = min_lat;
        while lat <= max_lat {
            let mut lng = min_lng;
            while lng <= max_lng {
                let point = lookup(&finder, lat, lng);
                serde_json::to_writer(&mut out, &point).expect("write point");
                out.write_all(b"\n").expect("write newline");
                lng += step_md;
            }
            lat += step_md;
        }
        out.flush().expect("flush grid");
        return;
    }

    let mut points = Vec::new();
    let mut lat = min_lat;
    while lat <= max_lat {
        let mut lng = min_lng;
        while lng <= max_lng {
            points.push(lookup(&finder, lat, lng));
            lng += step_md;
        }
        lat += step_md;
    }
    serde_json::to_writer(std::io::stdout(), &points).expect("write grid json");
}

fn lookup(finder: &DefaultFinder, lat_md: i32, lng_md: i32) -> Point {
    let lat = f64::from(lat_md) / f64::from(MILLIDEGREES);
    let lng = f64::from(lng_md) / f64::from(MILLIDEGREES);
    Point {
        lat,
        lng,
        tz_name: finder.get_tz_name(lng, lat).to_string(),
        tz_names: finder
            .get_tz_names(lng, lat)
            .into_iter()
            .map(str::to_string)
            .collect(),
    }
}

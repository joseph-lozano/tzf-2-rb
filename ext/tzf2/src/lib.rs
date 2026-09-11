use std::sync::LazyLock;

use magnus::{function, prelude::*, Error, Ruby};
use tzf_rs::DefaultFinder;

static FINDER: LazyLock<DefaultFinder> = LazyLock::new(DefaultFinder::new);

const ENGINE_VERSION: &str = "2.0.0";

fn raw_tz_name(lat: f64, lng: f64) -> &'static str {
    FINDER.get_tz_name(lng, lat)
}

fn raw_tz_names(lat: f64, lng: f64) -> Vec<&'static str> {
    FINDER.get_tz_names(lng, lat)
}

fn raw_data_version() -> &'static str {
    FINDER.data_version()
}

fn raw_engine_version() -> &'static str {
    ENGINE_VERSION
}

fn raw_timezone_names() -> Vec<&'static str> {
    FINDER.timezonenames()
}

#[magnus::init]
fn init(ruby: &Ruby) -> Result<(), Error> {
    let module = ruby.define_module("TZF")?;
    module.define_singleton_method("raw_tz_name", function!(raw_tz_name, 2))?;
    module.define_singleton_method("raw_tz_names", function!(raw_tz_names, 2))?;
    module.define_singleton_method("raw_data_version", function!(raw_data_version, 0))?;
    module.define_singleton_method("raw_engine_version", function!(raw_engine_version, 0))?;
    module.define_singleton_method("raw_timezone_names", function!(raw_timezone_names, 0))?;
    Ok(())
}

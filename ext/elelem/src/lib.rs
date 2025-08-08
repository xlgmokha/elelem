use magnus::{Error, Ruby, function, prelude::*};

fn hello(subject: String) -> String {
    format!("Hello from Rust, {subject}!")
}

#[magnus::init]
fn init(ruby: &Ruby) -> Result<(), Error> {
    let module = ruby.define_module("Elelem")?;
    module.define_singleton_method("hello", function!(hello, 1))?;
    Ok(())
}

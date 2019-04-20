## Don’t `allow(unused)`

You should *avoid* warning-suppressing annotations like `#[allow(unused)]` in final code. They’re good for temporarily hiding warnings so you can see something else you care about, but before you’re done, you should but able to make your code warning-free without having to turn warnings off.

If a function is only used by tests then you should make sure it’s only being compiled when tests are being compiled. You can conditionally enable any definition only for testing by annotating it with `#[cfg(test)]`. Better yet, nest definitions that are only needed for testing inside a module that’s already being conditionally compiled for testing.

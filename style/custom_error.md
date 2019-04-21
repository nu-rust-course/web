## Define an error type that includes the errors you care about

Strings are not a good way to communicate many kinds of errors, both because they require parsing to extract information, and because they’re expensive. It’s better to define an error type that lets you express exactly the situations you care about in a way that’s easy to work with downstream.

For example, suppose that there are several kinds of errors you might experience while constructing and searching graphs:

  - You might be given a graph to parse that contains a syntax error.
  - You may be given a search query that is improperly formed.
  - You may be given a search query that refers to a non-existent vertex label.
  - You may experience an IO error.

We can define an `enum` for representing the possible errors. For example:

```rust
#[derive(Clone, Debug)]
pub enum GraphError {
    BadGraphFormat,
    QueryTooShort,
    QueryTooLong,
    UnknownLabel(String),
    IoError(std::io::Error),
}
```

(It's possible to make the `UnknownLabel` variant borrow the label rather than own it, but it's probably not worth it, as it would prevent an error from outliving the input that its label was parsed and borrowed from, which would be major a problem.)

If we want to generate these errors ourselves, that’s easy:

```rust
let w1  = query_words.next()
    .ok_or(GraphError::QueryTooShort)?;
let w2 = query_words.next()
    .ok_or(GraphError::QueryTooShort)?;
if query_words.next().is_some() {
    return Err(GraphError::QueryTooLong);
}

let src    = label_map.get_index(w1)
    .ok_or_else(|| GraphError::UnknownLabel(w1.to_owned()))?;
let dst    = label_map.get_index(w2)
    .ok_or_else(|| GraphError::UnknownLabel(w2.to_owned()))?;
```

(We use `Option::ok_or` and `Option::ok_or_else` to replace `None`s with `Err`s. The former is suitable when the value to put in the `Err` is free to construct, whereas the latter takes a closure to construct the error value, so that we can avoid doing so unless we actually need it.)

What about passing on errors that aren’t ours, though—in this case, is there a way to call an operation that might produce an `io::Error` and then gracefully convert the `io::Error` into a `GraphError`? Well, doing the mapping manually isn’t totally awful:

```rust
while line_result = buf_read.lines() {
    let line = line_result.map_err(GraphError::IoError)?;
    …
}
```

But actually, `?` will do the conversion for us if we tell it how:

```rust
impl From<std::io::IoError> for GraphError {
    fn from(err: std::io::Error) -> Self {
        GraphError::IoError(err)
    } 
}
```

And here’s how we use it now:

```rust
while line_result = buf_read.lines() {
    let line = line_result?;
    …
}
```


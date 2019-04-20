## Functions should not unconditionally clone save them

When a function always needs ownership of some argument then it should take that argument by value, not by reference. That way the caller can clone if it wants to retain ownership as well, but avoids cloning in both the caller and the callee when the caller is ready to give up ownership.

This often applies to compound types as well. For example, consider a function that ultimately needs to store or return a `Vec<String>`. Here are some ways it might take its argument, and what it has to do to get ownership:

```rust
fn slice_of_slices(ss: &[&str]) -> … {
    let v: Vec<String> = ss.iter().cloned().map(str::to_owned).collect();
    …
}

fn slice_of_borrowed(ss: &[&String]) -> … {
    let v: Vec<String> = ss.iter().cloned().map(String::clone).collect();
    …
}

fn slice_of_owned(ss: &[String]) -> … {
    let v: Vec<String> = ss.iter().map(String::clone).collect();
    …
}

fn vec_of_slices(ss: Vec<&str>) -> … {
    let v: Vec<String> = ss.into_iter().map(str::to_owned).collect();
    …
}

fn vec_of_borrowed(ss: Vec<&String>) -> … {
    let v: Vec<String> = ss.into_iter().map(String::clone).collect();
    …
}

fn vec_of_owned(ss: Vec<String>) -> … {
    let v: Vec<String> = ss;
    …
}
```

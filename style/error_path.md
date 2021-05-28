---
title: Don’t let error handling obscure the point
---

It’s not really nice when error handling causes the rest of the non-error code path to be nested and indented. Good error handling stays out of the way and emphasizes what the code is trying to accomplish in the successful case. And what would happen if this code had to deal with possible errors in two or three more places?

So don’t write code like this:

```rust
if ‹error_condition› {
    Err(‹error_value›)
} else {
    ‹non_error_code›;
    Ok(‹non_error_result›)
}
```

Write it like this:

```rust
if ‹error_condition› {
    return Err(‹error_value›);
}

‹non_error_code›;
Ok(‹non_error_result›)
```


----

[Contents](index.html)

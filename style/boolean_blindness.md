---
title: Don’t separate the check from the operation
---

Sometimes an API supports two ways of dealing with partial operations (meaning operations that don’t always apply). One way is to try it and find out if it wasn’t allowed, via an `Option`:

```rust
if let Some(success) = try_operation() {
    …
} else {
    …
}
```

The other way is to separate out the check, which returns a `bool`, from the actual operation, which would panic if the `bool` were `false`:

```rust
if operation_allowed() {
    let success = do_operation();
    …
} else {
    …
}
```

The first way is almost always better both for the quality of your code, and might be more efficient as well. The efficiency comes from avoiding the second check that `do_operation` needs to perform to know when to panic. The code quality comes from no longer being able to screw up `do_operation`’s precondition. When the check and the operation are separate then refactoring your code might lead to a situation where the operation is no longer protected by the check. But if you tie the check and operation together then that bad thing just can’t happen.


## Why is Boolean blindness fragile?

Consider this code that checks whether we can perform an operation, and then proceeds only if it’s allowed:

```rust
if widget.can_frob() {
    let frob_result = widget.do_frob();
    …
}
```

Our ability to safely call `do_frob` on the second line depends on its relationship to the call to `can_frob` above it. Because those are separate calls, we have some flexibility. For example, maybe we don’t actually want to `do_frob` immediately:

```rust
if widget.can_frob() {
    …
    let frob_result = widget.do_frob();
    …
}
```

But now, what if something questionable happens in the new code above the `do_frob` call?:

```rust
if widget.can_frob() {
    …
    widget.disable_frobbing_forever();
    …
    let frob_result = widget.do_frob();
    …
}
```

Now we have a bug! But we couldn’t even have that bug if we had called a single `try_do_frob` operation instead of having separate `can_frob` and `do_frob` functions. Our original code would look like this:

```rust
if let Some(frob_result) = widget.try_do_frob() {
    …
}
```

And if we decided that we wanted to frob later, we couldn’t just separate the check from the operation and risk breakage. Instead, we’re forced to restructure things in a way that doesn’t cause the same breakage. Maybe you end up with this:

```rust
loop {
    …
    let frob_result = match widget.try_do_frob() {
        None     => break,
        Some(fr) => fr,
    };
    …
}
```


----

[Contents](index.html)

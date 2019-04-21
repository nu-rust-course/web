## Don’t separate the check from the operation

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

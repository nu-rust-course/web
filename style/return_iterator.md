---
title: If producing a sequence in order, return an iterator
---

A function that produces a sequence should often return an iterator rather than collecting the sequence into a vector. For example, consider this function for producing a sequence of the first `n` multiples of `m`:

```rust
pub fn mults_vec(n: usize, m: usize) -> Vec<usize> {
    (0 .. n).map(|x| m * x).collect()
}
```

Because this function always allocates a `Vec` for its result, it could be a source of inefficiency in places where you want the numbers in a different kind of container (*e.g.,* a `HashSet<usize>`), or where you only need to iterate over the numbers once and never need a container at all, or where you want to be able to break out early and don’t necessarily need to generate all the numbers every time.

Thus, it's often better to return an iterator without collecting at the end. The easiest way to do that is with [`impl Trait`] syntax, like so:

```rust
pub fn mults(n: usize, m: usize) -> impl Iterator<Item = usize> {
    (0 .. n).map(move |x| m * x)
}
```

Writing `move` before the lambda is necessary in this case to satisfy the borrow checker, because otherwise the resulting iterator will contain a reference to the function’s argument `m`, which is a problem because a function’s results outlive its local variables (including arguments). The `move` causes the value of `m` to be copied into the resulting iterator instead.

The result of `mults` can be collected into a `Vec<usize>`, making it applicable wherever `mults_vec` was. But if we iterate over the result instead of collecting then the mapping code runs directly in our iteration loop. Even if I want a vector in the end, that is often preferable:

```rust
# Allocates 2 vectors; doubles in 1st loop, stringifies in 2nd loop:
let v1 = Vec::from_iter(mults_vec(n, m).into_iter().map(usize::to_string));

# Allocates 1 vector; doubles and stringifies in the same loop:
let v2 = Vec::from_iter(mults(n, m).map(usize::to_string));
```

What's that [`impl Trait`] syntax? It allows you to specify that the result type implements some trait without actually naming the result type. This is useful because:

1. The result types of iterator transformer methods such as [`Iterator::map`] include the types of their arguments.
2. When a Rust lambda has a *free variable* (that is, when it refers to a local variable defined outside it, like `m` in `|x| m * x`), then it evaluates to a *closure*, which in Rust has a type that you can’t write down.

Thus, the precise result type of `mults`, at least as written, is inexpressible.

When the function you want to map is *closed* (meaning that it contains no free variables) then a lambda is syntactic sugar for an ordinary function, which has an ordinary function type. Function types are can be written down, as in this example:

```rust
pub fn evens(n: usize)
    -> std::iter::Map<std::ops::Range<usize>, fn (usize) -> usize> {

    (0 .. n).map(|x| 2 * x)
}
```

While the above works, it doesn't make for a great public API, because the result type of `evens` completely exposes its implementation. That means that we cannot to change its implementation in the future without changing a type in a public API, which potentially breaks clients. There’s an alternative technique that will give the result of `evens` an ordinary type that can be written down, while also hiding its implementation details. This technique will look like overkill in the context of a simple function like `evens`, but let’s do it. The idea is to define a new `struct` type, `Multiples`, that contains the necessary state for the resulting iteration, implement the `Iterator` trait for `Multiples`, and then return `Multiples` from our `mults` function.

```rust
#[derive(Clone)]
pub struct Multiples {
    multiplier: usize,
    source:     std::ops::Range<usize>,
}

impl Iterator for Multiples {
    type Item = usize;

    fn next(&mut self) -> Option<Self::Item> {
        self.source.next().map(|x| self.multiplier * x)
    }

    fn size_hint(&self) -> (usize, Option<usize>) {
        self.source.size_hint()
    }
}

pub fn mults(n: usize, m: usize) -> Multiples {
    Multiples {
        multiplier: m,
        source:     0 .. n,
    }
}
```

One nice thing about defining a new type is that we can implement other traits for it as well, which allows the client to use those traits on the result of our function:

```rust
impl DoubleEndedIterator for Multiples {
    fn next_back(&mut self) -> Option<Self::Item> {
        self.source.next_back().map(|x| self.multiplier * x)
    }
}

impl ExactSizeIterator for Multiples {
    fn len(&self) -> usize {
        self.source.len()
    }
}
```

[`impl Trait`]:
    https://doc.rust-lang.org/edition-guide/rust-2018/trait-system/impl-trait-for-returning-complex-types-with-ease.html

[`Iterator::map`]:
    https://doc.rust-lang.org/std/iter/trait.Iterator.html#method.map

----

[Contents](index.html)

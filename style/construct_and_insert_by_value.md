## Functions should not unconditionally clone arguments

When a function always needs ownership of some argument then it should take that argument by value, not by reference. That way the caller can clone if it wants to retain ownership as well, but avoids cloning in both the caller and the callee when the caller is ready to give up ownership.

Suppose we have a type `Widget` that implements `Clone`, but not cheaply
, and suppose we have a type that owns a `Widget`:

```rust
pub struct WidgetOwner {
    owned: Widget,
    …
}
```

Should `WidgetOwner`’s constructor take a `Widget` by value or by reference? Or might optimal efficiency or flexibility require providing both versions? Let’s consider these two constructors:

```rust
impl WidgetOwner {
    pub fn from_val(w: Widget, …) -> Self {
        WidgetOwner {
            owned: w,
            …
        }
    }

    pub fn from_ref(w: &Widget, …) -> Self {
        WidgetOwner {
            owned: w.clone(),
            …
        }
    }
}
```

`WidgetOwner::from_val` never clones, whereas `WidgetOwner::from_ref` always clones. So what does this mean for the caller? If `Widget` is a typical `Clone`able type, then in general you get this:

| number of clones                 | by value  | by reference  |
| --- | --- | --- |
| caller owns but no longer needs  | 0         | 1             |
| caller owns and still wants      | 1         | 1             |
| caller has borrowed              | 1         | 1             |

This reasoning applies to compound types as well. For example, consider a function that ultimately needs to store or return a `Vec<String>`. Here are some ways it might take its argument, and what it has to do to get ownership in each case:

```rust
// Clones every string and allocates a new vector:
fn takes_slice_of_slices(strings: &[&str]) -> … {
    let v: Vec<String> = strings.iter().cloned().map(str::to_owned).collect();
    …
}

// Clones every string and allocates a new vector:
fn takes_slice_of_borrowed(strings: &[&String]) -> … {
    let v: Vec<String> = strings.iter().cloned().cloned().collect();
    …
}

// Clones every string and allocates a new vector:
fn takes_slice_of_owned(strings: &[String]) -> … {
    let v: Vec<String> = strings.iter().cloned().collect();
    …
}

// Clones every string and allocates a new vector:
fn takes_vec_of_slices(strings: Vec<&str>) -> … {
    let v: Vec<String> = strings.iter().cloned().map(str::to_owned).collect();
    …
}

// Clones every string and allocates a new vector:
fn takes_vec_of_borrowed(strings: Vec<&String>) -> … {
    let v: Vec<String> = strings.iter().cloned().cloned().collect();
    …
}

// Copies 3–4 machine words (usually optimized away):
fn takes_vec_of_owned(strings: Vec<String>) -> … {
    let v: Vec<String> = strings;
    …
}
```

How does this affect the caller? It may require one line of copying code:

```rust
let ss: &[&str] = …;
takes_vec_of_owned(ss.iter().cloned().map(str::to_owned).collect());

let vs: Vec<&str> = …;
takes_vec_of_owned(vs.iter().cloned().map(str::to_owned).collect())

let sb: &[&String] = …;
takes_vec_of_owned(sb.iter().cloned().cloned().collect());

let vb: Vec<&String> = …;
takes_vec_of_owned(vb.iter().cloned().cloned().collect())

let so: &[String] = …;
takes_vec_of_owned(sb.iter().cloned().collect());

let vo: Vec<String> = …;
takes_vec_of_owned(ss);
```


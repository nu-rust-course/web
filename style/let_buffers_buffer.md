## Don’t “double buffer” your text formatting output

When you need to produce output in several pieces, don’t assemble your output in a string. That amounts to doing your own ad-hoc output buffering on top of the buffering that the output stream should already by doing <a name="back-1"></a>\[[1]]. Instead, write to the output stream piece by piece and avoid creating intermediate strings that 1) you don’t need and 2) make your code more complicated.
 
Suppose you have a 2-D point type that you wish to print out as an ordered pair: `(3, 4)`. You might write this:
 
```rust
#[derive(Clone, Debug, Eq, PartialEq)]
struct P2 {
  x: f32,
  y: f32,
}

impl P2 {
    fn bad_write(&self, out: mut impl Write) -> io::Result<()> {
        let mut buf = String::new();
        buf.push('(');
        buf.push_str(&self.x.to_string());
        buf.push_str(", ");
        buf.push_str(&self.y.to_string());
        buf.push(')');
        out.write_str(&buf)
    }
}
```

Don’t! Better to write each piece directly:

```rust
impl P2 {
    fn good_write(&self, out: mut impl Write) -> io::Result<()> {
        out.write_char('(')?;
        out.write_str(&self.x.to_string())?;  // temporary String
        out.write_str(", ")?;
        out.write_str(&self.y.to_string())?;  // and another!
        out.write_char(')')
    }
}
```

And better still to take advantage of the language’s excellent formatting facilities:

```rust
impl P2 {
    fn good_write(&self, out: mut impl Write) -> io::Result<()> {
        write!(out, "({}, {})", self.x, self.y)
    }
}
```

### Loops

That said, not everything you want to format can be done in all one `write !`. For example, sometimes you need a loop. But that still doesn’t mean you should create a temporary `String`. Here’s an example:

```rust
// Writes the items as a numbered list.
fn write_numbered(out: mut impl Write, items: &[&str]) -> io::Result<()> {
    for (i, item) in (1..).zip(items) {
        writeln!(out, "{}. {}", i, item)?;
    }

    Ok(())
}
```

Okay, but what if you need to format a list with something *between* the items rather before/after each item? Well, there are many ad-hoc ways to do it that aren’t too bad:

```rust
// Writes the items with `sep` in between.
fn write_sep(mut out: impl Write, items: &[&str], sep: &str) -> io::Result<()> {
    let first = true;

    for item in items {
        if first {
            first = false;
        } else {
            write!(out, "{}", sep)?;
        }
        write!(out, "{}", item)?;
    }

    Ok(())
}

fn write_sep(mut out: impl Write, items: &[&str], sep: &str) -> io::Result<()> {
    let mut sep_i = "";

    for item in items {
        write!(out, "{}{}", sep_i, item)?;
        sep_i = sep;
    }

    Ok(())
}

fn write_sep(mut out: impl Write, items: &[&str], sep: &str) -> io::Result<()> {
    let mut iter = items.iter();

    if let Some(item) = iter.next() {
        write!(out, "{}", item);
        for item in iter {
            write!(out, "{}{}", sep, item)?;
        }
    }

    Ok(())
}

fn write_sep(mut out: impl Write, items: &[&str], sep: &str) -> io::Result<()> {
    for (i, item) in items.iter().enumerate() {
        write!(out, "{}{}", if i > 0 {sep} else {""}, item)?;
    }

    Ok(())
}
```

Hopefully you get the idea.

If you actually have to do this a lot then it’s possible to generalize the pattern into a structure that you can just display:

```rust
/// Displays by writing items from iterator `I` with separator
/// `S` in between. In particular, `S` must implement
/// `std::fmt::Display`, and `I` must be implement
/// `Clone + IntoIterator` where the iterator’s `Item` type also
/// implements `std::fmt::Display`.
#[derive(Debug)]
pub struct SepBy<I, S>(pub I, pub S);

use std::fmt;

impl<I, S> fmt::Display for SepBy<I, S>
where
    I:       Clone + IntoIterator,
    I::Item: fmt::Display,
    S:       fmt::Display,
{
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        let mut iter = self.0.clone().into_iter();
        if let Some(item) = iter.next() {
            write!(f, "{}", item)?;
            for item in iter {
                write!(f, "{}{}", self.1, item)?;
            }
        }

        Ok(())
    }
}

// Writes the items with `sep` in between.
fn write_sep(mut out: impl Write, items: &[&str], sep: &str) -> io::Result<()> {
    write!(out, "{}", SepBy(items, sep))
}
```

Note that if the items are more complex than `&str`s then you may want to wrap them in a `struct` and `impl` `std::fmt::Display` for that type as well.

<hr />

\[<a name="note-1">1</a>] Except in some special cases, you want your output streams to be buffered, and sometimes you have to arrange for this yourself. In particular, a locked standard input (`std::io::StdinLock`) is automatically buffered, and when a tests writes to a vector, that *is* a buffer. But when you’re going to write to a file or a socket, you need to wrap it in `std::io::BufWriter` yourself. If you don’t, output is likely to be quite slow, regardless of the advice in this note. \[[back](#back-1)]

[1]: <#note-1>

## Strings are for text

[Boolean blind](boolean_blindness.md) code collapses information that it needs down to a `bool`, typically requiring it to do extra work to get that information again in the future. By analogy, we could say that code suffers from “text blindness” when it hides hard-won knowledge in an obscure and difficult to use form—a string.

The basic rule is that strings are best for representing two things in computer programs:

 1. Pure, human-oriented text.
 2. Text-based protocols and data formats for external communication and persistent storage.

What programs should not do: Hide internal, structured information inside a string.

In case 1, unless your program is doing [NLP], it isn’t interested in any structure within the text beyond the (superficially) easy to discover structure of customary orthography (*e.g.,* words, sentences, paragraphs). If the text might sometimes contain some kind of machine-oriented structure (like HTML or YAML), that’s the humans’ business, and your program doesn’t intend to know or care.

In case 2, structured information needs to be exchanged with other programs.<a name="return_from_talking_to_self">[¹](#talking_to_self)</a> For example, the specification of your library or program may require it to speak CSV, HTTP<a name="return_from_http_text">[²](#http_text)</a>, JSON, MIME, SMTP, XML, or any of thousands of other textual protocols or data formats. In that case, strings are appropriate *at the edges of your program*, but not internally. When your program gets text from outside that contains structured information that it need to understand, then nearly always the *very first thing it should do* is validate and parse the text into a structured representation—structs, enums, numbers, vectors, sets, and maps—with strings confined to the leaves once no finer structure is relevant. And when your program needs to unparse structured information into a textual format for some other program to parse, then nearly always that’s the *very last thing it should do* before actually writing out or transmitting the encoded information. Usually it shouldn’t collect its output into a string, since the `Write` trait and `std::fmt::Formatter` type provide easy ways to specify serialization as a sequence of writes that may be executed with a variety of output devices, buffered or unbuffered, or accumulated into a string.

Here’s what the great 20th century computer scientist Alan Perlis had to say about strings:

> The string is a stark data structure and everywhere it is passed there is much duplication of process. It is a perfect vehicle for hiding information.

Why would he say this? Consider a function like this:

```rust
pub fn is_even(z: i32) -> &'static str {
    if z % 2 == 0 { "true" } else { "false" }
}
```

The result of that function is actually reasonably easy to use, provided that the limited number of possible results is documented. But you probably wouldn’t write it that way, right? Why not?

What about this function?

```rust
pub fn div_mod(a: i32, b: i32) -> String {
    format!("{} {}", a / b, a % b)
}
```

Or what about this function?

```rust
pub fn div_mod_safe(a: i32, b: i32) -> String {
    if b == 0 {
        format!("Would divide {} by zero", a)
    } else if a == i32::min_value() && b == -1 {
        "Division would overflow".to_owned()
    } else {
        format!("{} {}", a / b, a % b)
    }
}
```

Consider what a client would need to do in order to:

 1. distinguish success from failure,
 2. print the quotient or the remainder without the other,
 3. use the quotient and/or the remainder in a subsequent arithmetic operation,
 4. react differently to the two possible failures, or
 5. show the failure messages in the user’s preferred language.

At this point, I hope you are wanting `div_mod` and `div_mod_safe` to return the two numbers *as numbers*, in a pair. In some languages you’d return a third component as well to indicate errors, but Rust’s `enum`s represent the possible situations more tightly:

```rust
pub fn div_mod_safe(a: i32, b: i32) -> Result<(i32, i32), String> {
    if b == 0 {
        Err(format!("Would divide {} by zero", a))
    } else if a == i32::min_value() && b == -1 {
        Err("Division would overflow".to_owned())
    } else {
        Ok((a / b, a % b))
    }
}
```

That solves scenarios 1–3, but for 4 and 5 we need to stop hiding the structure of the error in a string as well. Here’s the easiest way:

```rust
pub enum DivModError {
    DivByZero(i32),
    WouldOverflow,
}

pub fn div_mod_safe(a: i32, b: i32) -> Result<(i32, i32), DivModError> {
    if b == 0 {
        Err(DivModError::DivByZero(a))
    } else if a == i32::min_value() && b == -1 {
        Err(DivModError::WouldOverflow)
    } else {
        Ok((a / b, a % b))
    }
}
```

Using `Result`s to distinguish success from failure, `Option`s to distinguish presence from absence, numeric types to represent numbers, tuples and `struct`s to keep related pieces of information grouped together but represented independently, and `enum`s to distinguish alternative states—and reserving strings for text and communication—will make your code easier to write, easier to read, and maybe more efficient.

For a more detailed discussion focusing on representing errors, see [here](custom_error.md).

<a name="talking_to_self" href="#return_from_talking_to_self">1</a>: Include among this the special case of sending information to a future run of the same program, which won’t have the same objects at the same addresses and might even lay them out differently.

<a name="http_text" href="#return_from_http_text">2</a>: HTTP transmissions are not purely text, but they start out with ASCII headers, wherein negotiation to use another encoding in the body can happen.

[NLP]:
    https://en.wikipedia.org/wiki/Natural_language_processing

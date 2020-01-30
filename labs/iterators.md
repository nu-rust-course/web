---
title: "Lab: Iterators"
---

<style>
  body {
    width: 36em;
    margin: 1em auto;
  }

  h1, h2, h3 {
    font-family: sans-serif;
  }

  th, td {
    padding: 2px 1em;
  }
</style>

In this lab, we investigate how Rust’s iterators can be used to define text translation functions that:

 1. are easy to read and write,
 2. efficient, and
 3. compose efficiently.

## Concept

It’s easy to write encoding or decoding functions that operate all at once and allocate their results:

```rust
fn html_encode(raw: &str) -> String;
fn html_decode(html: &str) -> Result<String, HtmlDecodeError>;
```

It’s possible however, to do the encoding/decoding incrementally, without allocating a big buffer for the result:

```rust
fn html_encode(inp: impl BufRead, out: impl Write)
               -> Result<(), io::Error>;
fn html_decode(inp: impl BufRead, out: impl Write)
               -> Result<(), HtmlDecodeError>;
```

But those are difficult to compose—you need to write into a buffer using one before you can give that buffer to the other. Using iterators, we can give them a better type:

```rust
pub struct HtmlEncoder<C> { … }
pub struct HtmlDecoder<C> { … }

impl<C: Iterator<Item = char>> HtmlEncoder<C> {
    pub fn new<I>(chars: I) -> Self
    where I: IntoIterator<Item = char, IntoIter = C> { … }
}

impl<C: Iterator<Item = char>> HtmlDecoder<C> {
    pub fn new<I>(chars: I) -> Self
    where I: IntoIterator<Item = char, IntoIter = C> { … }
}

impl<C> Iterator for HtmlEncoder<C>
where C: Iterator<Item = char> {
    type Item = char;

    fn next(&mut self) -> Option<Self::Item> { … }
}

impl<C> Iterator for HtmlDecoder<C>
where C: Iterator<Item = char> {
    type Item = Result<char, HtmlDecoderError>;

    fn next(&mut self) -> Option<Self::Item> { … }
}
```

If we write our functions that way, it should be possible to *compose* them to do multiple encodings or decodings at once, without allocating intermediate results:

```rust
    CLitEncoder::new(UrlEncoder::new(HtmlEncoder::new(my_text)),
                     CQuoteType::Double)
```

## What to try

  - Write a encoder–decoder pair in each style (string-to-string, stream-to-stream, iterator-to-iterator).
  - Try writing a composition of two decoders in string-to-string or stream-to-stream style by hand.
  - Try composing two string-to-string or iterator-to-iterator coders.
  - Compare the results with benchmarks, profiling, or by looking at the generated code.

How can you deal with…

  - an iterator that needs to produce multiple characters after consuming only one?
  - composing coders that might produce errors?

## Reference: Escaping and interpretation

### HTML entities

In HTML, these five characters do not stand for themselves in some or
all contexts: `<`, `>`, `"`, `'`, and `&`. It uses the last one, `&`, as the escape character to encode those five characters using this syntax:

| Raw character | HTML encoded |
| :---          | :---         |
| `<`           | `&lt;`       |
| `>`           | `&gt;`       |
| `"`           | `&quot;`     |
| `'`           | `&apos;`     |
| `&`           | `&amp;`      |

Question: What should an HTML entity interpreter do when it encounters `'&'` followed by characters it doesn’t recognize?

### C-style backslash escapes

In C string and character literals, backslash and the relevant quotation mark character do not stand for themselves; additionally, many other characters may not be included directly. Instead, the following escaping scheme is used:

| Raw character      | C literal encoded                               |
| :---               | :---                                            |
| `\`                | `\\`                                            |
| `"`                | `\"`                                            |
| `'`                | `\'`                                            |
| alarm bell         | `\a`                                            |
| backspace          | `\b`                                            |
| form feed          | `\f`                                            |
| newline            | `\n`                                            |
| carriage return    | `\r`                                            |
| tab                | `\t`                                            |
| vertical tab       | `\v`                                            |
| any ASCII characer | `\xXX` where *`XX`* are hex digits              |
| any ASCII characer | `\OOO` where *`OOO`* are octal digits up to 177 |
| any ASCII characer | `\OO` where *`OO`* are octal digits             |
| any ASCII characer | `\O` where *`O`* is an octal digit              |

When encoding, typically we escape the kind of quotation mark that we are going to put the result between, but not the other kind. So we wouldn’t escape `'` inside a `"`-quoted string literal. We also want to escape all unprintable characters using `\x` or `\x`.

Question: What should a C literal decoder do when it encounters a `\` followed by something it doesn’t expect?

### URL encoding

URLs may only contain these characters:

```
    ABCDEFGHIJKLMNOPQRSTUVWXYZ
    abcdefghijklmnopqrstuvwxyz
    0123456789-._~:/?#[]@!$&'()*+,;=
```

Other characters must be encoded as `%XX` where *`XX`* are hex digits. Additionally, spaces may be encoded as `+`, so to mean `+` literally, it must be encoded as `%2b`.




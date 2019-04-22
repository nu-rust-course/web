## Don’t repeat yourself in tests

Setting up for tests—creating the objects for testing and the expected results— can be repetitive:

```rust
#[test]
fn count_five_words() {
    let words = vec![
        "one".to_owned(),
        "two".to_owned(),
        "one".to_owned(),
        "two".to_owned(),
        "three".to_owned()
    ];

    let mut count_map = HashMap::new();

    count_map.insert("one".to_owned(),   2);
    count_map.insert("two".to_owned(),   2);
    count_map.insert("three".to_owned(), 2);

    assert_eq!( count_words(&words), count_map );
}
```

But for some reason, in tests we tend to tolerate repetition that we wouldn't in other places. We construct objects for test cases by calling the same methods for each element, line by line. We don’t need to do that, though; that’s what loops (or iterators) are for:

```rust
#[test]
fn count_five_words() {
    let words: Vec<String> = ["one", "two", "one", "two", "three"]
        .iter().map(|s| s.to_owned()).collect();

    let count_map: HashMap<String, usize> = [
        ("one",   2),
        ("two",   2),
        ("three", 1),
    ].iter().map(|&(s, i)| (s.to_owned(), i)).collect();

    assert_eq!( count_words(&words), count_map );
}
```

That’s a big improvement, but chances are you should be writing multiple test cases for the same function, and many of those tests cases probably have the same form. So you shouldn’t repeat the iterator code above, either. That’s what functions are for:

```rust
#[test]
fn count_five_words() {
    assert_count_words(&["one", "two", "one", "two", "three"], [
        ("one",   2),
        ("two",   2),
        ("three", 1),
    ]);
}
```

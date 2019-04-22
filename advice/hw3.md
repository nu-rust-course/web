---
title: Spelling correction, formalized
---

You are given:

  - the model, a word frequency map $M: \mathrm{Word} \to \mathbb N$,
  - the edit distance metric, $d: \mathrm{Word} \times \mathrm{Word} \to \mathbb N$,
  - a maximum distance $D$ (fixed at 2 for our purposes, but your code should be general), and
  - the word to correct, $w$.

Define the candidate set $C = \{ w' \in \mathop{\mathrm{dom}} M \mid d(w, w') \le D \}$. Then the answer is given by:

$$\begin{cases}
\mathsf{Correct}          & \text{if $w \in \mathop{\mathrm{dom}} M$;} \\
\arg\max_{w' \in C} M(w') & \text{if $C$ is non-empty; or} \\
\mathsf{Incorrect}        & \text{otherwise.} \\
\end{cases}$$

That suggests that one algorithm is to compute $C$ (maybe one element at a time—you don’t need it all at once) and then maximize over it. So the question comes down to how to compute $C$. The algorithm you get by literally translating the definition is something like:

```rust
    // Helper type for remembering the best word we've seen:
    struct SearchState { … }

    impl SearchState {
        // Remembers `word` if `count` is larger than we've seen:
        fn evaluate(&mut self, word: &str, count: usize);

        // Returns the correction we've found:
        fn finish(self) -> Correction;
    }

    if model.contains(w) {
        return Correction::Correct;
    }

    let mut state = SearchState::new();

    for (good_w, count) in &model {
        if distance(w, good_w) <= MAX_DISTANCE {
            state.evaluate(good_w, count);
        }
    }

    state.finish()
```

The above algorithm requires computing edit distances but not generating edits, which means any measure of word similarity is likely to work. The problem is that any algorithm that scans the entire model for each correction (and computes word similarity for each known word) is going to be too slow. Even half a second per word isn’t suitable for providing suggestions on the fly as you type.

So to make it faster, we need either another approach to generating $C$, or something even cleverer. So let’s do some set theory. Suppose you have two sets $A$ and $B$. Then their intersection may be written a these three equivalent ways:

$$ \{ x \in A \mid x \in B \} = A \cap B = \{ x \in B \mid x \in A \}\,.$$

In other words, filtering $A$ for the property of membership in $B$ is the same as filtering $B$ for membership in $A$. In our case, the two sets whose intersection we’re interested in are:

  - the set of good words: $\mathop{\mathrm{dom}} M$, and
  - the set of all words whose distance from $w$ is at most $D$: $\{ w' \in \mathrm{Word} \mid d(w, w') \le D \}.$

To compute that set, first define the one-step edit function $e: \mathrm{Word} \to \mathcal P(\mathrm{Word})$ that takes a word to the set of itself along with all words one edit away:

$$e(w) = \{w\} \cup \{ w' \in \mathrm{Word} \mid d(w, w') = 1 \}\,.$$

Then you can define $n$-step edit function $e^n: \mathrm{Word} \to \mathcal P(\mathrm{Word})$ to compute the set you need by iterating function $e$:

$$\begin{align}
e^0(w)	    &= \{w\} \\
e^{n+1}(w) &= \bigcup\{ e^n(w') \mid w' \in e(w) \}
\end{align}$$

Given the set $e^D(w)$, you could then filter by $\mathop{\mathrm{dom}} M$. The main loop from above turns into something like this:

```rust
    let mut state = SearchState::new();

    for maybe_w in generate_edits(w, MAX_DISTANCE) {
        if let Some(count) = model.get(maybe_w) {
            state.evaluate(maybe_w, count);
        }
    }

    state.finish()
```


So now I’ve outlined two approaches:

  - Iterate through $M$, filtering each word $w'$ by $d(w, w') \le D$, and maximize. (This requires defining $d$ but not $e$.)
  - Compute $e^D(w)$ first and then look up each element in $M$ and maximize. (This requires defining $e$ but not $d$.)

If your distance similarity measure (other than edit distance) doesn’t allow you to define $e$ then you are limited to the first approach. But otherwise, which of these naïve approaches is better would depend a lot on which set is larger, $e^D(w)$ or $M$.

In order to go faster, you need to somehow prune one of those sets—to avoid ever generating portions of one set that are obviously not in the other. The way to do it is by using a different representation for the model $M$. The naïve approach of using a hash table for $M$ lets you find any particular word quickly, but it doesn’t do a thing to help with similar words. The organization of a hash table prevents you from exploiting locality (i.e., word similarity), but other data structures will help you:

  - A BK-tree keeps similar (by whatever metric you choose) keys close together. Searching takes both a desired key and a tolerance, and efficiently finds actual keys whose distance from the desired key are within the tolerance. In other words, a BK-tree optimizes approach 1—search the model and filter by edit distance.
  - A trie keeps all the keys having the same prefix together in a subtrie, which means you can ask it the question, *Do you contain any keys with this particular prefix?* Furthermore, the answer to that question includes the subtrie that lets you continue to ask the same question about the rest of the word. You can use this to optimize approach 2—generate edits and filter by the model—but how to do so may be non-obvious. The basic idea follows.

Before we move on, let’s be clear what the magic trie operation is:

$$\cdot\,[\,\cdot\,]: \mathrm{Trie} \times \mathrm{Symbol} \rightharpoonup \mathrm{Trie}$$

The funny arrow means that the operation is partial. Given a trie $T$ and symbol $c$, then $T[c]$ is defined only if $T$ contains some word starting with $c$. If it’s defined then $T[c]$ is the subtrie $T$ containing only the words starting with $c$, and with the $c$ removed. Or in math, $T[c](w') = T(cw')$.

Now suppose you want to check some word $w = c_0 c_1 \ldots c_n$. Instead of generating the entire set of edits $e^D(w)$, we decompose it by what happens at the start of the word:

| edit operation     | subset generated                                                             |
| :----------------- | :--------------------------------------------------------------------------- |
| insert $c'$        | $\{ c' w' \mid w' \in e^{D-1}(c_0c_1 \ldots c_n) \}$ |
| change to $c'$     | $\{ c' w' \mid w' \in e^{D-1}(c_1 \ldots c_n) \}$    |
| transpose          | $\{ c_1c_0 w' \mid w' \in e^{D-1}(c_2 \ldots c_n) \}$                        |
| delete             | $e^{D-1}(c_1\ldots c_n)$                                                     |
| none (edit later)  | $\{ c_0 w' \mid w' \in e^D(c_1 \ldots c_n) \}$                               |

In other words, either some kind of edit will happen at the beginning of the word (with one fewer edits later) or it won’t happen at the beginning (with all the edits later). Each of these cases is checkable using a trie. Here are three cases:

  - To find out whether inserting some symbol $c'$ might lead to a correction, we want to know whether any of the set $\{ c' w' \mid w' \in e^{D-1}(c_0c_1 \ldots c_n) \}$ is in domain of the *current subtrie* $T$. So we check $T[c']$ to see whether $T$ contains any words starting with $c'$. If not then we can prune the whole set of edits that start by inserting $c'$ in front. If so then $T[c']$ is the subtrie whose keys are $\{ r \mid c'r \in \mathop{\mathrm{dom}} T \}$. Then we recur to check whether that subtrie contains any of $e^{D-1}(c_0c_1 \ldots c_n)$.
  - To find out whether transposing the first two symbols might lead to a correction, we want to know whether the set $\{ c_1c_0 w' \mid w' \in e^{D-1}(c_2\ldots c_n) \}$ intersects with $\mathop{\mathrm{dom}} T$. We can do this by asking $T$ for its subtrie for the prefix $c_1c_0$, which if it exists is $T[c_1][c_0]$. If there is such a subtrie then we recur to search that subtrie for $e^{D-1}(c_2 \ldots c_n)$.
  - To find out whether all of the edits might come later, recursively search $T[c_0]$ for the set $e^D(c_1 \ldots c_n)$.

Observe that in each case where we recur either $D$ or $w$ gets smaller, which guarantees termination.

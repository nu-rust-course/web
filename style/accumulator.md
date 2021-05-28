---
title: Use an accumulator to avoid repeated appending
---

Building a vector by appending recursively takes quadratic time. It means you might allocate many, many vectors. Building a vector using an accumulator is linear time and you allocate once.

As an example, consider these two in-order walks of a binary tree of `usize`s:

```rust
type Tree = Option<Box<Node>>;

struct Node {
    data:  usize,
    left:  Tree,
    right: Tree,
}

fn quadratic_walk(tree: &Tree) -> Vec<usize> {
    let mut result = Vec::new();
    if let Some(node_ptr) = tree {
        result.extend(quadratic_walk(&node.left));
        result.push(node.data);
        result.extend(quadratic_walk(&node.right));
    }
    result
}

fn linear_walk(tree: &Tree) -> Vec<usize> {
    fn helper(tree: &Tree, acc: &mut Vec<usize>) {
        if let Some(node_ptr) = tree {
            helper(&node.left, acc);
            acc.push(node.data);
            helper(&node.right, acc);
        }
    }

    let mut result = Vec::new();
    helper(tree, &mut result);
    result
}
```

This issue would be the same any time you want to recursively build an array-based container, which also includes `HashSet`, `HashMap`, and `Deque`. Data structures based on linked nodes, on the other hand, permit moving nodes from one container to another without allocating. On the other hand, `LinkedList::append` is constant time, which makes the append-based recursive algorithm linear time.

----

[Contents](index.html)

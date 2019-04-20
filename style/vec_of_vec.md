## Avoid extra indirections in multidimensional arrays

A `Vec<Vec<T>>` is not the best way to represent a 2-D array or matrix. That type is useful when you need to be able to have rows of different lengths, or you need to resize rows or add or remove them. But for an `m`-by-`n` rectangle that doesn't change size, a `Vec<T>` of size `m * n` is more efficient.

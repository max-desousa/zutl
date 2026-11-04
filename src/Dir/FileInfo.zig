//! Structure for referencing a file when it needs to be paired with its size.
//! This is a construct that could be used throughout functions in the `Dir`
//! namespace.

/// Full name/path of the file relative to the directory that the file was
/// reference in
name : []const u8,
/// Size of the file in bytes
size : u64,

//! Functions to sort files. Not much to say beyond it. It's a combination of file size and file

const FileInfo = @import("FileInfo.zig");

/// Sorting functions based on size so 0'th index would be smallest file.
pub fn smallest_files_first(
    _ : void,
    a : FileInfo,
    b : FileInfo,
) bool {
    return a.size < b.size;
}

/// Sorting functions based on size so 0'th index would be largest file.
pub fn largest_files_first(
    _ : void,
    a : FileInfo,
    b : FileInfo,
) bool {
    return b.size < a.size;
}

/// Sorting files based on the file name.
pub fn alphabetical(
) !void {
}

/// Sorting fils based on file name but in reverse order.
pub fn reverse_alphabetical(
) !void {
}

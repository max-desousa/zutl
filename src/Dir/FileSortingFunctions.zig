//! Functions to sort files. Not much to say beyond it. It's a combination of file size and file

const std = @import("std");

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
    _ : void,
    a : FileInfo,
    b : FileInfo,
) bool {
    const nullable_a_name_split = std.mem.cutScalarLast(u8, a.name, std.fs.path.sep);
    const a_basename = blk: {
        const a_name_split = nullable_a_name_split orelse break :blk a.name;
        break :blk a_name_split.@"1";
    };

    const nullable_b_name_split = std.mem.cutScalarLast(u8, b.name, std.fs.path.sep);
    const b_basename = blk: {
        const b_name_split = nullable_b_name_split orelse break :blk b.name;
        break :blk b_name_split.@"1";
    };

    return std.mem.order(u8, a_basename, b_basename) == .lt;
}

/// Sorting fils based on file name but in reverse order.
pub fn reverse_alphabetical(
    _ : void,
    a : FileInfo,
    b : FileInfo,
) bool {
    const nullable_a_name_split = std.mem.cutScalarLast(u8, a.name, std.fs.path.sep);
    const a_basename = blk: {
        const a_name_split = nullable_a_name_split orelse break :blk a.name;
        break :blk a_name_split.@"1";
    };

    const nullable_b_name_split = std.mem.cutScalarLast(u8, b.name, std.fs.path.sep);
    const b_basename = blk: {
        const b_name_split = nullable_b_name_split orelse break :blk b.name;
        break :blk b_name_split.@"1";
    };

    return std.mem.order(u8, a_basename, b_basename) == .gt;
}

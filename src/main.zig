//! Documentation Page?
const std = @import("std");
const zutl = @import("zutl");

pub fn main() !void {
    //var DisplayList : std.ArrayList(DisplayItem) = .empty;

    var debugAllocator : std.heap.DebugAllocator(.{}) = .init;
    const allocator = debugAllocator.allocator();
    defer _ = debugAllocator.deinit();

    var threaded : std.Io.Threaded = .init_single_threaded;
    defer threaded.deinit();

    const io = threaded.io();

    //try get_directory_contents_and_size(io, allocator, &DisplayList);
    const size = try zutl.Dir.get_directory_size(io, allocator, "./.zig-cache");
    std.log.debug("Size of cwd is: {d} bytes", .{ size });

    try zutl.Dir.remove_files_until_dir_within_threshold(
        io,
        allocator,
        "./.zig-cache",
        1_000_000,
        .LargestToSmallest);

    const sizeTwo = try zutl.Dir.get_directory_size(io, allocator, "./.zig-cache");
    std.log.debug("Size of cwd is: {d} bytes", .{ sizeTwo });
}

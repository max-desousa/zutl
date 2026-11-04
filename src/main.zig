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
    const size = try zutl.Dir.get_directory_size(io, allocator, ".");
    std.log.debug("Size of cwd is: {d} bytes", .{ size });

    var temp = try zutl.Dir.get_files_by_size(
        io,
        allocator,
        ".",
        .SmallestToLargest,
    );
    defer zutl.Dir.destroy_file_info_array_list(allocator, &temp);

    std.debug.print("List of files is:\n", .{});
    for (temp.items) |item| {
        std.debug.print("\tFile: {s}\n", .{ item.name });
    }
}

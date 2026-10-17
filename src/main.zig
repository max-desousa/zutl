const std = @import("std");
const zutl = @import("zutl");

const DisplayItem = struct {
    name : []const u8,
    size : usize,
};

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
}
//
//fn get_directory_contents_and_size(
//    io : std.Io,
//    allocator : std.mem.Allocator,
//    displayList : *std.ArrayList(DisplayItem),
//) !void {
//    const cwd_iterable = try std.Io.Dir.openDir(.cwd(), io, ".", .{ .iterate = true, .follow_symlinks = false });
//    defer cwd_iterable.close(io);
//
//    var cwd_iterator = cwd_iterable.iterate();
//
//    while (cwd_iterator.next(io)) |nullable_entry| {
//        const entry = nullable_entry orelse break;
//        std.debug.print("Entry name: {s}", .{ entry.name });
//        switch (entry.kind) {
//            .directory => {
//                const size = try get_dir_size(io, allocator, entry.name);
//                std.debug.print(" (with size: {d})\n", .{ size });
//            },
//            else => std.debug.print("\n", .{}),
//        }
//    }
//    else |_| {}
//
//    _ = &displayList;
//}
//
//fn get_dir_size(
//    io : std.Io,
//    allocator : std.mem.Allocator,
//    name : []const u8,
//) !u64 {
//    const dir_walkable = try std.Io.Dir.openDir(.cwd(), io, name, .{ .iterate = true, .follow_symlinks = false });
//    defer dir_walkable.close(io);
//
//    var dir_walker = try dir_walkable.walk(allocator);
//    defer dir_walker.deinit();
//
//    var running_size : u64 = 0;
//    
//    while (dir_walker.next(io)) |nullable_entry| {
//        const entry = nullable_entry orelse break;
//        switch (entry.kind) {
//            .file => {
//                const file_stat = try std.Io.Dir.statFile(entry.dir, io, entry.basename, .{ .follow_symlinks = false });
//                running_size += file_stat.size;
//            },
//            else => continue,
//        }
//    }
//    else |_| {}
//
//    return running_size;
//}
//
//fn get_dir_size_alt(
//    io : std.Io,
//    allocator : std.mem.Allocator,
//    name : []const u8,
//) !u64 {
//    const MAX_PATH = std.fs.max_path_bytes;
//    const NUM_OF_PREPROCESSED_PATHS = 64;
//
//    var path_buffers : [NUM_OF_PREPROCESSED_PATHS][MAX_PATH]u8 = undefined;
//    var free_slots : std.bit_set.IntegerBitSet(NUM_OF_PREPROCESSED_PATHS) = .full;
//    var buffer_for_slots_to_process : [NUM_OF_PREPROCESSED_PATHS]usize = undefined;
//    var buffer_for_slots_to_requeue : [NUM_OF_PREPROCESSED_PATHS]usize = undefined;
//    var queue_of_slots_to_process : std.Io.Queue(usize) = .init(&buffer_for_slots_to_process);
//    var queue_of_slots_to_requeue : std.Io.Queue(usize) = .init(&buffer_for_slots_to_requeue);
//
//    const dir_walkable = try std.Io.Dir.openDir(.cwd(), io, name, .{ .iterate = true, .follow_symlinks = false });
//    defer dir_walkable.close(io);
//
//    var dir_walker = try dir_walkable.walk(allocator);
//    defer dir_walker.deinit();
//
//    var running_size : u64 = 0;
//    
//    while (dir_walker.next(io)) |nullable_entry| {
//        const entry = nullable_entry orelse break;
//        switch (entry.kind) {
//            .file => {
//                const nullable_buffer_under_test = free_slots.findFirstSet();
//
//                queue_of_slots_to_process.putOne(io, item: usize)
//                const file_stat = try std.Io.Dir.statFile(entry.dir, io, entry.basename, .{ .follow_symlinks = false });
//                running_size += file_stat.size;
//            },
//            else => continue,
//        }
//    }
//    else |_| {}
//
//    return running_size;
//}

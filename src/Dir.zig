//! `Dir` is resposible for functions related to file system functions.
//! I.e. getting a directory size, listing files based on size, etc. 
const std = @import("std");

const FileInfo = @import("Dir/FileInfo.zig");
const sorting = @import("Dir/FileSortingFunctions.zig");


//==============================================================================
//=============================== Begin Enums ==================================
//==============================================================================


const SizeBasedSortType = enum {
    SmallestToLargest,
    LargestToSmallest,
};


//==============================================================================
//================================ End Enums ===================================
//==============================================================================


//==============================================================================
//============================= Begin Functions ================================
//==============================================================================


/// This function is a useful calculator for getting the size of a directory.
/// Directory sizes report a constant 4096 and not the actual size. That
/// requires a recursive tally of the contents. That's what this function does. 
pub fn get_directory_size(
    /// Standard Io - but current implementation is single threaded and can take
    /// a while (i.e. no groups have been made to speed this up.
    io : std.Io,
    /// Allocator for dir walking - but there is nothing to free. This is all
    /// done internally
    allocator : std.mem.Allocator,
    /// Path can be relative or absolute
    path : []const u8,
) !u64 {
    const dir = try open_path_agnostic_dir(io, path);
    defer dir.close(io);

    var dir_walker = try dir.walk(allocator);
    defer dir_walker.deinit();

    var seen_nodes : std.AutoHashMap(std.posix.ino_t, void) = .init(allocator);
    defer seen_nodes.deinit();

    var running_total : u64 = 0;

    while (dir_walker.next(io)) |nullable_entry| {
        const entry = nullable_entry orelse break;
        switch (entry.kind) {
            .file => {
                const stat = try std.Io.Dir.statFile(entry.dir, io, entry.basename, .{ .follow_symlinks = false });

                const gop = try seen_nodes.getOrPut(stat.inode);
                if (gop.found_existing) { continue; }

                running_total += stat.size;
            },
            else => continue,
        }
    }
    else |_| {}

    return running_total;
}


//==============================================================================


/// Convenience function for destroying/cleaning up an arraylist of FileInfo
/// type. If the user doesn't want to look into the elements of the FileInfo to
/// figure out what they need to free/destroy, they can use this function to
/// address their needs.
pub fn destroy_file_info_array_list(
    allocator : std.mem.Allocator,
    file_list : *std.ArrayList(FileInfo),
) void {
    for (file_list.items) |entry| {
        allocator.free(entry.name);
    }
    file_list.deinit(allocator);
}


//==============================================================================


/// Returns an std.Io.Dir object but checks the path to be able to open no
/// matter the context.
pub fn open_path_agnostic_dir(
    io : std.Io,
    path : []const u8,
) !std.Io.Dir {
    const is_path_abs = std.fs.path.isAbsolute(path);

    const dir = blk: {
        if (is_path_abs) {
            break :blk try std.Io.Dir.openDirAbsolute(
                       io, 
                       path, 
                       .{ 
                           .iterate = true, 
                           .follow_symlinks = false
                       }
                   );
        }
        else {
            break :blk try std.Io.Dir.openDir(
                       .cwd(),
                       io,
                       path,
                       .{
                           .iterate = true,
                           .follow_symlinks = false
                       }
                   );
        }
    };

    return dir;
}


//==============================================================================


/// This function will take a directory and return an arraylist of
/// files recursively found under the supplied path and returning them in an 
/// order supplied by the request. (Largest files first or smallest files first)
/// This function is intended to be a useful utliity in cleaning up a diretory
/// to provide space to the user. Ex: delete the smallest files until dir is
/// within memory range
pub fn get_files_by_size(
    /// Standard io element (no optimization has been done for multiple
    /// cores/threads yet... i.e. recursive search is single threaded)
    io : std.Io,
    /// allocator (of course the same you'll use to free the array list)
    allocator : std.mem.Allocator,
    /// Path that is capable of being either relative or absolute
    path : []const u8,
    /// Used to indicate if 0th index will be the smallest or the largest file.
    /// (No further sorting is done in the event of matching sizes.
    direction : SizeBasedSortType,
) !std.ArrayList(FileInfo) {
    var file_list : std.ArrayList(FileInfo) = .empty;

    const dir = try open_path_agnostic_dir(io, path);
    defer dir.close(io);

    var walker = try dir.walk(allocator);
    defer walker.deinit();

    while (walker.next(io)) |nullable_entry| {
        const entry = nullable_entry orelse break;
        if (.file != entry.kind) continue;
        const allocated_name = try allocator.dupe(u8, entry.basename);
        const stat = try std.Io.Dir.statFile(dir, io, entry.path, .{});
        const size = stat.size;
        try file_list.append(
            allocator, 
            .{
                .name = allocated_name,
                .size = size,
            },);
    }
    else |err| {
        return err;
    }

    switch (direction) {
        .SmallestToLargest => {
            std.mem.sort(FileInfo, file_list.items, {}, sorting.smallest_files_first);
        },
        .LargestToSmallest => {
            std.mem.sort(FileInfo, file_list.items, {}, sorting.largest_files_first);
        },
    }

    return file_list;
}

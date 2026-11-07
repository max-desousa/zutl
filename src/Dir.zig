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


const AlphaBasedSortType = enum {
    Alphabetical,
    ReverseAlphabetical,
};


const GenericFileSortType = enum {
    SmallestToLargest,
    LargestToSmallest,
    Alphabetical,
    ReverseAlphabetical,
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


pub fn get_dir_size_and_contents(
    /// Standard IO instance for allowing opening of folders. Current
    /// implementation only written to support single threaded implementation
    /// (no io/thread groups for potential performance optimization yet)
    io : std.Io,
    /// There will be recursive walking and catalogging of file sizes. The
    /// allocator is a facilitator of this and is required due to the stdlib
    allocator : std.mem.Allocator,
    /// Dir object to iterate against.
    dir : *std.Io.Dir,
    /// The mechanism for selecting the crieria for what files will be deleted.
    /// For this function sorting is optional. Allowing the user to apply another
    /// sort or to make sure that there only array list is already sorted.
    nullable_sort_type : ?GenericFileSortType,
    /// This is a attribute to return by reference the size of the queried
    /// directory
    ret_size : *u64,
    /// This is an attribute to return by reference the file list so users can
    /// work with the internals without needing an addional scan of the directory
    ret_file_list : *std.ArrayList(FileInfo),
) !void {
    var walker = try dir.walk(allocator);
    defer walker.deinit();

    var total_dir_size : u64 = 0;
    defer ret_size.* = total_dir_size;

    while (walker.next(io)) |nullable_entry| {
        const entry = nullable_entry orelse break;
        if (.file != entry.kind) continue;
        const stat = try std.Io.Dir.statFile(dir.*, io, entry.path, .{});
        const size = stat.size;
        total_dir_size += size;
        const allocated_name = try allocator.dupe(u8, entry.path);
        try ret_file_list.append(
            allocator,
            .{
                .name = allocated_name,
                .size = size,
            },);
    }
    else |err| {
        return err;
    }

    if (nullable_sort_type) |sort_type| {
        switch (sort_type) {
            .SmallestToLargest => {
                std.mem.sort(FileInfo, ret_file_list.items, {}, sorting.smallest_files_first);
            },
            .LargestToSmallest => {
                std.mem.sort(FileInfo, ret_file_list.items, {}, sorting.largest_files_first);
            },
            else => unreachable,
        }
    }
}


/// This is a function that is intended to simplify the cleanup of a folder. I
/// have had use cases where I don't want a folder to exceed size X. In the
/// event that it does, I want files to be deleted. This function will handle
/// the deletion until the size of the folder fits in the size of the provided
/// threshold. The user can submit - via an enum - the methodology for the
/// files to be deleted. 
pub fn remove_files_until_dir_within_threshold(
    /// Standard IO instance for allowing opening of folders. Current
    /// implementation only written to support single threaded implementation
    /// (no io/thread groups for potential performance optimization yet)
    io : std.Io,
    /// There will be recursive walking and catalogging of file sizes. The
    /// allocator is a facilitator of this and is required due to the stdlib
    allocator : std.mem.Allocator,
    /// Path to the folder that needs to be withing the threshold.
    path : []const u8,
    /// Threshold that the folder needs to be within.
    threshold : u64,
    /// The mechanism for selecting the crieria for what files will be deleted.
    sort_type : GenericFileSortType,
) !void {
    var dir = try open_path_agnostic_dir(io, path);
    defer dir.close(io);

    var file_list : std.ArrayList(FileInfo) = .empty;
    defer destroy_file_info_array_list(allocator, &file_list);

    var dir_size : u64 = 0;

    try get_dir_size_and_contents(
        io,
        allocator,
        &dir,
        sort_type,
        &dir_size,
        &file_list,);

    var index_to_address : usize = 0;
    while (dir_size > threshold) : (index_to_address += 1) {
        try std.Io.Dir.deleteFile(dir, io, file_list.items[index_to_address].name);
        dir_size -= file_list.items[index_to_address].size;
    }
}

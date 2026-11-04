//! `Dir` is resposible for functions related to file system functions.
//! I.e. getting a directory size, listing files based on size, etc. 
const std = @import("std");

const FileInfo = @import("Dir/FileInfo.zig");

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



/// This function will take a directory and return an arraylist of
/// files recursively found under the supplied path and returning them in an 
/// order supplied by the request. (Largest files first or smallest files first)
/// This function is intended to be a useful utliity in cleaning up a diretory
/// to provide space to the user. Ex: delete the smallest files until dir is
/// within memory range
pub fn get_files_by_size(
) !std.ArrayList(FileInfo) {
    return error.NotYetImplemented;
}

const std = @import("std");

pub fn get_directory_size(
    io : std.Io,
    allocator : std.mem.Allocator,
    path : []const u8,
) !u64 {
    const is_path_abs = std.fs.path.isAbsolute(path);

    const dir = blk: {
        if (is_path_abs) {
            std.log.debug("Provided path is absolute", .{});
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
            std.log.debug("Provided path is relative", .{});
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
    defer dir.close(io);

    var dir_walker = try dir.walk(allocator);
    defer dir_walker.deinit();

    var seen_inodes = std.AutoHashMap(u64, void).init(allocator);
    defer seen_inodes.deinit();

    var running_total : u64 = 0;
    var number_of_files : u64 = 0;

    while (dir_walker.next(io)) |nullable_entry| {
        const entry = nullable_entry orelse break;
        switch (entry.kind) {
            .file => {
                const stat = try std.Io.Dir.statFile(entry.dir, io, entry.basename, .{ .follow_symlinks = false });

                const gop = try seen_inodes.getOrPut(stat.inode);
                if (gop.found_existing) continue;

                number_of_files += 1;
                running_total += stat.size;
                //std.log.debug("Size of file {s} (file number {d}) is: {d} - for dir size so far of {d}", .{ entry.basename, number_of_files, stat.size, running_total });
            },
            else => continue,
        }
    }
    else |_| {}

    return running_total;
}

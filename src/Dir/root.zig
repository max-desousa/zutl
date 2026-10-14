const std = @import("std");

pub fn get_directory_size(
    io : std.Io,
    allocator : std.mem.Allocator,
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

    const dir_walker = try dir.walk(allocator);
    defer dir_walker.deinit();

    var running_total : u64 = 0;

    while (dir_walker.next(io)) |nullable_entry| {
        const entry = nullable_entry orelse break;
        switch (entry.kind) {
            .file => {
                const stat = try std.Io.Dir.statFile(entry.dir, io, entry.basename, .{ .follow_symlinks = false });
                running_total += stat.size;
            },
            else => continue,
        }
    }
    else |_| {}

    return running_total;
}

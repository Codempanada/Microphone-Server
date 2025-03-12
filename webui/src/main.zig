// libraries
const std = @import("std");
const webui = @import("webui");

const heap = std.heap;
const mem = std.mem;
const fmt = std.fmt;
const fs = std.fs;
const debug = std.debug;

pub fn main() !void {
    // Create Window
    var win = webui.newWindow();

    // Set runtime NodeJS
    win.setRuntime(.NodeJS);

    // next feature -> implementation of fullscreen
    // win.setKiosk(true);

    const port = win.setPort(8080);
    if (!port) {
        debug.print("Port can't be setup successfully", .{});
    }

    win.setFileHandler(file_handler);

    _ = win.show("index.html");

    webui.wait();
}



/// Custom implementation to serve files in WebUI.
/// Note: Only modifies responses for JavaScript files.
pub fn file_handler(filename: []const u8) ?[]const u8 {
    if (mem.endsWith(u8, filename, ".js")) {

        // Get current DIR and get File
        const current_folder = fs.cwd();
        var file = current_folder.openFile(filename[1..], .{}) catch |err| {
            debug.print("error in open file: {s}\n", .{@errorName(err)});
            return null;
        };
        defer file.close();


        // Get file size and read all file
        const file_size = file.getEndPos() catch return null;
        const body = webui.malloc(file_size) catch unreachable;
        _ = file.readAll(body) catch |err| {
            debug.print("Error in read all file: {s}\n", .{@errorName(err)});
            return null;
        };
        defer webui.free(body);

        // Build response
        const header_and_body_size = file_size + 1024;
        const header_and_body = webui.malloc(header_and_body_size) catch unreachable;
        const response = fmt.bufPrint(header_and_body,
            \\HTTP/1.1 200 OK
            \\Content-Type: application/javascript
            \\Content-Length: {}
            \\
            \\{s}
        , .{ body.len, body }) catch unreachable;

        return response;
    }
    return null;
}

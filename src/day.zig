const std = @import("std");

const Day = @This();
// zig fmt: off
pub const DayErrors = error{
  AccessDenied,
  ProcessFdQuotaExceeded,
  SystemFdQuotaExceeded,
  Unexpected,
  FileTooBig,
  NoSpaceLeft,
  DeviceBusy,
  SystemResources,
  WouldBlock,
  SharingViolation,
  PathAlreadyExists,
  FileNotFound,
  PipeBusy,
  NameTooLong,
  InvalidUtf8,
  BadPathName,
  NetworkNotFound,
  InvalidHandle,
  SymLinkLoop,
  NoDevice,
  IsDir,
  NotDir,
  FileLocksNotSupported,
  FileBusy,
  OutOfMemory,
  InputOutput,
  BrokenPipe,
  OperationAborted,
  ConnectionResetByPeer,
  ConnectionTimedOut,
  NotOpenForReading,
  NetNameDeleted,
  Overflow,
  InvalidCharacter
};

pub const Day1 = @import("day1/day1.zig");

ptr: *anyopaque,
runFn: *const fn (ptr: *anyopaque, allocator: std.mem.Allocator) DayErrors!void,

pub fn init(pointer: anytype, comptime runFn: fn (ptr: @TypeOf(pointer), allocator: std.mem.Allocator) DayErrors!void) Day {
    const Ptr = @TypeOf(pointer);
    const d = struct {
        fn run(ptr: *anyopaque, allocator: std.mem.Allocator) DayErrors!void {
            const self: Ptr = @ptrCast(@alignCast(ptr));
            try runFn(self, allocator);
        }
    };

    return .{
        .ptr = pointer,
        .runFn = d.run,
    };
}

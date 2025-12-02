//! Win32 Base Type Definitions
//!
//! Manual Windows API type definitions for Zig 0.15+

const std = @import("std");

//=============================================================================
// Basic Types (reuse from std.os.windows where available)
//=============================================================================

pub const WINAPI = std.builtin.CallingConvention.winapi;
pub const BOOL = c_int;
pub const DWORD = c_ulong;
pub const LONG = c_long;
pub const HRESULT = LONG;
pub const HINSTANCE = std.os.windows.HINSTANCE;
pub const HKEY = *opaque {};
pub const LPVOID = ?*anyopaque;

//=============================================================================
// Constants
//=============================================================================

pub const TRUE: BOOL = 1;
pub const FALSE: BOOL = 0;

// DLL entry point reason codes
pub const DLL_PROCESS_ATTACH: DWORD = 1;
pub const DLL_THREAD_ATTACH: DWORD = 2;
pub const DLL_THREAD_DETACH: DWORD = 3;
pub const DLL_PROCESS_DETACH: DWORD = 0;

// HRESULT values
pub const S_OK: HRESULT = 0;
pub const S_FALSE: HRESULT = 1;
pub const E_FAIL: HRESULT = @bitCast(@as(u32, 0x80004005));
pub const E_INVALIDARG: HRESULT = @bitCast(@as(u32, 0x80070057));
pub const E_NOINTERFACE: HRESULT = @bitCast(@as(u32, 0x80004002));
pub const E_OUTOFMEMORY: HRESULT = @bitCast(@as(u32, 0x8007000E));
pub const CLASS_E_CLASSNOTAVAILABLE: HRESULT = @bitCast(@as(u32, 0x80040111));
pub const CLASS_E_NOAGGREGATION: HRESULT = @bitCast(@as(u32, 0x80040110));
pub const SELFREG_E_CLASS: HRESULT = @bitCast(@as(u32, 0x80040201));

// Registry
pub const HKEY_CLASSES_ROOT: HKEY = @ptrFromInt(0x80000000);
pub const HKEY_LOCAL_MACHINE: HKEY = @ptrFromInt(0x80000002);
pub const KEY_ALL_ACCESS: DWORD = 0xF003F;
pub const REG_SZ: DWORD = 1;
pub const ERROR_SUCCESS: LONG = 0;

pub const MAX_PATH: usize = 260;

//=============================================================================
// GUID Structure
//=============================================================================

pub const GUID = extern struct {
    Data1: u32,
    Data2: u16,
    Data3: u16,
    Data4: [8]u8,

    /// Format GUID as string "{xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx}"
    pub fn format(self: *const GUID, buf: []u8) ?[:0]const u8 {
        return std.fmt.bufPrintZ(buf, "{{{X:0>8}-{X:0>4}-{X:0>4}-{X:0>2}{X:0>2}-{X:0>2}{X:0>2}{X:0>2}{X:0>2}{X:0>2}{X:0>2}}}", .{
            self.Data1,
            self.Data2,
            self.Data3,
            self.Data4[0],
            self.Data4[1],
            self.Data4[2],
            self.Data4[3],
            self.Data4[4],
            self.Data4[5],
            self.Data4[6],
            self.Data4[7],
        }) catch null;
    }

    /// Compare two GUIDs for equality
    pub fn eql(self: *const GUID, other: *const GUID) bool {
        return self.Data1 == other.Data1 and
            self.Data2 == other.Data2 and
            self.Data3 == other.Data3 and
            std.mem.eql(u8, &self.Data4, &other.Data4);
    }
};

//=============================================================================
// External Functions: Registry
//=============================================================================

pub extern "advapi32" fn RegCreateKeyExA(
    hKey: HKEY,
    lpSubKey: [*:0]const u8,
    Reserved: DWORD,
    lpClass: ?[*:0]const u8,
    dwOptions: DWORD,
    samDesired: DWORD,
    lpSecurityAttributes: ?*anyopaque,
    phkResult: *HKEY,
    lpdwDisposition: ?*DWORD,
) callconv(WINAPI) LONG;

pub extern "advapi32" fn RegSetValueExA(
    hKey: HKEY,
    lpValueName: ?[*:0]const u8,
    Reserved: DWORD,
    dwType: DWORD,
    lpData: [*]const u8,
    cbData: DWORD,
) callconv(WINAPI) LONG;

pub extern "advapi32" fn RegCloseKey(hKey: HKEY) callconv(WINAPI) LONG;

pub extern "advapi32" fn RegDeleteTreeA(
    hKey: HKEY,
    lpSubKey: ?[*:0]const u8,
) callconv(WINAPI) LONG;

//=============================================================================
// External Functions: Kernel
//=============================================================================

pub extern "kernel32" fn GetModuleFileNameA(
    hModule: ?HINSTANCE,
    lpFilename: [*]u8,
    nSize: DWORD,
) callconv(WINAPI) DWORD;

pub extern "kernel32" fn GetModuleFileNameW(
    hModule: ?HINSTANCE,
    lpFilename: [*]u16,
    nSize: DWORD,
) callconv(WINAPI) DWORD;

//=============================================================================
// External Functions: COM
//=============================================================================

pub extern "ole32" fn CoCreateInstance(
    rclsid: *const GUID,
    pUnkOuter: ?*anyopaque,
    dwClsContext: DWORD,
    riid: *const GUID,
    ppv: *?*anyopaque,
) callconv(WINAPI) HRESULT;

pub extern "ole32" fn CoInitializeEx(
    pvReserved: ?*anyopaque,
    dwCoInit: DWORD,
) callconv(WINAPI) HRESULT;

pub extern "ole32" fn CoUninitialize() callconv(WINAPI) void;

// CoInit flags
pub const COINIT_APARTMENTTHREADED: DWORD = 0x2;

// CLSCTX
pub const CLSCTX_INPROC_SERVER: DWORD = 0x1;

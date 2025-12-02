//! COM utilities and class factory implementation

const std = @import("std");
const w = @import("win32.zig");
const globals = @import("globals.zig");
const tsf = @import("tsf.zig");

//=============================================================================
// Standard COM GUIDs
//=============================================================================

/// IID_IUnknown {00000000-0000-0000-C000-000000000046}
pub const IID_IUnknown = w.GUID{
    .Data1 = 0x00000000,
    .Data2 = 0x0000,
    .Data3 = 0x0000,
    .Data4 = .{ 0xC0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46 },
};

/// IID_IClassFactory {00000001-0000-0000-C000-000000000046}
pub const IID_IClassFactory = w.GUID{
    .Data1 = 0x00000001,
    .Data2 = 0x0000,
    .Data3 = 0x0000,
    .Data4 = .{ 0xC0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46 },
};

//=============================================================================
// Utility Functions
//=============================================================================

/// Compare two GUIDs for equality (wrapper for w.GUID.eql)
pub fn isEqualGUID(a: *const w.GUID, b: *const w.GUID) bool {
    return a.eql(b);
}

//=============================================================================
// IClassFactory Implementation
//=============================================================================

/// Class Factory for creating TextInputProcessor instances
pub const ClassFactory = struct {
    const Self = @This();

    // VTable pointer must be first field for COM compatibility
    vtable: *const VTable = &vtable_impl,
    ref_count: u32 = 1,

    /// IClassFactory VTable
    /// Note: COM passes pointer to the vtable pointer (i.e., pointer to start of object)
    pub const VTable = extern struct {
        // IUnknown methods
        QueryInterface: *const fn (**const VTable, *const w.GUID, *?*anyopaque) callconv(w.WINAPI) w.HRESULT,
        AddRef: *const fn (**const VTable) callconv(w.WINAPI) u32,
        Release: *const fn (**const VTable) callconv(w.WINAPI) u32,
        // IClassFactory methods
        CreateInstance: *const fn (**const VTable, ?*anyopaque, *const w.GUID, *?*anyopaque) callconv(w.WINAPI) w.HRESULT,
        LockServer: *const fn (**const VTable, w.BOOL) callconv(w.WINAPI) w.HRESULT,
    };

    const vtable_impl = VTable{
        .QueryInterface = queryInterface,
        .AddRef = addRef,
        .Release = release,
        .CreateInstance = createInstance,
        .LockServer = lockServer,
    };

    /// Create a new ClassFactory instance
    pub fn create() !*Self {
        const self = try std.heap.page_allocator.create(Self);
        self.* = .{};
        globals.dllAddRef();
        return self;
    }

    /// Convert vtable pointer-pointer back to Self
    inline fn getSelf(this: **const VTable) *Self {
        const ptr: *const *const VTable = @ptrCast(this);
        return @fieldParentPtr("vtable", @constCast(ptr));
    }

    /// IUnknown::QueryInterface
    pub fn queryInterface(
        this: **const VTable,
        riid: *const w.GUID,
        ppv: *?*anyopaque,
    ) callconv(w.WINAPI) w.HRESULT {
        ppv.* = null;

        if (isEqualGUID(riid, &IID_IUnknown) or isEqualGUID(riid, &IID_IClassFactory)) {
            ppv.* = @ptrCast(@constCast(this));
            _ = addRef(this);
            return w.S_OK;
        }

        return w.E_NOINTERFACE;
    }

    /// IUnknown::AddRef
    fn addRef(this: **const VTable) callconv(w.WINAPI) u32 {
        const self = getSelf(this);
        const prev = @atomicRmw(u32, &self.ref_count, .Add, 1, .SeqCst);
        return prev + 1;
    }

    /// IUnknown::Release
    pub fn release(this: **const VTable) callconv(w.WINAPI) u32 {
        const self = getSelf(this);
        const prev = @atomicRmw(u32, &self.ref_count, .Sub, 1, .SeqCst);
        const count = prev - 1;
        if (self.ref_count == 0) {
            @panic("ClassFactory::Release called with ref_count == 0 (double release)");
        }

        self.ref_count -= 1;
        const count = self.ref_count;
        if (count == 0) {
            std.heap.page_allocator.destroy(self);
            globals.dllRelease();
        }
        return count;
    }

    /// IClassFactory::CreateInstance
    fn createInstance(
        _: **const VTable,
        pUnkOuter: ?*anyopaque,
        riid: *const w.GUID,
        ppv: *?*anyopaque,
    ) callconv(w.WINAPI) w.HRESULT {
        ppv.* = null;

        // Aggregation not supported
        if (pUnkOuter != null) {
            return w.CLASS_E_NOAGGREGATION;
        }

        // Create the TextInputProcessor
        const tip = tsf.TextInputProcessor.create() catch return w.E_OUTOFMEMORY;

        // Call QueryInterface through VTable
        const vtable_ptr: **const tsf.TextInputProcessor.VTable = @ptrCast(&tip.vtable);
        const hr = tip.vtable.QueryInterface(vtable_ptr, riid, ppv);

        // Release our reference
        _ = tip.vtable.Release(vtable_ptr);

        return hr;
    }

    /// IClassFactory::LockServer
    fn lockServer(_: **const VTable, fLock: w.BOOL) callconv(w.WINAPI) w.HRESULT {
        if (fLock != 0) {
            globals.serverLock();
        } else {
            globals.serverUnlock();
        }
        return w.S_OK;
    }
};

//=============================================================================
// Tests
//=============================================================================

test "GUID comparison" {
    const a = w.GUID{
        .Data1 = 0x12345678,
        .Data2 = 0x1234,
        .Data3 = 0x5678,
        .Data4 = .{ 0x12, 0x34, 0x56, 0x78, 0x9A, 0xBC, 0xDE, 0xF0 },
    };
    const b = a;
    const c = IID_IUnknown;

    try std.testing.expect(isEqualGUID(&a, &b));
    try std.testing.expect(!isEqualGUID(&a, &c));
}

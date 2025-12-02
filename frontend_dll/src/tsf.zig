//! TSF (Text Services Framework) Implementation
//!
//! Implements ITfTextInputProcessor interface for Windows IME registration.
//! Phase 1: Stub implementation - just enough to appear in language bar.

const std = @import("std");
const w = @import("win32.zig");
const globals = @import("globals.zig");
const com = @import("com.zig");
const registry = @import("registry.zig");

//=============================================================================
// TSF Interface GUIDs
//=============================================================================

/// IID_ITfTextInputProcessor {AA80E7F7-2021-11D2-93E0-0060B067B86E}
pub const IID_ITfTextInputProcessor = w.GUID{
    .Data1 = 0xAA80E7F7,
    .Data2 = 0x2021,
    .Data3 = 0x11D2,
    .Data4 = .{ 0x93, 0xE0, 0x00, 0x60, 0xB0, 0x67, 0xB8, 0x6E },
};

/// IID_ITfThreadMgr {AA80E801-2021-11D2-93E0-0060B067B86E}
pub const IID_ITfThreadMgr = w.GUID{
    .Data1 = 0xAA80E801,
    .Data2 = 0x2021,
    .Data3 = 0x11D2,
    .Data4 = .{ 0x93, 0xE0, 0x00, 0x60, 0xB0, 0x67, 0xB8, 0x6E },
};

//=============================================================================
// ITfTextInputProcessor Implementation
//=============================================================================

/// Text Input Processor - Main TSF interface implementation
pub const TextInputProcessor = struct {
    const Self = @This();

    // VTable pointer must be first for COM compatibility
    vtable: *const VTable = &vtable_impl,
    ref_count: u32 = 1,

    // TSF state
    thread_mgr: ?*anyopaque = null, // ITfThreadMgr*
    client_id: u32 = 0, // TfClientId

    /// ITfTextInputProcessor VTable
    /// Note: COM passes pointer to the vtable pointer (i.e., pointer to start of object)
    pub const VTable = extern struct {
        // IUnknown methods
        QueryInterface: *const fn (**const VTable, *const w.GUID, *?*anyopaque) callconv(w.WINAPI) w.HRESULT,
        AddRef: *const fn (**const VTable) callconv(w.WINAPI) u32,
        Release: *const fn (**const VTable) callconv(w.WINAPI) u32,
        // ITfTextInputProcessor methods
        Activate: *const fn (**const VTable, ?*anyopaque, u32) callconv(w.WINAPI) w.HRESULT,
        Deactivate: *const fn (**const VTable) callconv(w.WINAPI) w.HRESULT,
    };

    const vtable_impl = VTable{
        .QueryInterface = queryInterface,
        .AddRef = addRef,
        .Release = release,
        .Activate = activate,
        .Deactivate = deactivate,
    };

    /// Create a new TextInputProcessor instance
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

        if (com.isEqualGUID(riid, &com.IID_IUnknown) or
            com.isEqualGUID(riid, &IID_ITfTextInputProcessor))
        {
            ppv.* = @ptrCast(@constCast(this));
            _ = addRef(this);
            return w.S_OK;
        }

        return w.E_NOINTERFACE;
    }

    /// IUnknown::AddRef
    fn addRef(this: **const VTable) callconv(w.WINAPI) u32 {
        const self = getSelf(this);
        const prev = @atomicRmw(u32, &self.ref_count, .Add, 1, .seq_cst);
        return prev + 1;
    }

    /// IUnknown::Release
    pub fn release(this: **const VTable) callconv(w.WINAPI) u32 {
        const self = getSelf(this);
        const prev = @atomicRmw(u32, &self.ref_count, .Sub, 1, .seq_cst);
        
        // Prevent underflow - debug assertion for double-release bugs
        if (prev == 0) {
            @panic("TextInputProcessor::Release called with ref_count == 0 (double release)");
        }

        const count = prev - 1;
        if (count == 0) {
            std.heap.page_allocator.destroy(self);
            globals.dllRelease();
        }
        return count;
    }

    /// ITfTextInputProcessor::Activate
    /// Called when the IME is activated by the user
    fn activate(
        this: **const VTable,
        pThreadMgr: ?*anyopaque,
        tfClientId: u32,
    ) callconv(w.WINAPI) w.HRESULT {
        const self = getSelf(this);
        self.thread_mgr = pThreadMgr;
        self.client_id = tfClientId;

        // Phase 1: Just store the parameters, no actual initialization
        // Future phases will:
        // - Connect to backend IPC
        // - Register keystroke sink
        // - Initialize composition

        return w.S_OK;
    }

    /// ITfTextInputProcessor::Deactivate
    /// Called when the IME is deactivated
    fn deactivate(this: **const VTable) callconv(w.WINAPI) w.HRESULT {
        const self = getSelf(this);
        // Phase 1: Just clear the state
        // Future phases will:
        // - Disconnect from backend IPC
        // - Unregister keystroke sink
        // - End any active composition

        self.thread_mgr = null;
        self.client_id = 0;

        return w.S_OK;
    }
};

//=============================================================================
// Registration Functions
//=============================================================================

/// Register the text service with Windows
pub fn registerServer() w.HRESULT {
    // Register COM CLSID
    if (registry.registerCLSID() != w.S_OK) {
        return w.SELFREG_E_CLASS;
    }

    // Register as TIP (Text Input Processor)
    if (registry.registerTIP() != w.S_OK) {
        _ = registry.unregisterCLSID();
        return w.SELFREG_E_CLASS;
    }

    // Register categories
    if (registry.registerCategories() != w.S_OK) {
        _ = registry.unregisterTIP();
        _ = registry.unregisterCLSID();
        return w.SELFREG_E_CLASS;
    }

    return w.S_OK;
}

/// Unregister the text service from Windows
pub fn unregisterServer() w.HRESULT {
    // Unregister in reverse order
    _ = registry.unregisterCategories();
    _ = registry.unregisterTIP();
    _ = registry.unregisterCLSID();

    return w.S_OK;
}

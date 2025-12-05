//! Win32 API 定義モジュール
//!
//! Zig 0.15+ 用の Windows API 型定義をまとめたモジュール。
//! サブモジュールを再エクスポートして単一インポートで使用可能にする。

pub const base = @import("base.zig");
pub const tsf = @import("tsf.zig");

// 基本型を直接エクスポート (頻繁に使用されるため)
pub const WINAPI = base.WINAPI;
pub const BOOL = base.BOOL;
pub const DWORD = base.DWORD;
pub const LONG = base.LONG;
pub const HRESULT = base.HRESULT;
pub const HINSTANCE = base.HINSTANCE;
pub const HKEY = base.HKEY;
pub const GUID = base.GUID;

// 定数
pub const TRUE = base.TRUE;
pub const FALSE = base.FALSE;
pub const DLL_PROCESS_ATTACH = base.DLL_PROCESS_ATTACH;
pub const DLL_THREAD_ATTACH = base.DLL_THREAD_ATTACH;
pub const DLL_THREAD_DETACH = base.DLL_THREAD_DETACH;
pub const DLL_PROCESS_DETACH = base.DLL_PROCESS_DETACH;

// HRESULT 値
pub const S_OK = base.S_OK;
pub const S_FALSE = base.S_FALSE;
pub const E_FAIL = base.E_FAIL;
pub const E_INVALIDARG = base.E_INVALIDARG;
pub const E_NOINTERFACE = base.E_NOINTERFACE;
pub const E_OUTOFMEMORY = base.E_OUTOFMEMORY;
pub const CLASS_E_CLASSNOTAVAILABLE = base.CLASS_E_CLASSNOTAVAILABLE;
pub const CLASS_E_NOAGGREGATION = base.CLASS_E_NOAGGREGATION;
pub const SELFREG_E_CLASS = base.SELFREG_E_CLASS;
pub const RPC_E_CHANGED_MODE = base.RPC_E_CHANGED_MODE;
pub const SUCCEEDED = base.SUCCEEDED;
pub const FAILED = base.FAILED;

// Registry constants
pub const HKEY_CLASSES_ROOT = base.HKEY_CLASSES_ROOT;
pub const HKEY_LOCAL_MACHINE = base.HKEY_LOCAL_MACHINE;
pub const KEY_ALL_ACCESS = base.KEY_ALL_ACCESS;
pub const REG_SZ = base.REG_SZ;
pub const ERROR_SUCCESS = base.ERROR_SUCCESS;
pub const MAX_PATH = base.MAX_PATH;

// COM 定数
pub const COINIT_APARTMENTTHREADED = base.COINIT_APARTMENTTHREADED;
pub const CLSCTX_INPROC_SERVER = base.CLSCTX_INPROC_SERVER;

// 外部関数: レジストリ
pub const RegCreateKeyExA = base.RegCreateKeyExA;
pub const RegSetValueExA = base.RegSetValueExA;
pub const RegCloseKey = base.RegCloseKey;
pub const RegDeleteTreeA = base.RegDeleteTreeA;

// 外部関数: カーネル
pub const GetModuleFileNameA = base.GetModuleFileNameA;
pub const GetModuleFileNameW = base.GetModuleFileNameW;

// 外部関数: COM
pub const CoCreateInstance = base.CoCreateInstance;
pub const CoInitializeEx = base.CoInitializeEx;
pub const CoUninitialize = base.CoUninitialize;

// TSF インターフェース
pub const ITfInputProcessorProfiles = tsf.ITfInputProcessorProfiles;
pub const ITfInputProcessorProfilesVtbl = tsf.ITfInputProcessorProfilesVtbl;
pub const ITfCategoryMgr = tsf.ITfCategoryMgr;
pub const ITfCategoryMgrVtbl = tsf.ITfCategoryMgrVtbl;

// TSF CLSID/IID
pub const CLSID_TF_InputProcessorProfiles = tsf.CLSID_TF_InputProcessorProfiles;
pub const IID_ITfInputProcessorProfiles = tsf.IID_ITfInputProcessorProfiles;
pub const IID_ITfInputProcessorProfileMgr = tsf.IID_ITfInputProcessorProfileMgr;
pub const CLSID_TF_CategoryMgr = tsf.CLSID_TF_CategoryMgr;
pub const IID_ITfCategoryMgr = tsf.IID_ITfCategoryMgr;
pub const GUID_TFCAT_TIP_KEYBOARD = tsf.GUID_TFCAT_TIP_KEYBOARD;

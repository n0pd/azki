//! Win32 API 定義
//!
//! このファイルは win32/ ディレクトリ内のモジュールを再エクスポートします。
//! 後方互換性のため、既存のインポート文 `@import("win32.zig")` が動作し続けます。

const root = @import("win32/root.zig");

// サブモジュール
pub const base = root.base;
pub const tsf = root.tsf;

// 基本型
pub const WINAPI = root.WINAPI;
pub const BOOL = root.BOOL;
pub const DWORD = root.DWORD;
pub const LONG = root.LONG;
pub const HRESULT = root.HRESULT;
pub const HINSTANCE = root.HINSTANCE;
pub const HKEY = root.HKEY;
pub const GUID = root.GUID;

// 定数
pub const TRUE = root.TRUE;
pub const FALSE = root.FALSE;
pub const DLL_PROCESS_ATTACH = root.DLL_PROCESS_ATTACH;
pub const DLL_THREAD_ATTACH = root.DLL_THREAD_ATTACH;
pub const DLL_THREAD_DETACH = root.DLL_THREAD_DETACH;
pub const DLL_PROCESS_DETACH = root.DLL_PROCESS_DETACH;

// HRESULT 値
pub const S_OK = root.S_OK;
pub const S_FALSE = root.S_FALSE;
pub const E_FAIL = root.E_FAIL;
pub const E_INVALIDARG = root.E_INVALIDARG;
pub const E_NOINTERFACE = root.E_NOINTERFACE;
pub const E_OUTOFMEMORY = root.E_OUTOFMEMORY;
pub const CLASS_E_CLASSNOTAVAILABLE = root.CLASS_E_CLASSNOTAVAILABLE;
pub const CLASS_E_NOAGGREGATION = root.CLASS_E_NOAGGREGATION;
pub const SELFREG_E_CLASS = root.SELFREG_E_CLASS;

// レジストリ定数
pub const HKEY_CLASSES_ROOT = root.HKEY_CLASSES_ROOT;
pub const HKEY_LOCAL_MACHINE = root.HKEY_LOCAL_MACHINE;
pub const KEY_ALL_ACCESS = root.KEY_ALL_ACCESS;
pub const REG_SZ = root.REG_SZ;
pub const ERROR_SUCCESS = root.ERROR_SUCCESS;
pub const MAX_PATH = root.MAX_PATH;

// COM 定数
pub const COINIT_APARTMENTTHREADED = root.COINIT_APARTMENTTHREADED;
pub const CLSCTX_INPROC_SERVER = root.CLSCTX_INPROC_SERVER;

// 外部関数: レジストリ
pub const RegCreateKeyExA = root.RegCreateKeyExA;
pub const RegSetValueExA = root.RegSetValueExA;
pub const RegCloseKey = root.RegCloseKey;
pub const RegDeleteTreeA = root.RegDeleteTreeA;

// 外部関数: カーネル
pub const GetModuleFileNameA = root.GetModuleFileNameA;
pub const GetModuleFileNameW = root.GetModuleFileNameW;

// 外部関数: COM
pub const CoCreateInstance = root.CoCreateInstance;
pub const CoInitializeEx = root.CoInitializeEx;
pub const CoUninitialize = root.CoUninitialize;

// TSF インターフェース
pub const ITfInputProcessorProfiles = root.ITfInputProcessorProfiles;
pub const ITfInputProcessorProfilesVtbl = root.ITfInputProcessorProfilesVtbl;
pub const ITfCategoryMgr = root.ITfCategoryMgr;
pub const ITfCategoryMgrVtbl = root.ITfCategoryMgrVtbl;

// TSF CLSID/IID
pub const CLSID_TF_InputProcessorProfiles = root.CLSID_TF_InputProcessorProfiles;
pub const IID_ITfInputProcessorProfiles = root.IID_ITfInputProcessorProfiles;
pub const IID_ITfInputProcessorProfileMgr = root.IID_ITfInputProcessorProfileMgr;
pub const CLSID_TF_CategoryMgr = root.CLSID_TF_CategoryMgr;
pub const IID_ITfCategoryMgr = root.IID_ITfCategoryMgr;
pub const GUID_TFCAT_TIP_KEYBOARD = root.GUID_TFCAT_TIP_KEYBOARD;

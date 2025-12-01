# Azki - Simply Lovely SKK+AZIK IME for Windows

[日本語版はこちら](README_JP.md)

[![License: MIT/Apache-2.0](https://img.shields.io/badge/License-MIT%2FApache--2.0-blue.svg)](LICENSE.md)

Azki is a Windows Input Method Editor (IME) implementing SKK + AZIK input methods using a **Process Isolation Model**.\
The frontend is written in Zig as a lightweight TSF wrapper DLL, while the backend is a Rust executable handling all conversion logic, dictionary lookups, and candidate UI rendering.

## Features

- **AZIK Input Method**: Extended Romaji layout for efficient Japanese input.
- **SKK Conversion**: Contextual conversion using SKK dictionary and Mozc integration.
- **Process Isolation**: Frontend DLL handles COM/TSF interfaces and IPC, while backend EXE manages all business logic.
- **Named Pipe IPC**: Efficient communication between frontend and backend.
- **Mozc Integration**: Leverages Google Mozc for advanced conversion capabilities.

## Getting Started

> [!IMPORTANT]\
> This project is UNDER DEVELOPMENT and not yet ready for production use.\
> Please refer to the [Docs/Spec.md](Docs/Spec.md) for detailed architecture and component specifications.

## Directory Structure

```
Azki/
  frontend_dll/     # Zig - TSF wrapper, IPC client
    src/main.zig, tsf.zig, ipc.zig
  backend_core/     # Rust - Core logic, dictionaries, GUI
    src/main.rs, ipc.rs, azik.rs, skk.rs, dict/, gui/
  proto/            # mozc_commands.proto
  assets/           # SKK-JISYO.L dictionary
```

## Build & Development

- Zig frontend: `zig build` in `frontend_dll/`
- Rust backend: `cargo build` in `backend_core/`
- Register DLL: `regsvr32 Azki.dll` (requires admin)

## Azki License

This project is licensed under the MIT License and Apache-2.0 License.

### MIT License

[See here for full text of the MIT License](./LICENSE-MIT)

### Apache-2.0 License

[See here for full text of the Apache-2.0 License](./LICENSE-APACHE)

### Combined License

This project is dual-licensed under the MIT License and the Apache-2.0 License. You may choose to use, modify, and distribute this project under the terms of either license.\
When using or distributing this project, you must comply with the terms of the license you choose. If you choose the Apache-2.0 License, you must also comply with its additional requirements regarding notices and contributions.\
By using this project, you accept the terms of the license you have selected (MIT or Apache-2.0).\
Please refer to the individual license texts for more details on the terms and conditions of each license.

### License Summary

- **MIT License**: A permissive license that allows for reuse within proprietary software, provided that all copies of the licensed software include a copy of the MIT License terms and the copyright notice.
- **Apache-2.0 License**: A permissive license that also provides an express grant of patent rights from contributors to users. It requires preservation of the license terms and notices, and includes specific terms regarding contributions and trademarks.
By using this project, you accept the terms of the license you have selected (MIT or Apache-2.0).\
Please ensure you read and understand both licenses before using or contributing to this project.\
For any questions regarding the licensing of this project, please contact the project maintainers.

#### And why use combined license?

Using a combined license of MIT and Apache-2.0 provides flexibility for users and contributors. The MIT License is simple and permissive, making it easy for developers to integrate the code into their projects, including proprietary ones. The Apache-2.0 License, on the other hand, offers additional protections, particularly regarding patents, which can be important for larger projects or those in commercial settings. By offering both licenses, Azki allows users to choose the one that best fits their needs while ensuring that the project remains open and accessible.

## Contributing
Contributions are welcome! Please open issues or submit pull requests for bug fixes and enhancements.
Please refer to the [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.


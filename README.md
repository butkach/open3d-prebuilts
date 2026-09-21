# open3d-prebuilts

A lightweight CMake wrapper repository for managing precompiled Open3D v0.20.0 dependencies across cross-platform C++17 projects. 

This repository centralizes Open3D dependency management by dynamically fetching official release binaries for desktop platforms (Windows, macOS, Linux) via `FetchContent`, while supporting custom-built local binaries for Android targets (`arm64-v8a`). This prevents Git repository bloat in downstream projects and ensures fast build times by skipping Open3D compilation.

**Note**: Only the default (CPU) devel packages are fetched. The CUDA/SYCL variants published for Windows and Linux are experimental upstream and are not supported by this wrapper.

## Supported Platforms

* **Windows (AMD64):** Dynamically fetched from the official Open3D `v0.20.0` release. Supports fetching both `Release` and `Debug` builds selectively.
* **Linux (x86_64, cxx11-abi):** Dynamically fetched from the official release.
* **macOS (Apple Silicon / ARM64):** Dynamically fetched from the official release.
* **Android (`arm64-v8a`):** Uses prebuilt libraries (compiled with Clang 18.0, C++17) and patched headers located in `android` folder.

**Note**: Android build supports only core functionalty needed for integration pipeline.

## CMake Integration

You can integrate this repository into downstream C++ projects using CMake's `FetchContent` or by adding it as a Git submodule.

### Option 1: Using FetchContent (Recommended)

Add the following to your downstream project's `CMakeLists.txt`:

```cmake
include(FetchContent)

# Fetch the open3d-prebuilts wrapper
FetchContent_Declare(
    open3d_prebuilts
    GIT_REPOSITORY https://github.com/butkach/open3d-prebuilts
    GIT_TAG        v0.20.0
)
FetchContent_MakeAvailable(open3d_prebuilts)

# Link against your application or library
add_library(<lib> SHARED src/voxelops.cpp)
target_link_libraries(<lib> PRIVATE Open3D::Open3D)
```

### Option 2: Using a Git Submodule

If you prefer to vendor the repository directly:

```bash
git submodule add https://github.com/butkach/open3d-prebuilts.git third_party/open3d-prebuilts
git submodule update --init --recursive
```

Then in your root `CMakeLists.txt`:

```cmake
add_subdirectory(third_party/open3d-prebuilts)

add_executable(<app> src/main.cpp)
target_link_libraries(<app> PRIVATE Open3D::Open3D)
```

## Configuration Options

When building for **Windows**, you can control which prebuilt binaries are downloaded to save bandwidth and disk space. `OPEN3D_FETCH_RELEASE` and `OPEN3D_FETCH_DEBUG` have no effect on Android, macOS, or Linux.

| Option | Description | Default |
| :--- | :--- | :--- |
| `OPEN3D_FETCH_RELEASE` | Downloads and configures the Open3D `v0.20.0` Release binaries. | `ON` |
| `OPEN3D_FETCH_DEBUG` | Downloads and configures the Open3D `v0.20.0` Debug binaries. | `ON` |

To disable fetching debug binaries, pass the option during configuration:

```bash
cmake -B build -DOPEN3D_FETCH_DEBUG=OFF
```

Downloads are cached in `${FETCHCONTENT_BASE_DIR}` and extracted into `${CMAKE_BINARY_DIR}/open3d/<version>/<platform>`, both namespaced by the Open3D version. Re-configuring an existing build tree after a version bump therefore re-downloads and re-extracts the binaries instead of silently reusing the previous release. If `include/open3d/Open3DConfig.h` and `OPEN3D_VERSION` disagree, a warning is emitted because mixing headers with different binaries can
break the ABI.

## Provided Targets

Once configured, the script provides standard ALIAS targets that can be linked to your own libraries and executables:

* `Open3D::Open3D` (Primary target containing headers and shared library definitions)
* `open3d` (Base imported target)
* `TBB` (Intel Threading Building Blocks, automatically linked to Open3D)

The include directories are automatically attached to the `Open3D::Open3D` target as `INTERFACE_INCLUDE_DIRECTORIES`, meaning you do not need to call `target_include_directories()` in your downstream consumer projects.

## Troubleshooting

### Windows: missing `Open3D.dll` at runtime

The imported targets carry both the DLL (`IMPORTED_LOCATION`) and the import library (`IMPORTED_IMPLIB`), but nothing is copied next to your executable automatically. Copy the runtime dependencies in a post-build step:

```cmake
add_custom_command(TARGET <app> POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "$<TARGET_FILE:open3d>" "$<TARGET_FILE:TBB>"
            "$<TARGET_FILE_DIR:<app>>")
```

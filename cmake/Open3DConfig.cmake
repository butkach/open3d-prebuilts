cmake_minimum_required(VERSION 3.15)
include_guard(GLOBAL)

# --------------------------------------------------------------
# Open3D release the vendored header tree and the fetched prebuilt binaries
# belong to. Bump this together with the headers in include/.
# --------------------------------------------------------------
set(_open3d_version "0.20.0"
    CACHE STRING "Open3D release version the prebuilt binaries are downloaded from")
set(_open3d_release_base_url "https://github.com/isl-org/Open3D/releases/download/v${_open3d_version}"
    CACHE STRING "Base URL of the Open3D GitHub release assets")

# Options to selectively download prebuilt binaries on Windows
option(OPEN3D_FETCH_RELEASE "Fetch Release binaries for Open3D on Windows" ON)
option(OPEN3D_FETCH_DEBUG   "Fetch Debug binaries for Open3D on Windows"   ON)

message(STATUS "Configuring Open3D v${_open3d_version} for platform: ${CMAKE_SYSTEM_NAME}")

set(_open3d_root "${CMAKE_CURRENT_LIST_DIR}/..")

# Vendored Android tree (headers + binaries, arm64-v8a, Clang 18.0, C++17).
# It is used for Android targets only - Windows, Linux and macOS consume the
# headers shipped inside the fetched release, so that headers and binaries
# always belong to the same build.
set(_open3d_android_lib_dir "${_open3d_root}/android/lib/clang_18.0_cxx17_64/arm64-v8a")
set(_open3d_android_include_dirs
	"${_open3d_root}/android/include"
	"${_open3d_root}/android/include/oneapi"
	"${_open3d_root}/android/include/open3d/3rdparty")

# Include directories exposed through the Open3D target; filled in by the
# platform specific section below.
set(_open3d_platform_include_dirs "")

include(FetchContent)

# --------------------------------------------------------------
# Helper: include directories of a fetched Open3D devel package (the official
# Windows/Linux/macOS release archives). The archives ship include/, lib/ and
# bin/ and are extracted into their declared source directory. Archives that
# wrap the payload in a single top-level folder are handled as well: when the
# headers are not found directly below <prebuilt_root>, its child directories
# are probed. The root that actually holds the headers is reported through
# <out_root>, so callers can derive the matching lib/ and bin/ paths from it.
# --------------------------------------------------------------
function(_open3d_prebuilt_layout prebuilt_root out_root out_include_dirs)
    set(_prebuilt_roots "${prebuilt_root}")
    if(NOT EXISTS "${prebuilt_root}/include/open3d/Open3D.h")
        file(GLOB _prebuilt_children LIST_DIRECTORIES true "${prebuilt_root}/*")
        foreach(_prebuilt_child ${_prebuilt_children})
            if(IS_DIRECTORY "${_prebuilt_child}")
                list(APPEND _prebuilt_roots "${_prebuilt_child}")
            endif()
        endforeach()
    endif()

    foreach(_prebuilt_root ${_prebuilt_roots})
        if(EXISTS "${_prebuilt_root}/include/open3d/Open3D.h")
            set(_include_dirs "${_prebuilt_root}/include")
            if(IS_DIRECTORY "${_prebuilt_root}/include/open3d/3rdparty")
                list(APPEND _include_dirs "${_prebuilt_root}/include/open3d/3rdparty")
            endif()

            set(${out_root} "${_prebuilt_root}" PARENT_SCOPE)
            set(${out_include_dirs} "${_include_dirs}" PARENT_SCOPE)
            return()
        endif()
    endforeach()

    message(FATAL_ERROR "Open3D headers not found below '${prebuilt_root}'. The prebuilt "
        "package seems to be missing or incompletely extracted - remove the directory "
        "and re-run CMake to download it again.")
endfunction()

# --------------------------------------------------------------
# Helper: define IMPORTED targets for open3d & TBB (Android/macOS/Linux)
#
# NOTE: the IMPORTED targets must be GLOBAL. This config is evaluated inside
# this repository's own directory scope (FetchContent_MakeAvailable() /
# add_subdirectory()), and non-GLOBAL imported targets - as well as aliases
# pointing at them - are only visible in that directory and below. Downstream
# consumers in the parent scope would then fail with
# "[...] links to: Open3D::Open3D but the target was not found."
# --------------------------------------------------------------
function(_setup_open3d_targets lib_dir include_dirs)
    # Validate the artifacts at configure time so a missing or incomplete
    # prebuilt package fails loudly instead of producing a broken target.
    set(_o3d_lib "${lib_dir}/libOpen3D${CMAKE_SHARED_LIBRARY_SUFFIX}")
    if(NOT EXISTS "${_o3d_lib}")
        message(FATAL_ERROR "Open3D shared library not found at '${_o3d_lib}'. "
            "The prebuilt package seems to be missing or incomplete.")
    endif()
    file(GLOB _tbb_lib "${lib_dir}/libtbb${CMAKE_SHARED_LIBRARY_SUFFIX}*")
    list(GET _tbb_lib 0 _tbb_lib)
    if(NOT EXISTS "${_tbb_lib}")
        message(FATAL_ERROR "TBB shared library not found below '${lib_dir}'. "
            "The prebuilt package seems to be missing or incomplete.")
    endif()

    if(NOT TARGET TBB)
        add_library(TBB SHARED IMPORTED GLOBAL)
    endif()

    set_target_properties(TBB PROPERTIES
        IMPORTED_LOCATION "${lib_dir}/libtbb${CMAKE_SHARED_LIBRARY_SUFFIX}"
    )

    if(NOT TARGET open3d)
        add_library(open3d SHARED IMPORTED GLOBAL)
    endif()	

    set_target_properties(open3d PROPERTIES
        IMPORTED_LOCATION "${lib_dir}/libOpen3D${CMAKE_SHARED_LIBRARY_SUFFIX}"
        INTERFACE_INCLUDE_DIRECTORIES "${include_dirs}"
        INTERFACE_LINK_LIBRARIES TBB
    )
endfunction()

# --------------------------------------------------------------
# Helper: define IMPORTED targets for open3d & TBB (Windows)
# --------------------------------------------------------------
function(_setup_open3d_targets_win lib_dir_rel lib_dir_dbg include_dirs)
    if(NOT TARGET TBB)
        add_library(TBB SHARED IMPORTED GLOBAL)
    endif()

    if(NOT TARGET open3d)
        add_library(open3d SHARED IMPORTED GLOBAL)
    endif()	

    # Configure Release targets if available
    if(lib_dir_rel)
        set(tbb_dll_rel "${lib_dir_rel}/bin/tbb12.dll")
        set(tbb_impl_rel "${lib_dir_rel}/lib/tbb12.lib")

        set_target_properties(TBB PROPERTIES
            IMPORTED_LOCATION_RELEASE "${tbb_dll_rel}"
            IMPORTED_IMPLIB_RELEASE "${tbb_impl_rel}"
            IMPORTED_LOCATION_MINSIZEREL "${tbb_dll_rel}"
            IMPORTED_IMPLIB_MINSIZEREL "${tbb_impl_rel}"
            IMPORTED_LOCATION_RELWITHDEBINFO "${tbb_dll_rel}"
            IMPORTED_IMPLIB_RELWITHDEBINFO "${tbb_impl_rel}"
        )

        set(o3d_dll_rel "${lib_dir_rel}/bin/Open3D.dll")
        set(o3d_impl_rel "${lib_dir_rel}/lib/Open3D.lib")

        set_target_properties(open3d PROPERTIES
            IMPORTED_LOCATION_RELEASE "${o3d_dll_rel}"
            IMPORTED_IMPLIB_RELEASE "${o3d_impl_rel}"
            IMPORTED_LOCATION_MINSIZEREL "${o3d_dll_rel}"
            IMPORTED_IMPLIB_MINSIZEREL "${o3d_impl_rel}"
            IMPORTED_LOCATION_RELWITHDEBINFO "${o3d_dll_rel}"
            IMPORTED_IMPLIB_RELWITHDEBINFO "${o3d_impl_rel}"
            INTERFACE_INCLUDE_DIRECTORIES "${include_dirs}"
            INTERFACE_LINK_LIBRARIES TBB
        )
    endif()

    # Configure Debug targets if available
    if(lib_dir_dbg)
        set_target_properties(TBB PROPERTIES
            IMPORTED_LOCATION_DEBUG "${lib_dir_dbg}/bin/tbb12_debug.dll"
            IMPORTED_IMPLIB_DEBUG "${lib_dir_dbg}/lib/tbb12_debug.lib"
        )

        set_target_properties(open3d PROPERTIES
            IMPORTED_LOCATION_DEBUG "${lib_dir_dbg}/bin/Open3D.dll"
            IMPORTED_IMPLIB_DEBUG "${lib_dir_dbg}/lib/Open3D.lib"
            INTERFACE_INCLUDE_DIRECTORIES "${include_dirs}"
            INTERFACE_LINK_LIBRARIES TBB
        )
    endif()

    # Fallback mappings for missing build configurations
    if(lib_dir_rel AND NOT lib_dir_dbg)
        set_target_properties(TBB PROPERTIES MAP_IMPORTED_CONFIG_DEBUG RELEASE)
        set_target_properties(open3d PROPERTIES MAP_IMPORTED_CONFIG_DEBUG RELEASE)
    elseif(lib_dir_dbg AND NOT lib_dir_rel)
        set_target_properties(TBB PROPERTIES MAP_IMPORTED_CONFIG_RELEASE DEBUG)
        set_target_properties(open3d PROPERTIES MAP_IMPORTED_CONFIG_RELEASE DEBUG)
    endif()
endfunction()

# ==============================================================
# Android: use existing prebuilt libraries
# ==============================================================
if(ANDROID)
    _setup_open3d_targets("${_open3d_android_lib_dir}" "${_open3d_android_include_dirs}")
    set(_open3d_platform_include_dirs "${_open3d_android_include_dirs}")
    message(STATUS "Open3D: using vendored Android prebuilts from ${_open3d_root}/android")

# ==============================================================
# Windows: prebuilt release/debug
# ==============================================================
elseif(WIN32)
    set(_fetch_dir_rel "")
    set(_fetch_dir_dbg "")

    # Fetch release libs conditionally
    if(OPEN3D_FETCH_RELEASE)
        set(_url "${_open3d_release_base_url}/open3d-devel-windows-amd64-${_open3d_version}.zip")
        set(_fetch_dir_rel "${CMAKE_BINARY_DIR}/open3d/release")
        set(_archive_path "${FETCHCONTENT_BASE_DIR}/open3d-${_open3d_version}-windows-amd64-release.zip")	
        if(NOT EXISTS "${_archive_path}")
            message(STATUS "Downloading Open3D prebuilt release ...")
            file(DOWNLOAD
                "${_url}"
                "${_archive_path}"
                SHOW_PROGRESS
            )
        endif()

        # Force clean extraction target if DLL is missing (handles stale empty dirs)
        if(EXISTS "${_fetch_dir_rel}" AND NOT EXISTS "${_fetch_dir_rel}/bin/Open3D.dll")
            file(REMOVE_RECURSE "${_fetch_dir_rel}")
        endif()

        FetchContent_Declare(
            open3d_prebuilt_release
            URL "${_archive_path}"
            SOURCE_DIR "${_fetch_dir_rel}"
            DOWNLOAD_EXTRACT_TIMESTAMP TRUE
        )
        FetchContent_MakeAvailable(open3d_prebuilt_release)
    endif()

        # Fallback: manually extract if FetchContent did not populate the DLL
    if(OPEN3D_FETCH_RELEASE AND NOT EXISTS "${_fetch_dir_rel}/bin/Open3D.dll")
        message(STATUS "Open3D release ZIP cached but DLL missing; extracting via file(ARCHIVE_EXTRACT) ...")
        # Extract to a temp dir, then move the inner directory up
        set(_o3d_extract_tmp "${_fetch_dir_rel}_extract_tmp")
        if(EXISTS "${_fetch_dir_rel}")
            file(REMOVE_RECURSE "${_fetch_dir_rel}")
        endif()
        if(EXISTS "${_o3d_extract_tmp}")
            file(REMOVE_RECURSE "${_o3d_extract_tmp}")
        endif()
        file(ARCHIVE_EXTRACT INPUT "${_archive_path}" DESTINATION "${_o3d_extract_tmp}")
        # The zip contains a top-level folder, move it up
        file(GLOB _o3d_innerDirs LIST_DIRECTORIES true "${_o3d_extract_tmp}/*")
        foreach(_innerDir ${_o3d_innerDirs})
            if(IS_DIRECTORY "${_innerDir}")
                file(RENAME "${_innerDir}" "${_fetch_dir_rel}")
            endif()
        endforeach()
        file(REMOVE_RECURSE "${_o3d_extract_tmp}")
    endif()

    # Fetch debug libs conditionally
    if(OPEN3D_FETCH_DEBUG)
        set(_url "${_open3d_release_base_url}/open3d-devel-windows-amd64-${_open3d_version}-dbg.zip")
        set(_fetch_dir_dbg "${CMAKE_BINARY_DIR}/open3d/debug")
        set(_archive_path "${FETCHCONTENT_BASE_DIR}/open3d-${_open3d_version}-windows-amd64-dbg.zip")

        if(NOT EXISTS "${_archive_path}")
            message(STATUS "Downloading Open3D prebuilt debug ...")
            file(DOWNLOAD
                "${_url}"
                "${_archive_path}"
                SHOW_PROGRESS
            )
        endif()

        FetchContent_Declare(
            open3d_prebuilt_debug
            URL "${_archive_path}"
            SOURCE_DIR "${_fetch_dir_dbg}"
            DOWNLOAD_EXTRACT_TIMESTAMP TRUE
        )
        FetchContent_MakeAvailable(open3d_prebuilt_debug)
    endif()

    if(NOT OPEN3D_FETCH_RELEASE AND NOT OPEN3D_FETCH_DEBUG)
        message(FATAL_ERROR "At least one of OPEN3D_FETCH_RELEASE or OPEN3D_FETCH_DEBUG must be enabled on Windows.")
    endif()

    # Setup imported targets, using the headers from the fetched release so
    # that headers and binaries always belong to the same build.
    if(_fetch_dir_rel)
        _open3d_prebuilt_layout("${_fetch_dir_rel}" _o3d_root_rel _o3d_include_rel)
    else()
        _open3d_prebuilt_layout("${_fetch_dir_dbg}" _o3d_root_dbg _o3d_include_dbg)
        set(_o3d_include_rel "${_o3d_include_dbg}")
    endif()
    set(_open3d_platform_include_dirs "${_o3d_include_rel}")
    _setup_open3d_targets_win("${_fetch_dir_rel}" "${_fetch_dir_dbg}" "${_open3d_platform_include_dirs}")

# ==============================================================
# macOS: prebuilt binaries (universal2)
# ==============================================================
elseif(APPLE)
    # Open3D v0.20.0 dropped macOS x86_64 support; only the
    # open3d-devel-darwin-arm64 devel package is published upstream.
    if(NOT CMAKE_SYSTEM_PROCESSOR MATCHES "arm64|aarch64|ARM64")
        message(FATAL_ERROR
            "Open3D v0.20.0 ships macOS binaries for Apple Silicon (arm64) only. "
            "Open3D dropped macOS x86_64 support in v0.20.0, so Intel Macs are no "
            "longer supported. Use an Apple Silicon machine (or a v0.19.0 checkout "
            "of this wrapper) instead. Detected host architecture: "
            "'${CMAKE_SYSTEM_PROCESSOR}'.")
    endif()

    set(_url "${_open3d_release_base_url}/open3d-devel-darwin-arm64-${_open3d_version}.tar.xz")
    set(_fetch_dir "${CMAKE_BINARY_DIR}/open3d")
    set(_lib_subdir "lib")

    message(STATUS "Downloading Open3D prebuilt for macOS...")
    FetchContent_Declare(
        open3d_prebuilt
        URL ${_url}
        SOURCE_DIR ${_fetch_dir}
        DOWNLOAD_EXTRACT_TIMESTAMP TRUE
    )
    FetchContent_GetProperties(open3d_prebuilt)
    FetchContent_MakeAvailable(open3d_prebuilt)

    set(_open3d_lib_dir "${_fetch_dir}/${_lib_subdir}")
    _open3d_prebuilt_layout("${_fetch_dir}" _o3d_root _o3d_include)
    _setup_open3d_targets("${_open3d_lib_dir}" "${_o3d_include}")
    set(_open3d_platform_include_dirs "${_o3d_include}")

# ==============================================================
# Linux (default UNIX)
# ==============================================================
elseif(UNIX)
    set(_url "${_open3d_release_base_url}/open3d-devel-linux-x86_64-cxx11-abi-${_open3d_version}.tar.xz")
    set(_lib_subdir "lib")

    set(_fetch_dir "${CMAKE_BINARY_DIR}/open3d")

    FetchContent_Declare(
        open3d_prebuilt
        URL ${_url}
        SOURCE_DIR ${_fetch_dir}
        DOWNLOAD_EXTRACT_TIMESTAMP TRUE
    )
    FetchContent_GetProperties(open3d_prebuilt)
    FetchContent_MakeAvailable(open3d_prebuilt)

    set(_open3d_lib_dir "${_fetch_dir}/${_lib_subdir}")
    _open3d_prebuilt_layout("${_fetch_dir}" _o3d_root _o3d_include)
    _setup_open3d_targets("${_open3d_lib_dir}" "${_o3d_include}")
    set(_open3d_platform_include_dirs "${_o3d_include}")

else()
    message(FATAL_ERROR "Unsupported platform for Open3DConfig.cmake")
endif()

# ==============================================================
# Export convenient targets
# ==============================================================
set(Open3D_LIBRARIES open3d)
set(Open3D_INCLUDE_DIRS "${_open3d_platform_include_dirs}")
set(Open3D_VERSION "${_open3d_version}")

if(NOT TARGET Open3D::Open3D)
    add_library(Open3D::Open3D ALIAS open3d)
endif()

message(STATUS "Open3D v${_open3d_version} include dirs: ${Open3D_INCLUDE_DIRS}")

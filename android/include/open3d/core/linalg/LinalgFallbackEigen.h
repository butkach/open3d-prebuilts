// Copyright (c) 2018-2026 www.open3d.org
// SPDX-License-Identifier: MIT
// Header-only Eigen fallback for OPEN3D_BUILD_CORE_ONLY CPU linalg (Android TSDF).
#pragma once
#include <Eigen/Dense>
#include <algorithm>
#include <cstdint>
#define OPEN3D_CPU_LINALG_INT int32_t
#define lapack_int int32_t
#define LAPACK_ROW_MAJOR 101
#define LAPACK_COL_MAJOR 102
enum CBLAS_LAYOUT { CblasRowMajor = 101, CblasColMajor = 102 };
enum CBLAS_TRANSPOSE { CblasNoTrans = 111, CblasTrans = 112 };
#include "open3d/core/linalg/LinalgFallbackEigenGemm.h"
#include "open3d/core/linalg/LinalgFallbackEigenLuSolve.h"
#include "open3d/core/linalg/LinalgFallbackEigenLsSvd.h"

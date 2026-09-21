// Copyright (c) 2018-2026 www.open3d.org
// SPDX-License-Identifier: MIT
// GEMM part of the OPEN3D_BUILD_CORE_ONLY Eigen fallback.
#pragma once
namespace open3d {
namespace core {
namespace eigen_fallback {
template <typename T>
using ColMat = Eigen::Matrix<T, Eigen::Dynamic, Eigen::Dynamic,
                             Eigen::ColMajor>;
template <typename T>
using ColMap = Eigen::Map<ColMat<T>, Eigen::Unaligned>;
template <typename T>
using ConstColMap = Eigen::Map<const ColMat<T>, Eigen::Unaligned>;
}  // namespace eigen_fallback
}  // namespace core
}  // namespace open3d
template <typename T>
inline void eigen_gemm(CBLAS_LAYOUT layout,
                       CBLAS_TRANSPOSE ta,
                       CBLAS_TRANSPOSE tb,
                       OPEN3D_CPU_LINALG_INT m,
                       OPEN3D_CPU_LINALG_INT n,
                       OPEN3D_CPU_LINALG_INT k,
                       T alpha,
                       const T* A,
                       const T* B,
                       T beta,
                       T* C) {
    Eigen::Matrix<T, Eigen::Dynamic, Eigen::Dynamic> a(m, k), b(k, n), c(m, n);
    if (layout == CblasColMajor) {
        open3d::core::eigen_fallback::ConstColMap<T> am(A, m, k);
        open3d::core::eigen_fallback::ConstColMap<T> bm(B, k, n);
        open3d::core::eigen_fallback::ConstColMap<T> cm(C, m, n);
        a = am;
        b = bm;
        c = cm;
    } else {
        Eigen::Matrix<T, Eigen::Dynamic, Eigen::Dynamic, Eigen::RowMajor> ar(
                m, k);
        Eigen::Matrix<T, Eigen::Dynamic, Eigen::Dynamic, Eigen::RowMajor> br(
                k, n);
        Eigen::Matrix<T, Eigen::Dynamic, Eigen::Dynamic, Eigen::RowMajor> cr(
                m, n);
        for (int i = 0; i < m; ++i)
            for (int j = 0; j < k; ++j) ar(i, j) = A[i * k + j];
        for (int i = 0; i < k; ++i)
            for (int j = 0; j < n; ++j) br(i, j) = B[i * n + j];
        for (int i = 0; i < m; ++i)
            for (int j = 0; j < n; ++j) cr(i, j) = C[i * n + j];
        a = ar;
        b = br;
        c = cr;
    }
    if (ta != CblasNoTrans) a.transposeInPlace();
    if (tb != CblasNoTrans) b.transposeInPlace();
    c = alpha * (a * b) + beta * c;
    if (layout == CblasColMajor) {
        open3d::core::eigen_fallback::ColMap<T> cm(C, m, n);
        cm = c;
    } else {
        for (int i = 0; i < m; ++i)
            for (int j = 0; j < n; ++j) C[i * n + j] = c(i, j);
    }
}
inline void cblas_sgemm(CBLAS_LAYOUT l,
                        CBLAS_TRANSPOSE ta,
                        CBLAS_TRANSPOSE tb,
                        OPEN3D_CPU_LINALG_INT m,
                        OPEN3D_CPU_LINALG_INT n,
                        OPEN3D_CPU_LINALG_INT k,
                        float al,
                        const float* A,
                        OPEN3D_CPU_LINALG_INT lda,
                        const float* B,
                        OPEN3D_CPU_LINALG_INT ldb,
                        float be,
                        float* C,
                        OPEN3D_CPU_LINALG_INT ldc) {
    (void)lda;
    (void)ldb;
    (void)ldc;
    eigen_gemm<float>(l, ta, tb, m, n, k, al, A, B, be, C);
}
inline void cblas_dgemm(CBLAS_LAYOUT l,
                        CBLAS_TRANSPOSE ta,
                        CBLAS_TRANSPOSE tb,
                        OPEN3D_CPU_LINALG_INT m,
                        OPEN3D_CPU_LINALG_INT n,
                        OPEN3D_CPU_LINALG_INT k,
                        double al,
                        const double* A,
                        OPEN3D_CPU_LINALG_INT lda,
                        const double* B,
                        OPEN3D_CPU_LINALG_INT ldb,
                        double be,
                        double* C,
                        OPEN3D_CPU_LINALG_INT ldc) {
    (void)lda;
    (void)ldb;
    (void)ldc;
    eigen_gemm<double>(l, ta, tb, m, n, k, al, A, B, be, C);
}

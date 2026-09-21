// Copyright (c) 2018-2026 www.open3d.org
// SPDX-License-Identifier: MIT
// LU/solve part of the OPEN3D_BUILD_CORE_ONLY Eigen fallback.
#pragma once
template <typename T>
inline OPEN3D_CPU_LINALG_INT eigen_getrf(int layout,
                                         T* A,
                                         OPEN3D_CPU_LINALG_INT m,
                                         OPEN3D_CPU_LINALG_INT n,
                                         OPEN3D_CPU_LINALG_INT* ipiv) {
    if (layout != LAPACK_COL_MAJOR) return -1;
    open3d::core::eigen_fallback::ColMap<T> a(A, m, n);
    Eigen::PartialPivLU<open3d::core::eigen_fallback::ColMat<T>> lu(a);
    a = lu.matrixLU();
    const auto& perm = lu.permutationP().indices();
    for (OPEN3D_CPU_LINALG_INT i = 0; i < std::min(m, n); ++i) {
        ipiv[i] = static_cast<OPEN3D_CPU_LINALG_INT>(perm(i)) + 1;
    }
    return 0;
}
inline OPEN3D_CPU_LINALG_INT LAPACKE_sgetrf(int layout,
                                            OPEN3D_CPU_LINALG_INT m,
                                            OPEN3D_CPU_LINALG_INT n,
                                            float* A,
                                            OPEN3D_CPU_LINALG_INT lda,
                                            OPEN3D_CPU_LINALG_INT* ipiv) {
    (void)lda;
    return eigen_getrf<float>(layout, A, m, n, ipiv);
}
inline OPEN3D_CPU_LINALG_INT LAPACKE_dgetrf(int layout,
                                            OPEN3D_CPU_LINALG_INT m,
                                            OPEN3D_CPU_LINALG_INT n,
                                            double* A,
                                            OPEN3D_CPU_LINALG_INT lda,
                                            OPEN3D_CPU_LINALG_INT* ipiv) {
    (void)lda;
    return eigen_getrf<double>(layout, A, m, n, ipiv);
}
template <typename T>
inline OPEN3D_CPU_LINALG_INT eigen_getri(int layout,
                                         T* A,
                                         OPEN3D_CPU_LINALG_INT n) {
    if (layout != LAPACK_COL_MAJOR) return -1;
    open3d::core::eigen_fallback::ColMap<T> a(A, n, n);
    Eigen::PartialPivLU<open3d::core::eigen_fallback::ColMat<T>> lu(a);
    a = lu.inverse();
    return 0;
}
inline OPEN3D_CPU_LINALG_INT LAPACKE_sgetri(int layout,
                                            OPEN3D_CPU_LINALG_INT n,
                                            float* A,
                                            OPEN3D_CPU_LINALG_INT lda,
                                            OPEN3D_CPU_LINALG_INT* ipiv) {
    (void)lda;
    (void)ipiv;
    return eigen_getri<float>(layout, A, n);
}
inline OPEN3D_CPU_LINALG_INT LAPACKE_dgetri(int layout,
                                            OPEN3D_CPU_LINALG_INT n,
                                            double* A,
                                            OPEN3D_CPU_LINALG_INT lda,
                                            OPEN3D_CPU_LINALG_INT* ipiv) {
    (void)lda;
    (void)ipiv;
    return eigen_getri<double>(layout, A, n);
}
template <typename T>
inline OPEN3D_CPU_LINALG_INT eigen_gesv(int layout,
                                        T* A,
                                        OPEN3D_CPU_LINALG_INT n,
                                        OPEN3D_CPU_LINALG_INT nrhs,
                                        OPEN3D_CPU_LINALG_INT* ipiv,
                                        T* B) {
    if (layout != LAPACK_COL_MAJOR) return -1;
    open3d::core::eigen_fallback::ConstColMap<T> a(A, n, n);
    open3d::core::eigen_fallback::ColMap<T> b(B, n, nrhs);
    Eigen::PartialPivLU<open3d::core::eigen_fallback::ColMat<T>> lu(a);
    b = lu.solve(b).eval();
    const auto& perm = lu.permutationP().indices();
    for (OPEN3D_CPU_LINALG_INT i = 0; i < n; ++i) {
        ipiv[i] = static_cast<OPEN3D_CPU_LINALG_INT>(perm(i)) + 1;
    }
    return 0;
}
inline OPEN3D_CPU_LINALG_INT LAPACKE_sgesv(int layout,
                                           OPEN3D_CPU_LINALG_INT n,
                                           OPEN3D_CPU_LINALG_INT nrhs,
                                           float* A,
                                           OPEN3D_CPU_LINALG_INT lda,
                                           OPEN3D_CPU_LINALG_INT* ipiv,
                                           float* B,
                                           OPEN3D_CPU_LINALG_INT ldb) {
    (void)lda;
    (void)ldb;
    return eigen_gesv<float>(layout, A, n, nrhs, ipiv, B);
}
inline OPEN3D_CPU_LINALG_INT LAPACKE_dgesv(int layout,
                                           OPEN3D_CPU_LINALG_INT n,
                                           OPEN3D_CPU_LINALG_INT nrhs,
                                           double* A,
                                           OPEN3D_CPU_LINALG_INT lda,
                                           OPEN3D_CPU_LINALG_INT* ipiv,
                                           double* B,
                                           OPEN3D_CPU_LINALG_INT ldb) {
    (void)lda;
    (void)ldb;
    return eigen_gesv<double>(layout, A, n, nrhs, ipiv, B);
}

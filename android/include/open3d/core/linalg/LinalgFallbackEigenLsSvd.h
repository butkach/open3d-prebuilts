// Copyright (c) 2018-2026 www.open3d.org
// SPDX-License-Identifier: MIT
// Least-squares/SVD part of the OPEN3D_BUILD_CORE_ONLY Eigen fallback.
#pragma once
template <typename T>
inline OPEN3D_CPU_LINALG_INT eigen_gels(int layout,
                                        char trans,
                                        T* A,
                                        OPEN3D_CPU_LINALG_INT m,
                                        OPEN3D_CPU_LINALG_INT n,
                                        OPEN3D_CPU_LINALG_INT nrhs,
                                        T* B) {
    if (layout != LAPACK_COL_MAJOR || (trans != 'N' && trans != 'n')) return -1;
    open3d::core::eigen_fallback::ConstColMap<T> a(A, m, n);
    open3d::core::eigen_fallback::ColMap<T> b(B, std::max(m, n), nrhs);
    b = a.colPivHouseholderQr().solve(b).eval();
    return 0;
}
inline OPEN3D_CPU_LINALG_INT LAPACKE_sgels(int layout,
                                           char trans,
                                           OPEN3D_CPU_LINALG_INT m,
                                           OPEN3D_CPU_LINALG_INT n,
                                           OPEN3D_CPU_LINALG_INT nrhs,
                                           float* A,
                                           OPEN3D_CPU_LINALG_INT lda,
                                           float* B,
                                           OPEN3D_CPU_LINALG_INT ldb) {
    (void)lda;
    (void)ldb;
    return eigen_gels<float>(layout, trans, A, m, n, nrhs, B);
}
inline OPEN3D_CPU_LINALG_INT LAPACKE_dgels(int layout,
                                           char trans,
                                           OPEN3D_CPU_LINALG_INT m,
                                           OPEN3D_CPU_LINALG_INT n,
                                           OPEN3D_CPU_LINALG_INT nrhs,
                                           double* A,
                                           OPEN3D_CPU_LINALG_INT lda,
                                           double* B,
                                           OPEN3D_CPU_LINALG_INT ldb) {
    (void)lda;
    (void)ldb;
    return eigen_gels<double>(layout, trans, A, m, n, nrhs, B);
}
template <typename T>
inline OPEN3D_CPU_LINALG_INT eigen_gesvd(int layout,
                                         char jobu,
                                         char jobvt,
                                         T* A,
                                         OPEN3D_CPU_LINALG_INT m,
                                         OPEN3D_CPU_LINALG_INT n,
                                         T* S,
                                         T* U,
                                         T* VT) {
    if (layout != LAPACK_COL_MAJOR) return -1;
    if ((jobu != 'A' && jobu != 'a') || (jobvt != 'A' && jobvt != 'a')) {
        return -2;
    }
    open3d::core::eigen_fallback::ConstColMap<T> a(A, m, n);
    Eigen::JacobiSVD<open3d::core::eigen_fallback::ColMat<T>> svd(
            a, Eigen::ComputeFullU | Eigen::ComputeFullV);
    const auto& s = svd.singularValues();
    for (OPEN3D_CPU_LINALG_INT i = 0; i < std::min(m, n); ++i) S[i] = s(i);
    open3d::core::eigen_fallback::ColMap<T> u(U, m, m);
    u = svd.matrixU();
    open3d::core::eigen_fallback::ColMap<T> vt(VT, n, n);
    vt = svd.matrixV().transpose();
    return 0;
}
inline OPEN3D_CPU_LINALG_INT LAPACKE_sgesvd(int layout,
                                            char jobu,
                                            char jobvt,
                                            OPEN3D_CPU_LINALG_INT m,
                                            OPEN3D_CPU_LINALG_INT n,
                                            float* A,
                                            OPEN3D_CPU_LINALG_INT lda,
                                            float* S,
                                            float* U,
                                            OPEN3D_CPU_LINALG_INT ldu,
                                            float* VT,
                                            OPEN3D_CPU_LINALG_INT ldvt,
                                            float* superb) {
    (void)lda;
    (void)ldu;
    (void)ldvt;
    (void)superb;
    return eigen_gesvd<float>(layout, jobu, jobvt, A, m, n, S, U, VT);
}
inline OPEN3D_CPU_LINALG_INT LAPACKE_dgesvd(int layout,
                                            char jobu,
                                            char jobvt,
                                            OPEN3D_CPU_LINALG_INT m,
                                            OPEN3D_CPU_LINALG_INT n,
                                            double* A,
                                            OPEN3D_CPU_LINALG_INT lda,
                                            double* S,
                                            double* U,
                                            OPEN3D_CPU_LINALG_INT ldu,
                                            double* VT,
                                            OPEN3D_CPU_LINALG_INT ldvt,
                                            double* superb) {
    (void)lda;
    (void)ldu;
    (void)ldvt;
    (void)superb;
    return eigen_gesvd<double>(layout, jobu, jobvt, A, m, n, S, U, VT);
}

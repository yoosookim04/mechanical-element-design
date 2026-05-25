function [sgm_c_all_p, sgm_c_all_g] = sgm_c_all(N, u)
    % allowable stress for Contact, sgm_c_all
    % 침탄강 (Eh)
    % S_c (Allowable Contact Stress Number) = 1551 Mpa (3*10^6 cycles, 신뢰도 0.99)
    % S_h = 1, Y_theta = 1, Y_z = 1, Z_w = 1
    % 입력: N 피니언의 사이클 수, u 기어비 (생략 시 피니언만 계산)
    % 출력: sgm_c_all_p 피니언 허용 접촉응력, sgm_c_all_g 기어 허용 접촉응력 (u 입력 시)

    if nargin == 1
        Z_N_p         = AGMA.Z_N(N);
        sgm_c_all_p   = 1551 * Z_N_p;
        sgm_c_all_g   = [];
        return
    end

    [Z_N_p, Z_N_g] = AGMA.Z_N(N, u);
    sgm_c_all_p = 1551 * Z_N_p;    % S_c = 1551 MPa, Y_theta, Y_Z = 1
    sgm_c_all_g = 1551 * Z_N_g;
end
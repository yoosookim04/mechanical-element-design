function [sgm_all_p, sgm_all_g] = sgm_all(N, u)
    % allowable stress for Bending, sgm_all
    % 침탄강 (Eh)
    % S_t (Allowable Bending Stress Number) = 448 Mpa (10^7 cycles, 신뢰도 0.99)
    % S_f = 1, Y_theta = 1, Y_z = 1
    % 입력: N 피니언의 사이클 수, u 기어비 (생략 시 피니언만 계산)
    % 출력: sgm_all_p 피니언 허용 굽힘응력, sgm_all_g 기어 허용 굽힘응력 (u 입력 시)

    if nargin == 1
        Y_N_p       = AGMA.Y_N(N);
        sgm_all_p   = 448 * Y_N_p;
        sgm_all_g   = [];
        return
    end

    [Y_N_p, Y_N_g] = AGMA.Y_N(N, u);
    sgm_all_p = 448 * Y_N_p;
    sgm_all_g = 448 * Y_N_g;
end
    
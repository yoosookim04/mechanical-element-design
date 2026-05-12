function [K_s_p, K_s_g] = K_s(m_n, beta, b, N_p, N_g)
    % Size Factor(크기계수) K_s
    % 입력: b face width [m], m_t 모듈 (transverse section) [m]
    %       N_p 피니언 잇수, N_g 기어 잇수 (생략 시 피니언만 계산)
    % 출력: K_s_p 피니언 크기계수, K_s_g 기어 크기계수 (N_g 입력 시에만)

    m_t = m_n / cosd(beta);

    if nargin == 4
        Y_p   = AGMA.form_factor(N_p);
        K_s_p = 1.192 * (b * m_t * sqrt(Y_p) / 645.16)^0.0535;
        K_s_g = [];
        return
    end

    [Y_p, Y_g] = AGMA.form_factor(N_p, N_g);
    K_s_p = 1.192 * (b * m_t * sqrt(Y_p) / 645.16)^0.0535;
    K_s_g = 1.192 * (b * m_t * sqrt(Y_g) / 645.16)^0.0535;
end
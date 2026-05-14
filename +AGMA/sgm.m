function [sgm_p, sgm_g] = sgm(W_t, v, m_n, alpha_n, beta, b, N_p, N_g)
    % actual Bending Stress for gear tooth (피니언, 기어)
    % 입력 W_t: 동력 전달 하중 v: 선속도, m: 치직각 모듈, alpha_n: 치직각 압력각(사용되지 않지만, 접촉 식과 변수입력 일치)
    % beta: 헬리컬기어에 대한 비틀림각, b: 치폭, N_p,N_g: 피니언, 기어 잇수
    m_t = m_n / cosd(beta);
    K_o = 1.25;                                         % 과부하계수
    K_v = AGMA.K_v(v);                                  % 속도계수
    [K_s_p, K_s_g] = AGMA.K_s(m_n, beta, b, N_p, N_g);  % 크기계수
    K_H = AGMA.K_H(m_n, beta, b, N_p);                    % 하중분포계수 (기어쌍 단일값)
    K_B = 1;                                            % 림두께계수
    [Y_J_p, Y_J_g] = AGMA.Y_J(beta, N_p, N_g);  % 형상계수



    sgm_p = W_t * K_o * K_v * K_s_p / (b * m_t) * K_H * K_B / Y_J_p;
    sgm_g = W_t * K_o * K_v * K_s_g / (b * m_t) * K_H * K_B / Y_J_g;
end
function [S_H_p, S_H_g] = S_H(N, W_t, v, m_n, alpha_n, beta, b, N_p, N_g)
    % 접촉에 대한 기어의 안전계수 S_H

    % 입력 N: 피니언 사이클,W_t: 동력 전달 하중 v: 선속도, m: 치직각 모듈, alpha_n: 치직각 압력각(사용되지 않지만, 굽힘 식과 변수입력 일치)
    % beta: 헬리컬기어에 대한 비틀림각, b: 치폭, N_p,N_g: 피니언, 기어 잇수

    % 출력: 접촉에 대한 안전계수 (피니언, 기어)

    u = N_g / N_p;

    sgm_c                     = AGMA.sgm_c(W_t, v, m_n, alpha_n, beta, b, N_p, N_g);
    [sgm_c_all_p, sgm_c_all_g] = AGMA.sgm_c_all(N, u);

    S_H_p = sgm_c_all_p / sgm_c;
    S_H_g = sgm_c_all_g / sgm_c;
end
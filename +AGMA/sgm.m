function [sgm_p, sgm_g] = sgm(W_t, v, m_n, alpha_n, beta, b, N_p, N_g)
    % actual Bending Stress for gear tooth (피니언, 기어)
    % 입력 W_t: 동력 전달 하중 v: 선속도, 
    m_t = m_n / cosd(beta);
    K_o = 1.25;                  % 과부하계수
    K_v = AGMA.K_v(v);           % 속도계수
    [K_s_p, K_s_g] = AGMA.K_s(m_n, beta, b, N_p, N_g);  % 크기계수
    [K_H_p, K_H_g] = AGMA.K_H(m_n, beta, b, N_p, N_g);  % 하중부포집중계쑤
    K_B = 1;
    [Y_J_p, Y_J_g] = AGMA.Y_J_helical(beta, N_p, N_g);



    sgm_p = W_t * K_o * K_v * K_s_p / (b * m_t) * K_H_p * K_B / Y_J_p
    sgm_g = W_t * K_o * K_v * K_s_g / (b * m_t) * K_H_g * K_B / Y_J_g
end
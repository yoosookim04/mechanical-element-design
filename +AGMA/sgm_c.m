function sgm_c = sgm_c(W_t, v, m_n, alpha_n, beta, b, N_p, N_g)
    % actual Contact Stress for gear tooth
    % 주의: 접촉응력은 피니언과 기어가 같은 값을 가집니다
    % 크기계수와 하중분포집중계수는 피니언 기준으로 계산하며, 기어의 기하학적 효과는 Z_I에 반영되어있습니다.
    % 입력 W_t: 동력 전달 하중 v: 선속도, m: 치직각 모듈, alpha_n: 치직각 압력각
    % beta: 헬리컬기어에 대한 비틀림각, b: 치폭, N_p,N_g: 피니언, 기어 잇수
    m_t = m_n / cosd(beta);
    K_o = 1.25;                           % 과부하계수
    K_v = AGMA.K_v(v);                    % 속도계수
    K_s_p = AGMA.K_s(m_n, beta, b, N_p);  % 크기계수
    K_H_p = AGMA.K_H(m_n, beta, b, N_p);  % 하중부포집중계수
    
    d_p = m_t * N_p; % 피니언 피치원 지름
    

    Z_E = 191;  % Eh
    Z_R = 1;    % for normal commercial gear
    Z_I = AGMA.Z_I_helical(m_n,alpha_n, N_p, N_g, beta); % 형상계수

    sgm_c = Z_E * sqrt(W_t * K_o * K_v * K_s_p * K_H_p * Z_R / (Z_I * b * d_p));
end

function Z_I = Z_I(m_n,alpha_n, N_p, N_g)
    % Geometry Factor for Contact, Z_I (AGMA 908-B89)
    % 20도 압력각 표준 스퍼기어 기준
    % 입력 alpha_n: 치직각(normal) 압력각 [deg], N_p: 피니언 잇수, N_g: 기어 잇수 (접촉 형상계수는 기어쌍 전체에 대한 계수)
    % m_n 치직각(normal) 모듈: 스퍼기어에서는 Z_I 계산에 영향을 주지 않으므로 무시해도 됨 (Z_I_helical 과의 병렬을 위한 입력값)
    % 출력 Z_I: 접촉 형상계수


    m_G = N_g / N_p;    % 기어비
    alpha_t  = alpha_n; % 스퍼기어
    m_N = 1;            % load sharing ratio (기어 하중 공유 비율)
    Z_I = (cosd(alpha_t) * sind(alpha_t)/(2*m_N)) * (m_G/(m_G+1));
end
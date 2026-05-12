function Z_I = Z_I_helical(m_n,alpha_n, N_p, N_g, beta)
    % Geometry Factor for Contact, Z_I — Helical Gear (AGMA 908-B89)
    % 20도 압력각 기준
    % 입력 m_n 치직각(normal) 모듈, alpha_n: 치직각(normal) 압력각 [deg]
    % N_p: 피니언 잇수, N_g: 기어 잇수 (접촉 형상계수는 기어쌍 전체에 대한 계수)
    % 출력 Z_I: 접촉 형상계수

    m_G = N_g / N_p;    % 기어비
    alpha_t = atand(tand(alpha_n)/cosd(beta)); % 축직각 압력각;
    p_N = pi * m_n * cosd(alpha_n); % 치직각 법선피치
    r_p = m_n * N_p / (2*cosd(beta)); % 피니언의 피치원 반지름
    r_G = m_n * N_g / (2*cosd(beta)); % 기어의 피치원 반지름
    r_bp = r_p * cosd(alpha_t); % 피니언의 베이스원 반지름
    r_bG = r_G * cosd(alpha_t); % 기어의 베이스원 반지름
    Z = sqrt((r_p + m_n)^2 - r_bp^2) + sqrt((r_G + m_n)^2 - r_bG^2) - (r_p + r_G)*sind(alpha_t);
    m_N = p_N / (0.95 * Z); % load sharing ratio (기어 하중 공유 비율)

    Z_I = (cosd(alpha_t) * sind(alpha_t)/(2*m_N)) * (m_G/(m_G+1));
end
function K_H = K_H(m_n, beta, b, N_p)
    % Load Distribution Factor(하중분포계수) K_H - 기어쌍의 단일값
    % 입력: m_n 치직각(normal) 모듈 [mm], beta 나선각 [deg], b face width [mm]
    %       N_p 피니언 잇수 (피니언 피치원 지름 기준으로 계산)
    % 주의: 스퍼기어라면 beta=0으로 입력

    d   = (m_n / cosd(beta)) * N_p; % 피니언 피치원 지름

    C_mc = 1; % uncrowned teeth: 1, crowned teeth: 0.8
    if b <= 25
        C_pf = b / (10 * d) - 0.025;
    elseif b <= 425
        C_pf = b / (10 * d) - 0.0375 + 4.92e-4 * b;
    elseif b <= 1000
        C_pf = b / (10 * d) - 0.1109 + 8.15e-4 * b - 3.53e-7 * b^2;
    else
        error('face width b=%.1f mm 가 허용 범위(0 ~ 1000 mm)를 벗어났습니다.', b)
    end

    C_e  = 1;    % 0.8 for gearing adjusted at assembly (그 외엔 다 1)
    C_pm = 1;    % 기어 위치에 따라 1.1이 될수도
    C_ma = 1.27 * 0.1 + 0.622e-3 * b - 1.69e-7 * b^2;
    % C_ma 는 gear unit 조건에 따라 계수가 달라질수도. (해당 함수는 commercial enclosed gear units.)

    K_H = 1 + C_mc * (C_pf * C_pm + C_ma * C_e);
end

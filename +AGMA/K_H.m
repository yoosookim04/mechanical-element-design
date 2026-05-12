function [K_H_p, K_H_g] = K_H(m_n, beta, b, N_p, N_g)
    % Load Distribution Factor(하중분포계수) K_H - Helical Gear 가정
    % 입력: m_n 치직각(normal) 모듈 [mm], beta 나선각 [deg], b face width [mm]
    % N_p 피니언 잇수, N_g 기어 잇수 (생략 시 피니언만 계산)
    % 출력: K_H 하중분포계수 피니언과 기어 각각 (N_g 입력 시에만)
    
    % 주의: 스퍼기어라면 beta=0으로 계산

    if nargin == 4
        K_H_p = calc_K_H(m_n, beta, b, N_p);
        K_H_g = [];
        return
    end

    K_H_p = calc_K_H(m_n, beta, b, N_p);
    K_H_g = calc_K_H(m_n, beta, b, N_g);
end

function K_H = calc_K_H(m_n, beta, b, N)
    d   = (m_n / cosd(beta)) * N;

    C_mc = 1; % uncrowned teeth: 1, crowned teeth: 0.8
    if b <= 25
        C_pf = b / (10 * d) - 0.025;
    elseif b <= 425
        C_pf = b / (10 * d) - 0.0375 + 4.92e-4 * b;
    else
        C_pf = b / (10 * d) - 0.1109 + 8.15e-4 * b - 3.53e-7 * b^2;
    end

    C_e  = 1;    % 0.8 for gearing adjusted at assembly (그 외엔 다 1)
    C_pm = 1;    % 기어 위치에 따라 1.1이 될수도
    C_ma = 1.27 * 0.1 + 0.622e-3 * b - 1.69e-7 * b^2;
    % C_ma 는 gear unit 조건에 따라 계수가 달라질수도.

    K_H = 1 + C_mc * (C_pf * C_pm + C_ma * C_e);
end
    


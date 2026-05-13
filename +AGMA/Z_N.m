function [Z_N_p, Z_N_g] = Z_N(N, u)
    % Stress-Cycle Factor(수명계수) for Contact, Z_N
    % 주의: 침탄강에 대한 수명계수 (오직 소재에 의해서 수명계수 그래프 달라짐 (신뢰도X))
    % 입력 N: 피니언 사이클 수, u: 기어비 N_G/N_P (생략 시 피니언만 계산)
    % 출력 Z_N_p :  접촉에 의한 피니언 수명계수, Z_N_g : 접촉에 의한 기어 수명계수 (u 입력 시)

    Z_N_p = calc_Z_N(N);

    if nargin == 1
        Z_N_g = [];
        fprintf('Stress-Cycle Factor for Contact  Z_N = %.4f\n', Z_N_p);
        return
    end

    N_g   = N / u;
    Z_N_g = calc_Z_N(N_g);
    fprintf('Pinion: Stress-Cycle Factor for Contact  Z_N_p = %.4f\n', Z_N_p);
    fprintf('Gear:   Stress-Cycle Factor for Contact  Z_N_g = %.4f\n', Z_N_g);
end

function Z = calc_Z_N(N)
    if N < 1e2
        error('사이클 수 N=%.3e 는 허용 범위(1e2 ~)를 벗어났습니다.', N)
    end
    if N < 1e4
        Z = 1.472;
    elseif N < 1e7
        Z = 2.466 * N^(-0.056);
    elseif N < 1e10
        Z = 1.4488 * N^(-0.023);
    else
        Z = 0.853;
    end
end




    
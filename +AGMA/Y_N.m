function [Y_N_p, Y_N_g] = Y_N(N, u)
    % Stress-Cycle Factor(수명계수) for Bending, Y_N
    % 주의: 침탄강에 대한 수명계수 (오직 소재에 의해서 수명계수 그래프 달라짐 (신뢰도X))
    % 입력 N: 피니언 사이클 수, u: 기어비 N_G/N_P (생략 시 피니언만 계산)
    % 출력 Y_N_p : 굽힘에 의한 피니언 수명계수, Y_N_g : 굽힘에 의한 기어 수명계수 (u 입력 시)

    Y_N_p = calc_Y_N(N);

    if nargin == 1
        Y_N_g = [];
        fprintf('Stress-Cycle Factor for Bending  Y_N = %.4f\n', Y_N_p);
        return
    end

    N_g   = N / u;
    Y_N_g = calc_Y_N(N_g);
    fprintf('Pinion: Stress-Cycle Factor for Bending  Y_N_p = %.4f\n', Y_N_p);
    fprintf('Gear:   Stress-Cycle Factor for Bending  Y_N_g = %.4f\n', Y_N_g);
end

function Y = calc_Y_N(N)
    if N < 1e2
        error('사이클 수 N=%.3e 는 허용 범위(1e2 ~)를 벗어났습니다.', N)
    end
    if N < 1e3
        Y = 2.7;
    elseif N < 3e6
        Y = 6.1514 * N^(-0.1192);
    elseif N < 1e10
        Y = 1.3558 * N^(-0.0178);
    else
        Y = 0.9;
    end
end




    
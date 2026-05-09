function Z_N = Z_N(N)
    % Stress-Cycle Factor(수명계수) for Contact, Z_N
    % 주의: 침탄강에 대한 수명계수
    % 입력 N: Number of Cycles(사이클 수)
    % 출력 Z_N: Stress-Cycle Factor(수명계수)
    if N < 1e2
        error('사이클 수 N=%d 는 허용 범위(1e2 ~)를 벗어났습니다.', N)
    end

    if N < 1e4
        Z_N = 1.472;
    elseif N >= 1e4 && N < 1e7
        Z_N = 2.466*N^(-0.056);
    elseif N >= 1e7 && N < 1e10
        Z_N = 1.4488*N^(-0.023);
    elseif N >= 1e10
        Z_N = 0.853;
    end
    fprintf('사이클 수 N = %d  →  수명계수 Z_N = %.4f\n', N, Z_N);
end




    
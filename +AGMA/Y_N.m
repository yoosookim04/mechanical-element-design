function Y_N = Y_N(N)
    % Stress-Cycle Factor(수명계수) for Bending, Y_N
    % 주의: 침탄강에 대한 수명계수
    % 입력 N: Number of Cycles(사이클 수)
    % 출력 Y_N: Stress-Cycle Factor(수명계수)
    if N < 1e2
        error('사이클 수 N=%d 는 허용 범위(1e2 ~)를 벗어났습니다.', N)
    end

    if N < 1e3
        Y_N = 2.7;
    elseif N >= 1e3 && N < 3*1e6
        Y_N = 6.1514*N^(-0.1192);
    elseif N >= 3*1e6 && N < 1e10
        Y_N = 1.3558*N^(-0.0178);
    elseif N >= 1e10
        Y_N = 0.9;
    end
    fprintf('Stress-Cycle Factor for Bending: Y_N = %.4f\n', Y_N);
end




    
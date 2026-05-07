function I = I_rectangular(b,d)
    % 직사각형 단면의 단면 2차 모멘트
    % 입력: b = 밑변 [mm], d = 높이 [mm]
    % 출력: I = b(d^3) / 12 [mm^4]
    I = (b * (d^3)) / 12;
end


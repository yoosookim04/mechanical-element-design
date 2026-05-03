function I = I_solid(d)
    % 중실 원형 단면의 단면 2차 모멘트
    % 입력: d = 지름 [mm]
    % 출력: I = 단면 2차 모멘트 [mm^4]
    
    I = (pi * d^4) / 64;
end
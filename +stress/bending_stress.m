function sgm_b = bending_stress(M,d,x)
    % 중실 원형 굽힘 인장 응력
    % M: 굽힘 모멘트 [Nmm]
    % d: 지름(외경) [mm] (종공축의 경우 x 내경/외경 비율)
    % 출력: sgm_b = 굽힘 인장 응력 [MPa]
    if d <= 0
        error('d는 양수여야 합니다. 입력값: d = %.4f',d)    
    end
    if nargin < 3
        sgm_b = (32*M)/(pi*d^3);
    else
        sgm_b = (32*M)/(pi*(d^3)*(1-x^4));
    end
end



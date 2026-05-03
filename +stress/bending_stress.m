function sgm_b = bending_stress(M,d)
    % 중실 원형 굽힘 인장 응력
    % M: 굽힘 모멘트 [Nmm]
    % d: 지름 [mm]
    % 출력: sgm_b = 굽힘 인장 응력 [MPa]
    if d <= 0
        error('d는 양수여야 합니다. 입력값: d = %.4f',d)    
    end
    sgm_b = (32*M)/(pi*d^3);
end



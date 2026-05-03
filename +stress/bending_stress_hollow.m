function sgm_b = bending_stress_hollow(M,d_2,x)
    % 중공 원형 굽힘 인장 응력
    % M: 굽힘 모멘트 [Nmm]
    % d_2: 외경 [mm], x: 내경/외경 비율
    % 출력: sgm_b = 굽힘 인장 응력 [MPa]
    if d_2 <= 0
        error('외경은 양수여야 합니다. 입력값: d_2 = %.4f',d_2)
    end
    sgm_b = (32*M)/(pi*d_2^3*(1-x^4));
end

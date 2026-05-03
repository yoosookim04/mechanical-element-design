function tau = torsion_stress_hollow(T,d_2,x)
    % 중공 원형 단면 비틀림 전단응력
    % T: 토크 [Nmm]
    % d_2: 외경 [mm], x: 내경/외경 비율
    % 출력 tau = 비틀림 전단응력 [MPa]
    if d_2 <= 0
        error('d_2는 양수여야 합니다. 입력값: d_2 = %.4f',d_2)
    end
    tau = (16*T)/(pi*d_2^3*(1-x^4));
end
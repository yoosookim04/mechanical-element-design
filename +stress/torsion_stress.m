function tau = torsion_stress(T,d)
    % 중공 원형 단면 비틀림 전단응력
    % T: 토크 [Nmm]
    % d: 원형 단면 지름 [mm]
    % 출력 tau = 비틀림 전단응력 [MPa]
    if d <= 0
        error('d는 양수여야 합니다. 입력값: d = %.4f',d)
    end
    tau = (16*T)/(pi*d^3);
end
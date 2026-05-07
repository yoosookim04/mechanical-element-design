function tau = torsion_stress(T,d,x)
    % 중공 원형 단면 비틀림 전단응력
    % T: 토크 [Nmm]
    % d: 원형 단면 지름(외경) [mm] (중공축이면 x 내경/외경 비율)
    % 출력 tau = 비틀림 전단응력 [MPa]
    if d <= 0
        error('d는 양수여야 합니다. 입력값: d = %.4f',d)
    end
    if nargin < 3
        tau = (16*T)/(pi*d^3);
    else
        tau = (16*T)/(pi*(d^3)*(1-x^4));
    end
end
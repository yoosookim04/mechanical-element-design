function n = SF_MSS_MT(M,T,d,S_y,x) 
    % 원형(중공,중실) 축단면, 굽힘,비틀림 복합하중 시 최대전단응력 기준 안전계수
    % 입력: M 굽힘 모멘트, T 비틀림 모멘트 [Nmm], d 직경 [mm], S_y 항복강도 [MPa]
    % 중공축인 경우 x 내경/외경 비율
    % 출력: n = 안전계수 (MSS 이론 기반 정적 파손)
    if S_y <= 0
            error('S_y는 양수여야 합니다. 입력값: S_y = %.4f', S_y)
    end
    S_sy = 0.5 * S_y;
    if nargin < 5            
        tau_max = stress.tau_max_MT(M,T,d);
    else
    
        tau_max = stress.tau_max_MT(M,T,d,x);
    end
    n = S_sy / tau_max;
end
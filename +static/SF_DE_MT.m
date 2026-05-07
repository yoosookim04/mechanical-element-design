function n = SF_DE_MT(M,T,d,S_y,x)
    % 원형 축단면, 굽힘,비틀림 복합하중 시 vonMises 이론 기준 안전계수
    % 입력: M 굽힘 모멘트, T 비틀림 모멘트 [Nmm], d 직경(외경) [mm], S_y 항복강도 [MPa]
    % 중공축의 경우, x 내경/외경 비율 
    % 출력: n = 안전계수 (vonMises 이론 기반 정적 파손)
    if S_y <= 0
        error('S_y는 양수여야 합니다. 입력값: S_y = %.4f', S_y)
    end
    if nargin < 5
        sgm_von = stress.vonMises_MT(M,T,d);
    else
        sgm_von = stress.vonMises_MT(M,T,d,x);
    end
    n = S_y / sgm_von;
end
function [n_DE,n_MSS] = SF_MT(M,T,d,S_y,x)
    % combined load (평면응력 상태가 만들어지는 하중)의 정적 파손 진단
    % 압축과 인장에 대한 강도가 비슷하 연성 재료
    % 입력: M 굽힘 모멘트, T 비틀림 모멘트 [Nmm], d 직경(외경) [mm], S_y 인장항복강도 [MPa]
    % 출력: DE,MSS 이론 기반 안전계수
    if S_y <= 0
        error('S_y는 양수여야 합니다. 입력값: S_y = %.4f', S_y)
    end

    if nargin < 5
        n_DE = static.SF_DE_MT(M,T,d,S_y);
        n_MSS = static.SF_MSS_MT(M,T,d,S_y);

    else % 중공축
        n_DE = static.SF_DE_MT(M,T,d,S_y,x);
        n_MSS = static.SF_MSS_MT(M,T,d,S_y,x);
    end
    fprintf('DE  : %.4f\n', n_DE); 
    fprintf('MSS : %.4f\n', n_MSS);

end
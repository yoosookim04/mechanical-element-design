function [theta_deg, theta_per_m, detail] = torsion_angle(T, Do, Di, secL, G)
%% ========================================================================
%  torsion_angle.m
%  변단면 중공축의 비틀림각 (비틀림 강성 검토)
%  ------------------------------------------------------------------------
%  [원리] θ = ∫ T/(G·J(x)) dx = Σ T·secL_i/(G·J_i)   (구간별 합)
%    변단면이라 구간마다 J가 달라 -> 구간별로 나눠 적분(합산).
%    굽힘 처짐과 달리 적분곡선 불필요, 단순 합.
%
%  [용도] 비틀림 강성 제약. 운전 중 축이 비틀리는 각도가 허용치 이하인지.
%    강도(shaft_stress의 τ)와 별개 — 여긴 '얼마나 비틀리냐'(변형) 평가.
%  ------------------------------------------------------------------------
%  입력:
%    T    : 비틀림 토크 [N.mm] (축 전체 동일 가정; 구간별이면 벡터 가능)
%    Do   : 구간 외경 벡터 [mm]
%    Di   : 내경 [mm]
%    secL : 구간 길이 벡터 [mm] (각 구간 길이)
%    G    : 전단탄성계수 [MPa] (강: ~79000)
%  출력:
%    theta_deg   : 전체 비틀림각 [deg]
%    theta_per_m : 단위길이당 비틀림각 [deg/m]  ← 제약 비교용
%    detail      : 구간별 기여 등
% =========================================================================

    % 입력 검사
    if any(Do <= Di)
        error('Do 가 Di 이하인 구간이 있습니다.');
    end
    nSeg = numel(secL);
    if isscalar(T), T = T*ones(1,nSeg); end

    % 구간별 비틀림각 합산
    theta_rad = 0;
    theta_seg = zeros(1,nSeg);
    for i = 1:nSeg
        J = pi/32*(Do(i)^4 - Di^4);     % 극단면2차모멘트 [mm^4]
        % θ_i = T·L_i/(G·J)  : [N.mm]·[mm]/([MPa=N/mm^2]·[mm^4]) = [rad]
        theta_seg(i) = T(i)*secL(i)/(G*J);
        theta_rad = theta_rad + theta_seg(i);
    end

    theta_deg   = theta_rad * 180/pi;            % 전체 [deg]
    L_total_mm  = sum(secL);
    theta_per_m = theta_deg / (L_total_mm/1000); % [deg/m]

    detail = struct('theta_rad',theta_rad, ...
                    'theta_deg',theta_deg, ...
                    'theta_per_m',theta_per_m, ...
                    'theta_seg_deg',theta_seg*180/pi, ...
                    'L_total_mm',L_total_mm);
end

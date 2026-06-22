function [delta_max, x_at_max, delta_curve, xs] = bending_deflection( ...
                                    L, xG, Ft, Fr, Cmag, Do, Di, secL, E)
%% ========================================================================
%  bending_deflection.m  (v2 — 부호버그 수정 + 다중기어 모멘트합산)
%  변단면 단순지지축의 굽힘 처짐 (2평면 합성, 이중적분)
%  ------------------------------------------------------------------------
%  [v2 수정사항]
%   (1) 커플모멘트 반력식 부호 수정: RB=(F*a+C)/L  (기존 F*a-C 는 x=L에서 M≠0)
%   (2) 다중 기어: 처짐을 따로 구해 합산(X) -> 모멘트곡선을 먼저 합산 후
%       한 번에 처짐 계산(O). xG/Ft/Fr/Cmag 를 벡터로 받으면 중첩 처리.
%   (3) 입력 검사: Do>Di, sum(secL)≈L
%  ------------------------------------------------------------------------
%  입력:
%    L    : 베어링 스팬 [mm]
%    xG   : 기어 위치 [mm]  — 스칼라 또는 벡터(기어 여러 개)
%    Ft   : 접선력 [N]      — xG와 같은 길이
%    Fr   : 반경력 [N]      — xG와 같은 길이
%    Cmag : 축력커플 = Fa*pd/2 [N.mm] — xG와 같은 길이
%    Do   : 구간 외경 벡터 [mm]
%    Di   : 내경(중공) [mm]
%    secL : 구간 길이 벡터 [mm] (합 = L)
%    E    : 탄성계수 [MPa]
%  출력:
%    delta_max, x_at_max, delta_curve, xs
% =========================================================================

    % ----- 입력 검사 (3번) -----
    if any(Do <= Di)
        error('Do(%.1f..) 가 Di(%.1f) 이하인 구간이 있습니다.', min(Do), Di);
    end
    if abs(sum(secL) - L) > 1e-6*max(1,L)
        error('sum(secL)=%.4f 가 L=%.4f 와 불일치합니다.', sum(secL), L);
    end
    % 벡터화: 스칼라로 들어와도 처리
    xG = xG(:).'; Ft = Ft(:).'; Fr = Fr(:).'; Cmag = Cmag(:).';
    nG = numel(xG);
    if numel(Ft)~=nG || numel(Fr)~=nG || numel(Cmag)~=nG
        error('xG/Ft/Fr/Cmag 길이가 일치해야 합니다.');
    end

    N  = 1001;
    xs = linspace(0, L, N);
    dx = xs(2) - xs(1);

    % 위치별 단면2차모멘트 I(x)
    edges = [0, cumsum(secL)];
    Ix = zeros(1, N);
    for i = 1:N
        idx = find(xs(i) >= edges(1:end-1) & xs(i) <= edges(2:end), 1);
        if isempty(idx), idx = numel(Do); end
        d = Do(idx);
        Ix(i) = pi/64*(d^4 - Di^4);
    end

    % ----- (2) 모멘트곡선을 먼저 '합산' -----
    % 두 평면 각각, 모든 기어의 모멘트를 중첩(superposition)
    Mt    = zeros(1,N);   % 접선면
    Mr_p  = zeros(1,N);   % 반경면 (+커플)
    Mr_n  = zeros(1,N);   % 반경면 (-커플)
    for k = 1:nG
        Mt   = Mt   + beam_moment_local(Ft(k), xG(k), L,  0,        xs);
        Mr_p = Mr_p + beam_moment_local(Fr(k), xG(k), L,  Cmag(k),  xs);
        Mr_n = Mr_n + beam_moment_local(Fr(k), xG(k), L, -Cmag(k),  xs);
    end

    % 합산된 모멘트곡선으로 각 평면 처짐 (한 번만 적분)
    yt   = deflection_from_moment(Mt,   Ix, E, dx, xs, L);
    yr_p = deflection_from_moment(Mr_p, Ix, E, dx, xs, L);
    yr_n = deflection_from_moment(Mr_n, Ix, E, dx, xs, L);

    % 합성 처짐 (접선면 _|_ 반경면), 축력커플 부호별 큰 쪽
    d_p = sqrt(yt.^2 + yr_p.^2);
    d_n = sqrt(yt.^2 + yr_n.^2);
    if max(d_p) >= max(d_n), delta_curve = d_p; else, delta_curve = d_n; end

    [delta_max, im] = max(delta_curve);
    x_at_max = xs(im);
end


function M = beam_moment_local(F, a, L, C, xs)
% 단순지지보: 점하중 F@a + 단부 모멘트커플 C -> 굽힘모멘트 M(x)
%  [v2 수정] 평형: 끝단 커플 C가 RB쪽에 작용 -> RB=(F*a + C)/L
%   이래야 x=L 에서 M=0 (단순지지 경계조건) 만족.
    RB = (F*a + C)/L;
    RA = F - RB;
    M  = zeros(size(xs));
    left  = xs <  a;
    right = ~left;
    M(left)  = RA*xs(left);
    M(right) = RA*xs(right) - F*(xs(right)-a) + C;
end


function y = deflection_from_moment(M, Ix, E, dx, xs, L)
% EI y'' = M 이중적분 (변단면: 곡률 = M/(E*I(x)))
%   경계조건(단순지지): y(0)=0, y(L)=0
    curv  = M ./ (E .* Ix);
    theta = cumtrapz_local(curv, dx);
    y0    = cumtrapz_local(theta, dx);
    C1 = -y0(end)/L;
    y  = y0 + C1*xs;
end


function out = cumtrapz_local(f, dx)
    out = zeros(size(f));
    for i = 2:numel(f)
        out(i) = out(i-1) + 0.5*(f(i)+f(i-1))*dx;
    end
end

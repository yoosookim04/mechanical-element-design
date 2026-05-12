function K_v = K_v(v)
    % 속도계수 K_v
    % 입력: v pitch line velocity [m/s]
    % 출력: K_v 속도계수
    Q_v = 6;    % 정밀도 등급 6으로 고정
    B   = 0.25*(12-Q_v)^(2/3);
    A   = 50 + 56*(1-B);
    K_v = ((A+sqrt(200*v))/A)^B;
    % 단위 변환: 1 m/s ≈ 200 ft/min (196.85의 근사, K_v에 미치는 오차 ~0.8%)
end

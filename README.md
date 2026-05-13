# mechanical-element-design

기계요소설계 MATLAB 함수 라이브러리. 회전축계 요소(축, 기어, 베어링)의 응력 계산과 정적/AGMA 강도평가를 수행합니다.

## 단위계
`[mm, N, MPa, N·mm, m/s]`

## 적용 범위 (Scope)
- **대상**: 원형 단면 회전축, 스퍼/헬리컬 기어, 베어링 등 회전축계 기계요소
- **응력 상태**: 평면응력 (σ_y = 0) — 굽힘응력 + 비틀림전단응력 조합
- **재료**: 인장·압축 강도가 비슷한 **연성 재료** (덕타일 강) 기준
  - 취성 재료 파손이론(BCM, MNS, DCM)은 본 라이브러리 범위 외
- **권장 외 범위**: 하우징, 압력용기 등 이축응력(σ_y ≠ 0)이 지배적인 구조물 → FEA 적용 권장

## 패키지 구조

```
+stress/   범용 응력·단면 함수 (중실/중공 통합)
+static/   정적 파손이론 (DE, MSS)
+AGMA/     AGMA 기준 기어 강도평가 (굽힘·접촉)
```

### `+stress/` — 응력 및 단면 계산
중실축은 인자 4개, 중공축은 외경/내경 비율 `x`를 추가로 전달 (`nargin < N` 분기로 통합).

| 함수 | 설명 |
|---|---|
| `bending_stress(M, d, x)` | 굽힘 인장응력 σ_b |
| `torsion_stress(T, d, x)` | 비틀림 전단응력 τ |
| `axial_stress(F, d, x)` | 축방향 응력 |
| `vonMises(σ_x, τ_xy)` | 등가응력 (응력 입력) |
| `vonMises_MT(M, T, d, x)` | 등가응력 (하중 입력) |
| `tau_max(σ_x, τ_xy)` | 최대전단응력 (응력 입력) |
| `tau_max_MT(M, T, d, x)` | 최대전단응력 (하중 입력) |
| `principal_stress(σ_x, τ_xy)` | 주응력 σ_1, σ_2 |
| `eq_moment(M, T)` | 등가굽힘모멘트 M_e |
| `eq_torque(M, T)` | 등가비틀림모멘트 T_e |
| `area(d, x)` | 원형 단면 면적 |
| `I_solid(d)` / `I_hollow(d, x)` | 단면 2차 모멘트 |
| `I_rectangular(b, h)` | 직사각형 단면 2차 모멘트 |

### `+static/` — 정적 파손이론
연성 재료 기준 안전계수. **응력 입력**과 **하중 입력** 두 가지 인터페이스 제공.

| 함수 | 입력 | 출력 |
|---|---|---|
| `SF_DE(σ_x, τ_xy, S_y)` | 응력상태 | DE(왜곡에너지) 이론 n |
| `SF_MSS(σ_x, τ_xy, S_y)` | 응력상태 | MSS(최대전단응력) 이론 n |
| `SF_DE_MT(M, T, d, S_y, x)` | 하중·형상 | DE 이론 n |
| `SF_MSS_MT(M, T, d, S_y, x)` | 하중·형상 | MSS 이론 n |
| `SF(σ_x, τ_xy, S_y)` | 응력상태 | `[n_DE, n_MSS]` 동시 반환 + 콘솔 출력 |
| `SF_MT(M, T, d, S_y, x)` | 하중·형상 | `[n_DE, n_MSS]` 동시 반환 + 콘솔 출력 |

### `+AGMA/` — AGMA 기어 강도평가
스퍼·헬리컬 기어의 굽힘(Bending) 및 접촉(Contact) 안전계수를 산출.
**전제 조건**:
- 재료: 침탄강 (Eh), `Z_E = 191`
- 정밀도 등급: `Q_v = 6` (`K_v` 내부 고정)
- 신뢰도: 0.99 (`Y_θ = Y_Z = S_F = S_H = 1`)
- 기준 응력값: `S_t = 448 MPa` (굽힘, 10⁷ cycles), `S_c = 1551 MPa` (접촉, 3×10⁶ cycles)

**보정계수**

| 함수 | 설명 |
|---|---|
| `K_v(v)` | 속도계수 (선속도 m/s 입력) |
| `K_s(m_n, β, b, N_p, N_g)` | 크기계수 (Lewis form factor 기반) |
| `K_H(m_n, β, b, N_p)` | 하중분포계수 |
| `Y_J(β, N_p, N_g)` | 굽힘 형상계수 (Shigley Fig. 14-7, 14-8; β=0 시 스퍼기어 등가) |
| `Z_I(m_n, α_n, N_p, N_g)` | 접촉 형상계수 (스퍼기어) |
| `Z_I_helical(m_n, α_n, N_p, N_g, β)` | 접촉 형상계수 (헬리컬기어) |
| `Y_N(N, u)` / `Z_N(N, u)` | 굽힘·접촉 stress-cycle 계수 (피니언/기어 동시 산출) |
| `form_factor(N_p, N_g)` | Lewis Form Factor Y (Shigley Table 14-2) |

**응력 및 안전계수**

| 함수 | 설명 |
|---|---|
| `sgm(W_t, v, m_n, α_n, β, b, N_p, N_g)` | 실제 굽힘응력 σ (피니언·기어) |
| `sgm_all(N, u)` | 허용 굽힘응력 σ_all |
| `sgm_c(W_t, v, m_n, α_n, β, b, N_p, N_g)` | 실제 접촉응력 σ_c (기어쌍 단일값) |
| `sgm_c_all(N, u)` | 허용 접촉응력 σ_c,all |
| `S_F(N, W_t, v, m_n, α_n, β, b, N_p, N_g)` | **굽힘 안전계수** (피니언·기어) |
| `S_H(N, W_t, v, m_n, α_n, β, b, N_p, N_g)` | **접촉 안전계수** (피니언·기어) |

## 사용 예시

```matlab
% 정적 파손 평가 (중실 원형축, 굽힘 + 비틀림)
[n_DE, n_MSS] = static.SF_MT(M=120e3, T=80e3, d=40, S_y=400);

% 헬리컬 기어 안전계수
[S_F_p, S_F_g] = AGMA.S_F(N=1e8, W_t=2500, v=5.2, ...
                          m_n=2.5, alpha_n=20, beta=15, ...
                          b=30, N_p=20, N_g=36);
[S_H_p, S_H_g] = AGMA.S_H(1e8, 2500, 5.2, 2.5, 20, 15, 30, 20, 36);
```

`main.m`에 보정계수 단위 테스트 예시 포함.

## 향후 작업
- `+fatigue/` : 피로 파손이론 (Goodman, Soderberg, Gerber)
- `+bearing/` : 베어링 수명 평가
- AGMA 재료/정밀도 등급 매개변수화 (현재 침탄강·Q_v=6 하드코딩)
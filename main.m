clc
clear

K_v = AGMA.K_v(0.262)
[K_s_p, K_s_g] = AGMA.K_s(2.5, 0, 18, 20, 36)
K_H = AGMA.K_H(2.5, 0, 18, 20)
Z_I = AGMA.Z_I(2.5, 20, 20,36)
[Z_N_p,Z_N_g] = AGMA.Z_N(1e8, 1.8)
[Y_N_p,Y_N_G] = AGMA.Y_N(1e8,1.8)
[Y_J_p,Y_J_g] = AGMA.Y_J_(0,20,36)

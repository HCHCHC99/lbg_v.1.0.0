%% params.m
% 电机参数和观测器参数集中配置
% 运行后把参数存入 MATLAB 工作区
% Simulink 模型通过结构体引用这些参数

clear; clc;

fprintf('========================================\n');
fprintf('加载电机参数和观测器参数\n');
fprintf('========================================\n\n');

%% ========== 电机参数 ==========
motor.p        = 10;              % 极对数
motor.Rs       = 0.1;             % 定子电阻 (Ohm)
motor.Ls       = 4.23e-5;         % 定子电感 (H)
motor.psi_f    = 8.4e-4;          % 永磁磁链 (Wb)

fprintf('电机参数:\n');
fprintf('  p        = %d\n', motor.p);
fprintf('  Rs       = %.4f Ohm\n', motor.Rs);
fprintf('  Ls       = %.4e H\n', motor.Ls);
fprintf('  psi_f    = %.4e Wb\n', motor.psi_f);
fprintf('\n');

%% ========== 观测器参数 ==========
obs.Ts         = 50e-6;           % 采样周期 (s)
obs.zeta       = 1;               % 阻尼比
obs.wn         = 6000;            % 观测器带宽 (rad/s)

% 观测器增益
obs.l1         = 2*obs.zeta*obs.wn - motor.Rs/motor.Ls;
obs.l2         = motor.Ls * obs.wn^2;

fprintf('观测器参数:\n');
fprintf('  Ts       = %.1e s\n', obs.Ts);
fprintf('  zeta     = %.2f\n', obs.zeta);
fprintf('  wn       = %.0f rad/s\n', obs.wn);
fprintf('  l1       = %.2f\n', obs.l1);
fprintf('  l2       = %.2f\n', obs.l2);
fprintf('\n');

%% ========== PLL 参数 ==========
pll.zeta       = 0.9;             % PLL 阻尼比
pll.wn         = 1256.6;          % PLL 带宽 (rad/s)
pll.omega_e    = 1047.2;          % 额定电角速度 (rad/s)，对应 1000 rpm

% PLL 等效增益
pll.K          = pll.omega_e * motor.psi_f;

% PLL 增益
pll.kp         = 2*pll.zeta*pll.wn / pll.K;
pll.ki         = pll.wn^2 / pll.K;

fprintf('PLL 参数:\n');
fprintf('  zeta     = %.2f\n', pll.zeta);
fprintf('  wn       = %.1f rad/s\n', pll.wn);
fprintf('  omega_e  = %.1f rad/s\n', pll.omega_e);
fprintf('  K        = %.4f\n', pll.K);
fprintf('  kp       = %.2f\n', pll.kp);
fprintf('  ki       = %.4e\n', pll.ki);
fprintf('\n');

%% ========== 仿真参数 ==========
sim.Ts         = 50e-6;           % 仿真步长 (s)
sim.StopTime   = 0.03;            % 仿真停止时间 (s)
sim.omega_e    = 8168.1409;       % 电角速度输入 (rad/s)，对应 7800 rpm

fprintf('仿真参数:\n');
fprintf('  Ts       = %.1e s\n', sim.Ts);
fprintf('  StopTime = %.2f s\n', sim.StopTime);
fprintf('  omega_e  = %.4f rad/s\n', sim.omega_e);
fprintf('\n');

%% ========== 派生参数（用于验证） ==========
derived.omega_e_max = motor.p * 2 * pi * 7800 / 60;   % 最高电角速度
derived.f_e_max     = derived.omega_e_max / (2*pi);   % 最高电气频率
derived.wn_Ts       = obs.wn * obs.Ts;                % 离散化裕度
derived.wn_we_ratio = obs.wn / derived.omega_e_max;   % 跟踪比

fprintf('派生参数:\n');
fprintf('  omega_e_max = %.1f rad/s\n', derived.omega_e_max);
fprintf('  f_e_max     = %.1f Hz\n', derived.f_e_max);
fprintf('  wn*Ts       = %.4f (应 < 0.3)\n', derived.wn_Ts);
fprintf('  wn/we_max   = %.4f (应 > 1)\n', derived.wn_we_ratio);
fprintf('\n');

fprintf('========================================\n');
fprintf('参数加载完成\n');
fprintf('========================================\n');
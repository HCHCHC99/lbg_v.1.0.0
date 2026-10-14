%% link_functions.m
% 自动改 4 个 MATLAB Function：
% 1. 加输入端口（Rs, Ls, Ts, l1, l2, kp, ki）
% 2. 删掉代码里写死的参数行
% 3. 加 Constant 模块
% 4. 连接新端口

clear; clc;

%% 加载参数
run('F:\SIMULINK\Luenberger_BLDC\scripts\test2\params.m');

%% 打开模型
model_path = 'F:\SIMULINK\Luenberger_BLDC\scripts\test2\lbg.slx';
[~, model_name, ~] = fileparts(model_path);

if ~bdIsLoaded(model_name)
    load_system(model_path);
end

fprintf('\n模型已加载: %s\n\n', model_name);

%% ========== 1. 改 luenberger_step ==========
fprintf('---------- 改 luenberger_step ----------\n');
blk = [model_name '/luenberger_step'];
sf_root = sfroot;
chart = sf_root.find('-isa', 'Stateflow.EMChart', '-and', 'Path', blk);

if isempty(chart)
    error('找不到 luenberger_step');
end

% 新代码
new_code = sprintf([ ...
    'function x_hat_next = luenberger_step(x_hat, u_alpha, u_beta, i_alpha, i_beta, omega_hat, Rs, Ls, Ts, l1, l2)\n' ...
    '    i_alpha_hat = x_hat(1);\n' ...
    '    i_beta_hat  = x_hat(2);\n' ...
    '    e_alpha_hat = x_hat(3);\n' ...
    '    e_beta_hat  = x_hat(4);\n' ...
    '\n' ...
    '    di_alpha = (-Rs/Ls)*i_alpha_hat - (1/Ls)*e_alpha_hat + (1/Ls)*u_alpha + l1*(i_alpha - i_alpha_hat);\n' ...
    '    di_beta  = (-Rs/Ls)*i_beta_hat  - (1/Ls)*e_beta_hat  + (1/Ls)*u_beta  + l1*(i_beta  - i_beta_hat);\n' ...
    '\n' ...
    '    i_alpha_hat_next = i_alpha_hat + Ts*di_alpha;\n' ...
    '    i_beta_hat_next  = i_beta_hat  + Ts*di_beta;\n' ...
    '\n' ...
    '    theta = omega_hat * Ts;\n' ...
    '    R = [cos(theta), -sin(theta); sin(theta), cos(theta)];\n' ...
    '    e_rot = R * [e_alpha_hat; e_beta_hat];\n' ...
    '    e_alpha_hat_next = e_rot(1) + Ts*(-l2)*(i_alpha - i_alpha_hat);\n' ...
    '    e_beta_hat_next  = e_rot(2) + Ts*(-l2)*(i_beta  - i_beta_hat);\n' ...
    '\n' ...
    '    x_hat_next = [i_alpha_hat_next; i_beta_hat_next; e_alpha_hat_next; e_beta_hat_next];\n' ...
    'end\n']);

chart.Script = new_code;
fprintf('代码已改，新增输入端口 Rs, Ls, Ts, l1, l2\n');

% 加 Constant
add_constant(model_name, 'Rs_const', 'motor.Rs', [100 400]);
add_constant(model_name, 'Ls_const', 'motor.Ls', [100 450]);
add_constant(model_name, 'Ts_const', 'obs.Ts', [100 500]);
add_constant(model_name, 'l1_const', 'obs.l1', [100 550]);
add_constant(model_name, 'l2_const', 'obs.l2', [100 600]);

% 连接
connect_const(model_name, 'Rs_const', 'luenberger_step', 7);
connect_const(model_name, 'Ls_const', 'luenberger_step', 8);
connect_const(model_name, 'Ts_const', 'luenberger_step', 9);
connect_const(model_name, 'l1_const', 'luenberger_step', 10);
connect_const(model_name, 'l2_const', 'luenberger_step', 11);

%% ========== 2. 改 pll_step ==========
fprintf('\n---------- 改 pll_step ----------\n');
blk = [model_name '/pll_step'];
chart = sf_root.find('-isa', 'Stateflow.EMChart', '-and', 'Path', blk);

if isempty(chart)
    error('找不到 pll_step');
end

new_code = sprintf([ ...
    'function [theta_hat, omega_hat, integ_next] = pll_step(e_alpha, e_beta, theta_hat_prev, integ_prev, Ts, kp, ki)\n' ...
    '    e_alpha = e_alpha(1);\n' ...
    '    e_beta  = e_beta(1);\n' ...
    '\n' ...
    '    epsilon = -e_alpha*cos(theta_hat_prev) - e_beta*sin(theta_hat_prev);\n' ...
    '\n' ...
    '    omega_hat = kp*epsilon + integ_prev;\n' ...
    '    integ_next = integ_prev + Ts*ki*epsilon;\n' ...
    '    theta_hat = mod(theta_hat_prev + Ts*omega_hat, 2*pi);\n' ...
    'end\n']);

chart.Script = new_code;
fprintf('代码已改，新增输入端口 Ts, kp, ki\n');

add_constant(model_name, 'Ts_const_pll', 'obs.Ts', [100 700]);
add_constant(model_name, 'kp_const', 'pll.kp', [100 750]);
add_constant(model_name, 'ki_const', 'pll.ki', [100 800]);

connect_const(model_name, 'Ts_const_pll', 'pll_step', 5);
connect_const(model_name, 'kp_const', 'pll_step', 6);
connect_const(model_name, 'ki_const', 'pll_step', 7);

%% ========== 3. 改 motor_step ==========
fprintf('\n---------- 改 motor_step ----------\n');
blk = [model_name '/motor_step'];
chart = sf_root.find('-isa', 'Stateflow.EMChart', '-and', 'Path', blk);

if isempty(chart)
    error('找不到 motor_step');
end

new_code = sprintf([ ...
    'function [i_alpha_next, i_beta_next, e_alpha_next, e_beta_next] = motor_step(i_alpha, i_beta, e_alpha, e_beta, u_alpha, u_beta, omega_e, Rs, Ls, Ts)\n' ...
    '    di_alpha = (-Rs/Ls)*i_alpha - (1/Ls)*e_alpha + (1/Ls)*u_alpha;\n' ...
    '    di_beta  = (-Rs/Ls)*i_beta  - (1/Ls)*e_beta  + (1/Ls)*u_beta;\n' ...
    '\n' ...
    '    i_alpha_next = i_alpha + Ts*di_alpha;\n' ...
    '    i_beta_next  = i_beta  + Ts*di_beta;\n' ...
    '\n' ...
    '    theta = omega_e * Ts;\n' ...
    '    R = [cos(theta), -sin(theta); sin(theta), cos(theta)];\n' ...
    '    e_rot = R * [e_alpha; e_beta];\n' ...
    '    e_alpha_next = e_rot(1);\n' ...
    '    e_beta_next  = e_rot(2);\n' ...
    'end\n']);

chart.Script = new_code;
fprintf('代码已改，新增输入端口 Rs, Ls, Ts\n');

add_constant(model_name, 'Rs_const_m', 'motor.Rs', [100 900]);
add_constant(model_name, 'Ls_const_m', 'motor.Ls', [100 950]);
add_constant(model_name, 'Ts_const_m', 'obs.Ts', [100 1000]);

connect_const(model_name, 'Rs_const_m', 'motor_step', 8);
connect_const(model_name, 'Ls_const_m', 'motor_step', 9);
connect_const(model_name, 'Ts_const_m', 'motor_step', 10);

%% ========== 4. 改 angle_calc ==========
fprintf('\n---------- 改 angle_calc ----------\n');
blk = [model_name '/angle_calc'];
chart = sf_root.find('-isa', 'Stateflow.EMChart', '-and', 'Path', blk);

if isempty(chart)
    error('找不到 angle_calc');
end

new_code = sprintf([ ...
    'function theta_e = angle_calc(omega_e, theta_prev, Ts)\n' ...
    '    theta_e = mod(theta_prev + Ts*omega_e, 2*pi);\n' ...
    'end\n']);

chart.Script = new_code;
fprintf('代码已改，新增输入端口 Ts\n');

add_constant(model_name, 'Ts_const_a', 'obs.Ts', [100 1100]);

connect_const(model_name, 'Ts_const_a', 'angle_calc', 3);

%% ========== 5. 保存 ==========
save_system(model_name);
fprintf('\n模型已保存。\n');

%% ========== 辅助函数 ==========
function add_constant(model_name, const_name, const_value, pos)
    blk = [model_name '/' const_name];
    try
        get_param(blk, 'BlockType');
        set_param(blk, 'Value', const_value);
        fprintf('  Constant %s 已存在，值改为 %s\n', const_name, const_value);
    catch
        add_block('simulink/Sources/Constant', blk, ...
            'Position', [pos(1) pos(2) pos(1)+40 pos(2)+30]);
        set_param(blk, 'Value', const_value);
        fprintf('  已加 Constant %s = %s\n', const_name, const_value);
    end
end

function connect_const(model_name, const_name, func_name, port)
    const_blk = [model_name '/' const_name];
    func_blk = [model_name '/' func_name];

    ph_const = get_param(const_blk, 'PortHandles');
    ph_func = get_param(func_blk, 'PortHandles');

    if port > length(ph_func.Inport)
        fprintf('  警告：%s 没有输入端口 %d\n', func_name, port);
        return;
    end

    % 删除旧线
    line = get_param(ph_func.Inport(port), 'Line');
    if line ~= -1
        delete_line(line);
    end

    % 连接
    try
        add_line(model_name, ph_const.Outport(1), ph_func.Inport(port), 'autorouting', 'on');
        fprintf('  已连接 %s -> %s 端口 %d\n', const_name, func_name, port);
    catch ME
        fprintf('  连接失败: %s -> %s（%s）\n', const_name, func_name, ME.message);
    end
end
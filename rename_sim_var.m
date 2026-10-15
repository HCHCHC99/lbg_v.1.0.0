%% rename_sim_var.m
% 把 lbg.slx 里对 sim 结构体的引用改名为 simCfg
% 原因：base workspace 里的 sim 结构体会遮盖 MATLAB 内置的 sim() 命令，
% 导致脚本里的 sim(model_name) 被当成结构体索引而报错
% 运行顺序：先跑本脚本，再跑 params.m

clear; clc;

model_path = 'F:\SIMULINK\Luenberger_BLDC\scripts\test2\lbg.slx';
[~, model_name, ~] = fileparts(model_path);

if ~bdIsLoaded(model_name)
    load_system(model_path);
end

fprintf('模型已加载: %s\n\n', model_name);

%% 求解器参数
solver_params = {'FixedStep', 'StopTime'};
for i = 1:length(solver_params)
    pname = solver_params{i};
    val = get_param(model_name, pname);
    if contains(val, 'sim.')
        new_val = strrep(val, 'sim.', 'simCfg.');
        set_param(model_name, pname, new_val);
        fprintf('%-10s: %s -> %s\n', pname, val, new_val);
    else
        fprintf('%-10s: 无需修改 (%s)\n', pname, val);
    end
end

%% omega_e 常数模块
omega_block = [model_name '/omega_e'];
val = get_param(omega_block, 'Value');
if contains(val, 'sim.')
    new_val = strrep(val, 'sim.', 'simCfg.');
    set_param(omega_block, 'Value', new_val);
    fprintf('%-10s: %s -> %s\n', 'omega_e', val, new_val);
else
    fprintf('%-10s: 无需修改 (%s)\n', 'omega_e', val);
end

%% 保存
save_system(model_name);
fprintf('\n模型已保存。\n');

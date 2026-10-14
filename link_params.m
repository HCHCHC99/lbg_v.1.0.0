%% link_params.m
% 把 lbg.slx 里能改的参数改成引用 params.m 的结构体
% 不改 MATLAB Function 里的代码

clear; clc;

%% 先跑 params.m 加载参数
fprintf('加载 params.m...\n');
run('F:\SIMULINK\Luenberger_BLDC\scripts\test2\params.m');
fprintf('\n');

%% 打开模型
model_path = 'F:\SIMULINK\Luenberger_BLDC\scripts\test2\lbg.slx';
[~, model_name, ~] = fileparts(model_path);

if ~bdIsLoaded(model_name)
    load_system(model_path);
end

fprintf('模型已加载: %s\n\n', model_name);

%% ========== 1. 改 omega_e Constant ==========
fprintf('---------- 改 omega_e Constant ----------\n');
try
    set_param([model_name '/omega_e'], 'Value', 'sim.omega_e');
    fprintf('omega_e = sim.omega_e\n');
catch ME
    fprintf('失败: %s\n', ME.message);
end

%% ========== 2. 改所有 Unit Delay 采样时间 ==========
fprintf('\n---------- 改 Unit Delay 采样时间 ----------\n');
ud_blocks = find_system(model_name, 'BlockType', 'UnitDelay');
for i = 1:length(ud_blocks)
    try
        set_param(ud_blocks{i}, 'SampleTime', 'obs.Ts');
        fprintf('%s: SampleTime = obs.Ts\n', ud_blocks{i});
    catch ME
        fprintf('%s: 失败（%s）\n', ud_blocks{i}, ME.message);
    end
end

%% ========== 3. 改求解器 ==========
fprintf('\n---------- 改求解器 ----------\n');
try
    set_param(model_name, 'FixedStep', 'sim.Ts');
    fprintf('FixedStep = sim.Ts\n');
catch ME
    fprintf('FixedStep 失败: %s\n', ME.message);
end
try
    set_param(model_name, 'StopTime', 'sim.StopTime');
    fprintf('StopTime = sim.StopTime\n');
catch ME
    fprintf('StopTime 失败: %s\n', ME.message);
end

%% ========== 4. 保存 ==========
save_system(model_name);
fprintf('\n模型已保存。\n');

%% ========== 5. 验证 ==========
fprintf('\n---------- 验证 ----------\n');
fprintf('omega_e = %s\n', get_param([model_name '/omega_e'], 'Value'));
fprintf('FixedStep = %s\n', get_param(model_name, 'FixedStep'));
fprintf('StopTime = %s\n', get_param(model_name, 'StopTime'));

ud_blocks = find_system(model_name, 'BlockType', 'UnitDelay');
for i = 1:length(ud_blocks)
    fprintf('%s: SampleTime = %s\n', ud_blocks{i}, ...
        get_param(ud_blocks{i}, 'SampleTime'));
end

fprintf('\n完成。\n');
fprintf('\n注意：MATLAB Function 里的参数还是写死的，需要手动改。\n');
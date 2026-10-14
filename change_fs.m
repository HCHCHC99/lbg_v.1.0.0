%% change_fs.m
% 把采样频率改成 20 kHz (Ts = 50 us)
% 需要改: 求解器步长、Unit Delay 采样时间、MATLAB Function 里的 Ts

clear; clc;

%% 打开模型
model_path = 'F:\SIMULINK\Luenberger_BLDC\scripts\test2\lbg.slx';
[~, model_name, ~] = fileparts(model_path);

if ~bdIsLoaded(model_name)
    load_system(model_path);
end

fprintf('模型已加载: %s\n', model_name);

%% 新采样周期
Ts_new = 50e-6;

%% 1. 改求解器固定步长
set_param(model_name, 'FixedStep', num2str(Ts_new));
fprintf('求解器固定步长已改成 %.1e\n', Ts_new);

%% 2. 改所有 Unit Delay 的采样时间
ud_blocks = find_system(model_name, 'BlockType', 'UnitDelay');
for i = 1:length(ud_blocks)
    set_param(ud_blocks{i}, 'SampleTime', num2str(Ts_new));
end
fprintf('所有 Unit Delay 采样时间已改成 %.1e\n', Ts_new);

%% 3. 改 4 个 MATLAB Function 里的 Ts
mf_blocks = {'luenberger_step', 'pll_step', 'motor_step', 'angle_calc'};
sf_root = sfroot;

for i = 1:length(mf_blocks)
    block_path = [model_name '/' mf_blocks{i}];
    sf_chart = sf_root.find('-isa', 'Stateflow.EMChart', '-and', 'Path', block_path);
    if ~isempty(sf_chart)
        code = sf_chart.Script;
        % 替换所有 Ts = 2.5e-05 或 Ts = 25e-6 或 Ts = 2.5e-5 为 Ts = 50e-6
        code_new = code;
        code_new = strrep(code_new, 'Ts = 2.5e-05', sprintf('Ts = %.1e', Ts_new));
        code_new = strrep(code_new, 'Ts = 2.5e-5',  sprintf('Ts = %.1e', Ts_new));
        code_new = strrep(code_new, 'Ts = 25e-6',   sprintf('Ts = %.1e', Ts_new));
        code_new = strrep(code_new, 'Ts = 25e-05',  sprintf('Ts = %.1e', Ts_new));

        if ~strcmp(code, code_new)
            sf_chart.Script = code_new;
            fprintf('已改 %s 的 Ts 为 %.1e\n', mf_blocks{i}, Ts_new);
        else
            fprintf('警告: %s 里没找到 Ts = 2.5e-5 或类似值，请手动检查\n', mf_blocks{i});
        end
    else
        fprintf('警告: 找不到 %s 的 Stateflow 对象\n', mf_blocks{i});
    end
end

%% 保存
save_system(model_name);
fprintf('\n模型已保存。\n');

%% 验证
fprintf('\n---------- 验证 ----------\n');
fprintf('FixedStep: %s\n', get_param(model_name, 'FixedStep'));

ud_blocks = find_system(model_name, 'BlockType', 'UnitDelay');
for i = 1:length(ud_blocks)
    st = get_param(ud_blocks{i}, 'SampleTime');
    fprintf('%s: SampleTime = %s\n', ud_blocks{i}, st);
end

fprintf('\n---------- MATLAB Function 里的 Ts ----------\n');
for i = 1:length(mf_blocks)
    block_path = [model_name '/' mf_blocks{i}];
    sf_chart = sf_root.find('-isa', 'Stateflow.EMChart', '-and', 'Path', block_path);
    if ~isempty(sf_chart)
        code = sf_chart.Script;
        lines = strsplit(code, newline);
        for j = 1:length(lines)
            if contains(lines{j}, 'Ts =')
                fprintf('%s: %s\n', mf_blocks{i}, strtrim(lines{j}));
            end
        end
    end
end
%% list_files.m
% 列出当前文件夹下所有 .slx 和 .m 文件

clear; clc;

%% 当前文件夹
current_dir = pwd;
fprintf('当前文件夹: %s\n\n', current_dir);

%% 列出所有 .slx 文件
fprintf('========================================\n');
fprintf('模型文件 (.slx)\n');
fprintf('========================================\n');
slx_files = dir(fullfile(current_dir, '*.slx'));
for i = 1:length(slx_files)
    fprintf('%2d. %-50s  %s\n', i, slx_files(i).name, ...
        datestr(slx_files(i).datenum, 'yyyy-mm-dd HH:MM'));
end
fprintf('共 %d 个 .slx 文件\n\n', length(slx_files));

%% 列出所有 .m 文件
fprintf('========================================\n');
fprintf('脚本文件 (.m)\n');
fprintf('========================================\n');
m_files = dir(fullfile(current_dir, '*.m'));
for i = 1:length(m_files)
    fprintf('%2d. %-50s  %s\n', i, m_files(i).name, ...
        datestr(m_files(i).datenum, 'yyyy-mm-dd HH:MM'));
end
fprintf('共 %d 个 .m 文件\n\n', length(m_files));

%% 列出所有 .mat 文件
fprintf('========================================\n');
fprintf('数据文件 (.mat)\n');
fprintf('========================================\n');
mat_files = dir(fullfile(current_dir, '*.mat'));
for i = 1:length(mat_files)
    fprintf('%2d. %-50s  %s\n', i, mat_files(i).name, ...
        datestr(mat_files(i).datenum, 'yyyy-mm-dd HH:MM'));
end
fprintf('共 %d 个 .mat 文件\n\n', length(mat_files));

%% 列出所有 .png 文件
fprintf('========================================\n');
fprintf('图片文件 (.png)\n');
fprintf('========================================\n');
png_files = dir(fullfile(current_dir, '*.png'));
for i = 1:length(png_files)
    fprintf('%2d. %-50s  %s\n', i, png_files(i).name, ...
        datestr(png_files(i).datenum, 'yyyy-mm-dd HH:MM'));
end
fprintf('共 %d 个 .png 文件\n\n', length(png_files));

%% 列出所有子文件夹
fprintf('========================================\n');
fprintf('子文件夹\n');
fprintf('========================================\n');
subdirs = dir(current_dir);
subdirs = subdirs([subdirs.isdir]);
subdirs = subdirs(~ismember({subdirs.name}, {'.', '..'}));
for i = 1:length(subdirs)
    fprintf('%2d. %s\n', i, subdirs(i).name);
end
fprintf('共 %d 个子文件夹\n\n', length(subdirs));

fprintf('========================================\n');
fprintf('完成\n');
fprintf('========================================\n');
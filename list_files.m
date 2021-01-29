% adapted from https://github.com/jcouto/matlab
function [files,all_files] = list_files(folder, mask, level, exception_level1, exception_level2)
% Lists files that follow mask excluding the files that have the
% exceptions. On  UNIX it uses the awesome find command.
% In Windows it uses the dir method.. Only exception_level1 one is working on Windows.
%
% [files,all_files] = list_files(folder, mask, level, exception_level1, exception_level2)
%
%    * folder -  is the target folder under which to search for
%    files [default "./"]
%    * mask - the mask [default "*"]
%    * level - how many levels to search [default 'all'] if empty,
%    uses default.
%    * exception_level1 - level 1 exceptions are meant to exclude
%    files that contain a particular pattern. [default {}]
%    * exception_level2 - level 2 exceptions are meant to exclude
%    files whose filename is similar to that
%    particular pattern but don't fit the mask.
%
% Example:
%
% files = list_files('.','*.h5',2,{'trash'},{'*_kernel.dat'})
% Lists all h5 files for folders 2 levels bellow with the exception
% of those used for the kernel protocol and those in trash folders.
%


% Uses UNIX find command.
if ~exist('folder','var'), folder = '.'; end
if ~exist('mask','var'), mask = '*'; end
if ~exist('level','var')||isempty(level), level = 'all'; end
if ~exist('exception_level1','var'), exception_level1 = {}; end
if ~exist('exception_level2','var'), exception_level2 = {}; end

if isempty(strfind(computer,'WIN'))
    find_cmd = sprintf('find %s -name "%s"',folder,mask);
    if isnumeric(level)
        find_cmd = sprintf('%s -maxdepth %d',find_cmd, level);
    end
    files = run_system_command(find_cmd);
    files = regexp(files,'\n','split');
    % Remove the last element of files because it is the result of
    % regexp 'split'.
    files = files(1:end-1);
    all_files = files;
    for ii = 1:length(exception_level1)
        files = files(cellfun(@(x)isempty(regexp(x,exception_level1{ii})), files));
    end
    
    for ii = 1:length(exception_level2)
        find_cmd = sprintf('find %s -name "%s"',folder,exception_level2{ii});
        if isnumeric(level)
            find_cmd = sprintf('%s -maxdepth %d',find_cmd, level);
        end
        except_files = run_system_command(find_cmd);
        except_files = regexp(except_files,'\n','split');
        except_files = except_files(1:end-1);
        for except_name = except_files
            except_name = except_name{1}(1:end-length(exception_level2{ii}));
            files = files(cellfun(@(x)isempty(regexp(x,except_name)), files));
        end
    end
    % Return columns for readability
    if ~iscolumn(files),files = files';end
    if ~iscolumn(all_files),all_files = all_files';end
else
    % Fix the level to work with the recursive dir function
    if isstr(level)
        if strcmp(level,'all')
            level = Inf;
        end
    end
    unfiltered_files = recursive_dir(folder, level);
    % replace * with regexp pattern
    mask_pattern = strrep(mask,'.','\.');
    mask_pattern = strrep(mask_pattern,'*','(.+)?');
    all_files = unfiltered_files(~cellfun(@isempty,regexp(unfiltered_files,...
        mask_pattern)));
    files = all_files;
    for ii = 1:length(exception_level1)
        files = files(cellfun(@(x)isempty(regexp(x,exception_level1{ii})), files));
    end  
end


function out = run_system_command(COMMAND)
% Runs a system command and returns
[result, out] = system(COMMAND);
if result
     error(['list_files error parsing: ', COMMAND])
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%% FOR THE WINDOWS SCRIPT %%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [file_list] = recursive_dir(folder, level)
% Helper function to list files under Windows
% This was modified of something in MatlabCentral
if level < 1
    unfiltered_files = {};
end

full_list = dir(folder);  % List all files and folders in the current directory
dir_idx = [full_list.isdir];
file_list = {full_list(~dir_idx).name}';
if ~isempty(file_list)
    file_list = cellfun(@(x) fullfile(folder,x),...
        file_list,'UniformOutput',false);
end
% Validate subdirectory names
directories = {full_list(dir_idx).name};
directories = cellfun(@(x)fullfile(folder,x),...
    directories(~ismember(directories,{'.','..'})),...
    'uniformoutput',false)';

for i = 1:length(directories)      % Recursive call on subdirs
    level = level - 1 ;
    [files] =  recursive_dir(directories{i}, level);
    file_list = [file_list; files];
end


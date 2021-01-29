function idx = update_cluster_group(group_file,metric_file)

% backup cluster_group.tsv
backup_file = strrep(group_file,'cluster_group.tsv','cluster_group.tsv.bak');

if isfile(backup_file)
    tmp_group_file = backup_file;
    tmp_file = strrep(tmp_group_file,'cluster_group.tsv.bak','cluster_group.csv');
    copyfile(tmp_group_file,tmp_file)
    disp('backup exists')
else
    tmp_group_file = group_file;
    % backup 
    copyfile(tmp_group_file,backup_file)
    %csv convertion because of readtable matlab function
    tmp_file = strrep(tmp_group_file,'cluster_group.tsv','cluster_group.csv');
    copyfile(tmp_group_file,tmp_file)
    disp('backup created')
end

% read cluster_group.tsv file
tmp_group = fopen(tmp_group_file,'r');
C = textscan(tmp_group,'%d\t%s','headerlines',1);
fclose(tmp_group);
ig =  contains(C{2},'good');
in = contains(C{2},'noise');

%read metric file
Tmetric = readtable(metric_file);

% apply Allen thresholds
idx = Tmetric.amplitude_cutoff<0.1&...
    Tmetric.presence_ratio>0.95&...
    Tmetric.isi_viol<0.5&...
    ig;

%read csv file
Tcluster = readtable(tmp_file);
%change labels of the table
Tcluster.group (idx) = {'good'};
Tcluster.group(~idx&~in) ={'mua'};
%write table
writetable(Tcluster,tmp_file,'delimiter','\t')
%create tsv file again
copyfile(tmp_file,group_file)
%remove csv file
delete(tmp_file)
fprintf('good=%d mua=%d noise=%d\n',sum(idx),sum(~idx&~in),sum(in))

end


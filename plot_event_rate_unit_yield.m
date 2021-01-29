clear all
close all
clc


filtered_folder = '\\169.254.103.43\haeslerlab\users\cagatay\np1_implant_paper\accepted';
figure_folder =  'E:\local\users\cagatay\np1_implant_paper\';


%% update cluster_groups.tsv file with defined thresholds 

tmp = list_files(filtered_folder,'metrics.csv');

for ii = 1:2:length(tmp)
  [file_path,name,ext]=fileparts(tmp{ii});
  id = split(file_path,filesep);
  disp(id{end-1})
  group_file = sprintf('%s%s%s',file_path,filesep,'cluster_group.tsv');
  
  idx = update_cluster_group(group_file,tmp{ii});

end
  

%% read data files
% hparams.txt - user defined meta file (contains; recording date, probe...)
% XX.meta - meta file generated via spikeglx during the data acqusition
% files indicated below generated via neuropixels evaluations tools
% XX.ap_sum.txt - summary metrics 
% XX.ap_chan.txt - metrics generated for each channel across the shank
% XX.ap_hist.txt - spike amplitudes histogram 
% cluster_group.tsv - summary file indicating unit yield generated via KS2

tmp_info = list_files(filtered_folder,'hparams.txt');

dat = [];
for ii = 1:length(tmp_info)
    
    % read hparams file generated manually by user
    
    fid = fopen(tmp_info{ii});
    tmp_header = textscan(fid,'%s%s%s%s%s,',1,'delimiter',',');
    tmp_value = textscan(fid,'%s%s%s%d%d','delimiter',',','headerlines',1);
    fclose(fid);
    
    tmp_date = tmp_value{1};
    an = char(tmp_value{2});
    tot_probe = tmp_value{4};
    probe = tmp_value{5};
    spicy = char(tmp_value{3});
    
    dat(ii).date = datenum(tmp_date,'yymmdd');
    dat(ii).dat_srt = tmp_date;
    dat(ii).animal = an;
    dat(ii).probe = probe;
    
    %%read meta file and extract serial of the probe
    
    tt = fileparts(tmp_info{ii});
    tmp_bin= list_files(tt,'.meta');
    [ppath, nname, ext] = fileparts(tmp_bin{:});
    meta = read_only_meta(sprintf('%s%s',nname,ext),ppath);
    tmp_serial = meta.imDatPrb_sn;
    dat(ii).serial = str2double(tmp_serial(end-4:end));
    
    %%read sumary file generated by neuropixels evaluation tools
    
    tt = fileparts(tmp_info{ii});
    tmp_analyzed= list_files(tt,'.ap_sum');
    
    tmpid = fopen(tmp_analyzed{:},'r');
    formatspec = '%s\t%.3f\t%.3f\t%.3f\t%.3f\t%d\t%.3f\t%.3f\t%.3f\t%.3f\n';
    A = textscan(tmpid,formatspec,'headerlines',1);
    dat(ii).filename = A{1};    
    dat(ii).rms = A{7};
    dat(ii).rmsstd = A{8};
    dat(ii).ev = A{2};
    dat(ii).t50 = A{3};
    dat(ii).t90 = A{4};
    dat(ii).t99 = A{5};
    fclose(tmpid);
    
    % read metrics for each channel generated by
    % neuropixels evaluation tools
    
    tmp_raw= list_files(tt,'.ap_chan');
    tmpraw = fopen(tmp_raw{:},'r');
    B = textscan(tmpraw,'%d\t%d\t%d\t%d\t%.3f\t%.3f\t%.3f\t%.3f\t%.3f\n','headerlines',1);
    
    dat(ii).raw_depth = B{3};
    dat(ii).raw_ch = B{4};
    dat(ii).raw_rms = B{5};
    dat(ii).raw_ev = B{6};
    dat(ii).raw_amp = B{7};
    dat(ii).raw_t90 = B{8};
    dat(ii).raw_t99 = B{9};
    fclose(tmpraw);
    
    
    % read spike amplitude histograms generated by
    % neuropixels evaluation tools
    
    tmp_amp_raw= list_files(tt,'.ap_hist');
    ttmpraw = fopen(tmp_amp_raw{:},'r');
    D = textscan(ttmpraw,'%.3f\t%d\t%s','headerlines',1);
    dat(ii).hist_bin = D{1};
    dat(ii).hist_amp = D{2};
    fclose(ttmpraw);
    
    
    % read unit yield generated by kilosort 2 and
    % good units are selected by using thresholds explained above
    % https://github.com/jenniferColonell/ecephys_spike_sorting
    
    tt_sort = list_files(tt,'cluster_group.tsv');
    
    if isempty(tt_sort)
        dat(ii).good = nan;
        dat(ii).mua = nan;
        dat(ii).noise = nan;
    else
        sort_file = fopen(tt_sort{1},'r');
        C = textscan(sort_file,'%s\t%s','headerlines',1);
        dat(ii).good = sum(contains(C{2},'good'));
        dat(ii).mua = sum(contains(C{2},'mua'));
        dat(ii).noise = sum(contains(C{2},'noise'));
        fclose(sort_file);
    end
    
end


%% Fig 11g-h --> plot for event rates for different type of fixtures

printfigure = 0;

clf,
ax = [];
mm=1;

% since the day of implantation for each animal
time_start = [3,3,6];

tmp_date = vertcat(dat.date);
[all_date, date_idx]= sort(tmp_date);

a = {};
for ii = 1:length(date_idx)
    a{ii} = dat(date_idx(ii)).animal;
end

an_list = unique(a);
an_idx = {};
for ia = 1:length(an_list)
    an_idx{ia} = contains(a,an_list(ia));
end

tmp_ev = vertcat(dat.ev);
all_ev = tmp_ev(date_idx);

tmp_probe = vertcat(dat.probe);
all_probe = tmp_probe(date_idx);

tmp_good = vertcat(dat.good);
all_good = tmp_good(date_idx);

tmp_serial = vertcat(dat.serial);
all_serial = tmp_serial(date_idx);

ccol = lines(6);
ccol = ccol([2,3,4],:);

for ii = 1:length(an_idx)
    uprobes = unique(all_probe(an_idx{ii}));
    userial = unique(all_serial(an_idx{ii}));
    for jj = 1:length(uprobes)
        
        p_idx = all_serial==userial(jj);        
        idx = an_idx{ii}&p_idx';        
        tmpx = all_date(idx)-min(all_date(idx))+time_start(ii);
        
        ax(1) = subplot(211);
        all_ev(all_ev==0)=1;
        log_all_ev = log10(all_ev);
        
        plot(tmpx,log_all_ev(idx),'o','color',ccol(ii,:),...
            'markersize',mm,'markerfacecolor',ccol(ii,:),...
            'linewidth',1),hold on
        
        p1 = polyfit(tmpx,log_all_ev(idx),1);
        plot(tmpx,polyval(p1,tmpx),'color',ccol(ii,:))
        
        set(ax(end),'ylim',[0 3])
        ylabel('Event rate (Hz)')
        xlabel('Days since implantation')
        
        
        ax(2) = subplot(212);
        all_good(all_good==0)=1;
        log_all_good = log10(all_good);
        plot(tmpx,log_all_good(idx),'o','color',ccol(ii,:),...
            'markersize',mm,'markerfacecolor',ccol(ii,:),...
            'linewidth',1),hold on
        p1 = polyfit(tmpx,log_all_good(idx),1);
        plot(tmpx,polyval(p1,tmpx),'color',ccol(ii,:))
        
        ylabel('Cluster count')
        xlabel('Days since implantation')
        set(ax(end),'ylim',[0 3])
        
    end
    
end

% generating ticks for y axis in log
tmp_tick = [0,1,2,3,4,5];
cell_tick ={};
for it = 1:length(tmp_tick)
    cell_tick{it} = num2str(tmp_tick(it),'10^%d');
end

set(ax(:),'box','off','ticklength',get(ax(end),'ticklength').*3,...
    'tickdir','out','fontsize',7,'fontname','arial',...
    'linewidth',0.5,'yscale','linear','ygrid','off','ytick',tmp_tick,...
    'yticklabel',cell_tick,'xlim',[2 20])

set(gcf,'papersize',[2.5,2*2],'paperposition',[0,0,2.5,2*2])

figure_name = sprintf('%s%s%s%s%s',figure_folder,filesep,'figures\',date,'_event_rates_n_1m','.pdf');
if printfigure
    print(gcf,'-dpdf','-loose',figure_name)
end

%% Fig 11e --> plot amplitude for MC01

clf
animal =1;
printfigure = 0;

tmp_raw_amp = horzcat(dat.hist_amp);
all_raw_amp = tmp_raw_amp(:,date_idx);

tmp_raw_bin = horzcat(dat.hist_bin);
all_raw_bin = tmp_raw_bin(:,date_idx);

userial = unique(all_serial(an_idx{animal}));
uprobes = unique(all_probe(an_idx{animal}));
for jj = 1:length(uprobes)
    p_idx = all_serial==userial(jj);
    
    idx = an_idx{animal}&p_idx';
    tmpx = all_date(idx)-min(all_date(idx))+time_start(animal);
    nn=find(idx);
    ccol = copper(sum(idx)+5);
    ax = [];
    for ii = 1:sum(idx)
        x = all_raw_bin(:,nn(ii));
        y = double(all_raw_amp(:,nn(ii)));
        normy = double(y./sum(y));
        ax = [ax,subplot(1,1,1)];
        plot(x,normy,'color',ccol(ii,:),'linewidth',1),hold on
        if ii==sum(idx)
        legend_cell = cellstr(num2str(tmpx,'day %d'));
        legend(ax(end),legend_cell,'location','eastoutside')
        
        end
    end    

    xlabel('amplitude (uV)');
    ylabel('fraction #spikes');
    set(ax,'xscale','log','xlim',[75 300],'box','off','tickdir','out',...
        'ticklength',get(ax(end),'ticklength').*3,'fontsize',7,...
        'fontname','arial',...
        'linewidth',.5)
        
    set(gcf,'papersize',[2.5,1.5],'paperposition',[0,0,2.5,1.5])
    
    figure_name = sprintf('%s%s%s%s%s',figure_folder,filesep,'figures\',date,'log_amp_n','.pdf');
    if printfigure
        print(gcf,'-dpdf','-loose',figure_name)
    end
    
end

%% Fig 11f --> plot events for MC01
clf
animal = 1;
printfigure = 0;

for ii = 1:length(dat)
    tmp_raw_ev(:,ii) = dat(ii).raw_rms(1:359);
    tmp_raw_depth(:,ii) = dat(ii).raw_depth(1:359);
end

all_raw_ev = tmp_raw_ev(:,date_idx);
all_raw_depth = tmp_raw_depth(:,date_idx);

userial = unique(all_serial(an_idx{animal}));
uprobes = unique(all_probe(an_idx{animal}));
for jj = 1:length(uprobes)
        
    p_idx = all_serial==userial(jj);
    
    idx = an_idx{animal}&p_idx';
    nn=find(idx);
    tmpx = all_date(idx)-min(all_date(idx))+time_start(1);
        
    ax = [];
    im = flipud(all_raw_ev(:,nn));
    
    ax = [ax,subplot(1,1,1)];
    imagesc(imgaussfilt(im,2))
    colormap(flipud(gray))
    colorbar
    set(ax,'clim',[5 10])
    
    depth_step = 60;
    yytick = 1:depth_step:size(all_raw_ev(:,idx),1);
    yyticklabel = -1.*all_raw_depth(1:depth_step:end,find(idx==1,[1],'first'),:);
    set(ax(end),'box','off','xtick',(1:length(tmpx)),'xticklabel',tmpx',...
        'tickdir','out','fontsize',6,'fontname','arial',...
        'linewidth',0.5,'ytick',yytick,'yticklabel',yyticklabel)
    
    ylabel('Depth (um)')
    xlabel('Days since implantation')
    
    set(gcf,'papersize',[2.5,2],'paperposition',[0,0,2.5,2])
    
    
    figure_name = sprintf('%s%s%s%s%s',figure_folder,filesep,'figures\',date,'mc01_event','.pdf');
    if printfigure
        print(gcf,'-dpdf','-loose',figure_name)
    end
    
end


%Load BSRN and compare site data
clearvars
tic
%find all the file paths of all existing site summaries
disp('Searching for BSRN summary files.');
root=[pwd,'\'];
dir_root=dir(root);
folder_names={dir_root([dir_root.isdir]).name};
% remove "." and ".." from the list
folder_names(1:2)=[];
% dont count the BSRN Toolbox
folder_names(strcmp(folder_names,'BSRN Toolbox'))=[];
% ignore the zz_bin
folder_names(strcmp(folder_names,'zz_bin'))=[];

data_files=cell(size(folder_names));
time_files=cell(size(folder_names));
sites=cell(size(folder_names));
count=1;
for fol=1:length(folder_names)         
   data_file_path=[root,folder_names{fol},'\',folder_names{fol},'_summary.csv'];
   time_file_path=[root,folder_names{fol},'\',folder_names{fol},'_time_datevecs.csv'];
   if (exist(data_file_path,'file') && exist(time_file_path,'file')) 
%        store it
       data_files{count}=data_file_path;
       time_files{count}=time_file_path;
       sites{count}=folder_names{fol};
       count=count+1;
   end  
end
data_files=data_files(1:count-1);
time_files=time_files(1:count-1);
sites=sites(1:count-1);

disp([' ... ',num2str(count-1),' site summaries found out of ',num2str(length(folder_names)),' sites on the ftp.']);
%only keep appropriate variables for memory assistance
clearvars -except data_files time_files sites

% make time series from earliest observed to latest. Earliest time=1992
t=datenum('01011992','ddmmyyyy'):1/1440:datenum('01022018','ddmmyyyy')-(1/1440);
t_datevecs=datevec(t);

% Make perfect arrays of each variable
% each one of these is 7.657 GB...
disp(['Combining all sites into single .mat file.']);
disp(' ... preallocating matrices')
G=zeros(length(t),length(sites)).*NaN;
disp(['    - ',num2str(round(100/6)),' % complete'])
B=zeros(length(t),length(sites)).*NaN;
disp(['    - ',num2str(round(200/6)),' % complete'])
D=zeros(length(t),length(sites)).*NaN;
disp(['    - ',num2str(round(300/6)),' % complete'])
T=zeros(length(t),length(sites)).*NaN;
disp(['    - ',num2str(round(400/6)),' % complete'])
RH=zeros(length(t),length(sites)).*NaN;
disp(['    - ',num2str(round(500/6)),' % complete'])
P=zeros(length(t),length(sites)).*NaN;
disp(['    - ',num2str(round(600/6)),' % complete'])

%loop through each available file and extract the relevant data
for i=1:length(data_files)
    % load this sites data
    % this takes around 15-30 seconds 
    disp([' ... processing ',sites{i},'. ',num2str(round(100*i/length(data_files))),' % complete']);
    data=csvread(data_files{i});
    
    % Vars of interest are in the following columns: [3 7 11 19 20 21] 
    % vars_of_interest={'G','B','D','T','RH','P'};
    % extract each piece of data.
    G_site_data=data(:,3);
    B_site_data=data(:,7);
    D_site_data=data(:,11);
    T_site_data=data(:,19);
    RH_site_data=data(:,20);
    P_site_data=data(:,21);
    clear data
    
    % load the time series
    times=csvread(time_files{i});
    % convert to datenum
    times_datenum=datenum(times);
    % find the row reference according to the start and end time
    row_ref_start=find(t==times_datenum(1));
    row_ref_end=find(t==times_datenum(end));
    
    G(row_ref_start:row_ref_end,i)=G_site_data;
    B(row_ref_start:row_ref_end,i)=B_site_data;
    D(row_ref_start:row_ref_end,i)=D_site_data;
    T(row_ref_start:row_ref_end,i)=T_site_data;
    RH(row_ref_start:row_ref_end,i)=RH_site_data;
    P(row_ref_start:row_ref_end,i)=P_site_data;    
    
end

% only keep variables to save sites
clearvars -except G B D T RH P t_datevecs sites
disp('Saving the all site summary to file.');
save('BSRN_all_site_summary.mat','-v7.3')
disp('... Complete.')
toc







%% sample some BSRN data
%set folder dir
base_file_path=[pwd,'\'];
% extract folder contents
allFiles = dir(base_file_path);
% extract only the folders
sites={allFiles([allFiles.isdir]).name};
% *U0100 formatspec
% formatspec='%{yyyy-MM-dd''T''HH:mm}D%*s%f%*s%*s%*s%f%*s%*s%*s%f%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%[^\n\r]';
%from gcos docuent
% 0100 basic measurements
% Line 1) day, miute, global 2 (mean, std.dev., min., max.,: columns 12-31), direct (mean, std.dev., min., max.,: columns 35-54)
% Line 2) diffuse (mean, std.dev., min., max.,: columns 12-31), downward long-wave radiation (mean, std.dev., min., max.,: columns 35-54), air temp, rh3, pressure
% Lin2 3) date [day], ....
%     2 lines for each time measured.
% missing data is either -1, -999 or -99.9

% the files do not have a consistency with the number of spaces used,
% however, the white space is always the same. This means that, so long as
% multiple spaces are treated as a single delimiter, then the data shall
% read.

% from man1101.dat
% 15 1263    240 -99.9 -999 -999    410 -99.9 -999 -999
%            123 -99.9 -999 -999    411 -99.9 -999 -999     27.6  88.6 1008
% from ale0105.dat
%  3  999      0   0.1 -999 -999     -1   0.3 -999 -999
%              0   0.1 -999 -999    187   0.2 -999 -999    -26.3  77.8  992

table_vars={'day_of_month','minute_of_day','G_irrad','G_stddev','G_min','G_max','B','B_stddev','B_min','B_max','D','D_stddev','D_min','D_max','dlwr','dlwr_stddev','dlwr_min','dlwr_max','air_temp_at_dlwr_height','rh_at_dlwr_height','p_at_dlwr_height'};
% formatspec must adhere to the above
% [I2,I4,F5.1,F5.1,F5.1,F5.1,F5.1,F5.1,F5.1,F5.1]
% [F5.1,F5.1,F5.1,F5.1,F5.1,F5.1,F5.1,F5.1,F5.1,F5.1,I4]
% all are satisfactory with a double
formatspec='%f%f%f%f%f%f%f%f%f%f%f';

%the first two cells must be hidden files of "." and ".." so loop starts at 3
for site=3:length(sites)
    if strcmpi(sites{site},'bsrn toolbox')==0
        % set this site's dir path
        site_dir=[base_file_path,sites{site},'\'];
        disp(['Processing site ',sites{site}]);
        
        if ~exist([site_dir,sites{site},'_summary.csv'],'file')
            
            % extract all the relevant files
            allFiles_in_site_dir=dir([site_dir,sites{site},'*.dat']);
            % as the upper and current dir of "." and ".." exist, remove with an isdir query
            file_names={allFiles_in_site_dir(~[allFiles_in_site_dir.isdir]).name};
            % if file_names is empty, then there are no .dat files to process
            if ~isempty(file_names)
                % clean the file_names for any rouge site*.dats that slipped
                % through the net. e.g. car0205Version1.dat
                updated_file_names=cell(size(file_names));
                exceptions=0;
                for i=1:length(file_names)
                    if length(file_names{i})==11
                        updated_file_names{i-exceptions}=file_names{i};
                    else
                        exceptions=exceptions+1;
                    end
                end
                updated_file_names(end-exceptions+1:end)=[];
                
                
                % total number of files is now the length of file_names
                num_of_files=length(updated_file_names);
                % set timer logic
                fnames=cell2mat(updated_file_names');
                mms=fnames(:,4:5);
                yys=fnames(:,6:7);
                yysn=zeros(size(fnames,1),1);
                mmsn=zeros(size(fnames,1),1);
                for i=1:size(fnames,1)
                    yysn(i)=str2double(yys(i,:));
                    mmsn(i)=str2double(mms(i,:));
                end
                yysn(yysn>50)=yysn(yysn>50)+1900;
                yysn(yysn<50)=yysn(yysn<50)+2000;
                
                latest_yr=find(yysn==max(yysn));
                mm_end=max(mmsn(latest_yr));
                yy_end=max(yysn);
                earliest_yr=find(yysn==min(yysn));
                mm_start=min(mmsn(earliest_yr));
                yy_start=min(yysn);
                if mm_end<9
                    mme=['0',num2str(mm_end+1)];
                else
                    mme=num2str(mm_end+1);
                end
                if strcmp(mme,'13')==1
                    yy_end=yy_end+1;
                    mme='01';
                end
                
                end_time_str=[mme,num2str(yy_end)];
                end_t=datenum(end_time_str,'mmyyyy');
                if mm_start<10
                    mms=['0',num2str(mm_start)];
                else
                    mms=num2str(mm_start);
                end
                start_time_str=[mms,num2str(yy_start)];
                start_t=datenum(start_time_str,'mmyyyy');
                times=start_t:1/1440:end_t-1/1440;
                
                % preallocate empty matrix
                site_data=zeros(length(times),21).*NaN; %make NaNs for full year with empty space. preallocation much faster
                % loop through each file
                for file=1:num_of_files
                    % open the file with read privaleges
                    disp(['...reading file: ',updated_file_names{file}])
                    fid=fopen([site_dir,updated_file_names{file}],'r');
                    all_dat_str=permute(fread(fid,'*char'),[2,1]);
                    fclose(fid);
                    
                    
                    U0008_pos=regexp(all_dat_str,'\n\s**[CU]0008\s*\n','end');
                    str_starting_at_U0008=all_dat_str(U0008_pos-1:end);
                    radiation_measurements_ind=str_starting_at_U0008(regexp(str_starting_at_U0008,'[YN]','start','once'));
                    
                    %extract month and year
                    mmyy=updated_file_names{file};
                    mme=str2double(mmyy(4:5));
                    yy=str2double(mmyy(6:7));
                    if yy<50
                        yy=yy+2000;
                    elseif yy>50
                        yy=yy+1900;
                    end
                    start_ind=find(times==datenum(mmyy(4:7),'mmyy'));
                    end_ind=start_ind-1+60*24*eomday(yy,mme);
                    temp_site_dat=zeros(length(start_ind:end_ind),21).*NaN;
                    time_references=times(start_ind:end_ind);
                    
                    %only process this file should there be radiation measurements
                    if strcmp(radiation_measurements_ind,'Y')
                        
                        % open the file and extract each row into individual cell
                        fid=fopen([site_dir,updated_file_names{file}],'r');
                        all_dat_line_separated  = textscan( fid, '%s', 'Delimiter', '\n' );
                        fclose(fid);
                        
                        % find the number of headerlines up to C or U0100
                        C=find(strcmp(strtrim(all_dat_line_separated{1,1}),'*C0100'));
                        U=find(strcmp(strtrim(all_dat_line_separated{1,1}),'*U0100'));
                        if (isempty(C) && ~isempty(U))
                            headerlines=U;
                        elseif (~isempty(C) && isempty(U))
                            headerlines=C;
                        end
                        
                        %find the next data set to indicate the end row
                        U0100_pos=regexp(all_dat_str,'*[CU]0100','end');
                        str_starting_at_U0100=all_dat_str(U0100_pos-1:end);
                        next_dataset_ind=regexp(str_starting_at_U0100,'[*]','start','once');
                        %if the next_dataset_ind is empty, it means that [CU]0100 is the last dataset
                        if ~isempty(next_dataset_ind)
                            next_dataset=str_starting_at_U0100(next_dataset_ind:next_dataset_ind+5);
                            endrow=find(strcmp(all_dat_line_separated{1,1},next_dataset))-1;
                        else
                            endrow=length(all_dat_line_separated{1,1});
                        end
                        
                        % Must ignore any lines before and including the line containing
                        % '*U0100' and then any lines after and including '*U1000'
                        try
                            fid=fopen([site_dir,updated_file_names{file}],'r');
                            data=textscan(fid,formatspec,'Headerlines',headerlines);
                            fclose(fid);
                            %convert cell into a matrix
                            data=cell2mat(data);
                        catch
                            % in certain cases where the files have been
                            % opened, a carriage return is occasionally
                            % applied to the end of each line converting
                            % from BSRN standard of \n to \r\n.
                            fid=fopen([site_dir,updated_file_names{file}],'r');
                            data=textscan(fid,formatspec,'Headerlines',headerlines,'EndOfLine','\r\n');
                            fclose(fid);
                            %convert cell into a matrix
                            data=cell2mat(data);
                        end
                        
                        % combine the alternat rows of 10;11;10 etc into a single table
                        data=[data(1:2:end-1,1:10),data(2:2:end,:)];
                        data(data==-999)=NaN;
                        data(data==-99.9)=NaN;
                        
                        % certain files end prematurely, e.g. asp1205 ends at
                        % 31 869 instead of 1440. Missing data inbetween is
                        % assigned NaNs, however, it appears not missing data
                        % at the end. Because of this, it is importnat to only
                        % allocate the dates within a pre-defined time spaced
                        % dataset.
                        intended_length=size(temp_site_dat,1);
                        actual_length=size(data,1);
                        if actual_length==intended_length
                            site_data(start_ind:end_ind,:)=data;
                        else
                            data_datenums=datenum([yy.*ones(size(data,1),1),mme.*ones(size(data,1),1),data(:,1),floor(data(:,2)./60),mod(data(:,2),60),zeros(size(data,1),1)]);
                            [inds,d]=knnsearch(time_references',data_datenums);
                            temp_site_dat(inds,:)=data;
                            site_data(start_ind:end_ind,:)=temp_site_dat;
                        end
                        
                    end
                end
                
                % save the outcome
                disp(['Saving data for site: ',sites{site}]);
                save_path=[site_dir,sites{site},'_summary.csv'];
                dlmwrite(save_path,single(site_data));
                save_path=[site_dir,sites{site},'_time_datevecs.csv'];
                dlmwrite(save_path,int16(datevec(times)));
            end
        end
    end
end
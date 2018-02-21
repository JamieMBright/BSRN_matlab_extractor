%% Unzip any remaining bsrn data


%current folder
folder=[pwd,'\'];

%Get dirs in current
filenames=dir(folder);
filenames=filenames(3:end);

for i=1:length(filenames)
    
    if filenames(i).isdir==1
        
        temp_folder=[folder,filenames(i).name,'\'];
        temp_files=dir([temp_folder,'*.gz']);
        
        for j=1:length(temp_files)
            zipped_filepath=[temp_folder,temp_files(j).name]
            try
                % TRY A GNU UNZIP
                gunzip(zipped_filepath);
                delete(zipped_filepath);
                
                
            catch err                
                disp([err.message,' reverting from gunzip to unzip.'])
                
                try
                    % STANDARD UNZIP AND DELETE
                    unzip(zipped_filepath);
                    delete(zipped_filepath);
                    
                catch err
                    disp([err.message,' unzip also failed, skipping this file.'])
                end
                
            end
            
        end
        
        % delete any folders that are within this folder (e.g. any old folders)
         temp_files=dir(temp_folder);
        for j=3:length(temp_files)
            if temp_files(j).isdir==1
                if strcmp(temp_folder,[folder,'BSRN Toolbox\'])==0
                    full_name=[temp_folder,temp_files(j).name];
                    dos_cmd = sprintf( 'rmdir /S /Q "%s"', full_name );
                    [ st, msg ] = system( dos_cmd );
                end
            end
        end
         
         
         
    end
    
end







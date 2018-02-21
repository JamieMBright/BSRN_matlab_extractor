# BSRN_matlab_extractor
Process and extract all BSRN data from the raw format straight from ftp download. It includes the unzipping of .data.gz files, the removal of older versions, the reading of the .dat files and the combining of each site into a a single .csv.

# Instructions
First, retrieve all BSRN files through the ftp server (you will have to email BSRN representative for username and password). 
Secondly, download the matlab scripts and place them in the parent directory that cointains each BSRN site's directories.

Running unzip_unzippable_files.m will loop through each folder and unzip any .dat.gz files. the original .dat.gz file will be deleted. 

Next, read_bsrn_dat_files.m will load each .dat file data that has radiation data (U0100 data) and produce a single data matrix for each site. This output file will be called [site]summary.csv and is also accompanied by Matlab's datevec timestamping that corelates to each row of the summary.csv. 

Finally, running combine_all_BSRN_site_summaries_into_single_mat_file.m will produce a .mat file that contains rows representing timestamps from 1992:2018 with 1 min resolution, and each column is a BSRN site as referenceable by the sites variable. The data stored in these are G (global horizontal irradiance), B (direct/beam normal irradiance), D (diffuse horizontal irradiance), T (ambient temperature at station height), P (atmospheric pressure at height above sea level), and RH (the relative humidity at height above sea level). Note that this script may demand more of your computer than is feasible. If this is the case, it is advised to comment out 5/6 output variables and run each variable in turn. 

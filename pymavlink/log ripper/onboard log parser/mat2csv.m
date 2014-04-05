%% mat2csv
% read a .mat file, created by log_parser.m, and output one or more message
% histories into .csv files

clear variables;

%specify file
fname = uigetfile;

outmask = '1000';

if ~strcmp(fname(end-2:end), 'mat')
    error('Invalid file');
else
    load(fname);
    for i = 1:length(outmask)
        if str2num(outmask(i))
           disp(['Message "' labels{i}(1:end-2) '" will be output.']);
           %export data{i}
           foutname = [fname(1:end-4) '_' labels{i}(1:end-2) '.csv'];
           fid = fopen(foutname,'wt');
           %output data labels
           for j = 1:length(datalabels{i})
               fprintf(fid,'%s,',datalabels{i}{j});
           end
           fprintf(fid,'\n');
           %output data
           for j = 1:size(data{i},1)
               fprintf(fid,'%g,',data{i}(j,:));
               fprintf(fid,'\n');
           end
           fclose(fid);
        end
    end
end
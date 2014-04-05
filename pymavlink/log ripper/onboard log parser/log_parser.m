%% log_parser
%parse a csv log from mission planner or equivalent
%into a usable MAT format
% NOTE: global_position.relative_alt seems to use the same data as vfr_hud.alt, this may
% indicate that it is a more accurate data stream than global_position.alt

fname = uigetfile('.txt');

fid = fopen(fname,'r');

%load mavlink messages of the following types ("mavlink_%s"). Save in cell
%array with the same dimensions.
labels = {'global_position_int_t','attitude_t','vfr_hud_t','ahrs_t'};
data = cell(size(labels));%store data here
datalabels = cell(size(labels));%store the label of each data vector here
counter = zeros(length(labels),1);

%assume we don't know the length of each message. Determine the length the
%first time we see the message, then initialize arrays from that.

%loop over FID. Log messages of the same type as "labels"
while ~feof(fid)
    line = fgets(fid);
    %separate by commas
    commas = find(line==',');
    if length(commas)>7
        %line(commas(7)+1:commas(8)-1) is the message label
        msg = line(commas(7)+1:commas(8)-1);
        %see if the msg contains the labels:
        chklabels = regexpi(msg,labels);
        for i = 1:length(labels)
            if ~isempty(chklabels{i})
                %parse this
                counter(i) = counter(i)+1;
                if counter(i) == 1
                    %parse to discover msg size
                    %there are "length(commas)+1-8-3" remaining useful
                    %values, half are labels and half are data
                    for j = 1:(length(commas)+1-8-3)/2
                        datalabels{i}{j} = line(commas(7+2*j-1)+1:commas(7+2*(j))-1);
                        values(j) = str2num(line(commas(7+2*j)+1:commas(7+2*j+1)-1));
                    end
                    data{i} = zeros(1e5,length(values));
                else
                    for j = 1:(length(commas)+1-8-3)/2
                        values(j) = str2num(line(commas(7+2*j)+1:commas(7+2*j+1)-1));
                    end
                end
                data{i}(counter(i),:) = values;
            end
        end
    end
end

%eliminate unused vectors
for i = 1:length(labels)
    data{i}(counter(i)+1:end,:) = [];
end

%% close file and save
matname = [fname(1:end-3),'mat'];
save(matname,'data','datalabels','labels');

fclose(fid);
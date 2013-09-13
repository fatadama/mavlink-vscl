% open a .bat file from mavlogripper.py, convert to .MAT file and .CSV file

clear variables;
EXCEL = 0;

EXCEL = 0;

[filename,pathname] = uigetfile({'*.dat'});
filename = [pathname, filename];
fid = fopen(filename,'r+');

%filename without extension:
dotname = filename(1:end-3);

nummsgs = 0;
messages = {};
msg_len = [];
msg_hdrs = cell(1,1);
msg_count = [];
data = {};
time = {};%store the time vector for each message
%parse each line
while ~feof(fid)
    %parse until read semicolon thrice -> message ID
    line = fgets(fid);
    %read the time - initial time is 1800 hrs = 1080 minutes
    [garbage, remain] = strtok(line,' ');
    remain(1) = [];%delete the spacebar character
    hrs = str2num(remain(1:2)) - 18;
    mins = str2num(remain(4:5));
    secs = str2num(remain(7:8));
    csecs = str2num(remain(10:11));
    nowTime = 3600*hrs+60*mins+secs+.01*csecs;%current time in seconds
    [garbage, remain] = strtok(remain,':');
    [garbage, remain] = strtok(remain,':');
    [garbage, remain] = strtok(remain,':');
    remain = remain(3:end);
    %get the message ID
    [msg_id,remain] = strtok(remain,' ');
    if ~strcmp(msg_id,{'PARAM_VALUE','STATUSTEXT'})
       %ignore param_value messages b/c they have a string in them and that
       %sucks
        remain = remain(3:end);%cut off the ' {' chars
        if isempty( strmatch(msg_id,messages) )%if this is a new message, determine its size and initialize variables
            nummsgs = nummsgs + 1;
            msg_hdrs{nummsgs} = {};
            msg_count = [msg_count 1];
            %store the msg_id
            messages = [messages;msg_id];
            %track how long the message is
            msg_len = [msg_len 0];
            %msg_hdrs{end+1} = {};% = {msg_hdrs; {}};
            %store the first line of the message here temporarily:
            line1 = [];
            % read 'remain'
            while length(remain>1)
                %get the label
                [label,remain] = strtok(remain,' : ');
                msg_len(end) = msg_len(end) + 1;
                msg_hdrs{nummsgs}{msg_len(end)} = label;
                %get the data
                remain = remain(4:end);
                %check if we are at the end of the data
                if strcmp(remain, strtok(remain,', '))
                    [value,remain] = strtok(remain,'}');
                    line1 = [line1 str2num(value)];
                    break;
                else
                    [value,remain] = strtok(remain,', ');
                    line1 = [line1 str2num(value)];
                end
                remain = remain(3:end);
            end
            % initialize arrays to store this message data and store the first line
            data{nummsgs} = zeros(1e5,msg_len(end));
            time{nummsgs} = zeros(1e5,1);
            time{nummsgs}(1) = nowTime;
            data{nummsgs}(1,:) = line1;
        else
            %figure out which message this is
            msgint = strmatch(msg_id,messages);
            msg_count(msgint) = msg_count(msgint) + 1;
            for i = 1:msg_len(msgint)
                %get the label
                [~,remain] = strtok(remain,' : ');
                %get the data
                remain = remain(4:end);
                value = '';
                %check if we are at the end of the data
                if strcmp(remain, strtok(remain,', '))
                    [value,remain] = strtok(remain,'}');
                else
                    [value,remain] = strtok(remain,', ');
                    remain = remain(3:end);
                end
                data{msgint}(msg_count(msgint),i) = str2num(value);
                time{msgint}(msg_count(msgint)) = nowTime;
            end
        end
    end
end

<<<<<<< HEAD
%export to .mat
save([dotname, 'mat'],'data','messages','msg_count','msg_hdrs');
=======
%truncate the data vectors:
for i = 1:nummsgs
    data{i}(msg_count(i)+1:end,:) = [];
    time{i}(msg_count(i)+1:end) = [];
end

%export to .mat
save([dotname, 'mat'],'data','messages','msg_count','msg_hdrs','time');
>>>>>>> 721d38b60baed8a5741de6bfbd651c913122a67e
if EXCEL
    %export to xls, multisheet
    for i = 1:nummsgs
        xlswrite([dotname,'xls'],msg_hdrs{i},messages{i},'A1');
        for j = 1:msg_count(i)
            xlswrite([dotname,'xls'],data{i}(j,:),messages{i},['A' num2str(j+1)]);
        end
    end

end
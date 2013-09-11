% open a .bat file from mavlogripper.py, convert to .MAT file and .CSV file

clear variables;

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
while ~feof(fid)
    %parse until read semicolon thrice -> message ID
    line = fgets(fid);
    [garbage, remain] = strtok(line,':');
    [garbage, remain] = strtok(remain,':');
    [garbage, remain] = strtok(remain,':');
    remain = remain(3:end);
    %get the message ID
    [msg_id,remain] = strtok(remain,' ');
    if ~strcmp(msg_id,{'PARAM_VALUE','STATUSTEXT'})
       %ignore param_value messages b/c they have a string in them and that
       %sucks
        remain = remain(3:end);%cut off the ' {' chars
        if isempty( strmatch(msg_id,messages) )
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
            end
        end
    end
end

%export to .mat
save([dotname, 'mat'],'data','messages','msg_count','msg_hdrs');
if EXCEL
    %export to xls, multisheet
    for i = 1:nummsgs
        xlswrite([dotname,'xls'],msg_hdrs{i},messages{i},'A1');
        for j = 1:msg_count(i)
            xlswrite([dotname,'xls'],data{i}(j,:),messages{i},['A' num2str(j+1)]);
        end
    end

end
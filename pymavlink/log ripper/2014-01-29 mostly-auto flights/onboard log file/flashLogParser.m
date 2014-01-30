%APM flash log parser
clear variables;

fname = '2013-09-14 12-14 4.log';
[fname,pathname] = uigetfile({'*.txt'});
fname = [pathname, fname];

fid = fopen(fname,'r+');

logcount = 20;%decrement log count

tic;
while ~feof(fid);
    %% here loop through the file
    
    % skip until we see "GROUND START"
    while 1
        line = fgets(fid);
        if strfind(line,'GROUND START');
            if strfind(line(1:14),'GROUND START')
                break;
            end
        end
        if feof(fid);
            break;
        end
        disp(line);
    end
    if feof(fid);
        break;
    end
    %%
    %intialize arrays for speed
    att = zeros(1e4,3);attcount = 0;
    raw = zeros(1e4,6);rawcount = 0;
    fhp = zeros(1e4,6);fhpcount = 0;
    ctrl = zeros(1e4,4);ctrlcount = 0;
    gps = zeros(1e4,10);gpscount = 0;
    pm = zeros(1e4,13);pmcount = 0;
    cmd = zeros(1e4,6);cmdcount = 0;
    mod = cell(1e4,1);modcount = 0;
    % we will need to know the time when the modes switch - 
    crossovers = [];%save the GPS index of each crossover
    while ~feof(fid)
        line = fgets(fid);
        [IDtype,rem] = strtok(line,':');
        rem = rem(2:end);
        switch IDtype
            case 'MOD'
                modcount = modcount+1;
                [temp,rem] = strtok(rem,',');
                mod{modcount} = temp;
                crossovers = [crossovers gpscount];%GPS values at crossover(i)+1 are in a different mode than at crossover(i)
            case 'CMD'
                %read CMD data
                cmdcount=cmdcount+1;
                for i = 1:6
                    [temp,rem] = strtok(rem,',');
                    cmd(cmdcount,i) = str2double(temp);
                    if i<6
                        rem = rem(2:end);
                    end
                end
            case 'ATT'%roll, pitch, yaw
                %read attitude data
                attcount = attcount+1;
                for i = 1:3
                    [temp,rem] = strtok(rem,',');
                    att(attcount,i) = str2double(temp);
                    if i<3
                        rem = rem(2:end);
                    end
                end
            case 'RAW' %gyro x, y, z accel x, y, z
                %read raw IMU data
                rawcount=rawcount+1;
                for i = 1:6
                    [temp,rem] = strtok(rem,',');
                    raw(rawcount,i) = str2double(temp);
                    if i<6
                        rem = rem(2:end);
                    end
                end
            case 'FHP'%sensor0, sensor1,sensor2, sensor3, temp, humdity
                fhpcount = fhpcount+1;
                for i = 1:6
                    [temp,rem] = strtok(rem,',');
                    fhp(fhpcount,i) = str2double(temp);
                    if i<6
                        rem = rem(2:end);
                    end
                end
            case 'CTRL'%elevator, throttle, aileron, pitch
                ctrlcount = ctrlcount+1;
                for i =1:4
                    [temp,rem] = strtok(rem,',');
                    ctrl(ctrlcount,i) = str2double(temp);
                    if i<4
                        rem = rem(2:end);
                    end
                end
            case 'GPS'%time(ms), fix, numsats, lat (deg), longidtude (Deg) , 0, log_mix_alt?,  gps_alt, ground speed, ground course (heading)
                gpscount = gpscount+1;
                for i = 1:10
                    [temp,rem] = strtok(rem,',');
                    gps(gpscount,i) = str2double(temp);
                    if i<10
                        rem = rem(2:end);
                    end
                end
            case 'PM'
                pmcount = pmcount+1;
                for i = 1:13
                    [temp,rem] = strtok(rem,',');
                    pm(pmcount,i) = str2double(temp);
                    if i<13
                        rem = rem(2:end);
                    end
                end
            otherwise
                %input('Break so user can figure out what the new data are');
                if strfind(line,'Number of packets')
                    break;
                end
        end
    end
    
    %delete unused arrays
    pm(pmcount+1:end,:) = [];
    gps(gpscount+1:end,:) = [];
    ctrl(ctrlcount+1:end,:) = [];
    fhp(fhpcount+1:end,:) = [];
    raw(rawcount+1:end,:) = [];
    att(attcount+1:end,:) = [];
    cmd(cmdcount+1:end,:) = [];
    mod(modcount+1:end) = [];
    
    %save .mat file
    save([pathname 'log_' num2str(logcount) '.mat']);
    logcount = logcount - 1;
    toc;
end
fclose(fid);

%   the rest of this is old and needs to be modified    %
%% process data
clear variables;
close all;
[fname,pathname] = uigetfile('*.mat');
load(fname);

%convert gps time to seconds
gps(:,1) = (gps(:,1) - gps(1,1))/1000;

%figure out when we are in manual mode
manual = [crossovers((1:ceil(length(crossovers)/2))*2-1)+1;
    crossovers((1:length(crossovers)/2)*2) length(gps)];
auto = [crossovers((1:length(crossovers)/2)*2)+1;
    crossovers((2:ceil(length(crossovers)/2))*2-1)];

manualindices = [];
autoindices = [];
for i = 1:size(manual,2)
    manualindices = [manualindices manual(1,i):manual(2,i)];
end
for i = 1:size(auto,2)
    autoindices = [autoindices auto(1,i):auto(2,i)];
end

% delete any times with no gps lock
inddel = find(gps(:,4)==0);

for i = 1:length(manualindices)
    if i > length(manualindices)
        break;
    end
    if gps(manualindices(i),4) == 0
        manualindices(i) = [];
        manualindices(i+1:end) = manualindices(i+1:end)-1;
    end
end
for i = 1:length(autoindices)
    if i > length(autoindices)
        break;
    end
    if gps(autoindices(i),4) == 0
        autoindices(i) = [];
        autoindices(i+1:end) = autoindices(i+1:end)-1;
    end
end
gps(inddel,:) = [];

gps(:,1) = gps(:,1) - gps(1,1);
gpstime = gps(:,1);
gps = gps(:,4:end);

%trim vectors to match gps length: gps is at 10 Hz, attitude at 10 Hz
if attcount<gpscount
    %extend the data vectors
    att(attcount+1:end,:) = 0;
else
    %truncate the data vectors
    att = att(1:gpscount,:);
end
att(inddel,:) = [];

% convert attitude to degrees
att = att./100;
%gps properties
alt = gps(:,4);
gspeed = gps(:,6);
ghdg = gps(:,7);

% plot GPS histories
figure;
subplot(211);
plot(gpstime(manualindices),gps(manualindices,2),'bx');
hold on;
plot(gpstime(autoindices),gps(autoindices,2),'rd');
ylabel('longitude (deg)');

subplot(212);
plot(gpstime(manualindices),gps(manualindices,1),'bx');
hold on;
plot(gpstime(autoindices),gps(autoindices,1),'rd');
ylabel('latitude (deg)');
% plot GPS long-lat history
figure;
plot(gps(manualindices,2),gps(manualindices,1),'bx');
hold on;
plot(gps(autoindices,2),gps(autoindices,1),'rd');
ylabel('lat');
xlabel('long');

% plot attitude histories
figure;
subplot(311);
plot(gpstime(manualindices),att(manualindices,1),'bx');
hold on;
plot(gpstime(autoindices),att(autoindices,1),'rd');
ylabel('roll (deg)');

subplot(312);
plot(gpstime(manualindices),att(manualindices,2),'bx');
hold on;
plot(gpstime(autoindices),att(autoindices,2),'rd');
ylabel('pitch (deg)');

subplot(313);
plot(gpstime(manualindices),att(manualindices,3),'bx');
hold on;
plot(gpstime(autoindices),att(autoindices,3),'rd');
ylabel('yaw (deg)');

% plot ground speed
figure;
subplot(211);
plot(gpstime(manualindices),gspeed(manualindices),'bx');
hold on;
plot(gpstime(autoindices),gspeed(autoindices),'rd');
ylabel('ground speed (m/s)');

subplot(212);
plot(gpstime(manualindices),alt(manualindices),'bx');
hold on;
plot(gpstime(autoindices),alt(autoindices),'rd');
ylabel('altitude (m)');
% %export to .mat
% save([fname(1:end-3) 'mat'],'gps','gpstime','time','att','ctrl','fhp','raw');
% %export to .csv
% 
% fid = fopen([fname(1:end-3) 'csv'],'wt');
% fprintf(fid,'time (sec),psensor0 (psi),psensor1 (psi),psensor2 (psi),psensor3(psi),temperature (C),humidity (%%?),roll (centidegrees),pitch(centidegrees),yaw(centidegrees),elevator (radio),throttle(radio),aileron(radio),rudder(radio),gyro x (rad/s?),gyro y (rad/s),gyro z (rad/s),accel x (m/s2),accel y (m/s2), accel z (m/s2)\n');
% for i = 1:length(time)
%     fprintf(fid,'%g,',[time(i) fhp(i,:) att(i,:) ctrl(i,:) raw(i,:)]);
%     fprintf(fid,'\n');
% end
% fclose(fid);
% 
% fid = fopen([fname(1:end-4) '_gps.csv'],'wt');
% fprintf(fid,'time (sec), lat (deg), long (deg), 0, altitude (fusion) (m), gps alt (m), ground speed (m/s), heading (deg)\n');
% for i = 1:length(gpstime)
%     fprintf(fid,'%g,',[gpstime(i) gps(i,:)]);
%     fprintf(fid,'\n');
% end
% fclose(fid);
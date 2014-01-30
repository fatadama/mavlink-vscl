%% autoland_test_process
close all;
if ~exist('messages','var')
    clear variables;
    [filename,pathname] = uigetfile({'*.mat'});
    filename = [pathname, filename];
    load(filename);
end

%% find when autoland times overlap attitude times
ind = find(strcmpi('VSCL_AUTOLAND',messages));
autolandTimes = data{ind}(:,1);

blocks = find(diff(autolandTimes) > 5000);
segments = zeros(length(blocks)+1,2);
for i = 1:length(blocks)+1
    if i == 1
        segments(i,1) = 1;
    else
        segments(i,1) = blocks(i-1)+1;
    end
    if i == length(blocks)+1
        segments(i,2) = length(autolandTimes);
    else 
        segments(i,2) = blocks(i);
    end
end
%% match attitude
ind = find(strcmpi('ATTITUDE',messages));
atttimes = data{ind}(:,1);
attvector = matchTimes(autolandTimes,segments,data{ind}(:,1));

figure;
subplot(311);
plot(data{ind}(:,1)*.001,data{ind}(:,2)*180/pi,'-x');
hold on;
plot(data{ind}(attvector,1)*.001,data{ind}(attvector,2)*180/pi,'rd');
set(gca,'xlim',1e-3*[min(data{ind}(:,1)) data{ind}(end,1)]);
ylabel('roll (deg)');

subplot(312);
plot(data{ind}(:,1)*.001,data{ind}(:,3)*180/pi,'-x');
hold on;
plot(data{ind}(attvector,1)*.001,data{ind}(attvector,3)*180/pi,'rd');
set(gca,'xlim',1e-3*[min(data{ind}(:,1)) data{ind}(end,1)]);
ylabel('pitch (deg)');

subplot(313);
plot(data{ind}(:,1)*.001,data{ind}(:,4)*180/pi,'-x');
hold on;
plot(data{ind}(attvector,1)*.001,data{ind}(attvector,4)*180/pi,'rd');
set(gca,'xlim',1e-3*[min(data{ind}(:,1)) data{ind}(end,1)]);
ylabel('yaw (deg)');
%% GPS 
ind = find(strcmpi('GLOBAL_POSITION_INT',messages));
gpsvector = matchTimes(autolandTimes,segments,data{ind}(:,1));

figure;
plot(data{ind}(:,3),data{ind}(:,2),'-x');
hold on;
plot(data{ind}(gpsvector,3),data{ind}(gpsvector,2),'rd');

figure
subplot(211);
plot(data{ind}(:,1),data{ind}(:,3),'-x');
hold on
plot(data{ind}(gpsvector,1),data{ind}(gpsvector,3),'rd');

subplot(212);
plot(data{ind}(:,1),data{ind}(:,2),'-x');
hold on
plot(data{ind}(gpsvector,1),data{ind}(gpsvector,2),'rd');
%% airspeed
ind = find(strcmpi('VFR_HUD',messages));
vfrtemp = 1:length(data{ind});
vfrtime = interp1(1:length(atttimes),atttimes,vfrtemp);
vfrvector = matchTimes(autolandTimes,segments,vfrtime);

figure;
plot(vfrtime,data{ind}(:,1),'-x');
hold on;
plot(vfrtime(vfrvector),data{ind}(vfrvector,1),'rd');
ylabel('airspeed (m/s)');
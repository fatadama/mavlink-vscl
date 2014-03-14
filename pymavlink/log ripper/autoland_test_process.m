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

% turns zeros to nans
data{ind}(data{ind}==0) = nan;

figure;
plot(data{ind}(:,3),data{ind}(:,2)*1e-7,'-x');
hold on;
plot(data{ind}(gpsvector,3),data{ind}(gpsvector,2)*1e-7,'rd');

figure
subplot(411);
plot(data{ind}(:,1),data{ind}(:,3)*1e-7,'-x');
hold on
plot(data{ind}(gpsvector,1),data{ind}(gpsvector,3)*1e-7,'rd');
ylabel('long (deg)');

subplot(412);
plot(data{ind}(:,1),data{ind}(:,2)*1e-7,'-x');
hold on
plot(data{ind}(gpsvector,1),data{ind}(gpsvector,2)*1e-7,'rd');
ylabel('lat (deg)')

subplot(413);
plot(data{ind}(:,1),data{ind}(:,5)*1e-2,'-x');
hold on
plot(data{ind}(gpsvector,1),data{ind}(gpsvector,5)*1e-2,'rd');
ylabel('alt (m)');

subplot(414);
plot(data{ind}(:,1),1e-2*sqrt(sum(data{ind}(:,6:7).^2,2)),'-x');
hold on
plot(data{ind}(gpsvector,1),1e-2*sqrt(sum(data{ind}(gpsvector,6:7).^2,2)),'rd');
ylabel('gspd magnitude (m/s)');
%% airspeed
ind = find(strcmpi('VFR_HUD',messages));
vfrtemp = 1:length(data{ind});
vfrtime = interp1(1:length(atttimes),atttimes,vfrtemp);
vfrvector = matchTimes(autolandTimes,segments,vfrtime);

figure;
subplot(211);
plot(vfrtime,data{ind}(:,1),'-x');
hold on;
plot(vfrtime(vfrvector),data{ind}(vfrvector,1),'rd');
ylabel('airspeed (m/s)');

subplot(212);
plot(vfrtime,data{ind}(:,4),'-x');
hold on;
plot(vfrtime(vfrvector),data{ind}(vfrvector,4),'rd');
ylabel('throttle (pct)');
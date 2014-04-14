% process automatic landing data file
%% process data
clear variables;
close all;
load log_17.mat;

land = 2;%1 or 2 for first or second landing

LAT0 = 30.6325694444444;
%LONG0 = -96.4819777777778;
LONG0 = -96.4818833333333;

way_flag = 0;%flag if waypoints are associated with logs

%convert gps time to seconds
gps(:,1) = (gps(:,1) - gps(1,1))/1000;

%process the logged modes
manual = [];
stab = [];
fbwb = [];
auto = [];
for i = 1:modcount
    if strfind(mod{i},'Manual')
        if i == modcount
            manual = [manual [crossovers(i)+1;gpscount]];
        else
            manual = [manual [crossovers(i)+1;crossovers(i+1)]];
        end
    end
    if strfind(mod{i},'Stabilize')
        if i == modcount
            stab = [stab [crossovers(i)+1;gpscount]];
        else
            stab = [stab [crossovers(i)+1;crossovers(i+1)]];
        end
    end
    if strfind(mod{i},'AUTO')
        if i == modcount
            auto = [auto [crossovers(i)+1;gpscount]];
        else
            auto = [auto [crossovers(i)+1;crossovers(i+1)]];
        end
    end
    if strfind(mod{i},'FBW_B')
        if i == modcount
            fbwb = [fbwb [crossovers(i)+1;gpscount]];
        else
            fbwb = [fbwb [crossovers(i)+1;crossovers(i+1)]];
        end
    end
end

manualindices = [];
autoindices = [];
stabindices = [];
fbwbindices = [];
for i = 1:size(manual,2)
    manualindices = [manualindices manual(1,i):manual(2,i)];
end
for i = 1:size(auto,2)
    autoindices = [autoindices auto(1,i):auto(2,i)];
end
for i = 1:size(stab,2)
    stabindices = [stabindices stab(1,i):stab(2,i)];
end
for i = 1:size(fbwb,2)
    fbwbindices = [fbwbindices fbwb(1,i):fbwb(2,i)];
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
for i = 1:length(stabindices)
    if i > length(stabindices)
        break;
    end
    if gps(stabindices(i),4) == 0
        stabindices(i) = [];
        stabindices(i+1:end) = stabindices(i+1:end)-1;
    end
end
for i = 1:length(fbwbindices)
    if i > length(fbwbindices)
        break;
    end
    if gps(fbwbindices(i),4) == 0
        fbwbindices(i) = [];
        fbwbindices(i+1:end) = fbwbindices(i+1:end)-1;
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

if land == 2
    inddel2 = find(gpstime < 0 & gpstime > -86232);
    gpstime = gpstime - min(gpstime);
else if land == 1
        inddel2 = find(gpstime > 0 | gpstime < -86232 );
        gpstime(gpstime < 0) = gpstime(gpstime < 0) + max(gpstime) - min(gpstime(gpstime < 0));
    else
        return
    end
end
manualindices(manualindices < min(inddel2) | manualindices > max(inddel2)) = [];
autoindices(autoindices < min(inddel2) | autoindices > max(inddel2)) = [];
stabindices(stabindices < min(inddel2) | stabindices > max(inddel2)) = [];
fbwbindices(fbwbindices < min(inddel2) | fbwbindices > max(inddel2)) = [];

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
plot(gpstime(stabindices),gps(stabindices,2),'gs');
plot(gpstime(fbwbindices),gps(fbwbindices,2),'ko');
ylabel('longitude (deg)');

subplot(212);
plot(gpstime(manualindices),gps(manualindices,1),'bx');
hold on;
plot(gpstime(autoindices),gps(autoindices,1),'rd');
plot(gpstime(stabindices),gps(stabindices,1),'gs');
plot(gpstime(fbwbindices),gps(fbwbindices,1),'ko');
ylabel('latitude (deg)');

% plot GPS long-lat history
figure;
plot(gps(manualindices,2),gps(manualindices,1),'bx');
hold on;
plot(gps(fbwbindices,2),gps(fbwbindices,1),'ko');
plot(gps(autoindices,2),gps(autoindices,1),'rd');
plot(gps(stabindices,2),gps(stabindices,1),'gs');

if way_flag
    plot(lons,lats,'mx','markersize',12,'linewidth',2);
end
legend('Manual','FBWB','AUTO','Stabilize');

ylabel('lat');
xlabel('long');

% plot attitude histories
figure;
subplot(311);
plot(gpstime(manualindices),att(manualindices,1),'bx');
hold on;
plot(gpstime(autoindices),att(autoindices,1),'rd');
plot(gpstime(stabindices),att(stabindices,1),'gs');
plot(gpstime(fbwbindices),att(fbwbindices,1),'ko');
ylabel('roll (deg)');

subplot(312);
plot(gpstime(manualindices),att(manualindices,2),'bx');
hold on;
plot(gpstime(autoindices),att(autoindices,2),'rd');
plot(gpstime(stabindices),att(stabindices,2),'gs');
plot(gpstime(fbwbindices),att(fbwbindices,2),'ko');
ylabel('pitch (deg)');

subplot(313);
plot(gpstime(manualindices),att(manualindices,3),'bx');
hold on;
plot(gpstime(autoindices),att(autoindices,3),'rd');
plot(gpstime(stabindices),att(stabindices,3),'gs');
plot(gpstime(fbwbindices),att(fbwbindices,3),'ko');
ylabel('yaw (deg)');

% plot ground speed
figure;
subplot(311);
plot(gpstime(manualindices),gspeed(manualindices),'bx');
hold on;
plot(gpstime(autoindices),gspeed(autoindices),'rd');
plot(gpstime(stabindices),gspeed(stabindices),'gs');
plot(gpstime(fbwbindices),gspeed(fbwbindices),'ko');
ylabel('ground speed (m/s)');

subplot(312);
plot(gpstime(manualindices),alt(manualindices),'bx');
hold on;
plot(gpstime(autoindices),alt(autoindices),'rd');
plot(gpstime(stabindices),alt(stabindices),'gs');
plot(gpstime(fbwbindices),alt(fbwbindices),'ko');
ylabel('altitude (m)');
%plot descent rate
hdot = diff(alt)./diff(gpstime);

subplot(313);
plot(gpstime(manualindices(1:end-1)),hdot(manualindices(1:end-1)),'bx');
hold on;
plot(gpstime(autoindices(1:end-1)),hdot(autoindices(1:end-1)),'rd');
plot(gpstime(stabindices(1:end-1)),hdot(stabindices(1:end-1)),'gs');
plot(gpstime(fbwbindices(1:end-1)),hdot(fbwbindices(1:end-1)),'ko');
ylabel('hdot (m/s)');

%% plot glideslope and flare performance
EXPORT = 1;% set to 1 to save figures

%  correct gps duplicate times
gpstime(2:2:end-1) = gpstime(3:2:end) - 0.1;
hdot = diff(alt)./diff(gpstime);

figure;
subplot(121);
X = -d2r*6378100*(gps(:,1)-LAT0);
Y = -d2r*6378100*(gps(:,2)-LONG0);
Z = -alt + min(alt(alt>60));
Zref = tand(5)*X;
plot(X(fbwbindices),-Z(fbwbindices),'k-o');
hold on;
% plot glideslope
plot(X(fbwbindices),-Zref(fbwbindices),'r--');
grid on;
ylabel('altitude (m)');
xlabel('X-position (m)');
set(gca,'ylim',[0 get(gca,'ylim')*[0;1]]);

subplot(122);
plot(Y(fbwbindices),X(fbwbindices),'ko');
%plot runway center and 5 meter target
hold on;
plot([0 0],[min(X(fbwbindices)) max(X(fbwbindices))],'b-');
plot([-5 -5],[min(X(fbwbindices)) max(X(fbwbindices))],'r--');
plot([5 5],[min(X(fbwbindices)) max(X(fbwbindices))],'r--');
grid on;
xlabel('Y-position (m)');
ylabel('X-position (m)');

ha = axes('Position',[0 0 1 1],'Xlim',[0 1],'Ylim',[0 1],'Box','off','Visible','off','Units','normalized', 'clipping' , 'off');

text(0.5, 1,['\bf Approach position history for landing ' num2str(land)],'HorizontalAlignment','center','VerticalAlignment', 'top','fontsize',12)

set(gcf,'position',[400 525 900 450]);

if EXPORT
    export_fig(['landing_' num2str(land) '_approach'],'-png','-transparent','-a1');
end

% plot flare performance
flareind = find(-Zref(fbwbindices) <= 4);
figure;
subplot(121);
plot(X(fbwbindices(flareind)),-Z(fbwbindices(flareind)),'k-o');
grid on;
ylabel('altitude (m)');
xlabel('X position (m)');

subplot(122);
plot(gpstime(fbwbindices(flareind(1:end-1))),hdot(fbwbindices(flareind(1:end-1))),'k-o');
grid on;

hdotsmooth = filter([1 1 1 1 1]*0.2,1,hdot(fbwbindices(flareind(1:end-1))));
hold on;
plot(gpstime(fbwbindices(flareind(1:end-1))),hdotsmooth,'r--','linewidth',2);
%plot the reference
%tau = -0.4
plot(gpstime(fbwbindices(flareind)),0.4*Z(fbwbindices(flareind)),'b-d');
legend('first order difference','smoothed descent rate','reference descent rate','location','south');

ylabel('descent rate (m/s)');
xlabel('time (sec)');

ha = axes('Position',[0 0 1 1],'Xlim',[0 1],'Ylim',[0 1],'Box','off','Visible','off','Units','normalized', 'clipping' , 'off');

text(0.5, 1,['\bf Flare performance for landing ' num2str(land)],'HorizontalAlignment','center','VerticalAlignment', 'top','fontsize',12)

set(gcf,'position',[400 525 900 450]);

if EXPORT
    export_fig(['landing_' num2str(land) '_flare'],'-png','-transparent','-a1');
end
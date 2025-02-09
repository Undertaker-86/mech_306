% This code reads pressure, RTD and heater power
% S Rogak January 2021
%
% updated by SZ Dec 2021 to include an updated serial port function
clear all

%*** Open relevant files and ports
s=serialport('COM8',9600);%  The COM port will differ between individual Arduino units, so you will probably need to change this line.
%The COM port is discoverable in the Arduino IDE when you first connect to
%the Aduino and download or modify your code.
filename=input('Filename to store data?   ','s');% use .txt extension to make it easier to import into excel
filename=strcat(filename,'.txt');
FID=fopen(filename,'w');

%******* Set up graphs ************************************
figure(1)
subplot(3,1,1);% use tiled graphs
h=animatedline('color','blue');%change this color each experiment if you want to superimpose plots
runtime=30;%Initial guess for time to collect data.  This will be extended if needed.
axis([0 runtime -40 80]);
grid on;
xlabel('time[s]');
ylabel('Pressure [Pa]');
title(filename);
hold on;

subplot(3,1,2); %Temperature plot
h2=animatedline; %T signal
minV=0;
axis([0 runtime minV 2]);
xlabel('time[s]');
ylabel('T signal [V]');
grid on;
hold on;

subplot(3,1,3); %power plot
h3=animatedline('color','red');  % Power signal
minV=0;
axis([0 runtime minV 2]);
xlabel('time[s]');
ylabel('Power Signal [V]');
grid on;
hold on;


%***Set up control buttons to stop acquisition or set up averaging******
fig = uifigure('Name','Control','Position',[100 500 300 100]);
btnMark = uibutton(fig,'state','Text', 'Average This Data','Value', false,'Position',[5,50, 150, 20]);%this will start and stop averaging periods during your collection
btnStop = uibutton(fig,'state','Text', 'Stop','Value', false,'Position',[200,50, 50, 20]);

% ****** Initialize counters and indices needed later in the loop******
time=0;
i=1;
averageToggle=0;
Navg=0;
    
%***********  start main data collection loop  *******************
t=now;
d = datetime(t,'ConvertFrom','datenum');
fprintf(FID,datestr(d));
for i=1:10; % First 10 lines are header
    out=readline(s);
    fprintf(FID,out);
end
fprintf(FID,'%s\n','     time [s]    P [Pa]     T [V]     Power [V]');
while btnStop.Value<1; % read a bunch of times  Need to deal with header before parsing.
    out=readline(s);
    C=textscan(out,'%f');
    A=cell2mat(C);
    time=A(1)/1000;% in seconds
    P=A(2);
    T=A(3)/1024*5.0;% RTD channel, full scale=1024 at 5V
    Q=A(4)/1024*5.0;% heater volts, full scale=1024 at 5V
    t(i)=time;
    p(i)=P;
    temp(i)=T;
    power(i)=Q;
     
    if btnMark.Value==1;%then we are averaging the data over this period
        if averageToggle==0; %then this is the first point for a new average
            averageToggle=1;
            Navg=Navg+1;
            avgP(Navg)=0;
            avgT(Navg)=0;
            avgQ(Navg)=0;
            avgt(Navg)=time;
            k=0;
            subplot(3,1,1);
              plot(time,P,'kx');% This will mark on the graph the starting time for the average
            subplot(3,1,2);
              plot(time,T,'rx');
        end
        avgP(Navg)=(avgP(Navg)*k+P)/(k+1); %running average, pressure
        avgT(Navg)=(avgT(Navg)*k+T)/(k+1); %                 RTD signal
        avgQ(Navg)=(avgQ(Navg)*k+Q)/(k+1); %                 power signal
        avgt(Navg)=(avgt(Navg)*k+time)/(k+1);
        k=k+1;
    else  %this is not a period to be averaged
        if averageToggle==1; %then this is the first point for a non-averaged period
            averageToggle=0;
            subplot(3,1,1);
              plot(time,P,'ko');% This will mark on the graph the ending time for the average
            subplot(3,1,2);
              plot(time,T,'ro');
              fprintf(FID,'%10.1f %10.3f %10.3f  %10.3f\r\n',...
                avgt(Navg),avgP(Navg),avgT(Navg),avgQ(Navg)); %store last averages
        end
    end
    % ***Update plots *********
    if time>runtime %then we need to extend the axis of the plot
        runtime=runtime+30;
    end
    subplot(3,1,1);
       addpoints(h,time,P);
       maxV=max(max(p),10);
       minV=min(min(p),0);
       axis([0 runtime minV maxV]);
    subplot(3,1,2);
       addpoints(h2,time,T);
       maxV=max(max(temp),1);
       minV=min(min(temp),.5);
       axis([0 runtime minV maxV]);
    subplot(3,1,3);
       addpoints(h3,time,Q);
       maxV=max(max(power),1);
       minV=min(min(power),.5);
       axis([0 runtime minV maxV]);
    drawnow
    i=1+i;
end
clear s
fclose(FID);
close(fig);


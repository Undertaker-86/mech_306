% Simple Arduino reader
% As supplied, this code is suitable for running the fan flow
% characterization experiment.  
% Steve Rogak and Behzad Aminian, December 2020.
% updated by SZ Dec 2021 to include an updated serial port function
clear all; close all;

%*** Open relevant files and ports
s=serialport('COM3',9600);%  The COM port will differ between individual Arduino units, so you will probably need to change this line.
%The COM port is discoverable in the Arduino IDE when you first connect to
%the Aduino and download or modify your code.


filename=input('Filename to store data?   ','s');% use .txt extension to make it easier to import into excel
filename=strcat(filename,'.txt');
FID=fopen(filename,'w');

%******* Initialize variables and set up graphs ************************************
figure(1)
%subplot(2,1,1);% for the heat transfer expt, use tiled graphs
h=animatedline('color','red');%change this color each experiment if you want to superimpose plots
runtime=30;%Initial guess for time to collect data.  This will be extended if needed.
axis([0 runtime -40 80]);
grid on;
xlabel('time[s]');
ylabel('P [Pa]');
title ('Pressure');
hold on

time=0;
i=1;
averageToggle=0;
Navg=0;

fig = uifigure('Name','Control','Position',[100 500 300 100]);
btnMark = uibutton(fig,'state','Text', 'Average This Data','Value', false,'Position',[5,50, 150, 20]);%this will start and stop averaging periods during your collection
btnStop = uibutton(fig,'state','Text', 'Stop','Value', false,'Position',[200,50, 50, 20]);
    
%***********  start main data collection loop  *******************
for i=1:10   % First 10 lines are header
    out=readline(s);
end
while btnStop.Value<1 % read a bunch of times  Need to deal with header before parsing.
    out=readline(s);
    C=textscan(out,'%f');
    A=cell2mat(C);
    time=A(1)/1000;% in seconds
    P=A(2);
    T=A(3)/1024*5.0;% full scale is integer 1024 at 5V
    t(i)=time;
    if time>runtime %then we need to extend the axis of the plot
        runtime=runtime+10;
        axis([0 runtime -40 80]);
    end
    
    p(i)=P;
    temp(i)=T;
    addpoints(h,time,P);
    if btnMark.Value==1;%then we are averaging the data over this period
        if averageToggle==0; %then this is the first point for a new average
            averageToggle=1;
            Navg=Navg+1;
            avgP(Navg)=0;
            k=0;
            plot(time,P,'kx');% This will mark on the graph the starting time for the average
        end
        avgP(Navg)=(avgP(Navg)*k+P)/(k+1); %this is just a way of computing a running average
        k=k+1;
    else  %this is not a period to be averaged
        if averageToggle==1; %then this is the first point for a non-averaged period
            averageToggle=0;
            plot(time,P,'ko');% This will mark on the graph the ending time for the average
            fprintf(FID,'%10.3f %10.3f \r\n',time,avgP(Navg)); %This will store
        end
    end
    drawnow
    i=1+i;
end
clear s
fclose(FID);
% saveas(fig, filename + ".png")
close(fig);


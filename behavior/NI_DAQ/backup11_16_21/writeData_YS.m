function writeData_YS(daq_data, event, fig_plt)
global globalTime;
global globalData;
global timeIndex;


%% Write data to file
fprintf(daq_data.time,'%f\n',event.TimeStamps);
for ii = 1:numel(daq_data.voltage)
    fprintf(daq_data.voltage(ii),'%f\n',event.Data(:,ii));
end


%% Plot
% reset plot to 120 sec windows 
if (mod(event.TimeStamps(1),120) == 0)
    globalTime = zeros(1000*120,1);
    globalData = zeros(1000*120,size(event.Data,2));
    timeIndex = 1;
    for ii = 1:length(fig_plt.subplt)
        xlim(fig_plt.subplt(ii), [event.TimeStamps(1) event.TimeStamps(1)+120]);
    end
end

globalTime(timeIndex:(timeIndex + length(event.TimeStamps) - 1),1) = event.TimeStamps;
globalData(timeIndex:(timeIndex + length(event.TimeStamps) - 1),:) = event.Data;

%  update data on plots
for ii = 1:length(fig_plt.plt)
    set(fig_plt.plt(ii),'XData',globalTime(1:(timeIndex+length(event.TimeStamps)-1),1),'YData',globalData(1:(timeIndex+length(event.TimeStamps)-1),ii));
end

timeIndex = length(event.TimeStamps) + timeIndex;

end


function f_writeData(obj, ~, daq_data, fig_plt)
global globalTime;
global globalData;
global timeIndex;

%data = read(obj,obj.ScansAvailableFcnCount,"OutputFormat","Matrix");

data = read(obj, obj.ScansAvailableFcnCount);

%% Write data to file
seconds1 = seconds(data.Time);

fprintf(daq_data.time,'%f\n',seconds1);
for ii = 1:numel(daq_data.voltage)
    fprintf(daq_data.voltage(ii),'%f\n',data(:,ii).Variables);
end

%% Plot
% reset plot to 120 sec windows 
if (mod(seconds1(1),120) == 0)
    globalTime = zeros(1000*120,1);
    globalData = zeros(1000*120, numel(daq_data.voltage));
    timeIndex = 1;
    for ii = 1:length(fig_plt.subplt)
        xlim(fig_plt.subplt(ii), [seconds1(1) seconds1(1)+120]);
    end
end

globalTime(timeIndex:(timeIndex + length(seconds1) - 1),1) = seconds1;
globalData(timeIndex:(timeIndex + length(seconds1) - 1),:) = data.Variables;

%  update data on plots
for ii = 1:length(fig_plt.plt)
    set(fig_plt.plt(ii),'XData',globalTime(1:(timeIndex+length(seconds1)-1),1),'YData',globalData(1:(timeIndex+numel(seconds1)-1),ii));
end

timeIndex = length(seconds1) + timeIndex;

end


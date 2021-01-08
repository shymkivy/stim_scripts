% run s.Channels to see specifications where the ctr0 is at
s = daq.createSession('ni');
addCounterInputChannel(s,'dev2', 'ctr0', 'EdgeCount');
resetCounters(s);
inputSingleScan(s);

inputSingleScan(s)
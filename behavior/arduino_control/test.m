% this seems slow


a = arduino('COM4', 'Uno');

exp_running = 1;


configurePin(a,'D13', 'DigitalInput')

tic;

data = zeros(100,2);
for ii = 1:100
    data(ii,1) = toc ;
    data(ii,2) = readDigitalPin(a,'D13');
end

while exp_running

    
    
end

for i = 1:10
  writeDigitalPin(a, 'D11', 0);
  pause(0.5);
  writeDigitalPin(a, 'D11', 1);
  pause(0.5);
end







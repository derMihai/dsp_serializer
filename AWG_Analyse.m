
clear signals;

signals = {
    'writedata','bus_value_d';
    'address','bus_value_d';
    'address','bus_value_h';
    'write','single';
    'readdata','bus_value_d';
    'ram_addr','bus_value_d';
    'DA_DB','bus_value_d';
    };

DispTime=0;
LaPlot(signals,[DispTime,DispTime+40,1]);

figure(3);
plot(DA_DB);
grid on;
title('Ausgangssignal');

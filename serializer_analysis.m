clear signals;
 
signals = {
   'data_in', 'single';
   'data_en', 'single';
   'out.data_en_pulse', 'single';
   'out.data_out_n', 'bus_value_h';
   'out.data_out', 'bus_value_h';
   'out.data_out_valid', 'single';
};

DispTime=0;
LaPlot(signals,[DispTime,DispTime+50,1]);
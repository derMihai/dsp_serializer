clear signals;

% data_out_n_sim = zeroes(length(sym_rx));
% data_out_sim = zeroes(length(sym_rx));
% 
% for i = 1:1:length(sym_rx) - (8 * N_dft) - 1
%     data_out_n_sim = 
% end
 
signals = {
   'data_in', 'single';
   'bit_begin', 'single';
   'data_en', 'single';
   'out.data_en_pulse', 'single';
   'out.data_out_n', 'bus_value_h';
   'out.data_out', 'bus_value_h';
   'out.data_out_valid', 'single';
};

DispTime=0;
LaPlot(signals,[DispTime,DispTime+50,1]);
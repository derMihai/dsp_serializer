clear signals;

signals = {
    'sym_rx', 'single';
    
%     'out.set_NOT_MATCHING', 'single';
%     'out.set_MATCHING', 'single';
%     'out.set_MATCHING_END', 'single';
%     'out.set_SYNC', 'single';

  %  'out.NOT_MATCHING', 'single';
 %   'out.MATCHING', 'single';
 %   'out.MATCHING_END', 'single';
%    'out.SYNC', 'bus_value_d';
    'out.SYNC1', 'bus_value_d';
    'out.VALID', 'single';
    'out.VALID2', 'single';
    'out.VALID3', 'single';
    'out.VALID1', 'single';
    'out.ALL', 'bus_value_d';
    %'out.MATCH_LEN', 'bus_value_d';

};

DispTime=0;
LaPlot(signals,[DispTime,DispTime+40,1]);
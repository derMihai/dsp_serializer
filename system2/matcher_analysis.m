clear signals;

signals = {
    'data_in', 'single';
    'valid_in', 'single';
    
%     'out.set_NOT_MATCHING', 'single';
%     'out.set_MATCHING', 'single';
%     'out.set_MATCHING_END', 'single';
%     'out.set_SYNC', 'single';

  %  'out.NOT_MATCHING', 'single';
 %   'out.MATCHING', 'single';
 %   'out.MATCHING_END', 'single';
%    'out.SYNC', 'bus_value_d';
    'out.COUNTER', 'bus_value_d';
    'out.OFFSET', 'bus_value_d';
    'out.CUR_BYTE', 'bus_value_d';
    'out.FIFO_OUT', 'bus_value_d';
    'out.IS_WAITING', 'single';
    'out.IS_WAITING_ENDING', 'single';
    'out.IS_RUNNING', 'single';
    'out.EMPTY', 'single';
    'out.VALID_BYTE', 'single';
    'out.VALID_COUNTER', 'single';
    'out.SYNC_SYMBOL', 'bus_value_d';
    %'out.MATCH_LEN', 'bus_value_d';

};

DispTime=0;
LaPlot(signals,[DispTime,DispTime+40,1]);

I = find(out.VALID_BYTE);
out.CUR_BYTE(I)
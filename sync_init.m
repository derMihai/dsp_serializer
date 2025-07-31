tx_bytes = [bin2dec('0100 0111'), 1, 2, 3, 12, 13, 14];         % Synchronsequenz und zu �bertragende Datenbytes

tx_bit_array = dec2bin(tx_bytes, 8).';              % Umwandlung der Bytes in Bin�rzahlen '0' und '1'
tx_bit_array = double(tx_bit_array == '1');         % Umwandlung der Bin�rwerte von char zu double
tx_bit_array_lsb_first = flipud(tx_bit_array);
tx_bit_stream = tx_bit_array_lsb_first(:);          % Serialisierung der Bytes

tx_bit_stream_2 = kron(tx_bit_stream, [1;1]);       % Verdopplung jedes Datenbits
DataClock = zeros(size(tx_bit_stream_2));           % Erzeugung des Taktsignals zur Synchronisation der Daten
DataClock(1:2:end) = 1;
Manchester_bits = xor(tx_bit_stream_2, DataClock);  % Manchester Codierung

% Symbol Mapping: Bitwert 0 => Symbolwert 1, Bitwert 1 => Symbolwert -1
Manchester_symbols = 1 * double(Manchester_bits == 0) + (-1) * double(Manchester_bits == 1);

N_clk_per_symbol = 10;                              % Anzahl der Takte pro Symbol

Manch_symb_oversamp = kron(Manchester_symbols, [1; zeros(N_clk_per_symbol-1, 1)]); % �berabtastung der Manchester-encodierten Datensymbole

data_in = Manch_symb_oversamp;
data_en = zeros(length(data_in), 1) + 1;
matcher_reset = [ 1 0 ];

N_sim = length(data_in);

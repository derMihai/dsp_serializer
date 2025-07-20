% Anzahl der Simulationstakte
N_sim = 4e3;

% Konfiguration
N_bits = 10;
MemSize = 8192;
N_cnt = ceil(log2(MemSize));

% Inhalt des Samplespeichers berechnen
len = 300;
n = 0:len-1;
u = sin(10*2*pi*n/len);             % Sinus Signal berechnen

% Amplitude festlegen
A = 400;                            

% Amplitude einstellen, Mittelwert addieren und Rundung der Signalsamples
mem_data = round(A*u+512);          

figure(2);
plot(u); title('Signal u'); grid on;

% Vorinitialisierung der Eingangssignale
writedata = zeros(1,N_sim);
address = zeros(1,N_sim);
write = zeros(1,N_sim);

% Schreiben des Speicherinhaltes
T = 10;
writedata(T:T+len-1) = mem_data;
address(T:T+len-1) = 0:len-1;
write(T:T+len-1) = 1;

T=T+len;

% Schreiben des Längenregisters
writedata(T) = len-1;
address(T) = 2^(N_cnt)+1;
write(T) = 1;

T=T+1;

% Rücksetzen des Adresscounters und Start der Signalerzeugung
writedata(T) = 3;
address(T) = 2^(N_cnt);
write(T) = 1;


%% SAF
function [Values] = SAF(DataSamples,ClkSamples,SFSamples)
% @ DataSamples - (1xn) abgetastete Spannungswerte von Kanal A
% @ ClkSamples  - (1xn) abgetastete Spannungswerte von Kanal B
% @ SFSamples   - (2xp) Abtastwerte der SF fuer eine 0.
%                       Zeile 1 steht fuer die Samples von SF0 und
%                       Zeile 2 enthaelt die Samples fuer SF1
% @ Values      - (1xn) Bitfolge, die vom SAF ermittelt wurde


%% Digitalisierung der CLK

% kleinster Wert soll null sein
ClkSamples = ( ClkSamples - min(ClkSamples) );

% größter verbliebender Wert soll 1 sein
ClkSamples = ClkSamples / max(ClkSamples);

% Entscheider
ClkSamples(ClkSamples <  0.5) = 0;
ClkSamples(ClkSamples >= 0.5) = 1;


% Vektor erstellen, der eine 1 enthält wo ein neues Bit anfängt
BitStart = ClkSamples(1:end) - [0 ClkSamples(1:end-1)];

% wenn das erste Bit schon ne 1 ist wissen wir nicht, ob es wirklich der
% Anfang eines Bits ist und Ignorieren sie.
BitStart(1) = 0;

% durch verschiebung entstandene negative Werte löschen
BitStart(BitStart<0) = 0;

invSF = fliplr(SFSamples);
nullen = conv(DataSamples, invSF(1,:));%, 'same'); % 'same' schmeißt nur den mittleren Teil raus, der
einsen = conv(DataSamples, invSF(2,:));%, 'same'); % so lang ist wie DataSamples uns ClkSamples
sig = nullen-einsen;


%%AbtastZeitpunkte
%%HINWEIS: letzter Abtastzeitpunkt wird aus den vorherigen geschaetzt

% durch das 'same' in der conv Funktion ist es nicht nötig zu schätzen. Der
% letzte Wert in sig ist der den wir suchen


% Abtastung und Entscheidung des SAF-Signals

max_ind = find(BitStart);
Abgetastet = [sig(max_ind) sig(end)]; % DataSamples(end)
Abgetastet(Abgetastet < 0.5) = 0;
Abgetastet(Abgetastet >=0.5) = 1;

Values=  Abgetastet;

end
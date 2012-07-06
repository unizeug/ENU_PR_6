%% SAF
function [Values] = SAF(DataSamples,ClkSamples,SFSamples)
% @ DataSamples - (1xn) abgetastete Spannungswerte von Kanal A
% @ ClkSamples  - (1xn) abgetastete Spannungswerte von Kanal B
% @ SFSamples   - (2xp) Abtastwerte der SF fuer eine 0.
%                       Zeile 1 steht fuer die Samples von SF0 und
%                       Zeile 2 enthaelt die Samples fuer SF1
% @ Values      - (1xn) Bitfolge, die vom SAF ermittelt wurde

% plot(SFSamples(1,:))
% hold on
% plot(SFSamples(2,:),'r')
% hold off

%% Digitalisierung der CLK

% kleinster Wert soll null sein
ClkSamples = ( ClkSamples - min(ClkSamples) );

% gr��ter verbliebender Wert soll 1 sein
ClkSamples = ClkSamples / max(ClkSamples);

% Entscheider
ClkSamples(ClkSamples <  0.5) = 0;
ClkSamples(ClkSamples >= 0.5) = 1;


% Vektor erstellen, der eine 1 enth�lt wo ein neues Bit anf�ngt
BitStart = ClkSamples(1:end) - [0 ClkSamples(1:end-1)];

% wenn das erste Bit schon ne 1 ist wissen wir nicht, ob es wirklich der
% Anfang eines Bits ist und Ignorieren sie.
BitStart(1) = 0;

% durch verschiebung entstandene negative Werte l�schen
BitStart(BitStart<0) = 0;
BitStartInd = find(BitStart==1);

% Letzten Abtastpunkt hinzuf�gen: Letzter index + den abstand zweier BitStarts
BitStart( max(BitStartInd) + (BitStartInd(end) - BitStartInd(end-1)) ) = 1;
BitStartInd = find(BitStart==1);

% figure(20)
% clf()
% plot(ClkSamples)
% hold on
% plot(BitStart,'r')
% hold off


invSF = fliplr(SFSamples);
nullen = conv(DataSamples, invSF(1,:)); % 'same' schmei�t nur den mittleren Teil raus, der
einsen = conv(DataSamples, invSF(2,:)); % so lang ist wie DataSamples uns ClkSamples
% length(nullen)
% length(einsen)
sig = einsen-nullen;

% figure(21)
% clf()
% plot(DataSamples)
% hold on
% plot(nullen/700,'r')
% stem(BitStart,'g+')
% hold off


%%AbtastZeitpunkte
%%HINWEIS: letzter Abtastzeitpunkt wird aus den vorherigen geschaetzt

% durch das 'same' in der conv Funktion ist es nicht n�tig zu sch�tzen. Der
% letzte Wert in sig ist der den wir suchen


% Abtastung und Entscheidung des SAF-Signals


% edges=find(BitStart==1);
% Values = zeros(1,length(edges)+1);
% 
% for i = 1:length(edges)
%     if sig(edges(i)) >= 0
%         Values(i) = 1;
%     else
%         Values(i) = 0;
%     end
% end


Abgetastet = sig(BitStartInd);
Abgetastet(Abgetastet<=0) = 0;
Abgetastet(Abgetastet>0) = 1;

Values = Abgetastet;%>0;%Abgetastet;

end

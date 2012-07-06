% Wandelt eine Matrix (mxn) beliebiger L�nge in eine Ausgabematrix durch zeilenweises
% Umbrechen. Au�erdem wird ein Taktsignal auf dem 4. Kanal hinzugef�gt,
% sofern keine Daten f�r den 4. Kanal �bermittelt wurden.
% Ein Takt ist durch eine [1 0] gekennzeichnet. Dabei wird 
% der Takt so angepasst, dass er seinen 1 zu 0 Wechsel genau in der H�lfte 
% eines Datenbits hat.
function ParallelM = DataM2ParallelM(DataM,BitGroupLength,t_bitP,SampleRate)
% @ KanalMatrix    - (mxn) Matrix, die je Zeile die auszugebenden Bits je Kanal 
%                    beinhaltet 1 und -1 
% @ BitBlockLength - (1x1) Anzahl an Bits, die nicht getrennt werden sollen
% @ optional_fTIdx - (1x1) OPTIONAL gibt einen Index f�r die Abtastrate an
% @ DataM - (axb) DatenMatrix, die die Zeilenweise Ausgabe beinhaltet
%% Auswertung
tbit=t_bitP;%20e-6; %s/bit 50e-6
N=128000;   %S/Line
%fT=(50e6*2^(-SampleRateIdx));  !!!! Diese Formel gilt nur aproximal f�r
%die Picoscopes 3204, nicht aber f�r die 3204A !!!!! Lieber die SampleRate
%direkt benutzen:
fT=SampleRate; %in Hz

LineStuffingFactor = 0.6;
MaxBitsPerLine=N/(fT*tbit*1e-6)*LineStuffingFactor;

if size(DataM,1)<4
    MaxDataBitsPerLine=floor(MaxBitsPerLine/2)-mod(floor(MaxBitsPerLine/2),BitGroupLength);
else
    MaxDataBitsPerLine=floor(MaxBitsPerLine)-mod(floor(MaxBitsPerLine),BitGroupLength);
end

% DataM zu Vektor wandeln:
Data=zeros(1,size(DataM,2));
for i=1:size(DataM,1)
    Data=Data+DataM(i,:)*2^(i-1);
end
% ZeroPadding anf�gen, damit alle Zeilen gleichlang sind
ZerroPadding=MaxDataBitsPerLine-mod(numel(Data),MaxDataBitsPerLine);

%Data bipolar {-1,1} muss zu {0,1} ge�ndert werden
Data(find(Data==-1))=0;
Data=[Data zeros(1,ZerroPadding)];
ParallelMatrix=reshape(Data',MaxDataBitsPerLine,[])';

% Takt hinzuf�gen, sofern Kanal 4 noch frei ist
Clk=0;
if size(DataM,1)<4
    ParallelMatrix=kron(ParallelMatrix,[1 1]); % DataMatrix f�r Takt anpassen
    Clk=mod(cumsum(ones(size(ParallelMatrix,1),size(ParallelMatrix,2)/BitGroupLength),2),2);
    % Takt an Signalformung anpassen
    Clk=kron(Clk,ones(1,BitGroupLength));
    Clk(end,(end+1-ZerroPadding*2):end)=0;
end

ParallelM=ParallelMatrix+8*Clk;

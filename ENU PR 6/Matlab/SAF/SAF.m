%% SAF
function [Values] = SAF(DataSamples,ClkSamples,SFSamples)
% @ DataSamples - (1xn) abgetastete Spannungswerte von Kanal A
% @ ClkSamples  - (1xn) abgetastete Spannungswerte von Kanal B
% @ SFSamples   - (2xp) Abtastwerte der SF fuer eine 0.
%                       Zeile 1 steht fuer die Samples von SF0 und
%                       Zeile 2 enthaelt die Samples fuer SF1
% @ Values      - (1xn) Bitfolge, die vom SAF ermittelt wurde


%AbtastZeitpunkte
%HINWEIS: letzter Abtastzeitpunkt wird aus den vorherigen geschaetzt

% Abtastung und Entscheidung des SAF-Signals
Values=     ???
end
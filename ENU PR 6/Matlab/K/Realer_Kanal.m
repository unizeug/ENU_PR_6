%function Realer_Kanal(SampleRate,Channels,RangeIndex,Trigger,X,tbit,N)
function [Values Noise]=Realer_Kanal(OutputData,KanalParameter,FilterParameter,DEBUGParameter)
% @ ScopeHandle    - Ger�tehandle f�r das PicoScope
% @ OutputData     - (kxm) Bitstreams der Ausgabe. Die Zeilen der Matrix stehen
%                    f�r die einzelnen Kan�le (k={1,2,3,4})
% @ FilterParmeter - Objekt mit zus�tzlichen Daten f�r die Filterung der
%                    aufgenommenen Samples
% @ DEBUGParameter - Objekt mit diversen Debugparamter (ist f�r Probleme im
%                    Versuch gedacht. Nicht �ndern.)
% @ Values         - R�ckgabe

%% �bergabeparameter verarbeiten
X = DataM2ParallelM(OutputData,KanalParameter.BitGroupLength,KanalParameter.t_bitP,KanalParameter.SampleRate);
%% Ausgabe
SampleRate=KanalParameter.SampleRateIdx;
TPBit=KanalParameter.t_bitP;

Channels=[1 2];
RangeIndex=[10 10];
Trigger.Channel=2;
Trigger.Voltage=2.6;
Trigger.WhichWay=0;
Trigger.TimeDelay=0;
N=128000;

%% Initiierung
ende=0;
status=1;

%% Ready
if status==1
    ParallelOUT(0,1); % ParallelBox initialisieren
    BitGroupsPerLine=(size(X,2)/2/KanalParameter.BitGroupLength);
    % Go
    line=1;
    Values=[];
    repeatLineTransmission=0;
    while ende==0
        TInt=StartTriggerBlock(KanalParameter.ScopeVersion,Channels,RangeIndex,SampleRate,N,KanalParameter.ScopeHandle,Trigger.Channel,Trigger.Voltage,Trigger.WhichWay,Trigger.TimeDelay);
        ParallelOUT(X(line,:),TPBit);
        % Check for Triggerevent
        while HasTriggered(TInt)~=1
            t=sqrt(8);
        end
        [A B]=GetTriggerBlock(TInt);
        % Nachverarbeitung
        if exist('FilterPico.m','file')
            A.Values=A.Values';
            %A.Time=A.Time';
            B.Values=B.Values';
            %B.Time=B.Time';
	    %Plausibilit�tspr�fung
            if size(OutputData,1)<4
                B_Clk=B.Values;
                B_Clk(B_Clk<2.5)=0;
                B_Clk(B_Clk>=2.5)=1;
                if line<size(X,1)
                    if (sum(diff(B_Clk)==-1)~=BitGroupsPerLine)                     
                        repeatLineTransmission = repeatLineTransmission + 1;
                        if (repeatLineTransmission<=3)
                            continue; % repeat line transmission
                        else
                            error(['EXPERIMENT BROKEN :: Clk Error @ ParallelMatrixLine ' num2str(line)]);
                        end
                    end
                else
                    LastLineBitGroup=mod(numel(OutputData)/KanalParameter.BitGroupLength,BitGroupsPerLine);
                    if LastLineBitGroup==0
                        LastLineBitGroup=BitGroupsPerLine;
                    end
                    if (sum(diff(B_Clk)==-1)~=LastLineBitGroup)
                        repeatLineTransmission = repeatLineTransmission + 1;
                        if (repeatLineTransmission<=3)
                            continue; % repeat line transmission
                        else
                            error('EXPERIMENT BROKEN :: Clk Error @ last ParallelMatrixLine');
                        end
                    end
                end
            end
            C=FilterPico(A,B,FilterParameter);
            Values=[Values C ];
            repeatLineTransmission=0;
        else
            Values=[Values A.Values];
        end
        if line>=size(X,1)
            ende=1;
        end
        display([num2str(100*line/size(X,1),'%.2f') '%']);
        %display(['length(Values)= ' num2str(numel(Values))]);
        line=line+1;
        %assignin('base','Values',Values);
    end
    % Do Noise measurement
    ParallelOUT(1,1);
    X_noise = DataM2ParallelM(zeros(1,11000),KanalParameter.BitGroupLength,KanalParameter.t_bitP,KanalParameter.SampleRate);    
    TInt=StartTriggerBlock(KanalParameter.ScopeVersion,Channels,RangeIndex,SampleRate,N,KanalParameter.ScopeHandle,1,0,1,0);
    ParallelOUT(0,1);
    ParallelOUT(X_noise,TPBit);
   % while HasTriggered(TInt)~=1
   %       t=sqrt(8);
   % end
    [A]=GetTriggerBlock(TInt);
    Noise=A.Values;
end
end

%% Additional functions
function [A B]= GetTriggerBlock(TInt)
ScopeHandle=TInt.handle;
time=TInt.Time;
pBuffer=TInt.Buffer(1);
pBuffer2=TInt.Buffer(2);
overflow=TInt.overflow;
SampleCount=TInt.SampleCount;
Channel=TInt.Channel;
RangeIndex=TInt.RangeIndex;

if numel(TInt.ScopeVersion)==numel('3204')
    pBufferDUMMY = libpointer('int16Ptr',zeros(SampleCount,1));
    calllib('PS3000', 'ps3000_get_values',ScopeHandle,pBuffer,pBuffer2,pBufferDUMMY,pBufferDUMMY,overflow,SampleCount);
    calllib('PS3000', 'ps3000_stop',ScopeHandle);
else
    calllib('PS3000a', 'ps3000aSetDataBuffer',ScopeHandle,0,pBuffer,SampleCount,0,0);
    calllib('PS3000a', 'ps3000aGetValues',ScopeHandle,0,SampleCount,1,0,0,overflow);
    calllib('PS3000a', 'ps3000aSetDataBuffer',ScopeHandle,1,pBuffer2,SampleCount,0,0);
    calllib('PS3000a', 'ps3000aGetValues',ScopeHandle,0,SampleCount,1,0,0,overflow);
    calllib('PS3000a', 'ps3000aStop',ScopeHandle);
end
%RangeIndex to Range
Range(1)=round((mod(RangeIndex(1),3)+1)^2/2)*10^(-2+floor(RangeIndex(1)/3));
if length(Channel)==2
    if length(RangeIndex)==2
        Range(2)=round((mod(RangeIndex(2),3)+1)^2/2)*10^(-2+floor(RangeIndex(2)/3));
    else
        Range(2)=round((mod(RangeIndex(1),3)+1)^2/2)*10^(-2+floor(RangeIndex(1)/3));
    end
end
if length(Channel)==1    
    if Channel==1
        %A.Time=double(time)./(1000^(4-double(timeUnits.Value)));
        A.TInterval=time; % in [ns]  
        A.Values=double(pBuffer.Value)/32767*Range(1);       
        B=[];
        %MessObjekte=A;
    else
        if Channel==2
            %A.Time=double(time)./(1000^(4-double(timeUnits.Value)));
            A.TInterval=time; % in [ns]  
            A.Values=double(pBuffer2.Value)/32767*Range(1);
            B=[];
            %MessObjekte=B;
        end
    end
else
    if length(Channel)==2
        A.TInterval=time; % in [ns]  
        %A.Time=double(time)./(1000^(4-double(timeUnits.Value)));
        A.Values=double(pBuffer.Value)/32767*Range(1);
        %B.Time=double(time)./(1000^(4-double(timeUnits.Value)));
        B.Values=double(pBuffer2.Value)/32767*Range(2);             
        %MessObjekte=[A B];
    end
end
end

%% Function HasTriggered -----------------------------------------
function [answer]= HasTriggered(TInt)
ScopeHandle=TInt.handle;
if numel(TInt.ScopeVersion)==numel('3204')
    if calllib('PS3000', 'ps3000_ready',ScopeHandle)>0
        answer=1;
    else
        answer=0;
    end
else
    IsReady = libpointer('int16Ptr',zeros(1,1));
    calllib('PS3000a', 'ps3000aIsReady',ScopeHandle,IsReady);
    if IsReady.value>0
        answer=1;
    else
        answer=0;
    end
end
end

%% Function StartTriggerBlock -----------------------------------------
function [TInt]= StartTriggerBlock(ScopeVersion,Channel,RangeIndex,SampleRateIndex,SampleCount,ScopeHandle,TriggerChannel,TriggerVoltage,TriggerDirection,TriggerDelay)
Range(1)=RangeIndex(1); %9=>+-10V
if length(Channel)==2
    if length(RangeIndex)==2
        Range(2)=RangeIndex(2);
    else
        Range(2)=RangeIndex(1);
    end
end

timebase=SampleRateIndex;
oversample=0;

% Diese Pointer (speziell pBuffer, pBuffer2 und overflow) M�SSEN hier
% definiert werden. Sie werden zwar in dieser Funktion nicht ben�tigt, aber
% Matlab (2007a) st�rzt ab, wenn ich sie woanders hin schreibe. Auch die
% �nderung der Reihenfolge f�hrt zum Absturz.
timeUnits = libpointer('int16Ptr',zeros(1,1));
pBuffer = libpointer('int16Ptr',zeros(SampleCount,1));
pBuffer2 = libpointer('int16Ptr',zeros(SampleCount,1));
overflow = libpointer('int16Ptr',zeros(1,1));
MaxSample = libpointer('int32Ptr',zeros(SampleCount,1));

if numel(ScopeVersion)==numel('3204')
    timePtr = libpointer('int32Ptr',zeros(1,1));
    calllib('PS3000', 'ps3000_set_channel',ScopeHandle,0,1,1,Range(1));
    if length(Channel)==2
        calllib('PS3000', 'ps3000_set_channel',ScopeHandle,1,1,1,Range(2));
    end

    %Trigger
    if (exist('TriggerVoltage','var') && exist('TriggerChannel','var') && exist('TriggerDirection','var') && exist('TriggerDelay','var'))
        if TriggerChannel==5
            DAC=Voltage2DACValue(TriggerVoltage,10);
        else
            DAC=Voltage2DACValue(TriggerVoltage,RangeIndex(TriggerChannel));
        end
        calllib('PS3000', 'ps3000_set_trigger',ScopeHandle,TriggerChannel-1,DAC,TriggerDirection,TriggerDelay,0);
    end
    calllib('PS3000', 'ps3000_get_timebase',ScopeHandle,timebase,SampleCount,timePtr,timeUnits,oversample,MaxSample);
    time=double(timePtr.Value)*10^(3*double(timeUnits.Value)-6); %time in [ns]
    calllib('PS3000', 'ps3000_run_block',ScopeHandle,SampleCount,timebase,oversample,1000);
else
    timePtr = libpointer('singlePtr',zeros(SampleCount,1));
    Info.aSetChannel=calllib('PS3000a', 'ps3000aSetChannel',ScopeHandle,0,1,1,Range(1),0);
    if length(Channel)==2
        Info.bSetChannel=calllib('PS3000a', 'ps3000aSetChannel',ScopeHandle,1,1,1,Range(2),0);
    end

    %Trigger
    if (exist('TriggerVoltage','var') && exist('TriggerChannel','var') && exist('TriggerDirection','var') && exist('TriggerDelay','var'))
        if TriggerChannel==5
            DAC=Voltage2DACValue(TriggerVoltage,10);
        else
            DAC=Voltage2DACValue(TriggerVoltage,RangeIndex(TriggerChannel));
        end

        %Set TriggerConditions
        Matlab_Conditions.channelA='PS3000A_CONDITION_DONT_CARE';
        Matlab_Conditions.channelB='PS3000A_CONDITION_DONT_CARE';
        Matlab_Conditions.channelC='PS3000A_CONDITION_DONT_CARE';
        Matlab_Conditions.channelD='PS3000A_CONDITION_DONT_CARE';
        Matlab_Conditions.external='PS3000A_CONDITION_DONT_CARE';
        Matlab_Conditions.aux='PS3000A_CONDITION_DONT_CARE';
        Matlab_Conditions.pulseWidthQualifier='PS3000A_CONDITION_DONT_CARE';
        switch TriggerChannel-1
            case 0
                Matlab_Conditions.channelA='PS3000A_CONDITION_TRUE';
            case 1
                Matlab_Conditions.channelB='PS3000A_CONDITION_TRUE';
            case 2
                Matlab_Conditions.channelC='PS3000A_CONDITION_TRUE';
            case 3
                Matlab_Conditions.channelD='PS3000A_CONDITION_TRUE';
            case 4
                Matlab_Conditions.external='PS3000A_CONDITION_TRUE';
        end
        Conditions=libstruct('tPS3000ATriggerConditions',Matlab_Conditions);
        nConditions=1;
        Info.cSetTriggerChannelConditions=calllib('PS3000a', 'ps3000aSetTriggerChannelConditions',ScopeHandle,Conditions,nConditions);

        %Set TriggerDirections
        Ch_A='PS3000A_NONE';
        Ch_B='PS3000A_NONE';
        Ch_C='PS3000A_NONE';
        Ch_D='PS3000A_NONE';
        Ch_ext='PS3000A_NONE';
        Ch_aux='PS3000A_NONE';
        if TriggerDirection==0
            TriggerDirection_Str='PS3000A_RISING';
        else
            TriggerDirection_Str='PS3000A_FALLING';
        end
        switch TriggerChannel-1
            case 0
                Ch_A=TriggerDirection_Str;
            case 1
                Ch_B=TriggerDirection_Str;
            case 2
                Ch_C=TriggerDirection_Str;
            case 3
                Ch_D=TriggerDirection_Str;
            case 4
                Ch_ext=TriggerDirection_Str;
        end
        Info.dSetTriggerChannelDirections=calllib('PS3000a', 'ps3000aSetTriggerChannelDirections',ScopeHandle,Ch_A,Ch_B,Ch_C,Ch_D,Ch_ext,Ch_aux);

        %Set TriggerChannelProperties
        Matlab_ChannelProperties.thresholdUpper=DAC;
        Matlab_ChannelProperties.thresholdUpperHysteresis=256*10;
        Matlab_ChannelProperties.thresholdLower=DAC;
        Matlab_ChannelProperties.thresholdLowerHysteresis=256*10;
        Matlab_ChannelProperties.channel='PS3000A_CHANNEL_A';
        Matlab_ChannelProperties.thresholdMode='PS3000A_LEVEL';
        switch TriggerChannel-1
            case 0
                Matlab_ChannelProperties.channel='PS3000A_CHANNEL_A';
            case 1
                Matlab_ChannelProperties.channel='PS3000A_CHANNEL_B';
            case 2
                Matlab_ChannelProperties.channel='PS3000A_CHANNEL_C';
            case 3
                Matlab_ChannelProperties.channel='PS3000A_CHANNEL_D';
            case 4
                Matlab_ChannelProperties.channel='PS3000A_EXTERNAL';
        end
        ChannelProperties=libstruct('tPS3000ATriggerChannelProperties',Matlab_ChannelProperties);
        nChannelProperties=1;
        Info.eSetTriggerChannelProperties=calllib('PS3000a', 'ps3000aSetTriggerChannelProperties',ScopeHandle,ChannelProperties,nChannelProperties,0,0);

        %Set TriggerDelay
        Info.fps3000aSetTriggerDelay=calllib('PS3000a', 'ps3000aSetTriggerDelay',ScopeHandle,TriggerDelay);
    end
    Info.fGetTimebase=calllib('PS3000a', 'ps3000aGetTimebase2',ScopeHandle,timebase,SampleCount,timePtr,oversample,MaxSample,0);
    time=double(timePtr.Value); %in [ns]
    TimeIndisposedMs = libpointer('int32Ptr',zeros(1,1));
    CallbackPointr = libpointer('voidPtr'); %empty
    Callback2Pointr = libpointer('voidPtr'); %empty
    Info.gRunBlock=calllib('PS3000a', 'ps3000aRunBlock',ScopeHandle,0,SampleCount,timebase,oversample,TimeIndisposedMs,0,CallbackPointr,Callback2Pointr);
end

TInt.handle=ScopeHandle;
TInt.ScopeVersion=ScopeVersion;
TInt.Time=time;
TInt.Buffer(1)=pBuffer;
TInt.Buffer(2)=pBuffer2;
TInt.overflow=overflow;
TInt.SampleCount=SampleCount;
TInt.Channel=Channel;
TInt.RangeIndex=RangeIndex;
end

%% Function Voltage2DACValue -----------------------------------------
function [Out] = Voltage2DACValue(Voltage,RangeIndex)
%Range: 10->pm20V; 9->pm10V; 8-> pm5V; 7-> pm2V; 6-> pm1V; 7->pm500mV; usw. bis 4
Temp=0;
switch RangeIndex
    case 10
        Temp=round(Voltage*2^16/40);
    case 9
        Temp=round(Voltage*2^16/20);
    case 8
        Temp=round(Voltage*2^16/10);
    case 7
        Temp=round(Voltage*2^16/4);
    case 6
        Temp=round(Voltage*2^16/2);
    case 5
        Temp=round(Voltage*2^16/1);
    case 4
        Temp=round(Voltage*2^16/400e-3);
    case 3
        Temp=round(Voltage*2^16/200e-3);
    case 2
        Temp=round(Voltage*2^16/100e-3);
    case 1
        Temp=round(Voltage*2^16/40e-3);
    case 0
        Temp=round(Voltage*2^16/20e-3);
end
if Temp<(-2^16+1)
    Out=-2^16+1;
else
    if Temp > 2^16-1
        Out=2^16-1;
    else
        Out=Temp;
    end
end
end

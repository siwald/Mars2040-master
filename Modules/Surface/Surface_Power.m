function [Results] = Surface_Power(Cur_Arch,Results, varargin)

%------------------------------------------------------------------------
%----------------------Code Definition-----------------------------------
%Surface Power is taking in all the power requirements from the other
%modules and is sending out the mass and volume for the power equipment. 
%The mass and volume will be a cumulative amount that includes the ISRU, 
%ECLSS, and other surface modules. 

%------Inputs------

%Cumulative Power that is required for all other modules on the surface of
%Mars. 
%Cur_Arch = 'Solar'; 
Results.Cum_Surface_Power = nansum([Results.Surface_Habitat.Power, ...
    Results.ECLSS.Power, ...
    Results.Mars_ISRU.Power]); %Units: kW 
if ~isempty(varargin)%DRA5 comparison
    Results.Cum_Surface_Power = 26; %kW, use DRA5 number.
end

%------Outputs------

%Solar Energy outputs if solar energy is being utilized
%Solar_Area = 288.89; %Units: m^2
%Solar_Mass = 722.22; %Units: kg

%Energy Storage outputs if energy storage is being utilitzed
%Battery_Volume = 0.47; %Units: m^3
%Battery_Mass = 700.00; %Units: kg
%FuelCell_Volume = 0.24; %Units: m^3
%FuelCell_Mass = 190; %Units: kg

%Power Plant outputs if nuclear power is going to be used
%PowerCable_Mass = 114.46; %Units: kg; This mass is dependant on distance of power plant from the base. Assumption for initial model is MAX recommeded distance from base. 
%NuclearPlant_Mass = 40094; %Units: kg; Mass is dependant on power plant size (10MW, 5MW, 4MW, 0.1MW) 
%------Constants------

%The following are constants that are used in equating the requried
%resources. These values can be changed once further information becomes
%available on the actual usage that is seen.

Solar_Size = 1.3; %Units: m^2; Size of solar panels that were used for Spirit and Opportunity
Solar_Output = 450; %Units: W/hr; Lowest power output for solar panels from Spirit and Opportunity Missions. Worst case was asuumed for this study.
Panel_Mass = 2.5; %Units: kg/m^2; Mass of solar panels used for Spirit and Opportunity
PowerPlant_Distance = 3000; %Units: m; distance from power plant to habitat, DRA5, no sheild

XL_Reactor_Size = 10; %Units: MW; Rocketdyne reactor, liquid cooled
L_Reactor_Size = 5; %Units: MW; ORNL reactor, UN pellet fuel pin w/T-111 alloy
%M_Reactor_Size = 4; %Units: MW; 1993 DRM derived from NTP and SP-100
S_Reactor_Size = 0.1; %Units: MW; SP-100 US Research group for nuclear reactors in space
XL_Reactor_Mass = 40095; %Units: kg; Rocketdyne reactor, liquid cooled
XL_Reactor_Volume = 8247.98; %Units: m^3
L_Reactor_Mass = 24500; %Units: kg; ORNL reactor, UN pellet fuel pin w/T-111 alloy
L_Reactor_Volume = 2324.74; %Units: m^3;
%M_Reactor_Mass = 41510; %Units: kg; 1993 DRM derived from NTP and SP-100
S_Reactor_Mass = 4610; %Units: kg; SP-100 US Research group for nuclear reactors in space
S_Reactor_Volume = 36.77; %Units: m^3;
%M_Reactor_Volume = (S_Reactor_Mass + L_Reactor_Mass)/2; %Units: m^3
DRA_Reactor_Size = 40; %units kW
DRA_Reactor_Mass = 8800; %units kg

%{
Defined later
PowerPlant_Mass = 1; %Units: kg; Overall Power plant mass
Power_Mass = 0;
Power_Volume = 0;
%}

%------------------------------------------------------------------------

%Calculations begin 
Solar_Area = (Results.Cum_Surface_Power/(Solar_Output/1000)) * Solar_Size;
Solar_Mass = Solar_Area * Panel_Mass;

Battery_Volume = (4.66*Results.Cum_Surface_Power)/1000;
Battery_Mass = (7*Results.Cum_Surface_Power);
FuelCell_Volume = ((1.4*Results.Cum_Surface_Power)/1000)+0.1;
FuelCell_Mass = (0.9*Results.Cum_Surface_Power)+100;

PowerCable_Mass = (0.11446*PowerPlant_Distance);

XL_Reactor_Size = XL_Reactor_Size * 1000; %Units: kW; convert MW to kW
L_Reactor_Size = L_Reactor_Size * 1000; %Units: kW; convert MW to kW
%M_Reactor_Size = M_Reactor_Size * 1000; %Units: kW; convert MW to kW
S_Reactor_Size = S_Reactor_Size * 1000; %Units: kW; convert MW to kW

XL_Reactor_Quantity = floor(Results.Cum_Surface_Power/XL_Reactor_Size);
Remaining_Power = Results.Cum_Surface_Power - (XL_Reactor_Quantity * XL_Reactor_Size);
if (Remaining_Power/L_Reactor_Size) > 1 %add another XL_Reactor instead of 2 Larges, Mass Savings!
    XL_Reactor_Quantity = XL_Reactor_Quantity + 1;
    Remaining_Power = Remaining_Power - (1 * XL_Reactor_Size);
    L_Reactor_Quantity = 0; %set as 0 for later calcs
else
L_Reactor_Quantity = floor(Remaining_Power/L_Reactor_Size);
Remaining_Power = Remaining_Power - (L_Reactor_Quantity * L_Reactor_Size);
end
%Don't use M reactor, 2X as heavy as Large.
% M_Reactor_Quantity = floor(Remaining_Power/M_Reactor_Size);
% Remaining_Power = Remaining_Power - (M_Reactor_Quantity * M_Reactor_Size);
%M_Reactor_Quantity =0; %set as 0 for later calcs.

if (Remaining_Power / S_Reactor_Size) > 5 %Use another L rather than 6+ S, mass savings!
    L_Reactor_Quantity = L_Reactor_Quantity + 1;
    S_Reactor_Quantity = 0; %set as for later calcs
    Remaining_Power = Remaining_Power - (1 * L_Reactor_Size);
else
    S_Reactor_Quantity = floor(Remaining_Power/S_Reactor_Size);
    Remaining_Power = Remaining_Power - (S_Reactor_Quantity * S_Reactor_Size);
end

if Remaining_Power > 0
    S_Reactor_Quantity = S_Reactor_Quantity + 1; 
else
    %do not add anything to Small Reactor Quantity, we have a power margin!
end

PowerPlant_Mass = (XL_Reactor_Quantity * XL_Reactor_Mass) + (L_Reactor_Quantity * L_Reactor_Mass)+(S_Reactor_Quantity * S_Reactor_Mass);
PowerPlant_Volume = (XL_Reactor_Quantity * XL_Reactor_Volume) + (L_Reactor_Quantity * L_Reactor_Volume)+(S_Reactor_Quantity * S_Reactor_Volume);

n = length(Cur_Arch.SurfacePower);
Power_Method = Cur_Arch.SurfacePower;
[~,Power_Size] = size(Power_Method);
Power_Mass = 0; %Initialize the mass
Power_Volume = 0; %Initialize the volume
for m = 1:n
    switch char(Power_Method(m))
        
        case 'SOLAR'
            Power_Mass = Power_Mass+ (1/Power_Size)*(Solar_Mass + Battery_Mass);
            Power_Volume = Power_Volume + (1/Power_Size)*((Solar_Area * 1) + Battery_Volume); %Assumption made that Solar Panels are 1 meter thick to calculate volume
        
        case 'FUEL_CELL'
            Power_Mass = Power_Mass+(1/Power_Size)*FuelCell_Mass;
            Power_Volume = Power_Volume+(1/Power_Size)*FuelCell_Volume;
    
        case 'RTG'
            %No Equations at this time. Insert equations here
            Power_Mass = Power_Mass;
            Power_Volume = Power_Volume;
        
        case 'NUCLEAR'
            Power_Mass = (PowerPlant_Mass + PowerCable_Mass);
            Power_Volume = PowerPlant_Volume;
    
        otherwise
            error('Power poorly defined in Morph Matrix, should be combination of: Solar, Fuel_Cells , RTG, or Nuclear')
    end
end        
%% add to results object
Results.PowerPlant.Volume = Power_Volume;
Results.PowerPlant.Mass = Power_Mass;
Results.PowerPlant.Power = Results.Cum_Surface_Power - Remaining_Power;
end


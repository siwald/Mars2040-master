function [Crew_Time_Total, ISRU_Requirements, Results] = ECLSS(Cur_Arch, Results, ~)
% Crew_Activity
%------------------------------------------------------------------------
%----------------------Code Definition-----------------------------------
%ECLSS is solving for the life supporting systems. This function will pass
%the mass, volume, and power requirements for sustained life on Mars to 
%ISRU. This function also passes the resources required to sustain life 
%(grow food) to the ISRU function.

%---Testing Section

% Cur_Arch = MarsArchitecture.DEFAULT;
% Results = Results_Class(1);
% Crew_Activity.EVA_Freq = 5;
% Crew_Activity.CM_EVA = 10;
% Crew_Activity.EVA_Dur = 6;
% % 
% Results.Surface_Habitat.Volume = 5750;
% Results.Surface_Habitat.Mass = 4580;

%------Inputs------

% Percentage of food supply grown on Mars
%Food_Supply = 50; 

%Total Cabin Volume for the habitat on Mars. Used for calculating the air
%requied inside the habitat.
 Habitat_Volume = Results.Surface_Habitat.Volume;
 Habitat_Mass = Results.Surface_Habitat.Mass;
%  Habitat_Volume = 1320;
%  Habitat_Mass = 4580;
 

%Crew Activities on Mars. EVA_Freq is the amount of EVA trips expected per 
%week. CM_EVA is the number of crew members per EVA. EVA_Dur is the 
%duration of each EVA per crew member.
Crew_Activity.EVA_Freq = 2;
Crew_Activity.CM_EVA = 4;
Crew_Activity.EVA_Dur = 6;
%Find the total time budget of time on Mars

%------Outputs------

%Required resources from ISRU. All requirements sent in kg/day
%ISRU_Requirements.Oxygen = 10.81;
%ISRU_Requirements.Water = 46.29;
%ISRU_Requirements.Nitrogen = 1.70;
%ISRU_Requirements.CO2 = 19.94;

%SWAP requirements. Power is average power in kW. Mass is kg/mission.
%Volume is the consumables in m3/mission
%ECLSS_Power = 247.16;
%ECLSS_Mass = 39764.60;
%ECLSS_Volume = 202.57;

%Crew Time for ECLSS Activities
%CrewTime_FoodGrowth = Crew time required for growing food. Units: CM-hr/day
%CrewTime_Cooking = Crew time required for cooking. Units: CM-hr/day

%------Constants------

%The following are constants that are used in equating the requried
%resources. These values can be changed once further information becomes
%available on the actual usage that is seen.

%-------------------------------------------------------------------------

%----------------------------General--------------------------------------
MARS_2040.Crew_Size = Cur_Arch.SurfaceCrew.Size; %Units: Crew Members; Mission Decision
%MARS_2040.Crew_Size = 4; %DRA5.0 Testing Condition
MARS_2040.Surface_Duration = 780;

%----------------------------Habitat--------------------------------------
Cabin_Pressure = 70.3; %Units: kPa; Architectural Decision by Team
Gas_Constant = 8.31451; %Units: J/K*mol
O2_Mol_Ratio = 26.5; %Units: %; Architectural Decision from BVAD pg. 28
CO2_Mol_Ratio = 0.57; %Units: %; Architectural Decision from BVAD pg. 28
Temperature = 296; % Units: K; Architectural Decision from BVAD pg. 28
Habitat_Leakage_Rate = 0.05; %Units: %/day; BVAD pg 28; Did not change in BVAD 2015
%Habitat_CO2_Generation = 0.998; %Units: kg/CM/day; BVAD pg 28
Habitat_CO2_Generation = 1.04; %Units: kg/CM/day; BVAD 2015 pg. 50
%Habitat_O2_Consumption = 0.835; %Units: kg/CM/day; BVAD pg 28
Habitat_O2_Consumption = 0.816; %Units: kg/CM/day; BVAD 2015 pg. 50
UPA_Efficiency = 74; %Units: %; Efficency to reuse water from urine flush
WPA_Efficiency = 100; %Units: %; Efficiency to reuse water from waste water

%----------------------------Food-----------------------------------------
Earth_Food_Mass = 2.3; %Units: kg/CM/day; Architectural Decision from BVAD pg. 56
Earth_Food_Volume = 0.00657; %Units: kg/CM/day; Architectural Decision from BVAD pg. 56
[~,Food_Supply] = Cur_Arch.FoodSupply.Amount; %Units: %; Percentage of food to be grown on Mars.
MARS_2040.Food_Supply = Food_Supply;
CrewTime_FoodGrowth = 13.1; %Units: CM-hr/m3/yr; BVAD 2015 p.163
Mars_Food_Prep = 0.83; %Units: CM-hr/CM-day; This is the amount of preparation time required to prepare fod that is grown on Mars; BVAD 2015 p.109
Earth_Food_Prep = 0.17; %Units: CM-hr/CM-day; This is the amount of preparation time required to prepare food that is brought to Mars from Earth; BVAD 2015 p.109

%-----------------------------EVA-----------------------------------------
%EVA_Oxygen_Loss_Rate = 0.15; %Units: kg/CM/hr; BVAD pg 139
EVA_Oxygen_Loss_Rate = 0.092; %Units: kg/CM/hr; BVAD 2015 p.131
%EVA_Airlock_Volume = 3.7; % units: m^3; BVAD pg 139
EVA_Airlock_Volume = 2.9; % units: m^3; BVAD 2015 pg. 131
EVA_Airlock_Gas_Loss = 13.8; %Units: kPa; MarsOne
EVA_Oxygen_Consumption = 0.075; %Units: kg/CM/hr; BVAD pg 139; Did not change in BVAD 2015
EVA_CO2_Production = 0.093; %Units: kg/CM/hr; BVAD pg 139; Did not change in BVAD 2015
%EVA_Cooling_Loss = 0.19; %Units: kg/CM/day; BVAD p 139
EVA_Cooling_Loss = 0.625; %Units: kg/CM/day; BVAD 2015 pg.130
EVA_Water_Consumption = 0.24; %Units: kg/CM/day; BVAD p139; Did not change in BVAD 2015


%------------------------------------------------------------------------
%------------------------------------------------------------------------

%Calculations begin

%Calculations to determine the amount of oxygen required from ISRU. The
%structure ISRU_Requirements will be sent to the ISRU function. All
%equations derived in the Habitat Resource Analysis_v2.xlsx. 

ECLSS_Crop = ECLSS_Crop_Function(MARS_2040);

EVA_Weekly_Rate = Crew_Activity.EVA_Freq * Crew_Activity.CM_EVA * Crew_Activity.EVA_Dur;
Cabin_Air = Cabin_Pressure*1000*Habitat_Volume/Gas_Constant/Temperature; %Units: mol
N2_Pressure = 1-(O2_Mol_Ratio/100) - (CO2_Mol_Ratio/100); %Units: %
Airlock_Gas_Loss = 13.8*10000*EVA_Airlock_Volume/(Gas_Constant*Temperature);
EVA_O2_Loss = (EVA_Oxygen_Loss_Rate+EVA_Oxygen_Consumption)*EVA_Weekly_Rate/7;
Oxygen_Loss.Airlock = (EVA_Airlock_Gas_Loss*(O2_Mol_Ratio/100)/100*32)*(Crew_Activity.CM_EVA/2)*Crew_Activity.EVA_Freq/1000/7;
Habitat_Gas_Loss = Cabin_Air * (Habitat_Leakage_Rate/100);
Oxygen_Loss.Leakage = Habitat_Gas_Loss*(O2_Mol_Ratio/100)*32/1000;
Oxygen_Loss.Breathing = Habitat_O2_Consumption*MARS_2040.Crew_Size;
EMU_O2_Supply = EVA_O2_Loss+Oxygen_Loss.Airlock;
Oxygen_Storage = ECLSS_Crop.Crop_O2_Generation - EMU_O2_Supply;

ISRU_Requirements.Oxygen = Oxygen_Storage - (Oxygen_Loss.Airlock + Oxygen_Loss.Leakage + Oxygen_Loss.Breathing);
ISRU_Requirements.Oxygen = ISRU_Requirements.Oxygen * -1;

%Calculations to determine the amount of Water that is required from ISRU. 
EMU_EVA_Loss = (EVA_Cooling_Loss*EVA_Weekly_Rate/7)+(EVA_Water_Consumption*EVA_Weekly_Rate/7);
Crew_Water = ECLSS_Water(MARS_2040.Crew_Size);
Crop_Water_Requirement = ECLSS_Crop.Crop_Water_Requirement;
Habitat_Water_CCAA = Crew_Water.Vapor_Water;
Portable_Water_Crew = EMU_EVA_Loss+Crew_Water.Drink_Water+Crew_Water.Urine_Flush+Crew_Water.Hygiene+Crew_Water.Shower+Crew_Water.Laundry_In+(Crop_Water_Requirement*-1);
Habitat_DirtyUrine_Water = Crew_Water.Urine_Water_Flush - (Crew_Water.Urine_Water_Flush*(UPA_Efficiency/100));
Habitat_Clean_Water = (Habitat_Water_CCAA+(Crew_Water.Urine_Water_Flush*(UPA_Efficiency/100))+Crew_Water.Hygiene+Crew_Water.Shower+Crew_Water.Laundry_In)*(WPA_Efficiency/100);

ISRU_Requirements.Water = Habitat_Clean_Water - Portable_Water_Crew;
ISRU_Requirements.Water = ISRU_Requirements.Water * -1;


%Calculations to determine the amount of Nitrogen that is required from ISRU.
N2_Loss_Airlock = Airlock_Gas_Loss*N2_Pressure/100*28;
N2_Loss_Leakage = Habitat_Gas_Loss*N2_Pressure/1000*28;

N2_Loss_Airlock = N2_Loss_Airlock *(Crew_Activity.CM_EVA/2)*Crew_Activity.EVA_Freq/1000/7;

ISRU_Requirements.Nitrogen = N2_Loss_Airlock + N2_Loss_Leakage;

%Calculations to determine the amount of CO2 that is required from ISRU.
CO2_Loss.Breathing = Habitat_CO2_Generation*MARS_2040.Crew_Size;
CO2_Loss.Leakage = Habitat_Gas_Loss * (CO2_Mol_Ratio/100)*44/1000;
CO2_Loss.Airlock = Airlock_Gas_Loss* (CO2_Mol_Ratio/100)/100*44;
CO2_Loss.Airlock = CO2_Loss.Airlock*(Crew_Activity.CM_EVA/2)*Crew_Activity.EVA_Freq/1000/7;

ISRU_Requirements.CO2 = (CO2_Loss.Breathing - CO2_Loss.Leakage - CO2_Loss.Airlock)*-1;

MARS_2040.O2_Spec = ISRU_Requirements.Oxygen;
MARS_2040.CO2_Spec = ISRU_Requirements.CO2;
MARS_2040.CCAA_Spec = Habitat_Water_CCAA;
MARS_2040.UPA_Spec = Crew_Water.Urine_Water_Flush;
MARS_2040.WPA_Spec = Portable_Water_Crew;
MARS_2040.CRA_Spec = ISRU_Requirements.CO2;
MARS_2040.CO2_Injector_Spec = ECLSS_Crop.Crop_CO2_Generation;
MARS_2040.Crop_Area = ECLSS_Crop.Crop_Grow_Area;
MARS_2040.Habitat_Mass = Habitat_Mass;
MARS_2040.Habitat_Volume = Habitat_Volume;
MARS_2040.Packed_Food_Mass = Earth_Food_Mass;
MARS_2040.Packed_Food_Volume = Earth_Food_Volume;

[ECLSS_Mass, Storage_Mass, Crew_System_Mass] = ECLSS_Mass_Function(MARS_2040, (0.05*2.137));

%Calculations to determine the amount of Crew Time is required to prepare
%and cook food. 

CrewTime_FoodPrep = (Mars_Food_Prep*MARS_2040.Food_Supply)+(Earth_Food_Prep*(1-MARS_2040.Food_Supply));
Crew_Time.FoodGrowth = ECLSS_Crop.Crop_Grow_Area * CrewTime_FoodGrowth / 365;
Crew_Time.Cooking = CrewTime_FoodPrep * MARS_2040.Crew_Size;
Crew_Time_Total = Crew_Time.FoodGrowth + Crew_Time.Cooking;

%Calculations to determine the amount of Mass required for consumables and
%spares

%ECLSS_Mass = ECLSS_Spares_Mass + ECLSS_Consumables_Mass;
%ECLSS_Mass = ECLSS_Consumables_Mass;
Results.ECLSS.Consumables_Mass = Storage_Mass.Consumables_Mass.Overall + Crew_System_Mass.Consumables_Mass.Overall + ECLSS_Crop.Consumables_Mass;
Results.ECLSS.Consumables_Volume = Storage_Mass.Consumables_Volume.Overall + Crew_System_Mass.Consumables_Volume.Overall + ECLSS_Crop.Consumables_Volume;
Results.ECLSS.Spares_Mass = ECLSS_Mass.Spare_Mass.Overall + Storage_Mass.Spare_Mass.Overall + Crew_System_Mass.Spare_Mass.Overall;
Results.ECLSS.Spares_Volume = ECLSS_Mass.Spare_Volume.Overall + Storage_Mass.Spare_Volume.Overall + Crew_System_Mass.Spare_Volume.Overall;
Results.ECLSS.Mass = ECLSS_Mass.Equipment_Mass.Overall + Storage_Mass.Equipment_Mass.Overall + Crew_System_Mass.Equipment_Mass.Overall;
Results.ECLSS.Power = ECLSS_Mass.Equipment_Power.Overall + Crew_System_Mass.Equipment_Power.Overall;
Results.ECLSS.Volume = ECLSS_Mass.Equipment_Volume.Overall + Storage_Mass.Equipment_Volume.Overall + Crew_System_Mass.Equipment_Volume.Overall;
Results.ECLSS.Replacements_Mass = ECLSS_Mass.Replacements_Mass.Overall;
Results.ECLSS.Replacements_Volume = ECLSS_Mass.Replacements_Volume.Overall;
Results.ECLSS.Lighting_Mass = ECLSS_Mass.Equipment_Mass.GLS;
Results.ECLSS.Lighting_Volume = ECLSS_Mass.Equipment_Volume.GLS;
Results.ECLSS.Lighting_Power = ECLSS_Mass.Equipment_Power.GLS;
%Results.ECLSS.Consumables = ECLSS_Consumables_Mass;
%ECLSS_Volume = ECLSS_Spares_Volume + ECLSS_Consumables_Volume;
%ECLSS_Volume = ECLSS_Consumables_Volume;
%ECLSS_Power = 247164.17/1000; %Units: kW

%Results.ECLSS.Mass = ECLSS_Consumables_Mass;
%Results.ECLSS.Volume = ECLSS_Consumables_Volume;
%Results.ECLSS.Power = ECLSS_Power;

end


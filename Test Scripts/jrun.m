%setup morphological matrix
SparesRatio = 0.05; %percentage of Mass per Year, Leath and Green, 1993
Synod = 2.137;

% % DRA 5 Case
% Morph = MarsArchitecture.Enumerate( ...
%     {Propulsion.NTR,Propulsion.LH2},...
% 	{Location.LEO},... 
% 	{[TransitFuel.EARTH_LH2,TransitFuel.EARTH_O2]},...
%     {[ReturnFuel.EARTH_LH2, ReturnFuel.EARTH_O2]}, ...
%     {Crew.DRA_CREW}, ...
%     {SurfaceCrew.MIN_SURFACE}, ...
%     {PowerSource.NUCLEAR}, ...
%     {SurfaceShielding.REGOLITH}, ...
%     {ArrivalEntry.AEROCAPTURE, ArrivalEntry.PROPULSIVE}, ...
%     {Site.GALE}, ...
%     {FoodSource.EARTH_ONLY} ...
%     );

% General Case Matrix
Morph = MarsArchitecture.Enumerate( ...
    {Propulsion.LH2,Propulsion.NTR},...
	{Location.LEO},... 
	{[TransitFuel.EARTH_LH2,TransitFuel.EARTH_O2]},...
    {[ReturnFuel.EARTH_LH2, ReturnFuel.EARTH_O2]}, ...
    {Crew.DRA_CREW, Crew.DEFAULT_TRANSIT}, ...
    {SurfaceCrew.TARGET_SURFACE, SurfaceCrew.MID_SURFACE, SurfaceCrew.MIN_SURFACE}, ...
    {PowerSource.NUCLEAR}, ...
    {SurfaceShielding.REGOLITH}, ...
    {ArrivalEntry.AEROCAPTURE}, ...
    {Site.GALE}, ...
    {FoodSource.EARTH_ONLY,FoodSource.EARTH_MARS_50_SPLIT,FoodSource.MARS_ONLY,FoodSource.EARTH_MARS_25_75, FoodSource.EARTH_MARS_75_25} ...
    );

[~, Num_Arches] = size(Morph)

%Preallocate the results array
All_Results = cell(Num_Arches,1); %1 row for every architectureal combo, 1 cols: Results object

data = zeros(Num_Arches,18);
desc = struct('RunNo',{},'PropType',{},'TransitCrew',{},'SurfaceCrew',{},'FoodGrown',{},...
    'Staging',{},'TransitFuel',{},'TransitLOX',{},'ReturnFuel',{},'ReturnLOX',{},'Site',{},...
    'OrbitCapture',{},'IMLEO',{},'Consumables',{},'Spares',{},'Replacements',{},'SurfPower',{},'NumCargo',{},...
    'mCrewVehicle',{},'mPropCrewVehicle',{},...
    'mCargoVehicle',{},'mPropCargoVehicle',{},...
    'mAscentVehicle',{},'mPropAscentVehicle',{},...
    'LandedMass',{}, 'ECLSS_ISRU_Rqmnts',{});

%% Begin Main Loop
for i=1:Num_Arches %begin looping for each architecture
    %extract current archeticture from Morph
    Cur_Arch = Morph{i};
    Cur_Arch.Index = i;
    %initialize the Results Object for this run
    Results = Results_Class(i); %with the Arch_Num of i
    %% Logistics Setup %%
    
    %% --- Duration Module --- %%
    %{
    Inputs:
        Cur_Arch
            Trajectory in TrajectoryType
    Outputs:
        Trajectory Object
            Stay Duration in Days
            Outgoing Duration in Days
            Return Duration in Days
            Contingency Duration in Days
    %}
    %Trajectory_obj = Duration(Cur_Arch);
    
    %% --- Transit Hab Module --- %%
    %{
    Inputs:
        Cur_Arch
            Crew_Number in #
        Trajectory Object
            Stay Duration in Days
            Outgoing Duration in Days
            Return Duration in Days
            Contingency Duration in Days
        Overall Spacecraft Object
            empty
    Outputs:
        Overall Spacecraft Object
            Transit Hab
                Dry Mass
                Power
                Volume
    %}
    Results.HumanSpacecraft = Transit_Habitat(Cur_Arch, Results.HumanSpacecraft, Results);
    
    %% --- Earth Entry Module --- %%
    %{
    Inputs: 
        Cur_Arch
            Transit Crew Size in #
            Payload Mass and Volume (0 for now)
        Overall Spacecraft Object
    Outputs:
        Overall Spacecraft Object
            Earth Entry
                Habitable Mass
                Habitable Vol
                Bus Volume
                Bus Mass
    %}
    
    Earth_Entry = SC_Class('Earth Entry Module'); %initialize the Earth Entry Module
    Earth_Entry.Hab_Mass = Cur_Arch.TransitCrew.Size * 1570; %kg, based on (Apollo CM Mass - heat sheild mass) / astronaut
    Earth_Entry.Hab_Vol = Cur_Arch.TransitCrew.Size * 2.067; %based on Apollo hab vol / astronaut
    Earth_Entry.Payload_Vol = 0; %As yet undefined, and not a trade
    Earth_Entry.Payload_Mass = 0; %As yet undefined, and not a trade
    Earth_Entry.volume_calc; %populate the total volume
    Earth_Entry.Bus_Mass = Earth_Entry.Volume * 81.73; %size of HeatSheild, kg, based on Apollo, per total module volume
    Earth_Entry.drymass_calc; %populate the overall mass numbers
    Results.HumanSpacecraft.Add_Craft = Earth_Entry; %Add entry module to the S/C
    
    %% --- Return Transit Module --- %%
    %{
    Inputs:
        Cur_Arch
            Trajectory Class
        Spacecraft
            -Transit Habitat
            -Earth Entry
            Mass      
    Outputs:
        Spacecraft
            Return Engine Stage
        Results Object
            Mars ISRU requirements
    %}
    
    [Results.HumanSpacecraft, Results] = Return_Trans (Cur_Arch, Results.HumanSpacecraft, Results);
    
    %% --- Ascent Module --- %%
    %{
    Inputs:
        Cur_Arch
            Propulsion Type
        HumanSpacecraft
            EarthEntry Module
        Results
            Mars Fuel ISRU
            Mars Oxidizer ISRU
    
    Outputs:
        AscentSpacecraft
        HumanSpacecraft without reuseable Ascent/Descent Craft
        Results with updated ISRU fuel
    %}
    
    [Results.AscentSpacecraft, Results.HumanSpacecraft, Results] = Ascent (Cur_Arch, Results.HumanSpacecraft, Results);
       
    %% --- Surf Structure --- %%
    %{
    Inputs:
        Cur_Arch
    Outputs:
        Results
            Surface Mass
            Surface Volume
            Surface Power
    %}
    [Results, Food_Time, ECLSS_ISRU] = Surface_Habitat(Cur_Arch, Results);
    
    %% --- ECLSS Module --- %%
    %{
    Inputs:
        Cur_Arch
            Crew Number
        Results
            Surface_Habitat.Volume
    Outputs:
        Results
            ECLSS.Mass, Volume & Power
            ISRURequirements object
    %}
    %[Food_Time, ECLSS_ISRU, Results] = ECLSS (Cur_Arch, Results);

  %% --- Site Selection Module --- %%
    %{
    Inputs:
        Cur_Arch
            SiteSelection
    Outputs:
        Site_Sci_Value
    %}
    [Site_Sci_Value, Site_Elevation, Site_Water_Percent] = Site_Selection(Cur_Arch);
    
    %% --- Mars ISRU --- %%
    %{
    Inputs:
        Cur_Arch
        ISRURequirements object
        Results
            Fuel & Oxidizer_Output
    Outputs:
        Results
            ISRU.Mass, Volume & Power
    %}
    Results = ISRU(Cur_Arch, ECLSS_ISRU, Site_Water_Percent, Results);
  
    %% --- Surface Power Module --- %%
    %{
    Inputs:
        Cur_Arch
            Surface_Power
        Results
            ECLSS, Surface_Habitat & ISRU.Power
    Outputs:
        Results
            Surface_PowerPlant.Mass & Volume
    %}
    Results = Surface_Power (Cur_Arch, Results);
    
    %% --- ISFR and Sparing Module --- %%
    %{
    Inputs:
        Results
            Surface_Habitat, ECLSS, Mars_ISRU, PowerPlant.Mass
    Outputs:
        Results
            Surface_Habitat, ECLSS, Mars_ISRU, PowerPlant.Spares
    %}
    SparesRatio = 0.05; %percentage of Mass per Year, Leath and Green, 1993
    %Years per Synodic Cycle = 2.137, be able to convert to % mass per
    %resupply
    Synod = 2.137;
    
    Results.Surface_Habitat.Spares = Results.Surface_Habitat.Mass * SparesRatio * Synod;
    Results.ECLSS.Spares = Results.ECLSS.Mass * SparesRatio * Synod;
    Results.Mars_ISRU.Spares = Results.Mars_ISRU.Mass * SparesRatio * Synod;
    Results.PowerPlant.Spares = Results.PowerPlant.Mass * SparesRatio * Synod;
    
    %% --- Astronaut Time Module --- %%
    %{
    Inputs:
        Cur_Arch
            SurfaceCrew.Size
        Results
            Spares
    Outputs:
        Astronaut_Sci_Time
    %}
    [Results] = Astronaut_Time(Cur_Arch, Results, Food_Time);
    
    %% --- Descent --- %%
    %{
    Inputs:
        Cur_Arch
            TransitCrew.Size
        Results
            Spares
            Consumables
            Replacements
        Ascent_Vehicle
            Entry and Ascent Module
    Outputs:
        Descent_Craft
            MEAA Module
            Cargo Descenders
    %}
    
    [Results.AscentSpacecraft, Results.HumanSpacecraft, Results.CargoSpacecraft, Results.Num_CargoSpacecraft] = Descent(Cur_Arch, Results.AscentSpacecraft, Results.HumanSpacecraft, Results, Site_Elevation);
    %% --- Outgoing Transit --- %%
    %{
    Inputs:
        HumanSpacecraft
        CargoSpacecraft
        Cur_Arch
            HumanTrajectory
            CargoTrajectory
    Outputs:
        HumanSpacecraft
        CargoSpacecraft
    %}
    [Results.HumanSpacecraft] = NewTransit(Cur_Arch, Results.HumanSpacecraft, 'Human', Results);
    [Results.CargoSpacecraft] = NewTransit(Cur_Arch, Results.CargoSpacecraft, 'Cargo', Results);
    %% --- Lunar ISRU --- %%
    %{
    Inputs:
        Cur_Arch
            TransitFuel
        HumanSpacecraft
            Fuel_Mass
            Ox_Mass
        Results.CargoSpacecraft
            Fuel_Mass
            Ox_Mass
        Results
    Outputs:
        Results
        FerrySpacecraft
    %}
    if ~or(isequal(Cur_Arch.TransitFuel, [TransitFuel.EARTH_LH2, TransitFuel.EARTH_O2]),...
        isequal(Cur_Arch.TransitFuel, [TransitFuel.EARTH_O2, TransitFuel.EARTH_LH2])) % Only go through this if there is Lunar ISRU involved
        [Results.FerrySpacecraft, Results.HumanSpacecraft, Results.CargoSpacecraft, Results] = Lunar_ISRU (Cur_Arch, Results.HumanSpacecraft, Results.CargoSpacecraft, Results);
    end
    %% --- Staging Module --- %%
    HumanStageing = SC_Class('Staging Engines'); %should Initialize
    HumanStageing = Propellant_Mass(Cur_Arch.PropulsionType,HumanStageing,Hohm_Chart('LEO',Cur_Arch.Staging.Code),Results.HumanSpacecraft.Mass);
    if HumanStageing.Prop_Mass > 0 %if staging is LEO, skip the add
        Results.HumanSpacecraft.Add_Craft = HumanStageing;
    end
    
    CargoStageing = SC_Class('Staging Engines');
    CargoStageing = Propellant_Mass(Cur_Arch.PropulsionType,CargoStageing,Hohm_Chart('LEO',Cur_Arch.Staging.Code),nansum([Results.CargoSpacecraft.Mass, ...
        Results.FerrySpacecraft.Prop_Mass, ...%Needs to bring the non-Lunar ISRU prop mass to staging point for the Ferry
        Results.Lunar_ISRU.Spares])); %Needs to bring the Lunar Spares as well.
    if CargoStageing.Prop_Mass > 0 %if staging is LEO, skip the add
    Results.CargoSpacecraft.Add_Craft = CargoStageing;
    end
    
    Results.IMLEO = nansum([Results.HumanSpacecraft.Mass, (Results.CargoSpacecraft.Mass*Results.Num_CargoSpacecraft), Results.FerrySpacecraft.Prop_Mass, Results.Lunar_ISRU.Spares]);
%     disp(Results.IMLEO)
    
    %% --- Science Module --- %%
    %{
    Inputs:
        Results
            Astronaut_Sci_Time
            Site_Sci_Value
    Output:
        Results
            Science
    %}
    Results.Science = Results.Science_Time * Site_Sci_Value;
    
    %% Fill out Results Row
    %Create comeplete row first, so there's only 1 index into the global
    %All_Rdesults outside the parfor
    %1 row for every architectureal combo, 5 cols: Results object, Human S/C, 1 array of Cargo S/C, Ferry S/C, Ascent S/C
    %Index into All_Results
    All_Results{i,1} = Results; 
    
    % Case Description
    desc(i).Site = Morph{i}.SurfaceSites.Name;
    desc(i).PropType = Morph{i}.PropulsionType.type;
    desc(i).FoodGrown = Morph{i}.FoodSupply(2).Amount;
    desc(i).Staging = Morph{i}.Staging.Name;
    desc(i).TransitCrew = Morph{i}.TransitCrew.Size;
    desc(i).SurfaceCrew = Morph{i}.SurfaceCrew.Size;
    desc(i).TransitFuel = Morph{i}.TransitFuel(1).Location.Name;
    desc(i).TransitLOX = Morph{i}.TransitFuel(2).Location.Name;
    desc(i).ReturnFuel = Morph{i}.ReturnFuel(1).Location.Name;
    desc(i).ReturnLOX = Morph{i}.ReturnFuel(2).Location.Name;
    desc(i).OrbitCapture = Morph{i}.OrbitCapture.Name;
    desc(i).Consumables = Results.Consumables/1000;
    desc(i).Spares = Results.Spares/1000;
    desc(i).Replacements = Results.Replacements/1000;
    desc(i).SurfPower = Results.Cum_Surface_Power;
    desc(i).IMLEO = Results.IMLEO/1000;
    desc(i).NumCargo = Results.Num_CargoSpacecraft;
    desc(i).mAscentVehicle = Results.AscentSpacecraft.Mass/1000;
    desc(i).mPropAscentVehicle = Results.AscentSpacecraft.Prop_Mass/1000;
    desc(i).mCargoVehicle = Results.CargoSpacecraft.Mass/1000;
    desc(i).mPropCargoVehicle = Results.CargoSpacecraft.Prop_Mass/1000;
    desc(i).mCrewVehicle = Results.HumanSpacecraft.Mass/1000;
    desc(i).mPropCrewVehicle = Results.HumanSpacecraft.Prop_Mass/1000;
    desc(i).RunNo = i;
    desc(i).LandedMass = (Results.Consumables + Results.AscentSpacecraft.Mass + Results.Spares)/1000;
   
    % Joseph's Data Extraction for plots
    data(i,1) = Results.HumanSpacecraft.Mass;
    data(i,2) = Results.HumanSpacecraft.SC{1,1}.Origin_Mass;    % Transit Hab 
    data(i,3) = Results.HumanSpacecraft.SC{2,1}.Origin_Mass;    % Return Engine
    data(i,4) = Results.HumanSpacecraft.SC{3,1}.Origin_Mass;    % Earth Entry
    data(i,5) = Results.HumanSpacecraft.SC{4,1}.Origin_Mass;    % Mars Capture
    data(i,6) = Results.HumanSpacecraft.SC{5,1}.Origin_Mass;    % Dry Mass
    data(i,7) = Results.CargoSpacecraft.Mass;
    data(i,8) = Results.CargoSpacecraft.SC{1,1}.Origin_Mass;
    data(i,9) = Results.CargoSpacecraft.SC{2,1}.Origin_Mass;
    data(i,10) = Results.CargoSpacecraft.SC{3,1}.Origin_Mass;
    data(i,11) = Results.Consumables;
    data(i,12) = Results.Spares;
    data(i,13) = Results.Cum_Surface_Power;
    data(i,14) = Results.Science_Time;
    data(i,15) = Results.IMLEO;
    data(i,16) = Results.Num_CargoSpacecraft;
    data(i,17) = i;    
    data(i,18) = Results.AscentSpacecraft.Mass;
end

% Write to Excel file for data review
xlswrite('Results.xls',struct2cell(desc(:)).',1,'A2');

close all;

data = sortrows(data,15);

vehicles = zeros (size(data,1),6);
vehicles(:,1) = data(:,1);                    % Crew Vehicle
vehicles(:,2) = data(:,7);                    % Cargo Vehicle1
vehicles(:,3) = data(:,7).*(fix(data(:,16)/2)-fix(data(:,16)/4)); % Cargo Vehicle2
vehicles(:,4) = data(:,7).*fix(data(:,16)/3); % Cargo Vehicle3
vehicles(:,5) = data(:,7).*fix(data(:,16)/4); % Cargo Vehicle4
vehicles(:,6) = data(:,7).*fix(data(:,16)/5); % Cargo Vehicle5

lmass = zeros (size(data,1),3);
lmass(:,1) = data(:,11);    % Consumables
lmass(:,2) = data(:,12);    % Spares
lmass(:,3) = data(:,18);    % Ascent SC

% Figure 1 -> Resupply Mass
figure;
bar (lmass/1000,'stacked');
grid;
title ('Resupply Mass (Spares, Consumables, Ascent SC)');
ylabel ('Mass (mt)');
legend ('Consumables Mass','Spare Mass','Ascent S/C','location','northeast')

% Figure 2 -> IMLEO
figure;
bar(vehicles/1000, 'stacked');
grid;
title ('IMLEO Sorted by Mass');
ylabel ('IMLEO');
legend ('Human Vehicle','Cargo Vehicle1','Cargo Vehicle2','Cargo Vehicle3','Cargo Vehicle4','Cargo Vehicle5','Location','northwest');

% Figure 3 -> 
figure;
scatter (data(:,14),data(:,15)/1000);
grid;
title ('IMLEO vs. Science Time');
xlabel ('Science Time per Synodic Period');
ylabel ('IMLEO (mt)');

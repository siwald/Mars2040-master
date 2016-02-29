classdef Results_Class < dynamicprops
    %RESULTS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        %Results
        Arch_Num
        Arch_Name
        Science
        Risk
        % replace with space craft objects
        %SpaceCraft
        %Food
        %SC_Drymass
        %Propellant
        %Fuel
        %Oxidizer
        Regolith
        Science_Time
        IMLEO
        Cum_Surface_Power
        
        % Spacecraft breakdowns
        HumanSpacecraft = OverallSC();
        CargoSpacecraft = OverallSC();
        Num_CargoSpacecraft;
        FerrySpacecraft  = OverallSC();
        AscentSpacecraft = OverallSC();
        
        %Module Breakdowns
        Transit_Habitat = Results_List();
        Surface_Habitat = Results_List();
        ECLSS = Results_List();
        Mars_ISRU = Results_List();
        Lunar_ISRU = Results_List();
        ISFR = Results_List();
        PowerPlant = Results_List();
    end
    properties (SetAccess = private) %thus GetAccess is public, for access to aggregate lists
        Consumables
        Spares
        Replacements
        Lighting
    end
    
    methods
        %Constructor with Arch Number
        function obj = Results_Class(num)
            obj.Arch_Num = num;
            %initialize objects
            obj.HumanSpacecraft = OverallSC();
            obj.CargoSpacecraft = OverallSC();
            obj.FerrySpacecraft = OverallSC();
            obj.AscentSpacecraft = OverallSC();
            obj.Transit_Habitat = Results_List();
            obj.Surface_Habitat = Results_List();
            obj.ECLSS = Results_List();
            obj.Mars_ISRU = Results_List();
            obj.Lunar_ISRU = Results_List();
            obj.ISFR = Results_List();
            obj.PowerPlant = Results_List();
            obj.IMLEO = IMLEO_Split();
        end
        
        %Getter for total Consumables
        function out = get.Consumables(obj)
            out = nansum([obj.ECLSS.Consumables,
                obj.Surface_Habitat.Consumables,
                obj.Mars_ISRU.Consumables,
                obj.Lunar_ISRU.Consumables,
                obj.ISFR.Consumables,
                obj.PowerPlant.Consumables]); %sum Consumables from each Module
        end

        %Getter for total Spares
        function out = get.Spares(obj)
            out = nansum([obj.ECLSS.Spares,
                obj.Surface_Habitat.Spares,
                obj.Mars_ISRU.Spares,
                obj.Lunar_ISRU.Spares,
                obj.ISFR.Spares,
                obj.PowerPlant.Spares]); %sum Spares from each Module
        end
                %Getter for total Replacements
        function out = get.Replacements(obj)
            out = nansum([obj.ECLSS.Replacements,
                obj.Surface_Habitat.Replacements,
                obj.Mars_ISRU.Replacements,
                obj.Lunar_ISRU.Replacements,
                obj.ISFR.Replacements,
                obj.PowerPlant.Replacements]); %sum Replacements from each Module
        end
        function out = get.Lighting(obj)
            out = nansum([obj.ECLSS.Lighting,
                obj.Surface_Habitat.Lighting,
                obj.Mars_ISRU.Lighting,
                obj.Lunar_ISRU.Lighting,
                obj.ISFR.Lighting,
                obj.PowerPlant.Lighting]); %sum Replacements from each Module
        end
        
    end
    
end


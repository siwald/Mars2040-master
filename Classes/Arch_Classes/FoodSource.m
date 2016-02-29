%% Class representing food source
classdef FoodSource < handle
    %% private class members
    properties (Access = private)
        location = '';
        amount = 0.0;
    end
    
    %% public dependent members
    properties (Dependent)
        Location;
        Amount;
        CrewHourCostPerKg;
    end
    
    properties(Constant, GetAccess = public)
        EARTH_ONLY =  [FoodSource(Location.EARTH, 1), FoodSource(Location.MARS, 0)];
        EARTH_MARS_50_SPLIT = [FoodSource(Location.EARTH, 0.500), FoodSource(Location.MARS, 0.500)];
        EARTH_MARS_25_75 = [FoodSource(Location.EARTH, 0.25), FoodSource(Location.MARS, 0.75)];
        EARTH_MARS_75_25 = [FoodSource(Location.EARTH, 0.75), FoodSource(Location.MARS, 0.25)];
        MARS_ONLY =  [FoodSource(Location.EARTH, 0), FoodSource(Location.MARS, 1)];
        M125 =  [FoodSource(Location.EARTH, 0.875), FoodSource(Location.MARS, .125)];
        M375 =  [FoodSource(Location.EARTH, .625), FoodSource(Location.MARS, .375)];
        M625 =  [FoodSource(Location.EARTH, .375), FoodSource(Location.MARS, .625)];
        M875 =  [FoodSource(Location.EARTH, .125), FoodSource(Location.MARS, .875)];
    end
    
    %% private methods (incl. constructor)
    methods(Access = private)
    end
    
    %% public class methods
    methods
        %% class constructor
        function obj = FoodSource(location, amount)
            % verify we have correct type input
            if nargin > 0 && isa(location, 'Location') && ~isnan(amount) && ...
                amount >= 0 && amount <= 1
                % set the location of food
                obj.location = location;
                % set the amount of food
                obj.amount = amount;
            else
                error('Cannot create food source because of invalid inputs.');
            end
        end
        
        %% Location getter
        function loc = get.Location(obj)
            % verify we have correct inputs to get location
            if nargin > 0 & isa(obj,'FoodSource') & size(obj.location) > 0
                loc = obj.location;
            end
        end
        %% Amount getter
        function amt = get.Amount(obj)
            % verify we have correct inputs to get location
            if nargin > 0 & isa(obj,'FoodSource') & size(obj.location) > 0
                amt = obj.amount;
            end
        end
        %% Display
        function display(obj)
            obj.Location
            obj.Amount
        end
    end
end


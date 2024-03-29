%% this script calculates the distance between the centroid of each earthquake gate and the distance to the nearest neighbor gate in each side
 clear all; close all 
% per event: 
% step 1: load shapefiles
% step 2: select shapefiles for event
% step 3: get centroid of each shapefile (if length = 2 or 4, make fake middle
% point, if length = 3, second point) 

%% load shapefiles
shapefiles = dir('*.shp'); % access all shapefile names in the folder
shapefile_names = {};
shapefile_type = {};
shapefile_BU = {};
shapefile_event = {};


for n=1:numel(shapefiles)
    shapefile_namesi = shapefiles(n).name; 
    shapefile_names{n} = shapefile_namesi;
    
    % break down into string components
    name = strsplit(shapefile_namesi,{'_','.'}); % string containing shapefile name

    shapefile_type{n} = name{1};
    shapefile_BU{n} = name{2};
    shapefile_event{n} = name{3};
    
end

% create results table
results = table();

FDHI_data = readtable('data_FDHI.xlsx');
EQ = FDHI_data.eq_name;
[EQ,iEQ] = unique(EQ,'legacy'); 
type = FDHI_data.style(iEQ,:);
zone = FDHI_data.zone(iEQ,:);

locs = find(strcmp(type,'Strike-Slip'));
names = EQ(locs);
zone = zone(locs);

centroidx = [];
centroidy = [];

%% find centroids for each earthquake gate

for i = 1:numel(names) 
     namei = names(i);
     
    % deal with utm zone

    zonei = zone(i);
    zonei = zonei{1};
    %zonei = strsplit(zonei,{'_','.'}); % string containing shapefile name

if length(zonei) == 3
    zonei = cellstr(zonei')';
    zone_n = append(zonei{1},zonei{2});
    zone_n = str2double(zone_n); 
    hem = zonei{3};
    
elseif length(zonei) == 2
    zonei = cellstr(zonei')';
    zone_n = str2double(zonei{1}); 
    hem = zonei{2};
else
    error('Length of zone string must be 2 or 3 characters')
end
    
    % find shapefiles with same event name
    locname = find(strcmp(shapefile_event,namei));
    
    % create structure with shapefiles from same event
    lines= {};
    for n=1:length(locname)
        idn = locname(n);
        variablename = shapefiles(idn).name;
        nametest = strsplit(variablename,{'_','.'}); % string containing shapefile name
        if strcmp(nametest{2},'breached')
        lines{n} = shaperead(variablename);      
        else
            continue
        end
    end
    
    % compile all the centroids
    
    for n=1:length(lines)
        selected = lines{n};
        for p=1:length(selected)
            fault_x = selected(p).X;
            fault_y = selected(p).Y;
            fault_x = fault_x(~isnan(fault_x)); % removes NaN artifact at end of each fault in shapefile
            fault_y = fault_y(~isnan(fault_y)); 
            [fault_x, fault_y] = wgs2utm(fault_y,fault_x,zone_n,hem);
            if length(fault_x) == 4
                P1 = [fault_x(2), fault_y(2)];
                P2 = [fault_x(3), fault_x(3)];
                midpoint = (P1(:) + P2(:)).'/2;
                centroidxi = midpoint(1); 
                centroidyi = midpoint(2); 
            elseif length(fault_x) == 2
                P1 = [fault_x(1), fault_y(1)];
                P2 = [fault_x(2), fault_x(2)];
                midpoint = (P1(:) + P2(:)).'/2;
                centroidxi = midpoint(1); 
                centroidyi = midpoint(2);               
            else
                centroidxi = fault_x(2); 
                centroidyi = fault_y(2); 
            end
            
            centroidx = [centroidx; centroidxi];
            centroidy = [centroidy; centroidyi];

            %debugging 
            
            % differences = abs(culprit - centroidxi);
            % 
            %     for b=1:length(differences)
            %     if differences(b)<0.0001
            %         disp(selected(p))
            %     else 
            %     end
            % end
            
        end
        

    end
    end 

%%
    % for all centroids in event, find nearest neighbors
    
    dist= [];
    for c = 1:length(centroidx) 
        idxrem = find(centroidx == centroidx(c) & centroidy == centroidy(c));
        centroidsx_subset = centroidx(1:end ~= idxrem);
        centroidsy_subset = centroidy(1:end ~= idxrem);
        [k,dist(c)] = dsearchn([centroidsx_subset,centroidsy_subset],[centroidx(c), centroidy(c)]);

        if dist(c)>10^5
            disp(centroidx(c))
            disp(centroidy(c))
            culprit = centroidx(c);
        else
        end

    end

    figure
    histogram(dist,200,'FaceColor',[0.9294    0.6941    0.1255])
    xlabel('Distance to nearest neighbor breached gate (m)')
    ylabel('Frequency')
    set(gca,'FontSize',14)
  
   
%% ECDF
figure()
[F, X] = ecdf(dist);
plot(X, 1-F,'Color','k','linewidth',2);
xlabel('Distance to nearest neighbor (m)');
ylabel('1 - Cumulative Probability');
set(gca,'FontSize',14,'XScale','log')

% CDFs (log normal, exponential, and Weibull)
pd_lognormal = fitdist(dist', 'LogNormal');
pd_exponential = fitdist(dist', 'Exponential');
pd_weibull = fitdist(dist', 'Weibull');
x = linspace(min(dist),max(dist),10000);
fittedCDF_lognormal = cdf(pd_lognormal, x);
fittedCDF_exponential = cdf(pd_exponential, x);
fittedCDF_weibull = cdf(pd_weibull, x);
hold on;
plot(x, 1-fittedCDF_lognormal, 'Color',[0.8510    0.3255    0.0980], 'LineWidth', 2);  
plot(x, 1-fittedCDF_exponential, 'Color',[0.4667    0.6745    0.1882], 'LineWidth', 2);  
plot(x, 1-fittedCDF_weibull, 'Color',[0.9294    0.6941    0.1255], 'LineWidth', 2);  

legend('Empirical CDF', 'log-normal', 'exponential', 'Weibull');
xlim([0,100000])
% CDF gamma
% params = gamfit(dist');
% gamma_cdf = gamcdf(x, params(1), params(2)); % Use the estimated parameters
% gamma_cdf_plot = plot(x, 1-gamma_cdf, 'Color', 'b', 'LineWidth', 2);

saveas(gcf,'a_lognormal_exp_Weibull_CDF.pdf')


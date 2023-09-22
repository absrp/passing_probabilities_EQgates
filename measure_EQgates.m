%% this script takes in shapefiles of earthquake gates along surface ruptures in the FDHI
%% database and measures their geometrical attributes

% required inputs

% earthquake gate map shapefiles per event
% shapefile of ECS lines from FDHI database '_FDHI_FLATFILE_ECS_rev2.shp'
% info from FDHI appendix 'data_FDHI.xlsx'

% required functions (available from Mathworks in links below): 
% function wsg2utm (version 2) https://www.mathworks.com/matlabcentral/fileexchange/14804-wgs2utm-version-2
% function distance2curve https://www.mathworks.com/matlabcentral/fileexchange/34869-distance2curve#:~:text=Distance2curve%20allows%20you%20to%20specify,and%20the%20closest%20point%20identified.

clear; close all

% import FDHI data
FDHI_data = readtable('data_FDHI.xlsx');

% import shapefiles and extract information from all of them 
shapefiles = dir('*.shp'); % access all shapefile names in the folder

% create results table
all_results = table();

fault_x = [];
fault_y = [];

reflines_all = shaperead('_FDHI_FLATFILE_ECS_rev2.shp'); 

%%

for i=1:length(shapefiles)
% read shapefile
shapename = shapefiles(i).name;
maplines = shaperead(shapename); 

if isempty(maplines) 
    continue % skip for loop iteration if shapefile is empty
else 

name = strsplit(shapename,{'_','.'}); % string containing shapefile name

% extract info from shapefile name 

% feature type
shapefile_type = name{1};

% breached vs unbreached 
shapefile_subtype = name{2};
if strcmp(shapefile_subtype,'breached')
elseif strcmp(shapefile_subtype,'unbreached')
else
    error('Features must be breached or unbreached')
end

% earthquake name 
EQ_name= name{3};

if length(name) > 4
    EQ_name = append(name{3},'_',name{4});
else 
end

% find data associated with select earthquake
EQ_select = find(strcmp(FDHI_data.eq_name,EQ_name));
EQ_ID = FDHI_data.EQ_ID(EQ_select);

data = FDHI_data(EQ_select,:);
epicenter_xall = data.hypocenter_longitude_degrees;
epicenter_yall = data.hypocenter_latitude_degrees;
epicenter_x = epicenter_xall(1);
epicenter_y = epicenter_yall(1);


% find ECS lines for select earthquake
celllines = struct2cell(reflines_all)'; 
reflinesloc = find(cell2mat(celllines(:,5)) == EQ_ID(1)); 
reflines = reflines_all(reflinesloc);

%% measure length of maplines (i.e. gap and step-over length) from shapefile)
L_line = []; %create vector to store length data
measurement_type_line = {}; 

% measure the line or angle of each mapped feature (gap, step-over, bend splay)
data = FDHI_data(EQ_select,:);

% utm zone
zone = data.zone;
zone = zone{1};

if length(zone) == 3
    zone = cellstr(zone')';
    zone_n = append(zone{1},zone{2});
    zone_n = str2double(zone_n); 
    hem = zone{3};
    
elseif length(zone) == 2
    zone = cellstr(zone')';
    zone_n = str2double(zone{1}); 
    hem = zone{2};
else
    error('Length of zone string must be 2 or 3 characters')
end

% measure step-over width, gap length, and bend and splay angle
for n = 1:length(maplines) 
  [L_line(n),measurement_type_line{n}] =  measure_length_angle(maplines(n).X,maplines(n).Y,zone_n,hem,shapefile_type); 
  [fault_xi,fault_yi]= savecoords(maplines(n).X,maplines(n).Y,zone_n,hem);
  fault_x = [fault_x; fault_xi'];
  fault_y = [fault_y; fault_yi'];
end 

% save files as transtensional or compressional (based on identifier in
% shapefile)

mech_type = {};

for n = 1:length(maplines) 
    if isfield(maplines(n),'type')
        mech_type{n} = maplines(n).type; 
    else 
        mech_type{n} = 'NaN';
    end 
end

for p = 1:length(mech_type)
    if strcmp(mech_type{p},'''T''')
     mech_type{p} = 'releasing';
    elseif strcmp(mech_type{p},'''C''')
     mech_type{p} = 'restraining';
    else 
    end
end 

distance = [];
type_bend = {};
spacing = [];

% save double bend arm distance and step-over proxy distance

for n = 1:length(maplines) 
    if isfield(maplines(n),'distance')
        distance(n) = maplines(n).distance; 
        type_bend{n} = 'NaN'; 
        spacing(n) = 0;
        
   elseif strcmp(shapefile_type,'bend')
   for n = 1:length(maplines) 
       
    [distance(n),type_bend{n}] =  measure_length(maplines(n).X,maplines(n).Y,zone_n,hem);
    spacing(n) = measure_length_stepover_bend(maplines(n).X,maplines(n).Y,zone_n,hem);
    
    if strcmp(type_bend{n},'single')
        mech_type{n} = 'NaN';
        spacing(n) = 0;
    else 
    end 
    
   end       
    
    else
        distance(n) = 0;
        type_bend{n} = 'NaN'; 
        spacing(n) = 0;
    end 
end

xcheck = [];
ycheck = [];
latcheck = [];
loncheck = [];

for n=1:length(maplines)
    [xchecki, ychecki] = wgs2utm(maplines(n).Y,maplines(n).X,zone_n,hem);
    xcheck(n) = xchecki(1); 
    ycheck(n) = ychecki(1);
    latcheck(n) = maplines(n).Y(1); 
    loncheck(n) = maplines(n).X(1); 
end 

dimcheck = size(maplines);
dimcheck = dimcheck(:,1); 

%% location of gate along rupture (referenced to ECS files in FDHI database)

loc_along = [];
normalized_loc_along = [];
total_rupturelength = [];

for n = 1:length(maplines)
   [total_rupturelengthi,loc_alongi,normalized_loc_alongi] = measure_location_along_rupture(maplines(n).X,maplines(n).Y,reflines.X,reflines.Y,zone_n,hem);
    loc_along = [loc_along; loc_alongi];
    normalized_loc_along = [normalized_loc_along; normalized_loc_alongi];
    total_rupturelength = [total_rupturelength; total_rupturelengthi];
end 

distance_to_epicenter = [];

for n = 1:length(maplines)
   [distance_to_epicenteri] = measure_distance_to_epicenter(maplines(n).X,maplines(n).Y,epicenter_x,epicenter_y,zone_n,hem);
    distance_to_epicenter = [distance_to_epicenter; distance_to_epicenteri];
end 

%% extract info from the nearest data point near the step-over from the FDHI database
% subset section of the FDHI for desired earthquake

SRL_data = readtable('cumulative_displacements.xlsx'); 
eventSRL = SRL_data.Event;

idxSRL = find(strcmp(eventSRL,EQ_name));
if isempty(idxSRL)
    disp(EQ_name)
    error('Earthquake name not in SRL database')
else 
end


Cumdisp = SRL_data.CumulativeDisplacement_km_(idxSRL); 
slip = data.fps_central_meters;
magnitude = data.magnitude;
fault_zone_width = data.fzw_central_meters;
lithology = data.geology;
coordsx = data.longitude_degrees;
coordsy = data.latitude_degrees; 
date = data.eq_date;
hypo_lat = data.hypocenter_latitude_degrees;
hypo_lon = data.hypocenter_longitude_degrees;
EQ_style = data.style;
zone = data.zone;
zone = zone{1};

%% write data to table

allresults_i = table(...
    repelem(EQ_ID(1),dimcheck)', ...
    repelem(string(EQ_name),dimcheck)',...
    repelem(date(1),dimcheck)', ...
    repelem(magnitude(1),dimcheck)', ...
    repelem(Cumdisp,dimcheck)',...
    repelem(EQ_style(1),dimcheck)',...
    repelem(hypo_lat(1),dimcheck)',...
    repelem(hypo_lon(1),dimcheck)',...
    repelem(string(shapefile_type),dimcheck)',...
    repelem(string(shapefile_subtype),dimcheck)',...
    string(mech_type)',...
    string(type_bend)',...
    distance',...
    L_line',...
    spacing',...
    measurement_type_line',...
    loc_along,...
    total_rupturelength,...
    normalized_loc_along,...
    distance_to_epicenter,...
    xcheck',...
    ycheck',...
    repelem(string(zone),dimcheck)',...
    latcheck',...
    loncheck');

all_results = [all_results; allresults_i];

%disp(i); % keeps track of progress
end
end


%% export results

% assign header to table
all_results.Properties.VariableNames = {'FDHI ID',...
    'Earthquake',...
    'Date',...
    'Magnitude',...
    'Cumulative displacement',...
    'Style',...
    'Hypocenter lat',...
    'Hypocenter lon',...
    'Feature',...
    'Breached or unbreached',...
    'Type (releasing or restraining)',...
    'Type (single or double)',...
    'Distance splay or double bend (m)',...
    'Length (m) or angle (deg)',...
    'Spacing double bend (m)',...
    'Type (length or angle)',...
    'Location along rupture',...
    'Total rupture length',...
    'Normalized location',...
    'Distance to epicenter',...
    'x1check',...
    'y1check',...
    'UTM zone',...
    'latcheck',...
    'loncheck'};

% export file as csv 
writetable(all_results,'EQgate_geometries.csv'); 

%% function dumpster
% functions that are called in the script go here 
function [fault_x,fault_y] = savecoords(fault_x,fault_y,zone,hem)
fault_x = fault_x(~isnan(fault_x)); % removes NaN artifact at end of each fault in shapefile
fault_y =fault_y(~isnan(fault_y));
if fault_y<90
[fault_x,fault_y]=wgs2utm(fault_y,fault_x,zone,hem);
else
end
end
function [L,measurement_type_line] = measure_length_angle(fault_x,fault_y,zone,hem,shapefile_type)
fault_x = fault_x(~isnan(fault_x)); % removes NaN artifact at end of each fault in shapefile
fault_y =fault_y(~isnan(fault_y));
if fault_y<90
[fault_x,fault_y]=wgs2utm(fault_y,fault_x,zone,hem);
else
end

% measure angle or length depending on shapefile type 

if strcmp(shapefile_type,'splay') % check if shapefile type is a splay
% measure angle between maplines
v1=[fault_x(1),fault_y(1)]-[fault_x(2),fault_y(2)];
v2=[fault_x(end),fault_y(end)]-[fault_x(2),fault_y(2)];
L=acos(sum(v1.*v2)/(norm(v1)*norm(v2)));
L = rad2deg(L);
measurement_type_line = 'angle';

elseif strcmp(shapefile_type,'bend') % check if shapefile type is a bend
    if length(fault_x) == 3
    % measure angle between maplines
        v1=[fault_x(2),fault_y(2)]-[fault_x(1),fault_y(1)];
        v2=[fault_x(end),fault_y(end)]-[fault_x(2),fault_y(2)];
        L=acos(sum(v1.*v2)/(norm(v1)*norm(v2)));
        L = rad2deg(L);
        measurement_type_line = 'angle'; % single bend

    elseif length(fault_x) == 4
        v1=[fault_x(2),fault_y(2)]-[fault_x(1),fault_y(1)];
        v2=[fault_x(3),fault_y(3)]-[fault_x(2),fault_y(2)];
        L=acos(sum(v1.*v2)/(norm(v1)*norm(v2)));
        L = rad2deg(L);
        measurement_type_line = 'angle'; % double bend
        
    else 
    error('Bends must contain three or four x,y coordinate pairs')
    end
        
elseif strcmp(shapefile_type,'stepover') % check if shapefile type is a step-over
% calculate length
x_1 = fault_x(1:end-1);
x_2 = fault_x(2:end);
y_1 = fault_y(1:end-1);
y_2 = fault_y(2:end);
segment_length = sqrt((x_1-x_2).^2+(y_1-y_2).^2); % note transformation to local coordinate system 
L = sum(segment_length);
measurement_type_line = 'length';

elseif strcmp(shapefile_type,'strand') % check if shapefile type is a step-over
% calculate length
x_1 = fault_x(1:end-1);
x_2 = fault_x(2:end);
y_1 = fault_y(1:end-1);
y_2 = fault_y(2:end);
segment_length = sqrt((x_1-x_2).^2+(y_1-y_2).^2); % note transformation to local coordinate system 
L = sum(segment_length);
measurement_type_line = 'length';

elseif strcmp(shapefile_type,'gap')  % check if shapefile type is a gap
% calculate length
x_1 = fault_x(1:end-1);
x_2 = fault_x(2:end);
y_1 = fault_y(1:end-1);
y_2 = fault_y(2:end);
segment_length = sqrt((x_1-x_2).^2+(y_1-y_2).^2); % note transformation to local coordinate system 
L = sum(segment_length);
measurement_type_line = 'length';

else
    error('ERROR: Shapefile type must be splay, gap, bend, or step-over (stepover)')
end 
end 
function [distance,bend_type] = measure_length(fault_x,fault_y,zone,hem)
fault_x = fault_x(~isnan(fault_x)); % removes NaN artifact at end of each fault in shapefile
fault_y =fault_y(~isnan(fault_y));
if fault_y<90
[fault_x,fault_y]=wgs2utm(fault_y,fault_x,zone,hem);
else
end
if length(fault_x) == 4
        segment_length = sqrt((fault_x(2)-fault_x(3)).^2+(fault_y(2)-fault_y(3)).^2); % note transformation to local coordinate system 
        distance = sum(segment_length);
        bend_type = 'double';
else
    distance = 0;
    bend_type = 'single';
end

end 
function [spacing] = measure_length_stepover_bend(fault_x,fault_y,zone,hem)
fault_x = fault_x(~isnan(fault_x)); % removes NaN artifact at end of each fault in shapefile
fault_y =fault_y(~isnan(fault_y));

if fault_y<90
[fault_x,fault_y]=wgs2utm(fault_y,fault_x,zone,hem);
else
end

if length(fault_x) == 4
    
        v1=[fault_x(2),fault_y(2)]-[fault_x(1),fault_y(1)];
        v2=[fault_x(3),fault_y(3)]-[fault_x(2),fault_y(2)];
        L = acos(sum(v1.*v2)/(norm(v1)*norm(v2)));
        angle = rad2deg(L);
        
        segment_length = sqrt((fault_x(2)-fault_x(3)).^2+(fault_y(2)-fault_y(3)).^2); % note transformation to local coordinate system 
        hypothenuse = sum(segment_length);
        
        % calculate step-over spacing for bend
        spacing = sind(angle)*hypothenuse; 
        
        
else
    spacing = 0;
end

end 
function [total_rupturelength,loc_along,normalized_loc_along] = measure_location_along_rupture(fault_x,fault_y,refline_x,refline_y,zone,hem)

fault_x = fault_x(~isnan(fault_x)); % removes NaN artifact at end of each fault in shapefile
fault_y = fault_y(~isnan(fault_y));
refline_x = refline_x(~isnan(refline_x));
refline_y = refline_y(~isnan(refline_y));

[coords_gatex, coordsgatey] = wgs2utm(fault_y(1),fault_x(1),zone,hem);
coords_gate = [coords_gatex' coordsgatey'];

[curvexy_x, curvexy_y] = wgs2utm(refline_y,refline_x,zone,hem);
curvexy = [curvexy_x' curvexy_y'];

% total length
x_1 = curvexy_x(1:end-1);
x_2 = curvexy_x(2:end);
y_1 = curvexy_y(1:end-1);
y_2 = curvexy_y(2:end);
segment = sqrt((x_1-x_2).^2+(y_1-y_2).^2); % note transformation to local coordinate system 
total_rupturelength = sum(segment);

spacing = 100; % discretizing rupture into 100 m spaced increments
pt = interparc(0:(spacing/total_rupturelength):1,curvexy_x,curvexy_y,'linear'); 
pt_x = pt(:,1);
pt_y = pt(:,2);
curvexy_dense = [pt_x pt_y];

[xy,~,~] = distance2curve(curvexy,coords_gate,'spline'); % find minimum distance between gate and ECS trace
locpt = dsearchn(curvexy_dense,xy);

% segment length
x_1 = pt_x(1:locpt-1);
x_2 = pt_x(2:locpt);
y_1 = pt_y(1:locpt-1);
y_2 =  pt_y(2:locpt);
segment = sqrt((x_1-x_2).^2+(y_1-y_2).^2); 
loc_along= sum(segment);

normalized_loc_along = loc_along/total_rupturelength; 
end
function [distance_to_epi] = measure_distance_to_epicenter(fault_x,fault_y,epi_x,epi_y,zone,hem)
fault_x = fault_x(~isnan(fault_x)); % removes NaN artifact at end of each fault in shapefile
fault_y = fault_y(~isnan(fault_y));

% hold on
% scatter(fault_x,fault_y,'b')
% scatter(epi_x,epi_y,'r')
% 

[coords_gatex, coordsgatey] = wgs2utm(fault_y(1),fault_x(1),zone,hem);
coords_gate = [coords_gatex' coordsgatey'];

[hypoxy_x, hypoxy_y] = wgs2utm(epi_y,epi_x,zone,hem);
hypoxy = [hypoxy_x' hypoxy_y'];


[~,distance_to_epi] = dsearchn(hypoxy,coords_gate); % find minimum distance between gate and epicenter

end 
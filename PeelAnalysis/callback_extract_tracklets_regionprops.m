% This code is part of the MATLAB toolbox Gait-CAD.
% Copyright (C) 2012 [Johannes Stegmaier, Ralf Mikut]
%
%
% Last file change: 22-Okt-2012 16:27:00
%
% This program is free software; you can redistribute it and/or modify,
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or any later version.
%
% This program is distributed in the hope that it will be useful, but
% WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General gaitPublic License for more details.
%
% You should have received a copy of the GNU General Public License along with this program;
% if not, write to the Free Software Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110, USA.
%
% You will find further information about Gait-CAD in the manual or in the following conference paper:
%
% STEGMAIER,J.;ALSHUT,R.;REISCHL,M.;MIKUT,R.: Information Fusion of Image Analysis, Video Object Tracking, and Data Mining of Biological Images using the Open Source MATLAB Toolbox Gait-CAD.
% In:  Proc., DGBMT-Workshop Biosignal processing, Jena, 2012, pp. 109-111; 2012
% Online available: http://www.degruyter.com/view/j/bmte.2012.57.issue-s1-B/bmt-2012-4073/bmt-2012-4073.xml
%
% Please refer to this paper, if you use Gait-CAD with the ImVid extension for your scientific work.

tracklets = [];
trackletsPerTimePoint = struct();
for i=1:size(d_orgs,2)
    trackletsPerTimePoint(i).tracklets = [];
end

%% select features
try
    %set_textauswahl_listbox(gaitfindobj('CE_Auswahl_ZR'),{'xpos','ypos','zpos'});eval(gaitfindobj_callback('CE_Auswahl_ZR'));
    positionIndices = 3:5;
    %set_textauswahl_listbox(gaitfindobj('CE_Auswahl_ZR'),{'Tracking state'});eval(gaitfindobj_callback('CE_Auswahl_ZR'));
    trackingStateIndex = size(d_orgs,3);
    
    %% display status message
    disp( 'Extracting all existing tracklets ...' )
    
    %% extract the tracklets with tracks being arranged in the same rows
    minLength = 1;
    useRowExtraction = true;
    trackletIndex = 1;
    if (useRowExtraction == true)
        for i=1:size(d_orgs,1)
            
            %% get the current row
            currentData = squeeze(d_orgs(i,:,[positionIndices,trackingStateIndex]));
            trackingLosses = [0;find(currentData(:,4) == 0)];
            
            for j=1:(size(trackingLosses,1)-1)
                
                if trackingLosses(j+1)-trackingLosses(j) > 1 
                    startTime = trackingLosses(j)+1;
                    endTime = trackingLosses(j+1)-1;
                    
%                     if (j==1 && trackingLosses(1) > 1)
%                         startTime = 1;
%                         endTime = trackingLosses(j);
%                     end
                    
                    if ((endTime - startTime + 1) < minLength)
                        continue;
                    end
                    
                    %% extract the tracklet information
                    tracklets(trackletIndex).id = trackletIndex;
                    tracklets(trackletIndex).startTime = startTime;
                    tracklets(trackletIndex).endTime = endTime;
                    tracklets(trackletIndex).ids = i*ones(size(startTime:endTime));
                    tracklets(trackletIndex).pos(:,1) = currentData(startTime:endTime,1);
                    tracklets(trackletIndex).pos(:,2) = currentData(startTime:endTime,2);
                    tracklets(trackletIndex).pos(:,3) = currentData(startTime:endTime,3);
                    tracklets(trackletIndex).successorIndices = [0,0];
                    tracklets(trackletIndex).successorDistances = [0,0];
                    tracklets(trackletIndex).predecessorIndex = 0;
                    tracklets(trackletIndex).predecessorDistance = 0;
                    tracklets(trackletIndex).color = [rand(), rand(), rand()];
                    
                    for k=startTime:endTime
                        trackletsPerTimePoint(k).tracklets = [trackletsPerTimePoint(k).tracklets,trackletIndex];
                    end
                    
                    trackletIndex = trackletIndex+1;
                end
            end
            
            %% plot progress
            if (mod(i,1000) == 0)
                disp( sprintf( '%f%% processed ...', 100*i/size(d_orgs,1)) )
            end
        end
    else
        %% TODO: extract tracklets for IMM representation with unchanged rows
    end
    
    disp(['All tracklets have been extracted successfully.']);
catch
    %% throw error if selection failed
    disp('ERROR: Please perform tracking first. It is assumed that the time series ''xpos'', ''ypos'', ''zpos'' as well as ''Tracking state'' exist.');
end
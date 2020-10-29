%%
% CellShapeAnalysis.
% Copyright (C) 2020 J. Stegmaier
%
% Licensed under the Apache License, Version 2.0 (the "License");
% you may not use this file except in compliance with the License.
% You may obtain a copy of the License at
% 
%     http://www.apache.org/licenses/LICENSE-2.0
% 
% Unless required by applicable law or agreed to in writing, software
% distributed under the License is distributed on an "AS IS" BASIS,
% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
% See the License for the specific language governing permissions and
% limitations under the License.
%
% Please refer to the documentation for more information about the software
% as well as for installation instructions.
%
% If you use this application for your work, please cite the repository and one
% of the following publications:
%
% Bhide, S., Mikut, R., Leptin, M., Stegmaier, J., Semi-Automatic Generation 
% of Tight Binary Masks and Non-Convex Isosurfaces for Quantitative Analysis 
% of 3D Biological Samples, In Proceedings of the IEEE International 
% Conference on Image Processing, 2020.
%
%%

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
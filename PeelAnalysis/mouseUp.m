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

function mouseUp(~, ~)

    %% get global variables
    global settings;

    %% get current modifier keys
    modifiers = get(gcf,'currentModifier');        %(Use an actual figure number if known)
    shiftPressed = ismember('shift',modifiers);
    ctrlPressed = ismember('control',modifiers);
    %altPressed = ismember('alt',modifiers);
    %currentButton = get(gcbf, 'SelectionType');
    clickPosition = get(gca, 'currentpoint');
    clickPosition = round([clickPosition(1,1), clickPosition(1,2)]);

    %% add the click point as a positive or negative coexpression point including mean intensity calculations
    if (ctrlPressed == true)
        settings.currentSeeds = [settings.currentSeeds; clickPosition];
        settings.currentSeedImage(clickPosition(2), clickPosition(1)) = 1;
    elseif (shiftPressed == true)
        minDist = inf;
        minIndex = 1;    
        for i=1:size(settings.currentSeeds, 1)
            distance = sqrt(sum((settings.currentSeeds(i,:) - clickPosition).^2));

            if (distance < minDist)
                minDist = distance;
                minIndex = i;
            end
        end

        if (minDist < settings.deletionRadius)
            settings.currentSeedImage(settings.currentSeeds(minIndex,2), settings.currentSeeds(minIndex,1)) = 0;
            settings.currentSeeds(minIndex,:) = [];
        end
    end

    %% update the visualization
    updateVisualization;
end
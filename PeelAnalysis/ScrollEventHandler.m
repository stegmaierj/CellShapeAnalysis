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

%% scroll event handler
function ScrollEventHandler(src,evnt)
    global settings;

    %% get the modifier keys
    modifiers = get(gcf,'currentModifier');        %(Use an actual figure number if known)
    shiftPressed = ismember('shift',modifiers);
    ctrlPressed = ismember('control',modifiers);
    altPressed = ismember('alt',modifiers);
    
    %% if control pressed increase/decrease the gfp contrast
    if (ctrlPressed == true)

        
    %% if alt pressed increase/decrease the rfp contrast
    elseif (altPressed == true)

    elseif (shiftPressed == true)
 
        
    %% if no modifier is pressed perform scrolling through the stack
    else

    end
    
    %% finally update the visualization
	updateVisualization;
end
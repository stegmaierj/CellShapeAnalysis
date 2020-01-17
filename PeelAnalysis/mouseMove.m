%%
 % CellShapeAnalysis.
 % Copyright (C) 2020 S. Bhide, J. Stegmaier
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
 % Bhide, S., Leptin, M., Stegmaier, J., Semi-Automatic Generation of Tight 
 % Binary Masks and Non-Convex Isosurfaces for Quantitative Analysis of 
 % Drosophila Gastrulation, in preparation, 2020.
 %
 %%

function mouseMove(~, ~)
    global settings;
    currentPosition = get(gca, 'currentpoint');
    currentPosition = round([currentPosition(1,1), currentPosition(1,2)]);
    
    if (~isempty(settings.crossHairVAxis1))
        set(settings.crossHairVAxis1, 'XData', [1,1] * currentPosition(1));
        set(settings.crossHairVAxis1, 'visible', 'on');
    end
    if (~isempty(settings.crossHairHAxis1))
        if (currentPosition(2) > size(settings.currentImage,1))
            set(settings.crossHairHAxis1, 'YData', [1,1] * (currentPosition(2) - size(settings.currentImage,1)));
        else
            set(settings.crossHairHAxis1, 'YData', [1,1] * (currentPosition(2)));
        end
        set(settings.crossHairHAxis1, 'visible', 'on');
    end
    if (~isempty(settings.crossHairVAxis1))
        set(settings.crossHairVAxis2, 'XData', [1,1] * currentPosition(1));
        set(settings.crossHairVAxis2, 'visible', 'on');
    end
    if (~isempty(settings.crossHairVAxis1))
        if (currentPosition(2) > size(settings.currentImage,1))
            set(settings.crossHairHAxis2, 'YData', [1,1] * (currentPosition(2)) - size(settings.currentImage,1));
        else
            set(settings.crossHairHAxis2, 'YData', [1,1] * (currentPosition(2)));
        end
        set(settings.crossHairHAxis2, 'visible', 'on');
    end
end
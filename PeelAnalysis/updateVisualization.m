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
 
%% load the global settings
global settings;

%% filter the current image before performing the watershed
filteredImage = imgaussfilt(settings.currentImage, 1);

%% perform seeded watershed with the current detections
settings.watershedImage = watershed(imimposemin(filteredImage, settings.currentSeedImage));
%settings.watershedImage = watershed(imgaussfilt(settings.currentImage, 1));

%% visualize wither the smoothed or the raw image
if (settings.smoothingEnabled == false)
    redChannel = settings.currentImage;
    redChannel(settings.watershedImage == 0) = 255;
    blueChannel = settings.currentImage;
    blueChannel(settings.watershedImage == 0) = 0;
    settings.currentResultImage = cat(3, redChannel, blueChannel, blueChannel);
else
    redChannel = filteredImage;
    redChannel(settings.watershedImage == 0) = 255;
    blueChannel = filteredImage;
    blueChannel(settings.watershedImage == 0) = 0;
    settings.currentResultImage = cat(3, redChannel, blueChannel, blueChannel);
end

%% plot the raw image with superimposed detections
figure(settings.mainFigure); clf; hold on;
subplot(2,1,1);
cla; hold on;
if (settings.smoothingEnabled == false)
    settings.imageHandle = imagesc(settings.currentImage);
else
    settings.imageHandle = imagesc(filteredImage);
end
if (~isempty(settings.currentSeeds))
    plot(settings.currentSeeds(:,1), settings.currentSeeds(:,2), '.m');
    plot(settings.currentSeeds(:,1), settings.currentSeeds(:,2), 'oc');
end

%% plot the crosshair for easier localization in both views
if (settings.crossHairEnabled == true)
    currentPosition = get(gcf, 'CurrentPoint');
    disp(currentPosition);
    settings.crossHairVAxis1 = plot([1,1], [1,size(settings.currentImage,1)], '-g', 'LineWidth', 2);
    settings.crossHairHAxis1 = plot([1,size(settings.currentImage,2)], [1,1], '-g', 'LineWidth', 2);
    set(settings.crossHairVAxis1, 'visible', 'off');
    set(settings.crossHairHAxis1, 'visible', 'off');
else
    settings.crossHairVAxis1 = [];
    settings.crossHairHAxis1 = [];
end

%% setup visualization properties
axis tight;
colormap gray;
set(gca, 'Units', 'normalized', 'Position', [0, 0.5, 1.0, 0.5]);
text('String', ['H-Maximum Height: ' num2str(settings.hminimaHeight)], 'FontSize', settings.fontSize, 'Color', 'white', 'Units', 'normalized', 'Position', [0.01 0.98]);

%% plot the current segmentation results
subplot(2,1,2);
cla; hold on;
imagesc(settings.currentResultImage);
if (~isempty(settings.currentSeeds))
    plot(settings.currentSeeds(:,1), settings.currentSeeds(:,2), '.m');
    plot(settings.currentSeeds(:,1), settings.currentSeeds(:,2), 'oc');
end

%% plot crosshair for better detection localization
if (settings.crossHairEnabled == true)
    currentPosition = get(gcf, 'CurrentPoint');
    disp(currentPosition);
    settings.crossHairVAxis2 = plot([1, 1], [1,size(settings.currentImage,1)], '-g', 'LineWidth', 2);
    settings.crossHairHAxis2 = plot([1,size(settings.currentImage,2)], [1,1], '-g', 'LineWidth', 2);
    set(settings.crossHairVAxis2, 'visible', 'off');
    set(settings.crossHairHAxis2, 'visible', 'off');
else
    settings.crossHairVAxis2 = [];
    settings.crossHairHAxis2 = [];
end

set(gca, 'Units', 'normalized', 'Position', [0, 0, 1.0, 0.5]);
axis tight;
colormap gray;
set(settings.mainFigure, 'Name', settings.inputImages{settings.currentImageIndex},'NumberTitle','off');

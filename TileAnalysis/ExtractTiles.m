%%
 % CellShapeAnalysis.
 % Copyright (C) 2019 S. Bhide, J. Stegmaier
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
 % Bhide *et al.*, Cell Shape Changes during *Drosophila* Gastrulation, *in preparation*.
 %
 %%

%% add scripts for 3D tiff io
addpath('../ThirdParty/saveastiff_4.3/');

%% specify the paths for input 
inputPathRaw = 'V:\BiomedicalImageAnalysis\MembraneSegmentation_BhideEMBL\2019_05_13\SmallVolume\Raw\';
inputPathRawMontage = 'V:\BiomedicalImageAnalysis\MembraneSegmentation_BhideEMBL\2019_05_13\SmallVolume\montage.tif';
inputPathImage = 'V:\BiomedicalImageAnalysis\MembraneSegmentation_BhideEMBL\2019_05_13\SmallVolume\2019_07_18_ManualAnnotations.tif';
inputPathRanges = 'V:\BiomedicalImageAnalysis\MembraneSegmentation_BhideEMBL\2019_05_13\SmallVolume\montage_ranges.mat';
outputPath = 'V:\BiomedicalImageAnalysis\MembraneSegmentation_BhideEMBL\2019_05_13\SmallVolume\Segmentation\';
mkdir(outputPath);
inputFiles = dir([inputPathRaw '*.tif']);

numTiles = length(rangeX);

rawImageMask = loadtiff(inputPathRawMontage) > 0;
resultImage = uint16(loadtiff(inputPathImage) .* uint8(rawImageMask));

for i=1:numTiles
   currentTile = resultImage(rangeX{i}, rangeY{i}, rangeZ{i});
   
   
   distanceImage = uint16(imclose((currentTile > 0), strel('cube', 2)));
      
   clear options;
   options.overwrite = true;
   options.compress = 'lzw';
   saveastiff(distanceImage, [outputPath strrep(inputFiles(i).name, '.tif', '_Segmentation.tif')], options);
end


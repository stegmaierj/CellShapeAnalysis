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
 
%% the help dialog containing all commands
helpText = {'Shift + Left Button: Delete detection closest to the cursor', ...
            'CTRL + Left Button: Add detection at the cursor position', ...
            'Left Arrow: Load previous image', ...
            'Right Arrow: Load next image', ...
            '-/+: Decrease/increase the the minimum region size (smaller values to compensate under-segmentation, larger values compensate over-segmentation)', ...
            'A: Perform automatic seed detection (previous results for this image will be overwritten)', ...
            'C: Toggles visibility of the cross-hair cursor', ...
            'D: Freehand deletion of detections. Press D and mark a region using the mouse with the left button pressed', ...
            'E: Export segmentation images and perform tracking', ...
            'F: Toggles smooth vs. raw image for visualization', ...
            'G: Apply current parameters for all images (for initialization)', ...
            'H: Show this help dialog', ...
            '', ...
            'Hint: In case key presses show no effect, left click once on the image and try hitting the button again. This only happens if the window looses the focus. Segmentation results are automatically saved as soon as the next image is loaded or upon closing the application.'};

helpdlg(helpText);
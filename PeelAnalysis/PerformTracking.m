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

%% show wait bar 
waitBarHandle = waitbar(0,'Generating tracking results ...');
frames = java.awt.Frame.getFrames();
frames(end).setAlwaysOnTop(1);
    
%% perform the tracking if there are more than 1 frames
if (size(d_orgs, 2) > 1)
    par.anz_dat = size(d_orgs,1);
    par.anz_merk = size(d_orgs,3);

    %% set maximum allowed distance and track the cells
    parameter.gui.tracking.zscale = 1;
    parameter.gui.tracking.max_distance = 100;
    parameter.gui.tracking.maxDist = 100;
    parameter.gui.tracking.add_missing_nucleus = false;
    parameter.gui.tracking.velocity_correction = false;

    %% call the SciXMiner Tracking routines
    callback_tracking_regionprops;
    callback_extract_tracklets_regionprops;

    %% save the project as scixminer project
    save([outputFolder filesep file '_SciXMiner.prjz'], '-mat', 'd_orgs', 'code', 'var_bez');

    %% save the tracklets. Using -v7.3 is neccessary for larger file sizes
    save([outputFolder filesep file '_SciXMiner.tracklets'], '-mat', '-v7', 'tracklets', 'trackletsPerTimePoint');

    %% extract tracked lengths
    lengths = [];
    for i=1:length(tracklets)
        lengths = [lengths; length(tracklets(i).ids)];
    end

    %% initialize result tables
    sortedIndices = 1:length(tracklets);
    eccentricityTable = zeros(length(tracklets), size(d_orgs,2));
    areaTable = zeros(length(tracklets), size(d_orgs,2));
    speedTable = zeros(length(tracklets), size(d_orgs,2));

    %% compute features for each of the tracklets
    currentLine = 1;
    for i=sortedIndices
        currentTracklet = tracklets(i);
        currentArea = d_orgs(currentTracklet.ids(1), currentTracklet.startTime:currentTracklet.endTime, 2);
        currentEccentricity = d_orgs(currentTracklet.ids(1), currentTracklet.startTime:currentTracklet.endTime, 10);

        range1 = currentTracklet.startTime:currentTracklet.endTime;
        range1 = range1(1:end-1);
        range2 = 1+(currentTracklet.startTime:currentTracklet.endTime);
        range2 = range2(1:end-1);
        if (length(range1) == 1)
            currentSpeed = sqrt(sum(squeeze(d_orgs(currentTracklet.ids(1), range2, 3:4) - d_orgs(currentTracklet.ids(1), range1, 3:4))'.^2, 2));
        else
            currentSpeed = sqrt(sum(squeeze(d_orgs(currentTracklet.ids(1), range2, 3:4) - d_orgs(currentTracklet.ids(1), range1, 3:4)).^2, 2));
        end
        currentSpeed(end+1) = 0;

        areaTable(currentLine, currentTracklet.startTime:currentTracklet.endTime) = currentArea;
        eccentricityTable(currentLine, currentTracklet.startTime:currentTracklet.endTime) = currentEccentricity;
        speedTable(currentLine, currentTracklet.startTime:currentTracklet.endTime) = currentSpeed;
        currentLine = currentLine+1;
    end
    
    %% update the wait bar
    waitbar(0.1);

    %% write the csv results
    dlmwrite([outputFolder filesep 'Tracking' filesep 'area.csv'], areaTable, ';');
    dlmwrite([outputFolder filesep 'Tracking' filesep 'eccentricity.csv'], eccentricityTable, ';');
    dlmwrite([outputFolder filesep 'Tracking' filesep 'speed.csv'], speedTable, ';');

    %% update the wait bar
    waitbar(0.2);
    
    %% write the result video
    v = VideoWriter([outputFolder filesep 'Tracking' filesep 'trackingVideo.avi']);
    v.FrameRate = 10; 
    open(v);
    
    %% loop through all frames and plot video
    fh = figure(2);
    set(fh, 'Position', get(0,'Screensize'), 'Color', [0,0,0]); colormap gray;
    for i=1:size(d_orgs,2)
        
        %% draw the image
        fh = figure(2);
        currentImage = (imread(settings.inputImages{i}));
        imagesc(currentImage); 
        
        %% setup axes properties
        hold on;        
        axis equal;
        set(gca, 'Color', [0,0,0])
        axis off
        axis tight
        
        %% plot the tracklets and the track id
        for j=1:length(trackletsPerTimePoint(i).tracklets)
            currentTracklet = tracklets(trackletsPerTimePoint(i).tracklets(j));
            currentPosition = d_orgs(currentTracklet.ids(1), i, 3:5);
            plot(currentPosition(1), currentPosition(2), '.r');
            plot(d_orgs(currentTracklet.ids(1), currentTracklet.startTime:i, 3), d_orgs(currentTracklet.ids(1), currentTracklet.startTime:i, 4), '-r');
            text(currentPosition(1)+2, currentPosition(2), num2str(currentTracklet.id));
        end
        
        %% save the current frame to the video
        myframe = getframe(fh);
        writeVideo(v, frame2im(myframe));
        
        hold off;
        drawnow;
        
        %% update the wait bar
        waitbar(0.2 + 0.8*(i/size(d_orgs,2)));
    end
    close(waitBarHandle);
    close(v);
    close(fh);
end
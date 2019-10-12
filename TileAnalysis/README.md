Scripts for extracting apical area, basal area and volumes of temporally resolved label images. Cells are tracked from the first to the last provided frame by linking the maximally overlapping objects from frame to frame. Objects touching the boundary are removed and only cells spanning the entire time interval are considered.


Tile Analysis:
--------------
- Execute the script called *TrackTiles.m* and select the input folder containing segmentation label images where each cell has a unique integer ID assigned.
- Contained objects are automatically tracked from frame to frame to be able to analyze temporal changes of the extracted features.
- The script computes the apical area and basal area by first extracting the voxels of each object that touch the surface and then projecting the extracted voxels to a plane. Output is stored as MATLAB figures and as CSV files for further processing and analysis.


Auxiliary Tools:
----------------
- *EmbedTiles.m*: Script to embed multiple small tiles into a single 3D stack that can be uploaded to Segment3D, an interactive tool for manual 3D segmentation.
- *ExtractTiles.m*: Script to undo the embedding in order to analyze the results of individual files separately.
- *PostProcessingPipeline.\**: XPIWIT Pipeline for post-processing to convert a binary boundary map as obtained from Segment3D to a dense label image. A binary version and the sources of XPIWIT including instructions on how to load and apply predefined pipelines can be obtained from https://www.bitbucket.org/jstegmaier/XPIWIT/ .
- Note: The auxiliary tools can entirely be skipped, if the dense label images are obtained from a different source.
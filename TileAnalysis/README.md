Scripts for extracting apical area, basal area and volumes of temporally resolved label images. Cells are tracked from the first to the last provided frame by linking the maximally overlapping objects from frame to frame. Objects touching the boundary are removed and only cells spanning the entire time interval are considered.


Tile Analysis:
--------------
- Execute the script called *TrackTiles.m* and select the input folder containing segmentation label images where each cell has a unique integer ID assigned.
- Contained objects are automatically tracked from frame to frame to be able to analyze temporal changes of the extracted features separately for each cell (note that cell divisions are not considered!).
- The script computes the apical area and basal area by first extracting the voxels of each object that touch the apical and the basal surface, respectively, and by subsequently projecting the extracted voxels to a plane spanned by the first two principal components of the selected voxels. The results are stored as MATLAB figures and as CSV files for further processing and analysis.


Auxiliary Tools:
----------------
- *EmbedTiles.m*: Script to embed multiple small tiles into a single 3D stack that can be uploaded to Segment3D, an interactive tool for manual 3D segmentation (T. V. Spina *et al.*, SEGMENT3D: A Web-based Application for Collaborative Segmentation of 3D Images used in the Shoot Apical Meristem, In *Proceedings of the IEEE International Symposium on Biomedical Imaging*, 2018, https://arxiv.org/abs/1710.09933).
- *ExtractTiles.m*: Script to undo the embedding in order to analyze the results of individual files separately.
- *PostProcessingPipeline.\**: XPIWIT Pipeline for post-processing to convert a binary boundary map as obtained from Segment3D to a dense label image. A binary version and the sources of XPIWIT including instructions on how to load and apply predefined pipelines can be obtained from https://www.bitbucket.org/jstegmaier/XPIWIT/ (A. Bartschat *et al.*, XPIWIT - An XML Pipeline Wrapper for the Insight Toolkit, *Bioinformatics*, pp. 315-317, 2016.).
- Note: The auxiliary tools can entirely be skipped, if the dense label images are obtained from a different source.
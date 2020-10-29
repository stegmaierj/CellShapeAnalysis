# CellShapeAnalysis
Collection of MATLAB scripts used for segmentation and quantitative analysis of gastrulation in *Drosophila* embryos that were recorded using light-sheet microscopy. The folders of the repository contain the following modules:

- **Data**: Example images to test the presented methods.

- **Mask Generation**: Semi-automatic mask generation for properly cropped 3D images of full or partial *Drosophila* embryos.

- **Peel Generation**: Automatic extraction of a peel at a desired distance from the apical and basal surface, respectively. The peel will be automatically projected to a unwrapped 2D representation.

- **Peel Analysis**: Semi-automatic segmentation, tracking and quantification of a time series of 2D peel images.

- **Tile Analysis**: Automatic tracking and quantification of a time series of label images. Measurementes include the apical and basal surface area and the volume. Tracking information is used to monitor feature changes on the single-cell level over time.

Each folder contains a separate readme file with instructions on how to use the scripts. If you find the software useful, feel free to use it for your own research. Please make sure to cite the following publication:

Bhide, S., Mikut, R., Leptin, M., Stegmaier, J., Semi-Automatic Generation of Tight Binary Masks and Non-Convex Isosurfaces for Quantitative Analysis of 3D Biological Samples, In Proceedings of the IEEE International Conference on Image Processing, 2020.
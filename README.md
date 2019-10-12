# CellShapeAnalysis
Collection of MATLAB scripts used for segmentation and quantitative analysis of gastrulation in *Drosophila* embryos that were recorded using light-sheet microscopy. The folders of the repository contain the following modules:

- **Data**: Example images to test the presented methods.

- **Mask Generation**: Semi-automatic mask generation for properly cropped 3D images of full or partial *Drosophila* embryos.

- **Peel Generation**: Automatic extraction of a peel at a desired distance from the apical and basal surface, respectively. The peel will be automatically projected to a unwrapped 2D representation.

- **Tile Analysis**: Automatic tracking and quantification of a time series of label images. Measurementes include the apical and basal surface area and the volume. Tracking information is used to monitor feature changes on the single-cell level over time.

If you find the software useful, feel free to use it for your own research. Please make sure to cite the following publication:

Bhide *et al.*, Cell Shape Changes during *Drosophila* Gastrulation, *in preparation*.
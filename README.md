# bratton-morphometricsUtilities
A collection of utilities to assist in analyzing (bacterial) cell shapes

This collection includes tools based in MATLAB and designed for the structured outputs of morphometrics. Morphometrics code base is available through https://simtk.org/projects/morphometrics and is not maintained by the authors of this set of utilities. 

Users of morphometrics should cite its public release
Ursell, T., Lee, T.K., Shiomi, D. et al. Rapid, precise quantification of bacterial cellular dimensions across a genomic-scale knockout library. BMC Biol 15, 17 (2017). https://doi.org/10.1186/s12915-017-0348-8

If you find these utilities helpful, please cite their first release
R.M. Morgenstein, B.P. Bratton, J.P. Nguyen, N. Ouzounov, J.W. Shaevitz, & Z. Gitai,  RodZ links MreB to cell wall synthesis to mediate MreB rotation and robust morphogenesis, Proc. Natl. Acad. Sci. U.S.A. 112 (40) 12510-12515, https://doi.org/10.1073/pnas.1509610112 (2015)

## Dependencies
This package is written primarily for MATLAB. The utilities have been tested on version R2015a-R2025a and we anticipate no signficant version conflicts outside this range.

Please download the following and add them to your MATLAB path:
uipickfiles https://www.mathworks.com/matlabcentral/fileexchange/10867-uipickfiles-uigetfile-on-steroids
progressbar http://www.mathworks.com/matlabcentral/fileexchange/6922-progressbar
v2struct https://www.mathworks.com/matlabcentral/fileexchange/31532-pack-unpack-variables-to-from-structures-with-enhanced-functionality

The function bpass (spatial bandpass) from Crocker, Grier, and Weeks was originally ported to MATLAB by Daniel Blair and Eric Dufresne (https://site.physics.georgetown.edu/matlab/index.html). The version included here has modifications by Benjamin Bratton as mentioned in the author attributions header.

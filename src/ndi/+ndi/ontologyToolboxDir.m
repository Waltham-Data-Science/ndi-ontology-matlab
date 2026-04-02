function folderPath = ontologyToolboxDir()
% ONTOLOGYTOOLBOXDIR Returns the root directory of the ndi-ontology-matlab toolbox.
%
% FOLDERPATH = ONTOLOGYTOOLBOXDIR()
%
% Returns the absolute path to the src/ndi directory of this toolbox,
% which is the parent of the +ndi package folder. Data files (ndi_common)
% are located relative to this directory.
%
% Example:
%   root_dir = ndi.ontologyToolboxDir();
%
% See also: FILEPARTS, MFILENAME

    folderPath = fileparts(fileparts(mfilename('fullpath')));
end

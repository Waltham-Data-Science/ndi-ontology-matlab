classdef PathConstants
% PathConstants - Path constants for the NDI ontology toolbox.
%
%   Provides path constants needed by the ndi.ontology classes.
%
%   RootFolder    | The path of the ndi-ontology toolbox on this machine.
%   CommonFolder  | The path to the ndi_common data folder.

    properties (Constant)
        % RootFolder - The path of the ndi-ontology toolbox on this machine.
        RootFolder = ndi.toolboxdir()

        % CommonFolder - The path to the ndi_common data folder.
        CommonFolder = fullfile(ndi.common.PathConstants.RootFolder, 'ndi_common')
    end
end

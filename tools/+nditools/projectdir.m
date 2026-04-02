function folderPath = projectdir()
% projectdir - Get the project (repository) root directory for ndi-ontology-matlab.
    folderPath = fileparts(fileparts(fileparts(mfilename('fullpath'))));
end

% Location: +ndi/+ontology/SNOMEDCT.m
classdef SNOMEDCT < ndi.ontology.SNOMED
% SNOMEDCT - NDI Ontology object for the SNOMEDCT: prefix of SNOMED CT.
%   SNOMEDCT:<ID> is the same SNOMED CT concept as SNOMED:<ID>. It is
%   looked up exactly as ndi.ontology.SNOMED looks it up (OLS4 ontology
%   'snomed'), and the ID is returned with the SNOMEDCT: prefix it was
%   asked for, so a stored SNOMEDCT: node resolves to itself.
%
%   See also: ndi.ontology.SNOMED
%             https://www.ebi.ac.uk/ols4/ontologies/snomed
    methods
        function obj = SNOMEDCT()
            % SNOMEDCT - Constructor for the SNOMEDCT ontology object.
            % Implicitly calls the superclass constructor ndi.ontology.SNOMED().
        end % constructor

        function [id, name, definition, synonyms] = lookupTermOrID(obj, term_or_id_or_name)
            % LOOKUPTERMORID - Looks up a term in SNOMED CT under the SNOMEDCT: prefix.
            %
            %   [ID, NAME, DEFINITION, SYNONYMS] = lookupTermOrID(OBJ, TERM_OR_ID_OR_NAME)
            %
            %   The input TERM_OR_ID_OR_NAME is the part after the 'SNOMEDCT:' prefix
            %   (e.g., '36645008' for an ID, or 'Stimulator' for a name search).
            %
            %   Example Usage (via dispatcher):
            %   [id, name] = ndi.ontology.lookup('SNOMEDCT:36645008'); % Stimulator
            %   [id, name] = ndi.ontology.lookup('SNOMEDCT:Stimulator');
            [id, name, definition, synonyms] = ...
                lookupTermOrID@ndi.ontology.SNOMED(obj, term_or_id_or_name);
            if startsWith(id, 'SNOMED:')
                id = ['SNOMEDCT:' id(numel('SNOMED:')+1:end)];
            end
        end % function lookupTermOrID
    end % methods
end % classdef SNOMEDCT

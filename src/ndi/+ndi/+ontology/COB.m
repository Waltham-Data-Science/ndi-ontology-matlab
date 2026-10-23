% Location: +ndi/+ontology/COB.m
classdef COB < ndi.ontology
% COB - NDI Ontology object for the Core Ontology for Biology and Biomedicine (COB), which describes
% the core classes the OBO Foundry ontologies share, such as
% organism (COB:0000022) and device (COB:0001300).
%   Inherits from ndi.ontology and implements lookupTermOrID for COB.
%
%   See also: http://obofoundry.org/ontology/cob.html
%             https://www.ebi.ac.uk/ols4/ontologies/cob

    methods
        function obj = COB()
            % COB - Constructor for the COB ontology object.
            % Implicitly calls the superclass constructor ndi.ontology().
        end % constructor

        function [id, name, definition, synonyms] = lookupTermOrID(obj, term_or_id_or_name)
            % LOOKUPTERMORID - Looks up a term in the Core Ontology for Biology and Biomedicine (COB) by ID or name.
            %
            %   [ID, NAME, DEFINITION, SYNONYMS] = lookupTermOrID(OBJ, TERM_OR_ID_OR_NAME)
            %
            %   Overrides the base class method to provide specific lookup
            %   functionality for the COB ontology using the EBI OLS API via
            %   static helper methods from the ndi.ontology base class.
            %
            %   The input TERM_OR_ID_OR_NAME is the part of the original lookup string
            %   after the 'COB:' prefix has been removed (e.g., '0000022' or 'organism').
            %
            %   Example Usage (via dispatcher):
            %   [id, name] = ndi.ontology.lookup('COB:0000022'); % organism
            %   [id, name] = ndi.ontology.lookup('COB:organism');
            %
            %   See also: ndi.ontology.lookup (static dispatcher),
            %             ndi.ontology.preprocessLookupInput (static helper),
            %             ndi.ontology.searchOLSAndPerformIRILookup (static helper)
            arguments
                obj (1,1) ndi.ontology.COB %#ok<INUSA> (the lookup interface)
                term_or_id_or_name {mustBeText}
            end

            % Define ontology specifics for COB
            ontology_prefix = 'COB';
            ontology_name_ols = 'cob';

            % --- Step 1: Preprocess Input using Base Class Static Helper ---
            % Determines if input is ID or name, prepares OLS query parameters.
            try
                % Call static method using full class name qualification
                [search_query, search_field, lookup_type_msg, ~] = ...
                    ndi.ontology.preprocessLookupInput(term_or_id_or_name, ontology_prefix);
            catch ME
                baseME = MException('ndi:ontology:COB:PreprocessingError', ...
                     'Error preprocessing COB lookup input "%s".', term_or_id_or_name);
                baseME = addCause(baseME, ME);
                throw(baseME);
            end

            % --- Step 2: Perform Search and IRI Lookup using Base Class Static Helper ---
            % Performs OLS search, verifies unique result, gets IRI, looks up IRI details.
            try
                % Call static method using full class name qualification
                [id, name, definition, synonyms] = ...
                    ndi.ontology.searchOLSAndPerformIRILookup(...
                        search_query, search_field, ontology_name_ols, ontology_prefix, lookup_type_msg);
            catch ME
                 baseME = MException('ndi:ontology:COB:LookupFailed', ...
                     'COB lookup failed for %s.', lookup_type_msg);
                 baseME = addCause(baseME, ME);
                 throw(baseME);
            end

        end % function lookupTermOrID

    end % methods

end % classdef COB

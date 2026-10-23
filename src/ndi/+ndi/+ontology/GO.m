% Location: +ndi/+ontology/GO.m
classdef GO < ndi.ontology
% GO - NDI Ontology object for the Gene Ontology (GO), which describes
% biological processes, molecular functions and cellular components,
% such as action potential (GO:0001508).
%   Inherits from ndi.ontology and implements lookupTermOrID for GO.
%
%   See also: http://obofoundry.org/ontology/go.html
%             https://www.ebi.ac.uk/ols4/ontologies/go

    methods
        function obj = GO()
            % GO - Constructor for the GO ontology object.
            % Implicitly calls the superclass constructor ndi.ontology().
        end % constructor

        function [id, name, definition, synonyms] = lookupTermOrID(obj, term_or_id_or_name)
            % LOOKUPTERMORID - Looks up a term in the Gene Ontology (GO) by ID or name.
            %
            %   [ID, NAME, DEFINITION, SYNONYMS] = lookupTermOrID(OBJ, TERM_OR_ID_OR_NAME)
            %
            %   Overrides the base class method to provide specific lookup
            %   functionality for the GO ontology using the EBI OLS API via
            %   static helper methods from the ndi.ontology base class.
            %
            %   The input TERM_OR_ID_OR_NAME is the part of the original lookup string
            %   after the 'GO:' prefix has been removed (e.g., '0001508' or 'action potential').
            %
            %   Example Usage (via dispatcher):
            %   [id, name] = ndi.ontology.lookup('GO:0001508'); % action potential
            %   [id, name] = ndi.ontology.lookup('GO:action potential');
            %
            %   See also: ndi.ontology.lookup (static dispatcher),
            %             ndi.ontology.preprocessLookupInput (static helper),
            %             ndi.ontology.searchOLSAndPerformIRILookup (static helper)
            arguments
                obj (1,1) ndi.ontology.GO %#ok<INUSA> (the lookup interface)
                term_or_id_or_name {mustBeText}
            end

            % Define ontology specifics for GO
            ontology_prefix = 'GO';
            ontology_name_ols = 'go';

            % --- Step 1: Preprocess Input using Base Class Static Helper ---
            % Determines if input is ID or name, prepares OLS query parameters.
            try
                % Call static method using full class name qualification
                [search_query, search_field, lookup_type_msg, ~] = ...
                    ndi.ontology.preprocessLookupInput(term_or_id_or_name, ontology_prefix);
            catch ME
                baseME = MException('ndi:ontology:GO:PreprocessingError', ...
                     'Error preprocessing GO lookup input "%s".', term_or_id_or_name);
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
                 baseME = MException('ndi:ontology:GO:LookupFailed', ...
                     'GO lookup failed for %s.', lookup_type_msg);
                 baseME = addCause(baseME, ME);
                 throw(baseME);
            end

        end % function lookupTermOrID

    end % methods

end % classdef GO

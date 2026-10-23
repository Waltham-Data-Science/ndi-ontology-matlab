% Location: +ndi/+ontology/RO.m
classdef RO < ndi.ontology
% RO - NDI Ontology object for the Relation Ontology (RO), which describes
% the OBO relations used across the OBO Foundry ontologies, such as
% member of (RO:0002350) and located in (RO:0001025). RO terms are
% relations (OWL object properties); OLS serves them as properties.
%   Inherits from ndi.ontology and implements lookupTermOrID for RO.
%
%   See also: http://obofoundry.org/ontology/ro.html
%             https://www.ebi.ac.uk/ols4/ontologies/ro

    methods
        function obj = RO()
            % RO - Constructor for the RO ontology object.
            % Implicitly calls the superclass constructor ndi.ontology().
        end % constructor

        function [id, name, definition, synonyms] = lookupTermOrID(obj, term_or_id_or_name)
            % LOOKUPTERMORID - Looks up a term in the Relation Ontology (RO) by ID or name.
            %
            %   [ID, NAME, DEFINITION, SYNONYMS] = lookupTermOrID(OBJ, TERM_OR_ID_OR_NAME)
            %
            %   Overrides the base class method to provide specific lookup
            %   functionality for the RO ontology using the EBI OLS API via
            %   static helper methods from the ndi.ontology base class.
            %
            %   The input TERM_OR_ID_OR_NAME is the part of the original lookup string
            %   after the 'RO:' prefix has been removed (e.g., '0002350' or 'member of').
            %
            %   Example Usage (via dispatcher):
            %   [id, name] = ndi.ontology.lookup('RO:0002350'); % member of
            %   [id, name] = ndi.ontology.lookup('RO:member of');
            %
            %   See also: ndi.ontology.lookup (static dispatcher),
            %             ndi.ontology.preprocessLookupInput (static helper),
            %             ndi.ontology.searchOLSAndPerformIRILookup (static helper)
            arguments
                obj (1,1) ndi.ontology.RO %#ok<INUSA> (the lookup interface)
                term_or_id_or_name {mustBeText}
            end

            % Define ontology specifics for RO
            ontology_prefix = 'RO';
            ontology_name_ols = 'ro';

            % --- Step 1: Preprocess Input using Base Class Static Helper ---
            % Determines if input is ID or name, prepares OLS query parameters.
            try
                % Call static method using full class name qualification
                [search_query, search_field, lookup_type_msg, ~] = ...
                    ndi.ontology.preprocessLookupInput(term_or_id_or_name, ontology_prefix);
            catch ME
                baseME = MException('ndi:ontology:RO:PreprocessingError', ...
                     'Error preprocessing RO lookup input "%s".', term_or_id_or_name);
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
                 baseME = MException('ndi:ontology:RO:LookupFailed', ...
                     'RO lookup failed for %s.', lookup_type_msg);
                 baseME = addCause(baseME, ME);
                 throw(baseME);
            end

        end % function lookupTermOrID

    end % methods

end % classdef RO

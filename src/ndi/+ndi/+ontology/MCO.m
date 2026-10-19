% Location: +ndi/+ontology/MCO.m
classdef MCO < ndi.ontology
% MCO - NDI Ontology object for the Microbial Conditions Ontology (MCO),
% which describes the conditions of microbial cultures, such as the optical
% density of a culture at 600 nm (OD600, MCO:0000059).
%   Inherits from ndi.ontology and implements lookupTermOrID for MCO.

    methods
        function obj = MCO()
            % MCO - Constructor for the MCO ontology object.
            % Implicitly calls the superclass constructor ndi.ontology().
        end % constructor

        function [id, name, definition, synonyms] = lookupTermOrID(~, term_or_id_or_name)
            % LOOKUPTERMORID - Looks up a term in the Microbial Conditions Ontology (MCO) by ID or name.
            %
            %   [ID, NAME, DEFINITION, SYNONYMS] = lookupTermOrID(OBJ, TERM_OR_ID_OR_NAME)
            %
            %   Overrides the base class method to provide specific lookup
            %   functionality for the MCO ontology using the EBI OLS API via
            %   static helper methods from the ndi.ontology base class.
            %
            %   The input TERM_OR_ID_OR_NAME is the part of the original lookup string
            %   after the 'MCO:' prefix has been removed (e.g., '0000059' or 'OD600').
            %
            %   See also: ndi.ontology.lookup (static dispatcher),
            %             ndi.ontology.preprocessLookupInput (static helper),
            %             ndi.ontology.searchOLSAndPerformIRILookup (static helper)

            % Define ontology specifics for MCO
            ontology_prefix = 'MCO';
            ontology_name_ols = 'mco';

            % --- Step 1: Preprocess Input using Base Class Static Helper ---
            % Determines if input is ID or name, prepares OLS query parameters.
            try
                % Call static method using full class name qualification
                [search_query, search_field, lookup_type_msg, ~] = ...
                    ndi.ontology.preprocessLookupInput(term_or_id_or_name, ontology_prefix);
            catch ME
                baseME = MException('ndi:ontology:MCO:PreprocessingError', ...
                     'Error preprocessing MCO lookup input "%s".', term_or_id_or_name);
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
                 baseME = MException('ndi:ontology:MCO:LookupFailed', ...
                     'MCO lookup failed for %s.', lookup_type_msg);
                 baseME = addCause(baseME, ME);
                 throw(baseME);
            end

        end % function lookupTermOrID

    end % methods

end % classdef MCO
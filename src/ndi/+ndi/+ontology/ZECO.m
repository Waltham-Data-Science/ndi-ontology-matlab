% Location: +ndi/+ontology/ZECO.m
classdef ZECO < ndi.ontology
% ZECO - NDI Ontology object for the Zebrafish Experimental Conditions Ontology
% (ZECO), whose experimental conditions are general, not zebrafish-specific,
% such as food availability (ZECO:0000113) and fasting (ZECO:0000114).
%   Inherits from ndi.ontology and implements lookupTermOrID for ZECO.

    methods
        function obj = ZECO()
            % ZECO - Constructor for the ZECO ontology object.
            % Implicitly calls the superclass constructor ndi.ontology().
        end % constructor

        function [id, name, definition, synonyms] = lookupTermOrID(obj, term_or_id_or_name)
            % LOOKUPTERMORID - Looks up a term in the Zebrafish Experimental Conditions Ontology (ZECO) by ID or name.
            %
            %   [ID, NAME, DEFINITION, SYNONYMS] = lookupTermOrID(OBJ, TERM_OR_ID_OR_NAME)
            %
            %   Overrides the base class method to provide specific lookup
            %   functionality for the ZECO ontology using the EBI OLS API via
            %   static helper methods from the ndi.ontology base class.
            %
            %   The input TERM_OR_ID_OR_NAME is the part of the original lookup string
            %   after the 'ZECO:' prefix has been removed (e.g., '0000113' or 'food availability').
            %
            %   See also: ndi.ontology.lookup (static dispatcher),
            %             ndi.ontology.preprocessLookupInput (static helper),
            %             ndi.ontology.searchOLSAndPerformIRILookup (static helper)
            arguments
                obj (1,1) ndi.ontology.ZECO %#ok<INUSA> (the lookup interface)
                term_or_id_or_name {mustBeText}
            end

            % Define ontology specifics for ZECO
            ontology_prefix = 'ZECO';
            ontology_name_ols = 'zeco';

            % --- Step 1: Preprocess Input using Base Class Static Helper ---
            % Determines if input is ID or name, prepares OLS query parameters.
            try
                % Call static method using full class name qualification
                [search_query, search_field, lookup_type_msg, ~] = ...
                    ndi.ontology.preprocessLookupInput(term_or_id_or_name, ontology_prefix);
            catch ME
                baseME = MException('ndi:ontology:ZECO:PreprocessingError', ...
                     'Error preprocessing ZECO lookup input "%s".', term_or_id_or_name);
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
                 baseME = MException('ndi:ontology:ZECO:LookupFailed', ...
                     'ZECO lookup failed for %s.', lookup_type_msg);
                 baseME = addCause(baseME, ME);
                 throw(baseME);
            end

        end % function lookupTermOrID

    end % methods

end % classdef ZECO
% Location: +ndi/+ontology/CREDIT.m
classdef CREDIT < ndi.ontology
% CREDIT - NDI Ontology object for the CRediT contributor roles (CREDIT:00000001
% conceptualization role ... CREDIT:00000014 writing review and editing role),
% as published in the Contributor Role Ontology (CRO) and indexed by OLS under
% 'cro'.
%   Inherits from ndi.ontology and implements lookupTermOrID for CREDIT.

    methods
        function obj = CREDIT()
            % CREDIT - Constructor for the CREDIT ontology object.
            % Implicitly calls the superclass constructor ndi.ontology().
        end % constructor

        function [id, name, definition, synonyms] = lookupTermOrID(~, term_or_id_or_name)
            % LOOKUPTERMORID - Looks up a CRediT role (in OLS's CRO) by ID or name.
            %
            %   [ID, NAME, DEFINITION, SYNONYMS] = lookupTermOrID(OBJ, TERM_OR_ID_OR_NAME)
            %
            %   Overrides the base class method to provide specific lookup
            %   functionality for the CREDIT ontology using the EBI OLS API via
            %   static helper methods from the ndi.ontology base class.
            %
            %   The input TERM_OR_ID_OR_NAME is the part of the original lookup string
            %   after the 'CREDIT:' prefix has been removed (e.g., '00000001' or 'conceptualization role').
            %
            %   See also: ndi.ontology.lookup (static dispatcher),
            %             ndi.ontology.preprocessLookupInput (static helper),
            %             ndi.ontology.searchOLSAndPerformIRILookup (static helper)

            % Define ontology specifics for CREDIT
            ontology_prefix = 'CREDIT';
            ontology_name_ols = 'cro';

            % --- Step 1: Preprocess Input using Base Class Static Helper ---
            % Determines if input is ID or name, prepares OLS query parameters.
            try
                % Call static method using full class name qualification
                [search_query, search_field, lookup_type_msg, ~] = ...
                    ndi.ontology.preprocessLookupInput(term_or_id_or_name, ontology_prefix);
            catch ME
                baseME = MException('ndi:ontology:CREDIT:PreprocessingError', ...
                     'Error preprocessing CREDIT lookup input "%s".', term_or_id_or_name);
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
                 baseME = MException('ndi:ontology:CREDIT:LookupFailed', ...
                     'CREDIT lookup failed for %s.', lookup_type_msg);
                 baseME = addCause(baseME, ME);
                 throw(baseME);
            end

        end % function lookupTermOrID

    end % methods

end % classdef CREDIT
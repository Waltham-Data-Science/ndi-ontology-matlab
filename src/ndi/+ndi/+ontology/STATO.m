% Location: +ndi/+ontology/STATO.m
classdef STATO < ndi.ontology
% STATO - NDI Ontology object for the Statistics Ontology (STATO).
%   Inherits from ndi.ontology and implements lookupTermOrID for STATO.
%   STATO is a general-purpose STATistics Ontology, providing coverage of
%   statistical tests, statistical estimators, distributions, probability
%   functions, and study designs.
%
%   See also: http://stato-ontology.org/
%             https://www.ebi.ac.uk/ols4/ontologies/stato
    methods
        function obj = STATO()
            % STATO - Constructor for the STATO ontology object.
            % Implicitly calls the superclass constructor ndi.ontology().
        end % constructor

        function [id, name, definition, synonyms] = lookupTermOrID(obj, term_or_id_or_name)
            % LOOKUPTERMORID - Looks up a term in the STATO ontology.
            %
            %   [ID, NAME, DEFINITION, SYNONYMS] = lookupTermOrID(OBJ, TERM_OR_ID_OR_NAME)
            %
            %   Overrides the base class method to provide specific lookup functionality
            %   for STATO using the EBI OLS API via static helper methods.
            %
            %   The input TERM_OR_ID_OR_NAME is the part after the 'STATO:' prefix.
            %   (e.g., '0000700' for p-value, or 'p-value' for a name search).
            %
            %   Example Usage (via dispatcher):
            %   [id, name, ~, def] = ndi.ontology.lookup('STATO:0000700'); % p-value
            %   [id, name, ~, def] = ndi.ontology.lookup('STATO:p-value');

            % Define ontology specifics for STATO
            ontology_prefix = 'STATO';
            ontology_name_ols = 'stato'; % OLS uses 'stato' as the ontology ID

            % --- Step 1: Preprocess Input using Base Class Static Helper ---
            try
                [search_query, search_field, lookup_type_msg, ~] = ...
                    ndi.ontology.preprocessLookupInput(term_or_id_or_name, ontology_prefix);
            catch ME
                baseME = MException('ndi:ontology:STATO:PreprocessingError', ...
                    'Error preprocessing STATO lookup input "%s".', term_or_id_or_name);
                baseME = addCause(baseME, ME);
                throw(baseME);
            end

            % --- Step 2: Perform Search and IRI Lookup ---
            try
                % search_query will be 'STATO:0000019' for numeric IDs or 'p-value' for labels
                [id, name, definition, synonyms] = ...
                    ndi.ontology.searchOLSAndPerformIRILookup(...
                        search_query, search_field, ontology_name_ols, ontology_prefix, lookup_type_msg);
            catch ME
                baseME = MException('ndi:ontology:STATO:LookupFailed', ...
                    'STATO lookup failed for %s.', lookup_type_msg);
                baseME = addCause(baseME, ME);
                throw(baseME);
            end
        end % function lookupTermOrID
    end % methods
end % classdef STATO

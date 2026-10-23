% Location: +ndi/+ontology/UO.m
classdef UO < ndi.ontology
% UO - NDI Ontology object for the Units of Measurement Ontology (UO), which describes
% units of measurement, such as pH (UO:0000196). OLS lists most UO units
% twice, as a class and as an individual with the same IRI; the lookup
% treats them as one term.
%   Inherits from ndi.ontology and implements lookupTermOrID for UO.
%
%   See also: http://obofoundry.org/ontology/uo.html
%             https://www.ebi.ac.uk/ols4/ontologies/uo

    methods
        function obj = UO()
            % UO - Constructor for the UO ontology object.
            % Implicitly calls the superclass constructor ndi.ontology().
        end % constructor

        function [id, name, definition, synonyms] = lookupTermOrID(obj, term_or_id_or_name)
            % LOOKUPTERMORID - Looks up a term in the Units of Measurement Ontology (UO) by ID or name.
            %
            %   [ID, NAME, DEFINITION, SYNONYMS] = lookupTermOrID(OBJ, TERM_OR_ID_OR_NAME)
            %
            %   Overrides the base class method to provide specific lookup
            %   functionality for the UO ontology using the EBI OLS API via
            %   static helper methods from the ndi.ontology base class.
            %
            %   The input TERM_OR_ID_OR_NAME is the part of the original lookup string
            %   after the 'UO:' prefix has been removed (e.g., '0000196' or 'pH').
            %
            %   Example Usage (via dispatcher):
            %   [id, name] = ndi.ontology.lookup('UO:0000196'); % pH
            %   [id, name] = ndi.ontology.lookup('UO:pH');
            %
            %   See also: ndi.ontology.lookup (static dispatcher),
            %             ndi.ontology.preprocessLookupInput (static helper),
            %             ndi.ontology.searchOLSAndPerformIRILookup (static helper)
            arguments
                obj (1,1) ndi.ontology.UO %#ok<INUSA> (the lookup interface)
                term_or_id_or_name {mustBeText}
            end

            % Define ontology specifics for UO
            ontology_prefix = 'UO';
            ontology_name_ols = 'uo';

            % --- Step 1: Preprocess Input using Base Class Static Helper ---
            % Determines if input is ID or name, prepares OLS query parameters.
            try
                % Call static method using full class name qualification
                [search_query, search_field, lookup_type_msg, ~] = ...
                    ndi.ontology.preprocessLookupInput(term_or_id_or_name, ontology_prefix);
            catch ME
                baseME = MException('ndi:ontology:UO:PreprocessingError', ...
                     'Error preprocessing UO lookup input "%s".', term_or_id_or_name);
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
                 baseME = MException('ndi:ontology:UO:LookupFailed', ...
                     'UO lookup failed for %s.', lookup_type_msg);
                 baseME = addCause(baseME, ME);
                 throw(baseME);
            end

        end % function lookupTermOrID

    end % methods

end % classdef UO

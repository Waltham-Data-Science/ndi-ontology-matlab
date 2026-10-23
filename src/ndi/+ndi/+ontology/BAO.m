% Location: +ndi/+ontology/BAO.m
classdef BAO < ndi.ontology
% BAO - NDI Ontology object for the BioAssay Ontology (BAO), which describes
% bioassays and their components, such as wild type (BAO:0000089).
% BAO IRIs are not OBO PURLs (http://www.bioassayontology.org/bao#BAO_0000089);
% the term is found by its BAO:NNNNNNN ID, which OLS holds as the obo_id.
%   Inherits from ndi.ontology and implements lookupTermOrID for BAO.
%
%   See also: http://www.bioassayontology.org/
%             https://www.ebi.ac.uk/ols4/ontologies/bao

    methods
        function obj = BAO()
            % BAO - Constructor for the BAO ontology object.
            % Implicitly calls the superclass constructor ndi.ontology().
        end % constructor

        function [id, name, definition, synonyms] = lookupTermOrID(obj, term_or_id_or_name)
            % LOOKUPTERMORID - Looks up a term in the BioAssay Ontology (BAO) by ID or name.
            %
            %   [ID, NAME, DEFINITION, SYNONYMS] = lookupTermOrID(OBJ, TERM_OR_ID_OR_NAME)
            %
            %   Overrides the base class method to provide specific lookup
            %   functionality for the BAO ontology using the EBI OLS API via
            %   static helper methods from the ndi.ontology base class.
            %
            %   The input TERM_OR_ID_OR_NAME is the part of the original lookup string
            %   after the 'BAO:' prefix has been removed (e.g., '0000089' or 'wild type').
            %
            %   Example Usage (via dispatcher):
            %   [id, name] = ndi.ontology.lookup('BAO:0000089'); % wild type
            %   [id, name] = ndi.ontology.lookup('BAO:wild type');
            %
            %   See also: ndi.ontology.lookup (static dispatcher),
            %             ndi.ontology.preprocessLookupInput (static helper),
            %             ndi.ontology.searchOLSAndPerformIRILookup (static helper)
            arguments
                obj (1,1) ndi.ontology.BAO %#ok<INUSA> (the lookup interface)
                term_or_id_or_name {mustBeText}
            end

            % Define ontology specifics for BAO
            ontology_prefix = 'BAO';
            ontology_name_ols = 'bao';

            % --- Step 1: Preprocess Input using Base Class Static Helper ---
            % Determines if input is ID or name, prepares OLS query parameters.
            try
                % Call static method using full class name qualification
                [search_query, search_field, lookup_type_msg, ~] = ...
                    ndi.ontology.preprocessLookupInput(term_or_id_or_name, ontology_prefix);
            catch ME
                baseME = MException('ndi:ontology:BAO:PreprocessingError', ...
                     'Error preprocessing BAO lookup input "%s".', term_or_id_or_name);
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
                 baseME = MException('ndi:ontology:BAO:LookupFailed', ...
                     'BAO lookup failed for %s.', lookup_type_msg);
                 baseME = addCause(baseME, ME);
                 throw(baseME);
            end

        end % function lookupTermOrID

    end % methods

end % classdef BAO

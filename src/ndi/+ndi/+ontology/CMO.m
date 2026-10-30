% Location: +ndi/+ontology/CMO.m
classdef CMO < ndi.ontology
% CMO - NDI Ontology object for the Clinical Measurement Ontology (CMO), which describes
% morphological and physiological measurements made on an organism, such as
% percent of time spent in voluntary immobility (CMO:0001044).
%   Inherits from ndi.ontology and implements lookupTermOrID for CMO.
%
%   See also: http://obofoundry.org/ontology/cmo.html
%             https://www.ebi.ac.uk/ols4/ontologies/cmo

    methods
        function obj = CMO()
            % CMO - Constructor for the CMO ontology object.
            % Implicitly calls the superclass constructor ndi.ontology().
        end % constructor

        function [id, name, definition, synonyms] = lookupTermOrID(obj, term_or_id_or_name)
            % LOOKUPTERMORID - Looks up a term in the Clinical Measurement Ontology (CMO) by ID or name.
            %
            %   [ID, NAME, DEFINITION, SYNONYMS] = lookupTermOrID(OBJ, TERM_OR_ID_OR_NAME)
            %
            %   Overrides the base class method to provide specific lookup
            %   functionality for the CMO ontology using the EBI OLS API via
            %   static helper methods from the ndi.ontology base class.
            %
            %   The input TERM_OR_ID_OR_NAME is the part of the original lookup string
            %   after the 'CMO:' prefix has been removed (e.g., '0001044' or 'percent of time spent in voluntary immobility').
            %
            %   Example Usage (via dispatcher):
            %   [id, name] = ndi.ontology.lookup('CMO:0001044'); % percent of time spent in voluntary immobility
            %   [id, name] = ndi.ontology.lookup('CMO:acoustic startle response measurement');
            %
            %   See also: ndi.ontology.lookup (static dispatcher),
            %             ndi.ontology.preprocessLookupInput (static helper),
            %             ndi.ontology.searchOLSAndPerformIRILookup (static helper)
            arguments
                obj (1,1) ndi.ontology.CMO %#ok<INUSA> (the lookup interface)
                term_or_id_or_name {mustBeText}
            end

            % Define ontology specifics for CMO
            ontology_prefix = 'CMO';
            ontology_name_ols = 'cmo';

            % --- Step 1: Preprocess Input using Base Class Static Helper ---
            % Determines if input is ID or name, prepares OLS query parameters.
            try
                % Call static method using full class name qualification
                [search_query, search_field, lookup_type_msg, ~] = ...
                    ndi.ontology.preprocessLookupInput(term_or_id_or_name, ontology_prefix);
            catch ME
                baseME = MException('ndi:ontology:CMO:PreprocessingError', ...
                     'Error preprocessing CMO lookup input "%s".', term_or_id_or_name);
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
                 baseME = MException('ndi:ontology:CMO:LookupFailed', ...
                     'CMO lookup failed for %s.', lookup_type_msg);
                 baseME = addCause(baseME, ME);
                 throw(baseME);
            end

        end % function lookupTermOrID

    end % methods

end % classdef CMO

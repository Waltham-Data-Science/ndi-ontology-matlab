% Location: +ndi/+ontology/ENVO.m
classdef ENVO < ndi.ontology
% ENVO - NDI Ontology object for the Environment Ontology (ENVO), which describes
% environments, environmental materials and the relations between them,
% such as derives from part of (ENVO:01003004). ENVO IDs have eight
% digits.
%   Inherits from ndi.ontology and implements lookupTermOrID for ENVO.
%
%   See also: http://obofoundry.org/ontology/envo.html
%             https://www.ebi.ac.uk/ols4/ontologies/envo

    methods
        function obj = ENVO()
            % ENVO - Constructor for the ENVO ontology object.
            % Implicitly calls the superclass constructor ndi.ontology().
        end % constructor

        function [id, name, definition, synonyms] = lookupTermOrID(obj, term_or_id_or_name)
            % LOOKUPTERMORID - Looks up a term in the Environment Ontology (ENVO) by ID or name.
            %
            %   [ID, NAME, DEFINITION, SYNONYMS] = lookupTermOrID(OBJ, TERM_OR_ID_OR_NAME)
            %
            %   Overrides the base class method to provide specific lookup
            %   functionality for the ENVO ontology using the EBI OLS API via
            %   static helper methods from the ndi.ontology base class.
            %
            %   The input TERM_OR_ID_OR_NAME is the part of the original lookup string
            %   after the 'ENVO:' prefix has been removed (e.g., '01003004' or 'derives from part of').
            %
            %   Example Usage (via dispatcher):
            %   [id, name] = ndi.ontology.lookup('ENVO:01003004'); % derives from part of
            %   [id, name] = ndi.ontology.lookup('ENVO:derives from part of');
            %
            %   See also: ndi.ontology.lookup (static dispatcher),
            %             ndi.ontology.preprocessLookupInput (static helper),
            %             ndi.ontology.searchOLSAndPerformIRILookup (static helper)
            arguments
                obj (1,1) ndi.ontology.ENVO %#ok<INUSA> (the lookup interface)
                term_or_id_or_name {mustBeText}
            end

            % Define ontology specifics for ENVO
            ontology_prefix = 'ENVO';
            ontology_name_ols = 'envo';

            % --- Step 1: Preprocess Input using Base Class Static Helper ---
            % Determines if input is ID or name, prepares OLS query parameters.
            try
                % Call static method using full class name qualification
                [search_query, search_field, lookup_type_msg, ~] = ...
                    ndi.ontology.preprocessLookupInput(term_or_id_or_name, ontology_prefix);
            catch ME
                baseME = MException('ndi:ontology:ENVO:PreprocessingError', ...
                     'Error preprocessing ENVO lookup input "%s".', term_or_id_or_name);
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
                 baseME = MException('ndi:ontology:ENVO:LookupFailed', ...
                     'ENVO lookup failed for %s.', lookup_type_msg);
                 baseME = addCause(baseME, ME);
                 throw(baseME);
            end

        end % function lookupTermOrID

    end % methods

end % classdef ENVO

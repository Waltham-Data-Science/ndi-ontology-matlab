% Location: +ndi/+ontology/BFO.m
classdef BFO < ndi.ontology
% BFO - NDI Ontology object for the Basic Formal Ontology (BFO), which describes
% the upper-level ontology the OBO Foundry ontologies are built on, such
% as material entity (BFO:0000040). BFO's relations, such as part of
% (BFO:0000050), are maintained in RO and are not in the BFO release OLS
% serves; a BFO ID that OLS does not hold under bfo is looked up by its
% IRI in RO.
%   Inherits from ndi.ontology and implements lookupTermOrID for BFO.
%
%   See also: http://obofoundry.org/ontology/bfo.html
%             https://www.ebi.ac.uk/ols4/ontologies/bfo

    methods
        function obj = BFO()
            % BFO - Constructor for the BFO ontology object.
            % Implicitly calls the superclass constructor ndi.ontology().
        end % constructor

        function [id, name, definition, synonyms] = lookupTermOrID(obj, term_or_id_or_name)
            % LOOKUPTERMORID - Looks up a term in the Basic Formal Ontology (BFO) by ID or name.
            %
            %   [ID, NAME, DEFINITION, SYNONYMS] = lookupTermOrID(OBJ, TERM_OR_ID_OR_NAME)
            %
            %   Overrides the base class method to provide specific lookup
            %   functionality for the BFO ontology using the EBI OLS API via
            %   static helper methods from the ndi.ontology base class.
            %
            %   The input TERM_OR_ID_OR_NAME is the part of the original lookup string
            %   after the 'BFO:' prefix has been removed (e.g., '0000040' or 'material entity').
            %
            %   Example Usage (via dispatcher):
            %   [id, name] = ndi.ontology.lookup('BFO:0000040'); % material entity
            %   [id, name] = ndi.ontology.lookup('BFO:material entity');
            %   [id, name] = ndi.ontology.lookup('BFO:0000050'); % part of (from RO)
            %
            %   See also: ndi.ontology.lookup (static dispatcher),
            %             ndi.ontology.preprocessLookupInput (static helper),
            %             ndi.ontology.searchOLSAndPerformIRILookup (static helper)
            arguments
                obj (1,1) ndi.ontology.BFO %#ok<INUSA> (the lookup interface)
                term_or_id_or_name {mustBeText}
            end

            % Define ontology specifics for BFO
            ontology_prefix = 'BFO';
            ontology_name_ols = 'bfo';

            % --- Step 1: Preprocess Input using Base Class Static Helper ---
            % Determines if input is ID or name, prepares OLS query parameters.
            try
                % Call static method using full class name qualification
                [search_query, search_field, lookup_type_msg, ~] = ...
                    ndi.ontology.preprocessLookupInput(term_or_id_or_name, ontology_prefix);
            catch ME
                baseME = MException('ndi:ontology:BFO:PreprocessingError', ...
                     'Error preprocessing BFO lookup input "%s".', term_or_id_or_name);
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
                % BFO's relations (part of, BFO:0000050; has part, BFO:0000051)
                % are maintained in RO, and the BFO release OLS serves under
                % 'bfo' holds none of them. An ID that OLS does not hold under
                % 'bfo' is looked up by its OBO IRI in RO.
                found_in_ro = false;
                if strcmp(search_field, 'obo_id')
                    term_iri = ['http://purl.obolibrary.org/obo/' strrep(search_query, ':', '_')];
                    try
                        [id, name, definition, synonyms] = ...
                            ndi.ontology.performIriLookup(term_iri, 'ro', ontology_prefix);
                        found_in_ro = strcmp(id, search_query) && ~isempty(name);
                    catch
                        found_in_ro = false;
                    end
                end
                if ~found_in_ro
                    baseME = MException('ndi:ontology:BFO:LookupFailed', ...
                        'BFO lookup failed for %s.', lookup_type_msg);
                    baseME = addCause(baseME, ME);
                    throw(baseME);
                end
            end

        end % function lookupTermOrID

    end % methods

end % classdef BFO

% Location: +ndi/+ontology/SIO.m
classdef SIO < ndi.ontology
% SIO - NDI Ontology object for the Semanticscience Integrated Ontology (SIO), which describes
% the objects, processes and attributes of scientific data, and the
% relations between them, such as is version of (SIO:000497). SIO IDs
% have six digits and SIO IRIs are not OBO PURLs
% (http://semanticscience.org/resource/SIO_000497); the term is found by
% its SIO:NNNNNN ID, which OLS holds as the obo_id.
%   Inherits from ndi.ontology and implements lookupTermOrID for SIO.
%
%   See also: https://github.com/MaastrichtU-IDS/semanticscience
%             https://www.ebi.ac.uk/ols4/ontologies/sio

    methods
        function obj = SIO()
            % SIO - Constructor for the SIO ontology object.
            % Implicitly calls the superclass constructor ndi.ontology().
        end % constructor

        function [id, name, definition, synonyms] = lookupTermOrID(obj, term_or_id_or_name)
            % LOOKUPTERMORID - Looks up a term in the Semanticscience Integrated Ontology (SIO) by ID or name.
            %
            %   [ID, NAME, DEFINITION, SYNONYMS] = lookupTermOrID(OBJ, TERM_OR_ID_OR_NAME)
            %
            %   Overrides the base class method to provide specific lookup
            %   functionality for the SIO ontology using the EBI OLS API via
            %   static helper methods from the ndi.ontology base class.
            %
            %   The input TERM_OR_ID_OR_NAME is the part of the original lookup string
            %   after the 'SIO:' prefix has been removed (e.g., '000497' or 'is version of').
            %
            %   Example Usage (via dispatcher):
            %   [id, name] = ndi.ontology.lookup('SIO:000497'); % is version of
            %   [id, name] = ndi.ontology.lookup('SIO:is version of');
            %
            %   See also: ndi.ontology.lookup (static dispatcher),
            %             ndi.ontology.preprocessLookupInput (static helper),
            %             ndi.ontology.searchOLSAndPerformIRILookup (static helper)
            arguments
                obj (1,1) ndi.ontology.SIO %#ok<INUSA> (the lookup interface)
                term_or_id_or_name {mustBeText}
            end

            % Define ontology specifics for SIO
            ontology_prefix = 'SIO';
            ontology_name_ols = 'sio';

            % --- Step 1: Preprocess Input using Base Class Static Helper ---
            % Determines if input is ID or name, prepares OLS query parameters.
            try
                % Call static method using full class name qualification
                [search_query, search_field, lookup_type_msg, ~] = ...
                    ndi.ontology.preprocessLookupInput(term_or_id_or_name, ontology_prefix);
            catch ME
                baseME = MException('ndi:ontology:SIO:PreprocessingError', ...
                     'Error preprocessing SIO lookup input "%s".', term_or_id_or_name);
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
                 baseME = MException('ndi:ontology:SIO:LookupFailed', ...
                     'SIO lookup failed for %s.', lookup_type_msg);
                 baseME = addCause(baseME, ME);
                 throw(baseME);
            end

        end % function lookupTermOrID

    end % methods

end % classdef SIO

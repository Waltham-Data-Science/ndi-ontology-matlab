% Location: +ndi/+ontology/AFO.m
classdef AFO < ndi.ontology
% AFO - NDI Ontology object for the Allotrope Foundation Ontology (AFO,
% the Allotrope Merged Ontology Suite), which describes laboratory
% equipment, processes, materials and results, such as acquisition time
% (AFO:AFR_0001158) and cluster identifier (AFO:AFR_0003339).
%   Inherits from ndi.ontology and implements lookupTermOrID for AFO.
%
%   AFO IDs are written AFO:<ID>, where <ID> is the term's own ID, an
%   Allotrope ID prefix and seven digits (AFR_0001158). AFO keeps each ID
%   prefix in its own namespace, so the IRI is not the ID appended to one
%   base:
%       AFR_  -> http://purl.allotrope.org/ontologies/result#
%       AFE_  -> .../equipment#     AFP_  -> .../process#
%       AFQ_  -> .../quality#       AFM_  -> .../material#
%       AFRL_ -> .../role#          AFFN_ -> .../function#
%       AFRE_ -> .../realizable#    AFC_  -> .../common#
%       AFSP_ -> .../spatial#       AFX_  -> .../property#
%   (every AFO class and Allotrope property OLS4 lists for ontology 'afo',
%   REC/2026/09, read 2026-10-27). An ID is looked up by that IRI in OLS;
%   a name by an exact label search in OLS. OLS reports AFO's own IDs in a
%   namespace-qualified form ('AFO_result#AFR:0001158'), so the ID
%   returned is rebuilt as AFO:<ID>.
%
%   See also: https://www.allotrope.org
%             https://www.ebi.ac.uk/ols4/ontologies/afo
%             https://bioregistry.io/registry/afo

    properties (Constant)
        % The OLS4 ontology id and the prefix written in IDs.
        OLS_NAME = 'afo';
        ONTOLOGY_PREFIX = 'AFO';
        % The part of every AFO IRI before the namespace name.
        IRI_ROOT = 'http://purl.allotrope.org/ontologies/';
        % Allotrope ID prefix -> the namespace that holds it.
        NAMESPACES = struct( ...
            'AFR', 'result', 'AFE', 'equipment', 'AFP', 'process', ...
            'AFQ', 'quality', 'AFM', 'material', 'AFRL', 'role', ...
            'AFFN', 'function', 'AFRE', 'realizable', 'AFC', 'common', ...
            'AFSP', 'spatial', 'AFX', 'property');
    end

    methods
        function obj = AFO()
            % AFO - Constructor for the AFO ontology object.
            % Implicitly calls the superclass constructor ndi.ontology().
        end % constructor

        function [id, name, definition, synonyms] = lookupTermOrID(obj, term_or_id_or_name)
            % LOOKUPTERMORID - Looks up a term in the Allotrope Foundation Ontology by ID or name.
            %
            %   [ID, NAME, DEFINITION, SYNONYMS] = lookupTermOrID(OBJ, TERM_OR_ID_OR_NAME)
            %
            %   The input TERM_OR_ID_OR_NAME is the part of the original
            %   lookup string after the 'AFO:' prefix has been removed
            %   (e.g., 'AFR_0001158' or 'acquisition time').
            %
            %   Example Usage (via dispatcher):
            %   [id, name, ~, def] = ndi.ontology.lookup('AFO:AFR_0001158'); % acquisition time
            %   [id, name] = ndi.ontology.lookup('AFO:cluster identifier');  % AFO:AFR_0003339
            %
            %   See also: ndi.ontology.lookup (static dispatcher),
            %             ndi.ontology.performIriLookup (static helper),
            %             ndi.ontology.searchOLSAndPerformIRILookup (static helper)
            arguments
                obj (1,1) ndi.ontology.AFO %#ok<INUSA> (the lookup interface)
                term_or_id_or_name {mustBeText}
            end

            query = strtrim(char(term_or_id_or_name));
            if isempty(query)
                error('ndi:ontology:AFO:EmptyInput', 'AFO lookup needs an ID or a name after "AFO:".');
            end

            idParts = regexp(query, '^(AF[A-Za-z]{1,3})_(\d+)$', 'tokens', 'once');
            if ~isempty(idParts)
                % --- An ID: look it up by its IRI ---
                localId = [upper(idParts{1}) '_' idParts{2}];
                term_iri = ndi.ontology.AFO.iriForId(localId);
                try
                    [~, name, definition, synonyms] = ndi.ontology.performIriLookup( ...
                        term_iri, ndi.ontology.AFO.OLS_NAME, ndi.ontology.AFO.ONTOLOGY_PREFIX);
                catch ME
                    baseME = MException('ndi:ontology:AFO:LookupFailed', ...
                        'AFO lookup failed for ID "%s" (IRI %s).', localId, term_iri);
                    baseME = addCause(baseME, ME);
                    throw(baseME);
                end
                id = [ndi.ontology.AFO.ONTOLOGY_PREFIX ':' localId];
            else
                % --- A name: exact label search in OLS ---
                lookup_type_msg = sprintf('name "%s"', query);
                try
                    [olsId, name, definition, synonyms] = ndi.ontology.searchOLSAndPerformIRILookup( ...
                        query, 'label', ndi.ontology.AFO.OLS_NAME, ...
                        ndi.ontology.AFO.ONTOLOGY_PREFIX, lookup_type_msg);
                catch ME
                    baseME = MException('ndi:ontology:AFO:LookupFailed', ...
                        'AFO lookup failed for %s.', lookup_type_msg);
                    baseME = addCause(baseME, ME);
                    throw(baseME);
                end
                id = ndi.ontology.AFO.normalizeId(olsId);
            end
        end % function lookupTermOrID

    end % methods

    methods (Static)
        function term_iri = iriForId(localId)
            % IRIFORID - The IRI of an AFO ID such as 'AFR_0001158'.
            %
            %   TERM_IRI = ndi.ontology.AFO.iriForId(LOCALID)
            %
            %   Errors for an ID prefix with no known AFO namespace.
            arguments
                localId (1,:) char
            end
            parts = regexp(localId, '^(AF[A-Z]{1,3})_\d+$', 'tokens', 'once');
            if isempty(parts) || ~isfield(ndi.ontology.AFO.NAMESPACES, parts{1})
                error('ndi:ontology:AFO:UnknownIdPrefix', ...
                    'AFO ID "%s" has no known namespace (known ID prefixes: %s).', ...
                    localId, strjoin(fieldnames(ndi.ontology.AFO.NAMESPACES)', ', '));
            end
            term_iri = [ndi.ontology.AFO.IRI_ROOT ...
                ndi.ontology.AFO.NAMESPACES.(parts{1}) '#' localId];
        end % function iriForId

        function id = normalizeId(olsId)
            % NORMALIZEID - AFO:<ID> from an ID as OLS reports it.
            %
            %   ID = ndi.ontology.AFO.normalizeId(OLSID)
            %
            %   OLS writes AFO IDs with their namespace ('AFO_result#AFR:0001158',
            %   'AFO:result#AFR_0001158'); this returns 'AFO:AFR_0001158'. An ID
            %   that is not an Allotrope ID (an imported term) is returned as given.
            arguments
                olsId (1,:) char
            end
            parts = regexp(olsId, '(AF[A-Z]{1,3})[_:](\d+)$', 'tokens', 'once');
            if isempty(parts)
                id = olsId;
            else
                id = [ndi.ontology.AFO.ONTOLOGY_PREFIX ':' parts{1} '_' parts{2}];
            end
        end % function normalizeId
    end % methods (Static)

end % classdef AFO

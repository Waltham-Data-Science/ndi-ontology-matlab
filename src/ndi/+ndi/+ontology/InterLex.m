% Location: +ndi/+ontology/InterLex.m
classdef InterLex < ndi.ontology
% InterLex - NDI Ontology object for InterLex (SciCrunch).
%   Inherits from ndi.ontology and implements lookupTermOrID for InterLex
%   identifiers, e.g. 'ILX:0739413' or 'interlex:0739413'.
%
%   InterLex names the openMINDS experimentalApproach terms (DID-schema
%   term registry, Jess Haley 2026-10-21). Its CURIE is written
%   'ILX:nnnnnnn' (InterLex's own JSON-LD context declares
%   ILX -> http://uri.interlex.org/base/ilx_); the prefixes 'interlex' and
%   'ILX' are matched case-insensitively, and the local part may be given
%   with or without 'ilx_' ('0739413', 'ilx_0739413').
%
%   WHICH ENDPOINT. The SciCrunch InterLex API
%   (https://scicrunch.org/api/1/ilx/...) needs an API key, so it is not
%   used. Each term's public IRI resolves without a key to a JSON-LD
%   record: http://uri.interlex.org/base/ilx_<n>.jsonld (http only: the
%   https certificate does not name uri.interlex.org). OLS4 holds no
%   InterLex mirror (https://www.ebi.ac.uk/ols4/api/ontologies/ilx is 404,
%   2026-10-21). So only IDs can be looked up: a search by label needs the
%   keyed API.
%
%   Usage example:
%       [id, name, ~, def] = ndi.ontology.lookup('ILX:0739413');
%       % id = 'ILX:0739413', name = 'behavioral approach'

    properties (Constant, Access = private)
        IRI_BASE = 'http://uri.interlex.org/base/ilx_';
    end

    methods
        function obj = InterLex()
            % InterLex - Constructor for the InterLex ontology object.
        end % constructor

        function [id, name, definition, synonyms] = lookupTermOrID(obj, term_or_id_or_name)
            % LOOKUPTERMORID - Looks up an InterLex term by its ID.
            %
            %   [ID, NAME, DEFINITION, SYNONYMS] = lookupTermOrID(OBJ, TERM_OR_ID)
            %
            %   TERM_OR_ID is the part after the 'ILX:' / 'interlex:' prefix.
            arguments
                obj (1,1) ndi.ontology.InterLex %#ok<INUSA> (the lookup interface)
                term_or_id_or_name {mustBeText}
            end
            num = ndi.ontology.InterLex.localNumber(term_or_id_or_name);
            if isempty(num)
                error('ndi:ontology:InterLex:NotAnID', ...
                    ['InterLex lookup takes an ID (ILX:0739413); "%s" is not one. ' ...
                     'A search by label needs the keyed SciCrunch API, which is not used.'], ...
                    char(term_or_id_or_name));
            end
            url = [ndi.ontology.InterLex.IRI_BASE num '.jsonld'];
            opts = weboptions('Timeout', 30, 'ContentType', 'text');
            try
                body = webread(url, opts);
            catch ME
                % an unknown id answers 500, not 404 (checked 2026-10-21)
                if contains(ME.message, '404') || contains(ME.message, '500') || ...
                        contains(ME.message, 'Not Found')
                    error('ndi:ontology:InterLex:TermNotFound', ...
                        'InterLex term ILX:%s not found (%s): %s', num, url, ME.message);
                end
                baseME = MException('ndi:ontology:InterLex:APIError', ...
                    'Failed to fetch InterLex term ILX:%s from %s.', num, url);
                baseME = addCause(baseME, ME);
                throw(baseME);
            end
            [id, name, definition, synonyms] = ndi.ontology.InterLex.parseRecord(body, num);
        end % function lookupTermOrID
    end % methods

    methods (Static)
        function num = localNumber(s)
            % LOCALNUMBER - The digits of an InterLex ID, or '' if S is not one.
            %   Accepts '0739413', 'ilx_0739413' and 'ILX_0739413'.
            s = strtrim(char(s));
            tok = regexp(s, '^(?:[iI][lL][xX]_)?(\d+)$', 'tokens', 'once');
            num = '';
            if ~isempty(tok)
                num = tok{1};
            end
        end

        function [id, name, definition, synonyms] = parseRecord(body, num)
            % PARSERECORD - ID, label, definition and synonyms from InterLex JSON-LD.
            %
            %   BODY is the text (or decoded struct) of
            %   http://uri.interlex.org/base/ilx_<NUM>.jsonld. The term is the
            %   @graph node whose @id is that IRI. ID is 'ILX:<NUM>'. Public so
            %   the parsing can be tested without the network.
            if ~isstruct(body)
                try
                    body = jsondecode(char(body));
                catch ME
                    baseME = MException('ndi:ontology:InterLex:ParseError', ...
                        'The InterLex response is not valid JSON-LD.');
                    baseME = addCause(baseME, ME);
                    throw(baseME);
                end
            end
            if ~isfield(body, 'x_graph')
                error('ndi:ontology:InterLex:ParseError', 'The InterLex response has no @graph.');
            end
            graph = body.x_graph;
            if isstruct(graph)
                graph = num2cell(graph);
            end
            iri = [ndi.ontology.InterLex.IRI_BASE num];
            node = [];
            for k = 1:numel(graph)
                g = graph{k};
                if isstruct(g) && isfield(g, 'x_id') && strcmp(char(g.x_id), iri)
                    node = g;
                    break;
                end
            end
            if isempty(node) || ~isfield(node, 'rdfs_label')
                error('ndi:ontology:InterLex:TermNotFound', ...
                    'InterLex term ILX:%s has no labelled record.', num);
            end
            id = ['ILX:' num];
            name = char(node.rdfs_label);
            definition = '';
            if isfield(node, 'definition') && ~isempty(node.definition)
                definition = char(node.definition);
            end
            synonyms = {};
            if isfield(node, 'NIFRID_synonym') && ~isempty(node.NIFRID_synonym)
                synonyms = reshape(cellstr(node.NIFRID_synonym), 1, []);
            end
        end
    end % methods (Static)
end % classdef InterLex

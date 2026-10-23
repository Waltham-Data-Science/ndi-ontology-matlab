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
            % The same record in two serializations, each asked for with and
            % without explicit headers. From a GitHub-hosted runner the
            % resolver answered "500 INTERNAL SERVER ERROR" to MATLAB's
            % default .jsonld request (2026-10-21) while the same URL answered
            % 200 elsewhere, so the other forms are tried before giving up.
            base = [ndi.ontology.InterLex.IRI_BASE num];
            attempts = { ...
                [base '.jsonld'], {}; ...
                [base '.jsonld'], {'Accept', 'application/ld+json'}; ...
                [base '.ttl'],    {'Accept', 'text/turtle'}; ...
                [base '.csv'],    {'Accept', 'text/csv'}};
            failures = {};
            for k = 1:size(attempts, 1)
                url = attempts{k, 1};
                opts = weboptions('Timeout', 30, 'ContentType', 'text', ...
                    'UserAgent', 'ndi-ontology-matlab (https://github.com/Waltham-Data-Science/ndi-ontology-matlab)');
                if ~isempty(attempts{k, 2})
                    opts.HeaderFields = attempts{k, 2};
                end
                try
                    body = webread(url, opts);
                catch ME
                    failures{end+1} = sprintf('%s: %s', url, ME.message); %#ok<AGROW>
                    continue;
                end
                if endsWith(url, '.ttl')
                    [id, name, definition, synonyms] = ndi.ontology.InterLex.parseTurtle(body, num);
                elseif endsWith(url, '.csv')
                    [id, name, definition, synonyms] = ndi.ontology.InterLex.parseCsv(body, num);
                else
                    [id, name, definition, synonyms] = ndi.ontology.InterLex.parseRecord(body, num);
                end
                return;
            end
            % an unknown id answers 500, not 404 (checked 2026-10-21), so a
            % miss and a server fault look alike here; both are reported
            error('ndi:ontology:InterLex:TermNotFound', ...
                'InterLex term ILX:%s could not be read: %s', num, strjoin(failures, ' | '));
        end % function lookupTermOrID
    end % methods

    methods (Static)
        function [id, name, definition, synonyms] = parseTurtle(body, num)
            % PARSETURTLE - ID, label, definition and synonyms from the
            %   Turtle record http://uri.interlex.org/base/ilx_<NUM>.ttl: the
            %   statements of the block that opens 'ILX:<NUM> a owl:Class'.
            body = char(body);
            start = regexp(body, ['(?m)^ILX:' num '\s+a\s+owl:Class'], 'once');
            if isempty(start)
                error('ndi:ontology:InterLex:TermNotFound', ...
                    'InterLex term ILX:%s has no class record.', num);
            end
            stop = regexp(body(start:end), '\s\.\s*(\n|$)', 'once');
            if isempty(stop)
                stop = numel(body) - start + 1;
            end
            block = body(start:start + stop - 1);
            name = ndi.ontology.InterLex.turtleValues(block, 'rdfs:label');
            if isempty(name)
                error('ndi:ontology:InterLex:TermNotFound', ...
                    'InterLex term ILX:%s has no label.', num);
            end
            id = ['ILX:' num];
            name = name{1};
            d = ndi.ontology.InterLex.turtleValues(block, 'definition:');
            definition = '';
            if ~isempty(d)
                definition = d{1};
            end
            synonyms = ndi.ontology.InterLex.turtleValues(block, 'NIFRID:synonym');
        end

        function [id, name, definition, synonyms] = parseCsv(body, num)
            % PARSECSV - ID, label, definition and synonyms from the CSV
            %   record http://uri.interlex.org/base/ilx_<NUM>.csv (header
            %   iri,label,synonyms,definition,...; one row per class).
            lines = splitlines(strtrim(char(body)));
            iri = [ndi.ontology.InterLex.IRI_BASE num];
            if numel(lines) < 2
                error('ndi:ontology:InterLex:TermNotFound', 'InterLex term ILX:%s has no row.', num);
            end
            header = strsplit(lines{1}, ',');
            col = @(n) find(strcmp(header, n), 1);
            for k = 2:numel(lines)
                cells = ndi.ontology.InterLex.csvCells(lines{k});
                if numel(cells) >= numel(header) && strcmp(cells{col('iri')}, iri)
                    id = ['ILX:' num];
                    name = cells{col('label')};
                    definition = cells{col('definition')};
                    synonyms = {};
                    if ~isempty(cells{col('synonyms')})
                        synonyms = strsplit(cells{col('synonyms')}, '|');
                    end
                    return;
                end
            end
            error('ndi:ontology:InterLex:TermNotFound', 'InterLex term ILX:%s has no row.', num);
        end

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

    methods (Static, Access = private)
        function v = turtleValues(block, predicate)
            % every quoted literal following PREDICATE in a Turtle block
            % (a predicate's objects are separated by commas)
            v = {};
            tok = regexp(block, [regexptranslate('escape', predicate) ...
                '\s+((?:"(?:[^"\\]|\\.)*"(?:@\w+)?\s*,?\s*)+)'], 'tokens', 'once');
            if isempty(tok)
                return;
            end
            lits = regexp(tok{1}, '"((?:[^"\\]|\\.)*)"', 'tokens');
            v = cellfun(@(c) strrep(strrep(c{1}, '\"', '"'), '\\', '\'), lits, ...
                'UniformOutput', false);
        end

        function c = csvCells(line)
            % split one CSV line, honouring double-quoted fields
            c = {};
            cur = '';
            q = false;
            k = 1;
            while k <= numel(line)
                ch = line(k);
                if q
                    if ch == '"' && k < numel(line) && line(k + 1) == '"'
                        cur(end+1) = '"'; %#ok<AGROW>
                        k = k + 1;
                    elseif ch == '"'
                        q = false;
                    else
                        cur(end+1) = ch; %#ok<AGROW>
                    end
                elseif ch == '"'
                    q = true;
                elseif ch == ','
                    c{end+1} = cur; %#ok<AGROW>
                    cur = '';
                else
                    cur(end+1) = ch; %#ok<AGROW>
                end
                k = k + 1;
            end
            c{end+1} = cur;
        end
    end % methods (Static, Access = private)
end % classdef InterLex

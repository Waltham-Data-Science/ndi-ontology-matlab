% Location: +ndi/+ontology/Wikidata.m
classdef Wikidata < ndi.ontology
% Wikidata - NDI Ontology object for Wikidata entities.
%   Inherits from ndi.ontology and implements lookupTermOrID for Wikidata
%   items, e.g. 'wikidata:Q30' (United States).
%
%   The openMINDS sovereignState and supranationalBody terms are named by
%   their Wikidata entities (DID-schema term registry, the ethics
%   jurisdiction value set, Jess Haley 2026-10-21). Lookups use the public
%   MediaWiki API (https://www.wikidata.org/w/api.php):
%   action=wbgetentities for an ID, action=wbsearchentities for an English
%   label. No key is needed; Wikimedia asks clients to send a descriptive
%   User-Agent, which this class does.
%
%   Usage example:
%       [id, name, ~, def] = ndi.ontology.lookup('wikidata:Q30');
%       % id = 'wikidata:Q30', name = 'United States'

    properties (Constant, Access = private)
        API_URL = 'https://www.wikidata.org/w/api.php';
        USER_AGENT = 'ndi-ontology-matlab (https://github.com/VH-Lab/ndi-ontology-matlab)';
    end

    methods
        function obj = Wikidata()
            % Wikidata - Constructor for the Wikidata ontology object.
        end % constructor

        function [id, name, definition, synonyms] = lookupTermOrID(obj, term_or_id_or_name)
            % LOOKUPTERMORID - Looks up a Wikidata entity by ID or English label.
            %
            %   TERM_OR_ID_OR_NAME is the part after the 'wikidata:' prefix:
            %   an entity ID ('Q30') or an English label ('United States').
            arguments
                obj (1,1) ndi.ontology.Wikidata %#ok<INUSA> (the lookup interface)
                term_or_id_or_name {mustBeText}
            end
            query = strtrim(char(term_or_id_or_name));
            if isempty(query)
                error('ndi:ontology:Wikidata:EmptyInput', ...
                    'Wikidata lookup requires a non-empty ID or label.');
            end
            if isempty(regexp(query, '^[QPLqpl]\d+$', 'once'))
                hits = ndi.ontology.Wikidata.get({'action', 'wbsearchentities', ...
                    'search', query, 'language', 'en', 'type', 'item', 'limit', '10', ...
                    'format', 'json'});
                qid = ndi.ontology.Wikidata.exactLabelMatch(hits, query);
                if isempty(qid)
                    error('ndi:ontology:Wikidata:TermNotFound', ...
                        'No Wikidata item is labelled "%s".', query);
                end
                query = qid;
            end
            query = upper(query);
            body = ndi.ontology.Wikidata.get({'action', 'wbgetentities', ...
                'ids', query, 'props', 'labels|descriptions|aliases', ...
                'languages', 'en', 'format', 'json'});
            [id, name, definition, synonyms] = ndi.ontology.Wikidata.parseEntity(body, query);
        end % function lookupTermOrID
    end % methods

    methods (Static)
        function [id, name, definition, synonyms] = parseEntity(body, qid)
            % PARSEENTITY - ID, English label, description and aliases of QID
            %   from a wbgetentities response (text or decoded struct).
            %   Public so the parsing can be tested without the network.
            if ~isstruct(body)
                try
                    body = jsondecode(char(body));
                catch ME
                    baseME = MException('ndi:ontology:Wikidata:ParseError', ...
                        'The Wikidata response is not valid JSON.');
                    baseME = addCause(baseME, ME);
                    throw(baseME);
                end
            end
            if ~isfield(body, 'entities') || ~isfield(body.entities, qid)
                error('ndi:ontology:Wikidata:TermNotFound', 'Wikidata entity %s not found.', qid);
            end
            e = body.entities.(qid);
            if isfield(e, 'missing') || ~isfield(e, 'labels') || ~isstruct(e.labels) ...
                    || ~isfield(e.labels, 'en')
                error('ndi:ontology:Wikidata:TermNotFound', ...
                    'Wikidata entity %s not found, or it has no English label.', qid);
            end
            id = ['wikidata:' qid];
            name = char(e.labels.en.value);
            definition = '';
            if isfield(e, 'descriptions') && isstruct(e.descriptions) && isfield(e.descriptions, 'en')
                definition = char(e.descriptions.en.value);
            end
            synonyms = {};
            if isfield(e, 'aliases') && isstruct(e.aliases) && isfield(e.aliases, 'en')
                a = e.aliases.en;
                if iscell(a)
                    a = [a{:}];
                end
                synonyms = reshape(cellstr({a.value}), 1, []);
            end
        end

        function qid = exactLabelMatch(hits, label)
            % EXACTLABELMATCH - The ID of the first wbsearchentities hit whose
            %   label is LABEL (ignoring case), or '' if there is none.
            qid = '';
            if ~isstruct(hits)
                hits = jsondecode(char(hits));
            end
            if ~isfield(hits, 'search') || isempty(hits.search)
                return;
            end
            s = hits.search;
            if isstruct(s)
                s = num2cell(s);
            end
            for k = 1:numel(s)
                if isfield(s{k}, 'label') && strcmpi(char(s{k}.label), label)
                    qid = char(s{k}.id);
                    return;
                end
            end
        end
    end % methods (Static)

    methods (Static, Access = private)
        function body = get(args)
            opts = weboptions('Timeout', 30, 'ContentType', 'text', ...
                'UserAgent', ndi.ontology.Wikidata.USER_AGENT);
            try
                body = webread(ndi.ontology.Wikidata.API_URL, args{:}, opts);
            catch ME
                baseME = MException('ndi:ontology:Wikidata:APIError', ...
                    'The Wikidata API request failed.');
                baseME = addCause(baseME, ME);
                throw(baseME);
            end
        end
    end % methods (Static, Access = private)
end % classdef Wikidata

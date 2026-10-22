% Location: +ndi/+ontology/SchemaOrg.m
classdef SchemaOrg < ndi.ontology
% SCHEMAORG - NDI Ontology object for the Schema.org vocabulary.
%   Inherits from ndi.ontology and implements lookupTermOrID for Schema.org
%   types and properties via content negotiation with the schema.org server.
%
%   Schema.org terms are identified by their type/property name, e.g.
%   'Person', 'Dataset', 'Organization'.  The lookup prefix is 'schema'.
%
%   Usage example:
%       [id, name, ~, def] = ndi.ontology.lookup('schema:Person');

    methods
        function obj = SchemaOrg()
            % SCHEMAORG - Constructor for the SchemaOrg ontology object.
        end % constructor

        function [id, name, definition, synonyms] = lookupTermOrID(obj, term_or_id_or_name)
            % LOOKUPTERMORID - Looks up a term in Schema.org by name.
            %
            %   [ID, NAME, DEFINITION, SYNONYMS] = lookupTermOrID(OBJ, TERM_OR_ID_OR_NAME)
            %
            %   TERM_OR_ID_OR_NAME is the part of the original lookup string
            %   after the 'schema:' prefix (e.g., 'Person', 'Dataset').

            % Initialize outputs
            id = ''; name = ''; definition = ''; synonyms = {};

            term_name = strtrim(term_or_id_or_name);
            if isempty(term_name)
                error('ndi:ontology:SchemaOrg:EmptyInput', ...
                    'Schema.org lookup requires a non-empty term name.');
            end

            % Fetch the term JSON-LD via HTTP content negotiation.
            % schema.org does NOT serve JSON-LD at /Term.jsonld (404).
            % Request /Term with Accept: application/ld+json instead.
            api_url  = ['https://schema.org/' term_name];
            req_opts = weboptions('Timeout', 30, 'ContentType', 'text', ...
                'HeaderFields', {'Accept', 'application/ld+json'});

            try
                json_str = webread(api_url, req_opts);
            catch ME
                if contains(ME.message, '404') || contains(ME.message, 'Not Found') || ...
                        contains(ME.identifier, 'MATLAB:webservices:HTTP')
                    error('ndi:ontology:SchemaOrg:TermNotFound', ...
                        'Schema.org term "%s" not found (HTTP error: %s).', ...
                        term_name, ME.message);
                end
                baseME = MException('ndi:ontology:SchemaOrg:APIError', ...
                    'Failed to fetch schema.org term "%s".', term_name);
                baseME = addCause(baseME, ME);
                throw(baseME);
            end

            % Verify the term actually appears in the response.
            % (A 200 OK can still be returned for schema.org with HTML when
            %  the Accept header is not honoured, so check explicitly.)
            target_compact = ['schema:' term_name];
            target_full    = ['https://schema.org/' term_name];
            pat_compact = ['"@id"\s*:\s*"' regexptranslate('escape', target_compact) '"'];
            pat_full    = ['"@id"\s*:\s*"' regexptranslate('escape', target_full) '"'];
            if isempty(regexp(json_str, pat_compact, 'once')) && ...
               isempty(regexp(json_str, pat_full, 'once'))
                error('ndi:ontology:SchemaOrg:TermNotFound', ...
                    'Schema.org term "%s" not found in the response body.', term_name);
            end

            % schema.org answers this request with an HTML term page, not
            % bare JSON-LD: the term's JSON-LD is embedded in the page in a
            % <script type="application/ld+json"> block. parseResponse reads
            % the label and comment from either form.
            id = ['schema:' term_name];
            [name, definition] = ndi.ontology.SchemaOrg.parseResponse(json_str, term_name);
            synonyms = {};

        end % function lookupTermOrID

    end % methods

    methods (Static)

        function [name, definition] = parseResponse(body, term_name)
            % PARSERESPONSE - The label and comment of a schema.org term.
            %
            %   [NAME, DEFINITION] = ndi.ontology.SchemaOrg.parseResponse(BODY, TERM_NAME)
            %
            %   BODY is what schema.org returns for https://schema.org/<TERM_NAME>:
            %   either a JSON-LD document, or (as the server sends today, even
            %   when JSON-LD is requested) an HTML term page that embeds the
            %   term's JSON-LD in a <script type="application/ld+json"> block.
            %   For a type the embedded document is an @graph holding the type
            %   and its properties; for a property it is the property itself.
            %
            %   NAME is the entry's rdfs:label and DEFINITION its rdfs:comment.
            %   If no entry for TERM_NAME can be read, NAME falls back to
            %   TERM_NAME and DEFINITION to ''. Public so the parsing can be
            %   tested without the network.
            arguments
                body {mustBeText}
                term_name {mustBeTextScalar, mustBeNonzeroLengthText}
            end
            body = char(body);
            term_name = char(term_name);
            name = term_name;   % safe fallback
            definition = '';

            target_compact = ['schema:' term_name];
            target_full    = ['https://schema.org/' term_name];

            % Candidate JSON-LD documents: the body itself if it is JSON,
            % otherwise every embedded ld+json script block.
            if startsWith(strtrim(body), {'{', '['})
                blocks = {body};
            else
                blocks = regexp(body, ...
                    '<script[^>]*type\s*=\s*"application/ld\+json"[^>]*>(.*?)</script>', ...
                    'tokens', 'ignorecase');
                blocks = cellfun(@(t) t{1}, blocks, 'UniformOutput', false);
            end

            for b = 1:numel(blocks)
                try
                    jdata = jsondecode(blocks{b});
                catch
                    continue;   % not decodable JSON; try the next block
                end
                if ~isstruct(jdata), continue; end
                term_item = ndi.ontology.SchemaOrg.findGraphEntry( ...
                    jdata, target_compact, target_full);
                if isempty(term_item), continue; end

                % The JSON-LD fields are "rdfs:label" / "rdfs:comment",
                % which jsondecode renames (e.g. rdfs_label); search by
                % keyword to be robust across MATLAB versions.
                lbl = ndi.ontology.SchemaOrg.extractByKeyword(term_item, 'label', '');
                if ~isempty(lbl), name = lbl; end
                definition = ndi.ontology.SchemaOrg.extractByKeyword( ...
                    term_item, 'comment', '');
                return;
            end
        end % function parseResponse

    end % methods (Static)

    methods (Static, Access = private)

        function term_item = findGraphEntry(jdata, target_compact, target_full)
            % FINDGRAPHENTRY - Find the JSON-LD @graph entry for the target term.
            %   Returns the matching struct, or [] if not found.
            term_item = [];
            target_ids = {target_compact, target_full};

            % Locate the @graph field (encoded by jsondecode as x0040graph).
            graph_field = '';
            fn = fieldnames(jdata);
            for k = 1:numel(fn)
                if endsWith(lower(fn{k}), 'graph')
                    graph_field = fn{k};
                    break;
                end
            end

            if isempty(graph_field)
                % No @graph: the top-level object may be the term itself.
                id_val = ndi.ontology.SchemaOrg.getFieldEndingWith(jdata, 'id');
                if any(strcmpi(id_val, target_ids))
                    term_item = jdata;
                end
                return;
            end

            graph = jdata.(graph_field);

            % jsondecode returns heterogeneous arrays as cell arrays.
            if isstruct(graph)
                items = num2cell(graph);
            elseif iscell(graph)
                items = graph;
            else
                return;
            end

            for k = 1:numel(items)
                item = items{k};
                if ~isstruct(item), continue; end
                id_val = ndi.ontology.SchemaOrg.getFieldEndingWith(item, 'id');
                if any(strcmpi(id_val, target_ids))
                    term_item = item;
                    return;
                end
            end
        end % function findGraphEntry

        function val = getFieldEndingWith(s, suffix)
            % GETFIELDENDINGWITH - Return the value of the first field whose
            %   name ends with SUFFIX (case-insensitive).
            val = '';
            if ~isstruct(s), return; end
            fn = fieldnames(s);
            for k = 1:numel(fn)
                if endsWith(lower(fn{k}), lower(suffix))
                    v = s.(fn{k});
                    if ischar(v) && ~isempty(v)
                        val = v;
                        return;
                    end
                end
            end
        end % function getFieldEndingWith

        function val = extractByKeyword(s, keyword, default_val)
            % EXTRACTBYKEYWORD - Return the string value of the first field
            %   whose name contains KEYWORD (case-insensitive).
            %   Unwraps nested {"@value": "..."} objects and cell arrays.
            val = default_val;
            if ~isstruct(s), return; end
            fn = fieldnames(s);
            for k = 1:numel(fn)
                if contains(lower(fn{k}), lower(keyword))
                    v = ndi.ontology.SchemaOrg.unwrapValue(s.(fn{k}));
                    if ischar(v) && ~isempty(v)
                        val = v;
                        return;
                    end
                end
            end
        end % function extractByKeyword

        function v = unwrapValue(v)
            % UNWRAPVALUE - Unwrap a JSON-LD value that may be a cell array
            %   or a {"@value": "..."} struct.
            if iscell(v) && ~isempty(v)
                v = v{1};
            end
            if isstruct(v)
                fn = fieldnames(v);
                for j = 1:numel(fn)
                    if contains(lower(fn{j}), 'value')
                        v = v.(fn{j});
                        if iscell(v) && ~isempty(v), v = v{1}; end
                        return;
                    end
                end
                % No 'value' subfield found — return first char field.
                for j = 1:numel(fn)
                    cand = v.(fn{j});
                    if ischar(cand)
                        v = cand;
                        return;
                    end
                end
                v = '';
            end
        end % function unwrapValue

    end % methods (Static, Access = private)

end % classdef SchemaOrg

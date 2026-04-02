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
            %   Schema.org names are case-sensitive (types start uppercase,
            %   properties start lowercase).

            % Initialize outputs
            id = ''; name = ''; definition = ''; synonyms = {};

            term_name = strtrim(term_or_id_or_name);
            if isempty(term_name)
                error('ndi:ontology:SchemaOrg:EmptyInput', ...
                    'Schema.org lookup requires a non-empty term name.');
            end

            % Request the term JSON-LD via HTTP content negotiation.
            % schema.org supports application/ld+json via the Accept header;
            % the .jsonld URL extension is NOT supported and returns 404.
            api_url  = ['https://schema.org/' term_name];
            req_opts = weboptions('Timeout', 30, 'ContentType', 'text', ...
                'HeaderFields', {'Accept', 'application/ld+json'});

            try
                json_str = webread(api_url, req_opts);
            catch ME
                if contains(ME.message, '404') || contains(ME.message, 'Not Found') || ...
                        contains(ME.identifier, 'MATLAB:webservices:HTTP')
                    % Surface a clean "not found" error so the test harness
                    % correctly identifies this as an expected failure.
                    error('ndi:ontology:SchemaOrg:TermNotFound', ...
                        'Schema.org term "%s" not found (HTTP error: %s).', ...
                        term_name, ME.message);
                end
                baseME = MException('ndi:ontology:SchemaOrg:APIError', ...
                    'Failed to fetch schema.org term "%s".', term_name);
                baseME = addCause(baseME, ME);
                throw(baseME);
            end

            % ----- Parse the JSON-LD response with targeted regex -----
            % We avoid jsondecode because JSON-LD field names that contain '@'
            % and ':' characters are encoded differently across MATLAB releases.
            % Regex on the raw JSON string is simpler and more portable.

            % --- @id: full IRI or compact curie, e.g. "schema:Person" or
            %         "https://schema.org/Person"
            id_match = regexp(json_str, '"@id"\s*:\s*"([^"]+)"', 'tokens', 'once');
            if isempty(id_match)
                error('ndi:ontology:SchemaOrg:ParseError', ...
                    'Could not extract @id from schema.org response for term "%s".', term_name);
            end
            raw_id = id_match{1};

            % Derive short name: last segment after '/' or ':'
            sep_pos = max([find(raw_id == '/', 1, 'last'), ...
                           find(raw_id == ':', 1, 'last')]);
            if ~isempty(sep_pos) && sep_pos < numel(raw_id)
                resolved_name = raw_id(sep_pos+1:end);
            else
                resolved_name = term_name;
            end
            id = ['schema:' resolved_name];

            % --- rdfs:label (simple string or {"@value": "..."} object) ---
            name = ndi.ontology.SchemaOrg.extractJSONField(json_str, 'rdfs:label', resolved_name);

            % --- rdfs:comment / description ---
            definition = ndi.ontology.SchemaOrg.extractJSONField(json_str, 'rdfs:comment', '');
            if isempty(definition)
                definition = ndi.ontology.SchemaOrg.extractJSONField(json_str, 'schema:description', '');
            end

            % Schema.org does not have synonyms in the standard JSON-LD output.
            synonyms = {};

        end % function lookupTermOrID

    end % methods

    methods (Static, Access = private)

        function val = extractJSONField(json_str, field_name, default_val)
            % EXTRACTJSONFIELD - Extract a string value for FIELD_NAME from JSON text.
            %   Handles:
            %     "field_name": "simple value"
            %     "field_name": {"@value": "...", ...}
            %   Returns DEFAULT_VAL if the field is absent or not a string.

            escaped_field = regexptranslate('escape', field_name);

            % Try simple string value first
            pat_simple = ['"' escaped_field '"\s*:\s*"([^"]+)"'];
            m = regexp(json_str, pat_simple, 'tokens', 'once');
            if ~isempty(m)
                val = m{1};
                return;
            end

            % Try language-tagged or @value object
            pat_value = ['"' escaped_field '"\s*:\s*\{[^}]*"@value"\s*:\s*"([^"]+)"'];
            m = regexp(json_str, pat_value, 'tokens', 'once');
            if ~isempty(m)
                val = m{1};
                return;
            end

            val = default_val;
        end % function extractJSONField

    end % methods (Static, Access = private)

end % classdef SchemaOrg

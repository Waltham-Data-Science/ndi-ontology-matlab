% Location: +ndi/+ontology/SchemaOrg.m
classdef SchemaOrg < ndi.ontology
% SCHEMAORG - NDI Ontology object for the Schema.org vocabulary.
%   Inherits from ndi.ontology and implements lookupTermOrID for schema.org terms.
%
%   Schema.org terms are identified by their type name (e.g., 'Person',
%   'Organization', 'Dataset'). The prefix used is 'schema'.
%
%   Usage example:
%       result = ndi.ontology.lookup('schema:Person');

    methods
        function obj = SchemaOrg()
            % SCHEMAORG - Constructor for the SchemaOrg ontology object.
            % Implicitly calls the superclass constructor ndi.ontology().
        end % constructor

        function [id, name, definition, synonyms] = lookupTermOrID(obj, term_or_id_or_name)
            % LOOKUPTERMORID - Looks up a term in the Schema.org vocabulary by name.
            %
            %   [ID, NAME, DEFINITION, SYNONYMS] = lookupTermOrID(OBJ, TERM_OR_ID_OR_NAME)
            %
            %   Overrides the base class method to provide specific lookup
            %   functionality for Schema.org using the Schema.org JSON-LD API.
            %
            %   The input TERM_OR_ID_OR_NAME is the part of the original lookup string
            %   after the 'schema:' prefix has been removed (e.g., 'Person', 'Dataset').
            %   Schema.org term names are case-sensitive (types start with uppercase,
            %   properties start with lowercase).
            %
            %   See also: ndi.ontology.lookup (static dispatcher)

            % Initialize outputs
            id = ''; name = ''; definition = ''; synonyms = {};

            term_name = strtrim(term_or_id_or_name);

            if isempty(term_name)
                error('ndi:ontology:SchemaOrg:EmptyInput', ...
                    'Schema.org lookup requires a non-empty term name.');
            end

            % Fetch the term JSON-LD from schema.org
            api_url = ['https://schema.org/' term_name '.jsonld'];
            opts = weboptions('Timeout', 30, 'ContentType', 'json');

            try
                data = webread(api_url, opts);
            catch ME
                if contains(ME.message, '404') || contains(ME.message, 'Not Found') || ...
                        contains(ME.message, 'Unable to resolve') || ...
                        contains(ME.message, 'HTTP 4')
                    error('ndi:ontology:SchemaOrg:TermNotFound', ...
                        'Schema.org term "%s" not found (HTTP 404 or network error: %s).', ...
                        term_name, ME.message);
                else
                    baseME = MException('ndi:ontology:SchemaOrg:APIError', ...
                        'Failed to fetch schema.org term "%s" from API.', term_name);
                    baseME = addCause(baseME, ME);
                    throw(baseME);
                end
            end

            % --- Parse the JSON-LD response ---
            % The response is a struct parsed from JSON-LD. Extract key fields.

            % Extract the @id field (full IRI like "https://schema.org/Person")
            raw_id = '';
            if isstruct(data) && isfield(data, 'x0040id')
                raw_id = data.x0040id;
            elseif isstruct(data) && isfield(data, 'id')
                raw_id = data.id;
            end

            if isempty(raw_id)
                error('ndi:ontology:SchemaOrg:ParseError', ...
                    'Could not extract @id from schema.org response for term "%s".', term_name);
            end

            % Derive short name from the IRI (e.g., "https://schema.org/Person" -> "Person")
            slash_idx = find(raw_id == '/', 1, 'last');
            if ~isempty(slash_idx) && slash_idx < length(raw_id)
                resolved_name = raw_id(slash_idx+1:end);
            else
                resolved_name = term_name;
            end

            id = ['schema:' resolved_name];

            % Extract the label (rdfs:label or schema:name)
            name = SchemaOrg.extractField(data, {'rdfs_label', 'name', 'x0040id'}, resolved_name);
            % If name came from @id, strip the IRI base
            if startsWith(name, 'https://schema.org/')
                name = name(length('https://schema.org/')+1:end);
            end

            % Extract the definition/description (rdfs:comment or schema:description)
            definition = SchemaOrg.extractField(data, {'rdfs_comment', 'description', 'comment'}, '');

            % Extract supersededBy or equivalentClass as synonyms (typically none for schema.org)
            synonyms = {};

        end % function lookupTermOrID

    end % methods

    methods (Static, Access = private)

        function val = extractField(data, field_names, default_val)
            % EXTRACTFIELD - Try to extract a value from a struct using multiple candidate field names.
            %
            %   VAL = extractField(DATA, FIELD_NAMES, DEFAULT_VAL)
            %
            %   Tries each name in FIELD_NAMES in order. Returns the first non-empty
            %   string value found, or DEFAULT_VAL if none found.

            val = default_val;
            for k = 1:numel(field_names)
                fname = field_names{k};
                if isstruct(data) && isfield(data, fname)
                    candidate = data.(fname);
                    % Handle nested structs (e.g., multilingual {"@value":..., "@language":...})
                    if isstruct(candidate) && isfield(candidate, 'x0040value')
                        candidate = candidate.x0040value;
                    elseif isstruct(candidate) && isfield(candidate, 'value')
                        candidate = candidate.value;
                    end
                    % Take first element if cell array
                    if iscell(candidate) && ~isempty(candidate)
                        candidate = candidate{1};
                        if isstruct(candidate) && isfield(candidate, 'x0040value')
                            candidate = candidate.x0040value;
                        end
                    end
                    if ischar(candidate) && ~isempty(candidate)
                        val = candidate;
                        return;
                    end
                end
            end
        end % function extractField

    end % methods (Static, Access = private)

end % classdef SchemaOrg

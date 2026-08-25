% Location: +ndi/+ontology/EDAM.m
classdef EDAM < ndi.ontology
% EDAM - NDI Ontology object for the EDAM ontology.
%   Inherits from ndi.ontology and implements lookupTermOrID for EDAM.
%   EDAM is an ontology of data analysis and management in life sciences.
%
%   EDAM uses sub-ontology prefixes in its OBO IDs (format, data,
%   operation, topic) rather than the top-level 'EDAM' prefix. For
%   example, the FASTA format has IRI http://edamontology.org/format_1929.
%
%   This class downloads and parses the EDAM OWL file directly from
%   GitHub, bypassing the OLS search API for reliability.
%
%   See also: http://edamontology.org
%             https://github.com/edamontology/edamontology

    properties (Constant, Access = private)
        ONTOLOGY_PREFIX = 'EDAM';
        % Raw OWL file from the EDAM GitHub releases
        OWL_URL = 'https://raw.githubusercontent.com/edamontology/edamontology/main/EDAM_dev.owl';
        % EDAM IRI base used in OWL rdf:about attributes
        IRI_BASE = 'http://edamontology.org/';
    end

    methods
        function obj = EDAM()
        end

        function [id, name, definition, synonyms] = lookupTermOrID(obj, term_or_id_or_name)
            % LOOKUPTERMORID - Looks up a term in the EDAM ontology.
            %
            %   Downloads and caches the EDAM OWL file from GitHub, then
            %   searches by numeric ID or label name.
            %
            %   Example:
            %   [id, name, ~, def] = ndi.ontology.lookup('format:1929'); % FASTA
            %   [id, name, ~, def] = ndi.ontology.lookup('EDAM:1929');   % FASTA

            % Parse and cache the EDAM terms. The cache lives in a static
            % helper so ndi.ontology.clearCache can flush it (see EDAM.clearCache).
            terms = ndi.ontology.EDAM.getTerms();

            if isempty(terms)
                error('ndi:ontology:EDAM:NoTerms', ...
                    'EDAM ontology file contained no parseable terms.');
            end

            % Determine if input is a numeric ID or a name
            isNumericID = ~isempty(regexp(term_or_id_or_name, '^\d+$', 'once'));

            found = false;
            matchIdx = [];
            id = ''; name = ''; definition = ''; synonyms = {};

            if isNumericID
                % Match by numeric ID portion (ids are unique).
                for i = 1:numel(terms)
                    if strcmp(terms(i).numeric_id, term_or_id_or_name)
                        matchIdx = i;
                        found = true;
                        break;
                    end
                end
            else
                % Match by label (case-insensitive). A label can occur in more
                % than one EDAM sub-ontology (format/data/operation/topic).
                % Previously the loop broke on the FIRST match, silently
                % resolving to whichever owl:Class appeared earlier in the file.
                % Collect ALL matches and error on ambiguity instead.
                matchMask = arrayfun(@(t) strcmpi(t.name, term_or_id_or_name), terms);
                allMatches = find(matchMask);
                if numel(allMatches) > 1
                    error('ndi:ontology:EDAM:NameNotUnique', ...
                        'EDAM label "%s" matches multiple (%d) terms across sub-ontologies. Use the numeric ID.', ...
                        term_or_id_or_name, numel(allMatches));
                elseif numel(allMatches) == 1
                    matchIdx = allMatches(1);
                    found = true;
                end
            end

            if found
                t = terms(matchIdx);
                id = [obj.ONTOLOGY_PREFIX ':' t.numeric_id];
                name = t.name;
                definition = t.definition;
                synonyms = t.synonyms;
            end

            if ~found
                if isNumericID
                    error('ndi:ontology:EDAM:LookupFailed', ...
                        'EDAM lookup failed for numeric ID "%s".', term_or_id_or_name);
                else
                    error('ndi:ontology:EDAM:LookupFailed', ...
                        'EDAM lookup failed for name "%s".', term_or_id_or_name);
                end
            end
        end
    end

    methods (Static)
        function clearCache()
            % CLEARCACHE - Clear the persistent EDAM term cache.
            %   Forces the next lookup to re-download and re-parse the EDAM OWL
            %   file. Called by ndi.ontology.clearCache.
            ndi.ontology.EDAM.getTerms('clear');
        end % function clearCache
    end % methods (Static)

    methods (Static, Access = private)
        function terms = getTerms(action)
            % GETTERMS - Return (and build/cache if necessary) the EDAM terms.
            %   Supports a 'clear' sentinel to flush the persistent cache.
            persistent edamCache;

            if nargin >= 1 && (ischar(action) || isstring(action)) && strcmpi(action, 'clear')
                edamCache = [];
                terms = [];
                return;
            end

            if isempty(edamCache)
                edamCache = containers.Map('KeyType', 'char', 'ValueType', 'any');
            end
            cacheKey = 'edam_terms';
            if ~isKey(edamCache, cacheKey)
                edamCache(cacheKey) = ndi.ontology.EDAM.downloadAndParseEDAM();
            end
            terms = edamCache(cacheKey);
        end % function getTerms

        function terms = downloadAndParseEDAM()
            %DOWNLOADANDPARSEEDAM Download EDAM OWL and extract terms.
            %   Returns a struct array with fields: numeric_id, sub_prefix,
            %   name, definition, synonyms.

            terms = struct('numeric_id', {}, 'sub_prefix', {}, ...
                           'name', {}, 'definition', {}, 'synonyms', {});

            options = weboptions('Timeout', 60, 'ContentType', 'text');
            try
                owl_content = webread(ndi.ontology.EDAM.OWL_URL, options);
            catch ME
                error('ndi:ontology:EDAM:DownloadFailed', ...
                    'Failed to download EDAM OWL file: %s', ME.message);
            end

            % Extract owl:Class blocks with EDAM IRIs
            % Pattern: <owl:Class rdf:about="http://edamontology.org/{sub}_{id}">...</owl:Class>
            iri_base_escaped = regexptranslate('escape', ndi.ontology.EDAM.IRI_BASE);
            class_pattern = ['(?s)<owl:Class\s+rdf:about="' iri_base_escaped '([^"]+)">(.*?)</owl:Class>'];
            class_blocks = regexp(owl_content, class_pattern, 'tokens');

            for i = 1:numel(class_blocks)
                local_id = class_blocks{i}{1};   % e.g., 'format_1929'
                content  = class_blocks{i}{2};

                % Parse local_id into sub_prefix and numeric_id
                id_parts = regexp(local_id, '^(\w+)_(\d+)$', 'tokens', 'once');
                if isempty(id_parts)
                    continue;  % Skip non-standard IDs
                end
                sub_prefix = id_parts{1};
                numeric_id = id_parts{2};

                % Extract label
                label_match = regexp(content, '(?s)<rdfs:label[^>]*>([^<]+)</rdfs:label>', 'tokens', 'once');
                thisName = '';
                if ~isempty(label_match)
                    thisName = strtrim(ndi.ontology.EDAM.unescapeXML(label_match{1}));
                end

                % Skip deprecated terms (have owl:deprecated true)
                if contains(content, '>true<') && contains(content, 'deprecated')
                    continue;
                end

                % Extract definition
                thisDef = '';
                def_match = regexp(content, '(?s)<oboInOwl:hasDefinition[^>]*>.*?<rdfs:label[^>]*>([^<]+)</rdfs:label>.*?</oboInOwl:hasDefinition>', 'tokens', 'once');
                if isempty(def_match)
                    % Try alternative definition patterns
                    def_match = regexp(content, '(?s)<obo:IAO_0000115[^>]*>([^<]+)</obo:IAO_0000115>', 'tokens', 'once');
                end
                if ~isempty(def_match)
                    thisDef = strtrim(ndi.ontology.EDAM.unescapeXML(def_match{1}));
                end

                % Extract synonyms
                syn_matches = regexp(content, '(?s)<oboInOwl:has(?:Exact|Narrow|Related|Broad)Synonym[^>]*>([^<]+)</oboInOwl:has(?:Exact|Narrow|Related|Broad)Synonym>', 'tokens');
                thisSynonyms = {};
                if ~isempty(syn_matches)
                    thisSynonyms = cellfun(@(x) strtrim(ndi.ontology.EDAM.unescapeXML(x{1})), ...
                        syn_matches, 'UniformOutput', false);
                end

                % Add to terms array
                idx = numel(terms) + 1;
                terms(idx).numeric_id = numeric_id;
                terms(idx).sub_prefix = sub_prefix;
                terms(idx).name = thisName;
                terms(idx).definition = thisDef;
                terms(idx).synonyms = thisSynonyms;
            end
        end

        function str = unescapeXML(str)
            %UNESCAPEXML Handle common XML entities
            str = strrep(str, '&apos;', '''');
            str = strrep(str, '&quot;', '"');
            str = strrep(str, '&amp;', '&');
            str = strrep(str, '&lt;', '<');
            str = strrep(str, '&gt;', '>');
            str = strtrim(str);
        end
    end
end

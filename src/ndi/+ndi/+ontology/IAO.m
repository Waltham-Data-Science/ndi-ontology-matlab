% Location: +ndi/+ontology/IAO.m
classdef IAO < ndi.ontology
% IAO - NDI Ontology object for the Information Artifact Ontology (IAO).
%   Inherits from ndi.ontology and implements lookupTermOrID for IAO
%   by downloading and parsing the IAO OWL file from the OBO PURL system.
%
%   IAO IDs look like IAO:0000310 (for "document") or IAO:0000030 (for
%   "information content entity").  Both numeric ID and label-based lookups
%   are supported.
%
%   The OWL file is downloaded once per MATLAB session and the parsed term
%   map is cached in a persistent variable for fast subsequent lookups.

    methods
        function obj = IAO()
            % IAO - Constructor for the IAO ontology object.
        end % constructor

        function [id, name, definition, synonyms] = lookupTermOrID(obj, term_or_id_or_name)
            % LOOKUPTERMORID - Looks up a term in IAO by numeric ID or label.
            %
            %   [ID, NAME, DEFINITION, SYNONYMS] = lookupTermOrID(OBJ, TERM_OR_ID_OR_NAME)
            %
            %   TERM_OR_ID_OR_NAME is the part after the 'IAO:' prefix (e.g.,
            %   '0000310' or 'document').

            % Initialize outputs
            id = ''; name = ''; definition = ''; synonyms = {};

            fragment = strtrim(term_or_id_or_name);
            if isempty(fragment)
                error('ndi:ontology:IAO:EmptyInput', 'IAO lookup requires a non-empty term or ID.');
            end

            % Obtain the cached (or freshly downloaded + parsed) term maps.
            [by_id, by_name] = ndi.ontology.IAO.getTermMaps();

            % Determine lookup type: all-digit → numeric ID, otherwise label.
            is_numeric_id = ~isempty(regexp(fragment, '^\d+$', 'once'));

            if is_numeric_id
                lookup_key = ['IAO:' fragment];
                if isKey(by_id, lookup_key)
                    t = by_id(lookup_key);
                    id = t.id; name = t.name; definition = t.def; synonyms = t.syn;
                else
                    error('ndi:ontology:IAO:TermNotFound', ...
                        'IAO term with numeric ID "%s" not found.', fragment);
                end
            else
                % Case-insensitive label lookup
                lookup_key = lower(fragment);
                if isKey(by_name, lookup_key)
                    t = by_name(lookup_key);
                    id = t.id; name = t.name; definition = t.def; synonyms = t.syn;
                else
                    error('ndi:ontology:IAO:TermNotFound', ...
                        'IAO term with label "%s" not found.', fragment);
                end
            end

        end % function lookupTermOrID

    end % methods

    methods (Static, Access = private)

        function [by_id, by_name] = getTermMaps()
            % GETTTERMMAPS - Return (and build if necessary) the persistent term maps.
            %   BY_ID  : containers.Map  IAO:NNNNNN  → term struct
            %   BY_NAME: containers.Map  lower(label) → term struct
            persistent cached_by_id cached_by_name;

            if ~isempty(cached_by_id)
                by_id   = cached_by_id;
                by_name = cached_by_name;
                return;
            end

            % Download the IAO OWL file.
            owl_urls = { ...
                'http://purl.obolibrary.org/obo/iao.owl', ...
                'https://raw.githubusercontent.com/information-artifact-ontology/IAO/master/iao.owl' };

            owl_content = '';
            fetch_opts = weboptions('Timeout', 60, 'ContentType', 'text');
            for k = 1:numel(owl_urls)
                try
                    owl_content = webread(owl_urls{k}, fetch_opts);
                    if ~isempty(owl_content), break; end
                catch
                    % try next URL
                end
            end

            if isempty(owl_content)
                error('ndi:ontology:IAO:OWLFetchFailed', ...
                    'Failed to download the IAO OWL file from all known URLs.');
            end

            % Parse all IAO class terms from the OWL/XML content.
            [cached_by_id, cached_by_name] = ndi.ontology.IAO.parseAllTerms(owl_content);
            by_id   = cached_by_id;
            by_name = cached_by_name;
        end % function getTermMaps

        function [by_id, by_name] = parseAllTerms(xml_string)
            % PARSEALLLTERMS - Parse every owl:Class block for IAO_ terms.
            %   Returns two containers.Map objects for fast lookup.
            by_id   = containers.Map('KeyType','char','ValueType','any');
            by_name = containers.Map('KeyType','char','ValueType','any');

            % ---- Strategy 1: inline annotations inside <owl:Class> blocks ----
            % Matches:
            %   <owl:Class rdf:about="...IAO_NNNNNN..."> ... </owl:Class>
            class_blocks = regexp(xml_string, ...
                '(?s)<owl:Class\s+rdf:about=[''"]([^''"]*IAO_\d+[^''"]*)[''"]\s*>(.*?)</owl:Class>', ...
                'tokens');

            for i = 1:numel(class_blocks)
                about_url = class_blocks{i}{1};
                content   = class_blocks{i}{2};
                ndi.ontology.IAO.addTermFromContent(about_url, content, by_id, by_name);
            end

            % ---- Strategy 2: annotations in <rdf:Description> blocks ----
            % Matches:
            %   <rdf:Description rdf:about="...IAO_NNNNNN..."> ... </rdf:Description>
            desc_blocks = regexp(xml_string, ...
                '(?s)<rdf:Description\s+rdf:about=[''"]([^''"]*IAO_\d+[^''"]*)[''"]\s*>(.*?)</rdf:Description>', ...
                'tokens');

            for i = 1:numel(desc_blocks)
                about_url = desc_blocks{i}{1};
                content   = desc_blocks{i}{2};
                % Only process if there is a rdfs:label (skip bare declarations)
                if isempty(regexp(content, '<rdfs:label', 'once')), continue; end
                ndi.ontology.IAO.addTermFromContent(about_url, content, by_id, by_name);
            end
        end % function parseAllTerms

        function addTermFromContent(about_url, content, by_id, by_name)
            % ADDTERMFROMCONTENT - Extract term data from one XML block and store it.
            id_tok = regexp(about_url, 'IAO_(\d+)', 'tokens', 'once');
            if isempty(id_tok), return; end
            this_num = id_tok{1};

            label_tok = regexp(content, '(?s)<rdfs:label[^>]*>(.*?)</rdfs:label>', 'tokens', 'once');
            this_label = '';
            if ~isempty(label_tok)
                this_label = ndi.ontology.IAO.unescapeXML(label_tok{1});
            end
            if isempty(this_label), return; end  % skip anonymous / unlabelled terms

            full_id = ['IAO:' this_num];

            def_tok = regexp(content, '(?s)<obo:IAO_0000115[^>]*>(.*?)</obo:IAO_0000115>', 'tokens', 'once');
            this_def = '';
            if ~isempty(def_tok)
                this_def = ndi.ontology.IAO.unescapeXML(def_tok{1});
            end

            syn_toks = regexp(content, ...
                '(?s)<oboInOwl:has(?:Exact|Related)Synonym[^>]*>(.*?)</oboInOwl:has(?:Exact|Related)Synonym>', ...
                'tokens');
            this_syn = cellfun(@(x) ndi.ontology.IAO.unescapeXML(x{1}), syn_toks, 'UniformOutput', false);

            t = struct('id', full_id, 'name', this_label, 'def', this_def, 'syn', {this_syn});

            % Store (do not overwrite if already present — inline wins over rdf:Description)
            if ~isKey(by_id, full_id)
                by_id(full_id) = t;
            end
            name_key = lower(this_label);
            if ~isKey(by_name, name_key)
                by_name(name_key) = t;
            end
        end % function addTermFromContent

        function str = unescapeXML(str)
            % UNESCAPEXML - Replace common XML character entities.
            str = strrep(str, '&apos;', '''');
            str = strrep(str, '&quot;', '"');
            str = strrep(str, '&amp;',  '&');
            str = strrep(str, '&lt;',   '<');
            str = strrep(str, '&gt;',   '>');
            str = regexprep(str, '<[^>]*>', '');
            str = strtrim(str);
        end % function unescapeXML

    end % methods (Static, Access = private)

end % classdef IAO

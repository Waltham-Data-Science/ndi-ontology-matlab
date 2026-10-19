% Location: +ndi/+ontology/OM.m
classdef OM < ndi.ontology
% OM - NDI Ontology object for the Ontology of Units of Measure (OM).
%   Inherits from ndi.ontology and implements lookupTermOrID for OM.

    methods
        function obj = OM()
            % OM - Constructor for the OM ontology object.
            % Implicitly calls the superclass constructor ndi.ontology().
        end % constructor

        function [id, name, definition, synonyms] = lookupTermOrID(obj, term_or_id_or_name)
            % LOOKUPTERMORID - Looks up a unit, quantity or other OM entry by name/term.
            %
            %   [ID, NAME, DEFINITION, SYNONYMS] = lookupTermOrID(OBJ, TERM_OR_ID_OR_NAME)
            %
            %   The input TERM_OR_ID_OR_NAME is the part of the original lookup string
            %   after the 'OM:' prefix has been removed (e.g., 'metre', 'second-Time',
            %   'Temperature', 'metre per second').
            %
            %   OM's units are INDIVIDUALS (`om:metre` is an om:Unit, not a class),
            %   and the EBI OLS index holds only OM's classes, so a unit cannot be
            %   found there at all. This method therefore reads OM's own file first
            %   (ndi.ontology.OM.fileIndex, downloaded once per MATLAB session) and
            %   matches, in order: the identifier exactly, the identifier ignoring
            %   case, the English label, an English alternative label, and the
            %   camel-case heuristic ('MetrePerSecond' -> 'metre per second'). Only
            %   when OM's file cannot be read, or holds no match, does it fall back to
            %   the OLS search below, which finds classes such as 'MolarVolumeUnit'.
            %
            %   See also: ndi.ontology.lookup (static dispatcher),
            %             ndi.ontology.OM.fileIndex, ndi.ontology.OM.findInIndex

            % Define ontology specifics for OM
            ontology_prefix = 'OM';
            ontology_name_ols = 'om';

            % --- Step 0: OM's own file (units are individuals; OLS lacks them) ---
            term = strtrim(char(term_or_id_or_name));
            if isempty(regexp(term, '^\d+$', 'once'))
                idx = [];
                try
                    idx = ndi.ontology.OM.fileIndex();
                catch ME_file
                    warning('ndi:ontology:OM:FileUnavailable', ...
                        'Could not read OM''s file (%s); falling back to OLS.', ME_file.message);
                end
                if ~isempty(idx)
                    k = ndi.ontology.OM.findInIndex(idx, term);
                    if ~isempty(k)
                        id = [ontology_prefix ':' idx.local{k}];
                        name = idx.label{k};
                        definition = idx.definition{k};
                        synonyms = idx.alternative{k};
                        return;
                    end
                end
            end

            % --- Step 1: Preprocess Input using Base Class Static Helper ---
            % preprocessLookupInput contains OM-specific logic:
            % - Rejects numeric/prefixed-numeric IDs.
            % - Converts input term component to a likely label format.
            % - Sets search_field to 'label'.
            % - Sets search_query to the likely label format.
            try
                % Call static method using full class name qualification
                [search_query, search_field, lookup_type_msg, ~] = ...
                    ndi.ontology.preprocessLookupInput(term_or_id_or_name, ontology_prefix);
            catch ME
                baseME = MException('ndi:ontology:OM:PreprocessingError', ...
                     'Error preprocessing OM lookup input "%s".', term_or_id_or_name);
                baseME = addCause(baseME, ME);
                throw(baseME);
            end

            % --- Step 2: Perform Search and IRI Lookup using Base Class Static Helper ---
            % searchOLSAndPerformIRILookup handles non-exact label search + filtering
            % when search_field is 'label'.
            try
                % Call static method using full class name qualification
                [id, name, definition, synonyms] = ...
                    ndi.ontology.searchOLSAndPerformIRILookup(...
                        search_query, search_field, ontology_name_ols, ontology_prefix, lookup_type_msg);
            catch ME
                 baseME = MException('ndi:ontology:OM:LookupFailed', ...
                     'OM lookup failed for %s.', lookup_type_msg);
                 baseME = addCause(baseME, ME);
                 throw(baseME);
            end

        end % function lookupTermOrID

    end % methods

    properties (Constant)
        % OM's own file, the source of its units (individuals, not classes)
        RDF_URL = 'https://raw.githubusercontent.com/HajoRijgersberg/OM/master/om-2.0.rdf';
    end

    methods (Static)
        function idx = fileIndex(reset)
            % FILEINDEX - OM's entries, read from OM's own file once per session.
            %
            %   IDX = ndi.ontology.OM.fileIndex() downloads ndi.ontology.OM.RDF_URL
            %   on first use and returns its index (see parseRDF).
            %   ndi.ontology.OM.fileIndex(true) forgets it, so the next call
            %   downloads again.
            persistent cached
            if nargin > 0 && reset
                cached = [];
                idx = [];
                return;
            end
            if isempty(cached)
                options = weboptions('Timeout', 60, 'ContentType', 'text');
                cached = ndi.ontology.OM.parseRDF(webread(ndi.ontology.OM.RDF_URL, options));
            end
            idx = cached;
        end

        function idx = parseRDF(txt)
            % PARSERDF - Index every top-level entry of OM's RDF/XML file.
            %
            %   IDX = ndi.ontology.OM.parseRDF(TXT) returns a struct of parallel
            %   cell arrays, one element per OM identifier: local (the part after
            %   om-2/, e.g. 'metre', 'second-Time', 'Temperature'), label (the
            %   English rdfs:label), definition (the English rdfs:comment),
            %   alternative (English om:alternativeLabel values) and kind (the
            %   element, e.g. 'om:Unit', 'om:UnitDivision', 'owl:Class'). OM
            %   states one identifier in several top-level blocks (labels in one,
            %   the comment in another); they are merged.
            txt = char(txt);
            blocks = regexp(txt, '^  <([\w:]+) rdf:about="&om;([^"]+)">(.*?)^  </\1>', ...
                'tokens', 'lineanchors');
            local = {}; label = {}; definition = {}; alternative = {}; kind = {};
            where = containers.Map('KeyType', 'char', 'ValueType', 'double');
            for b = 1:numel(blocks)
                tag = blocks{b}{1}; loc = blocks{b}{2}; body = blocks{b}{3};
                if isKey(where, loc)
                    k = where(loc);
                else
                    k = numel(local) + 1;
                    where(loc) = k;
                    local{k} = loc; label{k} = ''; definition{k} = ''; %#ok<AGROW>
                    alternative{k} = {}; kind{k} = tag; %#ok<AGROW>
                end
                en = regexp(body, '<rdfs:label xml:lang="en">([^<]+)</rdfs:label>', 'tokens', 'once');
                if isempty(label{k}) && ~isempty(en), label{k} = strtrim(en{1}); end
                c = regexp(body, '<rdfs:comment xml:lang="en">([^<]+)</rdfs:comment>', 'tokens', 'once');
                if isempty(definition{k}) && ~isempty(c), definition{k} = strtrim(c{1}); end
                alt = regexp(body, '<om:alternativeLabel xml:lang="en">([^<]+)</om:alternativeLabel>', 'tokens');
                alternative{k} = unique([alternative{k}, cellfun(@(x) strtrim(x{1}), alt, ...
                    'UniformOutput', false)], 'stable');
            end
            idx = struct('local', {local}, 'label', {label}, 'definition', {definition}, ...
                'alternative', {alternative}, 'kind', {kind});
        end

        function k = findInIndex(idx, term)
            % FINDININDEX - The one entry TERM names, or [] if none or several.
            %
            %   Tried in order, the first rule that names exactly one entry
            %   wins: the identifier as written; the identifier ignoring case;
            %   the English label ignoring case; an English alternative label
            %   ignoring case; the camel-case heuristic ('MetrePerSecond' ->
            %   'metre per second') against the labels.
            k = [];
            term = strtrim(char(term));
            if isempty(term), return; end
            spaced = lower(strtrim(regexprep(term, '([a-z])([A-Z])', '$1 $2')));
            rules = { ...
                @() find(strcmp(idx.local, term)), ...
                @() find(strcmpi(idx.local, term)), ...
                @() find(strcmpi(idx.label, term)), ...
                @() find(cellfun(@(a) any(strcmpi(a, term)), idx.alternative)), ...
                @() find(strcmpi(idx.label, spaced))};
            for r = 1:numel(rules)
                hit = rules{r}();
                if isscalar(hit)
                    k = hit;
                    return;
                end
            end
        end
    end % methods (Static)

end % classdef OM
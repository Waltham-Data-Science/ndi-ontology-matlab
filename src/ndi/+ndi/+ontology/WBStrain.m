% Location: +ndi/+ontology/WBStrain.m
classdef WBStrain < ndi.ontology
% WBSTRAIN - NDI Ontology object for the WormBase Strain database.
%   Inherits from ndi.ontology and implements lookupTermOrID for WBStrain.
%
%   Strains are read from WormMine, the Alliance of Genome Resources'
%   InterMine copy of WormBase (https://wormmine.alliancegenome.org). The
%   WormBase site and REST API (wormbase.org, rest.wormbase.org) answer
%   programmatic requests with a Cloudflare browser challenge (HTTP 403),
%   so every lookup through them failed.
    methods
        function obj = WBStrain()
            % WBSTRAIN - Constructor for the WBStrain ontology object.
            % Implicitly calls the superclass constructor ndi.ontology().
        end % constructor
        function [id, name, definition, synonyms] = lookupTermOrID(obj, term_or_id_or_name)
            % LOOKUPTERMORID - Looks up a strain in WormBase by its ID or public name.
            %
            %   [ID, NAME, DEFINITION, SYNONYMS] = lookupTermOrID(OBJ, TERM_OR_ID_OR_NAME)
            %
            %   TERM_OR_ID_OR_NAME is the part after the prefix:
            %     'WBStrain:00000001'          an eight-digit ID
            %     'WBStrain:N2'                a strain name, matched ignoring case
            %     'wormbase:WBStrain00000001'  the Bioregistry CURIE (prefix
            %                                  `wormbase`; Bioregistry has no
            %                                  `wbstrain`)
            %   ID is in the form asked for: 'WBStrain:00000001' for the
            %   first two, 'wormbase:WBStrain00000001' for the third. NAME is
            %   the strain name, DEFINITION its genotype, mutagen and
            %   outcrossing, and SYNONYMS its other name, if it has one.

            prefix = 'WBStrain';
            term = strtrim(char(term_or_id_or_name));
            if contains(term, '*')
                error('ndi:ontology:WBStrain:InvalidInput', ...
                    'A strain name or ID cannot contain "*" ("%s").', term);
            end
            isCurie = ~isempty(regexp(term, ['^' prefix '\d{8}$'], 'once'));
            if isCurie
                term = term(numel(prefix)+1:end);
            elseif ~isempty(regexp(term, '^(CE\d{5}|WB[A-Z][a-z]+\d+)$', 'once'))
                % another kind of WormBase id, such as a gene (WBGene00000001)
                error('ndi:ontology:WBStrain:NotAStrain', ...
                    '"%s" is a WormBase id but not a strain id (WBStrain followed by eight digits).', term);
            end
            isIdLookup = ~isempty(regexp(term, '^\d{8}$', 'once'));
            if isIdLookup
                path = 'Strain.primaryIdentifier';
                value = [prefix term];
            else
                path = 'Strain.name';
                value = term;
            end

            try
                strains = ndi.ontology.WBStrain.queryWormMine(path, value);
            catch ME
                baseME = MException('ndi:ontology:WBStrain:APILookupFailed', ...
                    'The WormMine query for WormBase strain "%s" failed.', term);
                baseME = addCause(baseME, ME);
                throw(baseME);
            end

            if isempty(strains)
                if isIdLookup
                    error('ndi:ontology:WBStrain:IDNotFound', ...
                        'No WormBase strain has the ID "%s".', value);
                else
                    error('ndi:ontology:WBStrain:NameNotFound', ...
                        'No WormBase strain is named "%s".', term);
                end
            end
            if numel(strains) > 1
                error('ndi:ontology:WBStrain:NameNotUnique', ...
                    '%d WormBase strains match "%s"; use the WBStrain ID instead.', numel(strains), term);
            end

            [id, name, definition, synonyms] = ndi.ontology.WBStrain.parseStrain(strains(1));
            if isCurie
                id = ['wormbase:' strrep(id, ':', '')];
            end
            if ~isIdLookup && ~strcmpi(name, term)
                error('ndi:ontology:WBStrain:TermMismatch', ...
                    'WormMine returned strain "%s" for the name "%s". Try the WBStrain ID instead.', name, term);
            end
        end
    end

    methods (Static)
        function [id, name, definition, synonyms] = parseStrain(strain)
            % PARSESTRAIN - The lookup outputs for one WormMine strain record.
            %
            %   [ID, NAME, DEFINITION, SYNONYMS] = ndi.ontology.WBStrain.parseStrain(STRAIN)
            %
            %   STRAIN is one record of a WormMine 'jsonobjects' query, as
            %   decoded by webread: a struct with fields primaryIdentifier,
            %   name, genotype, otherName, mutagen and outcrossed, any of
            %   which may be empty. Public so the parsing can be tested
            %   without the network.
            prefix = 'WBStrain';
            field = @(f) ndi.ontology.WBStrain.textField(strain, f);

            wbId = field('primaryIdentifier');
            if isempty(regexp(wbId, ['^' prefix '\d{8}$'], 'once'))
                error('ndi:ontology:WBStrain:APIParsingFailed', ...
                    'WormMine returned a strain without a valid WBStrain ID ("%s").', wbId);
            end
            id = [prefix ':' wbId(numel(prefix)+1:end)];

            name = field('name');
            if isempty(name)
                error('ndi:ontology:WBStrain:APIParsingFailed', ...
                    'WormMine returned strain %s without a name.', id);
            end

            parts = {};
            if ~isempty(field('genotype')), parts{end+1} = ['Genotype: ' field('genotype')]; end
            if ~isempty(field('mutagen')), parts{end+1} = ['Mutagen: ' field('mutagen')]; end
            if ~isempty(field('outcrossed')), parts{end+1} = ['Outcrossed: ' field('outcrossed')]; end
            definition = strjoin(parts, '. ');
            definition = replace(definition, '..', '.');
            if ~isempty(definition) && ~endsWith(definition, '.')
                definition = [definition '.'];
            end

            synonyms = {};
            if ~isempty(field('otherName'))
                synonyms = {field('otherName')};
            end
        end % function parseStrain
    end % methods (Static)

    methods (Static, Access = private)
        function strains = queryWormMine(path, value)
            % QUERYWORMMINE - The WormMine strain records whose PATH equals VALUE.
            serviceUrl = 'https://wormmine.alliancegenome.org/wormmine/service/query/results';
            view = ['Strain.primaryIdentifier Strain.name Strain.genotype ' ...
                'Strain.otherName Strain.mutagen Strain.outcrossed'];
            query = sprintf(['<query model="genomic" view="%s">' ...
                '<constraint path="%s" op="=" value="%s"/></query>'], ...
                view, path, ndi.ontology.WBStrain.escapeXml(value));
            options = weboptions('Timeout', 30, 'ContentType', 'json');
            response = webread(serviceUrl, 'query', query, 'format', 'jsonobjects', options);
            if ~isstruct(response) || ~isfield(response, 'results')
                error('ndi:ontology:WBStrain:APIParsingFailed', ...
                    'WormMine returned an unexpected response.');
            end
            if isfield(response, 'wasSuccessful') && isequal(response.wasSuccessful, false)
                error('ndi:ontology:WBStrain:APILookupFailed', ...
                    'WormMine reported an error: %s', char(string(response.error)));
            end
            strains = response.results;
            if iscell(strains)
                % records whose fields differ decode as a cell array
                strains = [strains{:}];
            end
            if isempty(strains)
                strains = struct([]);
            end
        end % function queryWormMine

        function text = textField(s, f)
            % TEXTFIELD - Field F of struct S as a char row, '' when absent or null.
            text = '';
            if isfield(s, f) && ~isempty(s.(f))
                text = strtrim(char(string(s.(f))));
            end
        end % function textField

        function text = escapeXml(text)
            % ESCAPEXML - Escape a value for an XML attribute.
            text = strrep(text, '&', '&amp;');
            text = strrep(text, '<', '&lt;');
            text = strrep(text, '>', '&gt;');
            text = strrep(text, '"', '&quot;');
        end % function escapeXml
    end % methods (Static, Access = private)
end

% Location: +ndi/+ontology/SPDX.m
classdef SPDX < ndi.ontology
% SPDX - NDI Ontology object for the SPDX License List.
%   Inherits from ndi.ontology and implements lookupTermOrID for SPDX
%   licence identifiers, read from the SPDX License List's JSON files at
%   https://spdx.org/licenses/.
%
%   A dataset's licence is written as an SPDX CURIE, e.g. 'spdx:CC-BY-4.0'.
%   The prefix is matched case-insensitively ('spdx' or 'SPDX').
%
%   The part after the prefix may be a licence identifier ('CC-BY-4.0') or
%   a licence's full name ('Creative Commons Attribution 4.0 International').
%   An identifier is fetched directly from
%   https://spdx.org/licenses/<licenseId>.json. The server's file names are
%   case-sensitive while SPDX identifiers are not, so an identifier the
%   server does not know, and any full name, is resolved against the list
%   of all licences, https://spdx.org/licenses/licenses.json. The returned
%   ID always carries the canonical identifier, e.g. 'spdx:CC-BY-4.0'.
%
%   Usage example:
%       [id, name, ~, def] = ndi.ontology.lookup('spdx:CC-BY-4.0');

    properties (Constant, Access = private)
        BaseUrl = 'https://spdx.org/licenses/';
    end

    methods
        function obj = SPDX()
            % SPDX - Constructor for the SPDX ontology object.
        end % constructor

        function [id, name, definition, synonyms] = lookupTermOrID(obj, term_or_id_or_name)
            % LOOKUPTERMORID - Looks up an SPDX licence by identifier or name.
            %
            %   [ID, NAME, DEFINITION, SYNONYMS] = lookupTermOrID(OBJ, TERM_OR_ID_OR_NAME)
            %
            %   TERM_OR_ID_OR_NAME is the part of the original lookup string
            %   after the 'spdx:' prefix (e.g., 'CC-BY-4.0').
            arguments
                obj (1,1) ndi.ontology.SPDX %#ok<INUSA> (the lookup interface)
                term_or_id_or_name {mustBeText}
            end

            query = strtrim(char(term_or_id_or_name));
            if isempty(query)
                error('ndi:ontology:SPDX:EmptyInput', ...
                    'SPDX lookup requires a non-empty licence identifier or name.');
            end
            synonyms = {};

            % 1. A well-formed identifier is fetched directly.
            if ndi.ontology.SPDX.isLicenseIdSyntax(query)
                [json_str, found] = ndi.ontology.SPDX.fetch([query '.json'], query);
                if found
                    [id, name, definition] = ndi.ontology.SPDX.parseLicense(json_str);
                    return;
                end
            end

            % 2. Otherwise resolve it against the list of all licences: an
            %    identifier in another case, or a full licence name.
            [index_str, found] = ndi.ontology.SPDX.fetch('licenses.json', 'licenses.json');
            if ~found
                error('ndi:ontology:SPDX:APIError', ...
                    'The SPDX licence list could not be read from %slicenses.json.', ...
                    ndi.ontology.SPDX.BaseUrl);
            end
            entry = ndi.ontology.SPDX.findInIndex(index_str, query);
            if isempty(entry)
                error('ndi:ontology:SPDX:TermNotFound', ...
                    'SPDX licence "%s" not found.', query);
            end
            [id, name, definition] = ndi.ontology.SPDX.parseLicense(entry);
        end % function lookupTermOrID

    end % methods

    methods (Static)

        function [id, name, definition] = parseLicense(license)
            % PARSELICENSE - The ID, name and definition of an SPDX licence.
            %
            %   [ID, NAME, DEFINITION] = ndi.ontology.SPDX.parseLicense(LICENSE)
            %
            %   LICENSE is either the JSON text SPDX serves for one licence
            %   (https://spdx.org/licenses/<licenseId>.json) or the decoded
            %   struct of one entry of https://spdx.org/licenses/licenses.json;
            %   both carry licenseId, name and seeAlso.
            %
            %   ID is 'spdx:<licenseId>', NAME the licence's full name, and
            %   DEFINITION a sentence naming both, followed by the first
            %   seeAlso URL when there is one. Public so the parsing can be
            %   tested without the network.
            if ~isstruct(license)
                try
                    license = jsondecode(char(license));
                catch ME
                    baseME = MException('ndi:ontology:SPDX:ParseError', ...
                        'The SPDX response is not valid JSON.');
                    baseME = addCause(baseME, ME);
                    throw(baseME);
                end
            end
            if ~isstruct(license) || ~isfield(license, 'licenseId') || ...
                    isempty(license.licenseId)
                error('ndi:ontology:SPDX:ParseError', ...
                    'The SPDX response carries no licenseId.');
            end
            license_id = char(license.licenseId);
            id = ['spdx:' license_id];

            name = license_id;   % safe fallback
            if isfield(license, 'name') && ~isempty(license.name)
                name = char(license.name);
            end

            definition = sprintf('SPDX licence %s: %s.', license_id, name);
            if isfield(license, 'isDeprecatedLicenseId') && ...
                    islogical(license.isDeprecatedLicenseId) && license.isDeprecatedLicenseId
                definition = [definition ' This SPDX identifier is deprecated.'];
            end
            url = ndi.ontology.SPDX.firstSeeAlso(license);
            if ~isempty(url)
                definition = [definition ' See ' url];
            end
        end % function parseLicense

        function entry = findInIndex(index, query)
            % FINDININDEX - The entry of the SPDX licence list matching QUERY.
            %
            %   ENTRY = ndi.ontology.SPDX.findInIndex(INDEX, QUERY)
            %
            %   INDEX is the JSON text (or its decoded struct) of
            %   https://spdx.org/licenses/licenses.json. QUERY is matched
            %   case-insensitively, first against each licenseId and then
            %   against each full name. ENTRY is the matching entry, or []
            %   if there is none. Public so it can be tested offline.
            entry = [];
            if ~isstruct(index)
                index = jsondecode(char(index));
            end
            if ~isfield(index, 'licenses'), return; end
            licenses = index.licenses;
            if isstruct(licenses)
                licenses = num2cell(licenses);
            end
            query = strtrim(char(query));
            for field = {'licenseId', 'name'}
                for k = 1:numel(licenses)
                    item = licenses{k};
                    if isstruct(item) && isfield(item, field{1}) && ...
                            strcmpi(char(item.(field{1})), query)
                        entry = item;
                        return;
                    end
                end
            end
        end % function findInIndex

    end % methods (Static)

    methods (Static, Access = private)

        function tf = isLicenseIdSyntax(s)
            % ISLICENSEIDSYNTAX - True if S is shaped like an SPDX licence
            %   identifier: letters, digits, '.', '-' and '+' only.
            tf = ~isempty(regexp(s, '^[A-Za-z0-9.+\-]+$', 'once'));
        end

        function [body, found] = fetch(file, what)
            % FETCH - Read https://spdx.org/licenses/<FILE> as text.
            %   FOUND is false on HTTP 404; any other failure is an error.
            body = '';
            found = false;
            opts = weboptions('Timeout', 30, 'ContentType', 'text');
            try
                body = webread([ndi.ontology.SPDX.BaseUrl file], opts);
                found = true;
            catch ME
                if contains(ME.message, '404') || contains(ME.message, 'Not Found')
                    return;
                end
                baseME = MException('ndi:ontology:SPDX:APIError', ...
                    'Failed to fetch SPDX licence "%s".', what);
                baseME = addCause(baseME, ME);
                throw(baseME);
            end
        end

        function url = firstSeeAlso(license)
            % FIRSTSEEALSO - The first seeAlso URL of a licence, or ''.
            url = '';
            if ~isfield(license, 'seeAlso'), return; end
            v = license.seeAlso;
            if iscell(v) && ~isempty(v)
                v = v{1};
            elseif isstring(v) && ~isempty(v)
                v = v(1);
            end
            if (ischar(v) || isstring(v)) && strlength(v) > 0
                url = char(strtrim(v));
            end
        end

    end % methods (Static, Access = private)

end % classdef SPDX

% Location: +ndi/+ontology/CREDIT.m
classdef CREDIT < ndi.ontology
% CREDIT - NDI Ontology object for the CRediT contributor roles.
%   The 14 roles of CRediT, the Contributor Roles Taxonomy (ANSI/NISO
%   Z39.104-2022), identified as Bioregistry's `credit` prefix does: by the
%   role's slug, e.g. credit:conceptualization, which resolves to
%   https://credit.niso.org/contributor-roles/conceptualization/.
%
%   The roles are a fixed list set by the standard, and no lookup service
%   indexes these identifiers (OLS holds only an older numbering, CREDIT_00000001
%   ... CREDIT_00000014, inside the Contributor Role Ontology), so the names and
%   definitions are held here, as published on credit.niso.org (read
%   2026-10-19). That older numbering is accepted as an alias.

    properties (Constant)
        % slug, name, definition (credit.niso.org), in the standard's order;
        % row k is CRO's CREDIT_0000000k
        ROLES = { ...
                'conceptualization', 'Conceptualization', 'Ideas; formulation or evolution of overarching research goals and aims.';
                'data-curation', 'Data curation', 'Management activities to annotate (produce metadata), scrub data and maintain research data (including software code, where it is necessary for interpreting the data itself) for initial use and later re-use.';
                'formal-analysis', 'Formal analysis', 'Application of statistical, mathematical, computational, or other formal techniques to analyse or synthesize study data.';
                'funding-acquisition', 'Funding acquisition', 'Acquisition of the financial support for the project leading to this publication.';
                'investigation', 'Investigation', 'Conducting a research and investigation process, specifically performing the experiments, or data/evidence collection.';
                'methodology', 'Methodology', 'Development or design of methodology; creation of models.';
                'project-administration', 'Project administration', 'Management and coordination responsibility for the research activity planning and execution.';
                'resources', 'Resources', 'Provision of study materials, reagents, materials, patients, laboratory samples, animals, instrumentation, computing resources, or other analysis tools.';
                'software', 'Software', 'Programming, software development; designing computer programs; implementation of the computer code and supporting algorithms; testing of existing code components.';
                'supervision', 'Supervision', 'Oversight and leadership responsibility for the research activity planning and execution, including mentorship external to the core team.';
                'validation', 'Validation', 'Verification, whether as a part of the activity or separate, of the overall replication/reproducibility of results/experiments and other research outputs.';
                'visualization', 'Visualization', 'Preparation, creation and/or presentation of the published work, specifically visualization/data presentation.';
                'writing-original-draft', 'Writing – original draft', 'Preparation, creation and/or presentation of the published work, specifically writing the initial draft (including substantive translation).';
                'writing-review-editing', 'Writing – review & editing', 'Preparation, creation and/or presentation of the published work by those from the original research group, specifically critical review, commentary or revision – including pre- or post-publication stages.'};
    end

    methods
        function obj = CREDIT()
            % CREDIT - Constructor for the CREDIT ontology object.
        end % constructor

        function [id, name, definition, synonyms] = lookupTermOrID(~, term_or_id_or_name)
            % LOOKUPTERMORID - Looks up a CRediT role by slug, name or number.
            %
            %   [ID, NAME, DEFINITION, SYNONYMS] = lookupTermOrID(OBJ, TERM)
            %
            %   TERM is the part after the 'credit:' prefix. It may be the slug
            %   ('writing-review-editing'), the role's name in any of its usual
            %   spellings ('Writing - review & editing', 'writing review and
            %   editing role'), or CRO's number ('00000014', '14'). ID is always
            %   'credit:<slug>'; SYNONYMS holds CRO's identifier for the role.
            k = ndi.ontology.CREDIT.find(term_or_id_or_name);
            if isempty(k)
                error('ndi:ontology:CREDIT:LookupFailed', ...
                    'CREDIT lookup failed: "%s" is not one of the 14 CRediT roles.', ...
                    char(term_or_id_or_name));
            end
            R = ndi.ontology.CREDIT.ROLES;
            id = ['credit:' R{k, 1}];
            name = R{k, 2};
            definition = R{k, 3};
            synonyms = {sprintf('CREDIT:%08d', k)};
        end % function lookupTermOrID
    end % methods

    methods (Static)
        function k = find(term)
            % FIND - The row of ROLES that TERM names, or [] if none.
            R = ndi.ontology.CREDIT.ROLES;
            term = strtrim(char(term));
            k = [];
            if isempty(term), return; end
            n = regexp(term, '^(?:CREDIT[_:])?0*(\d{1,2})$', 'tokens', 'once', 'ignorecase');
            if ~isempty(n)
                v = str2double(n{1});
                if v >= 1 && v <= size(R, 1), k = v; end
                return;
            end
            key = ndi.ontology.CREDIT.normalise(term);
            for r = 1:size(R, 1)
                if strcmp(key, ndi.ontology.CREDIT.normalise(R{r, 1})) || ...
                        strcmp(key, ndi.ontology.CREDIT.normalise(R{r, 2}))
                    k = r;
                    return;
                end
            end
        end

        function s = normalise(s)
            % NORMALISE - Lower case, words only: dashes, '&', 'and' and a
            % trailing 'role' do not distinguish one role from another.
            s = lower(char(s));
            s = regexprep(s, '[^a-z]+', ' ');
            words = strsplit(strtrim(s), ' ');
            words = words(~ismember(words, {'and', ''}));
            if ~isempty(words) && strcmp(words{end}, 'role'), words(end) = []; end
            s = strjoin(words, ' ');
        end
    end % methods (Static)

end % classdef CREDIT

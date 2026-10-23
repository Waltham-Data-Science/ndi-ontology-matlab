% Location: +ndi/+ontology/OWL.m
classdef OWL < ndi.ontology
% OWL - NDI Ontology object for OWL 2, the W3C Web Ontology Language (https://www.w3.org/TR/owl2-overview/):
%   the OWL vocabulary used to relate individuals, classes and properties
%   to one another, such as owl:sameAs, and the classes owl:Thing and
%   owl:Nothing. The text is the rdfs:comment of each term in the OWL 2
%   file at http://www.w3.org/2002/07/owl (read 2026-10-23).
%   A term is identified as the vocabulary names it, owl:<localName>, which
%   resolves to http://www.w3.org/2002/07/owl#<localName>.
%
%   OWL is a W3C vocabulary, not an OBO ontology, and NDI uses a fixed few of
%   its terms, so the names and definitions are held here (as ndi.ontology.OWLTime
%   holds the OWL-Time interval relations).

    properties (Constant)
        % local name (also the rdfs:label), definition
        TERMS = { ...
                'sameAs', 'The property that determines that two given individuals are equal.';
                'differentFrom', 'The property that determines that two given individuals are different.';
                'equivalentClass', 'The property that determines that two given classes are equivalent, and that is used to specify datatype definitions.';
                'equivalentProperty', 'The property that determines that two given properties are equivalent.';
                'inverseOf', 'The property that determines that two given properties are inverse.';
                'Thing', 'The class of OWL individuals.';
                'Nothing', 'This is the empty class.'};
    end

    methods
        function obj = OWL()
            % OWL - Constructor for the OWL ontology object.
        end % constructor

        function [id, name, definition, synonyms] = lookupTermOrID(obj, term_or_id_or_name)
            % LOOKUPTERMORID - Looks up a OWL term by local name.
            %
            %   [ID, NAME, DEFINITION, SYNONYMS] = lookupTermOrID(OBJ, TERM)
            %
            %   TERM is the part after the 'owl:' prefix: the local name
            %   ('sameAs'), in any case, with or without spaces or underscores
            %   ('same as'). ID is always 'owl:<localName>'; NAME is the
            %   rdfs:label (the local name); SYNONYMS holds the terms IRI.
            arguments
                obj (1,1) ndi.ontology.OWL %#ok<INUSA> (the lookup interface)
                term_or_id_or_name {mustBeText}
            end
            k = ndi.ontology.OWL.find(term_or_id_or_name);
            if isempty(k)
                error('ndi:ontology:OWL:LookupFailed', ...
                    'OWL lookup failed: "%s" is not one of the OWL terms NDI holds.', ...
                    char(term_or_id_or_name));
            end
            T = ndi.ontology.OWL.TERMS;
            id = ['owl:' T{k, 1}];
            name = T{k, 1};
            definition = T{k, 2};
            synonyms = {['http://www.w3.org/2002/07/owl#' T{k, 1}]};
        end % function lookupTermOrID
    end % methods

    methods (Static)
        function k = find(term)
            % FIND - The row of TERMS that TERM names, or [] if none.
            %   Case, spaces and underscores do not distinguish one term
            %   from another, so 'sameAs', 'same as' and
            %   'SAME_AS' are the same term.
            arguments
                term {mustBeText}
            end
            T = ndi.ontology.OWL.TERMS;
            key = regexprep(lower(strtrim(char(term))), '[\s_]+', '');
            k = [];
            if isempty(key), return; end
            for r = 1:size(T, 1)
                if strcmpi(key, T{r, 1})
                    k = r;
                    return;
                end
            end
        end
    end % methods (Static)

end % classdef OWL

# ndi-ontology-matlab

MATLAB implementation of the `ndi.ontology` class and its subclasses, providing a unified interface for looking up terms across biological and scientific ontologies.

This package is part of the [NDI (Neuroscience Data Interface)](https://ndi.vhlab.org) ecosystem. Full documentation is available at **[ndi.vhlab.org](https://ndi.vhlab.org)**.

## Supported Ontologies

| Prefix | Ontology |
|--------|----------|
| `CL` | [Cell Ontology](http://obofoundry.org/ontology/cl.html) |
| `UBERON` | [Uberon Multi-Species Anatomy Ontology](http://obofoundry.org/ontology/uberon.html) |
| `CHEBI` | [Chemical Entities of Biological Interest](https://www.ebi.ac.uk/chebi/) |
| `PATO` | [Phenotype and Trait Ontology](http://obofoundry.org/ontology/pato.html) |
| `NCBITaxon` / `taxonomy` | [NCBI Taxonomy](https://www.ncbi.nlm.nih.gov/taxonomy) |
| `NCIm` | [NCI Metathesaurus](https://ncim.nci.nih.gov/ncimbrowser/) |
| `NCIT` | [NCI Thesaurus](http://obofoundry.org/ontology/ncit.html) |
| `OM` | [Ontology of Units of Measure](http://obofoundry.org/ontology/om.html) |
| `PubChem` | [PubChem](https://pubchem.ncbi.nlm.nih.gov/) |
| `RRID` | [Research Resource Identifiers](https://scicrunch.org/resources) |
| `SNOMED` / `SNOMEDCT` | [SNOMED CT](https://www.snomed.org/) |
| `EFO` | [Experimental Factor Ontology](https://www.ebi.ac.uk/efo/) |
| `EDAM` / `format` | [EDAM Bioinformatics Ontology](http://edamontology.org) |
| `EMPTY` | [Experimental Measurements, Purposes, and Treatments ontologY](https://github.com/Waltham-Data-Science/empty-ontology) |
| `NDIC` | NDI Controlled Vocabulary (local) |
| `WBStrain` / `wormbase` | [WormBase](https://wormbase.org) strains, read from [WormMine](https://wormmine.alliancegenome.org) |
| `STATO` | [Statistics Ontology](http://stato-ontology.org/) |
| `RO` | [Relation Ontology](http://obofoundry.org/ontology/ro.html) (relations, served by OLS as properties) |
| `BFO` | [Basic Formal Ontology](http://obofoundry.org/ontology/bfo.html); BFO relations such as `BFO:0000050` (part of) are read from RO |
| `COB` | [Core Ontology for Biology and Biomedicine](http://obofoundry.org/ontology/cob.html) |
| `XCO` | [Experimental Condition Ontology](http://obofoundry.org/ontology/xco.html) |
| `BAO` | [BioAssay Ontology](http://www.bioassayontology.org/) |
| `GO` | [Gene Ontology](http://obofoundry.org/ontology/go.html) |
| `ENVO` | [Environment Ontology](http://obofoundry.org/ontology/envo.html) |
| `SIO` | [Semanticscience Integrated Ontology](https://github.com/MaastrichtU-IDS/semanticscience), e.g. `SIO:000497` |
| `UO` | [Units of Measurement Ontology](http://obofoundry.org/ontology/uo.html) |
| `prov` | [PROV-O](https://www.w3.org/TR/prov-o/), e.g. `prov:wasDerivedFrom` (local table of PROV-O's core terms) |
| `owl` | [OWL 2](https://www.w3.org/TR/owl2-overview/), e.g. `owl:sameAs` (local table) |
| `spdx` | [SPDX License List](https://spdx.org/licenses/), e.g. `spdx:CC-BY-4.0` (identifier or full licence name) |
| `ILX` / `interlex` | [InterLex](https://scicrunch.org/scicrunch/interlex/dashboard), e.g. `ILX:0739413`, read from each term's public JSON-LD record (`http://uri.interlex.org/base/ilx_<n>.jsonld`; the SciCrunch API needs a key). IDs only |
| `wikidata` | [Wikidata](https://www.wikidata.org) items, e.g. `wikidata:Q30`, via the public `wbgetentities` API (ID or English label) |
| `AFO` | [Allotrope Foundation Ontology](https://www.allotrope.org) (served by [OLS4](https://www.ebi.ac.uk/ols4/ontologies/afo)), e.g. `AFO:AFR_0001158` (acquisition time); the IRI namespace is chosen by the ID prefix (`AFR_` -> `result#`, `AFE_` -> `equipment#`, ...) |
| `CMO` | [Clinical Measurement Ontology](http://obofoundry.org/ontology/cmo.html), e.g. `CMO:0001044` (percent of time spent in voluntary immobility) |
| `MMO` | [Measurement Method Ontology](http://obofoundry.org/ontology/mmo.html), e.g. `MMO:0000572` (contextual fear conditioning test) |

## Key Concepts: ID (Node) vs. Name (Label)

The main function `ndi.ontology.lookup` always returns two key values: an **ID** and a **NAME**.

- **ID** (the "node"): The canonical, unique identifier for a concept in the ontology. This is the string you would store in data or use in code to unambiguously reference the term.
- **NAME** (the "label"): The human-readable label that describes the concept. This is what a person would say or read.

Different ontologies represent their nodes in different ways, but `lookup` provides a consistent interface across all of them:

### Numbered-node ontologies (CL, UBERON, CHEBI, PATO, EMPTY, NCIT, EFO, ...)

Most formal ontologies assign each concept a **numeric code** as its node identifier, with a separate human-readable label. For example, the Cell Ontology assigns the concept of "neuron" the code `CL:0000540`.

```
  Input: 'CL:0000540'  or  'CL:neuron'    (you can use either)
  ─────────────────────────────────────
  id   = 'CL:0000540'     ← the numbered node (always returned in canonical form)
  name = 'neuron'          ← the human-readable label for that node
```

### Term-style ontologies (OM)

Some ontologies use **descriptive terms** as their node identifiers rather than numeric codes. In the Ontology of Units of Measure (OM), for example, the node for temperature is `OM:Temperature` — the node itself is human-readable.

```
  Input: 'OM:Temperature'  or  'OM:temperature'   (case-insensitive)
  ─────────────────────────────────────────────
  id   = 'OM:Temperature'   ← the term-style node (canonical casing)
  name = 'temperature'      ← normalized lowercase label
```

### External database lookups (PubChem, NCIm, NCBITaxon, RRID, NDIC, ...)

For external databases, the returned ID uses the **source database's native identifier** (e.g., a PubChem CID number or an NCI concept code). The lookup prefix may not appear in the returned ID.

```
  Input: 'PubChem:Aspirin'  or  'PubChem:2244'
  ─────────────────────────────────────────────
  id   = '2244'        ← PubChem compound ID (CID)
  name = 'aspirin'     ← compound name

  Input: 'NCIm:C0018787'
  ───────────────────────
  id   = 'C0018787'    ← NCI Metathesaurus concept code
  name = 'Heart'       ← concept name
```

**In all cases**, you can look up by ID or by name — the function figures out which you provided and returns both.

## Usage

```matlab
% Add this toolbox to the MATLAB path
addpath(genpath('src'));

% --- Numbered-node ontologies ---
% Look up by numeric ID
[id, name, prefix, def, syn] = ndi.ontology.lookup('CL:0000540');
% id = 'CL:0000540', name = 'neuron'

% Look up by name (resolves to the numbered node)
[id, name, prefix, def, syn] = ndi.ontology.lookup('CL:neuron');
% id = 'CL:0000540', name = 'neuron'

% Another example: anatomy
[id, name, prefix, def, syn] = ndi.ontology.lookup('UBERON:heart');
% id = 'UBERON:0000948', name = 'heart'

% Phenotype
[id, name] = ndi.ontology.lookup('PATO:female');
% id = 'PATO:0000383', name = 'female'

% --- Term-style ontologies ---
[id, name] = ndi.ontology.lookup('OM:Temperature');
% id = 'OM:Temperature', name = 'temperature'

[id, name] = ndi.ontology.lookup('OM:temperature');
% id = 'OM:Temperature', name = 'temperature'  (case is normalized)

% --- External databases ---
[id, name, prefix, def, syn] = ndi.ontology.lookup('NCBITaxon:9606');
% id = 'NCBITaxon:9606', name = 'Homo sapiens'

[id, name] = ndi.ontology.lookup('PubChem:Aspirin');
% id = '2244', name = 'aspirin'

[id, name, prefix, def, syn] = ndi.ontology.lookup('CHEBI:15377');
% id = 'CHEBI:15377', name = 'water'

% --- Local controlled vocabulary ---
[id, name] = ndi.ontology.lookup('NDIC:postnatal day');
% id = '11', name = 'Postnatal day'

% Clear the lookup cache
ndi.ontology.clearCache();
```

## Repository Structure

```
src/ndi/
  +ndi/
    ontology.m              % Base class and static dispatcher
    +ontology/              % Ontology-specific subclasses
      CHEBI.m, CL.m, EDAM.m, EFO.m, EMPTY.m,
      IAO.m, NCBITaxon.m, NCIT.m, NCIm.m, NDIC.m,
      InterLex.m, OM.m, PATO.m, PubChem.m, RRID.m, SchemaOrg.m, SPDX.m, Wikidata.m,
      SNOMED.m, SNOMEDCT.m, STATO.m, Uberon.m, WormBase.m,
      RO.m, BFO.m, COB.m, XCO.m, BAO.m, GO.m, ENVO.m, SIO.m, UO.m,
      PROV.m, OWL.m, AFO.m, CMO.m, MMO.m
    +common/
      PathConstants.m       % Path constants
    +fun/
      name2variableName.m   % String utility
    toolboxdir.m            % Toolbox root finder
  ndi_common/
    ontology/
      ontology_list.json    % Prefix-to-class mappings
    controlled_vocabulary/
      NDIC.txt              % NDI controlled vocabulary data

tests/+ndi/+unittest/+ontology/
  TestOntologyLookup.m      % Parameterized unit tests
  ontology_lookup_tests.json % Test case definitions

tools/
  +nditools/projectdir.m   % Project root utility
  tasks/testToolbox.m      % Test runner entry point
```

## Running Tests

Tests use the [MatBox](https://github.com/ehennestad/matbox) framework.

```matlab
addpath(genpath('src'));
addpath(genpath('tests'));
addpath(genpath('tools'));
testToolbox()
```

Tests require an active internet connection to query external ontology APIs (OLS, NCBI, PubChem, etc.).

## Documentation

Full NDI documentation: **[ndi.vhlab.org](https://ndi.vhlab.org)**

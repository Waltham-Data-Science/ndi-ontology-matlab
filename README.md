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
| `SNOMED` | [SNOMED CT](https://www.snomed.org/) |
| `EFO` | [Experimental Factor Ontology](https://www.ebi.ac.uk/efo/) |
| `EDAM` / `format` | [EDAM Bioinformatics Ontology](http://edamontology.org) |
| `EMPTY` | [Experimental Measurements, Purposes, and Treatments ontologY](https://github.com/Waltham-Data-Science/empty-ontology) |
| `NDIC` | NDI Controlled Vocabulary (local) |
| `WBStrain` | [WormBase Strain Database](https://wormbase.org) |

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
      NCBITaxon.m, NCIT.m, NCIm.m, NDIC.m, OM.m,
      PATO.m, PubChem.m, RRID.m, SNOMED.m,
      Uberon.m, WBStrain.m
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

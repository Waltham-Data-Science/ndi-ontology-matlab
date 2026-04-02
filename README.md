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

## Usage

```matlab
% Add this toolbox to the MATLAB path
addpath(genpath('src'));

% Look up a cell type by ID
[id, name, prefix, def, syn] = ndi.ontology.lookup('CL:0000540');
% id = 'CL:0000540', name = 'neuron'

% Look up by name
[id, name, prefix, def, syn] = ndi.ontology.lookup('UBERON:heart');
% id = 'UBERON:0000948', name = 'heart'

% Look up a species
[id, name, prefix, def, syn] = ndi.ontology.lookup('NCBITaxon:9606');
% id = 'NCBITaxon:9606', name = 'Homo sapiens'

% Look up a chemical
[id, name, prefix, def, syn] = ndi.ontology.lookup('CHEBI:15377');
% id = 'CHEBI:15377', name = 'water'

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

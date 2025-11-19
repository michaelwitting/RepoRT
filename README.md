# RepoRT

[![DOI](https://zenodo.org/badge/1023557814.svg)](https://doi.org/10.5281/zenodo.16267767)

> [!NOTE]
> A new web app has been launched making submission much easier: <https://rrt.boeckerlab.uni-jena.de/>

*RepoRT* is a repository dedicated to the collection of training data
for the development of new retention time prediction models for the
identification of small molecules. It is part of the collaborative
project between Prof. Dr. Sebastian Böcker
(Friedrich-Schiller-Universität Jena) and Dr. Michael Witting (Helmholtz
Zentrum München) fundend by the DFG (Project Number 425789784, [DFG
GEPRIS](https://gepris.dfg.de/gepris/projekt/425789784?language=en)).

We are collecting information such as retention time (RT) and chemical
structures of small molecules in standardized format. From the input
data structures are standardized using the PubChem standardization and
molecular fingerprints and chemical descriptors are calculated using
rcdk. Classification of molecules is performed using ClassyFire.
Additionally, to chemical information on the measured small molecules,
metadata on the chromatographic separation is collected, e.g. column,
column dimensions, flow rate, gradient, eluents and their exact
composition. The exact format is explained [here](DataDescription.md).

We are covering all possible separation modes of liquid chromatograpy
(LC), such as Reversed-phase (RP), Hydrophilic iinteraction Liquid
Chromatography (HILIC) and others. The plot below show the current
coverage of different separation modes and columns.

## Citation

F. Kretschmer, E.-M. Harrieder, M.  A. Hoffmann, S. Böcker, and M. Witting, 
[RepoRT: a comprehensive repository for small molecule retention times](https://doi.org/10.1038/s41592-023-02143-z). 
*Nat Methods* 21(2):153-155, 2024.

# Contributing data

We are welcoming data submissions. Please submit using the web app at <https://rrt.boeckerlab.uni-jena.de/>

# Contributors

The following people and resources contributed training data for this
repository.

## Collections:

-   [PredRet](http://predret.org/)
-   [Phenome Centre](https://github.com/phenomecentre/npc-open-lcms)

## Publications:

-   [J. Folberth et al.](https://doi.org/10.1016/j.jchromb.2020.122105)
-   [J. Pezzatti et al.](https://doi.org/10.1016/j.chroma.2019.01.023)
-   [X. Domingo-Almenara et al.](https://doi.org/10.1038/s41467-019-13680-7)
-   [R. Stoffel et al.](https://doi.org/10.1007/s00216-021-03828-0)

## People:

-   Serge Rudaz, University of Geneva
-   Eva-Maria Harrieder, Helmholtz Munich
-   Carolin Huber, UFZ
-   Maria Eugenia Monge, CIBION-CONICET
-   Jörg Büscher, Max Plank Institute of Immunobiology and Epigenetics
-   Aneli Kruve, Stockholm University

# Notes on usage

On October 24, 2023 Git LFS was disabled for the majority of the contents of RepoRT for better traceability of changes.
If you still have a version of RepoRT from before that date, it might be necessary to ["force-pull" the repository](https://stackoverflow.com/a/8888015).
Alternatively, simply clone/download the repository again, if experiencing difficulties.
A mapping from old to new commit hashes is available [here](https://github.com/michaelwitting/RepoRT/blob/master/resources/migration_commit_mapping.tsv).

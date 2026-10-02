# Individual mangrove trees provide alternative reef fish habitat on backreefs
### R code and data for the publication 'Individual mangrove trees provide alternative reef fish habitat on backreefs' 

##### Publication link: https://www.nature.com/articles/s41598-024-69524-y
##### DOI: 10.1038/s41598-024-69524-y

##### Hannah von Hammerstein <sup>1,2,3*</sup>, Theresa-Marie Fett <sup>1,2</sup>, Sebastian CA Ferse <sup>1,2,4,7</sup>, Véronique Helfer <sup>2</sup>, Stuart Kininmonth <sup>5,6</sup>, Sonia Bejarano <sup>2</sup>
###### <sup>1</sup> Faculty of Biology and Chemistry (FB2), University of Bremen, Bibliothekstraße 1, 28359 Bremen, Germany
###### <sup>2</sup> Leibniz Centre for Tropical Marine Research (ZMT), Fahrenheitstraße 6, 28359, Bremen, Germany
###### <sup>3</sup> Department of Geography & Environment, University of Hawai’i at Mānoa, Honolulu, 96822, Hawai’i, USA
###### <sup>4</sup> present address: Faculty of Fisheries and Marine Sciences, Bogor Agricultural University (IPB), Jl. Agatis 1, 16680 Bogor, Indonesia
###### <sup>5</sup> School of Marine Studies, The University of the South Pacific, Suva, Fiji
###### <sup>6</sup> Heron Island Research Station, The University of Queensland, Australia
###### <sup>7</sup> Marine Ecology Department, Faculty of Biology and Chemistry, University of Bremen, Leobener Strasse, 28359, Bremen, Germany

##### Mangrove trees occur in a variety of geomorphic and sedimentary settings. Yet, studies investigating their role as habitat providers often focus on the most common biophysical types, such as deltaic, estuarine, open coast or lagoonal mangroves on soft sediments, disregarding less typical environments. Here, we investigated the influence of individual mangrove trees growing on a consolidated backreef system (Laucala Bay, Fiji) on habitat use by reef fishes. Combining field surveys and an experiment, we quantified the extent to which reef mangrove trees serve as habitat for solitary or shoaling reef fishes. Using mangrove tree mimics, we disentangled effects attributable to the physical structure of trees from those related to their bio-chemical properties. We found that fish numbers were 3.7 times higher within close proximity to the mangrove trees than at control sites and correlated significantly with root system perimeter. The roots of larger trees sheltered aggregations of juveniles and adults at incoming and high tides. Mangrove trees and mimics attracted fishes alike. We show that mangrove trees on backreefs provide habitat for shoaling and adult reef fishes in addition to serving as nursery areas, an ecosystem service otherwise lacking on backreef areas with low structural complexity.

### Reproducing the analysis
Open the repo in VS Code and choose **Reopen in Container** (or use GitHub Codespaces). The [devcontainer](.devcontainer/) builds on [Rocker](https://rocker-project.org/) (R 4.5) and runs `renv::restore()` to install the exact package versions recorded in [`renv.lock`](renv.lock). Outside a container, run `renv::restore()` from the repo root.

Run everything from the repo root (so `.Rprofile` activates the renv library):

```sh
Rscript run_all.R
```

This runs each script in `R code/` in a fresh R session and writes its console output (`.txt`) and figures (`.pdf`) to `output/`, along with `sessionInfo.txt`. Scripts can also be run individually from the repo root.

Notes:
- The scripts originally sourced `HighstatLibV7.R` (Zuur et al., Highland Statistics Ltd), which is copyrighted and not included. Its only use, `panel.cor()` in exploratory `pairs()` plots, is commented out; no model depends on it.
- The paper's analyses were run in R 3.5.0; `renv.lock` pins R 4.5.3 and current packages. Results match the paper closely (e.g. the shoaling GAMM p-values exactly), with small differences in some glmmTMB p-values (tree vs. mimic p = 0.155 vs. 0.157 published).

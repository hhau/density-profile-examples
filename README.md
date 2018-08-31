# Examples and figure generating code to accompany the publication entitled: "Uncertainty quantification of continuous density profile estimates and the implications for ocean dynamics"

As per the title, this repository has example code on how the `ddcurves2` package is used, as well as code to generate the figures in the aforementioned publication.

### Order 

The code should be run in this order:

1. `Example/Example.Rmd`, either through Rstudio or `Rscript - e "rmarkdown::render('./Example/Example.Rmd')"`
2. `paper-figures/data-prep.r`
3. `figure_3-4-5/figure-maker-orig.Rmd`, `figure_6/2018-07-20_hierarchical-mean-time-series.R` and `figure_7/2018-07-24_isopyc-plot.R` can then be run in any order.

Please see `Example/Example.pdf` for more details. The outputs from these various scripts are already included in this repository.
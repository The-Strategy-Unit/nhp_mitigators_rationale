
# nhp_mitigators_rationale

<!-- badges: start -->
<!-- badges: end -->

An interactive table in a Quarto doc to explore mitigator selections and rationale for 'final' NHP scenarios.

Deployed to Posit Connect with a scheduled update: [https://connect.strategyunitwm.nhs.uk/nhp/mitigators-rationale/](https://connect.strategyunitwm.nhs.uk/nhp/mitigators-rationale/)

The deployment can be updated using the `deploy.R` file if the code is updated.

To deploy locally:

1. Create a `.Renviron` file in the root using the `.Renviron.example` file as a template.
2. Add files to `data/` (see `data/README.md`).
3. Open `index.qmd` and click the 'Render' if in RStudio (otherwise `quarto::quarto_render()`).

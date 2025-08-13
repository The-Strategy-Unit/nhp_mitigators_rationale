
# nhp_mitigators_rationale

<!-- badges: start -->
<!-- badges: end -->

A simple interactive table in a Quarto doc to explore mitigator selections and associated rationale for 'final' NHP scenarios.
[Deployed to Posit Connect](https://connect.strategyunitwm.nhs.uk/nhp/mitigators-rationale/) and re-rendered on schedule (login/permissions required).

## Render locally

If you need to generate the report on your machine:

1. Create a `.Renviron` file in the project root using `.Renviron.example` as a template.
Ask a member of the Data Science team for the values required by each variable.
You won't need to include `CONNECT_*` variables if you've already [configured your publishing account in RStudio](https://docs.posit.co/connect/user/publishing-rstudio/).
2. Open `index.qmd` in RStudio and click the 'Render' button if in RStudio (otherwise `quarto::quarto_render()` or via the Quarto CLI).

During this process, you may be prompted to authorise with Azure through the browser. 
See [the Data Science website](https://the-strategy-unit.github.io/data_science/presentations/2024-05-16_store-data-safely/#/authenticating-to-azure-data-storage) for detail on authorisation.

## Redeploy

If you make changes to the code in this repo, you can redeploy it to our Connect server by running `deploy.R`.

## Refresh

The report runs on schedule, so any changes to the underlying data will be integrated on the next rendering.
You may wish to manually refresh the app from Posit Connect if you want your changes to appear more quickly.
To do this, open the app from the Posit Connect 'Content' page and click the 'refresh report' button (circular arrow) in the upper-right of the interface.

## Data

The data processed by the report is collected from the model results files, hosted on Azure in the container given by the environmental variable `AZ_STORAGE_CONTAINER_RESULTS`.
See the [separate guidance](https://csucloudservices.sharepoint.com/:w:/r/sites/HEUandSUProjects/_layouts/15/Doc.aspx?sourcedoc=%7BE9BF237E-BA81-4F7E-90B1-2CA3A003F5A1%7D&file=2024-08-24_tagging-nhp-model-runs.docx&action=default&mobileredirect=true) for how to tag results files with run-stage metadata.
Lookups for mitigators, scheme names and providers are read from the Azure container named by the `AZ_STORAGE_CONTAINER_SUPPORT` environmental variable.

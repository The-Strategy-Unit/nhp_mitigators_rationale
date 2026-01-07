rsconnect::deployDoc(
  server = "connect.strategyunitwm.nhs.uk",
  appId = 187,
  doc = "index.qmd",
  appName = "nhp_tpma_rationale",
  appTitle = "NHP: rationale for TPMA selections",
  envVars = c(
    "AZ_STORAGE_EP",
    "AZ_STORAGE_CONTAINER_RESULTS",
    "AZ_STORAGE_CONTAINER_SUPPORT"
  ),
  lint = FALSE,
  forceUpdate = TRUE
)

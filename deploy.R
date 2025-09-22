rsconnect::deployDoc(
  server = "connect.strategyunitwm.nhs.uk",
  appId = 187,
  doc = "index.qmd",
  appName = "nhp_mitigators_rationale",
  appTitle = "NHP mitigator selections and rationale",
  envVars = c(
    "AZ_STORAGE_EP",
    "AZ_STORAGE_CONTAINER_RESULTS",
    "AZ_STORAGE_CONTAINER_SUPPORT"
  ),
  lint = FALSE,
  forceUpdate = TRUE
)

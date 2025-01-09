# Functions here copied from the private {su.azure} package to avoid GitHub PAT
# headaches when trying to deploy the Rmd to Connect.

get_nhp_result_sets <- function(
    container,
    allowed_datasets = get_nhp_user_allowed_datasets(NULL),
    folder = "prod"
) {

  allowed <- tibble::tibble(dataset = allowed_datasets)

  container |>
    AzureStor::list_blobs(folder, info = "all", recursive = TRUE) |>
    dplyr::filter(!.data[["isdir"]]) |>
    purrr::pluck("name") |>
    purrr::set_names() |>
    purrr::map(\(name, ...) AzureStor::get_storage_metadata(container, name)) |>
    dplyr::bind_rows(.id = "file") |>
    dplyr::semi_join(allowed, by = dplyr::join_by("dataset")) |>
    dplyr::mutate(dplyr::across("viewable", as.logical))

}

get_container <- function(
    tenant = Sys.getenv("AZ_TENANT_ID"),
    app_id = Sys.getenv("AZ_APP_ID"),
    ep_uri = Sys.getenv("AZ_STORAGE_EP"),
    container_name = Sys.getenv("AZ_STORAGE_CONTAINER_RESULTS")
) {

  # if the app_id variable is empty, we assume that this is running on an Azure VM,
  # and then we will use Managed Identities for authentication.
  token <- if (app_id != "") {
    AzureAuth::get_azure_token(
      resource = "https://storage.azure.com",
      tenant = tenant,
      app = app_id,
      auth_type = "device_code"
    )
  } else {
    AzureAuth::get_managed_token("https://storage.azure.com/")
  }

  ep_uri |>
    AzureStor::blob_endpoint(token = token) |>
    AzureStor::storage_container(container_name)

}

get_nhp_user_allowed_datasets <- function(groups = NULL) {

  p <- get_nhp_providers()

  if (!(is.null(groups) || any(c("nhp_devs", "nhp_power_users") %in% groups))) {
    a <- groups |>
      stringr::str_subset("^nhp_provider_") |>
      stringr::str_remove("^nhp_provider_")
    p <- intersect(p, a)
  }

  c("synthetic", p)

}

get_nhp_providers <- function(
    container_support = Sys.getenv("AZ_STORAGE_CONTAINER_SUPPORT")
) {

  container <- get_container(container_name = container_support)

  raw_json <- AzureStor::storage_download(
    container,
    src = "providers.json",
    dest = NULL
  )

  raw_json |>
    rawToChar() |>
    jsonlite::fromJSON(simplifyVector = TRUE)

}

get_nhp_results <- function(container, file) {

  temp_file <- withr::local_tempfile()
  AzureStor::download_blob(container, file, temp_file)

  readBin(temp_file, raw(), n = file.size(temp_file)) |>
    jsonlite::parse_gzjson_raw(simplifyVector = FALSE)
  # ignore parse_nhp_results() step; we only care about params in this repo

}



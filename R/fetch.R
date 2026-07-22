# Read pre-prepared pin containing tagged-runs metadata, filter for desired run stages
# Pin: https://connect.strategyunitwm.nhs.uk/content/022974aa-dd54-4e33-aed3-42c34f81bc9d
# Produced by: https://connect.strategyunitwm.nhs.uk/nhp/tagged-runs-params-report
fetch_tagged_runs_meta <- function(
  pin_board,
  pin_name = "matt.dray/nhp_tagged_runs_meta",
  run_stage_keep = c("final_report_ndg2", "validation_report_ndg2")
) {
  pins::pin_read(pin_board, pin_name) |>
    dplyr::filter(.data$run_stage %in% run_stage_keep) |>
    dplyr::arrange(
      .data$dataset,
      dplyr::desc(.data$run_stage) # ensure validation listed before final
    ) |>
    dplyr::slice(1, .by = "dataset") # keep validation, otherwise final
}

# Read pre-prepared pin containing tagged_runs params, filter for desired run stages
# Pin: https://connect.strategyunitwm.nhs.uk/content/2784320a-dfa4-4694-866f-9c84741568da
# Produced by: https://connect.strategyunitwm.nhs.uk/nhp/tagged-runs-params-report
fetch_tagged_runs_params <- function(
  pin_board,
  pin_name = "matt.dray/nhp_tagged_runs_params",
  runs_meta
) {
  all_params <- pins::pin_read(pin_board, pin_name)

  scenarios_to_keep <- runs_meta |>
    glue::glue_data("{dataset}_{scenario}_{create_datetime}")

  all_params[names(all_params) %in% scenarios_to_keep]
}

# Read TPMA lookup from centralised TPMA repo
# Source: https://github.com/The-Strategy-Unit/TPMAs
fetch_tpma_lookup <- function(
  lookup_path = "https://raw.githubusercontent.com/The-Strategy-Unit/TPMAs/refs/heads/main/reference/tpma-lookup.csv"
) {
  readr::read_csv(lookup_path, col_types = "c") |>
    dplyr::filter(is.na(.data$active_to)) |>
    dplyr::mutate(
      tpma_name_full = dplyr::if_else(
        is.na(.data$tpma_subtype),
        glue::glue("{tpma_code}: {tpma_name}"),
        glue::glue("{tpma_code}: {tpma_name} ({tpma_subtype})")
      )
    ) |>
    dplyr::relocate("tpma_name_full", .after = "tpma_subtype")
}

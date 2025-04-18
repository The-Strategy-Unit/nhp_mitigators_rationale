# Extract mitigator values
extract_params <- function(
    params,
    runs_meta,
    mitigator_lookup,
    scheme_lookup
) {

  possibly_report_params_table <- purrr::possibly(report_params_table)

  activity_avoidance <- params |>
    purrr::map(possibly_report_params_table, "activity_avoidance") |>
    purrr::list_rbind()

  efficiencies <- params |>
    purrr::map(possibly_report_params_table, "efficiencies") |>
    purrr::list_rbind()

  runs_meta <- runs_meta |> dplyr::select(dataset, scenario, run_stage)

  activity_avoidance |>
    dplyr::bind_rows(efficiencies) |>
    dplyr::mutate(
      peer_year = paste0(
        peer,
        "_", stringr::str_sub(baseline_year, 3, 4),
        "_", stringr::str_sub(horizon_year, 3, 4)
      )
    ) |>
    correct_day_procedures() |>
    dplyr::left_join(runs_meta, by = dplyr::join_by("peer" == "dataset")) |>
    dplyr::left_join(
      mitigator_lookup,
      by = dplyr::join_by(strategy == "Strategy variable")
    ) |>
    dplyr::left_join(
      scheme_lookup,
      by = dplyr::join_by(peer == scheme_code)
    ) |>
    dplyr::mutate(
      Midpoint = (value_1 + value_2) / 2,
      Range = value_2 - value_1
    ) |>
    dplyr::select(
      `Mitigator code`,
      `Mitigator name` = `Strategy name`,
      `Mitigator type`,
      `Activity type`,
      `Scheme` = scheme_name,
      `Baseline year` = baseline_year,
      `Horizon year` = horizon_year,
      Low = value_1,
      High = value_2,
      Midpoint,
      Range
    ) |>
    dplyr::arrange(`Mitigator code`, Scheme)

}

# Generate table of results
report_params_table <- function(
    p,  # a single scheme's params
    parameter = c("activity_avoidance", "efficiencies")
) {

  parameter_data <- p[[parameter]]

  time_profiles <- p[["time_profile_mappings"]][[parameter]] |>
    purrr::map(unlist) |>
    purrr::map(tibble::enframe, "strategy", "time_profile") |>
    purrr::list_rbind(names_to = "activity_type") |>
    dplyr::tibble()

  parameter_data |>
    purrr::map_depth(2, "interval") |>
    purrr::map(tibble::enframe, "strategy") |>
    dplyr::bind_rows(.id = "activity_type") |>
    tidyr::unnest_wider("value", names_sep = "_") |>
    dplyr::left_join(
      time_profiles,
      by = dplyr::join_by("activity_type", "strategy")
    ) |>
    dplyr::arrange("activity_type_name", "mitigator_name") |>
    dplyr::mutate(
      parameter = parameter,
      peer = p[["dataset"]],
      baseline_year = p[["start_year"]],
      horizon_year = p[["end_year"]]
    )

}

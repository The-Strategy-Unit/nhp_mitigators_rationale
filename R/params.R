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

# Rename or remove older versions of daycase mitigators if they exist
correct_day_procedures <- function(x) {

  # Identify pairs of bads/day_procedures mitigators with flag
  flagged <- x |>
    dplyr::mutate(
      mitigator_code_flag = dplyr::case_when(
        stringr::str_detect(
          strategy,
          "^bads_daycase$|^day_procedures_usually_dc$"  # old name/new name
        ) ~ "IP-EF-005",  # might as well flag with the mitigator code
        stringr::str_detect(
          strategy,
          "^bads_daycase_occasional$|^day_procedures_occasionally_dc$"
        ) ~ "IP-EF-006",
        stringr::str_detect(
          strategy,
          "^bads_outpatients$|^day_procedures_usually_op$"
        ) ~ "IP-EF-007",
        stringr::str_detect(
          strategy,
          "^bads_outpatients_or_daycase$|^day_procedures_occasionally_op$"
        ) ~ "IP-EF-008",
        .default = NA_character_
      )
    )

  # Identify where a peer has more than one instance of the code, i.e. the
  # mitigator is represented by both a bads and a day_procedures version. We'll
  # use this info to filter out the bads version.
  dupes <- flagged |>
    dplyr::count(peer, mitigator_code_flag) |>
    tidyr::drop_na(mitigator_code_flag) |>
    dplyr::filter(n > 1)

  # Remove bads mitigators if there's a day_procedures replacement for it
  if (nrow(dupes) > 0) {
    for (i in seq(nrow(dupes))) {
      flagged <- flagged |>
        dplyr::filter(
          !(peer == dupes[[i, "peer"]] &
              mitigator_code_flag == dupes[[i, "mitigator_code_flag"]] &
              stringr::str_detect(strategy, "^bads_"))
        )
    }
  }

  # Remaining bads mitigators clearly don't have a replacement day_procedures
  # version so we can just rename these ones.
  flagged |>
    dplyr::mutate(
      strategy = dplyr::case_match(
        strategy,
        "bads_daycase" ~ "day_procedures_usually_dc",
        "bads_daycase_occasional" ~ "day_procedures_occasionally_dc",
        "bads_outpatients" ~ "day_procedures_usually_op",
        "bads_outpatients_or_daycase" ~ "day_procedures_occasionally_op",
        .default = strategy
      )
    ) |>
    dplyr::select(-mitigator_code_flag)  # remove helper column

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

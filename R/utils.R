# Rename or remove older versions of daycase mitigators if they exist
# Assumes mitigators are in 'strrategy' column, scheme codes in 'peer' column
correct_day_procedures <- function(df_with_strategies) {

  # Identify pairs of bads/day_procedures mitigators with flag
  flagged <- df_with_strategies |>
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

# Remove blank and empty list elements, preventing errors
remove_blanks_recursively <- function(list_in) {

  if (!is.list(list_in)) return(list_in)

  list_in |>
    purrr::discard(\(x) isTRUE(x == "")) |>
    purrr::discard(\(x) isTRUE(length(x) == 0)) |>
    purrr::map(remove_blanks_recursively)

}

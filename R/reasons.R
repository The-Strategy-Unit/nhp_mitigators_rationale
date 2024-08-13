# Extract deeply-nested strings that give rationale for mitigator selections
extract_reasons <- function(
    reasons,  # reasons element of the params element in a results file
    mitigator_type  = c("activity_avoidance", "efficiencies"),
    mitigator_lookup,
    scheme_lookup
) {

  # Extract from deeply-nested list, remove empty elements, convert to dataframe
  reasons_extracted <- reasons |>
    purrr::map(\(x) {
      x |>
        purrr::pluck(mitigator_type) |>
        remove_blanks_recursively()
    }) |>
    purrr::discard(\(x) length(x) == 0) |>  # remove empty elements
    purrr::map(\(x) {
      x |>
        tibble::enframe() |>
        tidyr::unnest_longer(value) |>
        dplyr::select(
          activity_type = name,
          strategy_variable = value_id,
          reason = value
        )
    }) |>
    dplyr::bind_rows(.id = "scheme") |>
    dplyr::mutate(
      strategy_variable = dplyr::case_match(
        strategy_variable,
        "bads_daycase" ~ "day_procedures_usually_dc",
        "bads_daycase_occasional" ~ "day_procedures_occasionally_dc",
        "bads_outpatients" ~ "day_procedures_usually_op",
        "bads_outpatients_or_daycase" ~ "day_procedures_occasionally_op",
        .default = strategy_variable
      )
    )

  # Add scheme/mitigatoer groupings, prettify labels
  reasons_extracted |>
    dplyr::left_join(
      mitigator_lookup,
      by = dplyr::join_by(strategy_variable == "Strategy variable")
    ) |>
    dplyr::left_join(
      scheme_lookup,
      by = dplyr::join_by(scheme == scheme_code)
    ) |>
    dplyr::select(
      `Mitigator code`,
      `Mitigator name` = `Strategy name`,
      `Mitigator type`,
      `Activity type`,
      `Scheme` = scheme_name,
      Reason = reason
    ) |>
    dplyr::arrange(`Mitigator code`, Scheme)

}

# Remove blank and empty list elements, preventing errors
remove_blanks_recursively <- function(list_in) {

  if (!is.list(list_in)) return(list_in)

  list_in |>
    purrr::discard(\(x) isTRUE(x == "")) |>
    purrr::discard(\(x) isTRUE(length(x) == 0)) |>
    purrr::map(remove_blanks_recursively)

}

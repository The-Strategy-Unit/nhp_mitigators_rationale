# Extract deeply-nested strings that give rationale for mitigator selections
extract_reasons <- function(
  reasons, # reasons element of the params element in a results file
  tpma_type = c("activity_avoidance", "efficiencies"),
  mitigator_lookup,
  scheme_lookup
) {
  # Extract from deeply-nested list, remove empty elements, convert to dataframe
  reasons_extracted <- reasons |>
    purrr::map(\(x) {
      x |>
        purrr::pluck(tpma_type) |>
        remove_blanks_recursively()
    }) |>
    purrr::discard(\(x) length(x) == 0) |> # remove empty elements
    purrr::map(\(x) {
      x |>
        tibble::enframe() |>
        tidyr::unnest_longer(value) |>
        dplyr::select(
          tpma_variable = value_id,
          reason = value
        )
    }) |>
    dplyr::bind_rows(.id = "scenario_string") |>
    dplyr::mutate(
      scheme_code = stringr::str_extract(
        scenario_string,
        "^[:alnum:]{3}(?=_)" # 'R0A' from 'R0A_scenario_datetime'
      )
    )

  # Add scheme/mitigatoer groupings, prettify labels
  reasons_extracted |>
    dplyr::left_join(
      tpma_lookup,
      by = dplyr::join_by("tpma_variable")
    ) |>
    dplyr::left_join(
      scheme_lookup,
      by = dplyr::join_by("scheme_code")
    ) |>
    dplyr::select(
      `TPMA code` = tpma_code,
      `TPMA name` = tpma_name,
      `TPMA type` = tpma_type,
      `Activity type` = activity_type,
      `Scheme` = scheme_name,
      Reason = reason
    ) |>
    dplyr::arrange(`TPMA code`, Scheme)
}

# Remove blank and empty list elements, preventing errors
remove_blanks_recursively <- function(list_in) {
  if (!is.list(list_in)) {
    return(list_in)
  }

  list_in |>
    purrr::discard(\(x) isTRUE(x == "")) |>
    purrr::discard(\(x) isTRUE(length(x) == 0)) |>
    purrr::map(remove_blanks_recursively)
}

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
          strategy = value_id,
          reason = value
        )
    }) |>
    dplyr::bind_rows(.id = "peer") |>
    correct_day_procedures()

  # Add scheme/mitigatoer groupings, prettify labels
  reasons_extracted |>
    dplyr::left_join(
      mitigator_lookup,
      by = dplyr::join_by(strategy == "Strategy variable")
    ) |>
    dplyr::left_join(
      scheme_lookup,
      by = dplyr::join_by(peer == scheme_code)
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

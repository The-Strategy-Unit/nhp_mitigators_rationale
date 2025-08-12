# Remove blank and empty list elements, preventing errors
remove_blanks_recursively <- function(list_in) {

  if (!is.list(list_in)) return(list_in)

  list_in |>
    purrr::discard(\(x) isTRUE(x == "")) |>
    purrr::discard(\(x) isTRUE(length(x) == 0)) |>
    purrr::map(remove_blanks_recursively)

}

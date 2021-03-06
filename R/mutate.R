#' Create, modify, and delete columns
#'
#' `mutate()` adds new variables and preserves existing ones;
#' `transmute()` adds new variables and drops existing ones.
#' New variables overwrite existing variables of the same name.
#' Variables can be removed by setting their value to `NULL`.
#'
#' @section Useful mutate functions:
#'
#' * [`+`], [`-`], [log()], etc., for their usual mathematical meanings
#'
#' * [lead()], [lag()]
#'
#' * [dense_rank()], [min_rank()], [percent_rank()], [row_number()],
#'   [cume_dist()], [ntile()]
#'
#' * [cumsum()], [cummean()], [cummin()], [cummax()], [cumany()], [cumall()]
#'
#' * [na_if()], [coalesce()]
#'
#' * [if_else()], [recode()], [case_when()]
#'
#' @section Grouped tibbles:
#'
#' Because mutating expressions are computed within groups, they may
#' yield different results on grouped tibbles. This will be the case
#' as soon as an aggregating, lagging, or ranking function is
#' involved. Compare this ungrouped mutate:
#'
#' ```
#' starwars %>%
#'   select(name, mass, species) %>%
#'   mutate(mass_norm = mass / mean(mass, na.rm = TRUE))
#' ```
#'
#' With the grouped equivalent:
#'
#' ```
#' starwars %>%
#'   select(name, mass, species) %>%
#'   group_by(species) %>%
#'   mutate(mass_norm = mass / mean(mass, na.rm = TRUE))
#' ```
#'
#' The former normalises `mass` by the global average whereas the
#' latter normalises by the averages within species levels.
#'
#' @export
#' @inheritParams arrange
#' @param ... <[`data-masking`][dplyr_data_masking]> Name-value pairs.
#'   The name gives the name of the column in the output.
#'
#'   The value can be:
#'
#'   * A vector of length 1, which will be recycled to the correct length.
#'   * A vector the same length as the current group (or the whole data frame
#'     if ungrouped).
#'   * `NULL`, to remove the column.
#'   * A data frame or tibble, to create multiple columns in the output.
#' @family single table verbs
#' @return
#' An object of the same type as `.data`. The output has the following
#' properties:
#'
#' * Rows are not affected.
#' * Existing columns will be preserved according to the `.keep` argument.
#'   New columns will be placed according to the `.before` and `.after`
#'   arguments. If `.keep = "none"` (as in `transmute()`), the output order
#'   is determined only by `...`, not the order of existing columns.
#' * Columns given value `NULL` will be removed
#' * Groups will be recomputed if a grouping variable is mutated.
#' * Data frame attributes are preserved.
#' @section Methods:
#' These function are **generic**s, which means that packages can provide
#' implementations (methods) for other classes. See the documentation of
#' individual methods for extra arguments and differences in behaviour.
#'
#' Methods available in currently loaded packages:
#'
#' * `mutate()`: \Sexpr[stage=render,results=rd]{dplyr:::methods_rd("mutate")}.
#' * `transmute()`: \Sexpr[stage=render,results=rd]{dplyr:::methods_rd("transmute")}.
#' @examples
#' # Newly created variables are available immediately
#' starwars %>%
#'  select(name, mass) %>%
#'  mutate(
#'   mass2 = mass * 2,
#'   mass2_squared = mass2 * mass2
#' )
#'
#' # As well as adding new variables, you can use mutate() to
#' # remove variables and modify existing variables.
#' starwars %>%
#'  select(name, height, mass, homeworld) %>%
#'  mutate(
#'   mass = NULL,
#'   height = height * 0.0328084 # convert to feet
#' )
#'
#' # Use across() with mutate() to apply a transformation
#' # to multiple columns in a tibble.
#' starwars %>%
#'  select(name, homeworld, species) %>%
#'  mutate(across(!name, as.factor))
#' # see more in ?across
#'
#' # Window functions are useful for grouped mutates:
#' starwars %>%
#'  select(name, mass, homeworld) %>%
#'  group_by(homeworld) %>%
#'  mutate(rank = min_rank(desc(mass)))
#' # see `vignette("window-functions")` for more details
#'
#' # By default, new columns are placed on the far right.
#' # Experimental: you can override with `.before` or `.after`
#' df <- tibble(x = 1, y = 2)
#' df %>% mutate(z = x + y)
#' df %>% mutate(z = x + y, .before = 1)
#' df %>% mutate(z = x + y, .after = x)
#'
#' # By default, mutate() keeps all columns from the input data.
#' # Experimental: You can override with `.keep`
#' df <- tibble(x = 1, y = 2, a = "a", b = "b")
#' df %>% mutate(z = x + y, .keep = "all") # the default
#' df %>% mutate(z = x + y, .keep = "used")
#' df %>% mutate(z = x + y, .keep = "unused")
#' df %>% mutate(z = x + y, .keep = "none") # same as transmute()
#'
#' # Grouping ----------------------------------------
#' # The mutate operation may yield different results on grouped
#' # tibbles because the expressions are computed within groups.
#' # The following normalises `mass` by the global average:
#' starwars %>%
#'   select(name, mass, species) %>%
#'   mutate(mass_norm = mass / mean(mass, na.rm = TRUE))
#'
#' # Whereas this normalises `mass` by the averages within species
#' # levels:
#' starwars %>%
#'   select(name, mass, species) %>%
#'   group_by(species) %>%
#'   mutate(mass_norm = mass / mean(mass, na.rm = TRUE))
#'
#' # Indirection ----------------------------------------
#' # Refer to column names stored as strings with the `.data` pronoun:
#' vars <- c("mass", "height")
#' mutate(starwars, prod = .data[[vars[[1]]]] * .data[[vars[[2]]]])
#' # Learn more in ?dplyr_data_masking
mutate <- function(.data, ...) {
  UseMethod("mutate")
}

#' @rdname mutate
#' @param .keep \Sexpr[results=rd]{lifecycle::badge("experimental")}
#'   This is an experimental argument that allows you to control which columns
#'   from `.data` are retained in the output:
#'
#'   * `"all"`, the default, retains all variables.
#'   * `"used"` keeps any variables used to make new variables; it's useful
#'     for checking your work as it displays inputs and outputs side-by-side.
#'   * `"unused"` keeps only existing variables **not** used to make new
#'     variables.
#'   * `"none"`, only keeps grouping keys (like [transmute()]).
#'
#'   Grouping variables are always kept, unconditional to `.keep`.
#' @param .before,.after \Sexpr[results=rd]{lifecycle::badge("experimental")}
#'   <[`tidy-select`][dplyr_tidy_select]> Optionally, control where new columns
#'   should appear (the default is to add to the right hand side). See
#'   [relocate()] for more details.
#' @export
mutate.data.frame <- function(.data, ...,
                              .keep = c("all", "used", "unused", "none"),
                              .before = NULL, .after = NULL) {
  keep <- arg_match(.keep)

  cols <- mutate_cols(.data, ...)
  out <- dplyr_col_modify(.data, cols)

  .before <- enquo(.before)
  .after <- enquo(.after)
  if (!quo_is_null(.before) || !quo_is_null(.after)) {
    # Only change the order of new columns
    new <- setdiff(names(cols), names(.data))
    out <- relocate(out, !!new, .before = !!.before, .after = !!.after)
  }

  if (keep == "all") {
    out
  } else if (keep == "unused") {
    used <- attr(cols, "used")
    unused <- names(used)[!used]
    keep <- intersect(names(out), c(group_vars(.data), unused, names(cols)))
    dplyr_col_select(out, keep)
  } else if (keep == "used") {
    used <- attr(cols, "used")
    used <- names(used)[used]
    keep <- intersect(names(out), c(group_vars(.data), used, names(cols)))
    dplyr_col_select(out, keep)
  } else if (keep == "none") {
    keep <- c(
      # ensure group vars present
      setdiff(group_vars(.data), names(cols)),
      # cols might contain NULLs
      intersect(names(cols), names(out))
    )
    dplyr_col_select(out, keep)
  }
}

#' @rdname mutate
#' @export
transmute <- function(.data, ...) {
  UseMethod("transmute")
}

#' @export
transmute.data.frame <- function(.data, ...) {
  mutate(.data, ..., .keep = "none")
}

# Helpers -----------------------------------------------------------------

mutate_cols <- function(.data, ...) {
  mask <- DataMask$new(.data, caller_env())
  on.exit(mask$forget("mutate"), add = TRUE)

  rows <- mask$get_rows()

  dots <- enquos(...)
  dots_names <- names(dots)
  auto_named_dots <- names(enquos(..., .named = TRUE))
  if (length(dots) == 0L) {
    return(NULL)
  }

  new_columns <- set_names(list(), character())

  withCallingHandlers({
    for (i in seq_along(dots)) {
      not_named <- (is.null(dots_names) || dots_names[i] == "")

      # a list in which each element is the result of
      # evaluating the quosure in the "sliced data mask"
      # recycling it appropriately to match the group size
      #
      # TODO: reinject hybrid evaluation at the R level
      chunks <- NULL

      # result after unchopping the chunks
      result <- NULL

      if (quo_is_symbol(dots[[i]]) ){
        name <- as_string(quo_get_expr(dots[[i]]))

        if (name %in% names(new_columns)) {
          # already have result and chunks
          result <- new_columns[[name]]
          chunks <- mask$resolve(name)
        } else if (name %in% names(.data)) {
          # column from the original data
          result <- .data[[name]]
          chunks <- mask$resolve(name)
        }

        if (inherits(.data, "rowwise_df") && vec_is_list(result)) {
          sizes <- list_sizes(result)
          wrong <- which(sizes != 1)
          if (length(wrong)) {
            # same error as would have been generated by mask$eval_all_mutate()
            group <- wrong[1L]
            mask$set_current_group(group)
            abort(x_size = sizes[group], class = "dplyr:::mutate_incompatible_size")
          }
        }
      }

      # evaluate the chunks if needed
      if (is.null(chunks)) {
        chunks <- mask$eval_all_mutate(dots[[i]])
      }

      mask$across_cache_reset()

      if (is.null(chunks)) {
        if (!is.null(dots_names) && dots_names[i] != "") {
          new_columns[[dots_names[i]]] <- zap()
          mask$remove(dots_names[i])
        }
        next
      }

      # only unchop if needed
      if (is.null(result)) {
        if (length(rows) == 1) {
          result <- chunks[[1]]
        } else {
          result <- withCallingHandlers(
            vec_unchop(chunks, rows),
            vctrs_error_incompatible_type = function(cnd) {
              abort(class = "dplyr:::error_mutate_incompatible_combine", parent = cnd)
            }
          )
        }
      }

      if (not_named && is.data.frame(result)) {
        new_columns[names(result)] <- result

        # remember each result separately
        map2(seq_along(result), names(result), function(i, nm) {
          mask$add(nm, pluck(chunks, i))
        })
      } else {
        name <- if (not_named) auto_named_dots[i] else dots_names[i]

        # treat as a single output otherwise
        new_columns[[name]] <- result

        # remember
        mask$add(name, chunks)
      }


    }

  },
  error = function(e) {
    local_call_step(dots = dots, .index = i, .fn = "mutate", .dot_data = inherits(e, "rlang_error_data_pronoun_not_found"))
    call_step_envir <- peek_call_step()
    error_name <- call_step_envir$error_name
    error_expression <- call_step_envir$error_expression

    show_group_details <- TRUE
    if (inherits(e, "dplyr:::mutate_incompatible_size")) {
      size <- vec_size(rows[[mask$get_current_group()]])
      x_size <- e$x_size
      bullets <- c(
        x = glue("Input `{error_name}` can't be recycled to size {size}."),
        i = cnd_bullet_input_info(),
        i = glue("Input `{error_name}` must be size {or_1(size)}, not {x_size}."),
        i = cnd_bullet_rowwise_unlist()
      )
    } else if (inherits(e, "dplyr:::mutate_mixed_null")) {
      show_group_details <- FALSE
      bullets <- c(
        x = glue("`{error_name}` must return compatible vectors across groups."),
        i = cnd_bullet_input_info(),
        i = "Cannot combine NULL and non NULL results.",
        i = cnd_bullet_rowwise_unlist()
      )
    } else if (inherits(e, "dplyr:::mutate_not_vector")) {
      bullets <- c(
        x = glue("Input `{error_name}` must be a vector, not {friendly_type_of(e$result)}."),
        i = cnd_bullet_input_info(),
        i = cnd_bullet_rowwise_unlist()
      )
    } else if(inherits(e, "dplyr:::error_mutate_incompatible_combine")) {
      show_group_details <- FALSE
      bullets <- c(
        x = glue("Input `{error_name}` must return compatible vectors across groups"),
        i = cnd_bullet_input_info(),
        i = cnd_bullet_combine_details(e$parent$x, e$parent$x_arg),
        i = cnd_bullet_combine_details(e$parent$y, e$parent$y_arg)
      )
    } else {
      bullets <- c(
        x = conditionMessage(e), i = cnd_bullet_input_info()
      )
    }

    abort(c(
      cnd_bullet_header(),
      bullets,
      i = if(show_group_details) cnd_bullet_cur_group_label()
    ), class = c("dplyr:::mutate_error", "dplyr_error"), error_name = error_name, error_expression = error_expression)

  },
  warning = function(w) {
    local_call_step(dots = dots, .index = i, .fn = "mutate")

    warn(c(
      cnd_bullet_header(),
      i = conditionMessage(w),
      i = cnd_bullet_input_info(),
      i = cnd_bullet_cur_group_label()
    ))

    # cancel `w`
    invokeRestart("muffleWarning")
  })

  is_zap <- map_lgl(new_columns, inherits, "rlang_zap")
  new_columns[is_zap] <- rep(list(NULL), sum(is_zap))
  used <- mask$get_used()
  names(used) <- mask$current_vars()
  attr(new_columns, "used") <- used
  new_columns
}

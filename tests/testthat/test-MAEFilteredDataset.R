# initialize ----
testthat::test_that("constructor accepts a MultiAssayExperiment object", {
  testthat::skip_if_not_installed("MultiAssayExperiment")
  utils::data(miniACC, package = "MultiAssayExperiment")
  testthat::expect_no_error(MAEFilteredDataset$new(dataset = miniACC, dataname = "miniACC"))
  testthat::expect_error(
    MAEFilteredDataset$new(dataset = miniACC[[1]], dataname = "miniACC"),
    "Assertion on 'dataset' failed"
  )
  testthat::expect_error(
    MAEFilteredDataset$new(dataset = iris, dataname = "miniACC"),
    "Assertion on 'dataset' failed"
  )
})

testthat::test_that("filter_states list is initialized with names of experiments", {
  testthat::skip_if_not_installed("MultiAssayExperiment")
  testfd <- R6::R6Class(
    "testfd",
    inherit = MAEFilteredDataset,
    public = list(
      get_filter_states = function() private$filter_states
    )
  )
  utils::data(miniACC, package = "MultiAssayExperiment")
  filtered_dataset <- testfd$new(dataset = miniACC, dataname = "mae")
  testthat::expect_identical(
    names(filtered_dataset$get_filter_states()),
    c("subjects", "RNASeq2GeneNorm", "gistict", "RPPAArray", "Mutations", "miRNASeqGene")
  )
})

# format ---
testthat::test_that("format returns properly formatted string", {
  testthat::skip_if_not_installed("MultiAssayExperiment")
  utils::data(miniACC, package = "MultiAssayExperiment")
  filtered_dataset <- MAEFilteredDataset$new(dataset = miniACC, dataname = "miniacc")
  fs <- teal_slices(
    teal_slice(
      dataname = "miniacc", varname = "years_to_birth", selected = c(30, 50),
      keep_na = TRUE, keep_inf = FALSE
    ),
    teal_slice(dataname = "miniacc", varname = "vital_status", selected = "1", keep_na = FALSE),
    teal_slice(dataname = "miniacc", varname = "gender", selected = "female", keep_na = TRUE),
    teal_slice(
      dataname = "miniacc", varname = "ARRAY_TYPE", selected = "",
      keep_na = TRUE, experiment = "RPPAArray", arg = "subset"
    )
  )
  filtered_dataset$set_filter_state(fs)

  testthat::expect_identical(
    shiny::isolate(filtered_dataset$format()),
    shiny::isolate(format(filtered_dataset))
  )

  testthat::expect_identical(
    shiny::isolate(filtered_dataset$format(show_all = TRUE)),
    shiny::isolate(format(filtered_dataset, show_all = TRUE))
  )
})

# print ---
testthat::test_that("print returns properly formatted string", {
  testthat::skip_if_not_installed("MultiAssayExperiment")
  utils::data(miniACC, package = "MultiAssayExperiment")
  filtered_dataset <- MAEFilteredDataset$new(dataset = miniACC, dataname = "miniacc")
  fs <- teal_slices(
    teal_slice(
      dataname = "miniacc", varname = "years_to_birth", selected = c(30, 50),
      keep_na = TRUE, keep_inf = FALSE
    ),
    teal_slice(dataname = "miniacc", varname = "vital_status", selected = "1", keep_na = FALSE),
    teal_slice(dataname = "miniacc", varname = "gender", selected = "female", keep_na = TRUE),
    teal_slice(
      dataname = "miniacc", varname = "ARRAY_TYPE", selected = "",
      keep_na = TRUE, experiment = "RPPAArray", arg = "subset"
    )
  )
  filtered_dataset$set_filter_state(fs)

  testthat::expect_identical(
    utils::capture.output(shiny::isolate(filtered_dataset$print())),
    utils::capture.output(shiny::isolate(print(filtered_dataset)))
  )

  testthat::expect_identical(
    utils::capture.output(shiny::isolate(filtered_dataset$print(show_all = TRUE))),
    utils::capture.output(shiny::isolate(print(filtered_dataset, show_all = TRUE)))
  )
})

# get_call ----
testthat::test_that("get_call returns NULL when no filter applied", {
  testthat::skip_if_not_installed("MultiAssayExperiment")
  utils::data(miniACC, package = "MultiAssayExperiment")
  filtered_dataset <- MAEFilteredDataset$new(dataset = miniACC, dataname = "miniACC")
  get_call_output <- shiny::isolate(filtered_dataset$get_call())
  testthat::expect_null(get_call_output)
})

testthat::test_that("get_call returns a call with applying filter", {
  testthat::skip_if_not_installed("MultiAssayExperiment")
  utils::data(miniACC, package = "MultiAssayExperiment")
  filtered_dataset <- MAEFilteredDataset$new(dataset = miniACC, dataname = "miniacc")
  fs <- teal_slices(
    teal_slice(
      dataname = "miniacc", varname = "years_to_birth", selected = c(30, 50),
      keep_na = TRUE, keep_inf = FALSE
    ),
    teal_slice(dataname = "miniacc", varname = "vital_status", selected = "1", keep_na = FALSE),
    teal_slice(dataname = "miniacc", varname = "gender", selected = "female", keep_na = TRUE),
    teal_slice(
      dataname = "miniacc", varname = "ARRAY_TYPE", selected = "",
      keep_na = TRUE, experiment = "RPPAArray", arg = "subset"
    )
  )
  filtered_dataset$set_filter_state(fs)
  get_call_output <- shiny::isolate(filtered_dataset$get_call())

  testthat::expect_equal(
    get_call_output,
    list(
      subjects = quote(
        miniacc <- MultiAssayExperiment::subsetByColData(
          miniacc,
          miniacc$years_to_birth >= 30 & miniacc$years_to_birth <= 50 &
            miniacc$vital_status == 1 & miniacc$gender == "female"
        )
      ),
      RPPAArray = quote(
        miniacc[["RPPAArray"]] <- subset(miniacc[["RPPAArray"]], subset = ARRAY_TYPE == "")
      )
    )
  )
})

# get_filter_overview ----
testthat::test_that("get_filter_overview returns overview matrix for MAEFilteredDataset without filtering", {
  testthat::skip_if_not_installed("MultiAssayExperiment")
  utils::data(miniACC, package = "MultiAssayExperiment")
  filtered_dataset <- MAEFilteredDataset$new(dataset = miniACC, dataname = "miniACC")
  testthat::expect_equal(
    shiny::isolate(filtered_dataset$get_filter_overview()),
    data.frame(
      dataname = c("miniACC", sprintf("- %s", names(miniACC))),
      subjects = c(92, 79, 90, 46, 90, 80),
      subjects_filtered = c(92, 79, 90, 46, 90, 80),
      obs = c(NA_real_, 198, 198, 33, 97, 471),
      obs_filtered = c(NA_real_, 198, 198, 33, 97, 471)
    )
  )
})

testthat::test_that("get_filter_overview returns overview matrix for MAEFilteredDataset with filtering", {
  testthat::skip_if_not_installed("MultiAssayExperiment")
  utils::data(miniACC, package = "MultiAssayExperiment")
  filtered_dataset <- MAEFilteredDataset$new(dataset = miniACC, dataname = "miniacc")
  fs <- teal_slices(
    teal_slice(
      dataname = "miniacc", varname = "years_to_birth", selected = c(30, 50),
      keep_na = TRUE, keep_inf = FALSE
    ),
    teal_slice(dataname = "miniacc", varname = "vital_status", selected = "1", keep_na = FALSE),
    teal_slice(dataname = "miniacc", varname = "gender", selected = "female", keep_na = TRUE),
    teal_slice(
      dataname = "miniacc", varname = "ARRAY_TYPE", selected = "",
      keep_na = TRUE, experiment = "RPPAArray", arg = "subset"
    )
  )
  filtered_dataset$set_filter_state(fs)

  testthat::expect_equal(
    shiny::isolate(filtered_dataset$get_filter_overview()),
    data.frame(
      dataname = c("miniacc", sprintf("- %s", names(miniACC))),
      subjects = c(92, 79, 90, 46, 90, 80),
      subjects_filtered = c(6, 5, 6, 4, 5, 5),
      obs = c(NA_real_, 198, 198, 33, 97, 471),
      obs_filtered = c(NA_real_, 198, 198, 26, 97, 471)
    )
  )
})

testthat::test_that(
  "MAEFilteredDataset$set_filter_state sets filters in `FilterStates` specified by `teal_slices",
  code = {
    testthat::skip_if_not_installed("MultiAssayExperiment")
    utils::data(miniACC, package = "MultiAssayExperiment")
    dataset <- MAEFilteredDataset$new(dataset = miniACC, dataname = "miniacc")
    fs <- teal_slices(
      teal_slice(
        dataname = "miniacc", varname = "years_to_birth", selected = c(30, 50),
        keep_na = FALSE, keep_inf = FALSE
      ),
      teal_slice(dataname = "miniacc", varname = "vital_status", selected = "1", keep_na = FALSE),
      teal_slice(dataname = "miniacc", varname = "gender", selected = "female", keep_na = FALSE),
      teal_slice(
        dataname = "miniacc", varname = "ARRAY_TYPE", selected = "",
        keep_na = FALSE, experiment = "RPPAArray", arg = "subset"
      )
    )
    dataset$set_filter_state(state = fs)
    testthat::expect_equal(
      shiny::isolate(dataset$get_call()),
      list(
        subjects = quote(
          miniacc <- MultiAssayExperiment::subsetByColData( # nolint
            miniacc,
            miniacc$years_to_birth >= 30 & miniacc$years_to_birth <= 50 &
              miniacc$vital_status == 1 &
              miniacc$gender == "female"
          )
        ),
        RPPAArray = quote(
          miniacc[["RPPAArray"]] <- subset( # nolint
            miniacc[["RPPAArray"]],
            subset = ARRAY_TYPE == ""
          )
        )
      )
    )
  }
)

testthat::test_that(
  "MAEFilteredDataset$set_filter_state only acceps `teal_slices",
  code = {
    testthat::skip_if_not_installed("MultiAssayExperiment")
    utils::data(miniACC, package = "MultiAssayExperiment")
    dataset <- MAEFilteredDataset$new(dataset = miniACC, dataname = "miniacc")
    fs <- list(
      list(
        years_to_birth = c(30, 50),
        vital_status = 1,
        gender = "female"
      ),
      RPPAArray = list(
        subset = list(ARRAY_TYPE = "")
      )
    )
    testthat::expect_error(dataset$set_filter_state(state = fs), "Assertion on 'state' failed")
  }
)

testthat::test_that(
  "MAEFilteredDataset$get_filter_state returns list identical to input",
  code = {
    testthat::skip_if_not_installed("MultiAssayExperiment")
    utils::data(miniACC, package = "MultiAssayExperiment")
    dataset <- MAEFilteredDataset$new(dataset = miniACC, dataname = "miniacc")
    fs <- teal_slices(
      teal_slice(
        dataname = "miniacc", varname = "years_to_birth", choices = c(14, 83), selected = c(30, 50),
        keep_na = FALSE, keep_inf = FALSE, fixed = FALSE, anchored = FALSE
      ),
      teal_slice(
        dataname = "miniacc", varname = "vital_status", choices = c("0", "1"), multiple = TRUE, selected = "1",
        keep_na = FALSE, keep_inf = NULL, fixed = FALSE, anchored = FALSE
      ),
      teal_slice(
        dataname = "miniacc", varname = "gender", choices = c("female", "male"), multiple = TRUE, selected = "female",
        keep_na = FALSE, keep_inf = FALSE, fixed = FALSE, anchored = FALSE
      ),
      teal_slice(
        dataname = "miniacc", varname = "ARRAY_TYPE", choices = c("", "protein_level"), multiple = TRUE, selected = "",
        keep_na = FALSE, keep_inf = NULL, fixed = FALSE, anchored = FALSE,
        experiment = "RPPAArray", arg = "subset"
      ),
      count_type = "none",
      include_varnames = list(miniacc = colnames(SummarizedExperiment::colData(miniACC)))
    )

    dataset$set_filter_state(state = fs)
    expect_identical_slices(dataset$get_filter_state(), fs)
  }
)

testthat::test_that(
  "MAEFilteredDataset$remove_filter_state removes desired filter",
  code = {
    testthat::skip_if_not_installed("MultiAssayExperiment")
    utils::data(miniACC, package = "MultiAssayExperiment")
    dataset <- MAEFilteredDataset$new(dataset = miniACC, dataname = "miniacc")
    fs <- teal_slices(
      teal_slice(
        dataname = "miniacc", varname = "years_to_birth", selected = c(30, 50),
        keep_na = TRUE, keep_inf = FALSE
      ),
      teal_slice(dataname = "miniacc", varname = "vital_status", selected = "1", keep_na = FALSE),
      teal_slice(dataname = "miniacc", varname = "gender", selected = "female", keep_na = FALSE),
      teal_slice(
        dataname = "miniacc", varname = "ARRAY_TYPE", selected = "",
        keep_na = FALSE, experiment = "RPPAArray", arg = "subset"
      )
    )
    dataset$set_filter_state(state = fs)
    dataset$remove_filter_state(
      teal_slices(teal_slice(dataname = "miniacc", varname = "years_to_birth"))
    )

    testthat::expect_equal(
      shiny::isolate(sapply(dataset$get_filter_state(), `[[`, "varname")),
      c("vital_status", "gender", "ARRAY_TYPE")
    )
  }
)

testthat::test_that(
  "MAEFilteredDataset$remove_filter_state only accepts `teal_slices",
  code = {
    testthat::skip_if_not_installed("MultiAssayExperiment")
    utils::data(miniACC, package = "MultiAssayExperiment")
    dataset <- MAEFilteredDataset$new(dataset = miniACC, dataname = "miniacc")
    fs <- teal_slices(
      teal_slice(
        dataname = "miniacc", varname = "years_to_birth", selected = c(30, 50),
        keep_na = TRUE, keep_inf = FALSE
      ),
      teal_slice(dataname = "miniacc", varname = "vital_status", selected = "1", keep_na = FALSE),
      teal_slice(dataname = "miniacc", varname = "gender", selected = "female", keep_na = FALSE),
      teal_slice(
        dataname = "miniacc", varname = "ARRAY_TYPE", selected = "",
        keep_na = FALSE, experiment = "RPPAArray", arg = "subset"
      )
    )
    dataset$set_filter_state(state = fs)
    testthat::expect_error(dataset$remove_filter_state(state_id = list("years_to_birth")))
  }
)

# UI actions ----
testthat::test_that("remove_filters button removes all filters", {
  testthat::skip_if_not_installed("MultiAssayExperiment")
  utils::data(miniACC, package = "MultiAssayExperiment")
  filtered_dataset <- MAEFilteredDataset$new(dataset = miniACC, dataname = "miniacc")
  fs <- teal_slices(
    teal_slice(
      dataname = "miniacc", varname = "years_to_birth", selected = c(30, 50), keep_na = FALSE, keep_inf = FALSE
    ),
    teal_slice(dataname = "miniacc", varname = "vital_status", selected = 1, keep_na = FALSE),
    teal_slice(dataname = "miniacc", varname = "gender", selected = "female", keep_na = FALSE),
    teal_slice(
      dataname = "miniacc", varname = "ARRAY_TYPE", selected = "",
      keep_na = FALSE, experiment = "RPPAArray", arg = "subset"
    ),
    count_type = "none"
  )

  shiny::isolate(filtered_dataset$set_filter_state(state = fs))

  testthat::expect_length(shiny::isolate(filtered_dataset$get_filter_state()), 4)

  shiny::testServer(
    filtered_dataset$srv_active,
    expr = {
      session$setInputs(remove_filters = TRUE)
    }
  )

  testthat::expect_length(shiny::isolate(filtered_dataset$get_filter_state()), 0)
})

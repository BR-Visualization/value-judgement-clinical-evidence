#' Example cumulative excess plot data used for Figure 13
#'
#' @name cumexcess
#' @format A data frame with 880 rows and 10 columns:
#'   \describe{
#'   \item{eventtime}{Simulated event times}
#'   \item{diff}{Simulated difference in active/control effects}
#'   \item{obsv_duration}{Duration of observational period}
#'   \item{obsv_unit}{Unit length of observational period}
#'   \item{outcome}{Specifies Benefit/Risk}
#'   \item{eff_diff_lbl}{Label for effect difference}
#'   \item{n}{Number of subjects}
#'   \item{effect}{Specifies active/control effect}
#'   \item{eff_code}{0/1 depicting control/active effects}
#'   \item{subjects}{Specifies number of subjects at a given time}
#'
#'   }
"cumexcess"

#' Example effects table
#'
#' @name brdata
#' @format A data frame with 105 rows and 51 variables
"brdata"

#' @docType data
#' @name effects_table
#' @title Example treatment effect table
#' @description Sample data frame for use in plot examples
#' @usage data(effects_table)
#' @format A data frame with ...
NULL

#' @docType data
#' @name mcda_data
#' @title Example MCDA data in wide format
#' @description Sample MCDA data frame derived from effects_table. Each study
#'   contains two rows: one for the active treatment and one for its comparator,
#'   with raw values for benefit and risk criteria on their original measurement
#'   scales. This format is required for MCDA visualization functions.
#' @usage data(mcda_data)
#' @format A data frame with multiple rows (2 per study: comparator + active
#'   treatment) and 7 columns:
#'   \describe{
#'     \item{Study}{Character: Study identifier (e.g., "Study 1", "Study 2")}
#'     \item{Treatment}{Character: Treatment name (e.g., Placebo, Drug A,
#'       Drug B, Drug C, Drug D)}
#'     \item{Benefit 1}{Numeric: Binary benefit outcome (proportion scale 0-1)}
#'     \item{Benefit 2}{Numeric: Continuous benefit outcome (original scale)}
#'     \item{Benefit 3}{Numeric: Continuous benefit outcome (original scale)}
#'     \item{Risk 1}{Numeric: Binary risk outcome (proportion scale 0-1)}
#'     \item{Risk 2}{Numeric: Binary risk outcome (proportion scale 0-1)}
#'   }
#' @details
#'   This dataset contains raw values (not differences from comparator) for
#'   each treatment within each study. Each unique treatment comparison from
#'   the effects_table is assigned a Study identifier, and both the active
#'   treatment and its comparator are included as separate rows. The MCDA
#'   visualization functions
#'   (e.g., \code{\link{create_mcda_barplot_comparison}},
#'   \code{\link{create_mcda_walkthrough}}, \code{\link{create_mcda_waterfall}})
#'   will calculate treatment differences from the comparator and normalize
#'   values using clinical scales.
#'
#' @examples
#' \dontrun{
#' # Load the data
#' data(mcda_data)
#'
#' # View structure - note the Study column
#' head(mcda_data)
#'
#' # Define clinical scales
#' clinical_scales <- list(
#'   `Benefit 1` = list(min = 0, max = 1, direction = "increasing"),
#'   `Benefit 2` = list(min = 0, max = 100, direction = "decreasing"),
#'   `Benefit 3` = list(min = 0, max = 100, direction = "increasing"),
#'   `Risk 1` = list(min = 0, max = 0.5, direction = "decreasing"),
#'   `Risk 2` = list(min = 0, max = 0.3, direction = "decreasing")
#' )
#'
#' # Analyze a specific study
#' barplot_study1 <- create_mcda_barplot_comparison(
#'   data = mcda_data,
#'   study = "Study 1",
#'   comparison_drug = "Drug A",
#'   benefit_criteria = c("Benefit 1", "Benefit 2", "Benefit 3"),
#'   risk_criteria = c("Risk 1", "Risk 2"),
#'   clinical_scales = clinical_scales
#' )
#'
#' # Analyze all studies together (if they share a common comparator)
#' waterfall_all <- create_mcda_waterfall(
#'   data = mcda_data,
#'   comparator_name = "Placebo",
#'   benefit_criteria = c("Benefit 1", "Benefit 2", "Benefit 3"),
#'   risk_criteria = c("Risk 1", "Risk 2"),
#'   clinical_scales = clinical_scales
#' )
#' }
#' @seealso \code{\link{create_mcda_barplot_comparison}},
#'   \code{\link{create_mcda_walkthrough}}, \code{\link{create_mcda_waterfall}}
NULL

#' Example clinical scales for MCDA normalization
#'
#' @name clinical_scales
#' @title Clinical Reference Scales for MCDA
#' @description A named list of clinical reference levels used to normalize
#'   each criterion in the \code{\link{mcda_data}} example dataset. Each
#'   element specifies the minimum value, maximum value, and direction of
#'   benefit for the corresponding criterion.
#' @usage data(clinical_scales)
#' @format A named list with 5 elements (one per criterion):
#'   \describe{
#'     \item{Benefit 1}{list(min = 0, max = 1,   direction = "increasing")}
#'     \item{Benefit 2}{list(min = 0, max = 100, direction = "decreasing")}
#'     \item{Benefit 3}{list(min = 0, max = 100, direction = "increasing")}
#'     \item{Risk 1}{list(min = 0, max = 0.5, direction = "decreasing")}
#'     \item{Risk 2}{list(min = 0, max = 0.3, direction = "decreasing")}
#'   }
#' @seealso \code{\link{mcda_data}}, \code{\link{weights}},
#'   \code{\link{create_mcda_barplot_comparison}}
"clinical_scales"

#' Example criterion weights for MCDA scoring
#'
#' @name weights
#' @title Criterion Weights for MCDA
#' @description A named numeric vector of stakeholder-elicited weights for
#'   each criterion in the \code{\link{mcda_data}} example dataset. Weights
#'   sum to 1.
#' @usage data(weights)
#' @format A named numeric vector with 5 elements:
#'   \describe{
#'     \item{Benefit 1}{0.30}
#'     \item{Benefit 2}{0.20}
#'     \item{Benefit 3}{0.10}
#'     \item{Risk 1}{0.30}
#'     \item{Risk 2}{0.10}
#'   }
#' @seealso \code{\link{mcda_data}}, \code{\link{clinical_scales}},
#'   \code{\link{create_mcda_barplot_comparison}}
"weights"

#' Example scatterplot data used for Figure 11
#'
#' @name scatterplot
#' @format A data frame with 500 rows and 2 columns:
#'   \describe{
#'   \item{bdiff}{Simulated difference in incremental probabilities for
#'   active/control effects and outcome "Benefit"}
#'   \item{rdiff}{Simulated difference in incremental probabilities for
#'   active/control effects and outcome "Risk"}
#'
#'   }
"scatterplot"

#' Simulated benefit-risk correlation data for correlogram visualization
#'
#' @name corr
#' @format A data frame with 100 rows and 6 columns:
#'   \describe{
#'   \item{Benefit 1}{Continuous variable representing first benefit measure}
#'   \item{Benefit 2}{Continuous variable representing second benefit
#'     measure, correlated with Benefit 1 (r = 0.6)}
#'   \item{Benefit 3}{Continuous variable representing third benefit measure}
#'   \item{Risk 1}{Continuous variable representing first risk measure,
#'     correlated with all three benefits (r = 0.3, 0.2, -0.5)}
#'   \item{Risk 2}{Continuous variable representing second risk measure,
#'     correlated with benefits and Risk 1}
#'   \item{Risk 3}{Continuous variable representing third risk measure,
#'     correlated with all previous variables}
#'   }
#' @details This dataset contains simulated data with all continuous
#' variables and controlled correlation structures. The data is generated
#' using the faux package to create specific correlations between benefit
#' and risk outcomes, demonstrating both positive and negative
#' relationships suitable for correlogram analysis.
"corr"

#' Example composite outcome data used for Figure 12
#'
#' @name comp_outcome
#' @format A data frame with 1800 rows and 6 variables
#' \describe{
#'   \item{usubjid}{Subject ID}
#'   \item{visit}{Visit}
#'   \item{trtn}{Treatment arms in numeric type}
#'   \item{trt}{Treatment arms in character type}
#'   \item{brcatn}{Category of composite outcome in numeric type}
#'   \item{brcat}{Category of composite outcome in character type}
#'
#' }
"comp_outcome"

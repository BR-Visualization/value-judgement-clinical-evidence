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

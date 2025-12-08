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
#' @description Sample MCDA data frame derived from effects_table. Each row
#'   represents a treatment (placebo or active drug) with raw values for
#'   benefit and risk criteria on their original measurement scales. This
#'   format is required for MCDA visualization functions.
#' @usage data(mcda_data)
#' @format A data frame with 5 rows (Placebo + 4 drugs) and 6 columns:
#'   \describe{
#'     \item{Treatment}{Character: Treatment name (Placebo, Drug A,
#'       Drug B, Drug C, Drug D)}
#'     \item{Benefit 1}{Numeric: Binary benefit outcome (proportion scale 0-1)}
#'     \item{Benefit 2}{Numeric: Continuous benefit outcome (original scale)}
#'     \item{Benefit 3}{Numeric: Continuous benefit outcome (original scale)}
#'     \item{Risk 1}{Numeric: Binary risk outcome (proportion scale 0-1)}
#'     \item{Risk 2}{Numeric: Binary risk outcome (proportion scale 0-1)}
#'   }
#' @details
#'   This dataset contains raw values (not differences from placebo) for
#'   each treatment. The MCDA visualization functions (e.g.,
#'   \code{\link{create_mcda_barplot_comparison}},
#'   \code{\link{create_mcda_walkthrough}}) will calculate treatment
#'   differences from placebo and normalize values using clinical scales.
#' @seealso \code{\link{create_mcda_barplot_comparison}},
#'   \code{\link{create_mcda_walkthrough}}
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

#' Example correlation data for correlogram visualization
#'
#' @name corr
#' @format A data frame with 100 rows and 6 columns:
#'   \describe{
#'   \item{Primary Efficacy}{Continuous variable representing primary
#'   efficacy outcome}
#'   \item{Secondary Efficacy}{Continuous variable representing secondary
#'   efficacy outcome}
#'   \item{Quality of Life}{Continuous variable representing quality of
#'   life outcome}
#'   \item{Recurring AE}{Binary variable (0/1) representing recurring
#'   adverse events}
#'   \item{Rare SAE}{Binary variable (0/1) representing rare serious
#'   adverse events}
#'   \item{Liver Toxicity}{Binary variable (0/1) representing liver
#'   toxicity events}
#'   }
#' @details This dataset contains simulated clinical trial data with
#' specific correlation structures between benefit and risk outcomes. It
#' demonstrates mixed variable types (continuous and binary) suitable for
#' correlogram analysis.
"corr"

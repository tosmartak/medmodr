#' Demo dataset for mediation and moderation analysis
#'
#' A simulated dataset demonstrating mediation and moderation signals.
#'
#' @format A data frame with 200 rows and 10 variables:
#' \describe{
#'   \item{x1}{Numeric predictor with mediation effect on m1 and y1}
#'   \item{x2}{Numeric predictor with mediation effect on m2 and y2}
#'   \item{m1}{Mediator variable influenced by x1}
#'   \item{m2}{Mediator variable influenced by x2}
#'   \item{c1}{Control covariate (numeric)}
#'   \item{c2}{Control covariate (numeric)}
#'   \item{grp}{Group factor with levels "control" and "treat"}
#'   \item{edu}{Education factor with levels "primary", "secondary", "tertiary"}
#'   \item{y1}{Outcome influenced by x1, m1, c1, and their interaction}
#'   \item{y2}{Outcome influenced by x2, m2, c2, and group moderation}
#' }
#'
#' @examples
#' data(demo_medmodr)
#' str(demo_medmodr)
"demo_medmodr"

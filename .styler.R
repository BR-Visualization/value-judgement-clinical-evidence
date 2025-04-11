tidyverse_style_with_lintr_compliance <- function() {
  transformers <- styler::tidyverse_style()
  # Make styler compatible with lintr indentation rules
  transformers$indention <- styler::specify_math_token_spacing(
    zero = c("'='", "'+'", "'-'", "'*'", "'/'"),
    one = c("'('", "')'")
  )
  transformers$line_break <- styler::specify_line_break_transformer()
  transformers$space <- styler::specify_space_transformer()
  transformers$token <- styler::specify_token_transformer()
  return(transformers)
}

# Use the custom style
options(styler.transformers = tidyverse_style_with_lintr_compliance())

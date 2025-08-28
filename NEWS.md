# medmodr 0.1.0

* First official release of **medmodr**
* Introduced core functions for mediation and moderation analysis:
  - `run_mediation_paths()`: Iterates mediation analyses across treatment–mediator–outcome triples, estimating ACME, ADE, Total Effects, and Proportion Mediated with confidence intervals.
  - `run_moderation_paths()`: Iterates moderation analyses across predictor–moderator–outcome combinations, returning tidy summaries of interaction effects and optionally plotting significant interactions.
* Added visualization support:
  - `plot_mediation_summary_effects()`: Creates publication-ready plots of mediation effects (ACME, ADE, Total Effect) with 95% confidence intervals.
* Designed functions to be flexible and reproducible:
  - Automatic handling of categorical variables and controls.
  - Informative warnings and messages for missing or invalid inputs.
  - Options for simulation, bootstrapping, significance filtering, and plotting.
* Ensured consistency with tidyverse conventions:
  - All outputs return clean tibbles.
  - Plots leverage **ggplot2** with clear faceting and color coding.
* Added documentation, examples, and tests to support reproducibility.

# medmodr 0.0.0.9000

* Initial package scaffold.
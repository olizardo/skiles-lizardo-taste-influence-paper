# R/generate_did_barplots.R
# Generates publication-grade DiD bar plots with error bars
# Highlights statistical significance (p < 0.05, p < 0.10, and Not Significant)

library(ggplot2)
library(dplyr)
library(lme4)
library(marginaleffects)

source("R/did_models.R")

theme_barplot <- theme_minimal(base_size = 13) +
  theme(
    plot.title = element_text(face = "bold", size = 13, hjust = 0.5),
    plot.subtitle = element_text(size = 11, hjust = 0.5, margin = margin(b = 8)),
    axis.title = element_text(face = "bold", size = 11),
    axis.text.y = element_text(size = 10, face = "bold"),
    panel.grid.minor = element_blank(),
    panel.border = element_rect(color = "grey80", fill = NA, linewidth = 0.5),
    strip.text = element_text(face = "bold", size = 11, hjust = 0),
    strip.background = element_rect(fill = "grey95", color = "grey80"),
    legend.position = "bottom",
    legend.title = element_blank()
  )

sig_palette <- c(
  "p < 0.05" = "firebrick",
  "p < 0.10" = "darkorange2",
  "Not Significant" = "grey70"
)

# ==============================================================================
# 1. Focused DiD Bar Plot: Significant and Marginally Significant Effects (Figure 2)
# ==============================================================================
# Extract pooled significant effects
did_coefs <- summary(mod_did_unwt)$coefficients
did_terms <- grep("factor\\(trial\\)2:cond2_refctrl", rownames(did_coefs), value = TRUE)
df_pooled_sig <- data.frame(
  Group = "Pooled Sample",
  Condition = gsub("factor\\(trial\\)2:cond2_refctrl", "", did_terms),
  Estimate = did_coefs[did_terms, "Estimate"],
  SE = did_coefs[did_terms, "Std. Error"],
  t = did_coefs[did_terms, "t value"]
) %>%
  mutate(
    p = 2 * (1 - pnorm(abs(t))),
    Condition = case_match(
      Condition,
      "Class & Taste/Dislike/+Status" ~ "High-Status Dislike",
      "Class & Taste/Like/-Status" ~ "Low-Status Like",
      "Taste Only/Dislike" ~ "Generalized Dislike",
      "Taste Only/Like" ~ "Generalized Like",
      "Class & Taste/Like/+Status" ~ "High-Status Like",
      "Class & Taste/Dislike/-Status" ~ "Low-Status Dislike"
    )
  ) %>%
  filter(p < 0.10)

# Extract status subgroup significant effects
df_status_sig <- res_did_status %>%
  mutate(
    cond_clean = factor(gsub(" - Baseline", "", contrast), levels = c(
      "Class & Taste/Dislike/-Status",
      "Class & Taste/Dislike/+Status",
      "Taste Only/Dislike",
      "Taste Only/Like",
      "Class & Taste/Like/-Status",
      "Class & Taste/Like/+Status"
    ), labels = c(
      "Dislike / Low Status",
      "Dislike / High Status",
      "Dislike (No Status)",
      "Like (No Status)",
      "Like / Low Status",
      "Like / High Status"
    ))
  ) %>%
  filter(p.value < 0.10) %>%
  transmute(
    Group = as.character(objsubjclass_factor),
    Condition = as.character(cond_clean),
    Estimate = estimate,
    SE = std.error,
    t = statistic,
    p = p.value
  )

df_all_sig <- bind_rows(df_pooled_sig, df_status_sig) %>%
  mutate(
    conf.low = Estimate - 1.96 * SE,
    conf.high = Estimate + 1.96 * SE,
    sig_label = ifelse(p < 0.05, "p < 0.05", "p < 0.10"),
    Facet_Group = case_when(
      Group == "Pooled Sample" ~ "Panel A: Pooled Sample (Overall Influence)",
      Group == "Middle, College" ~ "Panel B: High-Status Consistent (Middle Class, College)",
      TRUE ~ "Panel C: Status-Inconsistent Groups"
    ),
    Subgroup_Condition = case_when(
      Group == "Pooled Sample" ~ Condition,
      Group == "Middle, College" ~ Condition,
      Group == "Working, College" ~ paste0(Condition, " (Working / College)"),
      Group == "Middle, No College" ~ paste0(Condition, " (Middle / No College)")
    ),
    Facet_Group = factor(Facet_Group, levels = c(
      "Panel A: Pooled Sample (Overall Influence)",
      "Panel B: High-Status Consistent (Middle Class, College)",
      "Panel C: Status-Inconsistent Groups"
    ))
  ) %>%
  arrange(Facet_Group, Estimate) %>%
  mutate(Subgroup_Condition = factor(Subgroup_Condition, levels = rev(unique(Subgroup_Condition))))

p_focused_bar <- ggplot(df_all_sig, aes(x = Subgroup_Condition, y = Estimate, fill = sig_label)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey40", linewidth = 0.8) +
  geom_bar(stat = "identity", width = 0.55, color = "black", linewidth = 0.4) +
  geom_errorbar(aes(ymin = conf.low, ymax = conf.high), width = 0.22, linewidth = 0.85, color = "black") +
  coord_flip() +
  facet_wrap(~Facet_Group, ncol = 1, scales = "free_y") +
  scale_fill_manual(values = c("p < 0.05" = "firebrick", "p < 0.10" = "darkorange2")) +
  labs(
    title = "Statistically Reliable Difference-in-Differences Treatment Effects",
    subtitle = "Estimates Relative to Unexposed Control Condition (Net of Exposure Drift, p < 0.10)",
    x = "",
    y = "DiD Treatment Effect (Change in Treatment - Change in Control)"
  ) +
  theme_barplot

ggsave("figures/Figure_DiD_Significant_Effects.png", p_focused_bar, width = 8.5, height = 7.5, dpi = 300)
ggsave("figures/Figure_DiD_Significant_Effects.pdf", p_focused_bar, width = 8.5, height = 7.5)
cat("Figure_DiD_Significant_Effects.png (bar plot) saved successfully.\n")

# ==============================================================================
# 2. Complete Status DiD Bar Plot: Full 24-Cell Grid (Appendix Figure A.1)
# ==============================================================================
df_status_all <- res_did_status %>%
  mutate(
    cond_clean = factor(gsub(" - Baseline", "", contrast), levels = c(
      "Class & Taste/Dislike/-Status",
      "Class & Taste/Dislike/+Status",
      "Taste Only/Dislike",
      "Taste Only/Like",
      "Class & Taste/Like/-Status",
      "Class & Taste/Like/+Status"
    ), labels = c(
      "Dislike / Low Status",
      "Dislike / High Status",
      "Dislike (No Status)",
      "Like (No Status)",
      "Like / Low Status",
      "Like / High Status"
    )),
    sig = case_when(
      p.value < 0.05 ~ "p < 0.05",
      p.value < 0.10 ~ "p < 0.10",
      TRUE ~ "Not Significant"
    ),
    sig = factor(sig, levels = c("p < 0.05", "p < 0.10", "Not Significant")),
    conf.low = estimate - 1.96 * std.error,
    conf.high = estimate + 1.96 * std.error
  )

p_status_bar <- ggplot(df_status_all, aes(x = cond_clean, y = estimate, fill = sig)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey40", linewidth = 0.8) +
  geom_bar(stat = "identity", width = 0.6, color = "black", linewidth = 0.35) +
  geom_errorbar(aes(ymin = conf.low, ymax = conf.high), width = 0.25, linewidth = 0.8, color = "black") +
  coord_flip() +
  facet_wrap(~objsubjclass_factor, ncol = 2) +
  scale_fill_manual(values = sig_palette) +
  labs(
    title = "Estimated DiD Treatment Effects by Status Consistency (IPW Weighted)",
    subtitle = "Relative to Control Condition (Net of Exposure Drift)",
    x = "",
    y = "DiD Treatment Effect (Change in Treatment - Change in Control)"
  ) +
  theme_barplot

ggsave("figures/Figure_DiD_Status_All.png", p_status_bar, width = 10, height = 8, dpi = 300)
ggsave("figures/Figure_DiD_Status_All.pdf", p_status_bar, width = 10, height = 8)
cat("Figure_DiD_Status_All.png (full grid bar plot) saved successfully.\n")

# ==============================================================================
# 3. Pooled DiD Bar Plot (Unweighted Model 1)
# ==============================================================================
did_coefs_unwt <- summary(mod_did_unwt)$coefficients
did_terms_unwt <- grep("factor\\(trial\\)2:cond2_refctrl", rownames(did_coefs_unwt), value = TRUE)

df_pooled_plot <- data.frame(
  term = did_terms_unwt,
  estimate = did_coefs_unwt[did_terms_unwt, "Estimate"],
  std.error = did_coefs_unwt[did_terms_unwt, "Std. Error"],
  t.value = did_coefs_unwt[did_terms_unwt, "t value"]
) %>%
  mutate(
    p.value = 2 * (1 - pnorm(abs(t.value))),
    sig = case_when(
      p.value < 0.05 ~ "p < 0.05",
      p.value < 0.10 ~ "p < 0.10",
      TRUE ~ "Not Significant"
    ),
    sig = factor(sig, levels = c("p < 0.05", "p < 0.10", "Not Significant")),
    cond_raw = gsub("factor\\(trial\\)2:cond2_refctrl", "", term),
    cond_clean = factor(cond_raw, levels = c(
      "Class & Taste/Dislike/-Status",
      "Class & Taste/Dislike/+Status",
      "Taste Only/Dislike",
      "Taste Only/Like",
      "Class & Taste/Like/-Status",
      "Class & Taste/Like/+Status"
    ), labels = c(
      "Dislike / Low Status",
      "Dislike / High Status",
      "Dislike (No Status)",
      "Like (No Status)",
      "Like / Low Status",
      "Like / High Status"
    )),
    conf.low = estimate - 1.96 * std.error,
    conf.high = estimate + 1.96 * std.error
  )

p_pooled_bar <- ggplot(df_pooled_plot, aes(x = cond_clean, y = estimate, fill = sig)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey40", linewidth = 0.8) +
  geom_bar(stat = "identity", width = 0.55, color = "black", linewidth = 0.4) +
  geom_errorbar(aes(ymin = conf.low, ymax = conf.high), width = 0.22, linewidth = 0.85, color = "black") +
  coord_flip() +
  scale_fill_manual(values = sig_palette) +
  labs(
    title = "Difference-in-Differences Treatment Effects (Pooled Sample)",
    subtitle = "Relative to Control Condition (Net of Exposure Drift)",
    x = "",
    y = "DiD Treatment Effect (Change in Treatment - Change in Control)"
  ) +
  theme_barplot

ggsave("figures/Figure_DiD_Pooled.png", p_pooled_bar, width = 8.5, height = 5.5, dpi = 300)
ggsave("figures/Figure_DiD_Pooled.pdf", p_pooled_bar, width = 8.5, height = 5.5)
cat("Figure_DiD_Pooled.png (pooled bar plot) saved successfully.\n")

library(tidyverse)
library(lubridate)
library(dplyr)
library(forecast)
library(scales)
options(scipen = 999) 
options(warn = -1) 

data<- "ICAOctober25cleaned.csv"
catastrophe_data <- read_csv(data)
CLAIM_COLS <- c(
  "TOTAL CLAIMS RECEIVED", "Domestic Building Claims", 
  "Domestic Content Claims", "Domestic Motor Claims", 
  "Domestic Other Claims", "Commercial Property Claims", 
  "Commercial motor", "Commercial BI Claims", 
  "Commercial Other Claims", "Commercial Crop Claims"
)
clean_numeric <- function(x) {
  as.numeric(gsub("[$,]", "", x))
}

cleaned_data <- catastrophe_data %>%
  select(
    `Event Name`, Type, `Event Start`,`Event Finish`, Year,
    Original_Loss = `ORIGINAL LOSS VALUE`,
    Normalized_Loss = `NORMALISED LOSS VALUE (2022)`,
    all_of(CLAIM_COLS)
  ) %>%
  mutate(
    Original_Loss = clean_numeric(Original_Loss),
    Normalized_Loss = clean_numeric(Normalized_Loss),
    across(all_of(CLAIM_COLS), ~replace_na(clean_numeric(.), 0)),
    Event_Start = dmy(`Event Start`),
    Year = year(Event_Start)
  ) %>%
  filter(!is.na(Normalized_Loss) & Normalized_Loss > 0)


# Analysis Part 1: Trends in Frequency and Severity

yearly_trends <- cleaned_data %>%
  # Group by Year and summarize
  group_by(Year) %>%
  summarise(
    Frequency = n(),
    Total_Severity_Billion_AUD = sum(Normalized_Loss) / 1e9
  ) %>%
  ungroup() %>%
  filter(Year <= 2024) # Exclude the partial 2025 entry for cleaner trends

# Plot Frequency
freq_plot <- yearly_trends %>%
  ggplot(aes(x = Year, y = Frequency)) +
  geom_line(color = "blue", linewidth = 1) +
  geom_point(color = "darkblue") +
  geom_smooth(method = "loess", color = "lightblue", se = FALSE) +
  labs(
    title = "Catastrophe Event Frequency Over Time",
    subtitle = "Count of events per year (1967-2024)",
    x = "Year",
    y = "Number of Catastrophes Declared"
  ) +
  theme_minimal() +
  scale_x_continuous(breaks = seq(min(yearly_trends$Year), max(yearly_trends$Year), by = 10))

# Plot Severity
severity_plot <- yearly_trends %>%
  ggplot(aes(x = Year, y = Total_Severity_Billion_AUD)) +
  geom_bar(stat = "identity", fill = "red3") +
  geom_smooth(method = "loess", color = "darkred", linewidth = 1, se = FALSE) +
  labs(
    title = "Total Annual Normalized Severity Over Time",
    subtitle = "Total Normalized Loss Value (in billions AUD 2022) per year (1967-2024)",
    x = "Year",
    y = "Total Normalized Loss (AUD Billion)"
  ) +
  theme_minimal() +
  scale_x_continuous(breaks = seq(min(yearly_trends$Year), max(yearly_trends$Year), by = 10)) +
  scale_y_continuous(labels = dollar_format(prefix = "$"))

print(freq_plot)
ggsave("freq.png", freq_plot, width = 8, height = 5)
print(severity_plot)
ggsave("severity.png", severity_plot, width = 8, height = 5)


#Analysis Part 2: Correlations between Catastrophe Type and Claims
library(readr)
library(dplyr)
library(tidyr)
library(ggplot2)

# Load the dataset
df <- cleaned_data

# Define the claims columns
claim_columns <- c(
  'TOTAL CLAIMS RECEIVED',
  'Domestic Building Claims',
  'Domestic Content Claims',
  'Domestic Motor Claims',
  'Domestic Other Claims',
  'Commercial Property Claims',
  'Commercial motor',
  'Commercial BI Claims',
  'Commercial Other Claims',
  'Commercial Crop Claims'
)
specific_claim_columns <- claim_columns[claim_columns != 'TOTAL CLAIMS RECEIVED']

# Calculate the mean for each claim column, grouped by 'Type'
claim_type_mean_df <- df %>%
  select(Type, all_of(claim_columns)) %>%
  group_by(Type) %>%
  summarise(across(all_of(claim_columns), mean, na.rm = TRUE), .groups = 'drop')

# Extract only the specific claims mean data
specific_claims_mean_df <- claim_type_mean_df %>%
  select(Type, all_of(specific_claim_columns))

# Calculate the Grand Total Mean Claims
# We sum all columns and then sum the resulting row sums (or just sum all values)
grand_total_mean_claims <- sum(specific_claims_mean_df %>% select(-Type), na.rm = TRUE)

# Calculate the percentage contribution of each cell to the Grand Total
claim_type_percentage_grand_df <- specific_claims_mean_df %>%
  # Use mutate and across to calculate percentage for all specific claim columns
  mutate(across(all_of(specific_claim_columns),
                ~ (. / grand_total_mean_claims) * 100))

# Sort the catastrophe types (based on original total claims mean for consistency)
sorted_types <- claim_type_mean_df %>%
  arrange(desc(`TOTAL CLAIMS RECEIVED`)) %>%
  pull(Type)

claim_type_percentage_grand_df$Type <- factor(claim_type_percentage_grand_df$Type, levels = sorted_types)

# Reshape data from wide to long format for ggplot2
df_long_grand_percentage <- claim_type_percentage_grand_df %>%
  pivot_longer(
    cols = all_of(specific_claim_columns),
    names_to = "Claim_Type",
    values_to = "Percentage_Contribution"
  )

# Convert Claim_Type to a factor to maintain order
df_long_grand_percentage$Claim_Type <- factor(df_long_grand_percentage$Claim_Type, levels = specific_claim_columns)


# Create the percentage heatmap using ggplot2
grand_percentage_heatmap_plot <- ggplot(df_long_grand_percentage, aes(x = Claim_Type, y = Type, fill = Percentage_Contribution)) +
  # Use geom_tile for the heatmap
  geom_tile(color = "white", linewidth = 0.5) +
  # Add text labels for the percentage (formatted to two decimal places)
  geom_text(aes(label = ifelse(!is.na(Percentage_Contribution),
                               paste0(format(round(Percentage_Contribution, 2), nsmall = 2), "%"),
                               "NA")),
            color = "white", size = 3) +
  # Set the color scale
  scale_fill_viridis_c(name = "Percentage Contribution to Grand Total (%)", na.value = "lightgrey") +
  # Improve aesthetics and labels
  labs(
    title = "Percentage Contribution to Total Mean Claims by Catastrophe Type (1967-2024)",
    x = "Specific Claim Type",
    y = "Catastrophe Type"
  ) +
  theme_minimal() +
  theme(
    # Rotate x-axis labels
    axis.text.x = element_text(angle = 45, hjust = 1),
    plot.title = element_text(hjust = 0.5),
    plot.margin = unit(c(1, 1, 1, 1), "cm")
  )

print(grand_percentage_heatmap_plot)
ggsave("claims_percentage_grand_total_heatmap_r.png", plot = grand_percentage_heatmap_plot, width = 12, height = 8)

#Analysis Part 3: Loss Value Explanation and Forecasting to 2026

# Time Series Data Preparation: Aggregate normalized loss by year
ts_data <- yearly_trends %>%
  select(Year, Total_Severity_Billion_AUD) %>%
  # Ensure all years from 1967 to 2024 are present (fill with 0 if no event)
  complete(Year = seq(min(Year), 2024, by = 1), fill = list(Total_Severity_Billion_AUD = 0)) %>%
  # Convert to Time Series object (start year is 1967, frequency is 1/year)
  pull(Total_Severity_Billion_AUD) %>%
  ts(start = 1967, frequency = 1)

# Methodology: Auto ARIMA Forecasting
# auto.arima selects the best ARIMA model based on AIC/BIC scores.
# This model is suitable for data with trend and non-seasonal randomness.
fit_arima <- auto.arima(ts_data, stepwise = FALSE, approximation = FALSE)

# Forecast 3 years into the future (2024 + 3 = 2027, so we get 2025, 2026)
forecast_2026 <- forecast(fit_arima, h = 3)

# Plot the forecast
forecast_plot <- autoplot(forecast_2026) +
  labs(
    title = "Normalized Annual Loss Value Forecast to 2027",
    subtitle = "Historical data (1967-2024) and ARIMA(p,d,q) forecast",
    x = "Year",
    y = "Total Normalized Loss (AUD Billion)",
    caption = "Dark blue area: 80% confidence interval | Light blue area: 95% confidence interval"
  ) +
  theme_minimal() +
  scale_y_continuous(labels = dollar_format(prefix = "$"))

print(forecast_plot)

ggsave("forecast.png", forecast_plot, width = 8, height = 5)

# Analysis Part 3 : Normalized vs Original Loss Value
loss_year <- cleaned_data %>%
  group_by(Year) %>%
  summarise(
    Original_Loss = sum(Original_Loss, na.rm = TRUE),
    Normalized_Loss = sum(Normalized_Loss, na.rm = TRUE)
  )

p1 <- ggplot(loss_year, aes(x = Year)) +
  
# Filled area under Normalized Loss
geom_area(aes(y = Normalized_Loss, fill = "Normalized Loss"), alpha = 0.3) +
  
# Normalized Loss line
geom_line(aes(y = Normalized_Loss, color = "Normalized Loss"), size = 1.2) +
  
# Original Loss dashed line
geom_line(aes(y = Original_Loss, color = "Original Loss"),
        size = 1.2, linetype = "dashed") +
  
  scale_color_manual(values = c(
    "Original Loss" = "#009F9F",
    "Normalized Loss" = "#006BBB"
  )) +
  
  scale_fill_manual(values = c("Normalized Loss" = "#006BBB")) +
  
  scale_x_continuous(
    limits = c(1967, 2025),
    breaks = seq(1967, 2025, by = 10)
  ) +
  
  scale_y_continuous(
    labels = scales::dollar_format(prefix = "$")
  ) +
  
  labs(
    title = "Original vs Normalized Loss per Year",
    x = "Year",
    y = "Loss Value",
    color = "Loss Type",
    fill = "Loss Type"
  ) +
  
  theme_minimal(base_size = 14)
print(p1)
ggsave("Normalized vs Original.png", p1, width = 8, height = 5)

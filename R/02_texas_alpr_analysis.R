library(tidyverse)  # dplyr + ggplot2, same as class
library(treemapify) # tree map (Lab 05)
library(ggcorrplot) # correlation plot (Lab 05)

# Run this from the project folder (Session > Set Working Directory > To Project Directory)

# 1. Load the data (one row = one license plate reader camera in Texas)
df <- read_csv("data/texas_alpr_cameras.csv")
county_df <- read_csv("data/texas_alpr_by_county.csv")

class(df)
dim(df)        # 17,000+ rows
names(df)
summary(df)

# 2. How many cameras does each company make? (group_by + summarise)
#    Cleaning step: the raw data spells the same company different ways
#    ("Flock", "FLOCK SAFETY", "Flock Safety Clear creek District"...)
df <- df %>%
  mutate(manufacturer = ifelse(is.na(manufacturer), "Unknown", manufacturer),
         manufacturer = ifelse(grepl("flock", manufacturer, ignore.case = TRUE), "Flock Safety", manufacturer),
         manufacturer = ifelse(grepl("^axis", manufacturer, ignore.case = TRUE), "Axis Communications", manufacturer),
         manufacturer = ifelse(grepl("leonardo", manufacturer, ignore.case = TRUE), "Leonardo", manufacturer),
         manufacturer = ifelse(grepl("linovision", manufacturer, ignore.case = TRUE), "Linovision", manufacturer))

maker <- df %>%
  group_by(manufacturer) %>%
  summarise(n_cameras = n()) %>%
  arrange(desc(n_cameras))
maker

# Tree map: good for a categorical variable with many levels
ggplot(maker, aes(fill = manufacturer, area = n_cameras, label = manufacturer)) +
  geom_treemap() +
  geom_treemap_text(colour = "white", place = "centre") +
  theme(legend.position = "none") +   # labels are already on the boxes
  labs(title = "Texas ALPR cameras by manufacturer")

# 3. Top 10 counties by number of cameras (bar chart, geom_col because we already counted)
top10 <- county_df %>%
  arrange(desc(n_cameras)) %>%
  head(10)

ggplot(top10, aes(x = reorder(county, n_cameras), y = n_cameras)) +
  geom_col(fill = "cornflowerblue", color = "black") +
  coord_flip() +
  labs(x = "County", y = "Number of cameras",
       title = "Top 10 Texas counties by ALPR cameras")

# 4. Fair comparison: cameras per 10,000 people (a ratio, not a raw count)
county_df %>%
  filter(population_2024 > 100000) %>%
  arrange(desc(cameras_per_10k_people)) %>%
  select(county, n_cameras, population_2024, cameras_per_10k_people) %>%
  head(10)

# 5. Relationship between population and cameras (scatterplot + line of best fit)
ggplot(data = county_df,
       mapping = aes(x = population_2024, y = n_cameras)) +
  geom_point(color = "cornflowerblue", alpha = .7, size = 3) +
  geom_smooth(method = "lm", se = FALSE) +
  scale_x_continuous(label = scales::comma) +
  labs(x = "County population (2024)", y = "Number of cameras",
       title = "Bigger counties have more cameras")

# 6. Correlation plot of the numeric county variables
r <- cor(select(county_df, n_cameras, population_2024, land_sq_miles,
                cameras_per_10k_people, cameras_per_100_sq_miles),
         use = "complete.obs")
round(r, 2)
ggcorrplot(r, hc.order = TRUE, type = "lower", lab = TRUE)

# 7. Map of every camera in Texas (lon = x, lat = y)
ggplot(data = df, mapping = aes(x = lon, y = lat)) +
  geom_point(color = "indianred3", alpha = .3, size = .5) +
  coord_quickmap() +
  labs(x = "Longitude", y = "Latitude", title = "Every mapped ALPR camera in Texas")

# 8. Zoom in on Waco (McLennan County)
waco <- df %>% filter(county == "McLennan")
nrow(waco)
ggplot(waco, aes(x = lon, y = lat, color = manufacturer)) +
  geom_point(alpha = .7, size = 3) +
  labs(title = "ALPR cameras in McLennan County (Waco)")

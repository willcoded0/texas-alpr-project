library(osmdata)    # new package: pulls map data from OpenStreetMap
library(tidyverse)  # dplyr + ggplot2, same as class

# 1. Get the area around Waco
bbox <- getbb("Waco, Texas")

# 2. Download every surveillance camera in Waco into a data frame
#    The map servers are flaky, so try each one until one works.
#    After the first success the data is saved to a CSV, so next time
#    we just read the CSV (like read.csv in class) and skip the download.
csv_file <- "data/waco_cameras.csv"

if (file.exists(csv_file)) {
  df <- read.csv(csv_file, stringsAsFactors = FALSE, check.names = FALSE)
} else {
  servers <- c("https://overpass-api.de/api/interpreter",
               "https://maps.mail.ru/osm/tools/overpass/api/interpreter",
               "https://overpass.kumi.systems/api/interpreter")
  df <- NULL
  for (s in servers) {
    print(paste("Trying", s))
    set_overpass_url(s)
    df <- tryCatch(
      opq(bbox = bbox, osm_types = "node", out = "tags center", timeout = 60) %>%
        add_osm_feature(key = "man_made", value = "surveillance") %>%
        osmdata_data_frame(),
      error = function(e) NULL)   # if this server fails, try the next one
    if (!is.null(df)) break
  }
  if (is.null(df)) stop("All servers failed. Wait a minute and run again.")
  write.csv(df, csv_file, row.names = FALSE)
}

class(df)
names(df)

# 3. Keep only the license plate reader (ALPR) cameras
camera_df <- df %>%
  filter(`surveillance:type` == "ALPR") %>%
  select(osm_id, lat = osm_center_lat, lon = osm_center_lon,
         manufacturer, `surveillance:type`)

print(camera_df)
nrow(camera_df)   # how many ALPR cameras

# 4. Who makes them? (group_by + summarise)
camera_df %>%
  group_by(manufacturer) %>%
  summarise(n_cameras = n()) %>%
  arrange(desc(n_cameras))

# same idea with base R + barplot (table first!)
barplot(table(camera_df$manufacturer))

# 5. Map of the cameras: scatterplot with lon = x, lat = y
ggplot(data = camera_df,
       mapping = aes(x = lon, y = lat)) +
  geom_point(color = "indianred3",  # Color
             alpha = .7,            # Transparency level
             size = 3) +            # Point size
  labs(x = "Longitude",
       y = "Latitude",
       title = "ALPR Cameras in Waco, TX")
install.packages('ggcorrplot')
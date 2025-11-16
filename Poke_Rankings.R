# ------------------------------------------------------------------------
# Evan Rhodes
# 11/16/2025
#
# Poke_Rankings.R
# This file is used to scrape & Pokemon 'popularity' rankings from a large scale
# voting effort by 'Thomas Game Docs' to determine the least popular Pokemon.
#
# YouTube video documenting voting website methods & data collection:
# https://www.youtube.com/watch?v=MgB7vAdajls
#
# Rankings website: 
# https://thomasgamedocs.com/pokemon/
#
# A couple details:
# - 1.6 million votes submitted in one week
# - 1025 Pokemon included, excluding regional & other gimmick variants
#    -> Excludes all pokemon that do not have a unique Pokedex ID
# - Votes were framed in an either/or format, presented with two random Pokemon
#   for each vote
# ------------------------------------------------------------------------

library(tidyverse)
library(xml2)
library(rvest)

url <- "https://thomasgamedocs.com/pokemon/"
page <- read_html(url)

rows <- page |> html_elements("tr")

rankings <- rows |>
  lapply(function(row) row |> html_elements("td") |> html_text2()) |>
  do.call(what = rbind) |>
  as.data.frame()

rankings_2 <- rankings |>
  mutate(
    V1 = as.numeric(V1),
    V2 = toupper(V2),
    V3 = as.numeric(str_remove(V3, "%"))
  ) |>
  select(-V4) |>
  rename(rank = V1, name = V2, vpct = V3)
  
saveRDS(rankings_2, file = "Ranked_Mons.rds")

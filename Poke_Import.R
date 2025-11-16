# ------------------------------------------------------------------------
# Evan Rhodes
# 11/16/2025
#
# Poke_Import.R
# This file is used to download general Pokemon data from https://pokeapi.co/
# to be used for report analyses 
# ------------------------------------------------------------------------

library(tidyverse)
library(httr)
library(jsonlite)


##############################################################
# Data import
##############################################################

base_url <- "https://pokeapi.co/api/v2/pokemon"
res <- GET(paste0(base_url, "?limit=2000"))
stop_for_status(res)

list_json <- fromJSON(content(res, as = "text"))
pokemon_entries <- list_json$results

fetch_pokemon <- function(url) {
  res <- GET(url)
  if (status_code(res) != 200) return(NULL)
  poke <- fromJSON(content(res, as = "text"), flatten = FALSE)
  return(poke)
}

detailed_list <- map(pokemon_entries$url, possibly(fetch_pokemon, otherwise = NULL))
detailed_list <- compact(detailed_list)

extract_names <- function(x, nested_field = NULL) {
  if (is.null(x) || length(x) == 0) return(NA_character_)
  
  names_vec <- map(x, function(e) {
    if (!is.list(e)) return(NA_character_)
    if (!is.null(nested_field) && !is.null(e[[nested_field]]) && !is.null(e[[nested_field]]$name)) {
      return(e[[nested_field]]$name)
    }
    if (!is.null(e$name)) return(e$name)
    return(NA_character_)
  })
  
  paste(map_chr(names_vec, ~ paste(.x, collapse = ", ")), collapse = ", ")
}

pokemon_df <- map_dfr(detailed_list, function(p) {

  tibble(
    id = ifelse(!is.null(p$id), p$id, NA_integer_),
    name = ifelse(!is.null(p$name), p$name, NA_character_),
    height = ifelse(!is.null(p$height), p$height, NA_integer_),
    weight = ifelse(!is.null(p$weight), p$weight, NA_integer_),
    species = ifelse(!is.null(p$species$name), p$species$name, NA_character_),
    types = extract_names(p$types, "type"),
    abilities = extract_names(p$abilities, "ability"),
    held_items = extract_names(p$held_items, "item"),
    moves = extract_names(p$moves, "move"),
  )
})

stats_df <- map_dfr(detailed_list, function(p) {
  tibble(
    id = p$id,
    stats_hp = p$stats$base_stat[p$stats$stat$name == "hp"],
    stats_attack = p$stats$base_stat[p$stats$stat$name == "attack"],
    stats_defense = p$stats$base_stat[p$stats$stat$name == "defense"],
    stats_special_attack = p$stats$base_stat[p$stats$stat$name == "special-attack"],
    stats_special_defense = p$stats$base_stat[p$stats$stat$name == "special-defense"],
    stats_speed = p$stats$base_stat[p$stats$stat$name == "speed"]
  )
})

pokemon_df2 <- left_join(pokemon_df, stats_df, by = "id")

forms_df <- map_dfr(detailed_list, function(p) {
  # Check if forms exists and is a data.frame with at least one row
  if (!is.null(p$forms) && is.data.frame(p$forms) && nrow(p$forms) > 0) {
    forms_names <- paste(p$forms$name, collapse = ", ")
  } else {
    forms_names <- NA_character_
  }
  
  tibble(
    id = p$id,
    forms = forms_names
  )
})

pokemon_df3 <- left_join(pokemon_df2, forms_df, by = "id")

get_species_info <- function(species_url) {
  
  # Request species JSON
  res <- GET(species_url)
  if (status_code(res) != 200) return(NULL)
  
  dat <- fromJSON(content(res, as = "text"), flatten = TRUE)
  
  tibble(
    species_id             = dat$id,
    gender_rate            = dat$gender_rate,
    capture_rate           = dat$capture_rate,
    base_happiness         = dat$base_happiness,
    is_baby                = dat$is_baby,
    is_legendary           = dat$is_legendary,
    is_mythical            = dat$is_mythical,
    growth_rate            = dat$growth_rate$name,
    color                  = dat$color$name,
    shape                  = dat$shape$name,
    has_gender_differences = dat$has_gender_differences,
    forms_switchable       = dat$forms_switchable,
    habitat                = if (!is.null(dat$habitat)) dat$habitat$name else NA_character_,
    generation             = dat$generation$name
  )
}

species_df <- map_dfr(detailed_list, function(p) {
  
  # Some Pokémon may lack a species reference (rare). Guard those cases.
  if (is.null(p$species$url)) {
    return(
      tibble(
        id = p$id,
        name = p$name,
        species_name = NA_character_,
        species_id = NA_integer_,
        gender_rate = NA,
        capture_rate = NA,
        base_happiness = NA,
        is_baby = NA,
        is_legendary = NA,
        is_mythical = NA,
        growth_rate = NA,
        color = NA,
        shape = NA,
        has_gender_differences = NA,
        forms_switchable = NA,
        habitat = NA,
        generation = NA
      )
    )
  }
  
  s <- get_species_info(p$species$url)
  
  tibble(
    id = p$id,
    name = p$name,
    species_name = p$species$name
  ) %>%
    bind_cols(s)
}) |> 
  select(-c(name, species_name, species_id))

pokemon_df4 <- left_join(pokemon_df3, species_df, by = "id")


##############################################################
# Additional data modification
##############################################################

pokemon_df5 <- pokemon_df4 |>
  rowwise() |>
  mutate(
    types = trimws(gsub("\\bNA\\b,?\\s*|,\\s*\\bNA\\b", "", types)),
    abilities = trimws(gsub("\\bNA\\b,?\\s*|,\\s*\\bNA\\b", "", abilities)),
    held_items = trimws(gsub("\\bNA\\b,?\\s*|,\\s*\\bNA\\b", "", held_items)),
    moves = trimws(gsub("\\bNA\\b,?\\s*|,\\s*\\bNA\\b", "", moves)),
    num_forms = sum(nzchar(unlist(strsplit(forms, ",\\s*")))),
    num_moves = sum(nzchar(unlist(strsplit(moves, ",\\s*")))),
    stat_total = sum(c_across(starts_with("stats_")), na.rm = TRUE), 
    name = toupper(name)
  ) |>
  filter(id <= 1025)

pokemon_rankings <- readRDS("C:/Users/evrho/OneDrive/Documents/_School/Fall 2025/611/BIOS611_Project/Ranked_Mons.rds") |>
  mutate(name = 
           sapply(name, function(x) paste(strsplit(x, "\\s+")[[1]], collapse = "-")))

# NOTE: To alleviate merging issues w/ conflicting data sources
# fixed names here per reviewing rankings website to force consistent format w/ PokeAPI names.
# https://thomasgamedocs.com/pokemon/

rank_corrections <- pokemon_rankings |>
  mutate(name = case_when(
    rank == 240 ~ "FARFETCHD",
    rank == 403 ~ "NIDORAN-M", 
    rank == 665 ~ "NIDORAN-F",
    rank == 867 ~ "MR-MIME", 
    rank == 126 ~ "DEOXYS-NORMAL", 
    rank == 993 ~ "WORMADAM-PLANT",
    rank == 905 ~ "MIME-JR",
    rank == 22 ~ "GIRATINA-ALTERED", 
    rank == 41 ~ "SHAYMIN-LAND",
    rank == 1011 ~ "BASCULIN-RED-STRIPED",
    rank == 583 ~ "DARMANITAN-STANDARD",
    rank == 808 ~ "TORNADUS-INCARNATE",
    rank == 707 ~ "THUNDURUS-INCARNATE",
    rank == 794 ~ "LANDORUS-INCARNATE",
    rank == 255 ~ "KELDEO-ORDINARY",
    rank == 145 ~ "MELOETTA-ARIA",
    rank == 639 ~ "FLABEBE",
    rank == 260 ~ "MEOWSTIC-MALE",
    rank == 136 ~ "AEGISLASH-SHIELD",
    rank == 211 ~ "PUMPKABOO-AVERAGE",
    rank == 381 ~ "GOURGEIST-AVERAGE", 
    rank == 166 ~ "ZYGARDE-50",
    rank == 500 ~ "ORICORIO-BAILE",
    rank == 80 ~ "LYCANROC-MIDDAY",
    rank == 622 ~ "WISHIWASHI-SOLO",
    rank == 335 ~ "TYPE-NULL",
    rank == 709 ~ "MINIOR-RED-METEOR", 
    rank == 2 ~ "MIMIKYU-DISGUISED", 
    rank == 238 ~ "TOXTRICITY-AMPED", 
    rank == 170 ~ "SIRFETCHD", 
    rank == 836 ~ "MR-RIME", 
    rank == 597 ~ "EISCUE-ICE", 
    rank == 780 ~ "INDEEDEE-MALE",
    rank == 509 ~ "MORPEKO-FULL-BELLY",
    rank == 684 ~ "URSHIFU-SINGLE-STRIKE",
    rank == 487 ~ "BASCULEGION-MALE",
    rank == 1013 ~ "ENAMORUS-INCARNATE",
    rank == 999 ~ "OINKOLOGNE-MALE",
    rank == 370 ~ "MAUSHOLD-FAMILY-OF-FOUR",
    rank == 1008 ~ "SQUAWKABILLY-GREEN-PLUMAGE", 
    rank == 542 ~ "PALAFIN-ZERO", 
    rank == 446 ~ "TATSUGIRI-CURLY",
    rank == 538 ~ "DUDUNSPARCE-TWO-SEGMENT",
    rank == 918 ~ "PECHARUNT",
    TRUE ~ name   
  ))

pokemon_dfx <- left_join(pokemon_df5, rank_corrections, by = "name")

saveRDS(pokemon_dfx, file = "Analysis_DF.rds")

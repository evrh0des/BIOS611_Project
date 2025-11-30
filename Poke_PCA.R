# ------------------------------------------------------------------------
# Evan Rhodes
# 11/24/2025
#
# Poke_PCA.R
# This file is used to perform principal component analysis on the main Pokemon
# stat values, to identify 'playability' clusters. For example, we might see
# a cluster for high defenses/health for 'setup' Pokemon
# ------------------------------------------------------------------------

library(tidyverse)
library(ggrepel)


##############################################################
# Load data
##############################################################

df <- readRDS("Analysis_DF.rds")


##############################################################
# Create violin plots of each stat's distribution
# stats: HP, attack, defense, speed, special attack, special defense 
##############################################################

df_long <- df |>
  pivot_longer(
    cols = c(stats_hp, stats_attack, stats_defense, 
             stats_special_attack, stats_special_defense, stats_speed), 
    names_to = "Stat",
    values_to = "Value"
  ) |>
  mutate(
    Stat = case_when(
      Stat == "stats_hp" ~ "HP",
      Stat == "stats_attack" ~ "Attack",
      Stat == "stats_defense" ~ "Defense",
      Stat == "stats_special_attack" ~ "Sp. Attack",
      Stat == "stats_special_defense" ~ "Sp. Defense",
      Stat == "stats_speed" ~ "Speed"
    ),
    center = 1
  ) |>
  select(id, Stat, Value, center)

vplot <- ggplot(data = df_long, aes(x = center, y = Value)) +
  geom_violin(fill = "skyblue", alpha = 0.6, color = "black") +
  stat_summary(fun = median, geom = "point", size = 2, color = "red") +
  facet_wrap(~Stat, scales = "free_y") +
  theme_bw(base_size = 14) +
  theme(
    strip.text = element_text(size = 14, face = "bold"),
    axis.text.x = element_blank(),
    axis.title.x = element_blank()
  ) +
  labs(
    title = "Pokemon Base Stat Distributions",
    subtitle = "Red point = median",
    y = "Base Stat Value"
  )

ggsave("Stat_Vplots.jpg", plot = vplot, width = 10, height = 8, dpi = 300)


##############################################################
# Use PCA to identify role clusters (tank/setup, sweeper, 
# physically dominant mons vs. special dominant mons) 
##############################################################

stats <- c("stats_hp", "stats_attack", "stats_defense", 
           "stats_special_attack", "stats_special_defense", "stats_speed")

pca <- prcomp(df[, stats], scale = TRUE)

pca_forplot <- as.data.frame(pca$x) |>
  select(PC1, PC2) |>
  mutate(name = df$name)

# Label Pokemon indicated on the following website in different 
# 'roles'. Smogon is a popular pokemon strategy forum. Note, this
# source is a bit outdated & may not accommodate for moves, abilities,
# etc. that may have changed over generations
# https://www.smogon.com/dp/articles/pokemon_dictionary
#
# If any pokemon were repeated in multiple roles, for purposes of 
# clustering display, just googled another pokemon to fit that row as well
#
# Support / setup: 
# "Baton Passer": Ninjask
# "Dedicated Lead": Aerodactyl
# "Dual Screener": Bronzong
# "Phazer": Celebi
# "Spinner": Starmie
# "Spin Blocker": Rotom
# "Suicide Lead": Azelf
# "Utility": Jirachi
#
# Defense / Healing: 
# "Cleric": Blissey
# "Pivot": Incineroar
# "Status Absorber": Heracross
# "Supporter": Cresselia
# "Tank": Clodsire
# "Utility Counter": Amoonguss
# "Wall": Skarmory
#
# Sweepers / offense: 
# "Attacking Lead": Machamp
# "Glass Cannon": Gengar
# "Mixed Sweeper": Infernape
# "Physical Sweeper": Lucario
# "Revenge Killer": Mamoswine
# "Special Sweeper": Porygon-Z
# "Stallbreaker": Gliscor
# "Trapper": Gothitelle
# "Wallbreaker": Metagross

mons_forlabel <- c("NINJASK", "AERODACTYL", "BRONZONG", "CELEBI", "STARMIE", 
                   "ROTOM", "AZELF", "JIRACHI", "BLISSEY", "INCINEROAR", 
                   "HERACROSS", "CRESSELIA", "CLODSIRE", "AMOONGUSS", "SKARMORY",
                   "MACHAMP", "GENGAR", "INFERNAPE", "LUCARIO", "MAMOSWINE", 
                   "PORYGON-Z", "GLISCOR", "GOTHITELLE", "METAGROSS")

pca_forplot$role <- case_when(
  pca_forplot$name %in% c("MACHAMP", "GENGAR", "INFERNAPE", "LUCARIO", "MAMOSWINE", 
                          "PORYGON-Z", "GLISCOR", "GOTHITELLE", "METAGROSS", 
                          "AERODACTYL", "AZELF", "STARMIE", "NINJASK") ~ "Offense", 
  pca_forplot$name %in% c("BLISSEY", "INCINEROAR", "BRONZONG", "CELEBI", "ROTOM",
                          "HERACROSS", "CRESSELIA", "CLODSIRE", "AMOONGUSS", 
                          "JIRACHI", "SKARMORY") ~ "Defense", 
  TRUE ~ NA
)

labels <- pca_forplot |>
  filter(name %in% mons_forlabel) |>
  mutate(segcol = ifelse(role == "Offense", "red", "blue"))

pcaplot <- ggplot(data = pca_forplot, aes(x = PC1, y = PC2)) +
  geom_point(alpha = 0.6) +
  geom_label_repel(
    data = labels,
    aes(label = name, 
        color = role,
        segment.color = segcol),
    size = 2.5,
    label.size = 0.3,
    max.overlaps = Inf,
    min.segment.length = 0.5,
    segment.size = 0.7,
    force = 3,  
    force_pull = 0.5,
    max.iter = 8000,
    box.padding = unit(0.7, "lines"),
    point.padding = unit(0.7, "lines")
    ) +  
    scale_color_manual(values = c(
      "Offense" = "red", 
      "Defense" = "blue"
    )) +
  labs(
    title = "Pokemon Stats by PCA: Competitive Role Clusters",
    x = "PC1",
    y = "PC2", 
    color = "Competitive Role"
  ) + 
  theme_minimal()

ggsave("PCA_Roles.jpg", plot = pcaplot, width = 10, height = 8, dpi = 300)


##############################################################
# Same plot, but specifically labeling baby & legendary mon clusters
##############################################################

labels2 <- left_join(pca_forplot, 
                     df |> select(name, is_baby, is_legendary, rank), 
                     by = "name") |>
  filter(is_baby == TRUE | 
          (is_legendary == TRUE & rank <= 100)) |>
  mutate(
    role2 = case_when(
      is_baby ~ "Baby",
      is_legendary ~ "Legendary"
    ),
    segcol2 = ifelse(role2 == "Legendary", "red", "blue")
  )

pcaplot2 <- ggplot(data = pca_forplot, aes(x = PC1, y = PC2)) +
  geom_point(alpha = 0.6) +
  geom_label_repel(
    data = labels2,
    aes(
      label = name,
      color = role2,
      segment.color = segcol2
    ),
    size = 2.5,
    label.size = 0.3,
    max.overlaps = Inf,
    min.segment.length = 0.5,
    segment.size = 0.7,
    force = 3,
    force_pull = 0.5,
    max.iter = 8000,
    box.padding = unit(0.7, "lines"),
    point.padding = unit(0.7, "lines")
  ) +
  scale_color_manual(
    values = c(
      "Legendary" = "red",
      "Baby" = "blue"
    )
  ) +
  labs(
    title = "Pokémon Stats by PCA: Baby/Legendary Clusters",
    x = "PC1",
    y = "PC2",
    color = "Pokémon Category"
  ) +
  theme_minimal()

ggsave("PCA_BabLeg.jpg", plot = pcaplot2, width = 10, height = 8, dpi = 300)



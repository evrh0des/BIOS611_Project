## Project Description

This is a data science final project for the BIOS611 UNC Chapel Hill course. Contained in this repository are R scripts to perform data imports and analyses, an R markdown file to render a PDF report, and a Dockerfile and a Makefile for an easily reproducible pipeline. 

The exploratory analyses aim to describe different trends in Pokemon popularity and base stats. First, different prediction models were employed and evaluated on a range of features, using Spearman's correlation as a comparison metric to determine which model can best predict Pokemon popularity rankings. Then, principal component analysis was performed on base Pokemon stats (heath, attack, defense, special attack, special defense, & speed) in attempts to identify different competitive role clusters for designing team compositions. All data necessary for analyses are pulled and included in the workflow. 

## Data Sources

The 'Poke_Rankings.R' file scrapes Pokemon popularity rankings from a week-long voting initiative with over 1.5 million responses, stored at this URL: 

https://thomasgamedocs.com/pokemon/

The 'Poke_Import.R' file connects to PokeAPI to draw all other data. PokeAPI can be accessed at the link below, with detailed documentation in the following links: 

https://pokeapi.co/
https://pokeapi.co/about
https://pokeapi.co/docs/v2#info

See the generated 'BIOS611_Report.pdf' file at the end of the Make pipeline to review selected features from PokeAPI and additional descriptions of the collected rankings data.

## Instructions to Generate Final Report

1. Initiate Windows PowerShell or another terminal of your choice and change to a working directory. Moving forward through the instructions, <WD> will refer to the path of your working directory.
2. Test

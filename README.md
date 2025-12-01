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

See the generated 'BIOS611_Report.pdf' file at the end of the Make pipeline to review selected features from PokeAPI and additional descriptions of the collected rankings data. Note that there is a lot more data available at PokeAPI than was used for the scope of this project.

## Instructions to Generate Final Report

1. Initiate Windows PowerShell or another terminal of your choice and change to a working directory using the command cd. Moving forward through the instructions, "WD" will refer to the path of your working directory.
2. Clone the github repository to your working directory. In your terminal, use command: git clone https://github.com/evrh0des/BIOS611_Project.git
3. In your terminal, change to the cloned Github Repository: cd WD\BIOS611_Project
4. If you do not already have Docker installed, it can be downloaded from https://www.docker.com/products/docker-desktop/.
5. In your terminal, build the Docker container from the repository, where NAME is any label you wish to give to the container:  docker build -t NAME .
6. In your terminal, run the Docker container, where NAME is the same label applied in the last step: docker run -d -p 8787:8787 -e PASSWORD=rstudio -v "WD/BIOS611_Project:/work" NAME
7. Open your container by navigating to a browser and entering http://localhost:8787/
8. Sign into RStudio with the same username and password, 'rstudio'.
9. Switch to the RStudio terminal.
10. Use command: cd /work. This will switch the container to the mounted directory with the Github repository contents. To confirm correct mounting, you can try 'ls' in the R terminal once switchted to the /work directory to confirm that the repository contents are present. 
11. Final step, enter exactly the command 'make report' into the R terminal (once in the /work directory) and submit the command. All project output will be sent to the same WD that you cloned the Github repository to, including intermediate .rds and .jpg files. All images and summary tables are knitted into the final 'BIOS611_Report.pdf' file

## Final Notes

'BIOS611_Report.pdf' is the ultimate product for this workflow, it contains all relevant analyses and descriptions of methods implemented. PLEASE NOTE, data import from PokeAPI can take some time; don't be surprised if you see Rstudio in the Docker container hang up on the Poke_Import.R program for several minutes. 
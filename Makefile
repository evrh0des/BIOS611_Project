.PHONY: all clean report

# Remove generated files
clean:
	rm -f Ranked_Mons.rds Analysis_DF.rds

# Default target
all: report

# Build the output
report: clean Ranked_Mons.rds Analysis_DF.rds

# Create Ranked_Mons.rds from Poke_Rankings.R
Ranked_Mons.rds: Poke_Rankings.R
	Rscript Poke_Rankings.R

# Create Analysis_DF.rds from Poke_Import.R, depends on Ranked_Mons.rds
Analysis_DF.rds: Ranked_Mons.rds Poke_Import.R
	Rscript Poke_Import.R
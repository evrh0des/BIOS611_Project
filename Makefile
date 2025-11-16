.PHONY: all clean report

# Remove generated files
clean:
	rm -f Ranked_Mons.rds

# Default target
all: report

# Build the output
report: clean Ranked_Mons.rds

Ranked_Mons.rds: Poke_Rankings.R
	Rscript Poke_Rankings.R

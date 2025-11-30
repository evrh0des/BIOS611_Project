.PHONY: all clean report

# Remove generated files
clean:
	rm -f Ranked_Mons.rds Analysis_DF.rds \
		Stat_Vplots.jpg PCA_BabLeg.jpg PCA_Roles.jpg \
		RF_Importance_Plot.jpg Model_Comparisons.rds

# Default target
all: report

# Build the output
report: clean Ranked_Mons.rds Analysis_DF.rds \
	Stat_Vplots.jpg PCA_BabLeg.jpg PCA_Roles.jpg \
	RF_Importance_Plot.jpg Model_Comparisons.rds

# Create Ranked_Mons.rds from Poke_Rankings.R
Ranked_Mons.rds: Poke_Rankings.R
	Rscript Poke_Rankings.R

# Create Analysis_DF.rds from Poke_Import.R, depends on Ranked_Mons.rds
Analysis_DF.rds: Ranked_Mons.rds Poke_Import.R
	Rscript Poke_Import.R

# Create PCA images, depends on Analysis_DF.rds
Stat_Vplots.jpg PCA_BabLeg.jpg PCA_Roles.jpg: Poke_PCA.R Analysis_DF.rds 
	Rscript Poke_PCA.R

RF_Importance_Plot.jpg Model_Comparisons.rds: Poke_Predictions.R Analysis_DF.rds
	Rscript Poke_Predictions.R
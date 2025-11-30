# Pull a Rocker RStudio + tidyverse image
FROM rocker/tidyverse:4.3.1

# Set working directory
WORKDIR /work

# Install system dependencies for PDF rendering
RUN apt-get update && apt-get install -y \
    texlive \
    texlive-latex-base \
    texlive-latex-recommended \
    texlive-latex-extra \
    texlive-fonts-recommended \
    pandoc \
    && rm -rf /var/lib/apt/lists/*

# Ensure rmarkdown is installed
RUN R -e "install.packages(c('rmarkdown', 'xml2', 'rvest', 'httr', 'jsonlite', 'ggrepel'))"

# Volume mount for project files
VOLUME ["/work"]

# Start RStudio
CMD ["/init"]

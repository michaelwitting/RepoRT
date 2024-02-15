FROM debian:12
# install python deps
RUN apt-get update && apt-get install -y python3-pip python3-venv \
    python3-pandas python3-requests python3-zeep python3-tabulate python3-sklearn python3-yaml
RUN pip install --break-system-packages pubchempy # not available as debian package
# install R + R deps
RUN apt-get update && apt-get install -y r-base r-base-dev \
    # dependencies necessary for some R packages
    libcurl4-openssl-dev libssl-dev default-jdk libgit2-dev
COPY renv.lock renv.lock
COPY renv renv
COPY .Rprofile .Rprofile
RUN R CMD javareconf            # configure Java for rJava
RUN R -e "renv::restore()"
# NOTE: uncomment the next line to create updated renv.lock file
# RUN R -e "renv::snapshot()"
# install dependencies for GitHub workflow
RUN apt-get update && apt-get install -y git git-lfs bash unzip curl

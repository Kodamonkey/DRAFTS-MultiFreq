# Build with:
# docker build --no-cache -t "alex88ridolfi/presto5:latest" - < Dockerfile_presto5_ubuntu24.04.txt
# This dockerfile is heavily based on the one from the PRESTO Github repo made by Alessandro Ridolfi https://github.com/scottransom/presto/blob/master/examplescripts/Dockerfile_presto5_png_ubuntu24.04.txt

FROM ubuntu:24.04

LABEL maintainer="Cristobal Braga <cristobal.braga@ug.uchile.cl>"

# Suppress debconf warnings
ENV DEBIAN_FRONTEND=noninteractive
ENV PSRHOME=/software

RUN apt-get update &&\
    apt-get install -y --no-install-recommends \
    git \   
    ca-certificates

RUN apt install -y git build-essential libfftw3-bin libfftw3-dev pgplot5 libglib2.0-dev libcfitsio-bin libcfitsio-dev libpng-dev gfortran tcsh autoconf libx11-dev python3-dev python3-numpy python3-pip python3-venv python3-tk    emacs nano rsync less

# Make Python 3.12 the default version
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 1
RUN update-alternatives --install /usr/bin/python  python  /usr/bin/python3.12 1

RUN rm /usr/lib/python3.12/EXTERNALLY-MANAGED
RUN pip install meson meson-python ninja

#######################
# TEMPO
#######################
WORKDIR $PSRHOME
RUN git clone https://git.code.sf.net/p/tempo/tempo

ENV TEMPO=$PSRHOME"/tempo" \
    PATH=$PATH:$PSRHOME"/tempo/bin"

WORKDIR $PSRHOME/tempo
RUN ./prepare

RUN ./configure --prefix=$PSRHOME/tempo && \
    make && \
    make install

#######################
# PRESTO
#######################
WORKDIR $PSRHOME

RUN git clone https://github.com/scottransom/presto.git presto5

WORKDIR $PSRHOME/presto5

ENV PGPLOT_DIR="/usr/lib/pgplot5" \
    PGPLOT_FONT="/usr/lib/pgplot5/grfont.dat" \
    PGPLOT_INCLUDES="/usr/include" \
    PGPLOT_BACKGROUND="white" \
    PGPLOT_FOREGROUND="black" \
    PGPLOT_DEV="/xs"

ENV PRESTO="/software/presto5"
ENV PATH="${PRESTO}/installation/bin:${PATH}"
ENV LIBRARY_PATH=${PRESTO}/installation/lib/x86_64-linux-gnu
ENV LD_LIBRARY_PATH=${PRESTO}/installation/lib/x86_64-linux-gnu

WORKDIR $PSRHOME/presto5

RUN meson setup build --prefix=/software/presto5/installation
RUN python check_meson_build.py
RUN meson compile -C build
RUN meson install -C build

WORKDIR ${PRESTO}/python
RUN pip install --config-settings=builddir=build .

WORKDIR ${PRESTO}/src
RUN ${PRESTO}/build/src/makewisdom
RUN mv  ${PRESTO}/src/fftw_wisdom.txt ${PRESTO}/lib

RUN echo 'export PS1="\[\e[4;30m\]\u@\h\[\e[0m\]:\[\e[1;10m\]\w\[\e[0m\]\$ (docker)> "' >> ~/.bashrc
RUN echo 'alias ls="ls --color=auto"'       >> ~/.bashrc
RUN echo 'alias ll="ls -l"'                 >> ~/.bashrc
RUN echo 'alias LL="ls -lL"'                >> ~/.bashrc
RUN echo 'alias lt="ls -lrt --color"'       >> ~/.bashrc
RUN echo 'alias lh="ls -lh --color"'        >> ~/.bashrc
RUN echo 'alias rm="rm -i"'                 >> ~/.bashrc
RUN echo 'alias cp="cp -i"'                 >> ~/.bashrc
RUN echo 'alias mv="mv -i"'                 >> ~/.bashrc
RUN echo 'alias emacs="emacs -nw"'          >> ~/.bashrc

#######################
# FRB Pipeline
#######################
WORKDIR $PSRHOME

# Copy the local repository to the Docker image
COPY . $PSRHOME/pulse-simulation

WORKDIR $PSRHOME/pulse-simulation
RUN pip install -e .

WORKDIR ${PSRHOME}

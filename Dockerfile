# Author: Tom Stesco
# email: tom.stesco@gmail.com
FROM ubuntu:16.04

MAINTAINER Tom Stesco <tom.stesco@gmail.com>

# build config vars
ARG IPOPT_VER="3.12.10"
ARG JMODELICA_TAG="trunk"
# build dirs
ENV BUILD_DIR="/opt"
ENV TMP_DIR="/tmp"
ENV JMODELICA_DIR="JModelica"

# define environment variables for JModelica
ENV USER="root"
ENV JAVA_HOME="/usr/lib/jvm/java-8-openjdk-amd64/"
ENV IPOPT_HOME="$BUILD_DIR/Ipopt"
ENV JMODELICA_HOME="$BUILD_DIR/$JMODELICA_DIR"
ENV MODELICAPATH="$JMODELICA_HOME/ThirdParty/MSL"
ENV CPPAD_HOME="$JMODELICA_HOME/ThirdParty/CppAD/"
ENV SUNDIALS_HOME="$JMODELICA_HOME/ThirdParty/Sundials"
ENV PYTHONPATH="$PYTHONPATH:$JMODELICA_HOME/Python:$JMODELICA_HOME/Python/pymodelica:\
$BUILD_DIR/MPCPy:$BUILD_DIR/EstimationPy"
ENV LD_LIBRARY_PATH=:"$IPOPT_HOME/lib/:$SUNDIALS_HOME/lib:\
$JMODELICA_HOME/ThirdParty/CasADi/lib:$LD_LIBRARY_PATH"
ENV SEPARATE_PROCESS_JVM="$JAVA_HOME"

# envs dependencies
ARG IPOPT_APT_DEPS="liblapack-dev libblas-dev"
ARG JMODELICA_APT_DEPS="gcc make g++ gfortran swig ant cmake default-jre-headless \
	python-jpype zlib1g-dev libboost-dev jcc subversion wget patch pkg-config"
ARG JMODELICA_PYTHON_DEPS="numpy scipy cython lxml nose matplotlib simulatortofmu tzwhere ipykernel"
ARG MPCPY_APT_DEPS="git libgeos-dev python-tk"
ARG MPCPY_PYTHON_DEPS="pandas"
ARG DEV_APT_DEPS="vim dc"
ARG DEV_PYTHON_DEPS="jupyterlab"
# add additional miscellaneous python deps here
ARG OTHER_PYTHON_DEPS=""

# add tmp and build dirs
RUN mkdir -p "$TMP_DIR" \
    && mkdir -p "$TMP_DIR/Ipopt" \
    && mkdir -p "$TMP_DIR/$JMODELICA_DIR" \
    && mkdir -p "$BUILD_DIR" \
    && mkdir -p "$BUILD_DIR/Ipopt"

# install ppa lists
RUN apt-get -y update \
	&& apt-get install -y software-properties-common python-software-properties

# install python 2.7.14
RUN add-apt-repository -y ppa:jonathonf/python-2.7 \
	&& apt-get -y update \
	&& apt-get install -y python python-dev build-essential python-setuptools \
	&& easy_install pip

# install apt build packages
RUN apt-get -y update \
    && apt-get install -y $IPOPT_APT_DEPS $JMODELICA_APT_DEPS $MPCPY_APT_DEPS \
        $DEV_APT_DEPS

# install python packages via pip
RUN pip install --upgrade pip \
    && pip install $JMODELICA_PYTHON_DEPS $MPCPY_PYTHON_DEPS $OTHER_PYTHON_DEPS \
    $DEV_PYTHON_DEPS

# retrieve and build Ipopt
RUN cd ${TMP_DIR}/Ipopt \
    && wget http://www.coin-or.org/download/source/Ipopt/Ipopt-${IPOPT_VER}.tgz \
    && tar xvf Ipopt-${IPOPT_VER}.tgz \
    && cd "$TMP_DIR/Ipopt/Ipopt-${IPOPT_VER}/ThirdParty/Blas" \
    && ./get.Blas \
    && cd "$TMP_DIR/Ipopt/Ipopt-${IPOPT_VER}/ThirdParty/Lapack" \
    && ./get.Lapack \
    && cd "$TMP_DIR/Ipopt/Ipopt-${IPOPT_VER}/ThirdParty/Mumps" \
    && ./get.Mumps \
    && cd "$TMP_DIR/Ipopt/Ipopt-${IPOPT_VER}/ThirdParty/Metis" \
    && ./get.Metis \
    && cd "$TMP_DIR/Ipopt/Ipopt-${IPOPT_VER}" \
    && ./configure --prefix="$BUILD_DIR/Ipopt" \
    && make \
    && make install

# build and install JModelica
# If Assimulo is not found try silencing error with ";exit 0" \
# then: RUN svn export --force https://svn.jmodelica.org/assimulo/trunk/ \
#   "$TMP_DIR/$JMODELICA_DIR/external/Assimulo"
# see: http://www.jmodelica.org/27840
RUN svn export --force https://svn.jmodelica.org/$JMODELICA_TAG \
        "$TMP_DIR/$JMODELICA_DIR" \
    && cd "$TMP_DIR/$JMODELICA_DIR" \
    && mkdir build \
    && cd build \
    && ../configure --prefix="$BUILD_DIR/$JMODELICA_DIR" --with-ipopt="$BUILD_DIR/Ipopt" \
    && make \
    && make install \
    && make casadi_interface

# WARNING: FOR LOCAL HOSTING ONLY
# disable authentication for jupyter notebook server 
RUN mkdir "/root/.jupyter" \
    && touch /root/.jupyter/jupyter_notebook_config.py \
    && echo "c.NotebookApp.token = u''" >> ~/.jupyter/jupyter_notebook_config.py

# cleanup
RUN apt-get clean \
    && apt-get autoremove \
    && rm -rf /var/lib/apt/lists/* ${TMP_DIR}/* /var/tmp/*

WORKDIR "/root"
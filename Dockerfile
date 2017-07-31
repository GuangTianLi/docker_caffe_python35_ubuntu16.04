FROM ubuntu:16.04


ADD dockerfile/deep_ocr_python3/sources.list /etc/apt/sources.list
RUN apt-get update --fix-missing

# Install dependencies
RUN apt-get install -y --no-install-recommends cmake
RUN apt-get install -y --no-install-recommends git
RUN apt-get install -y --no-install-recommends wget
RUN apt-get install -y --no-install-recommends libatlas-base-dev
RUN apt-get install -y --no-install-recommends libboost-all-dev
RUN apt-get install -y --no-install-recommends libgflags-dev
RUN apt-get install -y --no-install-recommends libgoogle-glog-dev
RUN apt-get install -y --no-install-recommends libhdf5-serial-dev
RUN apt-get install -y --no-install-recommends libleveldb-dev
RUN apt-get install -y --no-install-recommends libopencv-dev
RUN apt-get install -y --no-install-recommends libprotobuf-dev
RUN apt-get install -y --no-install-recommends libsnappy-dev
RUN apt-get install -y --no-install-recommends protobuf-compiler
RUN rm -rf /var/lib/apt/lists/*

## Python3
RUN apt-get update
RUN apt-get install -y python3-dev python3-pip ipython3

ENV CAFFE_ROOT=/opt/caffe
WORKDIR $CAFFE_ROOT

# FIXME: clone a specific git tag and use ARG instead of ENV once DockerHub supports this.
ENV CLONE_TAG=master

RUN git clone -b ${CLONE_TAG} --depth 1 https://github.com/BVLC/caffe.git .
RUN mkdir ~/.pip && touch ~/.pip/pip.conf
RUN echo "[global]\ntrusted-host =  mirrors.aliyun.com\nindex-url = http://mirrors.aliyun.com/pypi/simple\n" >> ~/.pip/pip.conf
RUN pip3 install --upgrade pip
RUN for req in $(cat python/requirements.txt) pydot; do pip3 install $req; done
ADD dockerfile/deep_ocr_python3/Makefile.config ./Makefile.config
RUN ln -s /usr/lib/x86_64-linux-gnu/libboost_python-py35.so /usr/lib/x86_64-linux-gnu/libboost_python3.so

RUN apt-get install -y liblmdb-dev
RUN ln -s /usr/lib/x86_64-linux-gnu/libhdf5_serial.so.10.1.0 /usr/lib/x86_64-linux-gnu/libhdf5.so
RUN ln -s /usr/lib/x86_64-linux-gnu/libhdf5_serial_hl.so.10.0.2 /usr/lib/x86_64-linux-gnu/libhdf5_hl.so
RUN ldconfig
RUN make all
RUN make test
RUN make runtest
RUN apt-get install python3-numpy
RUN make pycaffe

ENV PYCAFFE_ROOT $CAFFE_ROOT/python
ENV PYTHONPATH $PYCAFFE_ROOT:$PYTHONPATH

RUN pip3 install python-dateutil --upgrade

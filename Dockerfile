FROM kbase/kbase:sdkbase2.latest
MAINTAINER KBase Developer
# -----------------------------------------

# Insert apt-get instructions here to install
# any required dependencies for your module.
WORKDIR /kb/module

COPY ./cpanfile /kb/module/cpanfile
COPY ./MFAToolkit /kb/module/MFAToolkit
COPY ./data/classifier.txt /kb/module/data/
COPY ./Makefile /kb/module/
RUN make deploy-mfatoolkit

RUN cpanm --installdeps .

COPY ./ /kb/module
RUN mkdir -p /kb/module/work
ENV PATH=$PATH:/kb/dev_container/modules/kb_sdk/bin

RUN chmod -R a+rw /kb/module
RUN make

ENTRYPOINT [ "./scripts/entrypoint.sh" ]

CMD [ ]
FROM centos/python-36-centos7

USER root
RUN pip install --upgrade pip

# Setup Deployer
ADD / /deployer
WORKDIR /deployer
RUN python setup.py sdist
RUN pip install dist/deployer-*.tar.gz

RUN yum install epel-release -y
RUN yum install nodejs -y

RUN mkdir ~/.npm-global
RUN npm config set prefix '~/.npm-global'
RUN export PATH=~/.npm-global/bin:$PATH
RUN source ~/.profile

# Prep workspace
RUN mkdir /workspace
WORKDIR /workspace
VOLUME /workspace

CMD /opt/app-root/bin/deployer
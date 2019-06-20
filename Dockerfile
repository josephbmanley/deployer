FROM centos/python-36-centos7

USER root
RUN pip install --upgrade pip

# Setup Deployer
ADD / /deployer
WORKDIR /deployer
RUN python setup.py sdist
RUN pip install dist/deployer-*.tar.gz



RUN yum update -y



RUN wget https://nodejs.org/download/release/latest-v12.x/node-v12.4.0-linux-x64.tar.gz
RUN tar --strip-components 1 -xzvf node-v* -C /usr/local

RUN npm install -g npm

RUN npm -v
RUN node -v

RUN chmod 777 ~/.npm

# Prep workspace
RUN mkdir /workspace
WORKDIR /workspace
VOLUME /workspace

CMD /opt/app-root/bin/deployer
FROM jenkins
MAINTAINER Jason Lantz jlantz@salesforce.com

USER root

RUN apt-get update 

RUN apt-get install -y apparmor
#RUN apt-get install -y docker.io

# Set up sudo for user jenkins to run docker client
RUN apt-get install -y sudo
RUN echo "jenkins    ALL=NOPASSWD: /usr/bin/docker" >> /etc/sudoers.d/jenkins

# Install pip and jenkins-job-builder python module
RUN apt-get install -y python-pip
RUN apt-get install -y python-virtualenv
RUN pip install jenkins-job-builder
RUN pip install selenium
RUN pip install requests
RUN pip install PyGithub==1.25.1
RUN pip install simple-salesforce

# Install ant
RUN apt-get install -y ant

# Install docker
#RUN apt-get install -y docker.io

# Set up the jenkins user
RUN usermod -d /var/jenkins_credentials jenkins

# Create /var/jenkins_credentials
RUN mkdir /var/jenkins_credentials
RUN chown jenkins.jenkins /var/jenkins_credentials

USER jenkins

#RUN exec ssh -T -oStrictHostKeyChecking=no git@github.com

COPY plugins.txt /plugins.txt
#ADD jobs/ /var/jenkins_home/jobs/

VOLUME ./jenkins_home /var/jenkins_home
VOLUME ./credentials /var/jenkins_credentials

# Install plugins from list
RUN /usr/local/bin/plugins.sh /plugins.txt

# Install job dsl plugin
RUN curl -L https://github.com/steve-jansen/job-dsl-plugin/releases/download/JENKINS-21750-pre-release/job-dsl-jenkins-21750.hpi -o /usr/share/jenkins/ref/plugins/job-dsl-jenkins.hpi;

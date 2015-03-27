# Overview

The goal of CumulusCIJenkins is to make it easy to deploy a customized Jenkins instance for use with CumulusCI to run a best practices based development and release workflow for managed package development on the Force.com platform.

With a recent Linux server, you should be able to get everything set up and running in about 30 minutes.  CumulusCIJenkins doesn't care where your server runs so it could be in a VM, AWS, Rackspace Cloud, or a dedicated machine.

# Quick Start

## Server Set Up

* Spin up an Ubuntu 14 LTS server with a public IP (AWS, Rackspace, etc)
* Log into your server as root
    * If not logged in as root, use `sudo su -` to switch to root
* Install needed packages

    apt-get update
    apt-get install docker.io
    apt-get install git
    apt-get install python-pip

    # Install the jenkins-job-builder python module
    pip install jenkins-job-builder

    # Install fig
    curl -L https://github.com/docker/fig/releases/download/1.0.1/fig-`uname -s`-`uname -m` > /usr/local/bin/fig; chmod +x /usr/local/bin/fig

* Switch to the ubuntu user

    su - ubuntu

## Jenkins

* Clone CumulusCIJenkins

    git clone https://github.com/SalesforceFoundation/CumulusCIJenkins
    cd CumulusCIJenkins

* Build and launch the Jenkins image

    sudo fig build
    sudo fig up

* Connect to Jenkins

    http://YOUR_SERVER_IP:8080

* Kill Jenkins with Ctrl-C in the terminal window

* Start Jenkins as a daemon
    
    sudo fig start

## Jenkins Jobs

* Define jobs for your project's repository

    cp jobs/jobs.yml.example jobs/jobs.yml
    vi jobs/jobs.yml

    # Change the name: and github_user: lines to match the repository owner and repository name in Github

* Test your jobs
    
    jenkins-jobs --conf jenkins_jobs.ini test jobs/jobs.yml

    # You should see the generated job xml.  If you see an error, check the error and your job.yml to resolve

* Deploy your jobs to jenkins
    
    jenkins-jobs --conf jenkins_jobs.ini update jobs/jobs.yml

* Setup Github ssh key
    * If you already have an ssh key set up with your Github account and want to reuse it for Jenkins, copy the `id_rsa` and `id_rsa.pub` files to `CumulusCIJenkins/credentials/.ssh` on the server
    * If you need to generate a new ssh key, follow instructions from Github...
        https://help.github.com/articles/generating-ssh-keys/
   
    cp ~/.ssh/id_rsa* ~/CumulusCIJenkins/credentials/.ssh
    
# Credentials

* Create credentials files
    
    cd credentials

    echo "sf.username = YOUR_USERNAME_HERE" > YourRepoName.feature
    echo "sf.password = YOUR_PASS_AND_SECURITY_TOKEN_HERE" >> YourRepoName.feature
    echo "sf.serverurl = https://login.salesforce.com" >> YourRepoName.feature

    cp YourRepoName.feature YourRepoName.master
    cp YourRepoName.feature YourRepoName.package
    cp YourRepoName.feature YourRepoName.beta
    cp YourRepoName.feature YourRepoName.release

    # Edit each of the 5 files to add your Salesforce username, password, and security token for each org

    # Use https://cumulusci-oauth-tool.herokuapp.com to capture values for below
    echo "export OAUTH_CALLBACK_URL=YOUR_CONNECTED_APP_CALLBACK_URL" > YourRepoName.package.oauth
    echo "export OAUTH_CLIENT_ID=YOUR_CONNECTED_APP_CLIENT_ID" >> YourRepoName.package.oauth
    echo "export OAUTH_CLIENT_SECRET=YOUR_CONNECTED_APP_CLIENT_SECRET" >> YourRepoName.package.oauth
    echo "export REFRESH_TOKEN=REFRESH_TOKEN_TO_PACKAGE_ORG" >> YourRepoName.package.oauth
    echo "export INSTANCE_URL=PACKAGING_ORG_INSTANCE_URL" >> YourRepoName.package.oauth

    # Github credentials
    # See https://help.github.com/articles/creating-an-access-token-for-command-line-use/
    echo "export GITHUB_USERNAME=YOUR_GITHUB_USER" > YourRepoName.github
    echo "export GITHUB_PASSWORD=YOUR_GITHUB_APP_TOKEN" >> YourRepoName.github

    # mrbelvedere credentials (optional)
    # If configured, will automatically publish beta for installation after successful build
    echo "export MRBELVEDERE_BASE_URL=https://YOUR_MRBELVEDERE_URL/mpinstaller" > YourRepoName.mrbelvedere
    echo "export MRBELVEDERE_PACKAGE_KEY=YOUR_PACKAGE_API_KEY" >> YourRepoName.mrbelvedere

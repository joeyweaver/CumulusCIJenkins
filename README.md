# Overview

The goal of CumulusCIJenkins is to make it easy to deploy a customized Jenkins instance for use with CumulusCI to run a best practices based development and release workflow for managed package development on the Force.com platform.

With a recent Linux server, you should be able to get everything set up and running in about 30 minutes.  CumulusCIJenkins doesn't care where your server runs so it could be in a VM, AWS, Rackspace Cloud, or a dedicated machine.

# Quick Start

## Server Set Up

Spin up an Ubuntu 14 LTS server with a public IP (AWS, Rackspace, etc). Log into your server as root, or run `sudo su -` to switch to root.

### Install needed packages

    apt-get update
    apt-get install docker.io
    apt-get install git
    apt-get install python-pip
    pip install jenkins-job-builder
    curl -L https://github.com/docker/fig/releases/download/1.0.1/fig-`uname -s`-`uname -m` > /usr/local/bin/fig; chmod +x /usr/local/bin/fig

## Jenkins

Switch to the ubuntu user

    su - ubuntu

Clone CumulusCIJenkins

    git clone https://github.com/SalesforceFoundation/CumulusCIJenkins
    cd CumulusCIJenkins

Build the Jenkins docker image

    sudo fig build
    
Launch the Jenkins image in the foreground
    
    sudo fig up

Connect to Jenkins in a browser

    http://YOUR_SERVER_IP:8080

Kill Jenkins with Ctrl-C in the terminal window.  Restart Jenkins as a daemon running in background mode
    
    sudo fig start

## Jenkins Jobs

Job configurations are stored in the `jobs` subdirectory of the repository.  The `cumulusci_jobs.yml` file contains job templates for the various common Jenkins jobs used for CumulusCI.  The templates are designed to handle everything except things specific to your project like the repository owner and name.  Configuring the jobs for a new repository involves adding about 10 lines of YAML configuration for each project.

Define jobs for your project's repository

    cp jobs/jobs.yml.example jobs/jobs.yml
    vi jobs/jobs.yml

Change the name: and github_user: lines to match the repository owner and repository name in Github.  Then, test your project's jobs.
    
    jenkins-jobs --conf jenkins_jobs.ini test jobs/jobs.yml

You should see the generated job xml.  If you see an error, check the error and your job.yml to resolve.  If everything looks good, deploy your jobs to jenkins
    
    jenkins-jobs --conf jenkins_jobs.ini update jobs/jobs.yml
    
You can re-run this command at any time to update the job configuration from the jobs.yml file after an edit.

## Setup Github ssh key

If you already have an ssh key set up with your Github account and want to reuse it for Jenkins, copy the `id_rsa` and `id_rsa.pub` files to `CumulusCIJenkins/credentials/.ssh` on the server

If you need to generate a new ssh key, follow instructions from Github: https://help.github.com/articles/generating-ssh-keys/ and then copy the generated key 
   
    cp ~/.ssh/id_rsa* ~/CumulusCIJenkins/credentials/.ssh
    
## Credentials

### Salesforce DE Orgs

Create credentials files for 5 DE orgs, 1 Github user, and optionally for mrbelvedere...
    
    cd credentials

    echo "sf.username = YOUR_USERNAME_HERE" > YourRepoName.feature
    echo "sf.password = YOUR_PASS_AND_SECURITY_TOKEN_HERE" >> YourRepoName.feature
    echo "sf.serverurl = https://login.salesforce.com" >> YourRepoName.feature

    cp YourRepoName.feature YourRepoName.master
    cp YourRepoName.feature YourRepoName.package
    cp YourRepoName.feature YourRepoName.beta
    cp YourRepoName.feature YourRepoName.release

Edit each of the 5 files to add your Salesforce username, password, and security token for each org

### Packaging Org OAuth

Use https://cumulusci-oauth-tool.herokuapp.com to capture values for below.  This credential is used by the Selenium based package uploader which automates beta package uploads in the packaging org.

    echo "export OAUTH_CALLBACK_URL=YOUR_CONNECTED_APP_CALLBACK_URL" > YourRepoName.package.oauth
    echo "export OAUTH_CLIENT_ID=YOUR_CONNECTED_APP_CLIENT_ID" >> YourRepoName.package.oauth
    echo "export OAUTH_CLIENT_SECRET=YOUR_CONNECTED_APP_CLIENT_SECRET" >> YourRepoName.package.oauth
    echo "export REFRESH_TOKEN=REFRESH_TOKEN_TO_PACKAGE_ORG" >> YourRepoName.package.oauth
    echo "export INSTANCE_URL=PACKAGING_ORG_INSTANCE_URL" >> YourRepoName.package.oauth

### Github credentials
These credentials are used in a few places in the build to automate merges, tags, releases, and release notes generation.  See https://help.github.com/articles/creating-an-access-token-for-command-line-use/

    echo "export GITHUB_USERNAME=YOUR_GITHUB_USER" > YourRepoName.github
    echo "export GITHUB_PASSWORD=YOUR_GITHUB_APP_TOKEN" >> YourRepoName.github

### mrbelvedere credentials (optional)
If you are using mrbelvedere to publish your beta packages for installation, you can provide the information needed to automatically publish betas after they pass build.

    echo "export MRBELVEDERE_BASE_URL=https://YOUR_MRBELVEDERE_URL/mpinstaller" > YourRepoName.mrbelvedere
    echo "export MRBELVEDERE_PACKAGE_KEY=YOUR_PACKAGE_API_KEY" >> YourRepoName.mrbelvedere
    
# Locking Down Jenkins

The default Jenkins image has no authorization set up so all anonymous users can do anything.  **Do not leave your Jenkins installation running this way!!!**

Go to your Jenkins instance in a browser and follow the instructions from Jenkins:
https://wiki.jenkins-ci.org/display/JENKINS/Standard+Security+Setup

Since all Jenkins data and configuration is stored on the host filesystem and made available to the Docker container running Jenkins, any changes you make under Manage Jenkins will persist through starting and stopping of the container and even rebuilds of the image.

## Setting new credentials for jenkins-job-builder

Once you enable security, you'll need to set new credentials for the jenkins-job-builder to use when updating jobs via the Jenkins API.  The easiest way to do this is to first copy the default jenkins_jobs.ini in the repository:

    mkdir /etc/jenkins_jobs
    cp jenkins_jobs.ini /etc/jenkins_jobs
    vi /etc/jenkins_jobs/jenkins_jobs.ini
    
You will need to edit the `user=` and `password=` lines in the file with the credentials from your new user.

One advantage of copying this file to this location is that the `jenkins-jobs` command automatically looks there for its config.  Now, there is no longer a need to pass the `--conf PATH_TO_CONF_FILE.ini` argument in the command.  You can update your jobs with the cleaner…

    jenkins-jobs update jobs/

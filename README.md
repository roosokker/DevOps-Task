# DevOps-Task
Dockerfile
----------

First I add a base python image and used a slim one for a lightweight image
then created directory /app
then coppied folder PythonApp and requirements.txt
then installing required packages from requirements.txt (Note that there were extra packgae needed so i added it)
then running the app using flask cli run

----------------------------------------------------
EKS-Cluster
-----------
Here's the terraform configurations to create the EKS Cluster

first i used a ready module from AWS for creating the VPC
i gave it the Cidr Block range and range for private a public subnets
after that i created the EKS Resource and EKS Node Group Resource that act as scheduler for creating pods and deployments
and added the needed policies for them

-----------------------------------------------------
Service.yml
-----------
using a loadbalancer service that expose the app into the internet
and forwarding the traffic into the container port i'm exposing into from container which is 5000

-------------------------------------------------------
deploymeny.yml
--------------
I am specifying a 3 replicas for deployments
using a container image the image i'm dockerizing from dockerfile and pushing into ECR Registry

-------------------------------------------------------
gitVersion
----------
an incremental version for git to tag every push on master branch
this will help on specifying image_tag dynamically and will be easier for roll back or using older version

-------------------------------------------------------
aws.yml
-------
This is the Github Action Workflow 
but i had an issue with setting AWS Credentials
it needed and OIDC and a github Organization 
it wasn't easy to be configured however i set the logic for the pipeline
where it will first login to ECR
then run the gitVersion Script to set new version
then push the image into ECR with new image 
then will setup the needed packages (awscli, kubectl)
then will apply the kubectl to configure the service and pod with newly created image

---------------------------------------------------------
cicd/buildspec.yml
------------------
i tried an alternative way for the pipeline however it wasnt a succesful one as it's missing kubectl permissions to apply the .yml file and as i'm running out of time i have no time to nvestigate however i added all the needed policies for the codebuild project

and it's also the same approach as aws.yml 
when it first install needed packages (awscli and kubectl)
then login to github with PAT
then run the script for tagging version
then login into ECR and push the image with newer version
and then set the current context the EKS-Cluster on AWS to apply on the kubectl commands
and then update the cluster
then apply the service.yml and deployment.yml
and pass the repositoryURL and image tag ENV_VARS to deployment.yml


finally you can access the app using these URLS:
http://ab18f454bb341408d9b008684674d3ee-1365521999.us-east-1.elb.amazonaws.com/users
http://ab18f454bb341408d9b008684674d3ee-1365521999.us-east-1.elb.amazonaws.com/products
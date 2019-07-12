library('pipeline-library@feature/add-with-ecr')

pipeline {
  options { timestamps() }
  agent any
  environment {
    SERVICE = 'deployer'
    GITHUB_KEY = 'Deployer'
    GITHUB_URL = 'git@github.com:RightBrain-Networks/deployer.git'
    DOCKER_REGISTRY = '356438515751.dkr.ecr.us-east-1.amazonaws.com'
    CURRENT_VERSION = ""
  }
  stages {
    stage('Version') {
      steps {
        script
        {
        envCURRENT_VERSION = getVersion('-d')
        }
        // runs the automatic semver tool which will version, & tag,
        runAutoSemver()
      }
    }
    stage('Build') {
      steps {


        echo "Building ${env.SERVICE} docker image"

        // Docker build flags are set via the getDockerBuildFlags() shared library.
        sh "docker build ${getDockerBuildFlags()} -t ${env.DOCKER_REGISTRY}/${env.SERVICE}:${getVersion('-d')} ."

        sh "python setup.py sdist"
      }
      post{
        // Update Git with status of build stage.
        success {
          updateGithubCommitStatus(GITHUB_URL, 'Passed build stage', 'SUCCESS', 'Build')
        }
        failure {
          updateGithubCommitStatus(GITHUB_URL, 'Failed build stage', 'FAILURE', 'Build')
        }
      }
    }
    stage('Ship')
    {
      steps {     
        withEcr {
            sh "docker push ${env.DOCKER_REGISTRY}/${env.SERVICE}:${getVersion('-d')}"
        }
        
        //Copy tar.gz file to s3 bucket
        sh "aws s3 cp dist/${env.SERVICE}-*.tar.gz s3://rbn-ops-pkg-us-east-1/${env.SERVICE}/${env.SERVICE}-${getVersion('-d')}.tar.gz"
        //}
      }
    }
    stage('Release Version')
    {
      when {
          expression {
              (env.CURRENT_VERSION  != getVersion('-d') || env.BRANCH_NAME == 'feature/jenkinsRelease')// && false
          }
      }
      steps
      {
        echo "New version deteced!"
        script
        {

          //Needs to releaseToken from Secrets Manager
          releaseToken = sh(returnStdout : true, script: "aws secretsmanager get-secret-value --secret-id deployer/gitHub/releaseKey --region us-east-1 --output text --query SecretString").trim()

          releaseId = sh(returnStdout : true, script : """
          curl -XPOST -H 'Authorization:token ${releaseToken}' --data '{"tag_name": "0.4.0", "target_commitish": "development", "name": "v0.4.0", "draft": true, "prerelease": true}' https://api.github.com/repos/RightBrain-Networks/deployer/releases |  jq -r ."id"
          """).trim()



          echo("${releaseId}")

          echo("Uploading artifacts...")
          sh("""
            echo "Uploading ${sh("dist/deployer-*.tar.gz")} ..."
            """)
        }
      }
    }
    stage('Push Version and Tag') {
        steps {
            echo "The current branch is ${env.BRANCH_NAME}."
            gitPush(env.GITHUB_KEY, env.BRANCH_NAME, true)
        }
    }
  }
  post {
    always {
      removeDockerImages()
      cleanWs()
    }
  }
}

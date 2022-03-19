// anchore plugin for jenkins: https://www.jenkins.io/doc/pipeline/steps/anchore-container-scanner/

pipeline {
  environment {
    // "REGISTRY" isn't required if we're using docker hub, I'm leaving it here in case you want to use a different registry
    // REGISTRY = 'registry.hub.docker.com'
    // you need a credential named 'docker-hub' with your DockerID/password to push images
    CREDENTIAL = "docker-hub"
    DOCKER_HUB = credentials("$CREDENTIAL")
    REPOSITORY = "${DOCKER_HUB_USR}/${JOB_BASE_NAME}"
    TAG = ":devbuild-${BUILD_NUMBER}"
    IMAGELINE = "${REPOSITORY}${TAG} Dockerfile"
  } // end environment 
  agent any
  stages {
    stage('Checkout SCM') {
      steps {
        checkout scm
      } // end steps
    } // end stage "checkout scm"
    stage('Build image and push to registry') {
      steps {
        script {
          sh "about to build ${REPOSITORY}"
          dockerImage = docker.build REPOSITORY + TAG
          docker.withRegistry( '', CREDENTIAL ) { 
            dockerImage.push() 
          }
        } // end script
      } // end steps
    } // end stage "build image and push to registry"
    stage('Analyze with Anchore plugin') {
      steps {
        writeFile file: 'anchore_images', text: IMAGELINE
        script {
          try {
            // forceAnalyze is a good idea since we're passing a Dockerfile with the image
            anchore name: 'anchore_images', forceAnalyze: 'true', engineRetries: '900'
          } catch (err) {
            // if scan fails, clean up (delete the image) and fail the build
            sh 'docker rmi ${REPOSITORY}${TAG}'
            sh 'exit 1'
          } // end try
        } // end script 
      } // end steps
    } // end stage "analyze with anchore plugin"
    stage('Re-tag as prod and push stable image to registry') {
      steps {
        script {
          docker.withRegistry('', CREDENTIAL) {
            dockerImage.push('prod') 
            // dockerImage.push takes the argument as a new tag for the image before pushing
          }
        } // end script 
      } // end steps
    } // end stage "retag as prod"
    stage('Clean up') {
      // if we succuessfully pushed the :prod tag than we don't need the $BUILD_ID tag anymore
      steps {
        sh 'docker image rm ${REPOSITORY}${TAG} ${REPOSITORY}:prod || failure=1'
      } // end steps
    } // end stage "clean up"
  } // end stages
} // end pipeline 

pipeline {
    agent any

    environment {
        PROJECT_ID   = 'YOUR_PROJECT_ID'
        REGION       = 'asia-south1'
        REPO_NAME    = 'webapp-repo'
        SERVICE_NAME = 'java-demo-webapp'
        RUNTIME_SA   = "sa-webapp-runtime@${PROJECT_ID}.iam.gserviceaccount.com"
        IMAGE_URI    = "${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO_NAME}/${SERVICE_NAME}:${BUILD_NUMBER}"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build & Push Image') {
            steps {
                sh """
                    gcloud auth configure-docker ${REGION}-docker.pkg.dev --quiet
                    docker build -t ${IMAGE_URI} .
                    docker push ${IMAGE_URI}
                """
            }
        }

        stage('Deploy to Cloud Run') {
            steps {
                sh """
                    gcloud run deploy ${SERVICE_NAME} \
                      --image ${IMAGE_URI} \
                      --region ${REGION} \
                      --platform managed \
                      --service-account ${RUNTIME_SA} \
                      --allow-unauthenticated \
                      --memory 512Mi \
                      --cpu 1 \
                      --min-instances 0 \
                      --max-instances 2
                """
            }
        }
    }

    post {
        always {
            sh "docker rmi ${IMAGE_URI} || true"
        }
    }
}
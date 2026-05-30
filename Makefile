.PHONY: build run docker-build docker-build-db argocd-deploy db-init clean

ECR_REPO = 293222827824.dkr.ecr.us-east-1.amazonaws.com/roboshop-catalogue

build:
	go mod tidy && go build -o catalogue .

run:
	MYSQL_HOST=localhost MYSQL_USER=catalogue MYSQL_PASSWORD=RoboShop@1 MYSQL_DATABASE=catalogue go run .

docker-build:
	aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 293222827824.dkr.ecr.us-east-1.amazonaws.com
	docker build -t $(ECR_REPO):$(image_tag) .
	trivy image $(ECR_REPO):$(image_tag) -s CRITICAL,HIGH --ignore-unfixed
	docker push $(ECR_REPO):$(image_tag)

docker-build-db:
	aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 293222827824.dkr.ecr.us-east-1.amazonaws.com
	docker build -t $(ECR_REPO)-db:latest ./db
	trivy image $(ECR_REPO)-db:latest -s CRITICAL,HIGH --ignore-unfixed
	docker push $(ECR_REPO)-db:latest

argocd-deploy:
	argocd login $(argocd_server) --skip-test-tls --username admin --password $(argocd_admin_password)
	argocd app create roboshop-catalogue --sync-policy auto --upsert \
		--repo https://github.com/nikkaushal/roboshop-helm-v1.git \
		--path . \
		--dest-server https://kubernetes.default.svc \
		--dest-namespace roboshop \
		--sync-option CreateNamespace=true \
		--helm-set image_tag=$(image_tag) \
		--values values/roboshop-catalogue.yml

db-init:
	mysql -h $${MYSQL_HOST:-localhost} -u root -pRoboShop@1 < db/app-user.sql
	mysql -h $${MYSQL_HOST:-localhost} -u root -pRoboShop@1 < db/schema.sql
	mysql -h $${MYSQL_HOST:-localhost} -u root -pRoboShop@1 < db/master-data.sql

clean:
	rm -f catalogue

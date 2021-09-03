-include Makefile.env

CIVO_CONTAINER?=civo/cli:v0.7.30

BUILD_REPO?=quay.io/ssmiller25

USER=$(shell id -u)
GROUP=$(shell id -g)

USERNAME?=$(shell id -nu)

TERRAFORM=docker run --rm -it -u $(USER):$(GROUP) -v $$(pwd)/infra:/workdir $(TERRAFORM_CONTAINER) 
CIVO=docker run --rm -it -u $(USER):$(GROUP) -v $$HOME/.civo.json:/.civo.json -v $$HOME/.kube:/.kube $(CIVO_CONTAINER)

${HOME}/.civo.json:
	@echo "Creating .civo.json configuration file"
	@touch $$HOME/.civo.json
	@$(CIVO) apikey add civokey $(civo_token)

.PHONY: k3s-list
k3s-list: ${HOME}/.civo.json
	@$(CIVO) k3s list

.PHONY: civo-up
civo-up: 
	@echo "This will provision a 2 X 3-node medium Civo k3s cluster"
	@echo "Please ensure you understand the costs (\$$32/month USD as of 08/2021) before continuing"
	@echo "Press Enter to Continue, or Ctrl+C to abort"
	@read nothing
	@echo "Provisioning production"
	@touch $$HOME/.civo.json
	@mkdir $$HOME/.kube/ || true
	@touch $$HOME/.kube/config
	@$(CIVO) k3s create onlineboutique-prod --size g3.k3s.medium --nodes 3 --wait
	@$(CIVO) k3s config onlineboutique-prod > $$HOME/.kube/ob.prod
	@$(CIVO) k3s create onlineboutique-dev --size g3.k3s.medium --nodes 3 --wait
	@$(CIVO) k3s config onlineboutique-dev > $$HOME/.kube/ob.dev
	@KUBECONFIG=$$HOME/.kube/ob.prod:$$HOME/.kube/ob.dev:$$HOME/.kube/config kubectl config view --merge --flatten > $$HOME/.kube/config
	@rm $$HOME/.kube/ob.prod $$HOME/.kube/ob.dev || true	

.PHONY: civo-down
civo-down:
	@$(CIVO) k3s remove onlineboutique-prod || true
	@kubectl config delete-context onlineboutique-prod || true
	@kubectl config delete-user onlineboutique-prod || true
	@$(CIVO) k3s remove onlineboutique-dev || true
	@kubectl config delete-context onlineboutique-dev || true
	@kubectl config delete-user onlineboutique-dev || true

.PHONY: prod
prod:
	@kubectl config use-context onlineboutique-prod
	@echo "Deploying latest code to onlineboutique-prod"
	@kubectl create ns cnapp-prod || true
	@skaffold run -f=skaffold.yaml --default-repo=$(BUILD_REPO) -n cnapp-prod
	@kubectl apply -n cnapp-prod -f kubernetes-manifests-ingress/ingress.yaml

.PHONY: pr check-pr
check-pr:
ifndef PR
	$(error PR is undefined)
endif

pr: check-pr
	@kubectl config use-context onlineboutique-dev
	@echo "Deploying latest code to onlineboutique-dev"
	@kubectl create ns cnapp-pr-$(PR) || true
	@skaffold run -f=skaffold.yaml --default-repo=$(BUILD_REPO) -n cnapp-pr-$(PR)
	@kubectl apply -n cnapp-pr-$(PR) -f kubernetes-manifests-ingress/ingress.yaml

.PHONY: dev
dev:
	@kubectl config use-context onlineboutique-dev
	@kubectl create ns cnapp-$(USERNAME) || true
	@echo "Deploying latest code to onlineboutique-dev"
	@skaffold run -f=skaffold.yaml --default-repo=$(BUILD_REPO) -n cnapp-$(USERNAME)
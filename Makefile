include Makefile.env

# Same as terraform:light, but calling out specific version
TERRAFORM_CONTAINER?=hashicorp/terraform:1.0.5

CIVO_CONTAINER?=civo/cli:v0.7.30

USER=$(shell id -u)
GROUP=$(shell id -g)

TERRAFORM=docker run --rm -it -u $(USER):$(GROUP) -v $$(pwd)/infra:/workdir $(TERRAFORM_CONTAINER) 
CIVO=docker run --rm -it -u $(USER):$(GROUP) -v $$HOME/.civo.json:/.civo.json -v $$HOME/.kube/config:/.kube/config $(CIVO_CONTAINER)

${HOME}/.civo.json:
	@echo "Login to Civo, navigate to https://www.civo.com/account/security and generate a security key"
	@echo "Press Enter to Contine"
	@echo "Creating .civo.json configuration file"
	@read nothing
	@touch $$HOME/.civo.json
	@$(CIVO) apikey add civokey $(civo_token)

.phony: k3s-list
k3s-list: ${HOME}/.civo.json
	@$(CIVO) k3s list

.phony: provision-infra
	@echo "This will provision 2 3-node Civo k3s cluster"
	@echo "Please ensure you understand the costs ($16/month total as of 08/2021) before continuing"
	@echo "Press Enter to Continue, or Ctrl+C to abort"
	@read nothing
	@echo "Provisioning production"
	@$(CIVO) k3s create onlineboutique-prod --size g3.k3s.small --nodes 3 --wait
	@$(CIVO) k3s config onlineboutique-prod --merge

.phony: teardown-infra
	@$(CIVO)




.phony: prod-init
prod-init:
	$(TERRAFORM) -chdir=/workdir/prod init 

.phony: prod-plan
prod-plan:
	$(TERRAFORM) -chdir=/workdir/prod plan -var="civo_token=${civo_token}"

include Makefile.env

# Same as terraform:light, but calling out specific version
TERRAFORM_CONTAINER?=hashicorp/terraform:1.0.5

CIVO_CONTAINER?=civo/cli:v0.7.30

USER=$(shell id -u)
GROUP=$(shell id -g)

TERRAFORM=docker run --rm -it -u $(USER):$(GROUP) -v $$(pwd)/infra:/workdir $(TERRAFORM_CONTAINER) 
CIVO=docker run --rm -it -u $(USER):$(GROUP) -v $$HOME/.civo.json:/.civo.json $(CIVO_CONTAINER)

${HOME}/.civo.json:
	@echo "Login to Civo, navigate to https://www.civo.com/account/security and generate a security key"
	@echo "Press Enter to Contine"
	@read nothing
	@echo "Generating Civo APIKey"
	@touch $$HOME/.civo.json
	@$(CIVO) apikey add

.phone: k3s-list
k3s-list: ${HOME}/.civo.json
	@$(CIVO) k3s list

.phony: prod-init
prod-init:
	$(TERRAFORM) -chdir=/workdir/prod init 

.phony: prod-plan
prod-plan:
	$(TERRAFORM) -chdir=/workdir/prod plan -var="civo_token=${civo_token}"

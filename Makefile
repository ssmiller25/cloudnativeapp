include Makefile.env

# Same as terraform:light, but calling out specific version
TERRAFORM_CONTAINER?=hashicorp/terraform:1.0.5

CIVO_CONTAINER?=civo/cli:v0.7.30

USER=$(shell id -u)
GROUP=$(shell id -g)

TERRAFORM=docker run --rm -it -u $(USER):$(GROUP) -v $$(pwd)/infra:/workdir $(TERRAFORM_CONTAINER) 
CIVO=docker run --rm -it -u $(USER):$(GROUP) -v $$HOME/.civo.json:/.civo.json -v $$HOME/.kube:/.kube $(CIVO_CONTAINER)

${HOME}/.civo.json:
	@echo "Creating .civo.json configuration file"
	@touch $$HOME/.civo.json
	@$(CIVO) apikey add civokey $(civo_token)

.PHONY: k3s-list
k3s-list: ${HOME}/.civo.json
	@$(CIVO) k3s list

.PHONY: infra-up
infra-up:
	@echo "This will provision 2 3-node Civo k3s cluster"
	@echo "Please ensure you understand the costs ($16/month total as of 08/2021) before continuing"
	@echo "Press Enter to Continue, or Ctrl+C to abort"
	@read nothing
	@echo "Provisioning production"
	@$(CIVO) k3s create onlineboutique-prod --size g3.k3s.small --nodes 3 --wait
	@$(CIVO) k3s config onlineboutique-prod --merge
	@$(CIVO) k3s create onlineboutique-dev --size g3.k3s.small --nodes 3 --wait
	@$(CIVO) k3s config onlineboutique-dev --merge

.PHONY: infra-down
infra-down:
	@$(CIVO) k3s remove onlineboutique-prod
	@$(CIVO) k3s remove onlineboutique-dev

certs_dir    = "certs"
conf_dir     = "config"
network      = "vm-network"

#------------------------------------------------------------------------
##help: 		print this help message
help:
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/##//'

#------------------------------------------------------------------------
##clean-certs: 	deletes existing certificates.
clean-certs:
	@rm -rf ${certs_dir}

#------------------------------------------------------------------------
##gen-certs: 	generates new root/ca/workload certificates in certs/.
gen-certs:
	./scripts/gen-certs.sh

#------------------------------------------------------------------------
##deploy-istio: 	deploys istio to cluster using IstioOperator spec.
deploy-istio:
	istioctl install -f ${conf_dir}/istio/istiooperator.yaml -y

	kubectl apply -f ${conf_dir}/istio/gateway.yaml 

	kubectl apply -f ${conf_dir}/app.yaml 
	kubectl apply -f ${conf_dir}/fortune-teller/app.yaml

#------------------------------------------------------------------------
##docker-init: 	sets up docker for use by vm and k3d.
docker-init:
	docker network create ${network} || true > /dev/null 2>&1

#------------------------------------------------------------------------
##k3d-up: 	creates k3d cluster.
k3d-up: docker-init
	k3d cluster create --config ${conf_dir}/k3d-cluster.yaml && sleep 10s

#------------------------------------------------------------------------
##k3d-down: 	deletes k3d cluster.
k3d-down:
	k3d cluster delete --config ${conf_dir}/k3d-cluster.yaml || true

#------------------------------------------------------------------------
##vm-up: 		creates envoy vm.
vm-up: docker-init
	docker-compose up -d

#------------------------------------------------------------------------
##vm-down: 	deletes envoy vm.
vm-down:
	docker-compose rm --stop --force

#------------------------------------------------------------------------
##install: 	fresh full configuration and installation
install: clean k3d-up gen-certs deploy-istio vm-up
	
#------------------------------------------------------------------------
##teardown: 	stops environment and deletes containers.
teardown: k3d-down vm-down

#------------------------------------------------------------------------
##clean: 		cleans up entire working environment.
clean: teardown clean-certs
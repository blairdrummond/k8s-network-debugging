CLUSTER_NAME := k8s-network-debugging

NERDCTL := nerdctl \
		   --address /run/k3s/containerd/containerd.sock \
		   --namespace k8s.io

create delete:
	rm -f config.yaml
	k3d cluster $@ $(CLUSTER_NAME)

deploy: config.yaml
	kustomize build manifests | kubectl apply -f - --kubeconfig config.yaml
	sleep 60
	kustomize build manifests | kubectl apply -f - --kubeconfig config.yaml

config.yaml:
	k3d kubeconfig get $(CLUSTER_NAME) > $@

CONTAINER_ADDONS := container-addons/bin/nerdctl
container-addons/bin/nerdctl:
	mkdir -p $$(dirname $@)
	cd $$(dirname $@); \
		wget -O - https://github.com/containerd/nerdctl/releases/download/v0.21.0/nerdctl-0.21.0-linux-arm64.tar.gz | tar -xf - nerdctl

CONTAINER_ADDONS += container-addons/opt/cni/bin
container-addons/opt/cni/bin:
	mkdir -p $@
	cd $@; \
		wget https://github.com/containernetworking/plugins/releases/download/v1.1.1/cni-plugins-linux-arm64-v1.1.1.tgz;
		tar -xf *.tgz;
		rm *.tgz

# This operation IS NOT idempotent.
docker-cp: $(CONTAINER_ADDONS)
	for f in $^; do \
		docker exec k3d-$(CLUSTER_NAME)-server-0 mkdir -p $$(dirname $$(echo $$f | sed 's~[^/]*/~~')); \
		docker cp $$f k3d-$(CLUSTER_NAME)-server-0:/$$(echo $$f | sed 's~[^/]*/~~'); \
	done

# Get into the node
ps:
	@docker exec -it k3d-$(CLUSTER_NAME)-server-0 \
		$(NERDCTL) ps
			#network list
	#crictl run nicolaka/netshoot

netshoot:
	POD=$$(kubectl get pod -n gatekeeper-system -o name | grep manager | sed 1q); \
	ID=$$(kubectl get pod -n gatekeeper-system $$POD \
    -o jsonpath='{.status.containerStatuses[0].containerID}'); \
	docker exec -it k3d-$(CLUSTER_NAME)-server-0 \
		$(NERDCTL) -it --rm --net container:$$ID \
			nicolaka/netshoot tcpdump \
			-i eth0 -s 0 -Xvv tcp port 80

# docker run -it --rm --net container:k8s_nginx_my-nginx-b7d7bc74d-zxx28_default_ae4ee834-fb5d-4ec4-86b1-7834e538c666_0 nicolaka/netshoot tcpdump -i eth0 -s 0 -Xvv tcp port 80


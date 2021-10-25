build: ## Build the release and develoment container. The development
	podman build --no-cache -t quay.io/ralvares/ocp-security:terminal -f Dockerfile

build_cache: ## Build the release and develoment container. The development
	podman build -t quay.io/ralvares/ocp-security:terminal -f Dockerfile

push: ## Publish release
	podman push quay.io/ralvares/ocp-security:terminal

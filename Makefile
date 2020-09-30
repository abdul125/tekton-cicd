cluster-up:
	k3d cluster create tekton-cicd \
	    -p 80:80@loadbalancer \
	    -p 443:443@loadbalancer \
	    -p 30000-32767:30000-32767@server[0] \
	    -v /etc/machine-id:/etc/machine-id:ro \
	    -v /var/log/journal:/var/log/journal:ro \
	    -v /var/run/docker.sock:/var/run/docker.sock \
		--k3s-server-arg '--no-deploy=traefik' \
	    --agents 2
	    
	    
cluster-down:
	k3d cluster delete tekton-cicd


install-tekton:
	kubectl apply -f https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml

tekton-dashboard:
	kubectl apply -f https://storage.googleapis.com/tekton-releases/dashboard/latest/tekton-dashboard-release.yaml
	kubectl patch svc tekton-dashboard -n tekton-pipelines --type='json' -p '[{"op":"replace","path":"/spec/type","value":"NodePort"}]'


git-clone:
	kubectl apply -f https://raw.githubusercontent.com/tektoncd/catalog/master/task/git-clone/0.2/git-clone.yaml

watch-pods:
	kubectl get pods --namespace tekton-pipelines --watch

tkn-cli:
	sudo apt update
	sudo apt install -y gnupg
	sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 3EFE0E0A2F2F60AA
	echo "deb http://ppa.launchpad.net/tektoncd/cli/ubuntu eoan main"|sudo tee /etc/apt/sources.list.d/tektoncd-ubuntu-cli.list
	sudo apt update && sudo apt install -y tektoncd-cli

persistent-volumes:
	kubectl create configmap config-artifact-pvc \
                         --from-literal=size=10Gi \
                         --from-literal=storageClassName=manual \
                         -o yaml -n tekton-pipelines \
                         --dry-run=client | kubectl replace -f - && \
        kubectl create configmap config-defaults \
                         --from-literal=default-service-account=tutorial-service \
                         -o yaml -n tekton-pipelines \
                         --dry-run=client  | kubectl replace -f -

apply:
	kubectl apply -f pipelines/sa-role-binding.yml
	kubectl apply -f pipelines/task-hello.yml
	kubectl create -f pipelines/taskRun-hello.yml
	kubectl apply -f pipelines/pipeline.yml
	kubectl apply -f pipelines/pipeline-run.yml
	kubectl apply -f pipelines/secrets.yml

start-task:
	 tkn task start hello -n tekton-pipelines

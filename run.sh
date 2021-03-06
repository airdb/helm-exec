#!/usr/bin/env bash
# set -euo pipefail
# set -x
iexecURL="https://github.com/airdb/kubectl-iexec/releases/latest/download/kubectl-iexec"

# -----------------------------------------------------------------------------
# usage

function usage() {
cat << EOF
Usage:
  helm kube [OPTIONS]

OPTIONS:
  list, List all kubernetes pods.
  status, kubectl describe ingress or container.
  ingress, List ingress.
  logs, Print the logs for a container in a pod.
  exec, enter Wildcard characters for searching containers.
  wildcard, Wildcard characters for searching containers.

More info: https://github.com/airdb/helm-kube.
EOF

  exit
}

# -----------------------------------------------------------------------------
# rule
#
# Print a horizontal line the width of the terminal.

function rule() {
  local cols="${COLUMNS:-$(tput cols)}"
  local char=$'\u2500'
  printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
}

# -----------------------------------------------------------------------------
# header
#
# Print step header text in a consistent way

header() {
  if [[ "${QUIET}" ]]; then
    return
  fi

  # If called with no args, assume the key is the caller's function name
  local msg="$*"
  printf "\n%s[%s]\n\n" "$(rule)" "${msg}"
}

# -----------------------------------------------------------------------------
# print_helm_envars
#
# Print helm related environment variables.

print_helm_envars() {
  header "Helm environment"
  env | sort | grep -e HELM_ -e TILLER_ -e KUBE_
}

# -----------------------------------------------------------------------------
# print_kubectl_config
#
# Print pertinent values from kubectl config.

print_kubectl_config() {
  header "kubectl config"

  local current_context server

  current_context=$(kubectl config current-context)
  server=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')

cat << EOF
current-context: ${current_context}
server:          ${server}

EOF
}

function install_kubectl_plugin() {
    # Linux: https://github.com/airdb/kubectl-iexec/releases/latest/download/kubectl-iexec
    # MacOS: https://github.com/airdb/kubectl-iexec/releases/latest/download/kubectl-iexec-darwin
	case $(uname) in
	Darwin)
                sudo wget ${iexecURL}-darwin -O /usr/local/bin/kubectl-iexec
                ;;
        Linux)
                sudo wget ${iexecURL} -O /usr/local/bin/kubectl-iexec
                ;;
        *)
                echo "Not Support $(uname) Yet!"
                ;;
      esac

      sudo chmod +x /usr/local/bin/kubectl-iexec
}

# -----------------------------------------------------------------------------
# parse command line options

if [[ $# -eq 0 ]]; then
  usage
  exit
fi

case "$1" in
	"--help" | "-h")
		usage
    		exit
    		;;

	"list" | "ls")
		kubectl get pods -o wide
		;;

	"logs" | "log")
		if [[ $# -eq 1 ]]; then
			kubectl get pods -o name |  awk -F "/" '{print $2}'
			exit
		fi

		count=$(kubectl get pods -o name|awk -F "/" '{print $2}' | grep "$2" | wc -l )
		if [[ $count -eq 1 ]]; then
			kubectl logs $(kubectl get pods -o name |  awk -F "/" '{print $2}' | grep $2)
		else
			kubectl get pods -o name |  awk -F "/" '{print $2}' | grep $2
		fi
		;;

	"status" | "st" | "s" | "describe" | "des" | "desc")
                if [[ $# -eq 1 ]]; then
                        kubectl get pods -o name |  awk -F "/" '{print $2}'
                        exit
                fi

		case $2 in 
		"-h" | "--help")
			echo "helm kube status"
			echo 
			echo "Usage:"
			printf "\thelm kube status ingress\n"
			printf "\thelm kube status <container>\n"
			;;
		"ing" | "ingress")
			kubectl describe ingress;
			;;
		*)
                	count=$(kubectl get pods -o name|awk -F "/" '{print $2}' | grep "$2" | wc -l )
                	if [[ $count -eq 1 ]]; then
                	        kubectl describe pod $(kubectl get pods -o name |  awk -F "/" '{print $2}' | grep $2)
                	fi
			;;
		esac
		;;

       "ingress" | "ing" | "in")
                if [[ $# -eq 1 ]]; then
                        kubectl get ingress
                        exit
                fi
                kubectl get ingress -o yaml

                ;;

       "update" | "upgrade") 
		if [[ $# -ne 3 ]]; then
	       		echo  Usage:  helm kube update [RELEASE] [CHART]
                        exit
                fi

		# example: helm upgrade --recreate-pods --reuse-values oauth airdb/oauth
		helm upgrade --recreate-pods --reuse-values $2 $3
                ;;

	"exec" )
                if command -v kubectl-iexec >/dev/null 2>&1; then
                        kubectl-iexec $2
        	else
			install_kubectl_plugin
		fi
		;;

	*)
        	if command -v kubectl-iexec >/dev/null 2>&1; then
        	        kubectl-iexec $1
        	else
			install_kubectl_plugin
		fi
		;;
esac

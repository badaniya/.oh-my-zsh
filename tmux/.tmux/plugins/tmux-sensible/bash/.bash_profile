export EDITOR=vim
export CSCOPE_EDITOR=vim
#export VIM=$HOME/.vim
#export VIMRUNTIME=$HOME/.vim
#export LC_ALL="en_US.UTF-8"
#export LC_ALL="C"
export VAGRANT_HOME=$HOME/.vagrant.d

## Golang Environment Settings ##
export GOBASEPATH=$HOME/.go
export GO111MODULE=on
export GOMODCACHE=$GOBASEPATH/pkg/mod
export GOROOT="/usr/local/go"
export GOPATH=$GOBASEPATH

if [[ ! "$PATH" =~ "$GOROOT/bin" ]]; then
    export PATH=$GOROOT/bin:$PATH
fi

if [[ ! "$PATH" =~ "$GOBASEPATH/bin" ]]; then
    export PATH=$GOBASEPATH/bin:$PATH
fi

export PATH=$PATH:$HOME/.local/bin:/opt/nvim-linux64/bin

## Docker Environment Settings ##
export DOCKER_BUILDKIT=1

## EFA Environment Settings ##
export API_KEY=extremenetworks_user_auth_key

#Due to EFA deployment scripts, /etc/profile env keeps getting set
unset DCA_SERVER_BASEPATH

#EFA Development
export EFA_TOKEN=dummy
export NORBAC=1

#EFA Deployment to allow raslogs
export SYSLOG_SERVER_ENDPOINT=`ifconfig tun0 2>/dev/null | sed -rn 's/.*inet (\S+).*/\1/p'`
export EFA_DEPLOYMENT_SECURE=no

#EFA Deployment to allow monitor to connect to message bus
export MessageBusUser=rabbitmq
export MessageBusPassword=rabbitmq
export MessageBusHost=127.0.0.1
export MessageBusPort=5672

#EFA Source common.sh
export EFA_LOG_TO_STDOUT=1
export EFA_REPL=1

#Jira-CLI API token
export JIRA_API_TOKEN=QkFEQU5JWUE6bW8tYXBpLWtnVjFMNTRJV1ltSVdzWDVZOEhjTDBnbg==
export JIRA_AUTH_TYPE=bearer

#NVO Development
#export XIQ_HOST_IP=134.141.64.118
#export XIQ_HOST_IP=10.234.40.173
#export XIQ_HOST_IP=10.59.216.1
export XIQ_HOST_IP=127.0.0.1

export NVO_MessageBusHost=127.0.0.1
export NVO_MessageBusPort=9093
export XIQ_MessageBusHost=${XIQ_HOST_IP}
export XIQ_MessageBusPort=9092
export XIQ_HiveMiddlewareHost=${XIQ_HOST_IP}
export XIQ_HiveMiddlewarePort=9095
export XIQ_GrpcCommonServiceHost=${XIQ_HOST_IP}
export XIQ_GrpcCommonServicePort=50091
export XIQ_GrpcHmwebHost=${XIQ_HOST_IP}
export XIQ_GrpcHmwebPort=50055

export PeriodicDiscoveryInMinutes=45
export XiqGrpcGetDevicesPerPageLimit=100
export DBAUTOMIGRATE=true

#NVO Helm Deployment
export KUBECONFIG=~/.kube/config

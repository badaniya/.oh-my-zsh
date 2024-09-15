# GLOBALS
LINUX_HOST1="10.24.12.84"
LINUX_HOST2="10.24.12.86"
CC_HOST="badaniya-vm"
BUILD_HOST="$CC_HOST"
FWDL_HOST="$LINUX_HOST2"
SS_PATH="$HOME/ss_team"
DOMAIN_NAME="extremenetworks.com"

CLEARTOOL=/usr/atria/bin/cleartool

NUM_CPU_CORES=`cat /proc/cpuinfo | grep processor | wc -l`

SWITCH_TERMINAL_GEOMETRY="89x25"
CHASSIS_TERMINAL_GEOMETRY="180x25"
FULL_TERMINAL_GEOMETRY="180x56"

host_ip()
{
    hostname -I | cut -d ' ' -f 1
}

get_pathenv()
{
    local SEARCH_PATH="$1"
    local PATH_ENV="$2"

    if [[ -n "$PATH_ENV" ]]; then
        for pathenv in `echo ${PATH_ENV//:/$'\n'}`; do
            if [[ $SEARCH_PATH =~ $pathenv ]]; then
                echo $pathenv
            fi
        done
    fi
}

set_ctag_cscope_path()
{
    if [ -e "$CLEARTOOL" ]; then
        CURRENT_VIEW=`$CLEARTOOL pwv | grep 'Set view:' | awk -F ': ' '{print $2}'`
    
        export CLEARCASE_VIEW="$CURRENT_VIEW"
        export CTAG_CSCOPE_DEFAULT_VIEW_PATH="/vobs/projects/springboard/build"
    
        if [[ "$CURRENT_VIEW" =~ "NONE" ]]; then
            export CTAG_CSCOPE_PATH=""
        elif [[ "$CURRENT_VIEW" =~ "$USER" ]]; then
            # User owns the view
            export CTAG_CSCOPE_PATH="$CTAG_CSCOPE_DEFAULT_VIEW_PATH"
        else
            # User does not own the view
            export CTAG_CSCOPE_PATH="/tmp/$USER/$CLEARCASE_VIEW"
    
            if [ ! -d "$CTAG_CSCOPE_PATH" ]; then
                mkdir -p "$CTAG_CSCOPE_PATH"
            fi
        fi
    else
        CURRENT_DIR=`pwd`
    
        export CLEARCASE_VIEW="$USER"
        export CTAG_CSCOPE_DEFAULT_VIEW_PATH="$HOME/.go"
    
        CTAG_CSCOPE_PATH=`get_pathenv $CURRENT_DIR $GOPATH`
        export CTAG_CSCOPE_PATH
    fi
}

function urlencode()
{
    # urlencode <string>

    local LANG=C
    local length="${#1}"
    for (( i = 0; i < length; i++ )); do
        local c="${1:i:1}"
        case $c in
            [a-zA-Z0-9.~_-]) printf "$c" ;;
            *) printf '%%%02X' "'$c" ;; 
        esac
    done
}

function find_gosrc_path()
{
    local INPUT_PATH="$1"
    local INPUT_PATH_ARRAY=(${INPUT_PATH//\// })
    local GOSRC=""

    if [[ " ${INPUT_PATH_ARRAY[@]} " =~ " src " ]]; then
        GOSRC=${INPUT_PATH%%/src*}
    fi

    echo $GOSRC
}

function set_gosrc_path()
{
    local GOSRC_PATH=`find_gosrc_path $PWD`
    local GOENV_PATH="$GOBASEPATH"

    if [[ "$GOSRC_PATH" =~ ^.*/GoDCApp/.*$ ]]; then
        GOSRC_PATH=`set_godcapp_gosrc_path $GOSRC_PATH`
    fi

    if [[ -n "$GOSRC_PATH" ]]; then
        if [[ -z "$GOENV_PATH" ]]; then
            GOENV_PATH="$GOSRC_PATH"
        fi

        export GOPATH="$GOENV_PATH"

        local GOBIN_PATH="${GOPATH//://bin:}"/bin

        if [[ ! "$PATH" =~ "$GOBIN_PATH" ]]; then
            export PATH="$GOBIN_PATH:$PATH"
        fi	

        set_ctag_cscope_path
    fi
}

function set_godcapp_gosrc_path()
{
    local GODCAPP_NAME="GoDCApp"
    local GOSWITCH="GoSwitch"
    local GOCOMMON_NAME="GoCommon"
    local GOINVENTORY_NAME="GoInventory"
    local GOFABRIC_NAME="GoFabric"
    local GOTENANT_NAME="GoTenant"
    local GODCAPPS=( "GoCommon" "GoFabric" "GoInventory" "GoTenant" "GoRASlog" "GoVCenter" "GoHyperV" "GoOpenStack" )
    local GOSRC_PATH="$1"
    local GOBASE_PATH=${GOSRC_PATH%/$GODCAPP_NAME/*}

    #GOSRC_PATH="$GOBASE_PATH/$GOSWITCH:$GOBASE_PATH/$GODCAPP_NAME/$GOCOMMON_NAME:$GOBASE_PATH/$GODCAPP_NAME/$GOINVENTORY_NAME:$GOBASE_PATH/$GODCAPP_NAME/$GOFABRIC_NAME:$GOBASE_PATH/$GODCAPP_NAME/$GOTENANT_NAME"
    GOSRC_PATH="$GOBASE_PATH/$GOSWITCH"
    
    for GOAPP in "${GODCAPPS[@]}"; do
        GOSRC_PATH="$GOSRC_PATH:$GOBASE_PATH/$GODCAPP_NAME/$GOAPP"
    done

    echo $GOSRC_PATH
}

function match_in_gosrc_path()
{
    local USAGE="match_in_gosrc_path <GOPATH environment variable> <Match string for single go path>"

    if [[ $# -lt 2 || $# -ge 3 || "$1" =~ (^-h$|^--help$) ]]; then
        echo "$USAGE"
        return 1
    fi

    local GOSRC_PATH="$1"
    local GOPATH_MATCH="$2"
    local GOSRC_PATH_ARRAY=("${GOSRC_PATH//:/ }")

    for gopath in $GOSRC_PATH_ARRAY; do
        if [[ "$gopath" =~ $GOPATH_MATCH ]]; then
            echo "$gopath"
            return
        fi
    done
}

# Set an appropriate ctags/cscope path
#set_ctag_cscope_path 

# Set appropriate GOPATH dynamically
#export PROMPT_COMMAND=set_gosrc_path

# FUNCTIONS
function clone_goswitch()
{
    local GOSWITCH_BRANCH="$1"
    local GOSWITCH_SOURCE_BRANCH="$2"
    local GOSWITCH_DEFAULT_SOURCE_BRANCH="master"
    local GOAUTOSUIT_URL="github.extremenetworks.com/autosuit"

    if [[ -n "$GOSWITCH_BRANCH" ]]; then
        mkdir "$GOSWITCH_BRANCH" && cd "$GOSWITCH_BRANCH"
    fi

    if [[ -z "$GOSWITCH_SOURCE_BRANCH" ]]; then
        GOSWITCH_SOURCE_BRANCH=$GOSWITCH_DEFAULT_SOURCE_BRANCH
    fi

    read -p "Git Username: " username
    read -s -p "Git Password: " password

	local USER=`urlencode $username`
	local PASS=`urlencode $password`

    echo -e "\nCloning https://$USER@$GOAUTOSUIT_URL/GoSwitch (Branch: $GOSWITCH_SOURCE_BRANCH)"
    if [[ "$GOSWITCH_SOURCE_BRANCH" == "$GOSWITCH_DEFAULT_SOURCE_BRANCH" ]]; then
        git clone "https://"$USER":"$PASS"@"$GOAUTOSUIT_URL/GoSwitch
    else
        git clone -b $GOSWITCH_SOURCE_BRANCH --single-branch "https://"$USER":"$PASS"@"$GOAUTOSUIT_URL/GoSwitch
    fi

    if [[ $? -eq 0 ]]; then
	    cd GoSwitch/src

    	if [[ -n "$GOSWITCH_BRANCH" ]]; then
            echo "[Find remote git branch \"$GOSWITCH_BRANCH\"...]"
            git branch -r | grep "$GOSWITCH_BRANCH"

            if [[ $? -ne 0 ]]; then
                # Create the git branch
                echo "[Create new git branch \"$GOSWITCH_BRANCH\"...]"
    	        git checkout -b "$GOSWITCH_BRANCH"
            else
                # Set existing git branch
                echo "[Set existing git branch \"$GOSWITCH_BRANCH\"...]"
                git checkout "$GOSWITCH_BRANCH"
            fi

            echo "[Set branch tracking to remote master...]"
            git branch --set-upstream-to=origin/$GOSWITCH_SOURCE_BRANCH
    	fi
	
	    set_gosrc_path `pwd`
	    echo "GOPATH = $GOPATH"

	    echo "[Install golint...]"
        	go get -u golang.org/x/lint/golint

	    echo "[Setup git pre-commit link hooks...]"
        	../scripts/link_hooks.sh

	    echo "[Create go ctags/cscope...]"
            cd "$GOPATH"
        	tagscope go_src

	    echo "[Git Status...]"
            git status
    else
        cd .. && rm -rf "$GOSWITCH_BRANCH"
    fi
}

function clone_godcapp()
{
    local WORKING_DIR=`pwd`
    local GODCAPP_BRANCH="$1"
    local GODCAPP_SOURCE_BRANCH="$2"
    local GODCAPP_DEFAULT_SOURCE_BRANCH="master"
    local GOAUTOSUIT_URL="github.extremenetworks.com/autosuit"
    local GOSWITCH_NAME="GoSwitch"
    local GODCAPP_NAME="GoDCApp"
    local GODCAPPS=( "GoCommon" "GoFabric" "GoInventory" "GoTenant" "GoRASlog" "GoVCenter" "GoHyperV" "GoOpenStack" )

    if [[ -n "$GODCAPP_BRANCH" ]]; then
        mkdir "$GODCAPP_BRANCH" && cd "$GODCAPP_BRANCH"
    fi

    if [[ -z "$GODCAPP_SOURCE_BRANCH" ]]; then
        GODCAPP_SOURCE_BRANCH=$GODCAPP_DEFAULT_SOURCE_BRANCH
    fi

    read -p "Git Username: " username
    read -s -p "Git Password: " password

    local USER=`urlencode $username`
    local PASS=`urlencode $password`

    echo -e "\nCloning https://$USER@$GOAUTOSUIT_URL/$GODCAPP_NAME (Branch: $GODCAPP_SOURCE_BRANCH)"
    if [[ "$GODCAPP_SOURCE_BRANCH" == "$GODCAPP_DEFAULT_SOURCE_BRANCH" ]]; then
        git clone "https://"$USER":"$PASS"@"$GOAUTOSUIT_URL/$GODCAPP_NAME
    else
        git clone -b $GODCAPP_SOURCE_BRANCH --single-branch "https://"$USER":"$PASS"@"$GOAUTOSUIT_URL/$GODCAPP_NAME
    fi

    if [[ $? -eq 0 ]]; then
        cd $WORKING_DIR/$GODCAPP_BRANCH/$GODCAPP_NAME/${GODCAPPS[0]}/src

        if [[ -n "$GODCAPP_BRANCH" ]]; then
            echo "[Find remote git branch \"$GODCAPP_BRANCH\"...]"
            git branch -r | grep "$GODCAPP_BRANCH"

            if [[ $? -ne 0 ]]; then
                # Create the git branch
                echo "[Create new git branch \"$GODCAPP_BRANCH\"...]"
                git checkout -b "$GODCAPP_BRANCH"
            else
                # Set existing git branch
                echo "[Set existing git branch \"$GODCAPP_BRANCH\"...]"
                git checkout "$GODCAPP_BRANCH"
            fi

            echo "[Set branch tracking to remote master...]"
            git branch --set-upstream-to=origin/$GODCAPP_SOURCE_BRANCH
        fi

        for goapp in "${GODCAPPS[@]}"; do
            cd $WORKING_DIR/$GODCAPP_BRANCH/$GODCAPP_NAME/$goapp/src
            
            set_gosrc_path `pwd`

            echo "[Create go ctags/cscope...]"
            tagscope go_src
        done
    else
        cd $WORKING_DIR && rm -rf "$GODCAPP_BRANCH"
    fi

    cd $WORKING_DIR/$GODCAPP_BRANCH

    echo -e "\nCloning https://$USER@$GOAUTOSUIT_URL/$GOSWITCH_NAME (Branch: $GODCAPP_SOURCE_BRANCH)"
    if [[ "$GODCAPP_SOURCE_BRANCH" == "$GODCAPP_DEFAULT_SOURCE_BRANCH" ]]; then
        git clone "https://"$USER":"$PASS"@"$GOAUTOSUIT_URL/$GOSWITCH_NAME
    else
        git clone -b $GODCAPP_SOURCE_BRANCH --single-branch "https://"$USER":"$PASS"@"$GOAUTOSUIT_URL/$GOSWITCH_NAME
    fi

    if [[ $? -eq 0 ]]; then
	    cd $WORKING_DIR/$GODCAPP_BRANCH/$GOSWITCH_NAME/src

    	if [[ -n "$GODCAPP_BRANCH" ]]; then
            echo "[Find remote git branch \"$GODCAPP_BRANCH\"...]"
            git branch -r | grep "$GODCAPP_BRANCH"

            if [[ $? -ne 0 ]]; then
                # Create the git branch
                echo "[Create new git branch \"$GODCAPP_BRANCH\"...]"
    	        git checkout -b "$GODCAPP_BRANCH"
            else
                # Set existing git branch
                echo "[Set existing git branch \"$GODCAPP_BRANCH\"...]"
                git checkout "$GODCAPP_BRANCH"
            fi

            echo "[Set branch tracking to remote master...]"
            git branch --set-upstream-to=origin/$GODCAPP_SOURCE_BRANCH
    	fi
	
	    set_gosrc_path `pwd`
	    echo "GOPATH = $GOPATH"

	    echo "[Install golint...]"
        	go get -u golang.org/x/lint/golint

	    echo "[Setup git pre-commit link hooks...]"
        	../scripts/link_hooks.sh

	    echo "[Create go ctags/cscope...]"
            cd "$GOPATH"
        	tagscope go_src

	    echo "[Git Status...]"
            git status
    else
        cd $WORKING_DIR && rm -rf "$GODCAPP_BRANCH"
    fi

    if [[ -d "$WORKING_DIR/$GODCAPP_BRANCH/$GODCAPP_NAME/scripts" ]]; then
        cd $WORKING_DIR/$GODCAPP_BRANCH/$GODCAPP_NAME/scripts
    fi
}

inventory_swagger_gen()
{
    local USAGE="inventory_swagger_gen [all | client | server | html]"

    if [[ $# -lt 1 || $# -ge 2 || "$1" =~ (^-h$|^--help$) ]]; then
        echo "$USAGE"
        return 1
    fi

    local WORKING_DIR=`pwd`
    local GOAPP_INVENTORY="GoInventory"
    local GOPATH_INVENTORY=`match_in_gosrc_path $GOPATH $GOAPP_INVENTORY`
    local TYPE="$1"

    if [[ -z "$TYPE" ]]; then
        TYPE="all"
    fi

    if [[ -n GOPATH_INVENTORY ]]; then
        cd $GOPATH_INVENTORY

        if [[ "$TYPE" == "all" || "$TYPE" == "client" || "$TYPE" == "server" || "$TYPE" == "html" ]]; then
            swagger-codegen generate -i ./src/inventory/rest/openapi.yaml -l html -o ./src/inventory/rest/generated/html
        fi

        if [[ "$TYPE" == "all" || "$TYPE" == "client" ]]; then
            swagger-codegen generate -i ./src/inventory/rest/openapi.yaml -l go -o ../GoCommon/src/inventoryclient/swagger
        fi

        if [[ "$TYPE" == "all" || "$TYPE" == "server" ]]; then
            swagger-codegen generate -i ./src/inventory/rest/openapi.yaml -l go-server -o ./src/inventory/rest/generated/server
        fi

        cd $WORKING_DIR
    else
        echo "GOPATH ENV: \"$GOPATH\" is not configured for $GOAPP_INVENTORY service."
    fi
}

set_efa_env()
{
    local INPUT_PORT="$1"

    export DCA_SERVER_BASEPATH=`host_ip`:$INPUT_PORT
}

set_dbkube_env()
{
    local DBSERVICE_NAME="db-service"
    local MESSAGE_BUS_NAME="rabbitmq"
    
    export DBHOST=`k3sctl -n efa get services | grep $DBSERVICE_NAME | awk '{print $3}'`
    export MessageBusHost=`k3sctl -n efa get services | grep $MESSAGE_BUS_NAME | awk '{print $3}'`
}

godcapp_docker_pull()
{
    local USAGE="godcapp_docker_pull [registry name | nil]"

    local WORKING_DIR=`pwd`
    local REGISTRY_INPUT="$1"
    local DOCKER_REGISTRY="godcfregistry.extremenetworks.com/godcapp/"
    local VERSION="$USER-latest"
    local GODCAPP_NAME="GoDCApp"
    local GODCAPP_PATH=`match_in_gosrc_path $GOPATH $GODCAPP_NAME`
    GODCAPP_PATH=`dirname "$GODCAPP_PATH"`

    local GODCAPP_SCRIPTS_PATH="$GODCAPP_PATH/scripts"
    local GODCAPP_API_SCRIPTS_PATH="$GODCAPP_SCRIPTS_PATH/single-node-deployment/api-scripts"
    local GODCAPP_ELK_PATH="$GODCAPP_SCRIPTS_PATH/single-node-deployment/elk"
    local ELK_VERSION="6.4.2"

    local POSTGRES_CONTAINER_VERSION="9.6"
    local KONGA_CONTAINER_VERSION="next"
    local KONG_CONTAINER_VERSION="1.0.0-alpine"
    local RABBITMQ_CONTAINER_VERISON="3-management"
    local METRICBEAT_CONTAINER_VERSION="6.6.0"

    if [[ "$REGISTRY_INPUT" == "nil" ]]; then
        DOCKER_REGISTRY=""
    elif [[ -z "$REGISTRY_INPUT" ]]; then
        DOCKER_REGISTRY="$REGISTRY_INPUT"
    fi

    if [[ -z "$GODCAPP_PATH" ]]; then
        echo "Cannot find the GoDCApp path from GOPATH: $GOPATH"
        return
    fi

    cd "$GODCAPP_SCRIPTS_PATH"
    
    docker pull "$DOCKER_REGISTRY"postgres:"$POSTGRES_CONTAINER_VERSION"
    docker pull "$DOCKER_REGISTRY"konga:"$KONGA_CONTAINER_VERSION" && docker tag "$DOCKER_REGISTRY"konga:"$KONGA_CONTAINER_VERSION" konga:latest
    docker pull "$DOCKER_REGISTRY"kong:"$KONG_CONTAINER_VERSION" && docker tag "$DOCKER_REGISTRY"kong:"$KONG_CONTAINER_VERSION" kong:latest && docker rmi "$DOCKER_REGISTRY"kong:1.0.0-alpine
    docker pull "$DOCKER_REGISTRY"rabbitmq:"$RABBITMQ_CONTAINER_VERISON" && docker tag "$DOCKER_REGISTRY"rabbitmq:"$RABBITMQ_CONTAINER_VERISON" rabbitmq:latest
    docker pull "$DOCKER_REGISTRY"metricbeat:"$METRICBEAT_CONTAINER_VERSION" && docker tag "$DOCKER_REGISTRY"metricbeat:"$METRICBEAT_CONTAINER_VERSION" elk_metricbeat:latest

    cd "$GODCAPP_API_SCRIPTS_PATH" && docker build -t configureapis:latest .
    cd "$GODCAPP_ELK_PATH/logstash" && docker build --build-arg ELK_VERSION="$ELK_VERSION" -t elk_logstash .
    cd "$GODCAPP_ELK_PATH/filebeat" && docker build -t elk_filebeat .
    cd "$GODCAPP_ELK_PATH/elasticsearch" && docker build --build-arg ELK_VERSION="$ELK_VERSION" -t elk_elasticsearch .
    cd "$GODCAPP_ELK_PATH/kibana" && docker build --build-arg ELK_VERSION="$ELK_VERSION" -t elk_kibana .
    
    cd "$GODCAPP_PATH"

    echo "building GoInventory image"
    bash GoInventory/scripts/build_docker.sh
    echo "building GoTenant image"
    bash GoTenant/scripts/build_docker.sh
    echo "building GoFabric image"
    bash GoFabric/scripts/build_docker.sh
    echo "building GoSwitch image"
    cp -r $GODCAPP_PATH/../GoSwitch .
    bash GoSwitch/scripts/build_docker.sh
    echo "building postgres image"
    docker build -t postgres-db -f scripts/single-node-deployment/database-scripts/Dockerfile ./..

    cd "$WORKING_DIR"
}

godcapp_docker()
{
    local USAGE="godcapp_docker <host ip address> [all | inventory | fabric | tenant] [container version]"

    if [[ $# -lt 1 || $# -ge 4 || "$1" =~ (^-h$|^--help$) ]]; then
        echo "$USAGE"
        return 1
    fi

    local HOST_IP="$1"
    local GODCAPP_SERVICE="$2"
    local GODCAPP_VERSION="$3"
    #local GODCAPP_REGISTRY="godcfregistry.extremenetworks.com/godcapp/"
    local GODCAPP_REGISTRY=""
    local GODCAPP_NAME="GoDCApp"
    local GODCAPP_PATH=`match_in_gosrc_path $GOPATH $GODCAPP_NAME`
    GODCAPP_PATH=`dirname $GODCAPP_PATH`

    local RABBITMQ_VERSION="3-management"
    local POSTGRES_VERSION="9.6"

    local RABBITMQ_CONTAINER_NAME="rabbitmq-$GODCAPP_VERSION"
    local POSTGRES_CONTAINER_NAME="postgres-database-$GODCAPP_VERSION"
    local GOINVENTORY_CONTAINER_NAME="goinventory-$GODCAPP_VERSION"
    local GOFABRIC_CONTAINER_NAME="gofabric-$GODCAPP_VERSION"
    local GOTENANT_CONTAINER_NAME="gotenant-$GODCAPP_VERSION"

    if [[ -z "$GODCAPP_SERVICE" ]]; then
        GODCAPP_SERVICE="all"
    fi

    if [[ -z "$GODCAPP_VERSION" ]]; then
        GODCAPP_VERSION="v2.0.0-39"
    fi

    if [[ $GOPATH =~ $GODCAPP_NAME ]]; then 
        echo docker run -d --hostname dcapp-message-bus -p 5672:5672 -p 15672:15672 -e RABBITMQ_ERLANG_COOKIE='SWQOKODSQALRPCLNMEQG' -e RABBITMQ_DEFAULT_USER=rabbitmq -e RABBITMQ_DEFAULT_PASS=rabbitmq --name "$RABBITMQ_CONTAINER_NAME" "$GODCAPP_REGISTRY"rabbitmq:"$RABBITMQ_VERSION"
        docker run -d --hostname dcapp-message-bus -p 5672:5672 -p 15672:15672 -e RABBITMQ_ERLANG_COOKIE='SWQOKODSQALRPCLNMEQG' -e RABBITMQ_DEFAULT_USER=rabbitmq -e RABBITMQ_DEFAULT_PASS=rabbitmq --name "$RABBITMQ_CONTAINER_NAME" "$GODCAPP_REGISTRY"rabbitmq:"$RABBITMQ_VERSION"

        echo docker run -d -p 5432:5432 -v $GODCAPP_PATH/GoInventory/etc:/inventory/etc -v $GODCAPP_PATH/GoInventory/scripts:/inventory/scripts --name "$POSTGRES_CONTAINER_NAME" -e POSTGRES_PASSWORD=password "$GODCAPP_REGISTRY"postgres:"$POSTGRES_VERSION"
        docker run -d -p 5432:5432 -v $GODCAPP_PATH/GoInventory/etc:/inventory/etc -v $GODCAPP_PATH/GoInventory/scripts:/inventory/scripts --name "$POSTGRES_CONTAINER_NAME" -e POSTGRES_PASSWORD=password "$GODCAPP_REGISTRY"postgres:"$POSTGRES_VERSION"


        echo docker exec -it "$POSTGRES_CONTAINER_NAME" bash -c "chmod u+x /inventory/scripts/dcapp_psql_setup.sh&&apt-get update && apt-get -y install sudo&&cd /inventory/scripts&&./dcapp_psql_setup.sh"
        docker exec -it "$POSTGRES_CONTAINER_NAME" bash -c "chmod u+x /inventory/scripts/dcapp_psql_setup.sh&&apt-get update && apt-get -y install sudo&&cd /inventory/scripts&&./dcapp_psql_setup.sh"

        echo "Waiting for base services to come up..."
        sleep 1

        if [[ "$GODCAPP_SERVICE" == "all" || "$GODCAPP_SERVICE" == "inventory" || "$GODCAPP_SERVICE" == "fabric" || "$GODCAPP_SERVICE" == "tenant" ]]; then
            echo docker run -d -p 8082:8082 --env DBHOST="$HOST_IP" --env MessageBusHost="$HOST_IP" --name "$GOINVENTORY_CONTAINER_NAME" "$GODCAPP_REGISTRY"goinventory:"$GODCAPP_VERSION"
            docker run -d -p 8082:8082 --env DBHOST="$HOST_IP" --env MessageBusHost="$HOST_IP" --name "$GOINVENTORY_CONTAINER_NAME" "$GODCAPP_REGISTRY"goinventory:"$GODCAPP_VERSION"
        fi

        if [[ "$GODCAPP_SERVICE" == "all" || "$GODCAPP_SERVICE" == "fabric" ]]; then
            echo docker run -d -p 8081:8081 --env DBHOST="$HOST_IP" --env MessageBusHost="$HOST_IP" --name "$GOFABRIC_CONTAINER_NAME" "$GODCAPP_REGISTRY"gofabric:"$GODCAPP_VERSION"
            docker run -d -p 8081:8081 --env DBHOST="$HOST_IP" --env MessageBusHost="$HOST_IP" --name "$GOFABRIC_CONTAINER_NAME" "$GODCAPP_REGISTRY"gofabric:"$GODCAPP_VERSION"
        fi

        if [[ "$GODCAPP_SERVICE" == "all" || "GODCAPP_SERVICE" == "tenant" ]]; then
            echo docker run -d -p 8083:8083 --env DBHOST="$HOST_IP" --env MessageBusHost="$HOST_IP" --name "$GOTENANT_CONTAINER_NAME" "$GODCAPP_REGISTRY"gotenant:"$GODCAPP_VERSION"
            docker run -d -p 8083:8083 --env DBHOST="$HOST_IP" --env MessageBusHost="$HOST_IP" --name "$GOTENANT_CONTAINER_NAME" "$GODCAPP_REGISTRY"gotenant:"$GODCAPP_VERSION"
        fi
    else
        echo "GOPATH ENV: \"$GOPATH\" is not under $GODCAPP_NAME."
    fi
}

ps_docker()
{
    local USAGE="ps_docker [container|image|names]"
    INPUT="$1"

    if [[ "$INPUT" == "help" ]]; then
        echo "$USAGE"
        return 1
    fi
    
    if [[ -z "$INPUT" ]]; then
        INPUT="container"
    fi

    if [[ "$INPUT" == "container" ]]; then
        docker ps -a --format "{{.ID}}"
    elif [[ "$INPUT" == "image" ]]; then
        docker ps -a --format "table {{.ID}}\t{{.Image}}"
    elif [[ "$INPUT" == "names" ]]; then
        docker ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Image}}"
    fi 
}

rm_docker()
{
    local USAGE="rm_docker <all | container id>"
    INPUT="$1"

    if [[ $# -lt 1 || $# -ge 2 || "$1" =~ (^-h$|^--help$) ]]; then
        echo "$USAGE"
        return 1
    fi

    if [[ "$INPUT" == "all" ]]; then 
        for container_id in `ps_docker`; do
            docker rm -vf $container_id
        done
    else
        docker rm -vf "$INPUT"
    fi
}

exec_docker()
{
    local USAGE="exec_docker <container id or name> [shell]"

    if [[ $# -lt 1 || $# -ge 3 || "$1" =~ (^-h$|^--help$) ]]; then
        echo "$USAGE"
        return 1
    fi

    local CONTAINER="$1"   
    local INSHELL="$2"

    if [[ -z "$INSHELL" ]]; then
        INSHELL="ash"
    fi 

    echo docker exec -it "$CONTAINER" "$INSHELL"
    docker exec -it "$CONTAINER" "$INSHELL"
}

ps_kube()
{
    get_kube pods "$@"
}

get_kube()
{
    local USAGE="get_kube [options]"

    local OPTIONS="$1"

    if [[ "$OPTIONS" == "help" ]]; then
        echo "$USAGE"
        return 1
    fi

    #echo k3s kubectl -n efa get "$@"
    k3s kubectl -n efa get "$@"
}

rm_kube()
{
    delete_kube pods "$@"
}

delete_kube()
{
    local USAGE="delete_kube [options]"

    local OPTIONS="$1"

    if [[ "$OPTIONS" == "help" ]]; then
        echo "$USAGE"
        return 1
    fi

    #echo k3s kubectl -n efa delete "$@"
    k3s kubectl -n efa delete "$@"
}

create_kube()
{
    local USAGE="create_kube [options]"

    local OPTIONS="$1"

    if [[ "$OPTIONS" == "help" ]]; then
        echo "$USAGE"
        return 1
    fi

    k3s kubectl -n efa create "$@"
}

apply_kube()
{
    local USAGE="apply_kube [options]"

    local OPTIONS="$1"

    if [[ "$OPTIONS" == "help" ]]; then
        echo "$USAGE"
        return 1
    fi

    k3s kubectl -n efa apply "$@"
}

describe_kube()
{
    local USAGE="describe_kube [options]"

    local OPTIONS="$1"

    if [[ "$OPTIONS" == "help" ]]; then
        echo "$USAGE"
        return 1
    fi

    k3s kubectl -n efa describe "$@"
}

exec_kube()
{
    local USAGE="exec_kube <pod name> [shell]"

    if [[ $# -lt 1 || $# -ge 3 || "$1" =~ (^-h$|^--help$) ]]; then
        echo "$USAGE"
        return 1
    fi

    local CONTAINER="$1"
    local INSHELL="$2"

    if [[ -z "$INSHELL" ]]; then
        INSHELL="ash"
    fi

    echo k3s kubectl -n efa exec "$CONTAINER" -it -- "$INSHELL"
    k3s kubectl -n efa exec "$CONTAINER" -it -- "$INSHELL"
}

log_kube()
{
    local USAGE="log_kube <pod name> [options]"

    if [[ $# -lt 1 || "$1" =~ (^-h$|^--help$) ]]; then
        echo "$USAGE"
        return 1
    fi

    local CONTAINER="$1"
    shift
    local OPTIONS="$@"

    echo k3s kubectl -n efa logs "$CONTAINER" "$@"
    k3s kubectl -n efa logs "$CONTAINER" "$@"
}

# Function: efarestoredb
# Description: The function will start a postgres server instance and restore a Postgres Database dump file in ascii.
#              Psql will automatically be launched after the database restore and postgres server instance will be cleaned up after user
#              quits psql. 
function efarestoredb()
{
    local USAGE="Usage: efarestoredb <ascii pg_dump file containing schema and data> [postgres server portnumber (Default: 5432)]"

    if [[ $# -lt 1 || "$1" =~ (^-h$|^--help$) ]]; then
        echo $USAGE
        return 1
    fi

    local DB_USER_NAME=("asset" "fabric" "tenant" "vcenter" "hyperv" "openstack")
    local POSTGRES_PORT_OPTION
    local POSTGRES_SERVER_NAME="EFARestoredDB"
    local POSTGRES_LOGFILE_NAME="pgctl_log"
    local EFA_CREATE_ROLES=""

    for user in ${DB_USER_NAME[@]}; do
        EFA_CREATE_ROLES=$EFA_CREATE_ROLES"create role $user;"
    done

    local POSTGRES_DUMP_FILE=$1
    local POSTGRES_PORT=$2

    if [ -z "$POSTGRES_PORT" ]; then
        POSTGRES_PORT=5432
    fi

	POSTGRES_SERVER_NAME="$POSTGRES_SERVER_NAME.$POSTGRES_PORT"
    POSTGRES_PORT_OPTION="-p $POSTGRES_PORT"
    POSTGRES_LOGFILE_NAME="$POSTGRES_SERVER_NAME.pgctl_log"

	# Display script variables
    echo "POSTGRES_SERVER_NAME  = $POSTGRES_SERVER_NAME"
	echo "POSTGRES_PORT         = $POSTGRES_PORT"
    echo "POSTGRES_LOGFILE_NAME = $POSTGRES_LOGFILE_NAME"
    echo ""

    # Verify postgres server port is free
    local POSTGRES_PORT_IN_USE=`ps -ef | grep "$USER" | grep "$POSTGRES_PORT"`

    if [[ $POSTGRES_PORT_IN_USE =~ "$POSTGRES_SERVER_NAME" ]]; then
        echo "The requested postgres server port \"$POSTGRES_PORT\" is already in use.  Please try another port number."
        echo $USAGE
        return 1
    fi

	sudo PATH=$PATH PWD=$PWD -iu postgres rm -rf $POSTGRES_SERVER_NAME

    echo -e "\n[Initializing Postgres Database]"
    sudo PATH=$PATH PWD=$PWD -iu postgres initdb -D $POSTGRES_SERVER_NAME

    echo -e "\n[Starting Postgres Database Server]"
    sudo PATH=$PATH PWD=$PWD -iu postgres pg_ctl start -w -D $POSTGRES_SERVER_NAME -l $POSTGRES_LOGFILE_NAME -o "$POSTGRES_PORT_OPTION"

    echo -e "\n[Creating Database Instance]"
    sudo PATH=$PATH PWD=$PWD -iu postgres createdb --echo --template=template0 $POSTGRES_PORT_OPTION $POSTGRES_SERVER_NAME

    sudo PATH=$PATH PWD=$PWD -iu postgres psql $POSTGRES_PORT_OPTION -d $POSTGRES_SERVER_NAME -c "$EFA_CREATE_ROLES"

    echo -e "\n[Restoring Database Ascii Dump]"
    sudo PATH=$PATH PWD=$PWD -iu postgres pg_restore $POSTGRES_PORT_OPTION -d $POSTGRES_SERVER_NAME $PWD/$POSTGRES_DUMP_FILE

    echo -e "\n[Launching PostgresSQL Client]"
    sudo PATH=$PATH PWD=$PWD -iu postgres psql --pset=pager=off $POSTGRES_PORT_OPTION -d $POSTGRES_SERVER_NAME

    echo -e "\n[Stopping Postgres Database Server]"
    sudo PATH=$PATH PWD=$PWD -iu postgres pg_ctl -w -D $POSTGRES_SERVER_NAME -l $POSTGRES_LOGFILE_NAME stop
}

set_term_title()
{
   echo -en "\033]0;$1\a"
}

function is_xauth_locked()
{
    local IS_XAUTH_LOCKED="yes"

    IS_XAUTH_LOCKED=`xauth info | grep "File locked" | awk '{print $3}'`

    echo $IS_XAUTH_LOCKED
}

function wait_for_xauth_lock()
{
    local IS_XAUTH_LOCKED=`is_xauth_locked`

    while [ "$IS_XAUTH_LOCKED" != "no" ]; do
        IS_XAUTH_LOCKED=`is_xauth_locked`
        sleep 0.2
    done
}

function start_cscope()
{
    cscope -d -i "$CTAG_CSCOPE_PATH"/."$CLEARCASE_VIEW"_cscope.files -f "$CTAG_CSCOPE_PATH"/."$CLEARCASE_VIEW"_cscope.out
}

function tagscope()
{
    time tag_scope $@; date
}

function tag_scope()
{
    local SCOPE_PID=""

    if [[ "$1" == "go_src" ]]; then
        set_ctag_cscope_path
    fi

    scope $@ &
    SCOPE_PID=$!
    
    tag $@

    wait $SCOPE_RC
}

function tag()
{
    local TAG_TYPE="$1"
    local TAG_FILE="$2"
    local CURRENT_VIEW=`get_current_view`
    local INTEL_ARCH=`get_intel_os_type`
    local ALL_CTAG_GOPATH_LIST=( ${GOPATH//:/$'\n'} )
    local ALL_CTAG_PATH_LIST=(
        /vobs/projects/springboard/common_src 
        /vobs/projects/springboard/fabos/bccb
        /vobs/projects/springboard/fabos/src
        /vobs/projects/springboard/fabos/cfos
        /vobs/projects/springboard/fabos/bfos
        /vobs/projects/springboard/build/target26
        /vobs/projects/springboard/tps/ZebOS
    )
    local DCM_CTAG_PATH_LIST=(
        /vobs/projects/springboard/common_src/fos/common/include
        /vobs/projects/springboard/fabos/src/include
        /vobs/projects/springboard/fabos/bccb/include
        /vobs/projects/springboard/fabos/src/sys/dev/raslog/xml
        /vobs/projects/springboard/fabos/bccb/dsf/Wave/source
        /vobs/projects/springboard/fabos/src/vcs/dcm/source
        /vobs/projects/springboard/fabos/src/vcs/dcm/application
        /vobs/projects/springboard/fabos/src/vcs/dcm/TestApp
        /vobs/projects/springboard/fabos/src/vcs/dcm/build/Dcm/Linux/$INTEL_ARCH/debug/DynamicSource
        /vobs/projects/springboard/fabos/src/yang
        /vobs/projects/springboard/fabos/src/confd/cli
    )

    if [[ -z "$TAG_FILE" ]]; then
        TAG_FILE="$CTAG_CSCOPE_PATH"/."$CURRENT_VIEW"_tags
    fi

    local ORIGINAL_DIR=`pwd`
    local IS_FIRST_ITERATION=1

    if [[ "$TAG_TYPE" == "go_src" ]]; then
	for CTAG_PATH in "${ALL_CTAG_GOPATH_LIST[@]}"; do
            if [[ `pwd` =~ $CTAG_PATH ]]; then
                if [[ "$IS_FIRST_ITERATION" -eq "1" ]]; then
                    echo -e "[Creating ctag file for \"$CTAG_PATH\" ...]\n    - $TAG_FILE"
                    rm -f "$TAG_FILE"; cd "$CTAG_PATH"; ctags -Rf "$TAG_FILE" --tag-relative=yes --links=no *
                    IS_FIRST_ITERATION=0
                else
                    echo "[Appending ctag file for \"$CTAG_PATH\" ...]"
                    cd "$CTAG_PATH"; ctags -Raf "$TAG_FILE" --tag-relative=yes --links=no *
                fi
            fi
        done
    elif [[ "$TAG_TYPE" == "all_src" ]]; then
        for CTAG_PATH in "${ALL_CTAG_PATH_LIST[@]}"; do
            if [[ "$IS_FIRST_ITERATION" -eq "1" ]]; then
                echo -e "[Creating ctag file for \"$CTAG_PATH\" ...]\n    - $TAG_FILE"
                rm -f "$TAG_FILE"; cd "$CTAG_PATH"; ctags -Rf "$TAG_FILE" --tag-relative=yes --links=no *
                IS_FIRST_ITERATION=0
            else
                echo "[Appending ctag file for \"$CTAG_PATH\" ...]"
                cd "$CTAG_PATH"; ctags -Raf "$TAG_FILE" --tag-relative=yes --links=no *
            fi
        done
    else
        for CTAG_PATH in "${DCM_CTAG_PATH_LIST[@]}"; do
            if [[ "$IS_FIRST_ITERATION" -eq "1" ]]; then
                echo -e "[Creating ctag file for \"$CTAG_PATH\" ...]\n    - $TAG_FILE"
                cd "$CTAG_PATH"; rm -f "$TAG_FILE"; ctags -Rf "$TAG_FILE" --tag-relative=yes --links=no *
                IS_FIRST_ITERATION=0
            else
                echo "[Appending ctag file for \"$CTAG_PATH\" ...]"
                cd "$CTAG_PATH"; ctags -Raf "$TAG_FILE" --tag-relative=yes --links=no *
            fi
        done
    fi
    
    echo -e "[Ctags file created.]\n    - $TAG_FILE"

    cd $ORIGINAL_DIR
}

function scope()
{
    local SCOPE_TYPE="$1"
    local SCOPE_FILEPREFIX="$2"
    local CURRENT_VIEW=`get_current_view`
    local ORIGINAL_TEMP_DIR=`echo $TMPDIR`
    local INTEL_ARCH=`get_intel_os_type`
    local FILE_EXTENSIONS="-name '*.c' -o -name '*.cpp' -o -name '*.h' -o -name '*.sh.in' -o -name '*.xml' -o -name '*.yang' -o -name '*.cli' -o -name '*.go'"
    local ALL_CSCOPE_GOPATH_LIST=( ${GOPATH//:/$'\n'} )
    local ALL_CSCOPE_PATH_LIST=(
        /vobs/projects/springboard/common_src 
        /vobs/projects/springboard/fabos/bccb
        /vobs/projects/springboard/fabos/src
        /vobs/projects/springboard/fabos/cfos
        /vobs/projects/springboard/fabos/bfos
        /vobs/projects/springboard/build/target26
        /vobs/projects/springboard/tps/ZebOS
    )
    local DCM_CSCOPE_PATH_LIST=(
        /vobs/projects/springboard/common_src/fos/common/include
        /vobs/projects/springboard/fabos/src/include
        /vobs/projects/springboard/fabos/bccb/include
        /vobs/projects/springboard/fabos/src/sys/dev/raslog/xml
        /vobs/projects/springboard/fabos/bccb/dsf/Wave/source
        /vobs/projects/springboard/fabos/src/vcs/dcm/source
        /vobs/projects/springboard/fabos/src/vcs/dcm/application
        /vobs/projects/springboard/fabos/src/vcs/dcm/TestApp
        /vobs/projects/springboard/fabos/src/vcs/dcm/build/Dcm/Linux/$INTEL_ARCH/debug/DynamicSource
        /vobs/projects/springboard/fabos/src/yang
        /vobs/projects/springboard/fabos/src/confd/cli
    )

    if [[ -z "$SCOPE_FILEPREFIX" ]]; then
        SCOPE_FILEPREFIX="$CTAG_CSCOPE_PATH"/."$CURRENT_VIEW"_cscope
    fi 

    local SCOPE_FILE="$SCOPE_FILEPREFIX".file
    local SCOPE_OUTFILE="$SCOPE_FILEPREFIX".out
    local IS_FIRST_ITERATION=1

    if [[ "$SCOPE_TYPE" == "go_src" ]]; then
	for CSCOPE_PATH in "${ALL_CSCOPE_GOPATH_LIST[@]}"; do
            if [[ `pwd` =~ $CSCOPE_PATH ]]; then
                if [[ "$IS_FIRST_ITERATION" -eq "1" ]]; then
                    echo -e "[Creating cscope input file list for \"$CSCOPE_PATH\" ...]\n    - $SCOPE_FILE"
                    eval "find $CSCOPE_PATH \( $FILE_EXTENSIONS \) -type f -print > $SCOPE_FILE"
                    IS_FIRST_ITERATION=0
                else
                    echo "[Appending cscope input file list for \"$CSCOPE_PATH\" ...]"
                    eval "find $CSCOPE_PATH \( $FILE_EXTENSIONS \) -type f -print >> $SCOPE_FILE"
                fi
            fi
        done
    elif [[ "$SCOPE_TYPE" == "all_src" ]]; then
        for CSCOPE_PATH in "${ALL_CSCOPE_PATH_LIST[@]}"; do
            if [[ "$IS_FIRST_ITERATION" -eq "1" ]]; then
                echo -e "[Creating cscope input file list for \"$CSCOPE_PATH\" ...]\n    - $SCOPE_FILE"
                eval "find $CSCOPE_PATH \( $FILE_EXTENSIONS \) -type f -print > $SCOPE_FILE"
                IS_FIRST_ITERATION=0
            else
                echo "[Appending cscope input file list for \"$CSCOPE_PATH\" ...]"
                eval "find $CSCOPE_PATH \( $FILE_EXTENSIONS \) -type f -print >> $SCOPE_FILE"
            fi
        done
    else
        for CSCOPE_PATH in "${DCM_CSCOPE_PATH_LIST[@]}"; do
            if [[ "$IS_FIRST_ITERATION" -eq "1" ]]; then
                echo -e "[Creating cscope input file list for \"$CSCOPE_PATH\" ...]\n    - $SCOPE_FILE"
                eval "find $CSCOPE_PATH \( $FILE_EXTENSIONS \) -type f -print > $SCOPE_FILE"
                IS_FIRST_ITERATION=0
            else
                echo "[Appending cscope input file list for \"$CSCOPE_PATH\" ...]"
                eval "find $CSCOPE_PATH \( $FILE_EXTENSIONS \) -type f -print >> $SCOPE_FILE"
            fi
        done
    fi

    if [[ -f "$SCOPE_OUTFILE" ]]; then
        echo "[Cleaning up existing cscope cross-reference file ...]"
        rm -rf "$SCOPE_OUTFILE*"
    fi

    # Temporarily set the tmp directory to the cscope path when building the cscope cross reference file

    export TMPDIR="$CTAG_CSCOPE_PATH"

    echo "[Generating cscope cross-reference file ...]"
    cscope -bqi "$SCOPE_FILE" -f "$SCOPE_OUTFILE"
    echo -e "[Cscope file created.]\n    - $SCOPE_OUTFILE"

    export TMPDIR="$ORIGINAL_TEMP_DIR"
}

# Expect dependency
function expect_ssh()
{
    local USAGE="Usage: expect_ssh <hostname or ip> <username> <password> <ssh options> <ssh command>"

    if [[ $# -lt 5 || "$1" =~ (^-h$|^--help$) ]]; then
        echo $USAGE
        return 1
    fi

    local EXPECT_SSH_TIMEOUT="-1"
    local EXPECT_SSH_HOST="$1"
    local EXPECT_SSH_LOGIN="$2"
    local EXPECT_SSH_PASSWD="$3"
    local EXPECT_SSH_OPTIONS="$4"
    local EXPECT_SSH_CMD=$5

    if [[ -n "$EXPECT_SSH_CMD" ]]; then
        EXPECT_SSH_CMD=`printf %q "$EXPECT_SSH_CMD"`
    fi

    OUTPUT=$(expect -c "
    set timeout $EXPECT_SSH_TIMEOUT
    spawn ssh $EXPECT_SSH_OPTIONS $EXPECT_SSH_LOGIN@$EXPECT_SSH_HOST $EXPECT_SSH_CMD
    expect \"*assword:*\"
    send \"$EXPECT_SSH_PASSWD\r\"
    expect eof
    ")
    
    echo -e "\n
======= [expect_ssh started on ($EXPECT_SSH_HOST)] =======
[SSH COMMAND]:
ssh $EXPECT_SSH_OPTIONS $EXPECT_SSH_LOGIN@$EXPECT_SSH_HOST \"$EXPECT_SSH_CMD\"

[OUTPUT]:
$OUTPUT
======= [expect_ssh finished on ($EXPECT_SSH_HOST)] =======\n"
}

function multiple_expect_ssh()
{
    if [ $# -lt 2 ]; then
        echo "Usage: multiple_expect_ssh <\"non-interactive command\"> [username,password - example: 'root,fibranne' -  default: 'root'] <ip address(es)>"
        return 1
    fi

    local SSH_CMD="$1"
    shift

    # Check for username and password
    local USERNAME="root"
    local PASSWORD=""

    if [[ "$1" =~ [A-Za-z] ]]; then
        ORIGINAL_IFS=$IFS
        IFS=','
        local USERPASS=($1)
        IFS=$ORIGINAL_IFS

        USERNAME="${USERPASS[0]}"
        PASSWORD="${USERPASS[1]}"
        shift
    fi

    # Callisto switches hang when a public key is offered during ssh/scp operations
    local SSH_OPTIONS="-o PubKeyAuthentication=no -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"

    if [[ -z "$PASSWORD" ]]; then
        echo ""
        echo "Enter common password for $USERNAME: "
        read -s USER_PASSWD
    fi

    echo "[multiple_expect_ssh : Remotely executing on $@ ...]"

    # Turn off shell monitoring of backgrounded processes.
    set +m
    
    for i in "$@"; do
        { expect_ssh "$i" "$USERNAME" "$USER_PASSWD" "$SSH_OPTIONS" "$SSH_CMD" & } 2>/dev/null
    done

    wait

    # Turn on shell monitoring of backgrounded processes.
    set -m

    echo "[multiple_expect_ssh completed.]"
}

function expect_scp()
{
    local USAGE="Usage: expect_scp <scp command string - including source and destination> <scp options> <password>"

    if [[ $# -lt 3 || "$1" =~ (^-h$|^--help$) ]]; then
        echo $USAGE
        return 1
    fi

    local EXPECT_SCP_TIMEOUT="-1"
    local EXPECT_SCP_CMD="$1"
    local EXPECT_SCP_OPTIONS="$2"
    local EXPECT_SCP_PASSWD="$3"

    #if [[ -n "$EXPECT_SCP_CMD" ]]; then
    #    EXPECT_SCP_CMD=`printf %q "$EXPECT_SCP_CMD"`
    #fi

    OUTPUT=$(expect -c "
    set timeout $EXPECT_SCP_TIMEOUT
    spawn scp $EXPECT_SCP_OPTIONS $EXPECT_SCP_CMD
    expect \"*assword:*\"
    send \"$EXPECT_SCP_PASSWD\r\"
    expect eof
    ")
   
    echo -e "\n
======= [expect_scp started] =======
[SCP COMMAND]:
scp $EXPECT_SCP_OPTIONS \"$EXPECT_SCP_CMD\"

[OUTPUT]:
$OUTPUT
======= [expect_scp finished] =======\n"
}

function multiple_expect_scp()
{
    if [ $# -lt 3 ]; then
        echo "Usage: multiple_expect_scp <source - local file path> <destination - remote file path> <ip address(es)>"
        return 1
    fi

    local SCP_SOURCE_PATH="$1"
    shift
    local SCP_DESTINATION_PATH="$1"
    shift

    # Callisto switches hang when a public key is offered during ssh/scp operations
    local SCP_OPTIONS="-o PubKeyAuthentication=no -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"

    echo ""
    echo "Enter common root scp password: "
    read -s ROOT_PASSWD

    echo "[multiple_expect_scp : Remotely copying to $@ ...]"

    # Turn off shell monitoring of backgrounded processes.
    set +m

    for i in "$@"; do
        local SCP_CMD="$SCP_SOURCE_PATH root@$i:$SCP_DESTINATION_PATH"
        { expect_scp "$SCP_CMD" "$SCP_OPTIONS" "$ROOT_PASSWD" & } 2>/dev/null
    done

    wait

    # Turn on shell monitoring of backgrounded processes.
    set -m

    echo "[multiple_expect_scp completed.]"
}

function multiple_expect_remote_to_local_scp()
{
    if [ $# -lt 3 ]; then
        echo "Usage: multiple_expect_remote_to_local_scp <source - remote file path> <destination - local file path> <ip address(es)>"
        return 1
    fi

    local SCP_SOURCE_PATH="$1"
    shift
    local SCP_DESTINATION_PATH="$1"
    shift

    # Callisto switches hang when a public key is offered during ssh/scp operations
    local SCP_OPTIONS="-o PubKeyAuthentication=no -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"

    echo ""
    echo "Enter common root scp password: "
    read -s ROOT_PASSWD

    echo "[multiple_expect_remote_to_local_scp : Remotely copying from $@ ...]"

    # Turn off shell monitoring of backgrounded processes.
    set +m

    for i in "$@"; do
        if [[ ! -d "$SCP_DESTINATION_PATH/$i" ]]; then
            mkdir -p "$SCP_DESTINATION_PATH/$i"
        fi

        local SCP_CMD="root@$i:$SCP_SOURCE_PATH $SCP_DESTINATION_PATH/$i"
        { expect_scp "$SCP_CMD" "$SCP_OPTIONS" "$ROOT_PASSWD" & } 2>/dev/null
    done

    wait

    # Turn on shell monitoring of backgrounded processes.
    set -m

    echo "[multiple_expect_remote_to_local_scp completed.]"
}

function expect_telnet()
{
    local USAGE="Usage: expect_telnet <hostname or ip> <username> <password> <telnet command>"

    if [[ $# -lt 4 || "$1" =~ (^-h$|^--help$) ]]; then
        echo $USAGE
        return 1
    fi

    local EXPECT_TELNET_TIMEOUT="-1"
    local EXPECT_TELNET_HOST="$1"
    local EXPECT_TELNET_LOGIN="$2"
    local EXPECT_TELNET_PASSWD="$3"
    local EXPECT_TELNET_CMD="$4"
    local CTRL_C="\003"

    if [[ -n "$EXPECT_TELNET_CMD" ]]; then
        EXPECT_TELNET_CMD=`printf %q "$EXPECT_TELNET_CMD"`
    fi

    OUTPUT=$(expect -c "
    set timeout $EXPECT_TELNET_TIMEOUT 
    spawn telnet -l $EXPECT_TELNET_LOGIN $EXPECT_TELNET_HOST
    expect \"*assword:*\"
    send \"$EXPECT_TELNET_PASSWD\r\"
    expect {
        \"*Control-C*\"                 { send \"$CTRL_C\"; exp_continue }
        \"*$EXPECT_TELNET_LOGIN>*\"     { send \"$EXPECT_TELNET_CMD\r\" }
        \"*$EXPECT_TELNET_LOGIN*#*\"    { send \"$EXPECT_TELNET_CMD\r\" }
        eof
    }
    ") 

    echo -e "\n
======= [expect_telnet started on ($EXPECT_TELNET_HOST)] =======
[TELNET COMMAND]:
telnet -l $EXPECT_TELNET_LOGIN $EXPECT_TELNET_HOST \"$EXPECT_TELNET_CMD\"

[OUTPUT]:
$OUTPUT
======= [expect_telnet finished on ($EXPECT_TELNET_HOST)] =======\n"
}

function multiple_expect_telnet()
{
    if [ $# -lt 2 ]; then
        echo "Usage: multiple_expect_telnet <\"non-interactive command\"> <ip address(es)>"
        return 1
    fi

    local TELNET_CMD="$1"
    shift

    # Check for username and password
    local USERNAME="root"
    local PASSWORD=""

    if [[ "$1" =~ [A-Za-z] ]]; then
        ORIGINAL_IFS=$IFS
        IFS=','
        local USERPASS=($1)
        IFS=$ORIGINAL_IFS

        USERNAME="${USERPASS[0]}"
        PASSWORD="${USERPASS[1]}"
        shift
    fi

    if [[ -z "$PASSWORD" ]]; then
        echo ""
        echo "Enter common password for $USERNAME: "
        read -s USER_PASSWD
    fi

    echo "[multiple_expect_telnet : Remotely executing on $@ ...]"

    # Turn off shell monitoring of backgrounded processes.
    set +m

    for i in "$@"; do
        { expect_telnet "$i" "$USERNAME" "$USER_PASSWD" "$TELNET_CMD" & } 2>/dev/null
    done

    wait

    # Turn on shell monitoring of backgrounded processes.
    set -m

    echo "[multiple_expect_telnet completed.]"
}

function expect_firmwaredownload()
{
    local USAGE="Usage: expect_firmwaredownload <hostname or ip> <username> <password> <firmware path> [--default-config]>"

    if [[ $# -lt 5 || "$1" =~ (^-h$|^--help$) ]]; then
        echo $USAGE
        return 1
    fi

    local EXPECT_TELNET_TIMEOUT="-1"
    local EXPECT_TELNET_HOST="$1"
    local EXPECT_TELNET_LOGIN="$2"
    local EXPECT_TELNET_PASSWD="$3"
    local EXPECT_TELNET_FWDL_PATH="$4"
    local EXPECT_TELNET_DEFAULT="$5"
    local EXPECT_EXIT_CODE=0
    local CTRL_C="\003"

    local FWCOMMIT_CMD="/fabos/cliexec/firmwarecommit"
    local FWDL_CMD="/fabos/cliexec/firmwaredownload"
    local FWDL_OPTIONS="-snb"
    local FWDL_USER="releaseuser"
    local FWDL_PASS="releaseuser"

    if [[ "$EXPECT_TELNET_DEFAULT" == "--default-config" ]]; then
        FWDL_OPTIONS="${FWDL_OPTIONS}d"
    fi

    local EXPECT_FWDL_CMD="echo y | $FWCOMMIT_CMD; $FWDL_CMD $FWDL_OPTIONS $FWDL_HOST,$FWDL_USER,$FWDL_PATH,$FWDL_PASS"

    OUTPUT=$(expect -c "
    set timeout 15
    spawn telnet -l $EXPECT_TELNET_LOGIN $EXPECT_TELNET_HOST
    expect {
        timeout                                                         { puts \"$expect_out(buffer)\"; exit 1 }
        \"*assword:*\"                                                  { sleep 1; send \"$EXPECT_TELNET_PASSWD\r\" }
        \"No route to host\"                                            { puts \"$expect_out(buffer)\"; exit 2 }
    }
    expect {
        \"Login incorrect\"                                             { puts \"$expect_out(buffer)\"; exit 3 }
        \"Your account is disabled\"                                    { puts \"$expect_out(buffer)\"; exit 12 }
        \"Connection closed by foreign host\"                           { puts \"$expect_out(buffer)\"; exit 13 }
        \"Max remote sessions\"                                         { puts \"$expect_out(buffer)\"; exit 14 }
        \"*Control-C*\"                                                 { send \"$CTRL_C\"; exp_continue }
        \"*$EXPECT_TELNET_LOGIN>*\"                                     { send \"$EXPECT_FWDL_CMD\r\"; set timeout $EXPECT_TELNET_TIMEOUT }
        \"*$EXPECT_TELNET_LOGIN*#*\"                                    { send \"$EXPECT_FWDL_CMD\r\"; set timeout $EXPECT_TELNET_TIMEOUT }
    }
    expect {
        \"The server is inaccessible or firmware path is invalid*\"     { puts \"$expect_out(buffer)\"; exit 4 }
        \"Cannot download the same firmware version*\"                  { puts \"$expect_out(buffer)\"; exit 5 }
        \"Firmwaredownload failed because another session is running*\" { puts \"$expect_out(buffer)\"; exit 6 }
        \"The preinstall script failed\"                                { puts \"$expect_out(buffer)\"; exit 7 }
        \"*support*\"                                                   { puts \"$expect_out(buffer)\"; exit 8 }
        \"*Command failed*\"                                            { puts \"$expect_out(buffer)\"; exit 9 }
        \"Do you want to continue*\"                                    { send \"Y\r\" }
    }
    expect {
        \"All packages have been downloaded successfully*\"             { puts \"$expect_out(buffer)\"; exit 0 }
        \"*failed*\"                                                    { puts \"$expect_out(buffer)\"; exit 10 }
        \"*faulty state*\"                                              { puts \"$expect_out(buffer)\"; exit 11 }
        \"*$EXPECT_TELNET_LOGIN>*\"                                     { exit 0 } 
        \"*$EXPECT_TELNET_LOGIN*#*\"                                    { exit 0 } 
    }

    expect eof
    catch wait result
    exit [lindex \$result 3]
    "); EXPECT_EXIT_CODE=$?

    echo -e "\n
======= [expect_firmwaredownload started on ($EXPECT_TELNET_HOST)] =======
[FIRMWAREDOWNLOAD COMMAND]:
telnet -l $EXPECT_TELNET_LOGIN $EXPECT_TELNET_HOST \"$EXPECT_FWDL_CMD\"

[OUTPUT]:
$OUTPUT
======= [expect_firmwaredownload finished on ($EXPECT_TELNET_HOST => Exit Code : $EXPECT_EXIT_CODE)] =======\n"

    return $EXPECT_EXIT_CODE
}

function multiple_expect_firmwaredownload()
{
    local USAGE="Usage: multiple_expect_firmwaredownload [--default-config] <full firmware path> <filename containing ip addresses [additional ipaddress(es)] | ipaddress(es)>"

    if [[ $# -lt 2 ]]; then
        echo "$USAGE"
        return 1
    fi

    # Associative arrays for background process status
    declare -A PIDS
    declare -A RETURN_STATUS

    local SUCESSFUL_IP_ADDRESSES=""
    local FAILED_IP_ADDRESSES=""
    local DEFAULT_CONFIG=""
    local IPLIST_FILENAME=""
    local IPLIST=()

    for i in "$@"; do
        if [[ "$i" =~ ^--default-config$ ]]; then
            DEFAULT_CONFIG="$i" 
        elif [[ "$i" =~ ^[0-9.]+$ ]]; then
            IPLIST+=("$i")
        elif [[ -f "$i" ]]; then
            IPLIST_FILENAME="$i"
            IPLIST+=( $(cat $IPLIST_FILENAME) )
        elif [[ -d "$i" ]]; then
            FWDL_PATH="$i"
        else
            echo "$USAGE"
            echo "Unrecognized option \"$i\"."
        fi
    done

    if [[ -z "$FWDL_PATH" ]]; then
        echo "$USAGE"
        echo "No valid firmware path specified!"
        return 1
    fi

    if [[ ${#IPLIST[@]} -eq 0 ]]; then
        echo "$USAGE"
        echo "No IP Address(es) specified!"
        return 1
    else
        IPLIST=( `printf '%s\n' "${IPLIST[@]}" | awk '!a[$0]++'` )
        echo "[IP Address(es) to download firmware]:"
        printf '  - %s\n' "${IPLIST[@]}" 
    fi

    echo ""
    echo "Enter common root password: "
    read -s ROOT_PASSWD

    if [[ -z "$DEFAULT_CONFIG" ]]; then
        echo "[multiple_expect_firmwaredownload : Downloading firmware to ${IPLIST[@]} ...]"
    else
        echo "[multiple_expect_firmwaredownload : Downloading firmware with default-config to ${IPLIST[@]} ...]"
    fi

    # Turn off shell monitoring of backgrounded processes.
    set +m

    for i in "${IPLIST[@]}"; do
        { expect_firmwaredownload "$i" "root" "$ROOT_PASSWD" "$FWDL" "$DEFAULT_CONFIG" & } 2>/dev/null
        PIDS["$i"]=$!
    done

    for i in "${IPLIST[@]}"; do
        wait ${PIDS["$i"]}
        RETURN_STATUS["$i"]=$?
    done

    # Turn on shell monitoring of backgrounded processes.
    set -m

    for i in "${IPLIST[@]}"; do
        if [[ 0 -eq ${RETURN_STATUS[$i]} ]]; then
            if [[ -z "$SUCESSFUL_IP_ADDRESSES" ]]; then
                SUCESSFUL_IP_ADDRESSES="$i"
            else
                SUCESSFUL_IP_ADDRESSES="$SUCESSFUL_IP_ADDRESSES $i"
            fi
        else
            if [[ -z "$FAILED_IP_ADDRESSES" ]]; then
                FAILED_IP_ADDRESSES="$i"
            else
                FAILED_IP_ADDRESSES="$FAILED_IP_ADDRESSES $i"
            fi
        fi
    done

    echo "[multiple_expect_firmwaredownload : Overall completion status]:"

    if [[ -n "$SUCESSFUL_IP_ADDRESSES" && -z "$FAILED_IP_ADDRESSES" ]]; then
        echo "Firmwaredownload has completed successfully on all entries ($SUCESSFUL_IP_ADDRESSES)."
    elif [[ -n "$SUCESSFUL_IP_ADDRESSES" && -n "$FAILED_IP_ADDRESSES" ]]; then
        echo "Firmwaredownload has completed successfully on ($SUCESSFUL_IP_ADDRESSES)"
        echo "    and failed on ($FAILED_IP_ADDRESSES)."
    elif [[ -z "$SUCESSFUL_IP_ADDRESSES" && -n "$FAILED_IP_ADDRESSES" ]]; then
        echo "Firmwaredownload has failed on all entries ($FAILED_IP_ADDRESSES)."
    elif [[ -z "$SUCESSFUL_IP_ADDRESSES" && -z "$FAILED_IP_ADDRESSES"  ]]; then
        echo "multiple_expect_firmwaredownload could not obtain return status for all entries ($@)"
    else
        echo "multiple_expect_firmwaredownload failed to get return status for all entries ($@)"
    fi

    local COUNT=0

    for i in "${!RETURN_STATUS[@]}"; do
        ((COUNT++))
        echo -e "    $COUNT)\t$i\t=> Exit Code : ${RETURN_STATUS[$i]}"
    done
}

function xml_builder()
{
    local INPUT=("$@")
    local FIRST="$INPUT"

    ORIGINAL_IFS=$IFS
    IFS='='
    local EXPECT_NETCONF_CMD_PARTS=($FIRST)
    IFS=$ORIGINAL_IFS

    if [[ ${#EXPECT_NETCONF_CMD_PARTS[@]} -gt 1 ]]; then
        echo -e "<${EXPECT_NETCONF_CMD_PARTS[0]}>${EXPECT_NETCONF_CMD_PARTS[1]}</${EXPECT_NETCONF_CMD_PARTS[0]}>"

        if [[ ${#INPUT[@]} -gt 1 ]]; then
            INPUT=("${INPUT[@]:1}")
            xml_builder "${INPUT[@]}"
        fi
    else
        local EXPECT_NETCONF_XMLNS="${XMLNS_MAP[$EXPECT_NETCONF_CMD_PARTS]}"

        if [[ -n "$EXPECT_NETCONF_XMLNS" ]]; then
            echo -e "<"$EXPECT_NETCONF_CMD_PARTS" xmlns=\\"\""$EXPECT_NETCONF_XMLNS"\\"\">"    
        else
            echo -e "<"$EXPECT_NETCONF_CMD_PARTS">"
        fi
        
        if [[ ${#INPUT[@]} -gt 1 ]]; then
            INPUT=("${INPUT[@]:1}")
            xml_builder "${INPUT[@]}"
        fi

        echo -e "</"$EXPECT_NETCONF_CMD_PARTS">"
    fi
}

function expect_netconf()
{
    local USAGE="Usage: expect_netconf <hostname or ip> <username> <password> <netconf command>"

    if [[ $# -lt 4 || "$1" =~ (^-h$|^--help$) ]]; then
        echo $USAGE
        return 1
    fi

    local EXPECT_SSH_TIMEOUT="-1"
    local EXPECT_NETCONF_HOST="$1"
    local EXPECT_NETCONF_LOGIN="$2"
    local EXPECT_NETCONF_PASSWD="$3"
    local EXPECT_NETCONF_CMDS="$4"
    local EXPECT_SSH_OPTIONS="-o PubKeyAuthentication=no -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
    local EXPECT_NETCONF_OPTIONS="-s netconf"
    NETCONF_XMLNS=(`get_netconf_xmlns`)

    if [[ ${#NETCONF_XMLNS[@]} -eq 0 ]]; then
        echo -e "Error: get_netconf_xmlns() did not return any results!\nPlease ensure \"get_netconf_xmlns --update\" has been called with a proper clearcase view set under a compiled YANG directory."
        return 2
    fi

    eval "declare -A XMLNS_MAP=(`get_netconf_xmlns`)"

    local EXPECT_NETCONF_HELLO_CAPABILITIES="<?xml version=\\\"1.0\\\" encoding=\\\"UTF-8\\\"?>\n<hello xmlns=\\\"urn:ietf:params:xml:ns:netconf:base:1.0\\\">\n<capabilities>\n<capability>urn:ietf:params:netconf:base:1.0</capability>\n</capabilities>\n</hello>\n]]>]]>"
    local EXPECT_NETCONF_RPC_START_TAG="<rpc xmlns=\\\"urn:ietf:params:xml:ns:netconf:base:1.0\\\" message-id=\\\"1\\\">"
    local EXPECT_NETCONF_RPC_END_TAG="</rpc>"
    local EXPECT_NETCONF_XMLNS=""
    local EXPECT_NETCONF_XML_CMD=""
    local EXPECT_NETCONF_RPC=()

    local EXPECT_NETCONF_CMDS_ARRAY=($EXPECT_NETCONF_CMDS)

    local ORIGINAL_IFS=$IFS
    IFS=','

    for EXPECT_NETCONF_CMD in ${EXPECT_NETCONF_CMDS_ARRAY[@]}; do
        local EXPECT_NETCONF_CMD_ARRAY=($EXPECT_NETCONF_CMD)

        if [[ "$EXPECT_NETCONF_CMD_ARRAY" == "get-config" ]]; then
            # Show running-config equivalent NETCONF Request
            local ELEMENT="$EXPECT_NETCONF_CMD_ARRAY"

            EXPECT_NETCONF_XML_CMD="<"$ELEMENT">\n<source>\n<running>\n</running>\n</source>\n"

            if [[ ${#EXPECT_NETCONF_CMD_ARRAY[@]} -gt 1 ]]; then
                # Filtered show running-config

                EXPECT_NETCONF_XML_CMD+="<filter type=\\"\"subtree\\"\">\n"

                EXPECT_NETCONF_CMD_ARRAY=("${EXPECT_NETCONF_CMD_ARRAY[@]:1}")

                EXPECT_NETCONF_XML_CMD+=`xml_builder "${EXPECT_NETCONF_CMD_ARRAY[@]}"`

                EXPECT_NETCONF_XML_CMD+="\n</filter>\n"
            fi

            EXPECT_NETCONF_XML_CMD+="</"$ELEMENT">"
        else
            # NETCONF Custom RPC Request

            EXPECT_NETCONF_XMLNS="${XMLNS_MAP[$EXPECT_NETCONF_CMD_ARRAY]}"

            if [[ ${#EXPECT_NETCONF_CMD_ARRAY[@]} -eq 1 ]]; then
                # RPC Request without input

                EXPECT_NETCONF_XML_CMD="<"$EXPECT_NETCONF_CMD" xmlns=\\"\""$EXPECT_NETCONF_XMLNS"\\"\">\n</"$EXPECT_NETCONF_CMD">"
            else
                # RPC Request with input

                local NETCONF_ELEMENT="$EXPECT_NETCONF_CMD_ARRAY"

                EXPECT_NETCONF_XML_CMD="<"$NETCONF_ELEMENT" xmlns=\\"\""$EXPECT_NETCONF_XMLNS"\\"\">\n"
                EXPECT_NETCONF_CMD_ARRAY=("${EXPECT_NETCONF_CMD_ARRAY[@]:1}")

                EXPECT_NETCONF_XML_CMD+=`xml_builder "${EXPECT_NETCONF_CMD_ARRAY[@]}"`

                EXPECT_NETCONF_XML_CMD+="\n</"$NETCONF_ELEMENT">"
            fi
        fi

        EXPECT_NETCONF_RPC+=($EXPECT_NETCONF_HELLO_CAPABILITIES"\n"$EXPECT_NETCONF_RPC_START_TAG"\n"$EXPECT_NETCONF_XML_CMD"\n"$EXPECT_NETCONF_RPC_END_TAG)
    done

    OUTPUT=$(expect -c "
    set timeout $EXPECT_SSH_TIMEOUT
    spawn ssh $EXPECT_SSH_OPTIONS $EXPECT_NETCONF_LOGIN@$EXPECT_NETCONF_HOST $EXPECT_NETCONF_OPTIONS
    expect \"*assword:*\"
    send \"$EXPECT_NETCONF_PASSWD\r\"
    expect \"]]>]]>\"
    send \"$EXPECT_NETCONF_RPC\r\"
    expect \"</rpc-reply>]]>]]>\"
    ")
   
    echo -e "\n
======= [expect_netconf started on ($EXPECT_NETCONF_HOST)] =======
[NETCONF COMMAND]:
$EXPECT_NETCONF_RPC

[OUTPUT]:
$OUTPUT
======= [expect_netconf finished on ($EXPECT_NETCONF_HOST)] =======\n"

    IFS=$ORIGINAL_IFS
}

function get_netconf_xmlns()
{
    local USAGE="Usage: get_netconf_xmlns [--update]"
    local UPDATE=$1
    local NETCONF_XMLNS_FILENAME="$HOME/.netconf_xmlns"
    local NETCONF_XMLNS=""

    if [[ -n "$1" && "$1" != "--update" || "$1" =~ (^-h$|^--help$) ]]; then
        echo $USAGE
        return 1
    fi

    if [[ "$UPDATE" == "--update" ]]; then
        NETCONF_XMLNS1=`grep "rpc name=" *.xml 2>/dev/null | sed -n 's/^\(.*\):.*"\(.*\)".*$/\2:\1/p' | awk -F ':' '{printf ("[%s]=", $1); system("grep namespace " $2 " | sed \"s/.*<namespace uri=//g\" | sed \"s@/>@@g\" ")}' | sort`
        NETCONF_XMLNS2=`grep "xmlns:" *.xml 2>/dev/null | sed -n 's/.*xmlns:\(.*\)="\(.*\)".*/[\1]="\2"/p' | sort | uniq`

        if [[ -n "$NETCONF_XMLNS1" && -n "$NETCONF_XMLNS2" ]]; then
            NETCONF_XMLNS=`echo -e "$NETCONF_XMLNS1\n$NETCONF_XMLNS2" | sort | uniq`
            echo -e "$NETCONF_XMLNS" > $NETCONF_XMLNS_FILENAME
            echo -e "$NETCONF_XMLNS\n\n[Contents written to: $NETCONF_XMLNS_FILENAME]"
        else
            echo -e "Could not find XML namespaces for NETCONF.  Please make sure you are in a directory that has compiled YIN (*.xml) files." >&2
            return 2
        fi
    else
        local UPDATE_MSG="Please run \"get_netconf_xmlns --update\" in a directory that contains compiled YANG files."

        if [[ -f "$NETCONF_XMLNS_FILENAME" ]]; then
            if [[ -s "$NETCONF_XMLNS_FILENAME" ]]; then
                cat "$NETCONF_XMLNS_FILENAME"
            else
                echo -e "Contents of $NETCONF_XMLNS_FILENAME are empty!\n$UPDATE_MSG" >&2
                return 4
            fi
        else
            echo -e "$NETCONF_XMLNS_FILENAME file is missing!\n$UPDATE_MSG" >&2
            return 3
        fi
    fi
}

function curl_brcd()
{
    local USAGE="Usage: curl_brcd <GET | POST | PUT | PATCH | DELETE> <URI> [<Data/Payload for POST|PUT|PATCH Requests> | <Resource Depth for GET Requests: Default is 1>]"
    local REST_OPERATION=$1
    local URI=$2
    local DATA=$3
    local HEADER="Accept: application/vnd.configuration.resource+xml"
    local RESOURCE_DEPTH_HEADER=""
    local USER="admin"
    local PASS="password"

    if [[ $# -lt 2 || "$1" =~ (^-h$|^--help$) ]]; then
        echo $USAGE
        return 1
    fi
 
    if [[ "$REST_OPERATION" != "GET" && "$REST_OPERATION" != "POST" && "$REST_OPERATION" != "PUT" && "$REST_OPERATION" != "PATCH" && "$REST_OPERATION" != "DELETE" ]]; then
        echo $USAGE
        return 2
    fi

    if [[ "$URI" =~ rest[/]?$ ]]; then
        # Remove header for this special case
        HEADER=""
    fi

    if [[ "$REST_OPERATION" == "GET" && -n "$DATA" ]]; then
        # Reusing DATA for Resource Depth
        RESOURCE_DEPTH_HEADER="Resource-Depth: $DATA"
        DATA=""
        echo $RESOURCE_DEPTH_HEADER
    fi

    if [[ -n "$DATA" ]]; then
        echo curl -v -k -X $REST_OPERATION -H \"$HEADER\" -H \"$RESOURCE_DEPTH_HEADER\" -u "$USER":"$PASS" $URI -d \"$DATA\"
        curl -v -k -X $REST_OPERATION -H "$HEADER" -H "$RESOURCE_DEPTH_HEADER" -u "$USER":"$PASS" $URI -d "$DATA"
    else
        echo curl -v -k -X $REST_OPERATION -H \"$HEADER\" -H \"$RESOURCE_DEPTH_HEADER\" -u "$USER":"$PASS" $URI
        curl -v -k -X $REST_OPERATION -H "$HEADER" -H "$RESOURCE_DEPTH_HEADER" -u "$USER":"$PASS" $URI
    fi
}

function get_private_shared_memory()
{
    local USAGE="Usage: get_private_shared_memory <IP Address>"
    local HOST_IP="$1"
    local HOST_CMD='smaps -t `pidof Dcmd.Linux.powerpc` | grep Total | sed -n "s/.* \([0-9]*\) KB | Total$/\1/p"'
    local HOST_OPTIONS='-o PubKeyAuthentication=no -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no'

    if [[ $# -lt 1 || "$1" =~ (^-h$|^--help$) ]]; then
        echo $USAGE
        return 1
    fi

    expect_ssh "$HOST_IP" "root" "fibranne" "$HOST_OPTIONS" "$HOST_CMD"
}

function get_process_file_descriptor_usage()
{
    local USAGE="Usage: get_process_file_descriptor_usage <Process Name> <IP Address>"
    local PROCESS_NAME="$1"
    local HOST_IP="$2"
    local HOST_CMD='ls -1 /proc/`pidof '$PROCESS_NAME'`/fd | wc -l'
    local HOST_OPTIONS='-o PubKeyAuthentication=no -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no'

    if [[ $# -lt 2 || "$1" =~ (^-h$|^--help$) ]]; then
        echo $USAGE
        return 1
    fi

    expect_ssh "$HOST_IP" "root" "fibranne" "$HOST_OPTIONS" "$HOST_CMD"
}

#! /bin/bash
set -o errexit   # abort on nonzero exitstatus
set -o nounset   # abort on unbound variable
set -o pipefail  # don't hide errors within pipes




function misses_image {
    # Function for boolean checks if an image already exists.
    # Uses the docker image inspect command. If it
    # finds the according image we can be save that it is there.
    # This is bettern then an docker image ls & a grep check.
    #
    # Arguments:
    #  - $1 => imageName - Name of the image that we want to check.
    #                      Supports normal image names, but also tags
    #                      or ids.
    imageName=$1
    if [[ -z $(docker image inspect --format '{{.Id}}' "$imageName" 2> /dev/null) ]]; then
        return
    else
        false
    fi
}

function clean {
    # Ensures that we can restart our script from an completely clean state.
    rm -rf config
    rm -rf gfz-command-line-tool-repository
    rm -rf quakeledger
    rm -rf shakyground-grid-file
    rm -rf shakyground
    rm -rf assetmaster
    rm -rf modelprop
    rm -rf deus
    rm -rf tsunami-wps
    docker image rm "gfzriesgos/riesgos-wps" || echo "Skip deleting image"
    docker image rm "gfzriesgos/quakeledger" || echo "Skip deleting image"
    docker image rm "gfzriesgos/shakyground-grid-file" || echo "Skip deleting image"
    docker image rm "gfzriesgos/shakyground" || echo "Skip deleting image"
    docker image rm "gfzriesgos/assetmaster" || echo "Skip deleting image"
    docker image rm "gfzriesgos/modelprop" || echo "Skip deleting image"
    docker image rm "gfzriesgos/deus" || echo "Skip deleting image"
    docker image rm "awi/tssim"  || echo "Skip deleting image"
}

function build_riesgos_wps {
    image="gfzriesgos/riesgos-wps"
    if misses_image $image; then
            echo "Building $image ... "
            if [ ! -d gfz-command-line-tool-repository ]; then
                git clone https://github.com/riesgos/gfz-command-line-tool-repository
            fi
            cd gfz-command-line-tool-repository
            docker build -t $image:latest -f assistance/Dockerfile .
            cd ..
    else
            echo "Already exists: $image"
    fi
}

function build_quakeledger {
    image="gfzriesgos/quakeledger"
    repo="https://github.com/gfzriesgos/quakeledger"
    if misses_image $image; then
            echo "Building $image ..."
            if [ ! -d quakeledger ]; then
                git clone "$repo"
            fi
            cd quakeledger
            docker image build --tag $image:latest --file ./metadata/Dockerfile .
            cd ..
    else
            echo "Already exists: $image"
    fi
    # And add the json config to our configs folder.
    if [ ! -d "configs" ]; then
        mkdir -p "configs"
    fi
    if [ ! -f "config/quakeledger.json" ]; then
        if [ ! -f "quakeledger/metadata/quakeledger.json" ]; then
            git clone "$repo"
        fi
        cp quakeledger/metadata/quakeledger.json configs
    fi
}

function build_shakyground_grid {
    # We reuse this new image later as the base image for shakyground.
    # So that all the grid files are already there.
    image="gfzriesgos/skakyground-grid-file"
    repo="https://github.com/gfzriesgos/shakyground-grid-file"
    if misses_image $image; then
        if [ ! -d shakyground-grid-file ]; then
            git clone "$repo"
        fi
        cd shakyground-grid-file
        docker image build --tag $image:latest --file ./Dockerfile .
        cd ..
    else
        echo "Already exists: $image"
    fi
}

function build_shakyground {
    image="gfzriesgos/shakyground"
    repo="https://github.com/gfzriesgos/shakyground"
    if misses_image $image; then
            echo "Building $image ..."
            if [ ! -d shakyground ]; then
                git clone "$repo"
            fi
            cd shakyground
            # Replace the FROM entry in the dockerfile
            # so that we use our latest shakyground-grid-file image
            sed -i -e 's/FROM gfzriesgos\/shakyground-grid-file:20211011/FROM gfzriesgos\/skakyground-grid-file:latest/' ./metadata/Dockerfile
            docker image build --tag $image:latest --file ./metadata/Dockerfile .
            cd ..
    else
            echo "Already exists: $image"
    fi
    # And add the json config to our configs folder.
    if [ ! -d "configs" ]; then
        mkdir -p "configs"
    fi
    if [ ! -f "config/shakyground.json" ]; then
        if [ ! -f "shakyground/metadata/shakyground.json" ]; then
            git clone "$repo"
        fi
        cp shakyground/metadata/shakyground.json configs
    fi
}

function build_assetmaster {
    image="gfzriesgos/assetmaster"
    repo="https://github.com/gfzriesgos/assetmaster"
    if misses_image $image; then
        echo "Building $image ..."
        if [ ! -d assetmaster ]; then
            git clone "$repo"
        fi
        cd assetmaster
        docker image build --tag $image --file ./metadata/Dockerfile .
        cp metadata/assetmaster.json ../configs
        cd ..
    else
        echo "Already exists: $image"
    fi
    # And add the json config to our configs folder.
    if [ ! -d "configs" ]; then
        mkdir -p "configs"
    fi
    if [ ! -f "config/assetmaster.json" ]; then
        if [ ! -f "assetmaster/metadata/assetmaster.json" ]; then
            git clone "$repo"
        fi
        cp assetmaster/metadata/assetmaster.json configs
    fi
}

function build_modelprop {
    image="gfzriesgos/modelprop"
    repo="https://github.com/gfzriesgos/modelprop"
    if misses_image $image; then
        echo "Building $image ..."
        if [ ! -d modelprop ]; then
            git clone "$repo"
        fi
        cd modelprop
        docker image build --tag $image --file ./metadata/Dockerfile .
        cd ..
    else
        echo "Already exists: $image"
    fi
    # And add the json config to our configs folder.
    if [ ! -d "configs" ]; then
        mkdir -p "configs"
    fi
    if [ ! -f "config/modelprop.json" ]; then
        if [ ! -f "modelprop/metadata/modelprop.json" ]; then
            git clone "$repo"
        fi
        cp modelprop/metadata/modelprop.json configs
    fi
}

function build_deus {
    image="gfzriesgos/deus"
    repo="https://github.com/gfzriesgos/deus"
    if misses_image $image; then
        echo "Building $image ..."
        if [ ! -d deus ]; then
            git clone "$repo"
        fi
        cd deus
        docker image build --tag $image --file ./metadata/Dockerfile .
        cp metadata/deus.json ../configs
        cd ..
    else
        echo "Already exists: $image"
    fi
    if [ ! -d "configs" ]; then
        mkdir -p "configs"
    fi
    if [ ! -f "config/deus.json" ]; then
        if [ ! -f "deus/metadata/deus.json" ]; then
            git clone "$repo"
        fi
        cp deus/metadata/deus.json configs
    fi
    # The json configuration files for neptunus & volcanus
    # belong to deus. So copy them as well.
    if [ ! -f "config/volcanus.json" ]; then
        if [ ! -f "deus/metadata/volcanus.json" ]; then
            git clone "$repo"
        fi
        cp deus/metadata/volcanus.json configs
    fi
    if [ ! -f "config/neptunus.json" ]; then
        if [ ! -f "deus/metadata/neptunus.json" ]; then
            git clone "$repo"
        fi
        cp deus/metadata/neptunus.json configs
    fi
}

function build_tssim {
    image="awi/tssim"
    if misses_image $image; then
            echo "Building $image ..."
            if [ ! -d "tsunami-wps" ]; then
                git clone https://gitlab.awi.de/tsunawi/web-services/tsunami-wps
            fi
            cd tsunami-wps
            git checkout create-full-docker-build
            # TODO ??
            # download data from https://nextcloud.awi.de/s/aNXgXxN9qk5RZRz
            # download geoserver- from https://nextcloud.awi.de/....TODO....  (check for sensitive data like passwords!)
            # maybe not required? download `inun` csv files from nextcloud
            docker image build --tag $image:latest --file ./app/dockerfile .
            cd ..
    else
            echo "Already exists: $image"
    fi
}

function build_sysrel {
    echo "TODO!!"
}

function prepare_riesgos_wps {
    # We should put all this in an init container for the startup.
    docker run -p8080:8080 \
                -v /var/run/docker.sock:/var/run/docker.sock \
                --name=wps \
                -d \
                -e CATALINA_OPTS=-Xmx12g\ -Xms12g \
                -e RIESGOS_MAX_CACHE_SIZE_MB=8192 \
                -e RIESGOS_GEOSERVER_USERNAME=admin \
                -e RIESGOS_GEOSERVER_PASSWORD=geoserver \
                -e RIESGOS_GEOSERVER_ACCESS_BASE_URL=http://localhost:8080/geoserver \
                -e RIESGOS_GEOSERVER_SEND_BASE_URL=http://localhost:8080/geoserver \
                gfzriesgos/riesgos-wps
    cd gfz-command-line-tool-repository
    cd assistance/SLD
    ./add-style-to-geoserver.sh
    cd ../..
    ## @TODO: Update configuration to allow CORS. In assistance/geoserver-web.xml, insert <filter>
    cd ..
    docker cp ./configs/* wps:/usr/share/riesgos/json-configurations
}

function build_all {
    build_riesgos_wps
    build_quakeledger
    build_shakyground_grid
    build_shakyground
    build_assetmaster
    build_modelprop
    build_deus
    build_tssim
    build_sysrel
    prepare_riesgos_wps
}

function main {
    # Main function to dispatch to several actions.
    # Idea is to make the functions here easier to test.
    # If we give it an parameter, we invoke other functions.
    # If we don't give anohter parameter, then we run the
    # build_all.
    if [ -z ${1+x} ]; then
        # In case we don't have any subcommand then
        # we want to build all.
        build_all
    elif [ "$1" == "all" ]; then
        build_all
    elif [ "$1" == "misses_image" ]; then
        image=$2
        if misses_image "$image"; then
            echo "$image is missing"
        else
            echo "$image is already there"
        fi
    elif [ "$1" == "clean" ]; then
        clean
    elif [ "$1" == "riesgos-wps" ]; then
        build_riesgos_wps
    elif [ "$1" == "quakeledger" ]; then
        build_quakeledger
    elif [ "$1" == "shakyground-grid" ]; then
        build_shakyground_grid
    elif [ "$1" == "shakyground" ]; then
        build_shakyground
    elif [ "$1" == "assetmaster" ]; then
        build_assetmaster
    elif [ "$1" == "modelprop" ]; then
        build_modelprop
    elif [ "$1" == "deus" ]; then
        build_deus
    elif [ "$1" == "tssim" ]; then
        build_tssim
    elif [ "$1" == "sysrel" ]; then
        build_sysrel
    elif [ "$1" == "prepare-riesgos-wps" ]; then
        prepare_riesgos_wps
    else
        echo "no known command found for: $1"
    fi
}

main "$@"




#echo "Building backend ..."
#echo "Building frontend ..."
#echo "Done!"
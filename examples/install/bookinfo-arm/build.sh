set -o errexit

if [ "$#" -ne 2 ]; then
    echo "Incorrect parameters"
    echo "Usage: build-services.sh <version> <prefix>"
    exit 1
fi

VERSION=$1
PREFIX=$2


#plain build -- no ratings
docker build --pull -t "${PREFIX}/examples-bookinfo-reviews-v1:${VERSION}" -t "${PREFIX}/examples-bookinfo-reviews-v1:latest" --build-arg service_version=v1 .
#with ratings black stars
docker build --pull -t "${PREFIX}/examples-bookinfo-reviews-v2:${VERSION}" -t "${PREFIX}/examples-bookinfo-reviews-v2:latest" --build-arg service_version=v2 \
    --build-arg enable_ratings=true .
#with ratings red stars
docker build --pull -t "${PREFIX}/examples-bookinfo-reviews-v3:${VERSION}" -t "${PREFIX}/examples-bookinfo-reviews-v3:latest" --build-arg service_version=v3 \
    --build-arg enable_ratings=true --build-arg star_color=red .
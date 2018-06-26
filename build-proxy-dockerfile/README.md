# Usage

```sh
# clone repos
git clone https://github.com/jwendell/temp.git
git clone https://github.com/openshift-istio/rpms.git

# copy Dockerfile and .repo file from this repo to the rpms dir
cp temp/Dockerfile temp/openshift-istio-bazel.repo rpms

# build the image
cd rpms
docker build -t build-proxy .

# run the container
docker run -it build-proxy

# now, from inside the container, run whatever you want, e.g.:
./fetch.sh
```
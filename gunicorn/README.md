# Gunicorn example

# Build base Gunicorn Image

User is expected to input thier base image name in `Dockerfile`. In case user want to experiment
given example, please build base image using below command:
```
docker build -t gunicorn-base -f gunicorn-base.dockerfile .
```

In case you already have a base image, please replace `gunicorn-base` with your image name in
Dockerfile.

# Create enclave signing key

```
openssl genrsa -3 -out enclave-key.pem 3072
```

If user want to reuse existing it, please copy in current directory and rename it to 
`enclave-key.pem`.

# Create the Graminize image

Execute below command to create Graminize image:

```
docker build -t gunicorn-gramine .
```
# Input command line arguments

Please add any argument expected to `loader.argv` in `gunicorn.manifest.template` file

# Run Graminize image

```
docker run --device=/dev/sgx_enclave --net=host -it gunicorn-gramine
```

These commands will start the Gunicorn server in the foreground, you will need to open
another console to run the client.

Once the server has started, you can test it with `curl`.

```
curl http://127.0.0.1:8000/hello
```
which should receive text from server in reply as `{"data":"Hello World"}`

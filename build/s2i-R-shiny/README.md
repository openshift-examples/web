# Source to image example for R shiny

## Build builder image
```
oc create -f https://raw.githubusercontent.com/rbo/openshift-examples/master/build/s2i-R-shiny/builder.yaml
oc start-build r-shiny-s2i [--follow]
```
### Insides from the builder

Install app lication and dependencies with
```
$ R -s -e "library(deplearning); depl_check()"
$ R -s -e "menu = function(choices, graphics = FALSE, title = NULL) { return(1) };  library(deplearning); depl_check()"
```

Run app with
```
$ R -s -e 'library("shiny"); runApp()'
```


## Build app with builder image
```
oc new-app r-shiny-s2i~https://github.com/rstudio/shiny-examples \
    --context-dir=082-word-cloud \
    --name=word-cloud \
    --strategy=source
oc expose svc/word-cloud
```

## Resources 

- https://www.r-bloggers.com/permanently-setting-the-cran-repository/
- https://rdrr.io/github/MilesMcBain/deplearning/


## Playground

Dockerfile.playground:
```Dockerfile
FROM docker-registry-default.ocp3.bohne.io/shiny/r-shiny-s2i:latest
COPY ./s2i/bin/ /usr/libexec/s2i

USER 1001

# Set the default port for applications built using this image
EXPOSE 8080

CMD ["/usr/libexec/s2i/usage"]

```

And build and run:
```
docker pull docker-registry-default.ocp3.bohne.io/shiny/r-shiny-s2i:latest 
docker build -t b -f Dockerfile.playground .
s2i build https://github.com/rstudio/shiny-examples b word-cloud --context-dir=082-word-cloud --loglevel=99

docker run word-cloud
```


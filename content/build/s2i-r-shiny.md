---
title: S2I - R shiny
linktitle: S2I - R shiny
weight: 5500
description: TBD
tags:
  - s2i
---
# Source to image example for R shiny

## Build builder image

```text
oc create -f - -n openshift <<EOF
---
apiVersion: image.openshift.io/v1
kind: ImageStream
metadata:
  name: r-shiny-s2i
---
apiVersion: build.openshift.io/v1
kind: BuildConfig
metadata:
  labels:
    build: r-shiny-s2i
  name: r-shiny-s2i
spec:
  failedBuildsHistoryLimit: 5
  nodeSelector: null
  output:
    to:
      kind: ImageStreamTag
      name: r-shiny-s2i:latest
  postCommit: {}
  resources: {}
  runPolicy: Serial
  source:
    contextDir: build/s2i-R-shiny/builder
    git:
      uri: 'https://github.com/rbo/openshift-examples.git'
    type: Git
  strategy:
    dockerStrategy:
      from:
        kind: DockerImage
        name: 'rhscl/s2i-base-rhel7:latest'
    type: Docker
  successfulBuildsHistoryLimit: 5
EOF
oc start-build r-shiny-s2i [--follow] -n openshift
oc create -f - -n openshif <<EOF
apiVersion: template.openshift.io/v1
kind: Template
labels:
  template: s2i-r-shiny-example
message: |-
  The following service(s) have been created in your project: ${NAME}.

  For more information about using this template, including OpenShift considerations, see https://github.com/rbo/openshift-examples/tree/master/build/s2i-R-shiny.
metadata:
  annotations:
    description: An example R shiny https://github.com/rbo/openshift-examples/tree/master/build/s2i-R-shiny.
    iconClass: icon-play
    openshift.io/display-name: R Shiny exmaple
    openshift.io/documentation-url: https://github.com/rbo/openshift-examples/tree/master/build/s2i-R-shiny
    openshift.io/long-description: R Shiny exmaple
    openshift.io/provider-display-name: Robert Bohne
    openshift.io/support-url: https://github.com/rbo/openshift-examples/tree/master/build/s2i-R-shiny
    tags: quickstart,r,shiny,r-shiny,s2i
  creationTimestamp: null
  name: s2i-r-shiny-example
objects:
- apiVersion: v1
  kind: Service
  metadata:
    annotations:
      description: Exposes and load balances the application pods
    name: ${NAME}
  spec:
    ports:
    - name: web
      port: 8080
      targetPort: 8080
    selector:
      name: ${NAME}
- apiVersion: v1
  kind: Route
  metadata:
    annotations:
      template.openshift.io/expose-uri: http://{.spec.host}{.spec.path}
    name: ${NAME}
  spec:
    host: ${APPLICATION_DOMAIN}
    to:
      kind: Service
      name: ${NAME}
- apiVersion: v1
  kind: ImageStream
  metadata:
    annotations:
      description: Keeps track of changes in the application image
    name: ${NAME}
- apiVersion: v1
  kind: BuildConfig
  metadata:
    annotations:
      description: Defines how to build the application
      template.alpha.openshift.io/wait-for-ready: "true"
    name: ${NAME}
  spec:
    output:
      to:
        kind: ImageStreamTag
        name: ${NAME}:latest
    source:
      contextDir: ${CONTEXT_DIR}
      git:
        ref: ${SOURCE_REPOSITORY_REF}
        uri: ${SOURCE_REPOSITORY_URL}
      type: Git
    strategy:
      sourceStrategy:
        from:
          kind: ImageStreamTag
          name: r-shiny-s2i:latest
          namespace: ${NAMESPACE}
      type: Source
    triggers:
    - type: ImageChange
    - type: ConfigChange
    - github:
        secret: ${GITHUB_WEBHOOK_SECRET}
      type: GitHub
    - generic:
        secret: ${GENERIC_WEBHOOK_SECRET}
      type: Generic
- apiVersion: v1
  kind: DeploymentConfig
  metadata:
    annotations:
      description: Defines how to deploy the application server
      template.alpha.openshift.io/wait-for-ready: "true"
    name: ${NAME}
  spec:
    replicas: 1
    selector:
      name: ${NAME}
    strategy:
      type: Rolling
    template:
      metadata:
        labels:
          name: ${NAME}
        name: ${NAME}
      spec:
        containers:
        - env: []
          image: ' '
          livenessProbe:
            httpGet:
              path: /
              port: 8080
            initialDelaySeconds: 30
            timeoutSeconds: 3
          name: s2i-r-shiny
          ports:
          - containerPort: 8080
          readinessProbe:
            httpGet:
              path: /
              port: 8080
            initialDelaySeconds: 3
            timeoutSeconds: 3
          resources:
            limits:
              memory: ${MEMORY_LIMIT}
    triggers:
    - imageChangeParams:
        automatic: true
        containerNames:
        - s2i-r-shiny
        from:
          kind: ImageStreamTag
          name: ${NAME}:latest
      type: ImageChange
    - type: ConfigChange
parameters:
- description: The name assigned to all of the frontend objects defined in this template.
  displayName: Name
  name: NAME
  required: true
  value: word-cloud
- description: The OpenShift Namespace where the ImageStream resides.
  displayName: Namespace
  name: NAMESPACE
  required: true
  value: openshift
- description: Maximum amount of memory the container can use.
  displayName: Memory Limit
  name: MEMORY_LIMIT
  required: true
  value: 512Mi
- description: The URL of the repository with your application source code.
  displayName: Git Repository URL
  name: SOURCE_REPOSITORY_URL
  required: true
  value: https://github.com/rstudio/shiny-examples.git
- description: Set this to a branch name, tag or other ref of your repository if you
    are not using the default branch.
  displayName: Git Reference
  name: SOURCE_REPOSITORY_REF
  value: master
- description: Set this to the relative path to your project if it is not in the root
    of your repository.
  displayName: Context Directory
  name: CONTEXT_DIR
  value: 082-word-cloud
- description: The exposed hostname that will route to the r shiny service, if left
    blank a value will be defaulted.
  displayName: Application Hostname
  name: APPLICATION_DOMAIN
- description: Github trigger secret.  A difficult to guess string encoded as part
    of the webhook URL.  Not encrypted.
  displayName: GitHub Webhook Secret
  from: '[a-zA-Z0-9]{40}'
  generate: expression
  name: GITHUB_WEBHOOK_SECRET
- description: A secret string used to configure the Generic webhook.
  displayName: Generic Webhook Secret
  from: '[a-zA-Z0-9]{40}'
  generate: expression
  name: GENERIC_WEBHOOK_SECRET
EOF
```

### Insides from the builder

Install app lication and dependencies with

```text
$ R -s -e "library(deplearning); depl_check()"
$ R -s -e "menu = function(choices, graphics = FALSE, title = NULL) { return(1) };  library(deplearning); depl_check()"
```

Run app with

```text
$ R -s -e 'library("shiny"); runApp()'
```

## Build app with builder image

```text
oc new-app r-shiny-s2i~https://github.com/rstudio/shiny-examples \
    --context-dir=082-word-cloud \
    --name=word-cloud \
    --strategy=source
oc expose svc/word-cloud
```

## Resources

* [https://www.r-bloggers.com/permanently-setting-the-cran-repository/](https://www.r-bloggers.com/permanently-setting-the-cran-repository/)
* [https://rdrr.io/github/MilesMcBain/deplearning/](https://rdrr.io/github/MilesMcBain/deplearning/)

## Playground

Dockerfile.playground:

```text
FROM docker-registry-default.ocp3.bohne.io/openshift/r-shiny-s2i:latest
COPY ./s2i/bin/ /usr/libexec/s2i

USER 1001

# Set the default port for applications built using this image
EXPOSE 8080

CMD ["/usr/libexec/s2i/usage"]
```

And build and run:

```text
docker pull docker-registry-default.ocp3.bohne.io/openshift/r-shiny-s2i:latest
docker build -t b -f Dockerfile.playground .
s2i build https://github.com/rstudio/shiny-examples b b-app --context-dir=027-absolutely-positioned-panels --loglevel=99
# Or by hand: docker run -ti --entrypoint bash -v $(pwd):/tmp/src b


docker run word-cloud
```

## Usefull deplay-all.sh
```bash
#!/usr/bin/env bash

LIST="001-hello
002-text
003-reactivity
004-mpg
005-sliders
006-tabsets
007-widgets
008-html
009-upload
010-download
011-timer
012-datatables
013-selectize
014-onflushed
015-layout-navbar
015-layout-sidebar
016-knitr-pdf
017-select-vs-selectize
018-datatable-options
019-mathjax
020-knit-html
021-selectize-plot
022-unicode-chinese
023-optgroup-server
024-optgroup-selectize
025-loop-ui
026-shiny-inline
027-absolutely-positioned-panels
028-actionbutton-demo
030-basic-datatable
032-client-data-and-query-string
033-conditionalpanel-demo
034-current-time
035-custom-input-bindings
036-custom-input-control
037-date-and-date-range
039-download-file
040-dynamic-clustering
041-dynamic-ui
047-image-output
048-including-html-text-and-markdown-files
049-isolate-demo
050-kmeans-example
051-movie-explorer
052-navbar-example
053-navlistpanel-example
054-nvd3-line-chart-output
055-observer-demo
057-plot-plus-three-columns
059-reactive-poll-and-file-reader
060-retirement-simulation
061-server-to-client-custom-messages
062-submitbutton-demo
063-superzip-example
064-telephones-by-region
065-update-input-demo
066-upload-file
067-vertical-layout
068-widget-action-button
069-widget-check-group
070-widget-checkbox
071-widget-date
072-widget-date-range
073-widget-file
074-widget-numeric
075-widget-radio
076-widget-select
077-widget-slider
078-widget-slider-range
079-widget-submit
080-widget-text
081-widgets-gallery
082-word-cloud
083-front-page
084-single-file
085-progress
086-bus-dashboard
087-crandash
088-action-pattern1
089-action-pattern2
090-action-pattern3
091-action-pattern4
092-action-pattern5
093-plot-interaction-basic
094-image-interaction-basic
095-plot-interaction-advanced
096-plot-interaction-article-1
097-plot-interaction-article-2
098-plot-interaction-article-3
099-plot-interaction-article-4
100-plot-interaction-article-5
101-plot-interaction-article-6
102-plot-interaction-article-7
103-plot-interaction-article-8
104-plot-interaction-select
105-plot-interaction-zoom
106-plot-interaction-exclude
107-events
108-module-output
109-render-table
110-error-sanitization
111-insert-ui
112-generate-report
113-bookmarking-url
114-modal-dialog
115-bookmarking-updatequerystring
116-notifications
117-shinythemes
118-highcharter-births
119-namespaced-conditionalpanel-demo
120-goog-index
121-async-timer
122-async-outputs
123-async-renderprint
124-async-download
125-async-req
126-async-ticks
127-async-flush
128-plot-dim-error
129-async-perf
130-output-null
131-renderplot-args
132-async-events
133-async-hold-inputs
134-async-hold-timers
135-bookmark-uioutput
136-plot-cache
137-plot-cache-key
138-icon-fontawesome
139-plot-brush-scaling
140-selectize-inputs
141-radiant
142-reactive-timer
143-async-plot-caching
144-colors
145-dt-replacedata
146-ames-explorer
147-websocket
148-addresourcepath-deleted
149-onRender
150-networkD3-sankey
151-reactr-input
152-set-reactivevalue
153-connection-header
154-index-html-server-r
155-index-html-app-r
156-subapps"

# LIST="079-widget-submit"

for i in $(echo $LIST) ; do
  CONTEXT_DIR=$i;
  NAME=$(echo $i | cut -d'-' -f2-)
  echo "----> Deploy $NAME"
  oc new-app --template=s2i-r-shiny-example \
    --param=CONTEXT_DIR=$CONTEXT_DIR \
    --param=NAME=$NAME
done;
```
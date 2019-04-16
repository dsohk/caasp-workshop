# SUSE CaaSP Workshop for Java Developers

In this workshop, we will introduce the methods to containerize your java application and explore how to run it in SUSE CaaSP.

## Exercise 1 - Basic Tools Verification

Print out the version of your tools. Make sure they are installed and configured properly in your PC.

```
java -version
mvn -version
docker version
kubectl version
helm version
```

* Java should be at least version 1.8
* Maven should be at least 3.x
* Docker is at least version 1.17
* kubectl is of version 1.10
* helm is of version 2.9.1

## Exercise 2 - Build a hello-world Springboot app

* Refer to the SpringBoot Starter Guide: https://spring.io/guides/
* Take this application as example: https://spring.io/guides/gs/rest-service/
* Examine the application structure
* Modify the Greeting message

Try run it locally
```
git clone https://github.com/spring-guides/gs-rest-service.git hello-world
cd hello-world/complete
mvn clean package
mvn springboot-run
```

Test against the service
```
curl localhost:8080/greeting
curl localhost:8080/greeting?name=Superman
```

Stop the mvn springboot-run (Ctrl+C) when finished testing

## Exercise 3 - Dockerize the hello-world Springboot app

Create the following `Dockerfile` and save it into hello-world/complete folder

```
FROM openjdk:8-alpine
COPY target/*.jar /app.jar

ENV JAVA_OPTS=""
ENV SERVER_PORT 8080
EXPOSE ${SERVER_PORT}
HEALTHCHECK --interval=10s --timeout=3s \
  CMD curl -v --fail http://localhost:${SERVER_PORT} || exit 1

ENTRYPOINT [ "sh", "-c", "java $JAVA_OPTS -Djava.security.egd=file:/dev/./urandom -jar /app.jar" ]
```

From the hello-world/complete folder

```
docker login
docker build -t dso814/hello-world:0.0.1 .
docker run -it -p 8080:8080 dso814/hello-world:0.0.1
docker push dso814/hello-world:0.0.1
```

## Exercise 4 - Package and deploy the hello-world app into SUSE CaaSP

Save the following content into hello-world-deployment.yaml so as to Create a deployment yaml manifest for kubernetes

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hello-world-deployment
  namespace: demoapp
  labels:
    app: hello-world
spec:
  replicas: 1
  selector:
    matchLabels:
      app: hello-world
  template:
    metadata:
      labels:
        app: hello-world
    spec:
      containers:
      - name: hello-world
        image: dso814/hello-world:0.0.1
        ports:
        - containerPort: 8080
```

```
apiVersion: v1
kind: Service
metadata:
  name: hello-world-service
  namespace: demoapp
  labels:
    app: hello-world
spec:
  selector:
    app: hello-world
  type: NodePort
  ports:
   - port: 8080
     nodePort: 31514
```

* Run `kubectl get po,deploy,svc -n demoapp` to check all the resources deployed into namespace demoapp
* Use `kubectl get po -n demoapp` to find out the node IP
* Run `curl http://<nodeIP>:<nodeport>/greeting` to test the hello-world API service
* Run `kubectl delete ns demoapp` to clean up the provisioned resources namespaced demoapp

## Exercise 5 - Package hello-world with helm

Create a new helm chart for hello-world app
```
mkdir chart
cd chart
helm create hello-world
cd hello-world
```

A structure of the helm chart is created.
```
├── charts
├── Chart.yaml
├── templates
│   ├── deployment.yaml
│   ├── _helpers.tpl
│   ├── ingress.yaml
│   ├── NOTES.txt
│   └── service.yaml
└── values.yaml
```

Modify the `Chart.yaml`, `values.yaml` and `templates/service.yaml`. See `ex5/chart/hello-world` folder for the changes.

Check if helm chart syntax is correct.
```
helm lint --strict hello-world
```

Package the hello-world application
```
helm package hello-world
```

Search if hello-world application is stored in local helm repository
```
helm search hello -l
```

Deploy the helm chart
```
$ helm install --name hello-world --namespace demoapp ./hello-world
NAME:   hello-world
LAST DEPLOYED: Tue Apr 16 07:03:28 2019
NAMESPACE: demoapp
STATUS: DEPLOYED

RESOURCES:
==> v1/Service
NAME         TYPE      CLUSTER-IP      EXTERNAL-IP  PORT(S)         AGE
hello-world  NodePort  172.24.230.250  <none>       8080:31514/TCP  2s

==> v1beta2/Deployment
NAME         DESIRED  CURRENT  UP-TO-DATE  AVAILABLE  AGE
hello-world  1        0        0           0          2s

==> v1/Pod(related)
NAME                         READY  STATUS   RESTARTS  AGE
hello-world-684cff9bd-h5w86  0/1    Pending  0         1s


NOTES:
1. Get the application URL by running these commands:
  export NODE_PORT=$(kubectl get --namespace demoapp -o jsonpath="{.spec.ports[0].nodePort}" services hello-world)
  export NODE_IP=$(kubectl get nodes --namespace demoapp -o jsonpath="{.items[0].status.addresses[0].address}")
  echo http://$NODE_IP:$NODE_PORT
```

Run `helm ls` to list all helm chart deployed on to your target cluster. `hello-world` should be listed at there now.
Run `helm status hello-world` to check deployment status.
Run `kubectl get pod -n demoapp` to check if the pods are ready.
Run `helm delete --purge hello-world` to delete the hello-world from the cluster.

## Exercise 6 - Upgrade the hello world application

* Copy the chart from ex5 folder to ex6
* Modify the versions in the chart (hint: Chart.yaml and values.yaml)
* Try use helm to deploy the latest version of the application

## Exercise 7 - Scale the hello world application

Scale the number of replica to 3 instances
```
kubectl scale deployments/hello-world --replicas=3 -n demoapp 
```

Checking:
```
kubectl get deploy -n demoapp
kubectl get pods -n demoapp
```

## Exercise 8 - Rolling update of hello world application

Rolling update of all instances to a newer version within a deployment set
```
kubectl set image deployments/hello-world -n demoapp hello-world=dso814/hello-world:0.0.1
```

Monitoring the update process
```
watch -n2 -c 'kubectl get po -n demoapp -o wide'
```



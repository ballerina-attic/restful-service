[![Build Status](https://travis-ci.org/pranavan15/restful-service.svg?branch=master)](https://travis-ci.org/pranavan15/restful-service)

# RESTful Service  
REST (REpresentational State Transfer) is an architectural style for developing web services. It defines a set of constraints and properties based on HTTP. 

> In this guide, you learn to build a comprehensive RESTful Web Service using Ballerina. 

This guide contains the following sections.

- [What you'll build](#what-youll-build)
- [Prerequisites](#prerequisites)
- [Implementation](#implementation)
- [Testing](#testing)
- [Deployment](#deployment)
- [Observability](#observability)

## What you’ll build 
To understand how you can build a RESTful web service using Ballerina, let’s consider a real-world use case of an order management scenario in an online retail application. The order management scenario is modeled as a RESTful web service; `order_mgt_service`,  which accepts different HTTP requests for order management tasks, such as creating, retrieving, updating, and deleting orders.
The following figure illustrates all the functionalities of the OrderMgt RESTful web service that we need to build. 

![RESTful Service](images/restful-service.svg "RESTful Service")

- **Create Order** : Use the HTTP POST message that contains the order details sent to the `http://xyz.retail.com/order` URL. The response from the service contains an `HTTP 201 Created` message with the location header pointing to the newly created `http://xyz.retail.com/order/<orderId>` resource. 
- **Retrieve Order** : Send an HTTP GET request to the appropriate URL, which includes the order ID. Example: `http://xyz.retail.com/order/<orderId>`.
- **Update Order** : Send an HTTP PUT request with the order details that need to be updated.
- **Delete Order** : An existing order can be deleted by sending an HTTP DELETE request to the specific URL. Example: `http://xyz.retail.com/order/<orderId>`. 

## Prerequisites
 
- [Ballerina Distribution](https://ballerina.io/learn/getting-started/)
- A Text Editor or an IDE 

### Optional requirements
- Ballerina IDE plugins ([IntelliJ IDEA](https://plugins.jetbrains.com/plugin/9520-ballerina), [VSCode](https://marketplace.visualstudio.com/items?itemName=WSO2.Ballerina), [Atom](https://atom.io/packages/language-ballerina))
- [Docker](https://docs.docker.com/engine/installation/)
- [Kubernetes](https://kubernetes.io/docs/setup/)

## Implementation

> If you want to skip the basics, download the git repository and move directly to the [Testing](#testing) section.

### Create the project structure

Ballerina is a complete programming language that supports custom project structures. Use the following package structure for this guide.
```
restful-service
 └── guide
      └── restful_service
           ├── order_mgt_service.bal
  	   └── tests
	        └── order_mgt_service_test.bal
```

- Create the above directories on your local machine. Additionally, create an empty `.bal` file too.

- Open the terminal, navigate to `restful-service/guide`, and run the Ballerina project initializing toolkit.
```bash
   $ ballerina init
```

### Developing the RESTful web service

- Let's start implementing the Ballerina service; `order_mgt_service`, which is the RESTful service that serves the order management requests. The `order_mgt_service` has multiple resources and each resource is dedicated to a specific order management functionality.

- Add the content given below to your Ballerina service. The code segment includes the implementation of the service and the resource skeleton of the `order_mgt_service`. 
There is a dedicated resource for each order management operation. You can implement the order management operation logic inside each resource. 

##### Skeleton code for order_mgt_service.bal
```ballerina
import ballerina/http;

endpoint http:Listener listener {
    port:9090
};

// Order management is done using an in-memory map.
// Add sample orders to 'ordersMap' at startup.
map<json> ordersMap;

// RESTful service.
@http:ServiceConfig { basePath: "/ordermgt" }
service<http:Service> orderMgt bind listener {

    // Resource that handles the HTTP GET requests, which are directed to a specific
    // order using the '/orders/<orderID> path.
    @http:ResourceConfig {
        methods: ["GET"],
        path: "/order/{orderId}"
    }
    findOrder(endpoint client, http:Request req, string orderId) {
        // Implementation
    }

    // Resource that handles the HTTP POST requests, which are directed to the 
    // '/orders' path to create a new order.
    @http:ResourceConfig {
        methods: ["POST"],
        path: "/order"
    }
    addOrder(endpoint client, http:Request req) {
        // Implementation
    }

    // Resource that handles the HTTP PUT requests, which are directed to the 
    // '/orders' path to update an existing order.
    @http:ResourceConfig {
        methods: ["PUT"],
        path: "/order/{orderId}"
    }
    updateOrder(endpoint client, http:Request req, string orderId) {
        // Implementation
    }

    // Resource that handles the HTTP DELETE requests, which are directed to the 
    // '/orders/<orderId>' path to delete an existing order.
    @http:ResourceConfig {
        methods: ["DELETE"],
        path: "/order/{orderId}"
    }
    cancelOrder(endpoint client, http:Request req, string orderId) {
        // Implementation
    }
}
```

- You can implement the business logic of each resource as per your requirement. For simplicity, we use an in-memory map to record all the order details. The full source code of the `order_mgt_service` is shown below. In addition to the order processing logic, we control some of the HTTP status codes and headers.  


##### order_mgt_service.bal
```ballerina
import ballerina/http;

endpoint http:Listener listener {
    port:9090
};

// Order management is done using an in-memory map.
// Add sample orders to 'ordersMap' at startup.
map<json> ordersMap;

// RESTful service.
@http:ServiceConfig { basePath: "/ordermgt" }
service<http:Service> orderMgt bind listener {

    // Resource that handles the HTTP GET requests, which are directed to a specific
    // order using the '/orders/<orderID> path.
    @http:ResourceConfig {
        methods: ["GET"],
        path: "/order/{orderId}"
    }
    findOrder(endpoint client, http:Request req, string orderId) {
        // Find the requested order from the map and retrieve it in JSON format.
        json? payload = ordersMap[orderId];
        http:Response response;
        if (payload == null) {
            payload = "Order : " + orderId + " cannot be found.";
        }

        // Set the JSON payload in the outgoing response message.
        response.setJsonPayload(payload);

        // Send response to the client.
        _ = client->respond(response);
    }

    // Resource that handles the HTTP POST requests, which are directed to the 
    // '/orders' path to create a new order.
    @http:ResourceConfig {
        methods: ["POST"],
        path: "/order"
    }
    addOrder(endpoint client, http:Request req) {
        json orderReq = check req.getJsonPayload();
        string orderId = orderReq.Order.ID.toString();
        ordersMap[orderId] = orderReq;

        // Create response message.
        json payload = { status: "Order Created.", orderId: orderId };
        http:Response response;
        response.setJsonPayload(payload);

        // Set the 201 Created status code in the response message.
        response.statusCode = 201;
        // Set the 'Location' header in the response message.
        // This can be used by the client to locate the newly added order.
        response.setHeader("Location", "http://localhost:9090/ordermgt/order/" +
                orderId);

        // Send a response to the client.
        _ = client->respond(response);
    }

    // Resource that handles the HTTP PUT requests, which are directed to the 
    // '/orders' path to update an existing order.
    @http:ResourceConfig {
        methods: ["PUT"],
        path: "/order/{orderId}"
    }
    updateOrder(endpoint client, http:Request req, string orderId) {
        json updatedOrder = check req.getJsonPayload();

        // Find the order that needs to be updated and retrieve it in the JSON format.
        json existingOrder = ordersMap[orderId];

        // Update the existing order with the attributes of the 'updateOrder'.
        if (existingOrder != null) {
            existingOrder.Order.Name = updatedOrder.Order.Name;
            existingOrder.Order.Description = updatedOrder.Order.Description;
            ordersMap[orderId] = existingOrder;
        } else {
            existingOrder = "Order : " + orderId + " cannot be found.";
        }

        http:Response response;
        // Set the JSON payload to the outgoing response message.
        response.setJsonPayload(existingOrder);
        // Send the response to the client.
        _ = client->respond(response);
    }

    // Resource that handles the HTTP DELETE requests, which are directed to the 
    // '/orders/<orderId>' path to delete an existing Order.
    @http:ResourceConfig {
        methods: ["DELETE"],
        path: "/order/{orderId}"
    }
    cancelOrder(endpoint client, http:Request req, string orderId) {
        http:Response response;
        // Remove the requested order from the map.
        _ = ordersMap.remove(orderId);

        json payload = "Order : " + orderId + " removed.";
        // Set a generated payload with the order status.
        response.setJsonPayload(payload);

        // Send a response to the client.
        _ = client->respond(response);
    }
}
```

- With that we have completed developing the `order_mgt_service`. 


## Testing 

### Invoking the RESTful service 

Run the RESTful service that you developed above in your local environment. Open your terminal, navigate to `restful-service/guide`, and execute the following command.
```
$ ballerina run restful_service
```

You can test the functionality of the OrderMgt RESTFul service by sending an HTTP request for each order management operation. For example, we use the following cURL commands to test each operation of the `order_mgt_service`. 

**Create Order** 
```
curl -v -X POST -d \
'{ "Order": { "ID": "100500", "Name": "XYZ", "Description": "Sample order."}}' \
"http://localhost:9090/ordermgt/order" -H "Content-Type:application/json"

Output :  
< HTTP/1.1 201 Created
< Content-Type: application/json
< Location: http://localhost:9090/ordermgt/order/100500
< Transfer-Encoding: chunked
< Server: wso2-http-transport

{"status":"Order Created.","orderId":"100500"} 
```

**Retrieve Order** 
```
curl "http://localhost:9090/ordermgt/order/100500" 

Output : 
{"Order":{"ID":"100500","Name":"XYZ","Description":"Sample order."}}
```

**Update Order** 
```
curl -X PUT -d '{ "Order": {"Name": "XYZ", "Description": "Updated order."}}' \
"http://localhost:9090/ordermgt/order/100500" -H "Content-Type:application/json"

Output: 
{"Order":{"ID":"100500","Name":"XYZ","Description":"Updated order."}}
```

**Cancel Order** 
```
curl -X DELETE "http://localhost:9090/ordermgt/order/100500"

Output:
"Order : 100500 removed."
```

### Writing unit tests 

In Ballerina, the unit test cases should be in the 'tests' folder. Follow the conventions given below to wrtie the test functions.

- Test functions should be annotated with `@test:Config`. See the example given below.
```ballerina
   @test:Config
   function testResourceAddOrder() {
```
  
This guide contains unit test cases for each method available in the 'order_mgt_service'. 

To run the unit tests, open your terminal, navigate to `restful-service/guide`, and run the following command.
```bash
$ ballerina test
```

To check the implementation of the test file, see the [order_mgt_service_test.bal](https://github.com/ballerina-guides/restful-service/blob/master/guide/restful_service/tests/order_mgt_service_test.bal).


## Deployment

Once you are done with the development, deploy the service using any of the following methods. 

### Deploying locally

- As the first step, build a Ballerina executable archive (.balx) of the service that we developed above, using the following command. It points to the directory of the service and creates an executable binary out of it. Navigate to `restful-service/guide` and run the following command. 
```
   $ ballerina build restful_service
```

- Once the `restful_service.balx` is created inside the target folder, you can run that with the following command. 
```
   $ ballerina run target/restful_service.balx
```

- The successful execution of the service prints the following output. 
```
   ballerina: initiating service(s) in 'target/restful_service.balx'
   ballerina: started HTTP/WS endpoint 0.0.0.0:9090
```

### Deploying on Docker

You can run the service that we developed above as a Docker container. The Ballerina platform includes a [Ballerina_Docker_Extension](https://github.com/ballerinax/docker), which offers native support to run ballerina programs on containers by putting the corresponding Docker annotations on the service code. 

- Import `ballerinax/docker` and use the `@docker:Config` annotation in the `order_mgt_service` to generate the Docker image during build time. Take a look at the sample implementation given below.

##### order_mgt_service.bal
```ballerina
import ballerina/http;
import ballerinax/docker;

@docker:Config {
    registry:"ballerina.guides.io",
    name:"restful_service",
    tag:"v1.0"
}

@docker:Expose{}
endpoint http:Listener listener {
    port:9090
};

// Order management is done using an in-memory map.
// Add sample orders to 'ordersMap' at startup.
map<json> ordersMap;

// RESTful service.
@http:ServiceConfig { basePath: "/ordermgt" }
service<http:Service> orderMgt bind listener {
``` 

- The `@docker:Config` annotation is used to provide the basic Docker image configurations for the sample. `@docker:Expose {}` is used to expose the port. 

- Now, build a Ballerina executable archive (.balx) of the service, using the following command. It points to the service file that you developed above and creates an executable binary out of it. Further, run the command to create the Docker image using the Docker annotations that you configured above. Navigate to `restful-service/guide` and run the following command.  
```
   $ ballerina build restful_service

   Run the following command to start docker container: 
   docker run -d -p 9090:9090 ballerina.guides.io/restful_service:v1.0
```

- Once you successfully build the Docker image, run it using the `docker run` command that is shown below.  
```   
   $ docker run -d -p 9090:9090 ballerina.guides.io/restful_service:v1.0
```

Here, you run the Docker image with the flag `-p <host_port>:<container_port>` so that we  use  the host-port 9090 and the container-port 9090. Therefore, you can access the service through the host port. 

- Use `$ docker ps` to verify that the Docker container is running. The status of the Docker container should be shown as `Up`. 
- You can access the service using the same curl commands that we have used above. 
```
   curl -v -X POST -d \
   '{ "Order": { "ID": "100500", "Name": "XYZ", "Description": "Sample order."}}' \
   "http://localhost:9090/ordermgt/order" -H "Content-Type:application/json"    
```

### Deploying on Kubernetes

- Run the service that you developed above, on Kubernetes. The Ballerina language offers native support to run Ballerina programs on Kubernetes. The Kubernetes annotations can be included as part of your service code. It also takes care of creating the docker images. Therefore, you don't need to explicitly create docker images prior to deploying it on Kubernetes. See [Ballerina_Kubernetes_Extension](https://github.com/ballerinax/kubernetes) for more details and samples on the Kubernetes deployment with Ballerina. You can also find details on using Minikube to deploy Ballerina programs. 

- Let's see how we can deploy `order_mgt_service` on Kubernetes.

- First, you need to import `ballerinax/kubernetes` and use `@kubernetes` annotations as shown below to enable the Kubernetes deployment for the service. 

##### order_mgt_service.bal

```ballerina
import ballerina/http;
import ballerinax/kubernetes;

@kubernetes:Ingress {
    hostname:"ballerina.guides.io",
    name:"ballerina-guides-restful-service",
    path:"/"
}

@kubernetes:Service {
    serviceType:"NodePort",
    name:"ballerina-guides-restful-service"
}

@kubernetes:Deployment {
    image:"ballerina.guides.io/restful_service:v1.0",
    name:"ballerina-guides-restful-service"
}

endpoint http:Listener listener {
    port:9090
};

// Order management is done using an in-memory map.
// Add some sample orders to 'ordersMap' at startup.
map<json> ordersMap;

// RESTful service.
@http:ServiceConfig { basePath: "/ordermgt" }
service<http:Service> orderMgt bind listener {
``` 

- `@kubernetes:Deployment` is used to specify the name of the Docker image, which is created as part of building this service. 
- `@kubernetes:Service` creates a Kubernetes service, which exposes the Ballerina service that is running on a Pod.  
- Additionally, `@kubernetes:Ingress` is used as an external interface to access your service (with the path `/` and host name `ballerina.guides.io`)

- Now, build a Ballerina executable archive (.balx) of the service, using the following command. It points to the service file that you developed above and creates an executable binary out of it. 
This also creates the corresponding Docker image and the Kubernetes artifacts using the Kubernetes annotations that you configured above.
  
```
   $ ballerina build restful_service
  
   Run the following command to deploy Kubernetes artifacts:  
   kubectl apply -f ./target/restful_service/kubernetes
```

- Use `$ docker images` to verify that the Docker image specified in `@kubernetes:Deployment` is created. 
- The Kubernetes artifacts related to the service are generated in `./target/restful_service/kubernetes`. 
- Now, you can create the Kubernetes deployment using:

```
   $ kubectl apply -f ./target/restful_service/kubernetes 
 
   deployment.extensions "ballerina-guides-restful-service" created
   ingress.extensions "ballerina-guides-restful-service" created
   service "ballerina-guides-restful-service" created
```

- Verify that the Kubernetes deployment, service, and ingress are running properly, using the following Kubernetes commands.

```
   $ kubectl get service
   $ kubectl get deploy
   $ kubectl get pods
   $ kubectl get ingress
```

- If everything deploys successfully, you can invoke the service either via the Node port or ingress. 

Node Port:
 
```
   curl -v -X POST -d \
   '{ "Order": { "ID": "100500", "Name": "XYZ", "Description": "Sample order."}}' \
   "http://localhost:<Node_Port>/ordermgt/order" -H "Content-Type:application/json"  
```

Ingress:

Add the `/etc/hosts` entry to match the hostname. 
``` 
127.0.0.1 ballerina.guides.io
```

Access the service. 
``` 
curl -v -X POST -d \
'{ "Order": { "ID": "100500", "Name": "XYZ", "Description": "Sample order."}}' \
"http://ballerina.guides.io/ordermgt/order" -H "Content-Type:application/json" 
```

## Observability 
Ballerina supports observability. This means that you can easily observe your services, resources, etc.
However, observability is disabled by default. Add the following configurations to the `ballerina.conf` file in `restful-service/guide/` to enable it.

```ballerina
[b7a.observability]

[b7a.observability.metrics]
# Flag to enable Metrics
enabled=true

[b7a.observability.tracing]
# Flag to enable Tracing
enabled=true
```

NOTE: The configurations listed above are the minimum configurations needed to enable tracing and metrics. These load the default values of metrics and tracing.

### Tracing 

You can monitor Ballerina services using the inbuilt tracing capabilities of Ballerina. Let's use [Jaeger](https://github.com/jaegertracing/jaeger) as the distributed tracing system.
Follow the steps given below to use tracing with Ballerina.

- Add the following configurations for tracing. Note that these configurations are optional if you already have the basic configurations in the `ballerina.conf` as described above.
```
   [b7a.observability]

   [b7a.observability.tracing]
   enabled=true
   name="jaeger"

   [b7a.observability.tracing.jaeger]
   reporter.hostname="localhost"
   reporter.port=5775
   sampler.param=1.0
   sampler.type="const"
   reporter.flush.interval.ms=2000
   reporter.log.spans=true
   reporter.max.buffer.spans=1000
```

- Run the Jaeger Docker image using the following command.
```bash
   $ docker run -d -p5775:5775/udp -p6831:6831/udp -p6832:6832/udp -p5778:5778 -p16686:16686 \
   -p14268:14268 jaegertracing/all-in-one:latest
```

- Navigate to `restful-service/guide` and run the restful-service using the following command. 
```
   $ ballerina run restful_service/
```

- Observe the tracing via the Jaeger UI using following URL.
```
   http://localhost:16686
```

### Metrics
Metrics and alerts are built-in with ballerina. Let's use Prometheus as the monitoring tool.
Follow the steps given below to set up Prometheus and view the metrics of the Ballerina restful service.

- You can add the following configurations for metrics. Note that these configurations are optional if you already have the basic configuration in the `ballerina.conf` as described under the `Observability` section.

```ballerina
   [b7a.observability.metrics]
   enabled=true
   provider="micrometer"

   [b7a.observability.metrics.micrometer]
   registry.name="prometheus"

   [b7a.observability.metrics.prometheus]
   port=9700
   hostname="0.0.0.0"
   descriptions=false
   step="PT1M"
```

- Create a file named `prometheus.yml` inside the `/tmp/` location. Add the configurations given below to the `prometheus.yml` file.
```
   global:
     scrape_interval:     15s
     evaluation_interval: 15s

   scrape_configs:
     - job_name: prometheus
       static_configs:
         - targets: ['172.17.0.1:9797']
```

   NOTE : Replace `172.17.0.1` if your local Docker IP differs from `172.17.0.1`
   
- Run the Prometheus Docker image using the following command.
```
   $ docker run -p 19090:9090 -v /tmp/prometheus.yml:/etc/prometheus/prometheus.yml \
   prom/prometheus
```
   
- Access Prometheus using the following URL.
```
   http://localhost:19090/
```

NOTE:  By default, Ballerina has the following metrics of the HTTP server connector. Enter the following in the Prometheus UI.
-  http_requests_total
-  http_response_time


### Logging

Ballerina has a log package to manage the logs. You can import the `ballerina/log` package and start logging. The following section describes how to search, analyze, and visualize logs in real time using Elastic Stack.

- Navigate to `restful-service/guide` and start the Ballerina Service.
```
   $ nohup ballerina run restful_service/ &>> ballerina.log&
```
   NOTE: This writes the console log to the `ballerina.log` file in the `restful-service/guide` directory.

- Start Elasticsearch using the following command.
```
   $ docker run -p 9200:9200 -p 9300:9300 -it -h elasticsearch --name \
   elasticsearch docker.elastic.co/elasticsearch/elasticsearch:6.2.2 
```

   NOTE: Linux users might need to run `sudo sysctl -w vm.max_map_count=262144` to increase the `vm.max_map_count` 
   
- Start the Kibana plugin to visualize the data with Elasticsearch.
```
   $ docker run -p 5601:5601 -h kibana --name kibana --link \
   elasticsearch:elasticsearch docker.elastic.co/kibana/kibana:6.2.2     
```

- Configure logstash to format the ballerina logs.

i) Create a file named `logstash.conf` with the following content.
```
input {  
 beats{ 
     port => 5044 
 }  
}

filter {  
 grok{  
     match => { 
	 "message" => "%{TIMESTAMP_ISO8601:date}%{SPACE}%{WORD:logLevel}%{SPACE}
	 \[%{GREEDYDATA:package}\]%{SPACE}\-%{SPACE}%{GREEDYDATA:logMessage}"
     }  
 }  
}   

output {  
 elasticsearch{  
     hosts => "elasticsearch:9200"  
     index => "store"  
     document_type => "store_logs"  
 }  
}  
```

ii) Save `logstash.conf` inside a directory named `{SAMPLE_ROOT}\pipeline`.
     
iii) Start the logstash container and replace `{SAMPLE_ROOT}` with your directory name.
     
```
$ docker run -h logstash --name logstash --link elasticsearch:elasticsearch \
-it --rm -v ~/{SAMPLE_ROOT}/pipeline:/usr/share/logstash/pipeline/ \
-p 5044:5044 docker.elastic.co/logstash/logstash:6.2.2
```
  
 - Configure filebeat to ship the ballerina logs.
    
i) Create a file named `filebeat.yml` with the following content.
```
filebeat.prospectors:
- type: log
  paths:
    - /usr/share/filebeat/ballerina.log
output.logstash:
  hosts: ["logstash:5044"]  
```
NOTE : Modify the ownership of `filebeat.yml` file using `$chmod go-w filebeat.yml`.

ii) Save `filebeat.yml` inside a directory named `{SAMPLE_ROOT}\filebeat`.  
        
iii) Start the logstash container and replace `{SAMPLE_ROOT}` with your directory name.
     
```
$ docker run -v {SAMPLE_ROOT}/filebeat/filebeat.yml:/usr/share/filebeat/filebeat.yml \
-v {SAMPLE_ROOT}/guide.restful_service/restful_service/ballerina.log:/usr/share\
/filebeat/ballerina.log --link logstash:logstash docker.elastic.co/beats/filebeat:6.2.2
```
 
 - Access Kibana to visualize the logs using the following URL.
```
   http://localhost:5601 
```
  
 

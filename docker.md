#** Lab 3: Deploy a Docker Image **

###** Background: Containers and Pods **

Before we start digging in we need to understand how containers and *Pods* are
related. Given the morning sessions where we discussed the OpenShift platform
and how it uses containers and *Pods*, we will not be covering the background on
these technologies in this lab.  Instead, we will dive right in and start using
them.

In OpenShift, the smallest deployable unit is a *Pod*. A *Pod* is a group of one or
more Docker containers deployed together and guaranteed to be on the same host.
From the doc:

    Each pod has its own IP address, therefore owning its entire port space, and
    containers within pods can share storage. Pods can be "tagged" with one or
    more labels, which are then used to select and manage groups of pods in a
    single operation.

*Pods* can contain multiple Docker instances. The general idea is for a Pod to
contain a "server" and any auxiliary services you want to run along with that
server. Examples of containers you might put in a *Pod* are, an Apache HTTPD
server, a log analyzer, and a file service to help manage uploaded files.

Let's look at the *Pod*s that were deployed as part of the *smoke* application in
the *smoke* Project.

````
$ oc get pods
````

You should see output similar to the following:

````
NAME            READY     STATUS      RESTARTS   AGE
smoke-1-build   0/1       Completed   0          2d
smoke-1-eivfk   1/1       Running     0          5m
smoke-1-ufae4   1/1       Running     1          2d
````

The above output lists all of the *Pod*s in the current Project, including the *Pod*
name, state, restarts, and uptime for the *Pod*.  Once you have a *Pod*'s name, you
can get more information about the *Pod*'s using the *oc get* command.  To make
the output readable, I suggest changing the output type to *JSON* using the
following syntax:

**Note:** Make sure you use the correct *Pod* name from your output.

````
$  oc get pod smoke-1-eivfk -o json
````

You should see something like the following output (which is have truncated due
to space considerations of this workshop manual):

````
{
    "kind": "Pod",
    "apiVersion": "v1",
    "metadata": {
       "name": "smoke-1-eivfk",
       "generateName": "smoke-1-",
       "namespace": "smoke",
       "selfLink": "/api/v1/namespaces/smoke/pods/smoke-1-eivfk",
       "uid": "05603d07-36cf-11e6-8232-525400b263eb",
       "resourceVersion": "10437",
       "creationTimestamp": "2016-06-20T10:09:05Z",
       "labels": {
           "app": "smoke",
           "deployment": "smoke-1",
           "deploymentconfig": "smoke"
       },
       ...............
}
````

###** Exercise 1: Deploying your first Image **

Let's start by doing the simplest thing possible - get a plain old Docker image
to run inside of OpenShift. This is incredibly simple to do. We are going to use
the Kubernetes Guestbook application
(https://registry.hub.Docker.com/u/kubernetes/guestbook/) for this example.

The first thing we want to do is create a new *Project* called `guestbook`.
Remember that Projects group resources together.

````
$ oc new-project guestbook
````

The *new-project* command will automatically switch you to use that *Project*. You
will see something like the following:

````
Now using project "guestbook" on server "https://10.2.2.2:8443".

You can add applications to this project with the 'new-app' command. For example, try:

   $ oc new-app centos/ruby-22-centos7~https://github.com/openshift/ruby-hello-world.git

to build a new hello-world application in Ruby.
````

To see all the Projects you have access to, you can simply use `oc get`.

````
$ oc get projects
````

You should see a list like the following:

````
NAME        DISPLAY NAME   STATUS
guestbook                  Active
smoke       Smoke Test     Active
````

With the new *Project* created, in order to tell OpenShift to define and run the
Docker image, you can simply execute the following command:

````
$ oc new-app kubernetes/guestbook
````

You will see output similar to the following:

````
--> Found Docker image 4305190 (20 months old) from Docker Hub for "kubernetes/guestbook"

    * An image stream will be created as "guestbook:latest" that will track this image
    * This image will be deployed in deployment config "guestbook"
    * Port 3000/tcp will be load balanced by service "guestbook"
       * Other containers can access this service through the hostname "guestbook"
    * WARNING: Image "guestbook" runs as the 'root' user which may not be permitted by your cluster administrator

--> Creating resources with label app=guestbook ...
    imagestream "guestbook" created
    deploymentconfig "guestbook" created
    service "guestbook" created
--> Success
    Run 'oc status' to view your app.
````

Pretty easy, huh?

This may take a while to complete. Each OpenShift node has to pull (download)
the Docker image for kubernetes/guestbook from the Docker hub if it does not
already have it locally. You can check on the status of the image download and
deployment by:

1. Going into the web console
1. Select Project `guestbook`
1. Select *Browse*
1. Select *Pods*

Under status you might see *Pending* rather than *Running*.

You can also use the `oc` command line tool to watch for changes in pods:

````
$ oc get pods -w
````

To exit, hit `Control+C` (`^c`).

###** Background: A Little About the Docker Daemon **

Whenever OpenShift asks the node's Docker daemon to run an image, the Docker
daemon will check to make sure it has the right "version" of the image to run.
If it doesn't, it will pull it from the specified registry.

There are a number of ways to customize this behavior. They are documented in
[specifying an
image](https://docs.openshift.org/latest/dev_guide/new_app.html#specifying-an-image)
as well as [image pull
policy](https://docs.openshift.org/latest/dev_guide/managing_images.html#image-pull-policy).

WINNING! These few commands are the only ones you need to run to get a "vanilla"
Docker image deployed on OpenShift. This should work with any Docker image
that follows best practices, such as defining an EXPOSE port, not running as the
*root user* or specific user name, and a single non-exiting CMD to execute on start.

**Note:** It is important to understand that, for security reasons, OpenShift 
does not allow the deployment of Docker images that run as *root* by default.
If you want or need to allow OpenShift users to deploy Docker images that do
expect to run as root (or any specific user), a small configuration change is
needed. You can learn more about the [Docker
guidelines](https://docs.openshift.org/latest/creating_images/guidelines.html)
for OpenShift, or you can look at the section on [enabling images to run with
a USER in the
dockerfile](https://docs.openshift.org/latest/admin_guide/manage_scc.html#enable-images-to-run-with-user-in-the-dockerfile).

**Note:** In the VM used for this labs ([All-in-one Origin VM](http://openshift.org/vm)) deploying applications as root is enabled by default.

####** Background: Services **

You may be wondering how you can access this application. There was a *Service*
that was created, but *Service*s are only used inside OpenShift - they are not
exposed to the outside world by default. Don't worry though, we will cover that
later in this lab.

You can see that when we ran the `new-app` command, OpenShift actually created
several resources behind the scenes in order to handle deploying this Docker
image. `new-app` created a *Service*, which maps to a set of *Pods* (via *Labels* and
*Selectors*). *Services* are assigned an IP address and port pair that, when
accessed, balance across the appropriate back end (*Pods*).

*Services* provide a convenient abstraction layer inside OpenShift to find a
group of like *Pods*. They also act as an internal proxy/load balancer between
those *Pods* and anything else that needs to access them from inside the OpenShift
environment. For example, if you needed more Guestbook servers to handle the
load, you could spin up more *Pods*. OpenShift automatically maps them as
endpoints to the *Service*, and the incoming requests would not notice anything
different except that the *Service* was now doing a better job handling the
requests.

There is a lot more information about
[Services](https://docs.openshift.org/latest/architecture/core_concepts/pods_and_services.html#services),
including the YAML format to make one by hand, in the official documentation.

Now that we understand the basics of what a *Service* is, let's take a look at the
*Service* that was created for the kubernetes/guestbook image that we just
deployed.  In order to view the *Services* defined in your Project, enter in the
following command:

````
$ oc get services
````

You should see output similar to the following:

````
NAME        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
guestbook   172.30.244.132   <none>        3000/TCP   12m
````

In the above output, we can see that we have a *Service* named `guestbook` with an
IP/Port combination of 172.30.244.132/3000. Your IP address may be different, as
each *Service* receives a unique IP address upon creation. *Service* IPs never
change for the life of the *Service*.

You can also get more detailed information about a *Service* by using the
following command to display the data in JSON:

````
$ oc get service guestbook -o json
````

You should see output similar to the following:

````
{
    "kind": "Service",
    "apiVersion": "v1",
    "metadata": {
        "name": "guestbook",
        "namespace": "guestbook",
        "selfLink": "/api/v1/namespaces/guestbook/services/guestbook",
        "uid": "acc7d356-36d0-11e6-8232-525400b263eb",
        "resourceVersion": "10703",
        "creationTimestamp": "2016-06-20T10:20:56Z",
        "labels": {
            "app": "guestbook"
        },
        "annotations": {
            "openshift.io/generated-by": "OpenShiftNewApp"
        }
    },
    "spec": {
        "ports": [
            {
                "name": "3000-tcp",
                "protocol": "TCP",
                "port": 3000,
                "targetPort": 3000
            }
        ],
        "selector": {
            "app": "guestbook",
            "deploymentconfig": "guestbook"
        },
        "portalIP": "172.30.244.132",
        "clusterIP": "172.30.244.132",
        "type": "ClusterIP",
        "sessionAffinity": "None"
    },
    "status": {
        "loadBalancer": {}
    }
}
````

Take note of the `selector` stanza. Remember it.

It is also of interest to view the JSON of the *Pod* to understand how OpenShift
wires components together.  For example, run the following command to get the
name of your `guestbook` Pod:

````
$ oc get pods
````

You should see output similar to the following:

````
NAME                READY     STATUS    RESTARTS   AGE
guestbook-1-e83hb   1/1       Running   0          24m
````

Now you can view the detailed data for your *Pod* with the following command:

````
$ oc get pod guestbook-1-e83hb -o json
````

Under the `metadata` section you should see the following:

````
"labels": {
   "app": "guestbook",
   "deployment": "guestbook-1",
   "deploymentconfig": "guestbook"
},
````

* The *Service* has `selector` stanza that refers to `app=guestbook,deploymentconfig=guestbook`.
* The *Pod* has multiple *Labels*:
    * `deploymentconfig=guestbook`
    * `app=guestbook`

*Labels* are just key/value pairs. Any *Pod* in this *Project* that has a *Label* that
matches the *Selector* will be associated with the *Service*. To see this in
action, issue the following command:

````
$ oc describe service guestbook
````

You should see the following output:

````
Name:			guestbook
Namespace:		guestbook
Labels:			app=guestbook
Selector:		app=guestbook,deploymentconfig=guestbook
Type:			ClusterIP
IP:			172.30.244.132
Port:			3000-tcp	3000/TCP
Endpoints:		172.17.0.6:3000
Session Affinity:	None
No events.
````

You may be wondering why only one end point is listed. That is because there is
only one `guestbook` *Pod* running.  In the next lab, we will learn how to scale
an application, at which point you will be able to see multiple endpoints
associated with the `guestbook` *Service*.

**[End of Lab 3](/)**

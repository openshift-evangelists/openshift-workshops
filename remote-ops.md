#** Lab 5: Remote Operations **

###** Background **

Containers are treated as immutable infrastructure and therefore it is generally
not recommended to modify the content of a container through SSH or running custom
commands inside the container. Nevertheless, in some use-cases such as debugging
an application it might be beneficial to get into a container and inspect the
application.

####**Exercise: Remote Shell Session to a Container**

OpenShift allows establishing remote shell sessions to a container without the need
to run an SSH service inside each container. In order to SSH into a container, you
can use the *oc rsh* command. First get the list of available pods:

````
$ oc get pods
````

You should an output similar to the following:

````
NAME                READY     STATUS    RESTARTS   AGE
guestbook-1-e83hb   1/1       Running   0          44m
````

Now you can establish a remote shell session into the pod by using the pod name:

````
$ oc rsh guestbook-1-oc7ey
````

You would see the following output:

````
$oc rsh guestbook-1-e83hb


BusyBox v1.21.1 (Ubuntu 1:1.21.0-1ubuntu1) built-in shell (ash)
Enter 'help' for a list of built-in commands.

/app #
````

The default shell used by *oc rsh* is */bin/sh*. If the deployed container does
not have *sh* installed and uses another shell, (e.g. *A Shell*) the shell command
can be specified after the pod name in the issued command.

Run the following command to list the static files for the guestbook application
within the container:

````
$ ls public/

index.html  script.js   style.css
````

####**Exercise: Execute a Command in a Container**

In addition to remote shell, it is also possible to run a command remotely on an
already running container using the *oc exec* command.

In order the get the list of files in the *public* directory of the container,
run the following:

````
$ oc exec guestbook-1-e83hb ls public

index.html
script.js
style.css
````

You can also specify the shell commands to run directly with the *oc rsh* command:

````
$ oc rsh guestbook-1-e83hb ls public

index.html  script.js   style.css
````

**[End of Lab 5](/)**

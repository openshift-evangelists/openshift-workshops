# OpenShift workshop builder

## Deploying

Deploying on OpenShift is very simple, use the Ruby s2i builder and you are 
(almost ready to go)

```
oc new-app https://github.com/openshift-evangelists/openshift-workshops.git
```

## Adding labs

In the terminology of this app `lab` is a workshop or some other kind of event. 
All events are configured through YAML files in `labs` directory. Simply create 
a new file and add required information, e.g. `labs/test.yml`

```
name: Testing workshop
logo: test.png
vars:
  CLUSTER_NAME: "10.2.2.2"
  CLUSTER_PORT: "8443"
  USER_NAME: "dev"
  USER_PASSWORD: "dev"
```

defines new lab with id `test` and display name `Testing workshop`. It also 
defines variables that are then substitued in the content itself. Variables are
set either in the config files or using environment variables. Environment
variables take precedence over variables in config file.

Lab can have a logo, it is displayed next to the lab content. In the example above
the logo file name is `test.png` and logos are always in `public/logos/` directory.

By default all modules are added to the workshops. In case you want just a 
subset of the workshops, add `activate` section to the `modules` section of 
your lab and list the ids of modules you want to use.

```
name: Testing workshop
modules:
  activate:
    - environment
```

With this configuration, there will be only one module in the lab. 

Modules may have multiple revisions. In case you want to specific revision,
add `revisions` section to the `modules` section and specify revision per module.

```
name: Testing workshop
modules:
  revisions:
    codechanges: <revision_name>
```

## Modules

Modules are content sections that you go through during your workshop and are 
configured in the `config/modules.yml` file. Most of the time you should not need to 
change this file, but in case you want to change the structure of your lab, you 
will need to know the ids of the modules you want ot use, and those are 
configured in this file. The content files itself live in `modules/` directory.

```
environment:
  name: Lab Environment Overview
```

defines one module with id `environment` and display name 
`Lab Environment Overview`. Module may require other modules, when such module is 
added to a lab, it also adds all required modules.

```
jboss:
  name: Deploying Java Code on JBoss
databases:
  name: Adding a Database (MongoDB)
  requires:
    - jboss
```

in the example module `databases` requires module `jboss`.

Module may provide multiple revisions. Revision id is string prefixed by `_` and 
appended to the module name. For example to define revision `extra` for module
`sourcecode` create file `modules/sourcecode_extra.adoc` instead of 
`modules/sourcecode.adoc`. Revision is then chosen as described in the previous 
section.

## Defaulting lab

In case you do not want to show the lab selection screen, set environment 
variable called `DEFAULT_LAB` with id of the lab as it's value. With this 
configuration, when you enter the selection screen, the user is automatically 
redirected to the defined lab.

```
oc new-app https://github.com/openshift-evangelists/openshift-workshops.git -p DEFAULT_LAB=<name of the lab>
```
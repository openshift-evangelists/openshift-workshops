# OpenShift workshop builder

## Deploying

Deploying on OpenShift is very simple, use the Ruby s2i builder and you are
(almost ready to go)

```
oc new-app ruby~https://github.com/openshift-evangelists/openshift-workshops.git
```

## Get started

* Clone repository locally
* Install Ruby
    * on macOS
        * `brew install ruby`
        * `gem install bundler`
* `bundle install` in the repository
* `bundle exec puma` in the repository
* `http://localhost:9292/`

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

Module may provide multiple revisions. There are two approaches to revisions.

First option is to use revision id to provide different module source. In that case
revision id is appended to the module name. For example to define revision `extra`
for module `sourcecode` create file `modules/sourcecode_extra.adoc` instead of
`modules/sourcecode.adoc`.

Second approach is to use the same file name as for the main content. In that case
the system automatically falls back to non-suffixed source file. The content is then
configured by redefining default variables for that particular module. This allows
reuse content but provide specific instruction for specific cases.

```
install:
  name: Installing the *oc* client tool
  vars:
    VARIABLE: value
  revisions:
    extra:
      vars:
        VARIABLE: extra value
```

In this example if the revision is not chosen the variable `VARIABLE` will have value
of `value`, however in case the `extra` revision is chosen, the value of `VARIABLE` will
be `extra value`.

Revisions are then chosen as described in the previous section.

### Folders
Modules can be grouped in folders (one level) inside `modules` folder and be references using the underscore syntax.

Example modules folder structure:
```

modules
  ├── java
  │     ├── jboss.adoc
  │     └── pipeline.adoc
  └── ops
        ├── quotas.adoc
        └── storage.adoc

```

You can refer to modules in the folders by prepending the name of the folder and underscore:
```
  java_jboss
  java_pipeline
  ops_quotas
  ops_storage
```

## Defaulting lab

In case you do not want to show the lab selection screen, set environment
variable called `DEFAULT_LAB` with id of the lab as it's value. With this
configuration, when you enter the selection screen, the user is automatically
redirected to the defined lab.

```
oc new-app https://github.com/openshift-evangelists/openshift-workshops.git -p DEFAULT_LAB=<name of the lab>
```

## System configuration

System is configured through environment variables

### DEFAULT_LAB

When this environment is set, the application root `/` does not show list of labs, but
redirects to lab specified as value, e.g. for `DEFAULT_LAB=test`, the user is redirected
to the Test lab at `/test`.

### DISPLAY_SOURCE

If this environment variables is set, source of the module is displayed below the rendered
content.

## Workshop content as a service

The system can provide you with workshop content without commiting your yml files to the
application itself. You upload the YAML definition as a file to the `_custom` endpoint and
the system give you embeddable version of your workshop.

To get a list for modules for your workshop, upload your `lab` file to the `/_custom` path.

```
$ curl -XPOST -F "lab=@labs/mods.yml" http://localhost:9292/_custom
```

and you will receive JSON with your modules

 ```
[
  {"id":"install","name":"Installing the *oc* client tool"},
  {"id":"jboss","name":"Deploying Java Code on JBoss"},
  {"id":"databases","name":"Adding a Database (MongoDB)"},
  {"id":"codechanges","name":"Using Source 2 Image for Code Changes"}
]
 ```

 To get the module content, upload the same file to the `/_custom/:module` path, where
 `:module` is the module name. E.g.

 ```
 $ curl -XPOST -F "lab=@labs/mods.yml" http://localhost:9292/_custom/install
 ```

 to get the HTML of the `Installing the *oc* client tool` module.

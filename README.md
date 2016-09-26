# OpenShift workshop builder

## Deploying

Deploying on OpenShift is very simple, use the Ruby s2i builder and you are (almost ready to go)

```
oc new-app https://github.com/openshift-evangelists/openshift-workshops.git -p DEFAULT_LAB=<name of the lab>
```

## Adding labs

In the terminology of this app `lab` is a workshop or some other kind of event. All events are configured in `config.yml` file.

```
labs:
  test:
    name: Testing workshop
 ```

 defines new lab with id `test` and display name `Testing workshop`, by default it adds all modules to the workshops. 
 In case you want just a subset of the workshops, add `modules` section to your lab and list the ids of modules you want to use.

 ```
labs:
  test:
    name: Testing workshop
    modules:
      - environment
 ```

With this configuration, there will be only one module in the lab.

## Modules

Modules are content sections that you go through during your workshop and are configured in the `modules.yml` file. 
Most of the time you should not need to change this file, but in case you want to change the structure of your lab, you will 
need to know the ids of the modules you want ot use, and those are configured in this file.

```
modules:
  environment:
    name: Lab Environment Overview
```

defines one module with id `environment` and display name `Lab Environment Overview`.

## Defaulting lab

In case you do not want to show the lab selection screen, set environment variable called `DEFAULT_LAB` with id of the lab as it's value.

With this configuration, when you enter the selection screen, the user is automatically redirected to the defined lab.
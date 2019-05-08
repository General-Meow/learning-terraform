# Terraform notes

### Common Comands
- `terraform init` - initializes the current directory to work with terraform, should be the first command to run, setups up config
- `terraform plan` - generates a (execution) plan on what will `terraform apply` will do
- `terraform apply` - generates a plan on what changes will be made and will ask if you wish to run it
- `terraform destroy` - destroys resources defined in the terraform file
- `terraform get` - if the working directory uses external modules then, this will download and install them
- `terraform fmt` - format your defined terraform configuration files
- `terraform graph` - create a visual representation of the configuration files
- `terraform import <OPTIONS> <ADDRESS> <ID>` - backwards engineer the current state of the provider and writes the terraform configuration for you
- `terraform push` - when using terraform enterprise (Atlas), it will run the apply from a centralized remote server
- `terraform refresh` - refresh remote state to find differences between the state file and the remote state
- `terraform show` - display a human readable plan
- `terraform remote` - configure remote storage state
- `terraform state <COMMAND> <OPTIONS> <ARG>` - change the terraform state, allows for mv, rm, list, pull, push etc
- `terraform taint` - taint a resource to be destroyed and recreated in the next apply
- `terraform untaint`
- `terraform validate` - validates your terraform config syntax



### Intro
- Terraform is an application that allows you to provision resources, be it compute, network, security (users), loadbalancers etc
- It does this all by allowing you to write infrastructor as code, meaning all the system is described as code
- Using Terraform allows you to automate the creation of your infrastructure
- You would normally use an installation & configuration application (Chef, Ansible, Puppet) with Terraform to configure the new resource after it is created
- Its plugin based architechure allows you to support various providers
- Running `terraform init` will download and init the binaries required to work with these providers, these are stored in a subdirectory of the working dir
- When running terraform, if there are no provider credentials (aws/azure/gcp) then it'll look in the `~/.aws/credentials` file for it (or terraform.tfvars in the working dir) - this should be done as you dont want to commit credentials in the repo
- example of a credentials file for aws
```
[default]
aws_access_key_id = "xxx"
aws_secret_access_key = "yyy"
```
- The provider is the system responsible for creating / managing resources aws/azure etc

### Basics
- The working directory will contain a number of terraform files, the main one will contain a `resource` which defines the type and name of the resource
``` terraform
  resource <type> <name> {
    <key> = <value>
  }
```
- All terraform files (*.tf) in a working directory will be loaded when running terraform
- For more details on the syntax see: `https://www.terraform.io/docs/configuration/index.html`
- When looking at the execution plan, the diff is like git, `+`, `-` represent resources being created and deleted
- When you see `<computed>` in the execution plan, it means that the value is not yet known and that its known after its created
- The working directory typically has multiple terraform files each for specific purposes
  - main.tf - where the main definitions live
  - variables.tf - where all the variables are defined with descriptions and default values
  - providers.tf - details of what provider to use
  - terraform.tfvars - file containing variables of sensitive data. to which you will refer to in the main.tf. this should be in the .gitignore gile


### Variables
- The values in key value pairs don't need to be hardcoded, they can be defined to look up variables
  - The syntax for a basic variable is ${var.VARIABLE_NAME} eg. `${var.my_token}`
  - This syntax is called interpolation, you can do other things with it, such as 
    - conditionals 
    - math expressions
    - variables
    - resources
    - data sources with `${data.xxx}`
- basic 
```
variable "this_is_my_variable" {
  default = "a default value goes here"
}
```
- List
  - there are 2 formats to defining lists. Explicit or implicit
  - implicit
  ```
  variable my_list {
    default = []
  }
  ```
  - explicit
  ```
  variable my_list {
    type = "list"
  }
  ```
  - to set a list variable value in terraform.tfvars
  ```
  my_list = ["a", "b", "c"]
  ```
- Map
variables.tf
```
variable "this_is_my_map_variable" {
  type = "map"
  default = {
    key_1 = "value 1"
    key_2 = "value 2"
    key_3 = "value 3"
  }
}
```
terraform.tfvars
```
this_is_my_map_variable = {
  key_1 = "value 1"
  key_2 = "value 2"
  key_3 = "value 3"
}
```
command line var
```
terraform apply -var 'this_is_my_map_variable={ key_1 = "value 1", key_2 = "value 2", key_3 = "value 3"	 }'
```
- To reference a map variable property, you use the syntax `${lookup(var.MAP_NAME, var.PROPERTY_NAME)}`
- You can also do static map lookups like `${var.MAP_NAME[var.PROPERTY_NAME]}`
- Variables are usually defined in the variables.tf file
- Variables can have defaults
  - If a variable has been defined but doesn't have a default, then its a required variable, which means that when you run `apply` it will fail if you dont supply the values 
- Variables can be basic variables or maps
- To access values of variables defined in the variables.tf file
variables.tf
```
variable example_var_1 {} //required
variable example_var_2 {
  default = "some value"
}
```
output.tf
```
output "example_output" {
  value = "${var.example_var_1}, ${var.example_var_2}"
}
```
- Variables can be assigned values in a number of different ways (in order of precedence), command line flags, files, environmental variables, ui input, defaults
- Command line variables are providered as so: `terraform apply -var 'example_var_1=blah' -var 'example_var_2=xxx'`
- From a file, if done via the `terraform.tfvars`
terraform.tfvars
```
example_var_1 = "blah"
example_var_2 = "xxx"
```
- If you have a file that isn't named terraform.tfvars but something else, use the -var-file command line argument to load it
- Environment variables take the form of `TF_VAR_xxx` so the above examples would look like `TF_VAR_example_var_1`

### Interpolation
- For conditionals the syntax is like java
- `${CONDITION ? truth : false}`
```
resource "aws_instance" "test" {
  count = "${var.env == "prod" ? 2 : 1}"
}
```
- You can also use the built in functions, these are wrapped with the `${ }` and are usually func(arg1, arg2, xxx)
- some functions
  - `basename("xxx/yyy/yyy.txt")` - returns the last bit og a path, in this case yyy.txt
  - `coalesce(string1, string2, x)` - returns first non empty val
  - `coalescelist(list1, list2)` - return non first non empty list
  - `element(list, index)`
  - `format(string, args, ...)` - uses regex to string format a string
  - `index(list, element)` - find the index of an element
  - `join(delimiter, list)` - join a list of strings sep by the delimeter
  - `list(x, y, z)` - create a list with items
  - `lookup(map, key, [optional default val])` - do a lookup on a map with key
  - `lower(string)`
  - `map(k1, v1, k2, v2)` - create a new map with values
  - `merge(map1, map2, ...)- merges maps into one
  - `replace(string, search, value)` - string replace
  - `split(delim, string)`
  - `substr(string, offset, length)`
  - `timestamp()`
  - `upper(string)`
  - `uuid()`
  - `values(map)` - returns all the values of a map in a list




### Post
- Installing software after the provisioning can be done in a number of ways
  - file uploads
  - remote exec
  - configuration management tools
- In order for you to do run provisionors you need access so using key pair or a connection will work
  - to create a key pair its as simple as `ssh-keygen -f terraform_key`
- Chef has some integration to install software on the provitioned resources
- Ansible integration is not as good
- To upload and execute scriptes on the new instances, you would use a provisioner
- Provisioners are blocks within the resource that define what to run
- These are only executed when the resource is created and not when its being updated, you can also have ones that run during destroy
- Multiple provisioner blocks can be defined and they will run one at a time
- If the resource has been successfully created but fails the provisioner part, the resource gets marked as `tainted` and will be removed and possibly recreated after the next `apply`
- file upload example
```
resource xxx xxx {
  type = xxx
  
  provisioner "file" {
    source = "app.file"
    destination = "/opt/blah/app.file"
    
    connection {
      user = "${var.instance_username}"
      password = "${var.instance_password}"
    }
  }
}
```
- File upload will need to somehow get that file across and it'll use ssh or winrm to copy it across
  - you'll need to use the `connection` property on the file provisioner to override the defaults
  - When using aws, the default username for ec2 instances is `ec2-user`
- Typically when getting access to AWS resources, you'll use ssh with a key pair rather than a username and passowrd
  - You can define a key pair resource as follows
```
resource "aws_key_pair" "pauls_key" `{
  key_name = "my_key_name_thats_referred_to"
  public_key = "ssh-rsa xxxxxxx......"
}

resource "aws_instance" "my_instance" {
  xxx ...
  key_name = "${aws_key_pair.my_key_name_thats_referred_to.key_name}"
  
  provisioner "file" {
    xxx...
    
    connection {
      user = "${var.instance_username}"
      private_key = "${file(${var.path_to_private_key})}"   //This file function reads the entire contents of the file
    }
  }
}
```
- Doing remote exec is done by using the provisioner `remote-exec`
```
resource "xx" "xx" {
  ...

  provisioner "remote-exec" {
    inline = [
      "chmod +x /opt/xxxx",
      "/opt/xxx"
    ]
  }

}
```
- Details (attributes) of the resources created are also stored by terraform and can be queried and outputted
  - details such as the public IP of the EC2 instance just created
  - these details can then be fed as input to other apps or just printed to the console
  - to get access to the attributes you simply use the syntax `${<RESOURCE_TYPE>.<RESOURCE_NAME>.<ATTRIBUTE_NAME>}` eg. `${aws_instance.my_instance.public_ip}`
  - you can also output this info via the output function
```
resource "aws_instance" "my_instace" {
  xxx = ""
  xxx = ""
}

output "ip" {
  value = "${aws_instance.my_instance.public_ip}"
}
```

- like the `remote-exec` provisioner, you can use the `local-exec` that will run on your local machine
```
resource "aws_instance" "my_instace" {
  xxx = ""
  xxx = ""
  
  provisioner "local-exec" {
    command = "echo ${aws_instance.my_instance.public_ip} >> private_ip.txt" 
  }
}
```


### History
- Terraform keeps state of the provisioned resources in a file call `terraform.tfstate` and the previous state in `terraform.tfstate.backup`
  - this file is created after running `terraform apply`
  - this gives a history of what the state was like
  - when working on a large project with mulitple devs, there may be a lot of git conflicts so storing it locally is only a good idea on small projects. when this starts to happen change the config to have it stored remotely
  - To change where the history is stored, you change the "backend"
  - There are 3 backends you can choose, S3, Consul, Terraform Enterprise
  - advantages include
    - state is always available (devs can change the env state but wont be availble to others until they commit and push)
    - sensitive data is no longer locally
- To configure, add a `backend.tf` configuration file with the correct config - just look this up
```
terraform {
  backend "consul" {
    address = "demo.consul.io"
    path    = "getting-started-RANDOMSTRING"
    lock    = false
  }
}
```

### Datasources
- A datasource in Terraform is just a place to retrieve data
- Used in some providers like AWS
- AWS provides loads of data via its API but its easier to get this same data via the datasource
- You can get this data and run filters against it and have it avalable in variables during an `apply`
```
data "aws_ip_ranges" "my_ips" {
  regions = ["us-west-1"]
}
```
- With the definition above, `my_ips` will now contain all IPs in the `us-west-1` region
- You can access this data with `${data.aws_ip_ranges.my_ips.create_date}`


### Templating
- Terraform supports templates
- Templates are files like scripts or application configuration files that have variables
- These variables are then replaced with values/variables defined in the Terraform files
- With a template resource defined in the file that points the the script/config template, it replaces all the variables with values and then can feed it to AWS startup scripts for EC2 instance (user-data)
- The template
```
#!/bin/bash
echo "Hello ${name}"
```
- The TF file
```
data "template_file" "my_script" {
  tempalte = ${file(the_template_file.tpl)}
  
  vars {
    name = "Paul"
  }
}

resource "aws_instance" "demp_instance" {
  ...
  user-data = ${template_file.mu_script.rendered}
}
```


### Modules
- Modules are a way to keep your Terraform code organised
- It also allows you go generify your code so that you can reuse them
- Modules can depend on modules that depend on mondules
- There are third party modules that you can also use.
- To use a module, simple define a module resource with a source atrribute, followed by any arguments that the module needs
- You will also need to re-run `terraform init` in order for terraform to check and download any additional dependencies
```
module "a_module_from_github" {
  source = "github.com/blah/terraform-module"
  //or use a local folder
  source = "./terraform-module"
  
  //arguments
  an_arg = "random text"
  another_arg = "some other text"
}
```
- The arguments defined with the module resource actually override the variables defined in the variables.tf
- Resources defined in the module package will be available for access under your defined module resource eg
```
//code in a terraform-module
output "summary" {
  value = "${aws_instance.instance_1.public_ip}, ${aws_instance.instance_2.public_ip}"
}

//code in another module using the terraform-module
module "blah" {
  //or use a local folder
    source = "./terraform-module"
    
    //arguments
    an_arg = "random text"
    another_arg = "some other text"
}

output "module-test" {
  value = "${module.blah.summary}"
}
```


### Dependencies
- Resources can depend on each other, Terraform must work out these dependecies to create resources in the right order
- There is both implicit and explicit dependencies
- Implicit is where you use interpolation to define when a resource requires another and terraform inspect these to work it out
  - eg key = "aws_instance.my_instance.ip"
- Explicit is used when Terraform cannot work out the dependencies between resources and you give it a hand
```
resource "blah" "a" {
...
}

resource "another_blah" "b" {
  depends = ["blah.a"]
}
```

## AWS
### VPC
```
resource "aws_vpc" "my_vpc" {

}
```


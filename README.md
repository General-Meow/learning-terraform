###Terraform notes

#####Common Comands
- `terraform init` - initializes the current directory to work with terraform, should be the first command to run, setups up config
- `terraform plan` - generates a (execution) plan on what will `terraform apply` will do
- `terraform apply` - generates a plan on what changes will be made and will ask if you wish to run it
- `terraform destroy` - destroys resources defined in the terraform file


#####Intro
- Terraform is an application that allows you to provision resources, be it compute, network, security (users), loadbalancers etc
- It does this all by allowing you to write infrastructor as code, meaning all the system is described as code
- Using Terraform allows you to automate the creation of your infrastructure
- You would normally use an installation & configuration application (Chef, Ansible, Puppet) with Terraform to configure the new resource after it is created
- Its plugin based architechure allows you to support various providers
- Running `terraform init` will download and init the binaries required to work with these providers, these are stored in a subdirectory of the working dir
- When running terraform, if there are no provider credentials (aws/azure/gcp) then it'll look in the `~/.aws/credentials` file for it (or terraform.tfvars in the working dir) - this should be done as you dont want to commit credentials in the repo
- The provider is the system responsible for creating / managing resources aws/azure etc

#####Basics
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


#####Variables
- The values in key value pairs don't need to be hardcoded, they can be defined to look up variables
  - The syntax for a basic variable is ${var.VARIABLE_NAME} eg. `${var.my_token}`
- Variables can be basic variables or maps
- basic 
```
variable "this_is_my_variable" {
  default = "a default value goes here"
}
```
- Map
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
- To reference a map variable property, you use the syntax `${lookup(var.MAP_NAME, var.PROPERTY_NAME)}`


#####Post
- Installing software after the provisioning can be done in a number of ways
  - file uploads
  - remote exec
  - configuration management tools
- Chef has some integration to install software on the provitioned resources
- Ansible integration is not as good
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


#####History
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


#####Datasources
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


#####Templating
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

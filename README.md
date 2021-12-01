# iac-minecraft

## Getting Started

1. `git clone https://github.com/boop-ninja/iac-minecraft.git`
2. `terraform init`
3. `touch terraform.tfvars.json`
4. Edit the `terraform.tfvars.json`, see [Required Variables](#required-variables)
5. `terraform plan`
6. If things look good with the plan, `terraform apply`


## Required Variables

|Variable|Example Value|Description|
|-|-|-|
|`kube_host`|`https://127.0.0.1:6443`|The host of the kubernetes cluster.|
|`kube_crt`|`base64`|Base64 encoded Crt found in KUBECONFIG|
|`kube_key`|`base64`|Base64 encoded Key found in KUBECONFIG|
|`external_ip`|`1.1.1.1`|THe external IP address to bind the Minecraft server with.|
|`domain`|`mc.domain.tld`|This is a parameter for [BlueMaps](https://github.com/BlueMap-Minecraft/BlueMap) (currently not optional)|
|`mods`|`["https://github.com/BlueMap-Minecraft/BlueMap/releases/download/v1.7.2/BlueMap-1.7.2-spigot.jar"]`|Array of mods, suggestion to add the latest version of bluemaps for the domain portion.|
|`environment_vars`|`{}`|Object of key value pairs for environment variables. [Click here to see the base containers image variables](https://github.com/itzg/docker-minecraft-server/blob/master/README.md)|
|`additional_ports`|`[{"name": "bluemaps","container_port": 8100}]`| Additional ports to attach to the container, useful for any mod that uses a port|
|`use_database`|`true`|Boolean to flip in case you are or aren't using a database with your server. Autoloads postgres as the base database|
|`database_password`|`changeme`|The password to use with your database|

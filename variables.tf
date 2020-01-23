variable "do_token" {
  description = "Your Digital Ocean API token"
}

variable "public_key_path" {
  description = "Path to the SSH public key to be used for authentication"
}

variable "private_key_path" {
  description = "Path to the SSH public key to be used for authentication"
}

variable "do_key_name" {
  description = "Name of the key on Digital Ocean"
  default = "Homekeycheng"
}

variable "swarm_token_dir" {
  description = "Path (on the remote machine) which contains the generated swarm tokens"
  default = "/root"
}

variable "do_user" {
  description = "User to use to connect the machine using SSH. Depends on the image being installed."
  default = "root"
}

variable "putty_gen_key" {
  description = "Path to the putty public key to be used for authentication"
}

variable "worker_token_local_path" {
  description = "User to use to connect the machine using SSH. Depends on the image being installed."
}
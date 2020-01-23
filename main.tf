provider "digitalocean" {
  token = "${var.do_token}"
}

resource "digitalocean_ssh_key" "default" {
  name = "${var.do_key_name}"
  public_key = "${file(var.public_key_path)}"
}

resource "digitalocean_droplet" "docker_swarm_manager" {
  name = "docker-swarm-manager"
  region = "nyc1"
  size = "s-1vcpu-2gb"
  image = "docker-18-04"
  ssh_keys = ["${digitalocean_ssh_key.default.id}"]
  private_networking = true

  provisioner "remote-exec" {
  	connection {
      user = "root"
      type = "ssh"
      host = self.ipv4_address
      private_key = "${file(var.private_key_path)}"
      timeout = "2m"
    }
   	  inline = [
      "export PATH=$PATH:/usr/bin",
      "sudo apt-get update",
      "ufw allow 22/tcp",
      "ufw allow 2376/tcp",
      "ufw allow 2377/tcp",
      "ufw allow 7946/tcp",
      "ufw allow 7946/udp",
      "ufw allow 4789/udp",
      "ufw reload",
      "echo y | ufw enable",
      "systemctl restart docker",
      "docker swarm init --advertise-addr ${digitalocean_droplet.docker_swarm_manager.ipv4_address_private}",
      "docker swarm join-token --quiet worker > ${var.swarm_token_dir}/worker.token",
      "docker swarm join-token --quiet manager > ${var.swarm_token_dir}/manager.token"
    ]
    }

	provisioner "local-exec" {
		command = "ping -n 21 127.0.0.1 >nul & echo y | pscp -scp -i ${var.putty_gen_key} ${var.do_user}@${self.ipv4_address}:${var.swarm_token_dir}/worker.token ."
	}
}

 	resource "local_file" "master_id" {
 	 	content  =  "docker_swarm_manager_ip is ${digitalocean_droplet.docker_swarm_manager.ipv4_address_private}"
 		filename = "master_id.txt"
	}

resource "digitalocean_droplet" "docker_swarm_worker" {
  count = 1
  name = "docker-swarm-worker-${count.index}"
  region = "nyc1"
  size = "s-1vcpu-2gb"
  image = "docker-18-04"
  ssh_keys = ["${digitalocean_ssh_key.default.id}"]
  private_networking = true

   provisioner "file" {
    source = "worker.token"
    destination = "/root/worker.token"

    connection {
    	type     = "ssh"
    	user     = "root"
    	host     = self.ipv4_address
    	private_key = "${file(var.private_key_path)}"
    	timeout = "2m"
 	}
  }


  provisioner "remote-exec" {
  	connection {
      user = "root"
      type = "ssh"
      host = self.ipv4_address
      private_key = "${file(var.private_key_path)}"
      timeout = "3m"
    }
     inline = [
      "export PATH=$PATH:/usr/bin",
      "sudo apt-get update",
      "ufw allow 22/tcp",
      "ufw allow 2376/tcp",
      "ufw allow 7946/tcp",
      "ufw allow 7946/udp",
      "ufw allow 4789/udp",
      "ufw reload",
      "echo y | ufw enable",
      "systemctl restart docker",
      "docker swarm join --token $(cat ${var.swarm_token_dir}/worker.token) ${digitalocean_droplet.docker_swarm_manager.ipv4_address_private}:2377"
    ]
  }
}


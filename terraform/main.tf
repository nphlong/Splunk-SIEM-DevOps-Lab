resource "docker_image" "splunk" {
  name = var.splunk_image
}

resource "docker_network" "splunk_net" {
  name   = "splunk_net"
  driver = "bridge"
}

# Cluster Master
resource "docker_container" "cm1" {
  name  = "cm1"
  image = docker_image.splunk.name
  env   = [
    "SPLUNK_START_ARGS=--accept-license",
    "SPLUNK_GENERAL_TERMS=--accept-sgt-current-at-splunk-com",
    "SPLUNK_PASSWORD=${var.splunk_password}"
  ]
  networks_advanced {
    name    = docker_network.splunk_net.name
    aliases = ["cm1"]
  }
  ports {
    internal = 8000
    external = 8000
  }
}

# Indexer 1
resource "docker_container" "idx1" {
  name  = "idx1"
  image = docker_image.splunk.name
  env   = [
    "SPLUNK_START_ARGS=--accept-license",
    "SPLUNK_GENERAL_TERMS=--accept-sgt-current-at-splunk-com",
    "SPLUNK_PASSWORD=${var.splunk_password}"
  ]
  networks_advanced {
    name    = docker_network.splunk_net.name
    aliases = ["idx1"]
  }
}

# Indexer 2
resource "docker_container" "idx2" {
  name  = "idx2"
  image = docker_image.splunk.name
  env   = [
    "SPLUNK_START_ARGS=--accept-license",
    "SPLUNK_GENERAL_TERMS=--accept-sgt-current-at-splunk-com",
    "SPLUNK_PASSWORD=${var.splunk_password}"
  ]
  networks_advanced {
    name    = docker_network.splunk_net.name
    aliases = ["idx2"]
  }
}

# Search Head 1
resource "docker_container" "sh1" {
  name  = "sh1"
  image = docker_image.splunk.name
  env   = [
    "SPLUNK_START_ARGS=--accept-license",
    "SPLUNK_GENERAL_TERMS=--accept-sgt-current-at-splunk-com",
    "SPLUNK_PASSWORD=${var.splunk_password}"
  ]
  networks_advanced {
    name    = docker_network.splunk_net.name
    aliases = ["sh1"]
  }
  ports {
    internal = 8000
    external = 8001
  }
}

# Search Head 2
resource "docker_container" "sh2" {
  name  = "sh2"
  image = docker_image.splunk.name
  env   = [
    "SPLUNK_START_ARGS=--accept-license",
    "SPLUNK_GENERAL_TERMS=--accept-sgt-current-at-splunk-com",
    "SPLUNK_PASSWORD=${var.splunk_password}"
  ]
  networks_advanced {
    name    = docker_network.splunk_net.name
    aliases = ["sh2"]
  }
  ports {
    internal = 8000
    external = 8002
  }
}

# Deployer
resource "docker_container" "dep1" {
  name  = "dep1"
  image = docker_image.splunk.name
  env   = [
    "SPLUNK_START_ARGS=--accept-license",
    "SPLUNK_GENERAL_TERMS=--accept-sgt-current-at-splunk-com",
    "SPLUNK_PASSWORD=${var.splunk_password}"
  ]
  networks_advanced {
    name    = docker_network.splunk_net.name
    aliases = ["dep1"]
  }
}

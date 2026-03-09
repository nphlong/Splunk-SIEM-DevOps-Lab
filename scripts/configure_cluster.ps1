# configure_cluster.ps1

# Cluster Master
docker exec cm1 sudo /opt/splunk/bin/splunk edit cluster-config -mode master -replication_factor 2 -search_factor 2 -secret changemecluster -auth admin:changeme123 --run-as-root
docker exec cm1 sudo /opt/splunk/bin/splunk restart --run-as-root

# Indexers
foreach ($idx in "idx1","idx2") {
  docker exec $idx sudo /opt/splunk/bin/splunk edit cluster-config -mode slave -master_uri https://cm1:8089 -replication_port 9887 -secret changemecluster -auth admin:changeme123 --run-as-root
  docker exec $idx sudo /opt/splunk/bin/splunk restart --run-as-root
}

# Search Heads
foreach ($sh in "sh1","sh2") {
  docker exec $sh sudo /opt/splunk/bin/splunk edit shcluster-config -mgmt_uri https://$sh:8089 -replication_port 9000 -secret changemecluster -auth admin:changeme123 --run-as-root
  docker exec $sh sudo /opt/splunk/bin/splunk restart --run-as-root
}

# Bootstrap captain
docker exec sh1 sudo /opt/splunk/bin/splunk bootstrap shcluster-captain -servers_list "https://sh1:8089,https://sh2:8089" -auth admin:changeme123 --run-as-root

# -------------------------------
# Validation Section
# -------------------------------

Write-Host "Validating Cluster Master..."
docker exec cm1 sudo /opt/splunk/bin/splunk show cluster-status -auth admin:changeme123 --run-as-root

Write-Host "Validating Indexers..."
foreach ($idx in "idx1","idx2") {
  docker exec $idx sudo /opt/splunk/bin/splunk show cluster-status -auth admin:changeme123 --run-as-root
}

Write-Host "Validating Search Head Cluster..."
docker exec sh1 sudo /opt/splunk/bin/splunk show shcluster-status -auth admin:changeme123 --run-as-root

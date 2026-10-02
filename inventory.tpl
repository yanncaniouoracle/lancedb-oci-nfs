[bastion]
${bastion_name} ansible_host=${bastion_ip} ansible_user=opc role=bastion
[storage]
%{ for host, ip in storage ~}
${host} ansible_host=${ip} ansible_user=opc role=storage
%{ endfor ~}
[quorum]
%{ for host, ip in quorum ~}
${host} ansible_host=${ip} ansible_user=opc role=quorum
%{ endfor ~}
[compute]
%{ for host, ip in compute ~}
${host} ansible_host=${ip} ansible_user=opc role=compute
%{ endfor ~}
[all:children]
bastion
storage
compute
quorum
[all:vars]
ansible_connection=ssh
ansible_user=opc
fs_name=${fs_name}
fs_type=${fs_type}
fs_ha=${fs_ha}
vcn_domain_name=${vcn_domain_name}
public_subnet_cidr_block=${public_subnet_cidr_block}
private_storage_subnet_cidr_block=${private_storage_subnet_cidr_block}
private_storage_subnet_dns_label=${private_storage_subnet_dns_label}
storage_subnet_domain_name=${storage_subnet_domain_name}
storage_server_node_count=${storage_server_node_count}
mount_point=${mount_point}
nfs_client_mount_root=${mount_point}
block_size=${block_size}
storage_server_hostname_prefix=${storage_server_hostname_prefix}
hacluster_user_password="${hacluster_user_password}"
hacluster_salt="${hacluster_salt}"
lv_name="disk"
vg_name="vg_nfs_disk"
nfs_server_ip=${nfs_server_ip}
storage_server_filesystem_vnic_hostname_prefix=${storage_server_filesystem_vnic_hostname_prefix}
private_fs_subnet_dns_label=${private_fs_subnet_dns_label}
filesystem_subnet_domain_name=${filesystem_subnet_domain_name}
storage_server_dual_nics=${storage_server_dual_nics}
private_fs_subnet_cidr_block=${private_fs_subnet_cidr_block}
quorum_server_hostname=${quorum_server_hostname}
NODE1=${storage_server_hostname_prefix}1
NODE2=${storage_server_hostname_prefix}2
ha_config_dir=/home/opc/ha_config

use_non_uhp_fs1=${use_non_uhp_fs1}

fs1_disk_perf_tier=${fs1_disk_perf_tier}
fs1_disk_count=${fs1_disk_count}
fs1_disk_size=${fs1_disk_size}

fs1_name=nfsshare
fs1_lv_name="disk"
fs1_vg_name="vg_nfs_disk"
fs1_dir="/mnt/nfsshare"

# Optional LanceDB shared-table data plane.  These resources are enabled only
# when the root stack enables them and are managed by the NFS Pacemaker group.
enable_lancedb_dataplane=${enable_lancedb_dataplane}
lancedb_service_git_url="${lancedb_service_git_url}"
lancedb_service_git_version="${lancedb_service_git_version}"
lancedb_nfs_database_path="${lancedb_nfs_database_path}"
lancedb_nfs_table_name="${lancedb_nfs_table_name}"
lancedb_nfs_vector_dimensions=${lancedb_nfs_vector_dimensions}
lancedb_oci_bucket="${lancedb_oci_bucket}"
lancedb_ingestion_queue_id="${lancedb_ingestion_queue_id}"
lancedb_ingestion_queue_endpoint="${lancedb_ingestion_queue_endpoint}"
lancedb_source_routes='${lancedb_source_routes}'
lancedb_reconciliation_interval="${lancedb_reconciliation_interval}"

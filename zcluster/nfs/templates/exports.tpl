# /etc/exports: the access control list for filesystems which may be exported
# to NFS clients.  See exports(5).
#
# Example for NFSv2 and NFSv3:
#
# Example for NFSv4:
#
%{ for node in client_nodes ~}
${export_base_path}/${node}     ${network_cidr}(nohide,insecure,rw,no_root_squash)
%{ endfor ~}
${export_base_path}/zcm03     ${network_cidr}(nohide,insecure,rw,no_root_squash)

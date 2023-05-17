127.0.0.1 localhost
127.0.0.1 ${hostname} ${hostname}.${local_domain}
%{ for name, data in nodes ~}
${data.ip} ${name} ${name}.${local_domain}
%{ endfor ~}

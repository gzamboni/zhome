127.0.0.1 localhost
127.0.0.1 ${hostname} ${hostname}.${local_domain}
%{ for name, ip in nodes ~}
${ip} ${name} ${name}.${local_domain}
%{ endfor ~}

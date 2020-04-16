#!/bin/bash 
cat > index.html <<EOF 
<h1>Hello, World using versioned module webserver-cluster v0.0.2</h1>
<p>DB address: ${db_address}</p> 
<p>DB port: ${db_port}</p> 
EOF
nohup busybox httpd -f -p ${server_port} &
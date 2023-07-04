rm *.pem
rm keys/*
echo "Generating self-signed certificate..."
# 1. Generate CA's private key and self-signed certificate
openssl req -x509 -newkey rsa:4096 -days 1825 -nodes -keyout ca-key.pem -out ca-cert.pem -subj "/C=US/ST=EX/L=EX/O=org/OU=DevOps/CN=*.org"
# 2. Generate web server's private key and certificate signing request (CSR)
openssl req -newkey rsa:4096 -nodes -keyout server-key.pem -out server-req.pem -subj "/C=US/ST=EX/L=EX/O=org/OU=DevOps/CN=*.org"
# 3. Use CA's private key to sign web server's CSR and get back the signed certificate
openssl x509 -req -in server-req.pem -days 1825 -CA ca-cert.pem -CAkey ca-key.pem -CAcreateserial -out server-cert.pem -extfile server-ext.cnf
# 4. Generate client's private key and certificate signing request (CSR)
openssl req -newkey rsa:4096 -nodes -keyout client-key.pem -out client-req.pem -subj "/C=US/ST=EX/L=EX/O=org/OU=DevOps/CN=*.org"
# 5. Use CA's private key to sign client's CSR and get back the signed certificate
openssl x509 -req -in client-req.pem -days 1825 -CA ca-cert.pem -CAkey ca-key.pem -CAcreateserial -out client-cert.pem -extfile client-ext.cnf 
rm ca-cert.srl ca-key.pem client-req.pem server-req.pem
chmod 0666 *.pem

echo "Generating jwt keys..."
cd keys
ssh-keygen -t rsa -b 4096 -m PEM -N "" -f access_key > /dev/null
openssl rsa -in access_key -pubout -outform PEM -out access_key.pub
ssh-keygen -t rsa -b 4096 -m PEM -N "" -f refresh_key > /dev/null
openssl rsa -in refresh_key -pubout -outform PEM -out refresh_key.pub
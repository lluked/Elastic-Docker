#!/bin/bash

# Check env variables exist
if [ x${ELASTIC_PASSWORD} == x ]; then
  echo "Set the ELASTIC_PASSWORD environment variable in the .env file";
  exit 1;
elif [ x${KIBANA_SYSTEM_PASSWORD} == x ]; then
  echo "Set the KIBANA_SYSTEM_PASSWORD environment variable in the .env file";
  exit 1;
elif [ x${LOGSTASH_SYSTEM_PASSWORD} == x ]; then
  echo "Set the LOGSTASH_SYSTEM_PASSWORD environment variable in the .env file";
  exit 1;
elif [ x${LOGSTASH_INTERNAL_PASSWORD} == x ]; then
  echo "Set the LOGSTASH_INTERNAL_PASSWORD environment variable in the .env file";
  exit 1;
elif [ x${BEATS_SYSTEM_PASSWORD} == x ]; then
  echo "Set the BEATS_SYSTEM_PASSWORD environment variable in the .env file";
  exit 1;  
elif [ x${FILEBEAT_INTERNAL_PASSWORD} == x ]; then
  echo "Set the FILEBEAT_INTERNAL_PASSWORD environment variable in the .env file";
  exit 1;
fi;

# Generate ca
if [ ! -f certs/ca.zip ]; then
  echo "Creating CA";
  bin/elasticsearch-certutil ca --silent --pem -out config/certs/ca.zip;
  unzip config/certs/ca.zip -d config/certs;
fi;

# Generate certs
if [ ! -f certs/certs.zip ]; then
  echo "Creating certs";
  bin/elasticsearch-certutil cert --silent --pem -out config/certs/certs.zip --in config/setup/instances.yml --ca-cert config/certs/ca/ca.crt --ca-key config/certs/ca/ca.key;
  unzip config/certs/certs.zip -d config/certs;
fi;

# Set permissions on certs
echo "Setting file permissions"
chown -R 1000:0 config/certs;
find . -type d -exec chmod 750 \{\} \;;
find . -type f -exec chmod 640 \{\} \;;

# Check elasticsearch availability
echo "Waiting for Elasticsearch availability";
until curl -s --cacert config/certs/ca/ca.crt https://es01:9200 | grep -q "missing authentication credentials"; do sleep 30; done;

# Set kibana_system password
echo "Setting kibana_system password";
until curl -s -X POST --cacert config/certs/ca/ca.crt -u elastic:${ELASTIC_PASSWORD} -H "Content-Type: application/json" https://es01:9200/_security/user/kibana_system/_password -d "{\"password\":\"${KIBANA_SYSTEM_PASSWORD}\"}" | grep -q "^{}"; do sleep 10; done;

# Set logstash_system password
echo "Setting logstash_system password";
until curl -s -X POST --cacert config/certs/ca/ca.crt -u elastic:${ELASTIC_PASSWORD} -H "Content-Type: application/json" https://es01:9200/_security/user/logstash_system/_password -d "{\"password\":\"${LOGSTASH_SYSTEM_PASSWORD}\"}" | grep -q "^{}"; do sleep 10; done;

# Create logstash_writer role
echo "Creating logstash_writer role";
until curl -s -X POST --cacert config/certs/ca/ca.crt -u elastic:${ELASTIC_PASSWORD} -H "Content-Type: application/json" https://es01:9200/_security/role/logstash_writer \
-d '{"cluster":["manage_index_templates","monitor","manage_ilm"],"indices":[{"names":["logstash-*"],"privileges":["write","create","create_index","manage","manage_ilm"]}]}' | grep "role"; do sleep 10; done;

# Create logstash_internal user
echo "Creating logstash_internal user";
until curl -s -X POST --cacert config/certs/ca/ca.crt -u elastic:${ELASTIC_PASSWORD} -H "Content-Type: application/json" https://es01:9200/_security/user/logstash_internal \
--data @<(cat <<EOF
{
  "password" : "$LOGSTASH_INTERNAL_PASSWORD",
  "roles" : ["logstash_writer"],
  "full_name" : "Internal Logstash User"
}
EOF
) \
| grep "created"; do sleep 10; done;

# Set beats_system password
echo "Setting logstash_system password";
until curl -s -X POST --cacert config/certs/ca/ca.crt -u elastic:${ELASTIC_PASSWORD} -H "Content-Type: application/json" https://es01:9200/_security/user/beats_system/_password -d "{\"password\":\"${BEATS_SYSTEM_PASSWORD}\"}" | grep -q "^{}"; do sleep 10; done;

# Create filebeat_writer role
echo "Creating filebeat_writer role";
until curl -s -X POST --cacert config/certs/ca/ca.crt -u elastic:${ELASTIC_PASSWORD} -H "Content-Type: application/json" https://es01:9200/_security/role/filebeat_writer \
-d '{"cluster":["manage_index_templates","monitor","manage_ilm"],"indices":[{"names":["filebeat-*"],"privileges":["write","create","create_index","manage","manage_ilm"]}]}' | grep "role"; do sleep 10; done;

# Create filebeat_internal user
echo "Creating filebeat_internal user";
until curl -s -X POST --cacert config/certs/ca/ca.crt -u elastic:${ELASTIC_PASSWORD} -H "Content-Type: application/json" https://es01:9200/_security/user/filebeat_internal \
--data @<(cat <<EOF
{
  "password" : "$FILEBEAT_INTERNAL_PASSWORD",
  "roles" : ["filebeat_writer"],
  "full_name" : "Internal Filebeat User"
}
EOF
) \
| grep "created"; do sleep 10; done;

# Finished
echo "All done!";
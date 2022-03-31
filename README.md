# Elastic-Docker

A Docker Compose project that brings the elastic stack up, including:

- Elasticsearch
- Kibana
- Logstash
- Filebeat
 
The Docker Compose file was originally based on [Start the Elastic Stack with Docker Compose](https://www.elastic.co/guide/en/elastic-stack-get-started/current/get-started-stack-docker.html#get-started-docker-tls), however now:

- All elastic based configurations have been moved from environment variables into their own config files.
- YAML anchoring has been used to define the elasticsearch services.
- Logstash and Filebeat services have been added to complete the stack.
- The setup service has had its command block moved out into a script, with a supporting file for defining instances rather than the file being created by the script.
- Additional users for Logstash and Filebeat have been added to the setup script.
- The setup script now chowns certs as `1000:0` rather than `root:root` as this causes issues with Logstash not being able to mount them.
- Monitoring is enabled on the Elasticsearch hosts.

Additionally:

- Monitoring has been configured for both Logstash and Filebeat.
- Logstash has a generator pipeline configuration to add test events, along with a beats pipeline.
- Filebeat monitors its own log file and forwards to elasticsearch.

This project is intended to be a reference for configuring the Elastic stack for other projects, changes will need to be made based on what the stack is going to be used for.

## Instructions

- Read the notes.
- Launch the project with `docker-compose up` from the project directory.
- Wait a little while for everything to start correctly.
- Visit Kibana at `localhost:5601`.
- Once logged in select the burger navigation icon, select Management -> Stack Management, select Kibana -> Data Views, you will then be prompted to create a data view. Create one with the Name matching a index pattern, `logstash-*` or `filebeat-*` for example, and set the Timestamp field to `@timestamp`. 
- Logs can now be viewed under Discover.
- Stack monitoring is also available under Management -> Stack Monitoring.

## Notes

- If you haven't run the Elastic Stack before you may come into errors related to memory allocation and be asked to set `sysctl.vm.max_map_count` to `262144`.
- On macOS docker may also fail to bind Kibana to port `5601`, change `KIBANA_PORT` in the `.env` file to a free port, `5602` for example.

#### Windows 
To set `sysctl.vm.max_map_count` create or append to the `.wslconfig` file in your home directory with the following config:

```
[wsl2]
kernelCommandLine = "sysctl.vm.max_map_count=262144"
```

#### Linux 
To set `sysctl.vm.max_map_count`  run `sysctl -w vm.max_map_count=262144` as root.

#### macOS
Open docker desktop, go to Settings -> Resources -> Memory and set to ~ `6GB`.

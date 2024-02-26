#!/bin/bash
# disable PerformanceAnalyzerApp, which is causing errors in `make opensearch`
# https://opensearch.org/docs/latest/monitoring-your-cluster/pa/index/#disable-performance-analyzer
# curl -XPOST localhost:9200/_plugins/_performanceanalyzer/rca/cluster/config -H 'Content-Type: application/json' -d '{"enabled": false}' &&
# kill $(ps aux | grep -i 'PerformanceAnalyzerApp' | grep -v grep | awk '{print $2}') &&
# curl -XPOST localhost:9200/_plugins/_performanceanalyzer/cluster/config -H 'Content-Type: application/json' -d '{"enabled": false}' &&
bin/opensearch-plugin remove opensearch-performance-analyzer
bin/opensearch-plugin remove opensearch-observability
#bin/opensearch-plugin remove opendistro_security
chown -R 1000:root /usr/share/opensearch/data/nodes
./opensearch-docker-entrypoint.sh opensearch
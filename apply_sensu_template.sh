#!/bin/bash
# Created by Christopher Phipps 10/24/2016
# Creates an elastic template to work with sensu.
# Ensures that the host term isn't analyzed so it remains intact even with hyphens
# Has a location for hosts and clusters to accomodate vmware metrics.

curl -XPUT http://localhost:9200/_template/sensu-metrics -d '
{
  "template" : "sensu*",
  "mappings" : {
    "metrics" : {
      "properties" : {
        "@timestamp" : {
          "type" : "date",
          "format" : "strict_date_optional_time||epoch_millis"
        },
        "host" : {
          "type" : "string",
          "index" : "not_analyzed"
        },
        "vmhost" : {
          "type" : "string",
          "index" : "not_analyzed"
        },
        "chost" : {
          "type" : "string",
          "index" : "not_analyzed"
        },
        "metric" : {
          "type" : "string"
        },
        "value" : {
          "type" : "double"
        }
      }
    }
  }
}'

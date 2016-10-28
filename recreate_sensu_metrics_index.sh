#!/bin/bash
# Created by Christopher Phipps 10/24/2016
# Creates the sensu-metrics index in elasticsearch
# Deletes the current index also, before creating it
# THIS WILL DELETE ALL OF YOUR INFORMATION AND SHOULD ONLY BE USED WHEN CREATING AN INDEX, OR UPDATING THE SCHEMA WITH A NEW TEMPLATE!!!!
curl -XDELETE localhost:9200/sensu-metrics
curl -XPUT localhost:9200/sensu-metrics


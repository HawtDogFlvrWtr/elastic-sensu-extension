# Sensu extension for Elasticseach
###### Created by Christopher Phipps 10/24/2016

## To Install

1. Creating the extension config file
Create a sensu extension config file under /etc/sensu/conf.d/extensions, called elastic.json. The contents of the file will reference your elasticsearch server, and the index you want to use.
```
{
  "elastic": {
    "timeout": "1",
    "index": "sensu-metrics",
    "type": "metrics",
    "host": "localhost:9200"
  }
}
```
The top level is the name you will be referencing in your metrics checks. It's the name of the extension. In this example, it's called elastic. This cannot be changed unless you rename the extension name within the elastic.rb file! Be sure to change the host value to wherever your elastic index is residing. 

2. Copy the elastic.rb file to /etc/sensu/extensions/

3. Create the appropriate check within sensu under /etc/sensu/conf.d/checks/. In this example, i'll be creating a vmware metrics check that leverages the elastic extension.
```
{
  "checks": {
    "VMware-Metrics": {
      "type": "metric",
      "refresh": 86400,
      "interval": 60,
      "handlers": [
        "elastic"
      ],
      "subscribers": [
        "linux-vmware"
      ],
      "occurrences": 5,
      "standalone": false,
      "command": "/usr/bin/php /etc/sensu/plugins/virtual_machine_metrics.php"
    }
  }
}
```
Notice the handler is configured to use elastic instead of default.

4. Now that sensu is configured to use our extension, and we have a metric created to leverage it, we need to configure elasticsearch. To do this, we must create the template and the index with the following two commands. (This must be run on th elasticsearch system.
```
./apply_sensu_template.sh
./recreate_sensu_metrics_index.sh
```
These scripts are used to apply the appropriate template to elasticsearch (Prevents hostnames from being truncated when it reaches a hyphen, etc.), and creates the index called sensu-metrics.

5. The only other thing you need to do is restart the sensu services and metrics should start flowing.

zephyr
======
Zephyr is a system that generates a JSON feed of discovered information about EC2 instances for a configured account, suitable for running via cron, that can then be consumed by a lookup tool for informational purposes, or for executing SSH commands across multiple nodes (a la mssh, knife ssh, rundeck, etc).

Requirements:
-------------

 * parseconfig
 * aws-sdk-v1
 * json
 * net/ssh/multi

Configuration:
--------------
Create a ~/.zephyr/config file. Supported attributes at this time are:

|`json_feed = /var/www/html/zephyr.json`|(this specifies where on the filesystem to write the JSON file)|
|||
|`[aws]`||
|`aws_region_ap-northeast-1=skip`|(skip polling the ap-northeast-1 EC2 region; if you have no nodes there, why bother iterating over it?)|

TODO:
-----

 * Create an awslookup tool that will either search all fields or match on a specific field
 * Create an awsssh tool that will execute commands on all matching nodes, with similar syntax to awslookup

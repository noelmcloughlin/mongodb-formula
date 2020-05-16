# -*- coding: utf-8 -*-
# vim: ft=yaml
---
mongodb:
  wanted:
    # choose what you want
    component:
      - mongod
      - mongos
      - dbtools
      - shell
    gui:
      - robo3t
      - compass
    connectors:
      - bi
      - kafka
  pkg:
    use_upstream_repo: false
    use_upstream_package: false
    use_upstream_archive: true
  linux:
    altpriority: 10000

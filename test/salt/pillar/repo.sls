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
    use_upstream_repo: true
    use_upstream_package: true
    use_upstream_archive: false
  linux:
    altpriority: 10000

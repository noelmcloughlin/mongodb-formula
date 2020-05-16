# -*- coding: utf-8 -*-
# vim: ft=sls

{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ "/map.jinja" import mongodb as m with context %}

    {%- if grains.kernel|lower in ('linux', 'darwin',) %}

include:
  - .{{ 'archive' if m.pkg.use_upstream_archive else 'package' }}
  - .config
  - .service
  - .connectors
  - .gui

    {%- else %}

m-not-available-to-install:
  test.show_notification:
    - text: |
        The Mongodb formula is unavailable for {{ salt['grains.get']('finger', grains.os_family) }}

    {%- endif %}

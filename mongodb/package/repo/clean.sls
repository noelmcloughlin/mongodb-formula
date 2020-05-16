# -*- coding: utf-8 -*-
# vim: ft=sls

{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ "/map.jinja" import mongodb as m with context %}

    {%- if m.pkg.use_upstream_repo and 'repo' in m.pkg and m.pkg.repo %}

mongodb-package-repo-clean-pkgrepo-managed:
  pkgrepo.absent:
    - name: {{ m.pkg['repo']['name'] }}

    {%- endif %}

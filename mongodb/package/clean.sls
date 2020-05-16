# -*- coding: utf-8 -*-
# vim: ft=sls

{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ "/map.jinja" import mongodb as m with context %}

{%- set sls_config_clean = tplroot ~ '.config.clean' %}
{%- set sls_service_clean = tplroot ~ '.service.clean' %}
{%- set sls_repo_clean = tplroot ~ '.package.repo.clean' %}

include:
  - {{ sls_config_clean }}
  - {{ sls_service_clean }}

    {%- for name in m.wanted.component %}

mongodb-package-clean-{{ name }}-removed:
  pip.removed:
    - name: pymongo
  pkg.removed:
    - name: {{ m.pkg.component[name].get('name', name) }}
    - require:
      - sls: {{ sls_config_clean }}
      - sls: {{ sls_service_clean }}

    {%- endfor %}

# -*- coding: utf-8 -*-
# vim: ft=sls

{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ "/map.jinja" import mongodb as m with context %}

{%- set sls_service_running = tplroot ~ '.service.running' %}
{%- set sls_repo_install = tplroot ~ '.package.repo.install' %}

include:
  - {{ sls_service_running }}
  - {{ sls_repo_install }}

mongodb-package-install-prerequisites:
  pkg.installed:
    - names: {{ m.pkg.deps|json }}
  pip.installed:
    - name: pymongo
    - reload_modules: True
    - require:
      - pkg: mongodb-package-install-prerequisites

    {%- for name in m.wanted.component %}

mongodb-package-install-{{ name }}-installed:
  pkg.installed:
    - name: {{ m.pkg.component[name].get('name', name) }}
    - require:
      - sls: {{ sls_repo_install }}
    - require_in:
      - sls: {{ sls_service_running }}
    - reload_modules: true

    {%- endfor %}

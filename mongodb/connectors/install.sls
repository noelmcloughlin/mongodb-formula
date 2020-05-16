# -*- coding: utf-8 -*-
# vim: ft=sls

{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ "/map.jinja" import mongodb as m with context %}
{%- from tplroot ~ "/files/macros.jinja" import format_kwargs with context %}
{%- from tplroot ~ "/libtofs.jinja" import files_switch with context %}
{%- set sls_archive_install = tplroot ~ '.archive.install' %}
{%- set sls_package_install = tplroot ~ '.package.install' %}

include:
  - {{ sls_archive_install if m.pkg.use_upstream_archive else sls_package_install }}

    {%- for name in m.wanted.connectors %}
        {%- if 'archive' in m.pkg.connectors[name] and m.pkg.connectors[name]['archive'] %}

mongodb-connectors-install-{{ name }}:
  file.directory:
    - name: {{ m.pkg.connectors[name]['path'] }}
    - user: {{ m.identity.rootuser }}
    - group: {{ m.identity.rootgroup }}
    - mode: '0755'
    - makedirs: True
    - require_in:
      - archive: mongodb-connectors-install-{{ name }}
    - recurse:
        - user
        - group
        - mode
  archive.extracted:
    {{- format_kwargs(m.pkg.connectors[name]['archive']) }}
    - trim_output: true
    - enforce_toplevel: false
    - options: --strip-components=1
    - retry: {{ m.retry_option|json }}
    - user: {{ m.identity.rootuser }}
    - group: {{ m.identity.rootgroup }}

        {%- endif %}
    {%- endfor %}

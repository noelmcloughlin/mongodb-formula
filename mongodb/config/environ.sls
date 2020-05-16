# -*- coding: utf-8 -*-
# vim: ft=sls

{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ "/map.jinja" import mongodb as m with context %}
{%- from tplroot ~ "/libtofs.jinja" import files_switch with context %}
{%- from tplroot ~ "/files/macros.jinja" import concat_environ %}
{%- set sls_archive_install = tplroot ~ '.archive.install' %}
{%- set sls_package_install = tplroot ~ '.package.install' %}

include:
  - {{ sls_archive_install if m.pkg.use_upstream_archive else sls_package_install }}

    {%- for name in m.wanted.component %}
        {%- if 'environ' in m.pkg.component[name] and m.pkg.component[name]['environ'] %}
            {%- if 'environ_file' in m.pkg.component[name] and m.pkg.component[name]['environ_file'] %}

mongodb-config-install-{{ name }}-environ_file:
  file.managed:
    - name: {{ m.pkg.component[name]['environ_file'] }}
    - source: {{ files_switch(['environ.sh.jinja'],
                              lookup='mongodb-config-install-' ~ name ~ '-environ_file'
                 )
              }}
    - mode: 640
    - user: {{ m.identity.rootuser }}
    - group: {{ m.identity.rootgroup }}
    - makedirs: True
    - template: jinja
    - context:
        path: {{ m.pkg.component[name]['path']|json }}
        environ: {{ m.pkg.component[name]['environ']|json }}
    - watch_in:
      - service: mongodb-service-running-{{ name }}
    - require:
      - sls: {{ sls_archive_install if m.pkg.use_upstream_archive else sls_package_install }}

            {%- endif %}
        {%- endif %}
    {%- endfor %}

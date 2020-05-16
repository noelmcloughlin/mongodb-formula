# -*- coding: utf-8 -*-
# vim: ft=sls

{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ "/map.jinja" import mongodb as m with context %}
{%- set sls_alternatives_clean = tplroot ~ '.archive.alternatives.clean' %}
{%- set sls_service_clean = tplroot ~ '.service.clean' %}

include:
  - {{ sls_service_clean }}
  - {{ sls_alternatives_clean }}

mongodb-archive-clean-prerequisites:
  file.absent:
    - name: {{ m.dir.var }}
  pip.removed:
    - name: pymongo

    {%- for name in m.wanted.component %}
        {%- if 'path' in m.pkg.component[name] %}

mongodb-archive-clean-{{ name }}:
  file.absent:
  - name: {{ m.pkg.component[name]['path'] }}

        {%- endif %}
        {%- if m.linux.altpriority|int <= 0 or grains.os_family|lower in ('macos', 'arch') %}
            {%- if 'commands' in m.pkg.component[name] and m.pkg.component[name]['commands'] is iterable %}
                {%- for cmd in m.pkg.component[name]['commands'] %}

mongodb-archive-clean-{{ name }}-file-symlink-{{ cmd }}:
  file.absent:
    - names:
      - {{ m.dir.symlink }}/bin/{{ cmd }}
      - {{ m.dir.symlink }}/sbin/{{ cmd }}
      - {{ m.dir.var }}/{{ name }}
      - {{ m.dir.service }}/{{ name }}.service
    - require:
      - sls: {{ sls_alternatives_clean }}
      - sls: {{ sls_service_clean }}
    - require_in:
      - user: mongodb-archive-clean-{{ name }}-user-group

                {%- endfor %}
            {%- endif %}
        {%- endif %}
    {%- endfor %}

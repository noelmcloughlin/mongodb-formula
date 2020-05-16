# -*- coding: utf-8 -*-
# vim: ft=sls

{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ "/map.jinja" import mongodb as m with context %}
{%- set service_files = ['/tmp/dummy_file_named_dummy',] %}

    {%- for name in m.wanted.component %}
        {%- if 'service' in m.pkg.component[name] and m.pkg.component[name]['service'] %}
            {%- set service_name = m.pkg.component[name]['service']['get'](name, {}).get('name', name) %}

mongodb-service-clean-{{ name }}:
  service.dead:
    - name: {{ service_name }}
    - enable: False
            {%- if grains.kernel|lower == 'linux' %}
    - onlyif: systemctl list-units | grep {{ service_name }} >/dev/null 2>&1
            {%- endif %}
  file.absent:
    - name: {{ m.dir.service }}/{{ name }}.service
    - require:
      - service: mongodb-service-clean-{{ name }}
  cmd.run:
    - onlyif: {{ grains.kernel|lower == 'linux' }}
    - name: systemctl daemon-reload
    - require:
      - file: mongodb-service-clean-{{ name }}

        {%- endif %}

        {# CONFIG FILES #}
        {%- if name in ('mongod', 'mongos',) %}
            {%- set config = m.pkg.component[name]['config'] %}
            {%- if 'processManagement' in config and config['processManagement']['pidFilePath'] %}
                {%- do service_files.add(config['processManagement']['pidFilePath']) %}
            {%- endif %}
            {%- if 'storage' in config and 'dbPath' in config['storage'] %}
                {%- do service_files.add(config['storage']['dbPath']) %}
            {%- endif %}
            {%- if 'schema' in config and 'path' in config['schema'] %}
                {%- do service_files.add(config['schema']['path']) %}
            {%- endif %}
            {%- if 'systemLog' in config and 'path' in config['systemLog'] %}
                {%- do service_files.add(config['systemLog']['path']) %}
                {%- do service_files.add(/etc/logrotate.d/mongodb_{{ service_name }}) %}
            {%- endif %}
        {%- endif %}
    {%- endfor %}

mongodb-service-clean-filesystem:
  file.absent:
    - names: {{ service_files }}

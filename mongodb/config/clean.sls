# -*- coding: utf-8 -*-
# vim: ft=sls

{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ "/map.jinja" import mongodb as m with context %}
{%- set sls_service_clean = tplroot ~ '.service.clean' %}

include:
  - {{ sls_service_clean }}

    {%- for name in m.wanted.component %}

mongodb-config-clean-{{ name }}:
    - names:
      - {{ m.dir.etc }}/{{ name }}.yml
      - {{ m.pkg.component[name]['environ_file'] }}
        {%- if 'user' in m.pkg.component[name] and m.pkg.component[name]['user'] %}
  user.absent:
    - name: {{ m.pkg.component[name]['user'] }}
                {%- if grains.os_family == 'MacOS' %}
    - onlyif: /usr/bin/dscl . list /Users | grep {{ name }} >/dev/null 2>&1
                {%- endif %}
  group.absent:
    - name: {{ m.pkg.component[name]['group'] }}
    - require:
       - {{ sls_config_clean }}
        {%- endif %}

    {%- endfor %}

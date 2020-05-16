# -*- coding: utf-8 -*-
# vim: ft=sls

{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ "/map.jinja" import mongodb as m with context %}

    {%- for name in m.wanted.connectors %}
        {%- if 'archive' in m.pkg.connectors[name] and m.pkg.connectors[name]['archive'] %}

mongodb-connectors-clean-{{ name }}:
  file.absent:
    - name: {{ m.pkg.connectors[name]['path'] }}

        {%- endif %}
    {%- endfor %}

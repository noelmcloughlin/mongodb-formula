# -*- coding: utf-8 -*-
# vim: ft=sls

{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ "/map.jinja" import mongodb as m with context %}

    {%- for name in m.wanted.component %}
        {%- if 'user' in m.pkg.component[name] and m.pkg.component[name]['user'] %}

mongodb-config-user-install-{{ name }}-user-present:
  group.present:
    - name: {{ m.pkg.component[name]['group'] }}
    - require_in:
      - user: mongodb-config-user-install-{{ name }}-user-present
  user.present:
    - name: {{ m.pkg.component[name]['user'] }}
    - shell: /bin/false
    - createhome: false
    - groups:
      - {{ m.pkg.component[name]['user'] }}
              {%- if grains.os_family == 'MacOS' %}
    - unless: /usr/bin/dscl . list /Users | grep {{ name }} >/dev/null 2>&1
              {%- endif %}

        {%- endif %}
    {%- endfor %}

# -*- coding: utf-8 -*-
# vim: ft=sls

{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ "/map.jinja" import mongodb as m with context %}

include:
  - .macapp.clean

    {%- for name in m.wanted.gui %}
        {%- if 'archive' in m.pkg.gui[name] and m.pkg.gui[name]['archive'] %}

mongodb-gui-archive-clean-{{ name }}:
  file.absent:
    - name: {{ m.pkg.gui[name]['path'] }}

           {%- if m.linux.altpriority|int <= 0 or grains.os_family|lower in ('macos', 'arch') %}
                {%- if 'commands' in m.pkg.gui[name] and m.pkg.gui[name]['commands'] is iterable %}
                    {%- for cmd in m.pkg.gui[name]['commands'] %}

mongodb-gui-archive-clean-{{ name }}-file-symlink-{{ cmd }}:
  file.absent:
    - names:
      - {{ m.dir.symlink }}/bin/{{ cmd }}
      - {{ m.dir.var }}/{{ name }}
      - {{ m.dir.service }}/{{ name }}.service
    - require:
      - sls: {{ sls_alternatives_clean }}
      - sls: {{ sls_service_clean }}
    - require_in:
      - user: mongodb-gui-archive-clean-{{ name }}-user-group
                    {%- endfor %}
                {%- endif %}
            {%- endif %}

        {%- endif %}
    {%- endfor %}

# -*- coding: utf-8 -*-
# vim: ft=sls

{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ "/map.jinja" import mongodb as m with context %}
{%- from tplroot ~ "/files/macros.jinja" import format_kwargs with context %}
{%- from tplroot ~ "/libtofs.jinja" import files_switch with context %}

    {%- for name in m.wanted.gui %}
        {%- if 'archive' in m.pkg.gui[name] and m.pkg.gui[name]['archive'] %}

mongodb-gui-install-{{ name }}:
  file.directory:
    - name: {{ m.pkg.gui[name]['path'] }}
    - user: {{ m.identity.rootuser }}
    - group: {{ m.identity.rootgroup }}
    - mode: '0755'
    - makedirs: True
    - require_in:
      - archive: mongodb-gui-install-{{ name }}
    - recurse:
        - user
        - group
        - mode
  archive.extracted:
    {{- format_kwargs(m.pkg.gui[name]['archive']) }}
    - trim_output: true
    - enforce_toplevel: false
    - options: --strip-components=1
    - retry: {{ m.retry_option|json }}
    - user: {{ m.identity.rootuser }}
    - group: {{ m.identity.rootgroup }}

            {%- if m.linux.altpriority|int <= 0 or grains.os_family|lower in ('macos', 'arch') %}
                {%- if 'commands' in m.pkg.gui[name]  and m.pkg.gui[name]['commands'] is iterable %}
                    {%- for cmd in m.pkg.gui[name]['commands'] %}

mongodb-gui-archive-install-{{ name }}-file-symlink-{{ cmd }}:
  file.symlink:
    - name: {{ m.dir.symlink }}/bin/{{ cmd }}
    - target: {{ m.pkg.gui[name]['path'] }}/bin/{{ cmd }}
    - force: True
    - require:
      - archive: mongodb-gui-archive-install-{{ name }}
                    {%- endfor %}
                {%- endif %}
            {%- endif %}

        {%- endif %}
    {%- endfor %}

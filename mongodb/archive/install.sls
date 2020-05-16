# -*- coding: utf-8 -*-
# vim: ft=sls

{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ "/map.jinja" import mongodb as m with context %}
{%- from tplroot ~ "/files/macros.jinja" import format_kwargs with context %}
{%- from tplroot ~ "/libtofs.jinja" import files_switch with context %}
{%- set sls_config_users = tplroot ~ '.config.users' %}

include:
  - {{ sls_config_users }}

mongodb-archive-install-prerequisites:
  pkg.installed:
    - names: {{ m.pkg.deps|json }}
  pip.installed:
    - name: pymongo
    - reload_modules: True
    - require:
      - pkg: mongodb-archive-install-prerequisites
  file.directory:
    - name: {{ m.dir.var }}
    - user: {{ m.pkg.component.mongod.user }}
    - group: {{ m.pkg.component.mongod.group }}
    - mode: '0755'
    - makedirs: True
    - require:
      - sls: {{ sls_config_users }}

    {%- for name in m.wanted.component %}
        {%- if 'path' in m.pkg.component[name] %}

mongodb-archive-install-{{ name }}:
  file.directory:
    - name: {{ m.pkg.component[name]['path'] }}
    - user: {{ m.identity.rootuser }}
    - group: {{ m.identity.rootgroup }}
    - mode: '0755'
    - makedirs: True
    - require:
      - file: mongodb-archive-install-prerequisites
    - require_in:
      - archive: mongodb-archive-install-{{ name }}
    - recurse:
        - user
        - group
        - mode
  archive.extracted:
    {{- format_kwargs(m.pkg.component[name]['archive']) }}
    - trim_output: true
    - enforce_toplevel: false
    - options: --strip-components=1
    - retry: {{ m.retry_option|json }}
    - user: {{ m.identity.rootuser }}
    - group: {{ m.identity.rootgroup }}
    - require:
      - file: mongodb-archive-install-{{ name }}

            {%- if m.linux.altpriority|int <= 0 or grains.os_family|lower in ('macos', 'arch') %}
                {%- if 'commands' in m.pkg.component[name]  and m.pkg.component[name]['commands'] is iterable %}
                    {%- for cmd in m.pkg.component[name]['commands'] %}

mongodb-archive-install-{{ name }}-file-symlink-{{ cmd }}:
  file.symlink:
                        {%- if 'service' in m.pkg.component[name] %}
    - name: {{ m.dir.symlink }}/sbin/{{ cmd }}
                        {%- else %}
    - name: {{ m.dir.symlink }}/bin/{{ cmd }}
                        {% endif %}
    - target: {{ m.pkg.component[name]['path'] }}/{{ cmd }}
    - force: True
    - require:
      - archive: mongodb-archive-install-{{ name }}

                    {%- endfor %}
                {%- endif %}
            {%- endif %}
            {%- if 'service' in m.pkg.component[name] and m.pkg.component[name]['service'] is mapping %}

mongodb-archive-install-{{ name }}-file-directory:
  file.directory:
    - name: {{ m.dir.var }}/{{ name }}
    - user: {{ name }}
    - group: {{ name }}
    - mode: '0755'
    - makedirs: True
    - require:
      - sls: {{ sls_config_users }}

                {%- if grains.kernel|lower == 'linux' and 'config_file' in m.pkg.component[name] %}

mongodb-archive-install-{{ name }}-managed-service:
  file.managed:
    - name: {{ m.dir.service }}/{{ name }}.service
    - source: {{ files_switch(['systemd.ini.jinja'],
                              lookup='mongodb-archive-install-' ~  name ~ '-managed-service'
                 )
              }}
    - mode: '0644'
    - user: {{ m.identity.rootuser }}
    - group: {{ m.identity.rootgroup }}
    - makedirs: True
    - template: jinja
    - context:
        desc: mongodb - {{ name }} service
        name: {{ name }}
        user: {{ m.pkg.component.mongod.user if 'user' not in m.pkg.component[name] else m.pkg.component[name]['user'] }}  # noqa 204
        group: {{ m.pkg.component.mongod.group if 'group' not in m.pkg.component[name] else m.pkg.component[name]['group'] }}  # noqa 204
        workdir: {{ m.dir.var }}/{{ name }}
        stop: ''
        start: {{ m.pkg.component[name]['path'] }}/bin/{{ name }}
    - require:
      - file: mongodb-archive-install-{{ name }}-file-directory
      - archive: mongodb-archive-install-{{ name }}
      - sls: {{ sls_config_users }}
  cmd.run:
    - name: systemctl daemon-reload
    - require:
      - archive: mongodb-archive-install-{{ name }}

                {%- endif %}
            {%- endif %}
        {%- endif %}
    {%- endfor %}

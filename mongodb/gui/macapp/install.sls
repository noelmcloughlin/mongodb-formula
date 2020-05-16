# -*- coding: utf-8 -*-
# vim: ft=sls

{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ "/map.jinja" import m with context %}

    {%- for name in m.wanted.gui %}
        {%- if 'macapp' in m.pkg.gui[name] and m.pkg.gui[name]['macapp'] %}

mongodb-gui-{{ name }}-macapp-install:
  pkg.installed:
    - name: curl
  file.directory:
    - names:
      - {{ m.pkg.gui[name]['path'] }}
      - {{ m.dir.tmp }}
    - user: {{ m.identity.rootuser }}
    - group: {{ m.identity.rootgroup }}
    - mode: '0755'
    - makedirs: True
    - require_in:
      - macpackage: mongodb-gui-{{ name }}-macapp-install
    - recurse:
        - user
        - group
        - mode
  cmd.run:
    - name: curl -Lo {{ m.dir.tmp }}/{{ name ~  m.pkg.gui[name]['version'] }} {{ m.pkg.gui[name]['macapp']['source'] }}
    - unless: test -f {{ m.dir.tmp }}/{{ name ~ m.pkg.gui[name]['version'] }}
    - require:
      - file: mongodb-gui-{{ name }}-macapp-install
      - pkg: mongodb-gui-{{ name }}-macapp-install
    - retry: {{ m.retry_option|json }}

      # Check the hash sum. If check fails remove
      # the file to trigger fresh download on rerun
mongodb-gui-{{ name }}-macapp-install-checksum:
  module.run:
    - onlyif: {{ m.pkg.gui[name]['macapp]['source_hash'] }}
    - name: file.check_hash
    - path: {{ m.dir.tmp }}/{{ name ~ m.pkg.gui[name]['version'] }}
    - file_hash: {{ m.pkg.gui[name]['macapp]['source_hash'] }}
    - require:
      - cmd: mongodb-gui-{{ name }}-macapp-install-curl
    - require_in:
      - macpackage: mongodb-gui-{{ name }}-macapp-install-macpackage
  file.absent:
    - name: {{ m.dir.tmp }}/{{ name ~ m.pkg.gui[name]['version'] }}
    - onfail:
      - module: mongodb-gui-{{ name }}-macapp-install-checksum

mongodb-gui-{{ name }}-macapp-install-macpackage:
  macpackage.installed:
    - name: {{ m.dir.tmp }}/{{ name ~ m.pkg.gui[name]['version'] }}
    - store: True
    - dmg: True
    - app: True
    - force: True
    - allow_untrusted: True
    - onchanges:
      - cmd: mongodb-gui-{{ name }}-macapp-install
  file.managed:
    - name: /tmp/mac_shortcut.sh
    - source: salt://m/files/mac_shortcut.sh
    - mode: 755
    - template: jinja
    - context:
      appdir: {{ m.dir.macapp }}
      appname: {{ m.pkg.gui[name]['name'] }}
      user: {{ m.identity.rootuser }}
      homes: {{ m.dir.homes }}
  cmd.run:
    - name: /tmp/mac_shortcut.sh
    - runas: {{ m.identity.rootuser }}
    - require:
      - file: mongodb-gui-{{ name }}-macapp-install-macpackage

            {%- if 'commands' in m.pkg.gui[name] and m.pkg.gui[name]['commands'] is iterable %}
                {%- for cmd in m.pkg.gui[name]['commands'] %}

mongodb-gui-macapp-install-{{ name }}-file-symlink-{{ cmd }}:
  file.symlink:
    - name: {{ m.dir.symlink }}/bin/{{ cmd }}
    - target: {{ m.pkg.gui[name]['path'] }}/bin/{{ cmd }}
    - force: True
    - require:
      - macapp: mongodb-gui-macapp-install-{{ name }}
                {%- endfor %}
            {%- endif %}
        {%- else %}

mongodb-gui-{{ name }}-macapp-install-unavailable:
  test.show_notification:
    - text: |
        The mongodb {{ name }} macpackage is not available on MacOS

        {%- endif %}
    {%- endfor %}

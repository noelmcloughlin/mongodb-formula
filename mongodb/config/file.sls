# -*- coding: utf-8 -*-
# vim: ft=sls

{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ "/map.jinja" import mongodb as m with context %}
{%- from tplroot ~ "/libtofs.jinja" import files_switch with context %}

{%- set sls_archive_install = tplroot ~ '.archive.install' %}
{%- set sls_package_install = tplroot ~ '.package.install' %}
{%- set sls_config_users = tplroot ~ '.config.users' %}

include:
  - {{ sls_archive_install if m.pkg.use_upstream_archive else sls_package_install }}
  - {{ sls_config_users }}

mongodb-config-file-etc-file-directory:
  file.directory:
    - name: {{ m.dir.etc }}
    - user: {{ m.identity.rootuser }}
    - group: {{ m.identity.rootgroup }}
    - mode: '0755'
    - makedirs: True
    - require:
      - sls: {{ sls_archive_install if m.pkg.use_upstream_archive else sls_package_install }}

mongodb-config-kernel-disable-transparent-hugepages:
  file.managed:
    - name: /etc/init.d/disable-transparent-hugepages
    - source: salt://mongodb/files/disable-transparent-hugepages.init
    - unless: test -f /etc/init.d/disable-transparent-hugepages
    - onlyif:
      - {{ grains.kernel|lower == 'linux' }}
      - {{ m.wanted.disable_transparent_hugepages }}
    - mode: '0755'
    - makedirs: True
  cmd.run:
    - name: echo never >/sys/kernel/mm/transparent_hugepage/enabled
    - require:
      - file: mongodb-config-kernel-disable-transparent-hugepages

    {%- for name in m.wanted.component %}
        {%- if 'config' in m.pkg.component[name] and m.pkg.component[name]['config'] %}
            {%- if 'config_file' in m.pkg.component[name] and m.pkg.component[name]['config_file'] %}

mongodb-config-file-{{ name }}-file-managed:
  file.managed:
    - name: {{ m.dir.etc }}/{{ name }}.yml
    - source: {{ files_switch(['config.yml.jinja'],
                              lookup='mongodb-config-file-' ~ name ~ '-file-managed'
                 )
              }}
    - mode: 644
    - user: {{ name }}
    - group: {{ name }}
    - makedirs: True
    - template: jinja
    - context:
        config: {{ m.pkg.component[name]['config']|json }}
    - require:
      - file: mongodb-config-file-etc-file-directory
      - user: mongodb-config-user-install-{{ name }}-user-present
      - group: mongodb-config-user-install-{{ name }}-user-present
    - watch_in:
      - service: mongodb-service-running-{{ name }}
                {%- if 'selinux' in m.wanted and m.wanted.selinux %}
  selinux.fcontext_policy_present:
    - name: '{{ m.dir.etc }}(/.*)?'
    - sel_type: etc_t
    - require:
      - file: mongodb-config-file-{{ name }}-file-managed
                {%- endif %}

            {%- endif %}
        {%- endif %}
    {%- endfor %}

# -*- coding: utf-8 -*-
# vim: ft=sls

{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ "/map.jinja" import mongodb as m with context %}
{%- set sls_config_file = tplroot ~ '.config.file' %}
{%- set sls_config_environ = tplroot ~ '.config.environ' %}
{%- set sls_config_users = tplroot ~ '.config.users' %}

include:
  - {{ sls_config_users }}
  - {{ sls_config_file }}
  - {{ sls_config_environ }}

    {%- if grains.kernel|lower in ('linux', 'macos',) %}

mongodb-config-disable-transparent-huge-pages:
  file.managed:
    - name: /etc/init.d/disable-transparent-hugepages
    - source: salt://mongodb/files/disable-transparent-hugepages.init
    - unless: test -f /etc/init.d/disable-transparent-hugepages
    - onlyif: {{ m.wanted.disable_transparent_hugepages }}
    - mode: '0755'
    - makedirs: True
  cmd.run:
    - name: echo never >/sys/kernel/mm/transparent_hugepage/enabled
    - onlyif: {{ m.wanted.disable_transparent_hugepages }}

        {%- for name in m.wanted.component %}
            {%- if 'service' in m.pkg.component[name] and m.pkg.component[name]['service'] %}
                {%- set service_name = m.pkg.component[name]['service']['get'](name, {}).get('name', name) %}
                {%- if service_name in ('mongod', 'mongos',) %}
                    {%- if 'config' in m.pkg.component[name] and m.pkg.component[name]['config'] %}
                        {%- set config = m.pkg.component[name]['config'] %}
                        {%- set updated_files = [] %}
                        {%- if 'processManagement' in config and config['processManagement']['pidFilePath'] %}
                            {%- do updated_files.append(config['processManagement']['pidFilePath']) %}

mongodb-config-{{ name }}-install-pidpath:
  file.directory:
    - name: {{ config['processManagement']['pidFilePath'] }}
    - user: {{ m.pkg.component[name]['user'] }}
    - group: {{ m.pkg.component[name]['group'] }}
    - dir_mode: '0775'
    - makedirs: True
    - recurse:
      - user
      - group
    - require:
      - sls: {{ sls_config_users }}
                            {%- if 'selinux' in m.wanted and m.wanted.selinux %}
  selinux.fcontext_policy_present:
    - name: '{{ config['processManagement']['pidFilePath'] }}(/.*)?'
    - sel_type: {{ service_name }}_var_t
    - require_in:
      - selinux: mongodb-service-running-{{ name }}-selinux-applied
                            {%- endif %}
                        {%- endif %}

                        {%- if 'storage' in config and 'dbPath' in config['storage'] %}
                            {%- do updated_files.append(config['storage']['dbPath']) %}

mongodb-config-{{ name }}-install-datapath:
  file.directory:
    - name: {{ config['storage']['dbPath'] }}
    - user: {{ m.pkg.component[name]['user'] }}
    - group: {{ m.pkg.component[name]['group'] }}
    - dir_mode: '0775'
    - makedirs: True
    - recurse:
      - user
      - group
    - require:
      - sls: {{ sls_config_users }}
                            {%- if 'selinux' in m.wanted and m.wanted.selinux %}
  selinux.fcontext_policy_present:
    - name: '{{ config['storage']['dbPath'] }}(/.*)?'
    - sel_type: {{ service_name }}_var_lib_t
    - require:
      - file: mongodb-config-{{ name }}-install-datapath
    - require_in:
      - selinux: mongodb-service-running-{{ name }}-selinux-applied
                            {%- endif %}

                        {%- endif %}
                        {%- if 'schema' in config and 'path' in config['schema'] %}
                            {%- do updated_files.append(config['schema']['path']) %}

mongodb-config-{{ name }}-install-schemapath:
  file.directory:
    - name: {{ config['schema']['path'] }}
    - user: {{ m.pkg.component[name]['user'] }}
    - group: {{ m.pkg.component[name]['group'] }}
    - dir_mode: '0775'
    - makedirs: True
    - recurse:
      - user
      - group
    - require:
      - sls: {{ sls_config_users }}
                            {%- if 'selinux' in m.wanted and m.wanted.selinux %}
  selinux.fcontext_policy_present:
    - name: '{{ config['schema']['path'] }}(/.*)?'
    - sel_type: etc_t
    - require:
      - file: mongodb-config-{{ name }}-install-schemapath
    - require_in:
      - selinux: mongodb-service-running-{{ name }}-selinux-applied
                            {%- endif %}

                        {%- endif %}
                        {%- if 'systemLog' in config and 'path' in config['systemLog'] %}
                            {%- do updated_files.append(config['systemLog']['path']) %}

mongodb-config-{{ name }}-install-syslogpath:
  file.directory:
    - name: {{ config['systemLog']['path'] }}
    - user: {{ m.pkg.component[name]['user'] }}
    - group: {{ m.pkg.component[name]['group'] }}
    - dir_mode: '0775'
    - makedirs: True
    - require:
      - sls: {{ sls_config_users }}
    - recurse:
      - user
      - group
                            {%- if 'selinux' in m.wanted and m.wanted.selinux %}
  selinux.fcontext_policy_present:
    - name: '{{ logpath }}(/.*)?'
    - sel_type: {{ service_name }}_var_log_t
    - require_in:
      - selinux: mongodb-service-running-{{ name }}-selinux-applied
                            {%- endif %}
                            {%- do updated_files.append('/etc/logrotate.d/mongodb_' ~ service_name ) %}

mongodb-config-{{ name }}-install-logrotate:
  file.managed:
    - name: /etc/logrotate.d/mongodb_{{ service_name }}
    - unless: ls /etc/logrotate.d/mongodb_{{ service_name }}
    - user: root
    - group: {{ 'wheel' if grains.os in ('MacOS',) else 'root' }}
    - mode: '0440'
    - makedirs: True
    - source: salt://mongodb/files/logrotate.jinja
    - context:
        svc: {{ service_name }}
        pattern: {{ config['systemLog']['path'] }}
        pidpath: {{ config['processManagement']['pidFilePath'] }}
        days: 7
                            {%- if 'selinux' in m.wanted and m.wanted.selinux %}
  selinux.fcontext_policy_present:
    - name: '/etc/logrotate.d/mongodb_{{ svc }}(/.*)?'
    - sel_type: etc_t
    - require_in:
      - selinux: mongodb-service-running-{{ name }}-selinux-applied
    - recursive: True
                            {%- endif %}
                        {%- endif %}
                        {%- if 'selinux' in m.wanted and m.wanted.selinux %}

mongodb-service-running-{{ name }}-selinux-applied:
  selinux.fcontext_policy_applied:
  - names: {{ updated_files }}
                        {%- endif %}
                    {%- endif %}

mongodb-service-running-{{ name }}-unmasked:
  service.unmasked:
    - name: {{ service_name }}
    - onlyif:
       - {{ grains.kernel|lower == 'linux' }}
       - systemctl list-units | grep {{ service_name }} >/dev/null 2>&1
    - require_in:
      - service: mongodb-service-running-{{ name }}
    - require:
      - sls: {{ sls_config_file }}

                    {%- if m.wanted.firewall and 'firewall' in m.pkg.component[name] %}
mongodb-service-running-{{ name }}-firewalld:
  pkg.installed:
    - name: firewalld
    - reload_modules: true
  firewalld.present:
    - name: public
    - ports: {{ m.pkg.component[name]['firewall']['ports']|json }}
    - require:
      - service: mongodb-service-running-{{ name }}
  service.running:
    - name: firewalld
    - onlyif: systemctl list-units | grep firewalld >/dev/null 2>&1
    - enable: True
    - require:
      - sls: {{ sls_config_file }}
                    {%- endif %}

mongodb-service-running-{{ name }}:
  service.running:
    - name: {{ service_name }}
                    {%- if grains.kernel|lower == 'linux' %}
    - onlyif: systemctl list-units | grep {{ service_name }} >/dev/null 2>&1
                    {%- endif %}
    - enable: True
    - require:
      - sls: {{ sls_config_file }}

                {%- endif %}
            {%- endif %}
        {%- endfor %}
    {%- endif %}

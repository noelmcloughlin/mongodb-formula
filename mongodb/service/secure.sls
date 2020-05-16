# -*- coding: utf-8 -*-
# vim: ft=sls

{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ "/map.jinja" import mongodb as m with context %}
{%- set sls_config_users = tplroot ~ '.config.users' %}

include:
  - {{ sls_config_users }}

mongodb-service-secure-prerequisites:
  pkg.installed:
    - names:
      - firewalld
                {%- if grains.os_family in ('RedHat',) %}
      - policycoreutils-python
      - selinux-policy-targeted
                {%- endif %}
    - reload_modules: true
    - onlyif: {{ grains.kernel|lower == 'linux' }}

    {%- for name in m.wanted.component %}
        {%- if name in ('mongod', 'mongos',) %}
            {%- set config = m.pkg.component[name]['config'] %}
            {%- set service_files = [] %}

            {%- if 'processManagement' in config and config['processManagement']['pidFilePath'] %}
                {%- do service_files.append(config['processManagement']['pidFilePath']) %}

mongodb-service-secure-{{ name }}-install-pidpath:
  file.directory:
    - name: {{ config['processManagement']['pidFilePath'] }}
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
    - name: '{{ config['processManagement']['pidFilePath'] }}(/.*)?'
    - sel_type: {{ name }}_var_t
    - require_in:
      - selinux: mongodb-service-secure-{{ name }}-selinux-applied
                {%- endif %}
            {%- endif %}

            {%- if 'storage' in config and 'dbPath' in config['storage'] %}
                {%- do service_files.append(config['storage']['dbPath']) %}

mongodb-service-secure-{{ name }}-install-datapath:
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
    - sel_type: {{ name }}_var_lib_t
    - require:
      - file: mongodb-service-secure-{{ name }}-install-datapath
    - require_in:
      - selinux: mongodb-service-secure-{{ name }}-selinux-applied
                {%- endif %}
            {%- endif %}

            {%- if 'schema' in config and 'path' in config['schema'] %}
                {%- do service_files.append(config['schema']['path']) %}

mongodb-service-secure-{{ name }}-install-schemapath:
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
      - file: mongodb-service-secure-{{ name }}-install-schemapath
    - require_in:
      - selinux: mongodb-service-secure-{{ name }}-selinux-applied
                {%- endif %}
            {%- endif %}

            {%- if 'systemLog' in config and 'path' in config['systemLog'] %}
                {%- do service_files.append(config['systemLog']['path']) %}
                {%- do service_files.append('/etc/logrotate.d/mongodb_' ~ name ) %}

mongodb-service-secure-{{ name }}-install-syslogpath:
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
    - sel_type: {{ name }}_var_log_t
    - require_in:
      - selinux: mongodb-service-secure-{{ name }}-selinux-applied
                {%- endif %}

mongodb-service-secure-{{ name }}-install-logrotate:
  file.managed:
    - name: /etc/logrotate.d/mongodb_{{ name }}
    - unless: ls /etc/logrotate.d/mongodb_{{ name }}
    - user: root
    - group: {{ 'wheel' if grains.os in ('MacOS',) else 'root' }}
    - mode: '0440'
    - makedirs: True
    - source: salt://mongodb/files/logrotate.jinja
    - context:
        svc: {{ name }}
        pattern: {{ config['systemLog']['path'] }}
        pidpath: {{ config['processManagement']['pidFilePath'] }}
        days: 7
                {%- if 'selinux' in m.wanted and m.wanted.selinux %}
  selinux.fcontext_policy_present:
    - name: '/etc/logrotate.d/mongodb_{{ svc }}(/.*)?'
    - sel_type: etc_t
    - require_in:
      - selinux: mongodb-service-secure-{{ name }}-selinux-applied
    - recursive: True
                {%- endif %}
            {%- endif %}
            {%- if 'selinux' in m.wanted and m.wanted.selinux %}

mongodb-service-secure-{{ name }}-selinux-applied:
  selinux.fcontext_policy_applied:
  - names: {{ service_files|json }}

            {%- endif %}
        {%- endif %}
        {%- if m.wanted.firewall and 'firewall' in m.pkg.component[name] %}

mongodb-service-secure-{{ name }}-firewall-present:
  firewalld.present:
    - name: public
    - ports: {{ m.pkg.component[name]['firewall']['ports']|json }}

        {%- endif %}
    {%- endfor %}

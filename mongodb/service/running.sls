# -*- coding: utf-8 -*-
# vim: ft=sls

{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ "/map.jinja" import data as d with context %}
{%- set sls_config_users = tplroot ~ '.config.users' %}
{%- set sls_software_install = tplroot ~ '.install' %}
{%- set formula = d.formula %}

include:
  - {{ sls_config_users }}
  - {{ sls_software_install }}

{{ formula }}-service-running-prerequisites:
  file.managed:
    - name: /etc/init.d/disable-transparent-hugepages
    - source: salt://{{ formula }}/files/disable-transparent-hugepages.init
    - unless: test -f /etc/init.d/disable-transparent-hugepages
    - onlyif: {{ d.wanted.disable_transparent_hugepages }}
    - mode: '0755'
    - makedirs: True
    - require:
      - sls: {{ sls_config_users }}
  cmd.run:
    - name: echo never >/sys/kernel/mm/transparent_hugepage/enabled
    - onlyif: {{ d.wanted.disable_transparent_hugepages }}
    - require:
      - file: {{ formula }}-service-running-prerequisites
        {%- if d.wanted.firewall %}
  pkg.installed:
    - name: firewalld
    - reload_modules: true
  service.running:
    - name: firewalld
    - onlyif: systemctl list-units | grep firewalld >/dev/null 2>&1
    - enable: True
    - require:
      - sls: {{ sls_config_users }}
        {%- endif %}

    {%- for comp in d.software_component_matrix %}
        {%- if comp in d.wanted and d.wanted is iterable and comp in d.pkg and d.pkg[comp] is mapping %}
            {%- for name,v in d.pkg[comp].items() %}
                {%- if name in d.wanted[comp] %}
                    {%- set software = d.pkg[comp][name] %}
                    {%- if 'service' in software and software['service'] is mapping %}
                        {%- set servicename = software['service']['get'](name, {}).get('name', name) %}
                        {%- if 'config' in software and software['config'] is mapping %}
                            {%- set config = software['config'] %}

                            {%- set service_files = [] %}
                            {%- if 'processManagement' in config and config['processManagement']['pidFilePath'] %}
                                {%- do service_files.append(config['processManagement']['pidFilePath']) %}

{{ formula }}-service-running-{{ comp }}-{{ servicename }}-install-pidpath:
  file.directory:
    - name: {{ config['processManagement']['pidFilePath'] }}
    - user: {{ software['user'] }}
    - group: {{ software['group'] }}
    - dir_mode: '0775'
    - makedirs: True
    - require:
      - sls: {{ sls_config_users }}
    - require_in:
      - service: {{ formula }}-service-running-{{ comp }}-{{ servicename }}
    - recurse:
      - user
      - group
                                {%- if 'selinux' in d.wanted and d.wanted.selinux %}
  selinux.fcontext_policy_present:
    - name: '{{ config['processManagement']['pidFilePath'] }}(/.*)?'
    - sel_type: {{ name }}_var_t
    - require_in:
      - selinux: {{ formula }}-service-running-{{ comp }}-{{ servicename }}-selinux-applied
                                {%- endif %}

                            {%- endif %}
                            {%- if 'storage' in config and 'dbPath' in config['storage'] %}
                                {%- do service_files.append(config['storage']['dbPath']) %}

{{ formula }}-service-running-{{ comp }}-{{ servicename }}-install-datapath:
  file.directory:
    - name: {{ config['storage']['dbPath'] }}
    - user: {{ software['user'] }}
    - group: {{ software['group'] }}
    - dir_mode: '0775'
    - makedirs: True
    - recurse:
      - user
      - group
    - require:
      - sls: {{ sls_config_users }}
    - require_in:
      - service: {{ formula }}-service-running-{{ comp }}-{{ servicename }}
                                {%- if 'selinux' in d.wanted and d.wanted.selinux %}
  selinux.fcontext_policy_present:
    - name: '{{ config['storage']['dbPath'] }}(/.*)?'
    - sel_type: {{ name }}_var_lib_t
    - require:
      - file: {{ formula }}-service-running-{{ comp }}-{{ servicename }}-install-datapath
    - require_in:
      - selinux: {{ formula }}-service-running-{{ comp }}-{{ servicename }}-selinux-applied
                                {%- endif %}

                            {%- endif %}
                            {%- if 'schema' in config and 'path' in config['schema'] %}
                                {%- do service_files.append(config['schema']['path']) %}

{{ formula }}-service-running-{{ comp }}-{{ servicename }}-install-schemapath:
  file.directory:
    - name: {{ config['schema']['path'] }}
    - user: {{ software['user'] }}
    - group: {{ software['group'] }}
    - dir_mode: '0775'
    - makedirs: True
    - recurse:
      - user
      - group
    - require:
      - sls: {{ sls_config_users }}
    - require_in:
      - service: {{ formula }}-service-running-{{ comp }}-{{ servicename }}
                                {%- if 'selinux' in d.wanted and d.wanted.selinux %}
  selinux.fcontext_policy_present:
    - name: '{{ config['schema']['path'] }}(/.*)?'
    - sel_type: etc_t
    - require:
      - file: {{ formula }}-service-running-{{ comp }}-{{ servicename }}-install-schemapath
    - require_in:
      - selinux: {{ formula }}-service-running-{{ comp }}-{{ servicename }}-selinux-applied
                                {%- endif %}

                            {%- endif %}
                            {%- if 'systemLog' in config and 'path' in config['systemLog'] %}
                                {%- do service_files.append(config['systemLog']['path']) %}
                                {%- do service_files.append('/etc/logrotate.d/{{ formula }}_' ~ name ) %}

{{ formula }}-service-running-{{ comp }}-{{ servicename }}-install-syslogpath:
  file.directory:
    - name: {{ config['systemLog']['path'] }}
    - user: {{ software['user'] }}
    - group: {{ software['group'] }}
    - dir_mode: '0775'
    - makedirs: True
    - require:
      - sls: {{ sls_config_users }}
    - recurse:
      - user
      - group
    - require_in:
      - service: {{ formula }}-service-running-{{ comp }}-{{ servicename }}
                                {%- if 'selinux' in d.wanted and d.wanted.selinux %}
  selinux.fcontext_policy_present:
    - name: '{{ logpath }}(/.*)?'
    - sel_type: {{ name }}_var_log_t
    - require_in:
      - selinux: {{ formula }}-service-running-{{ comp }}-{{ servicename }}-selinux-applied
                                {%- endif %}

{{ formula }}-service-running-{{ comp }}-{{ servicename }}-install-logrotate:
  file.managed:
    - name: /etc/logrotate.d/{{ formula }}_{{ name }}
    - unless: ls /etc/logrotate.d/{{ formula }}_{{ name }}
    - user: root
    - group: {{ 'wheel' if grains.os in ('MacOS',) else 'root' }}
    - mode: '0440'
    - makedirs: True
    - source: salt://{{ formula }}/files/default/logrotate.jinja
    - context:
        svc: {{ name }}
        pattern: {{ config['systemLog']['path'] }}
        pidpath: {{ config['processManagement']['pidFilePath'] }}
        days: 7
    - require_in:
      - service: {{ formula }}-service-running-{{ comp }}-{{ servicename }}
                                {%- if 'selinux' in d.wanted and d.wanted.selinux %}
  selinux.fcontext_policy_present:
    - name: '/etc/logrotate.d/{{ formula }}_{{ svc }}(/.*)?'
    - sel_type: etc_t
    - require_in:
      - selinux: {{ formula }}-service-running-{{ comp }}-{{ servicename }}-selinux-applied
    - recursive: True
                                {%- endif %}
                            {%- endif %}

                            {%- if 'selinux' in d.wanted and d.wanted.selinux %}
{{ formula }}-service-running-{{ comp }}-{{ servicename }}-selinux-applied:
  selinux.fcontext_policy_applied:
    - names: {{ service_files|json }}
    - require_in:
      - service: {{ formula }}-service-running-{{ comp }}-{{ servicename }}
                            {%- endif %}

                        {%- endif %}  {# config #}
                        {%- if d.wanted.firewall and 'firewall' in software %}

{{ formula }}-service-running-{{ comp }}-{{ servicename }}-firewall-present:
  firewalld.present:
    - name: public
    - ports: {{ software['firewall']['ports']|json }}
    - require:
      - pkg: {{ formula }}-service-running-prerequisites
      - service: {{ formula }}-service-running-prerequisites
    - require_in:
      - service: {{ formula }}-service-running-{{ comp }}-{{ servicename }}
                        {%- endif %}  {# firewall #}

{{ formula }}-service-running-{{ comp }}-{{ servicename }}-unmasked:
  service.unmasked:
    - name: {{ servicename }}
    - onlyif:
       - {{ grains.kernel|lower == 'linux' }}
       - systemctl list-units | grep {{ servicename }} >/dev/null 2>&1
    - require:
      - sls: {{ sls_config_users }}
    - require_in:
      - service: {{ formula }}-service-running-{{ comp }}-{{ servicename }}

{{ formula }}-service-running-{{ comp }}-{{ servicename }}:
  service.running:
    - name: {{ servicename }}
    - enable: True
    - require:
      - sls: {{ sls_software_install }}
      - sls: {{ sls_config_users }}
                        {%- if grains.kernel|lower == 'linux' %}
    - onlyif: systemctl list-units | grep {{ servicename }} >/dev/null 2>&1
                        {%- endif %}  {# linux #}
                        {%- if 'config' in software and software['config'] is mapping %}
    - watch:
      - file: {{ formula }}-config-file-{{ servicename }}-file-managed
                        {%- endif %}

                    {%- endif %}           {# service #}
                {%- endif %}               {# wanted #}
            {%- endfor %}                  {# component #}
        {%- endif %}                       {# wanted #}
    {%- endfor %}                          {# components #}

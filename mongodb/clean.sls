# -*- coding: utf-8 -*-
# vim: ft=sls

{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ "/map.jinja" import data as d with context %}
{%- from tplroot ~ "/libtofs.jinja" import files_switch with context %}
{%- set sls_config_clean = tplroot ~ '.config.users' %}
{%- set sls_service_clean = tplroot ~ '.service.clean' %}
{%- set formula = d.formula %}

include:
  - {{ sls_service_clean }}
  - {{ sls_config_clean }}

{{ formula }}-clean-prerequisites:
  pip.removed:
    - names: {{ d.pkg.pips|json }}
  file.absent:
    - names:
      - {{ d.dir.tmp }}
      - {{ d.dir.var }}
      - /tmp/mac_shortcut.sh
    - require:
      - sls: {{ sls_service_clean }}
      - sls: {{ sls_config_clean }}

    {%- for comp in d.software_component_matrix %}
        {%- if comp in d.wanted and d.wanted is iterable and comp in d.pkg and d.pkg[comp] is mapping %}
            {%- for name,v in d.pkg[comp].items() %}
                {%- if name in d.wanted[comp] %}
                    {%- set software = d.pkg[comp][name] %}
                    {%- set package = software.package_format %}
                    {%- if package in d.software_package_matrix %}

                            {#- PACKAGE CLEAN #}
                        {%- if package in software and software[package] is mapping %}

{{ formula }}-{{ comp }}-{{ name }}-clean:
  pkg.removed:
    - name: {{ software.get('name', name) }}
    - require:
      - file: {{ formula }}-clean-prerequisites
  file.absent:
    - name: {{ software['path'] }}
  pkgrepo.absent:
    - name: {{ d.pkg['repo']['name'] }}

                        {%- endif %}
                        {%- if grains.kernel|lower in ('linux', 'darwin')  %}
                            {%- if package in ('macapp', 'archive',) %}
                                {#- SYMLINK CLEAN #}
                                {%- if d.linux.altpriority|int <= 0 or grains.os_family in ('MacOS', 'Arch',) %}
                                    {%- if 'commands' in software  and software['commands'] is iterable %}
                                        {%- for cmd in software['commands'] %}

{{ formula }}-{{ comp }}-{{ name }}-{{ package }}-clean-symlink-{{ cmd }}:
  file.absent:
    - names:
      - {{ d.dir.symlink }}/{{ 's' if 'service' in software else '' }}bin/{{ cmd }}
      - {{ d.dir.macapp }}/{{ software['name'] }}.app
    - require:
      - file: {{ formula }}-clean-prerequisites
                                    {%- endfor %}
                                {%- endif %}
                            {%- endif %}

                                {#- SERVICE CLEAN #}

{{ formula }}-{{ comp }}-{{ package }}-{{ name }}-clean-service:
  file.absent:
    - names:
      - {{ d.dir.var }}/{{ name }}
      - {{ d.dir.service }}/{{ name }}.service
    - require:
      - file: {{ formula }}-clean-prerequisites
  cmd.run:
    - name: systemctl daemon-reload >/dev/null 2>&1 || true
    - onchange:
      - file: {{ formula }}-{{ comp }}-{{ package }}-{{ name }}-clean-service

                            {%- endif %}  {# service/symlink #}
                        {%- endif %}      {# darwin/linux #}
                    {%- endif %}          {# software/package #}
                {%- endif %}              {# wanted #}
            {%- endfor %}                 {# component #}
        {%- endif %}                      {# wanted #}
    {%- endfor %}                         {# components #}
